# Verifying a Withdrawal

For a user to withdraw their funds back to the L1, a two step process is involved. First, they would send the tokens to be withdrawn to the `ZERO_ADDRESS` on the L2. Once this transaction is batched by the operator on a state update, they are then able to call the `withdraw` function on the L1 smart contract to receive their funds. This function will check that the withdraw transaction was in fact batched inside of a transaction root, and will also have to verify that the user calling the function is in fact owner of the account that initiated the withdrawal. For that, we can ask the user to sign a message with their account's private key, and generate a proof that they submit as part of calling the `withdraw` function.

We will go into the details of the `withdraw` function on [chapter 6](../6_building_the_smart_contract/), but verifying this mentioned signature will be similar to what we did on [chapter 1](../1_verifying_an_eddsa_signature/), except only the public key and signed message will be used as public inputs:

```
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
```

We will be generating a Solidity verifier for this circuit that will form part of our rollup smart contract.