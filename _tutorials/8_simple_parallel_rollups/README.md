# Simple Parallel Rollups

In the project's [_README_](../../README.md), we covered the idea of using blockchain technology beyond the financial realm, like a swarm of drones where nodes don't necessarily trust each other. The nodes would be able to communicate, transact with each other, and carry out missions on their own. Such implementation, and others like this, is constrained by the underlying blockchain infrastructure. Issues in scalability prevent applications like this from being developed, which get partially solved by scaling solutions like the one being prototyped here.  The way these drones would connect with the network can be a security problem. For now, we will assume each drone can behave as a node or account, and will be able to safely send transactions to the L1 and consequently to the L2. 

## Parallel Rollup, Description

The nature of the mission may be such that the drone swarm gets separated into several sub swarms that are then unable to communicate with each other or the L1. Even in such scenario, the drones should still be able to carry out their mission: transacting between reachable nodes until they get reconnected with each other or the L1. 

Once reconnected, these sub swarms would have to provide a proof that, after separation, they only transacted with reachable nodes. This would prevent a malicious drone from double spending by claiming presence in both sub swarms. Ideally, this would be built into the proof itself, so that there is no need to prove if a separation event even happened: by simply proving a valid state transition we prove that if a separation happened, it was carried out in a secure manner. 

## Existing Solutions and Other Applications
As it stands right now, the Ethereum base layer cannot implement such applications natively because blockchain nodes need to deterministically agree on a single history of the order in which transactions were made to prevent double spending. Besides, the EVM is a single threaded state-machine: transactions need to be processed on a one-by-one basis.

Let us take the example of the Ethereum hard fork that took place in July 2016 and resulted in the distinction of the current Ethereum chain, and the longer standing Ethereum Classic. It would be nearly impossible to try and merge these two chains back together without running into numerous problems: assuming the accounts are the same, their balances and transaction history are vastly different, and each of these cases would have to be handled deterministically. Except for the case where these parallel chains kept the same transaction record, it is unfeasible to try and merge them. This is the case with the upcoming Ethereum merge with the _Beacon Chain_, after which the consensus algorithm of the network will move to Proof-of-Stake, which is expected for late 2022.

A possible solution to have parallel running chains is the one proposed under _sharding_: this is the process of splitting a database horizontally to spread the computational load. This would be the next major upgrade to Ethereum after the move to PoS. For the first proposed version of sharding, these _shards_ would only provide extra data to the network, and would not handle transactions or smart contracts. The improvement in data availability would help rollups increase the total TPS, but it would still not be possible to have parallel running chains that can be merged together.

The second version of sharding, each shard would contain its unique set of smart contracts and account balances, and could function as a parallel chain. Cross-shard communication would allow for transactions between shards, and thus open the possibility to merging them. However, the Ethereum community is debating whether this second version is truly needed: the increase in data availability and thus TPS given by the first version of sharding could be enough.

## ZK-Rollups as a Potential Solution
Zero knowledge proofs allow us to verify that a certain computation was done. As we saw, this can be used to prove ownership of a private key (by signing a message), and to prove the knowledge of a valid state transition, which was the basis for our rollup implementation.

Similarly, we can prototype a parallel chain implementation in which the separations and merging of these parallel chains and their valid state transitions can be proven using a SNARK, and this proof verified on a L1 smart contract. This would allow us to build a rollup which has a built-in mechanism for handling the separation and merging of these parallel chains, in a way that can be resolved deterministically and cannot be tampered with.

## Formal Definition and Prototype
Having n drones in the rollup, able to transact m times per batch.

First implementation, simple reorganize function called at a known time.

## Possible Improvements
Here, reorganization is built into the rollup itself.
