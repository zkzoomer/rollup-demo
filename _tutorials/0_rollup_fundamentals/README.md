# Crypto Fundamentals
This chapter is intended to serve as a reference manual for all the crypto fundamentals that our rollup will be built in. It is directed to people who are new to the space or for those who need a _quick rundown_. 

The field of cryptography is quite vast, and the realm of zero-knowledge proofs is rapidly evolving. This chapter will also serve as a compilation of useful and interesting resources to expand on the topics covered. If math does not scare you, make sure to check them out.

## Hash Functions
Just like in Ethereum, we will be using hash functions throughout our implementation. A hash function maps data of _arbitrary_ size into a _fixed_ size output or digest. Among these, we will be using cryptographic hash functions, in which this mapping is a deterministic, _one-way_ function: it is infeasible to recreate the input by knowing the output.

We will see that not all hash functions are the same, and some will be better suited for our application. The EVM has a built-in `SHA3` opcode to compute the Keccak-256 hash, which is used all throughout Ethereum, but we will be using the SNARK friendly [Poseidon hash function](https://www.poseidon-hash.info/).

## Merkle Trees
A tree in which every leaf is labelled with the hash of its data, and every branch is labelled with the hash of its two child nodes. A small change in a leaf node data will result in a vastly different label for all the nodes it inherits from.

The transactions and account balances of our rollup will be stored inside a Merkle tree, whose roots will be kept on-chain and updated accordingly. The hashing for these Merkle trees will be done with the mentioned Poseidon hash function.

## Public Key Cryptography and Signatures
Just as in Ethereum, ownership of an account is established via _private keys_, which are used for generating the _public keys_ that serve as addresses, and signing _messages_ that serve as transactions. To generate public keys and signatures we will be using the EdDSA digital-signature scheme as it is more efficient, and simpler. It should be noted that EdDSA signatures do not provide a way to recover the public key from the signature and the message, unlike with the ECDSA signatures used in Ethereum. 

To sign an input message, we need the signer's EdDSA private key:
1. Calculate the public key: `pubKey = prvKey * G`, where G is the generator point
2. Compute the nonce: `nonce = HASH(nonce_key || message)`
3. Compute the commitment: `R = nonce * G`
4. Compute the challenge as `HASH(commitment || pubKey || message)`
5. Compute the proof: `s = nonce + challenge · prvKey`
6. Return the signature: `{R, s}`

To verify a signed message, we take as inputs the `message`, the `pubKey`, and the signature `{R, s}`:
1. Calculate `h = HASH(R + pubKey + message)`
2. Calculate `P1 = s * G`
3. Calculate `P2 = R + h * pubKey`
4. Return `P1 == P2`, whether signature was verified or not

The `HASH` function mentioned above refers to the SNARK-friendly Poseidon hash function.

## Zero Knowledge Proofs
These are cryptographic primitives that allow a prover to show to a verifier that a certain statement is true, without revealing any additional information other than the fact that the statement is true. There are two main types: interactive, in which the prover and verifier communicate back and forth, and non interactive. Ideally, both schemes should enjoy three key properties:

- Zero-knowledge: the proof only conveys information about the validity of the statement, and does not reveal anything else about the computation of it.
- Completeness: every statement with a valid witness (a valid computation), has a proof that can convince the verifier.
- Soundness: an invalid witness does not have a proof that can convince the verifier.

The back and forth nature of interactive proofs is not well suited for blockchain applications, and so we will focus on non interactive solutions.

## ZK-SNARKs
Meaning _**Z**ero-**K**nowledge **S**uccinct **N**on-interactive **AR**gument of **K**nowledge_, proofs are generated so that checking a particular polynomial relationship between elements of the proof is equivalent to verifying the prover has a satisfying assignment for the circuit. This makes it easy to verify a proof (which is of constant size), while it is more computationally expensive to generate one. To generate these circuits, we will be using the [circom](https://docs.circom.io/) language.

By executing computations off-chain, and providing a zero-knowledge proof to verify these computations on-chain, it is possible to increase transaction throughput: achieving scalability via a rollup. The SNARK proof basically serve to compress these expensive operations. We say the rollup transactions will take place inside the Layer 2 (L2), while the rollup will post proofs of valid state transition on the base Ethereum layer, or L1. We can differentiate between application-specific rollups and general-rollups, meant to scale the whole Ethereum network by generating proofs of valid state transition on the rollup's EVM. Both of these can also be classified in one of the following:

- Validity-style rollups: zero-knowledge proofs are used to verify on the base layer the valid state changes on the L2. Users transact directly on the L2, submitting their transaction to operators, who then aggregate these and submit to the L1:
    - The new state Merkle tree root
    - A SNARK proof of valid state transition, which gets verified by the smart contract
    - Transaction headers for each of the transactions included in the batch and transaction root, which gets verified by the smart contract

- Validium-style rollups: they work essentially the same way, but the transaction headers are not included in the L1. The operator simply proves that the state transition that they have is valid, without providing any additional information.

The data availability of validity-style rollups is guaranteed, as it is posted on-chain, but this results in a higher end cost for the user. For validium-style rollups, we assume that the operator will be the one to provide the data availability. This can result in censorship attacks, in which a dishonest operator does not batch certain transactions. We can think of validity rollups as a _proof of computation_, while validium rollups serve as both a _proof of computation_ and a _proof of knowledge_.

## SNARK Circuits


## The `circom` Language


## STARKs
One of the main weaknesses of ZK-SNARKs is the need for a trusted setup: a certain secret key is needed to create a common reference string, on which both proof and verification are based. If this secret key is not properly disposed, it can leave the application vulnerable to attacks. This issue can be mitigated by a _1-of-N_ approach, in which several parties participate to generate a secret key such that we only need one of them to properly discard _their_ secret key for the application to be sound. Another issue is that they are not quantum resistant.

By using collision-resistant hash functions, ZK-STARKs avoid the need for a trusted setup and can also achieve quantum-resistance. However, they require a bigger proof size and a much longer verification time than their SNARK counterparts, thus costing more gas.

## Additional Resources
- [Mastering Ethereum](https://github.com/ethereumbook/ethereumbook), the canonical reference for the Ethereum world computer
- [Awesome zero knowledge proofs](https://github.com/matter-labs/awesome-zero-knowledge-proofs)
- [A Review of Zero Knowledge Proofs](https://timroughgarden.github.io/fob21/reports/r4.pdf), for a quick review on ZK-SNARKs
- [Why and How zk-SNARK Works: Definitive Explanation](https://arxiv.org/pdf/1906.07221.pdf), for a comprehensive review
- [Circuit compiler, circom](https://docs.circom.io/), to create and test zero knowledge proofs for our circuits
- [Circuit library, circomlib](https://github.com/iden3/circomlib), containing useful functions that will be used
- [Poseidon](https://www.poseidon-hash.info/), ZK-friendly hashing
