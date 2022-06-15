# Building the Smart Contract

As mentioned in previous tutorials, the user sends deposits and withdrawals directly to the smart contract, while the L2 transactions get sent to the coordinator. The coordinator then produces proofs of valid state transitions, and sends them to the smart contract to update the on-chain accounts root. This implementation is a validium-style rollup, where we are assuming the data is made available by the coordinator. We can easily change this into validity-style by making the desired inputs of our circuits public: these will get sent to the smart contract as part of the coordinator's verification transaction. As they will be recorded on the blockchain, we ensure data availability.

## Contract Variables
- `currentRoot`: Merkle root of the balance tree
- `pendingDeposits`: array containing the deposit hashes, its first element is the tallest perfect deposit subtree root
- `queueNumber`: number of deposits waiting to be processed
- `depositSubtreeHeight`: height of the tallest perfect deposit subtree, the first element in `pendingDeposits`
- `updateNumber`: number of updates that have been processed in total
- `updates`: mapping from transaction root to update index, to keep track of all the logged transaction roots
- `processedWithdrawals`: mapping from withdrawal hashed message to boolean, to keep track of voided withdrawals
- `pendingTokens`: tokens awaiting approval by the operator
- `registeredTokens`: tokens registered for use on the L2
- `numTokens`: number of registered tokens
- `coordinator`: address of the coordinator

## Defining the Hashing Function
Besides setting several variables like the coordinator, the constructor will define the hashing function: this is done by another smart contract that gets loaded on deployment. This hashing contract can be used to obtain a Merkle root tracing back from a leaf, or to compute the hash of several inputs, both of these using Poseidon. To execute this Poseidon hashing function inside the EVM, we are using the `buildPoseidon` function from `circomlibjs`, which returns the EVM bytecode for a Poseidon function that takes `n` inputs. This allows us to save up on gas, but a certain limitation exists with this solution, as it is not possible to create a smart contract for hashing more than 6 inputs with Poseidon. As such, we will be deploying 3 different Poseidon hashing smart contracts:

- For _2 inputs_: used to generate branches and roots for Merkle trees, and also to produce the hash of the message to be signed in a withdrawal, taking: the L2 account `nonce`, and the withdrawal `recipient`
- For _4 inputs_: used to generate a transaction leaf by hashing the transaction data in two pairs of four: the sender's and receiver's `pubKey` on one side, and the `index`, `nonce`, `amount` and `tokenType` on the other side
- For _5 inputs_: used to generate account leafs for the on-chain deposit tree, by taking: `pubKey[0]`, `pubKey[1]`, `amount`, `nonce` (which is zero, as it's a new account), and `tokenType`

These three different contracts then get defined inside our `PoseidonMerkle` smart contract, which will handle all the hashing for our `Rollup` smart contract.

## Deposit to Rollup
Users send the deposit transactions directly to the L1 smart contract, and the operator will add these to the balance tree, generating a new root. First, the smart contract will need to verify that the deposit is valid: the token sent is supported, and the estipulated quantity gets sent. The deposits awaiting to be added to the L2 get hashed inside the `pendingDeposits` array: 

![Batching Deposits](https://ethresear.ch/uploads/default/optimized/2X/6/65624d86c1420efcfe6df91d52b488d96e20e82c_2_690x348.png)

## Verifying a State Transition
Account states in the rollup chain get stored in a tree whose root is stored on-chain, and can only be changed by submitting a valid SNARK proof that verifies a valid state transition. 

## Verifying a Withdrawal Transaction


## Adding and approving new tokens
