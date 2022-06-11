# rollup-demo
Basic validium rollup implementation based on ZK-SNARKS. 

Users can transact different tokens in the L2 while an operator updates the L1 smart contract proving valid state transitions. We assume this operator is **honest**, providing data to users to update their leaf. 

For hashing we will use Poseidon, a SNARK friendly hashing function. 

## Future improvements
- The implementation can be changed to a validity style rollup by simply making the _private_ circuit inputs _public_.
- Accounts on the L2 can only support a single token each: public keys are related to a token type. Ideally each should be token agnostic.
- State updates can only be performed by the assign operator.
