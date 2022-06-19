const { expect } = require("chai");
const { ethers } = require("hardhat");
const { buildPoseidon, poseidonContract } =  require("circomlibjs");
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
        '1891156797631087029347893674931101305929404954783323547727418062433377377293',
        '14780632341277755899330141855966417738975199657954509255716508264496764475094'
    ]
    const pubkeyA = [
        '16854128582118251237945641311188171779416930415987436835484678881513179891664',
        '8120635095982066718009530894702312232514551832114947239433677844673807664026'
    ]
    const pubkeyB = [
        '17184842423611758403179882610130949267222244268337186431253958700190046948852',
        '14002865450927633564331372044902774664732662568242033105218094241542484073498'
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

    const first4HashPosition = [0, 0]
    const first4HashProof = [
        '14726732185301377694055836147998742577218505657530350941178791543526006846586',
        '12988208845277721051100143718644487453578123519232446209748947254348137166056'
    ]
    
    it("Processes the first batch of deposits", async () => {
        const pendingDepositsRoot = await rollup.pendingDeposits(0);
        // console.log("first subtree root: ", pendingDepositsRoot)
        // 6960010327421291228252508201419367439952682958152537088781183226962683807181

        await rollup.processDeposits(
            2,
            first4HashPosition,
            first4HashProof,
        )

        // await rollup.currentRoot().then(value => console.log(value.toString()))
        // 18466538241864797123870321785163926826062247087767621629240691857827325153252
    })

    const pubkeyC = [
        '1490516688743074134051356933225925590384196958316705484247698997141718773914',
        '18202685495984068498143988518836859608946904107634495463490807754016543014696'
    ]
    const pubkeyD = [
        '605092525880098299702143583094084591591734458242948998084437633961875265263',
        '5467851481103094839636181114653589464420161012539785001778836081994475360535'
    ]
    const pubkeyE = [
        '6115308589625576351618964952901291926887010055096213039283160928208018634120',
        '7748831575696937538520365609095562313470874985327756362863958469935920020098'
    ]
    const pubkeyF = [
        '8497552053649025231196693001489376949137425670153512736866407813496427593491',
        '2919902478295208415664305012229488283720319044050523257046455410971412405951'
    ]

    it("Makes the second batch of deposits", async () => {

        await rollup.connect(alice).deposit(pubkeyC, 200, 2)

        await rollup.deposit(pubkeyD, 100, 1, { value: 100 })

        await rollup.connect(alice).deposit(pubkeyE, 500, 2)

        await rollup.connect(bob).deposit(pubkeyF, 20, 1, { value: 20 })
        
    })

    const second4HashPosition = [1, 0]
    const second4HashProof = [
        '12819191360309232679792099574898289523791611627505351136339109161124786609513',
        '12988208845277721051100143718644487453578123519232446209748947254348137166056'
    ]

    it("Processes the second batch of deposits", async () => {
        await rollup.processDeposits(
            2,
            second4HashPosition,
            second4HashProof
        )

        // await rollup.currentRoot().then(value => console.log("Current root: ", value.toString()))
    })

    let updateProof = require("./multiple_proof.json");
    const updateA = [
        updateProof.pi_a[0], updateProof.pi_a[1]
    ]
    const updateB = [
        [updateProof.pi_b[0][1], updateProof.pi_b[0][0]],
        [updateProof.pi_b[1][1], updateProof.pi_b[1][0]],
    ]
    const updateC = [
        updateProof.pi_c[0], updateProof.pi_c[1]
    ]
    const updateInput = require("./multiple_public.json");

    it("Accepts a valid state transition", async () => {
        await rollup.updateState(
            updateA, updateB, updateC, updateInput
        )

        // await rollup.currentRoot().then(value => console.log(value.toString()))
    })

    // Account C will now initiate a withdrawal
    const pubkey_from = [
        '1490516688743074134051356933225925590384196958316705484247698997141718773914',
        '18202685495984068498143988518836859608946904107634495463490807754016543014696'
    ]
    const index = 4;
    const nonce = 0;
    const amount = 200;
    const token_type_from = 2;
    const position = [1, 0];
    const txRoot = 
        "19186308455265739472869206897619575926741774529294217504266944715222135200973"
    const recipient = '0xC33Bdb8051D6d2002c0D80A1Dd23A1c9d9FC26E4';

    let withdraw_proof = require("./withdraw_proof.json");
    const withdrawA = [
        withdraw_proof.pi_a[0], withdraw_proof.pi_a[1]
    ]
    const withdrawB = [
        [withdraw_proof.pi_b[0][1], withdraw_proof.pi_b[0][0]],
        [withdraw_proof.pi_b[1][1], withdraw_proof.pi_b[1][0]],
    ]
    const withdrawC = [
        withdraw_proof.pi_c[0], withdraw_proof.pi_c[1]
    ]
    const withdrawInput = require("./withdraw_public.json");

    const proof = [
        "17622290836824899442790044432196603002230043363292230216071565951453532330697",
        "17549222109753245772658415708953377529941918196958918546628754677657651638551"
    ]

    it("Accepts valid withdrawals that get voided", async () => {
        await rollup.connect(alice).withdraw(
            [
                pubkey_from[0],
                pubkey_from[1],
                index,
                0,  // toX
                0,  // toY
                nonce,
                amount,
                token_type_from,
                txRoot,
            ],
            position,
            proof,
            recipient,  // recipient
            withdrawA,
            withdrawB,
            withdrawC
        )

        expect(rollup.connect(alice).withdraw(
            [
                pubkey_from[0],
                pubkey_from[1],
                index,
                0,  // toX
                0,  // toY
                nonce,
                amount,
                token_type_from,
                txRoot,
            ],
            position,
            proof,
            recipient,  // recipient
            withdrawA,
            withdrawB,
            withdrawC
        )).to.be.revertedWith("Withdraw transaction already voided");

    })

})