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

    component txLeaf = Poseidon(8);
    txLeaf.inputs[0] <== from_x;
    txLeaf.inputs[1] <== from_y;
    txLeaf.inputs[2] <== from_index;
    txLeaf.inputs[3] <== to_x;
    txLeaf.inputs[4] <== to_y;
    txLeaf.inputs[5] <== nonce;
    txLeaf.inputs[6] <== amount;
    txLeaf.inputs[7] <== token_type_from;

    out <== txLeaf.out;
}