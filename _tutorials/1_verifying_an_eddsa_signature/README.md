# Verifying an EdDSA Signature

To sign transactions on the L2, we will be using the Poseidon hash function. To generate proofs for these signatures, we can use the provided `EdDSAPoseidonVerifier` function from `circomlib`. Our verifier will then take the form:

```
template VerifyEdDSAPoseidon() {

    signal input from_x;
    signal input from_y;
    signal input R8x;
    signal input R8y;
    signal input S;
    signal input M;
    
    component verifier = EdDSAPoseidonVerifier();   
    verifier.enabled <== 1;
    verifier.Ax <== from_x;
    verifier.Ay <== from_y;
    verifier.R8x <== R8x;
    verifier.R8y <== R8y;
    verifier.S <== S;
    verifier.M <== M;

}
```

To test this implementation and generate proofs, we can simply define a main component:

```
component main {public [from_x, from_y, R8x, R8y, S, M]} = VerifyEdDSAPoseidon();
```

For our example, the inputs will all be public. These could easily be made private to ensure privacy, so instead of a proof of computation, we would also be giving a proof of knowledge. 

- The `Ax` and `Ay` values correspond to the signer's public key
- The message being signed, `M`, is the poseidon hash of `[123, 456, 789]`. On a rollup, this message would be the transaction hash
- The values `R8x`, `R8y`, and `S` correspond to the signature, `{R, s}`