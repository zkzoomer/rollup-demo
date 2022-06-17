# Improving Data Availability
So far, we depend on an honest operator to provide all the necessary data to reconstruct the L2. This could be potentially exploited by denial of service attacks, in which such operator does not include the transactions made by a party into the batch. A simple solution is to depend on more than one operator to decentralize the network, but this solution is useless if these operators are unable to reconstruct the chain in an equally decentralized manner, not having to depend on the data made available by other operators.

The implementation right now does not allow or incentivize for multiple operators: a single address is whitelisted to act as such (although this address could be a smart contract being operated by multiple parties), and there is a lack of financial incentive via fees to perform this role. However, we can simply solve the issue of data availability by changing how our circuits are constructed.

--- reformat so base can be built from on-chain calldata alone, save as much $$$ as possible ---

## Validity vs Validium
>>> compare the cost of each of these, time to generate proof, TPS, ...