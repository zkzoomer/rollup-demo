# Improving Data Availability
So far, we depend on an honest operator to provide all the necessary data to reconstruct the L2. This could be potentially exploited by denial of service attacks, in which such operator does not include the transactions made by a party into the batch. A simple solution is to depend on more than one operator to decentralize the network, but this solution is useless if these operators are unable to reconstruct the chain in an equally decentralized manner, not having to depend on the data made available by other operators.

The implementation right now does not allow or incentivize for multiple operators: a single address is whitelisted to act as such (although this address could be a smart contract being operated by multiple parties), and there is a lack of financial incentive via fees to perform this role. However, we can simply solve the issue of data availability by changing how our circuits are constructed.

## Validty Style Rollup
In a validity style rollup, it is possible to reconstruct the entire history of the L2 from on-chain data alone, without having to rely on an operator or a third party. We will have to provide all the data necessary to rebuild the L2 as part of the SNARK proof, which will be sent as `calldata` function arguments. This ensures that every node on the L1 will have access to this data and thus will be able to reconstruct the state of the L2.

The logic behind a valid state transition is carried out by the SNARK proof, and doesn't depend on the public arguments given to it. Therefore, to save as much gas as possible, we need to provide to the L1 the minimum amount of information possible to reconstruct the history of the L2. For this, we need to analyze again the L2 deployment and use process.

### Deposits
Depositing to the L2 is done by calling the `deposit` function on the smart contract, and providing the L2 public key, amount to deposit and token type to be supported. Remember that accounts are defined by their public key, balance, nonce and token type. Since the nonce will start at zero, this means that the starting state of __every__ account in the L2 gets recorded on-chain.

These deposits later get processed by the operator by calling `processDeposits`, adding them to the balance tree. This is done by first proving that there exists an empty balance subtree for the `currentRoot` which will be replaced by these deposits. As this proof is done by providing a path for hashing to reach the `currentRoot`, we can derive where the pending deposits were added in the balance tree.

In summary, from on-chain data alone we can know the initial state of each of the accounts in the L2, as well as their permanent positions within the balance tree.

### Transactions
The other event that can change the `currentRoot` of the L2 are transactions. Whether they are between parties or withdrawals does not really matter: we will only have to account for the balance of the `ZERO_ACCOUNT` to remain null in the event of L2 withdrawal transactions. 

We can modify our circuits to include a `from_index` and `to_index` that represent the leaf indices inside the balance tree for the accounts that send and receive each transaction. The circuit logic would of course have to verify that these indices represent the actual correct positions of these leafs inside the balance tree. Simply using this plus the `amount` value for each of the transactions that make up the transaction tree is enough to derive the state of the L2 after every `updateState` smart contract call, purely from on-chain data.

### Achieving Full Data Availability
Remember that an account is defined as:

```
class Account = {
    pubkey: eddsa_pubkey,
    balance: integer,
    nonce: integer,
    token_type: integer
}
```

Both the public key and token type, which stays constant, can be obtained from the original `deposit` smart contract call. The account's index within the balance tree (used to identify transactions) can be obtained from the operator's call to `processDeposits`. The account's nonce will start at zero, and its balance will start at whatever was sent with the `deposit` call.

Considering that each of the operator's `updateState` call verifies a valid state transition from a given transaction batch, the state of the accounts tree after this transition can be simply derived by using the mentioned public inputs. We can get the current balance of an account by adding to the previous balance the inflows and outflows. The nonce can be obtained by adding to the previous value the number of times that account sent transactions.

This means that simply by readapting our circuits and making __public__ the inputs `from_index`, `to_index` and `amount`, which are different for every transaction in a state update, we can recreate the current state of the balance tree from on-chain data alone. This could allow other operators to start receiving transactions and batching them, validating the network without having to rely on others for their data availability.

## Implementation
To transform this into a Validity style rollup, we will have to make some simple changes. First, inside the logic of our circuits we will need to verify that the provided indeces are correct. This can be done by using the already existing `paths2root_from_pos` and `paths2root_to_pos`. We will also need to define a new input signal, `to_index`. Notice how `from_index` was already defined and used but not verified.

The implementation is simple. For the example of the `from_index`:
```
var from_idx = 0;
for (var k = n - 1; k >= 0; k--) {
    from_idx += paths2root_from_pos[i][k] * 2 ** k;
}
assert(from_idx = from_index[i]);
``` 

We will have to recompile our circuit to reflect this change and generate a new Solidity verifier that will replace the one in our smart contract. The new verifier will now take a greater amount of inputs:
```
inputs.length = 3 + 3 * 2 ** TX_DEPTH
```
These first three will be the `newRoot`, `txRoot`, and `oldRoot`, while the additional ones will be the `from_index`, `to_index` and `amount` arrays concatenated.

With these simple changes done, our rollup is now validity style.

## Validity vs Validium
We can draw some rough estimates comparing the efficiency of these two different implementations
// TODO - save gas on each optimizing code, as much as possible
// TODO - draw estimates comparing efficiency of both