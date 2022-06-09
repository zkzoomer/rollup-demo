// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Pairing.sol";

contract WithdrawVerifier {
    using Pairing for *;
    struct WithdrawVerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct WithdrawProof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function withdrawVerifyingKey() internal pure returns (WithdrawVerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            18363040305467739592440372775387826249015106968119033066790104568438791415817,
            20334394567135367649623329458538596133493249013003379565198912736213823039936
        );

        vk.beta2 = Pairing.G2Point(
            [1655763508354580093582116587162563121689908330767098182786646079200326517427,
             18274348423085846236925747673024289025821605340229384683616028343832515801549],
            [15605064854111831949247991501950056881940499613908479634629325620157431159315,
             21254281977158187503900876070253463023399590706737963890088861073411709299330]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [9369052684451603525643398882212607486193707558654327322578126897008642177677,
             16833290968415085976929790688873290960985806586378413349899496657185865535879],
            [17359294841728130999923270716004750430736906952326327329388506135148388060494,
             11425316070616590342955660225102191553589560885764462919026962085047647782358]
        );
        vk.IC = new Pairing.G1Point[](4);
        
        vk.IC[0] = Pairing.G1Point( 
            12987135878510334359742030868508439162404233261428181351577973246950466591702,
            7437887132184129935875844634648864089587920496929155795603741624947646437072
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            8769895011617691094124381175535536830270867361482787574333247996712333593591,
            5404067482874897918428855123507202697761025827062398833065545505382925431160
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            16960957743976583760927088191015378182590397404335654396269960983002549180961,
            2021502970979899031771584730093197272470965549057362738549768341850619492279
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            11968539020070108230343320364145416604772721175101984090130815909532060463239,
            12104637029760449512346913839663231857983966319318383049126695553236587180268
        );                                      
        
    }
    function withdrawVerify(uint[] memory input, WithdrawProof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        WithdrawVerifyingKey memory vk = withdrawVerifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyWithdrawProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[3] memory input
        ) public view returns (bool r) {
        WithdrawProof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (withdrawVerify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}