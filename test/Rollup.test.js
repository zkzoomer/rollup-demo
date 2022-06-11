const { expect } = require("chai");
const { ethers } = require("hardhat");
const { buildPoseidon, poseidonContract } =  require("circomlibjs");
const poseidon = require("../src/poseidon.js");
const assert = require('assert');

describe("Rollup contract tests", function () {
    let operator, alice, bob;
    let poseidonMerkle;
    let rollup;
    let testToken;
    this.timeout(100000);

    before (async function () {
        [operator, alice, bob] = await ethers.getSigners();

        // Deploying the Poseidon hashing contract
        const P2 = new ethers.ContractFactory(
            poseidonContract.generateABI(2),
            poseidonContract.createCode(2),
            operator
        );
        const P4 = new ethers.ContractFactory(
            poseidonContract.generateABI(4),
            poseidonContract.createCode(4),
            operator
        );
        const P5 = new ethers.ContractFactory(
            poseidonContract.generateABI(5),
            poseidonContract.createCode(5),
            operator
        );
        const poseidon2 = await P2.deploy();
        const poseidon4 = await P4.deploy();
        const poseidon5 = await P5.deploy();

        var PoseidonMerkle = await ethers.getContractFactory("PoseidonMerkle")
        poseidonMerkle = await PoseidonMerkle.deploy(
            poseidon2.address,
            poseidon4.address,
            poseidon5.address
        );
    })

    it("Deploys the contracts", async () => {
        var Rollup = await ethers.getContractFactory("Rollup");
        rollup = await Rollup.deploy(poseidonMerkle.address);

        var TestToken = await ethers.getContractFactory("TestToken");
        testToken = await TestToken.deploy();
    })

    it("Registers a new token", async () => {
        await rollup.connect(alice).registerToken(testToken.address);
        assert.equal(
            true,
            await rollup.pendingTokens(testToken.address)
        );
    })

    it("Can approve the token", async () => {
        await expect(rollup.connect(alice).approveToken(testToken.address)).to.be.reverted;
        await rollup.approveToken(testToken.address);

        assert.equal(
            2,
            (await rollup.numTokens()).toString()
        )
        assert.equal(
            testToken.address,
            (await rollup.registeredTokens(2))
        )
    })

    it("User can approve Rollup contract on TestToken", async () => {
        await testToken.connect(alice).approve(
            rollup.address,
            1700
        )

        // Will also fund alice with this amount
        await testToken.transfer(alice.address, 1700);
    })

    const pubkeyCoordinator = [
        '5686635804472582232015924858874568287077998278299757444567424097636989354076',
        '20652491795398389193695348132128927424105970377868038232787590371122242422611'
    ]
    const pubkeyA = [
        '5188413625993601883297433934250988745151922355819390722918528461123462745458',
        '12688531930957923993246507021135702202363596171614725698211865710242486568828'
    ]
    const pubkeyB = [
        '3765814648989847167846111359329408115955684633093453771314081145644228376874',
        '9087768748788939667604509764703123117669679266272947578075429450296386463456'
    ]

    it("Makes first batch of deposits", async () => {
        await rollup.deposit(
            [0,0],  // pubkey
            0,  // amount
            0,  // token type -- reserved to operator
        );

        await rollup.deposit(
            pubkeyCoordinator,
            0,
            0
        );

        await rollup.connect(alice).deposit(
            pubkeyA,
            1000,
            2
        );

        await rollup.connect(bob).deposit(
            pubkeyB,
            20,
            1,
            { value: 20 }
        );

        // await rollup.currentRoot().then(value => console.log(value.toString()));
    })

    let first4Hash
    const first4HashPosition = [0, 0]
    const first4HashProof = [
        '14726732185301377694055836147998742577218505657530350941178791543526006846586',
        '12988208845277721051100143718644487453578123519232446209748947254348137166056'
    ]
    
    it("Processes the first batch of deposits", async () => {
        const pendingDepositsRoot = await rollup.pendingDeposits(0);
        // console.log(pendingDepositsRoot)
        first4Hash = poseidon([
            poseidon([
                pendingDepositsRoot,
                first4HashProof[0]
            ]).toString(),
            first4HashProof[1]
        ]).toString();
        // console.log(first4Hash)

        await rollup.processDeposits(
            2,
            first4HashPosition,
            first4HashProof,
        )

        // await rollup.currentRoot().then(value => console.log(value.toString()))
    })

    const pubkeyC = [
        '1762022020655193103898710344498807340207430243997238950919845130297394445492',
        '8832411107013507530516405716520512990480512909708424307433374075372921372064'
    ]
    const pubkeyD = [
        '14513915892014871125822366308671332087536577613591524212116219742227565204007',
        '6808129454002661585298671177612815470269050142983438156881769576685169493119'
    ]
    const pubkeyE = [
        '20300689398049417995453571887069099991639845657899598560126131780687733391655',
        '3065218658444486645254031909815995896141455256411822883766560586158143575806'
    ]
    const pubkeyF = [
        '4466175261537103726537785696466743021163534542754750959075936842928329438365',
        '15538720798538530286618366590344759598648390726703115865880683329910616143012'
    ]

    it("Makes the second batch of deposits", async () => {

        await rollup.connect(alice).deposit(pubkeyC, 200, 2)

        await rollup.deposit(pubkeyD, 100, 1, { value: 100 })

        await rollup.connect(alice).deposit(pubkeyE, 500, 2)

        await rollup.connect(bob).deposit(pubkeyF, 20, 1, { value: 20 })
        
    })

    second4HashPosition = [1, 0]
    second4HashProof = [
        first4Hash,
        '12988208845277721051100143718644487453578123519232446209748947254348137166056'
    ]

    it("Processes the second batch of deposits", async () => {
        rollup.processDeposits(
            2,
            second4HashPosition,
            second4HashProof
        )

        // await rollup.currentRoot().then(value => console.log(value.toString()))
    })

    // TODO:

    it("Accepts a valid state transition", async () => {

    })

    it("Accepts valid withdrawals that get voided", async () => {
        
    })

})