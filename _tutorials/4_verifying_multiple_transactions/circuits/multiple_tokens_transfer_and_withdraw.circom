pragma circom 2.0.0;

include "../circomlib/circuits/poseidon.circom";
include "../circomlib/circuits/eddsaposeidon.circom";
include "../circomlib/circuits/bitify.circom";
include "./if_gadgets.circom";
include "./tx_existence_check.circom";
include "./balance_existence_check.circom";
include "./balance_leaf.circom";
include "./get_merkle_root.circom";

template ProcessTxs(n, m) {
    // n is the depth of the balance tree 
    // m is the depth of the transactions tree,
    // so for each proof, we update 2**m transactions

    // STEP 0: initialize signals
    // account tree initial root
    signal input tx_root;

    // paths for proving tx in tx tree
    signal input paths2tx_root[2**m][m];
    signal input paths2tx_root_pos[2**m][m];

    // Merkle root of old balance tree
    signal input current_state;

    // intermediate roots for all the transactions
    signal input intermediate_roots[2**(m + 1) + 1];

    // Merkle proof for sender account in old balance tree
    signal input paths2_root_from[2**m][n];
    signal input paths2root_from_pos[2**m][n];

    // Merkle proof for receiver account in old balance tree
    signal input paths2_root_to[2**m][n];
    signal input paths2root_to_pos[2**m][n];

    /* // TODO ????
    // Merkle proof for sender account in new balance tree
    signal input paths2new_root_from[2**m][n];
    // Merkle proof for receiver account in new balance tree
    signal input paths2new_root_to[2**m][n]; */

    // tx info, 10 fields
    signal input from_x[2**m]; //sender address x coordinate
    signal input from_y[2**m]; //sender address y coordinate
    signal input from_index[2**m]; // sender account leaf index
    signal input to_x[2**m]; // receiver address x coordinate
    signal input to_y[2**m]; // receiver address y coordinate
    signal input nonce_from[2**m]; // sender account nonce
    signal input amount[2**m]; // amount being transferred
    signal input token_type_from[2**m]; // sender token type
    signal input R8x[2**m]; // sender signature
    signal input R8y[2**m]; // sender signature
    signal input S[2**m]; // sender signature

    // additional account info, not included in tx
    signal input token_balance_from[2**m]; // sender token balance
    signal input token_balance_to[2**m]; // receiver token balance
    signal input nonce_to[2**m]; // receiver account nonce
    signal input token_type_to[2**m]; // receiver token type

    // new balance tree Merkle root 
    signal output out;

    // limiting nonce to 100
    var NONCE_MAX_VALUE = 100;  

    // constant zero address -- to process withdrawals
    var ZERO_ADDRESS_X = 0;
    var ZERO_ADDRESS_Y = 0;

    component txExistence[2**m];
    component senderExistence[2**m];
    component ifBothHighForceEqual[2**m];
    component newSender[2**m];
    component computedRootFromNewSender[2**m];
    component receiverExistence[2**m];
    component newReceiver[2**m];
    component allLow[2**m];
    component ifThenElse[2**m];
    component computedRootFromNewReceiver[2**m];

    // initial state should be the current state at the start
    current_state === intermediate_roots[0];

    // checking all transactions
    for (var i = 0; i < 2**m ; i++) {

        // transaction existence and signature check
        txExistence[i] = TxExistence(m);
        txExistence[i].from_x <== from_x[i];
        txExistence[i].from_y <== from_y[i];
        txExistence[i].from_index <== from_index[i];
        txExistence[i].to_x <== to_x[i];
        txExistence[i].to_y <== to_y[i];
        txExistence[i].nonce <== nonce_from[i];
        txExistence[i].amount <== amount[i];
        txExistence[i].token_type_from <== token_type_from[i];

        txExistence[i].tx_root <== tx_root;

        for (var j = 0; j < m; j++) {
            txExistence[i].paths2_root_pos[j] <== paths2tx_root_pos[i][j];
            txExistence[i].paths2_root[j] <== paths2tx_root[i][j];
        }
        
        txExistence[i].R8x <== R8x[i];
        txExistence[i].R8y <== R8y[i];
        txExistence[i].S <== S[i];

        // sender existence check
        senderExistence[i] = BalanceExistence(n);
        senderExistence[i].x <== from_x[i];
        senderExistence[i].y <== from_y[i];
        senderExistence[i].token_balance <== token_balance_from[i];
        senderExistence[i].nonce <== nonce_from[i];
        senderExistence[i].token_type <== token_type_from[i];

        senderExistence[i].balance_root <== intermediate_roots[2*i];
        for (var j = 0; j < n; j++){
            senderExistence[i].paths2_root_pos[j] <== paths2root_from_pos[i][j];
            senderExistence[i].paths2_root[j] <== paths2_root_from[i][j];
        }

        // balance checks - TODO: add fees
        assert(token_balance_from[i] - amount[i] <= token_balance_from[i]);
        assert(token_balance_to[i] + amount[i] >= token_balance_to[i]);
        assert(nonce_from[i] != NONCE_MAX_VALUE);

        // check token types for non withdrawals
        ifBothHighForceEqual[i] = IfBothHighForceEqual();
        ifBothHighForceEqual[i].check1 <== to_x[i];  // If we are not sending to ZERO_ADDRESS, will force token types to be the same
        ifBothHighForceEqual[i].check2 <== to_y[i];
        ifBothHighForceEqual[i].a <== token_type_to[i];
        ifBothHighForceEqual[i].b <== token_type_from[i];

        // subtract amount from sender balance and increase sender nonce
        newSender[i] = BalanceLeaf();
        newSender[i].x <== from_x[i];
        newSender[i].y <== from_y[i];
        newSender[i].token_balance <== token_balance_from[i] - amount[i];
        newSender[i].nonce <== nonce_from[i] + 1;
        newSender[i].token_type <== token_type_from[i];

        // get intermediate root from new sender leaf
        computedRootFromNewSender[i] = GetMerkleRoot(n);
        computedRootFromNewSender[i].leaf <== newSender[i].out;
        for (var j = 0; j < n; j++) {
            computedRootFromNewSender[i].paths2_root[j] <== paths2_root_from[i][j];
            computedRootFromNewSender[i].paths2_root_pos[j] <== paths2root_from_pos[i][j];
        }

        //check that the intermediate root is consistent with input
        computedRootFromNewSender[i].out === intermediate_roots[2*i + 1];

        // receiver existence check in intermediate root from new sender
        receiverExistence[i] = BalanceExistence(n);
        receiverExistence[i].x <== to_x[i];
        receiverExistence[i].y <== to_y[i];
        receiverExistence[i].token_balance <== token_balance_to[i];
        receiverExistence[i].nonce <== nonce_to[i];
        receiverExistence[i].token_type <== token_type_to[i];

        receiverExistence[i].balance_root <== intermediate_roots[2*i + 1];
        for (var j = 0; j < n; j++) {
            receiverExistence[i].paths2_root[j] <== paths2_root_to[i][j];
            receiverExistence[i].paths2_root_pos[j] <== paths2root_to_pos[i][j] ;
        }

        // check receiver after incrementing
        newReceiver[i] = BalanceLeaf();
        newReceiver[i].x <== to_x[i];
        newReceiver[i].y <== to_y[i];

        // if receiver is zero address, do not change balance
        // otherwise add amount to receiver balance
        allLow[i] = AllLow(2);
        allLow[i].in[0] <== to_x[i];
        allLow[i].in[1] <== to_y[i];

        ifThenElse[i] = IfAThenBElseC();
        ifThenElse[i].aCond <== allLow[i].out;
        ifThenElse[i].bBranch <== token_balance_to[i];
        ifThenElse[i].cBranch <== token_balance_to[i] + amount[i];

        newReceiver[i].token_balance <== ifThenElse[i].out;
        newReceiver[i].nonce <== nonce_to[i];
        newReceiver[i].token_type <== token_type_to[i];

        // get intermediate root from new receiver leaf
        computedRootFromNewReceiver[i] = GetMerkleRoot(n);
        computedRootFromNewReceiver[i].leaf <== newReceiver[i].out;
        for (var j = 0; j < n; j++) {
            computedRootFromNewReceiver[i].paths2_root[j] <== paths2_root_to[i][j];
            computedRootFromNewReceiver[i].paths2_root_pos[j] <== paths2root_to_pos[i][j];
        }

        // check that intermediate root is consistent with input
        computedRootFromNewReceiver[i].out === intermediate_roots[2*i + 2];
    }

    out <== computedRootFromNewReceiver[2**m - 1].out;
    
}

component main {public [tx_root, current_state]} = ProcessTxs(4, 2);