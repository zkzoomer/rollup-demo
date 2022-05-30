pragma circom 2.0.0;

include "./leaf_existence.circom";
include "./verify_eddsa.circom";
include "./get_merkle_root.circom";
include "../circomlib/circuits/poseidon.circom";

template ProcessTx(k) {
    // STEP 0: Initialise signals
    // account tree initial root
    signal input accounts_root; 

    // account tree root after one update
    signal input intermediate_root;

    // account public keys
    signal input accounts_pubkeys[2**k][2];

    // account balances 
    signal input accounts_balances[2**k];

    // transaction input
    signal input sender_pubkey[2];
    signal input sender_balance;
    signal input receiver_pubkey[2];
    signal input receiver_balance;
    signal input amount;
    // sender signature
    signal input signature_R8x;
    signal input signature_R8y;
    signal input signature_S;
    // proof of inclusion
    signal input sender_proof[k];
    signal input sender_proof_pos[k];
    signal input receiver_proof[k];
    signal input receiver_proof_pos[k];

    // final account tree root -- output
    signal output new_accounts_root;

    // STEP 1: Check sender's account existence
    // constructing the Merkle tree to verify sender account exists in accounts_root
    component senderExistence = LeafExistence(k, 3);
    // sender leaf node comes from hashing public key and balance
    senderExistence.preimage[0] <== sender_pubkey[0];
    senderExistence.preimage[1] <== sender_pubkey[1];
    senderExistence.preimage[2] <== sender_balance;
    senderExistence.root <== accounts_root;
    for (var i = 0; i < k; i++) {
        senderExistence.paths2_root[i] <== sender_proof[i];
        senderExistence.paths2_root_pos[i] <== sender_proof_pos[i];
    }

    // STEP 2: Check sender's account signature
    // constructing the signature to verify transaction was signed by the sender
    component signatureCheck = VerifyEdDSAPoseidon(5);
    // signing details
    signatureCheck.from_x <== sender_pubkey[0];
    signatureCheck.from_y <== sender_pubkey[1];
    signatureCheck.R8x <== signature_R8x;
    signatureCheck.R8y <== signature_R8y;
    signatureCheck.S <== signature_S;
    // message that was signed is the hash of the transactions details
    signatureCheck.preimage[0] <== sender_pubkey[0];
    signatureCheck.preimage[1] <== sender_pubkey[1];
    signatureCheck.preimage[2] <== receiver_pubkey[0];
    signatureCheck.preimage[3] <== receiver_pubkey[1];
    signatureCheck.preimage[4] <== amount;

    // STEP 3: Debit sender's account and create updated leaf
    component newSenderLeaf = Poseidon(3);
    newSenderLeaf.inputs[0] <== sender_pubkey[0];
    newSenderLeaf.inputs[1] <== sender_pubkey[1];
    newSenderLeaf.inputs[2] <== sender_balance - amount;

    // STEP 4: Update accounts tree to intermediate root - debited sender
    component computed_intermediate_root = GetMerkleRoot(k);
    
    computed_intermediate_root.leaf <== newSenderLeaf.out;
    for (var i = 0; i < k; i++) {
        computed_intermediate_root.paths2_root[i] <== sender_proof[i];
        computed_intermediate_root.paths2_root_pos[i] <== sender_proof_pos[i];
    }

    // verify that the computed intermediate root is equal to the inputted intermediate root
    computed_intermediate_root.out === intermediate_root;

    // STEP 5: Verify receiver's account in intermediate root
    // constructing the Merkle tree to verify receiver account exists in accounts_root
    component receiverExistence = LeafExistence(k, 3);
    // receiver leaf node comes from hashing public key and balance
    receiverExistence.preimage[0] <== receiver_pubkey[0];
    receiverExistence.preimage[1] <== receiver_pubkey[1];
    receiverExistence.preimage[2] <== receiver_balance;
    receiverExistence.root <== intermediate_root;
    for (var i = 0; i < k; i++) {
        receiverExistence.paths2_root[i] <== receiver_proof[i];
        receiverExistence.paths2_root_pos[i] <== receiver_proof_pos[i];
    }

    // STEP 6: Credit receiver's account and create updated leaf
    component newReceiverLeaf = Poseidon(3);
    newReceiverLeaf.inputs[0] <== receiver_pubkey[0]; 
    newReceiverLeaf.inputs[1] <== receiver_pubkey[1];
    newReceiverLeaf.inputs[2] <== receiver_balance + amount;

    // STEP 7: Update accounts tree to final root - updated receiver
    component computed_final_root = GetMerkleRoot(k);
    computed_final_root.leaf <== newReceiverLeaf.out;
    for (var i = 0; i < k; i++) {
        computed_final_root.paths2_root[i] <== receiver_proof[i];
        computed_final_root.paths2_root_pos[i] <== receiver_proof_pos[i];
    }

    // STEP 8: Output the final tree root
    new_accounts_root <== computed_final_root.out;
}

// ProcessTx testing main
component main {public [accounts_root]} = ProcessTx(1);