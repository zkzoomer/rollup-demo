// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// For our rollup contract we will be using the best SNARK hashing function, Poseidon.
// We will need to hash a different number of inputs for each case (always uint): 2, 5 or 8.

contract Poseidon2 {
    function poseidon(uint256[2] calldata) public pure returns(uint256) { } 
}

contract Poseidon4 {
    function poseidon(uint256[4] calldata) public pure returns(uint256) { } 
}

contract Poseidon5 {
    function poseidon(uint256[5] calldata) public pure returns(uint256) { } 
}


contract PoseidonMerkle {

    Poseidon2 public poseidon2;
    Poseidon4 public poseidon4;
    Poseidon5 public poseidon5;

    uint[16] public zeroCache = [
        14655542659562014735865511769057053982292279840403315552050801315682099828156,  //H0 = empty leaf
        17275449213996161510934492606295966958609980169974699290756906233261208992839,  //H1 = hash(H0, H0)
        14726732185301377694055836147998742577218505657530350941178791543526006846586,  //H2 = hash(H1, H1)
        12988208845277721051100143718644487453578123519232446209748947254348137166056,  //...and so on
        14968058171194073621279894200354949170268722034242224532403567996590872676126,
        8615460739809377184441412777719947554384977375428063175592285589143076086525,
        17517125834400843712650272236858095808688096369498525314272449367404266177422,
        2290268325899488232169207018500140876512210898783501305555057821275962186255,
        5116873551613691621174717210395847398776305081488269038167952634238575634751,
        21050503304019393343616794669701941453634016624480380810670518495510959330963,
        8113710104233924087413836855827281086202303705116397933747047506750005433768,
        20405370797557650101846758529041219701015233885317024354027190046680265967066,
        9391847671320267126571727380911180140742695253349488044679818629244886006613,
        16271418544906079482269144606193839734143510833917761320574442386464479126067,
        887340517592880241765377720067882006947543653708022397281398821810685106444,
        2027205362894749361615495674412935771962908091984992515156551985438321116324
    ];

    constructor(address _poseidon2, address _poseidon4, address _poseidon5) {
        poseidon2 = Poseidon2(_poseidon2);
        poseidon4 = Poseidon4(_poseidon4);
        poseidon5 = Poseidon5(_poseidon5);
    }

    function getRootFromProof(uint256 _leaf, uint256[] memory _position, uint256[] memory _proof) external view returns(uint256) {

        uint256[] memory root = new uint256[](_proof.length);

        if (_position[0] == 0) {  // left leaf
            root[0] = poseidon2.poseidon([_leaf, _proof[0]]);
        } else if (_position[0] == 1) {  // right leaf
            root[0] = poseidon2.poseidon([_proof[0], _leaf]);
        }

        for (uint256 i = 1; i < _proof.length; i++) {
            if (_position[i] == 0) {  // left leaf
                root[i] = poseidon2.poseidon([root[i - 1], _proof[i]]);
            } else if (_position[i] == 1) {  // right leaf
                root[i] = poseidon2.poseidon([_proof[i], root[i - 1]]);
            }
        }

        return root[root.length - 1];
        
    }

    function hashPoseidon(uint256[] calldata _array) external view returns(uint256) {

        uint nInputs = _array.length;
        uint poseidonHash;

        if (nInputs == 2) {

            uint256[2] memory array;
            for (uint256 i = 0; i < 2; i++) {
                array[i] = _array[i];
            }
            poseidonHash = poseidon2.poseidon(array);

        } else if (nInputs == 4) {

            uint256[4] memory array;
            for (uint256 i = 0; i < 4; i++) {
                array[i] = _array[i];
            }
            poseidonHash = poseidon4.poseidon(array);

        } else if (nInputs == 5) {

            uint256[5] memory array;
            for (uint256 i = 0; i < 5; i++) {
                array[i] = _array[i];
            }
            poseidonHash = poseidon5.poseidon(array);

        } else {
            revert("Length of array is not suppported");
        }

        return poseidonHash;
    }


}