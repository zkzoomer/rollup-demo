pragma circom 2.0.0;

include "../circomlib/circuits/poseidon.circom";

template TxLeaf() {
    // Returns the transaction leaf, which is the hash of the transaction:
    // hash(from, to, amount, token_type)

    signal input from_x;
    signal input from_y;
    signal input from_index;
    signal input to_x;
    signal input to_y;
    signal input nonce;
    signal input amount;
    signal input token_type_from;

    signal output out;

    component txLeaf = Poseidon(2);
    component leftSubLeaf = Poseidon(4);
    component rightSubLeaf = Poseidon(4);

    leftSubLeaf.inputs[0] <== from_x;
    leftSubLeaf.inputs[1] <== from_y;
    leftSubLeaf.inputs[2] <== to_x;
    leftSubLeaf.inputs[3] <== to_y;

    rightSubLeaf.inputs[0] <== from_index;
    rightSubLeaf.inputs[1] <== nonce;
    rightSubLeaf.inputs[2] <== amount;
    rightSubLeaf.inputs[3] <== token_type_from;

    txLeaf.inputs[0] <== leftSubLeaf.out;
    txLeaf.inputs[1] <== rightSubLeaf.out;

    out <== txLeaf.out;
}