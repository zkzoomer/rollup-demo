pragma circom 2.0.0;

include "../circomlib/circuits/eddsaposeidon.circom";
include "../circomlib/circuits/mimc.circom";

template Main(){

    signal input Ax;
    signal input Ay;
    signal input R8x;
    signal input R8y;
    signal input S;
    signal input M;

    component verifier = EdDSAPoseidonVerifier();   
    verifier.enabled <== 1;
    verifier.Ax <== Ax;
    verifier.Ay <== Ay;
    verifier.R8x <== R8x;
    verifier.R8y <== R8y;
    verifier.S <== S;
    verifier.M <== M;

}

component main {public [Ax, Ay, M]} = Main();