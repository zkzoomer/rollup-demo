# Verifying a Merkle Tree

Inside our rollup, we will be using Merkle trees to keep track of account balances and transactions. We will be testing two examples relevant to our application.

## Getting a Merkle Tree 

The account balance root is stored on-chain. To update this balance root, we need to provide a valid state transition proof. This proof will, among other things, construct the account balance Merkle tree. For our applications, we will be constructing a Merkle tree from a given leaf, tracing up the branches until reaching the root:

```
template GetMerkleRoot(k){
    // k is depth of tree

    signal input leaf;
    signal input paths2_root[k];
    signal input paths2_root_pos[k];

    signal output out;

    // hash of first two entries in tx Merkle proof
    component merkle_root[k];
    merkle_root[0] = Poseidon(2);
    merkle_root[0].inputs[0] <== leaf - paths2_root_pos[0]* (leaf - paths2_root[0]);
    merkle_root[0].inputs[1] <== paths2_root[0] - paths2_root_pos[0]* (paths2_root[0] - leaf);

    // hash of all other entries in tx Merkle proof
    for (var v = 1; v < k; v++){
        merkle_root[v] = Poseidon(2);
        merkle_root[v].inputs[0] <== merkle_root[v-1].out - paths2_root_pos[v]* (merkle_root[v-1].out - paths2_root[v]);
        merkle_root[v].inputs[1] <== paths2_root[v] - paths2_root_pos[v]* (paths2_root[v] - merkle_root[v-1].out);
    }

    // output computed Merkle root
    out <== merkle_root[k-1].out;
}
```

The `Poseidon` function is implemented as part of the `circomlib` library and will be used all throughout our implementation.

The first element of `paths2_root` is the label of the node that shares parents with our leaf. The first element of `paths2_root_pos` is the position of our leaf for the hashing function, `0` for the left position, `1` for the right position. The output of this hash will serve as our new 'leaf', which will be hashed with the second element of `paths2_root`, until reaching the Merkle root.

We can test this implementation by defining a main component, but do so by proving leaf existence at the same time.

## Proving the Existence of a Leaf

As we will see, part of our circuits will deal with proving that a certain leaf exists within a Merkle tree. Upon seeing the last example, this case is quite simple: 

```
template LeafExistence(k){
    // k is depth of tree
    
    signal input leaf;
    signal input root;
    signal input paths2_root[k];
    signal input paths2_root_pos[k];

    component computed_root = GetMerkleRoot(k);
    computed_root.leaf <== leaf;

    for (var w = 0; w < k; w++){
        computed_root.paths2_root[w] <== paths2_root[w];
        computed_root.paths2_root_pos[w] <== paths2_root_pos[w];
    }

    // equality constraint: input tx root === computed tx root 
    root === computed_root.out;
}
```

To test our implementation and generate proofs, we simply define a main component:
```
component main {public [leaf, root, paths2_root, paths2_root_pos]} = LeafExistence(2);
``` 

With this circuit, we will be able to prove that a certain `leaf` exists within a Merkle tree defined by its `root`. 

