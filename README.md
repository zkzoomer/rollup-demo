# rollup-demo
The goal with this repository is to become a comprehensive guide on understanding and building a basic rollup implementation based on ZK-SNARKS. We will be generating succinct proofs for large computations that are fast to verify: proving a valid state transition contaning an arbitrary number of transactions.

The [tutorial section](./_tutorials/) contains a quick rundown over the fundamentals behind a ZK-Rollup and gives step by step explanations on building the current implementation, the one present in this directory. As this current implementation evolves, so will the tutorial part behind it.

## Motivation
This repository covers the technical aspect of the research being done on verifiable computation for embedded blockchains as part of my MSc in Aerospace Engineering. The idea behind this research is to analyze and prototype possible applications of blockchain technology beyond the financial realm. While the obvious main limitation right now is scalability, there are other issues that arise with specific applications. 

A proposed potential application is having a swarm of drones (where nodes do not necessarily trust each other) communicate using transactions. While a rollup seems like a good fit, a possible issue arises if this swarm gets divided into two or more _sub swarms_ that cannot communicate with each other. While communication is still possible within the nodes of a sub swarm, if all the nodes were to be reunited again in the future it is necessary that they do so respecting all the valid transitions that ocurred while they were separated, so that the mission can carry on seamlessly. We believe that ZK-Rollups offer the necessary tools for solving such a problem, and so the idea of this repository is to investigate upon these tools and expand on them to unlock other applications.

## Tutorial Contents
+ [Rollup Fundamentals](./_tutorials/0_rollup_fundamentals/)
+ [Introduction to SNARKs](./_tutorials/1_intoduction_to_snarks/)
+ [Verifying an EdDSA Signature](./_tutorials/2_verifying_an_eddsa_signature/)
+ [Verifying a Merkle Tree](./_tutorials/3_verifying_a_merkle_tree/)
+ [Verifying a Single Transaction](./_tutorials/4_verifying_a_single_transaction/)
+ [Verifying Multiple Transactions](./_tutorials/5_verifying_multiple_transactions/)
+ [Verifying a Withdrawal](./_tutorials/6_verifying_a_withdrawal/)

## Current Development State
In the current implementation, users can transact different tokens in the L2 while an operator updates the L1 smart contract proving valid state transitions. Users can then withdraw their funds to the L1 by providing a valid signarure and a proof of withdrawal transaction inclusion in one of the transaction roots. We assume the operator to be **honest**: they will be collecting all the transactions and processing these batches to generate SNARK proofs of a valid state transition. The zero-knowledge proof gets verified by the L1 smart contract, storing the new state on-chain and thus completing the state transition. This implementation does not publish the transaction data to the L1: this is called a Validium style rollup, resulting in cheaper gas fees for users. We assume the operator will guarantee this data availability.

A dishonest operator cannot forge signatures or create invalid state transitions: the security guarantees are given by the soundness of the SNARK proof and the reliability of the L1. At most, they can freeze funds by not incorporating user's transactions in a batch or withholding off-chain data to users.

*The implementation as it stands still lacks the operator software needed to collect and process transactions in batches.

## Future improvements
- The implementation can be changed to a validity style rollup by simply making the _private_ circuit inputs _public_.
- Accounts on the L2 can only support a single token each: public keys are related to a token type. Ideally each should be token agnostic.
- State updates can only be performed by the assigned operator.

## Acknowledgements
This repository is based and extends on [RollupNC](https://github.com/rollupnc/RollupNC).