pragma circom 2.0.0;

include "./get_merkle_root.circom";
include "../circomlib/circuits/poseidon.circom";

// checks for existence of leaf in tree of depth k

template LeafExistence(k, l){
    // k is depth of tree
    // l is depth of preimage of leaf
    
    signal input preimage[l];
    signal input root;
    signal input paths2_root[k];
    signal input paths2_root_pos[k];

    component leaf = Poseidon(l);
    for (var i = 0; i < l; i++) {
        leaf.inputs[i] <== preimage[i];
    }

    component computed_root = GetMerkleRoot(k);
    computed_root.leaf <== leaf.out;

    for (var w = 0; w < k; w++){
        computed_root.paths2_root[w] <== paths2_root[w];
        computed_root.paths2_root_pos[w] <== paths2_root_pos[w];
    }

    // equality constraint: input tx root === computed tx root 
    root === computed_root.out;
}

// component main {public [leaf, root, paths2_root, paths2_root_pos]} = LeafExistence(2);