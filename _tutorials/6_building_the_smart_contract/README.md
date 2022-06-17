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
Users send the deposit transactions directly to the L1 smart contract, and the operator will add these to the balance tree, generating a new root. First, the smart contract will need to verify that the deposit is valid: the token sent is supported, and the estipulated quantity gets sent. The deposits awaiting to be added to the L2 get hashed inside the `pendingDeposits` array, following this scheme: 

![Batching Deposits](https://ethresear.ch/uploads/default/optimized/2X/6/65624d86c1420efcfe6df91d52b488d96e20e82c_2_690x348.png)

The first element in the `pendingDeposits` array will contain the tallest perfect deposit subtree root. The operator can then add this first element by proving that there exists an empty subtree in the `currentRoot`, after which this `currentRoot` will be updated to reflect the inclusion of these deposits, the first element in `pendingDeposits` removed, and the funds will be allowed to operate inside the L2. The change in state inside the smart contract means that, once deposits have been processed, the next state transition will have as starting root the result of adding these new accounts.

## Verifying a State Transition
Account states in the rollup chain get stored in a tree whose root is stored on-chain, and can only be changed by submitting a valid SNARK proof that verifies a valid state transition. This valid state transition can be:
- Result of adding a deposit batch to the L2. This more trivial case can be implemented directly in solidity, as it consits in proving that the balance tree has an empty branch and generating the new root. This results in a new balance root that gets reflected in the smart contract as the new `currentRoot`.
- Result of processing a batch of transactions on the L2. The operator will submit a valid SNARK proof to the `update` function of the smart contract, generated following [chapter 4](../4_verifying_multiple_transactions/). The transaction root will also be recorded inside the smart contract.

## Verifying a Withdrawal Transaction
After sending their L2 tokens to the zero address, a user will need to provide two proofs that show that:

- Their withdrawal transaction was included in a previous batch. This is done by providing a valid transaction root (result of a valid state transition, stored in the contract), the actual L2 withdrawal transaction hash, and the branches that trace it back to the transaction root. This proves that the L2 withdrawal transaction has been batched.
- They own the account that initiated the withdrawal in the L2. The SNARK proof is similar to the one done in [chapter 1](../1_verifying_an_eddsa_signature/), where they will prove ownership of the L2 private key by signing a message that is the hash of the corresponding L2 account nonce and the L1 address of the recipient.

The L2 transaction hash will then have to be voided to prevent double spending. By also requesting a new signature for each transaction, we ensure that to successfully call the `withdraw` function you need to first perform a L2 withdrawal, and prove ownership of that transaction.
## Adding and approving new tokens
By default, the L2 will support the native currency, ETH, for transactions. To whitelist other tokens for depositing on the L2, a two step process is involved:

1. The function `registerToken` is called: this function is `external`, so it can be called by anyone. This will put the requested token in a pending list, awaiting approval.
2. The function `approveToken` is called by the operator: after this the token will be available for deposits.

To operate on the L2, first we need to deposit those funds on the L1 smart contract. As such, for a token to be available on the L2, it first needs to have been deposited, and for that we require that it is whitelisted. Thanks to this, we have a built-in bridge for a series of whitelisted tokens, where the logic and security rests on the Ethereum chain itself, unlike other current bridge implementations.
