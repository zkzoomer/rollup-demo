// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Pairing.sol";

contract UpdateVerifier {
    using Pairing for *;
    struct UpdateVerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct UpdateProof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function updateVerifyingKey() internal pure returns (UpdateVerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            18327526583930768907492346140112657474132526684722811862225438503344380249605,
            10687794335906261657142314214349746490119788691681821338658109820395985883584
        );

        vk.beta2 = Pairing.G2Point(
            [19333941983493161101495467613532254966728349842437136814651548709749874433345,
             3115492169124445649916202181545021049271355355277727937727732156338331894841],
            [16929188638325039039116088552770561891736539359632632742683881564293567125508,
             21237681412810344294824665508523452921445836040590119925537524619954603604005]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [14053217263464846986687930153181580201611403982521374453162264095856776898125,
             16807769647728793925934904919955983399281187376639027708985534383834501323246],
            [6204843462855477647036660172503982624367944986484569215787912999964154604963,
             21189095153790613218557300847827328292215555534886467090694139605645927247597]
        );
        vk.IC = new Pairing.G1Point[](4);
        
        vk.IC[0] = Pairing.G1Point( 
            12563615804516679195186765851728821949770692868147301098675664095331878863064,
            19140099581844588722743598366453659246257809884869640274390530923711871090021
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            13626364758055126126039594820147660866320948062684218498280944107048938543390,
            20967681092352300243382369012287257709568524753496601525639505026025479101956
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            16905015011651463696454150706928436869244183800396775258648214875503496688372,
            4508355756256162287295414149769527155383047623065079440876964903244381299701
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            8915551648112572782452287525215150118226696271229027490220833065350738570573,
            577751213141086906531856083597545646612502971877391639017112528890962792521
        );                                      
        
    }
    function updateVerify(uint[] memory input, UpdateProof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        UpdateVerifyingKey memory vk = updateVerifyingKey();
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
    function verifyUpdateProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[3] memory input
        ) public view returns (bool r) {
        UpdateProof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (updateVerify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}