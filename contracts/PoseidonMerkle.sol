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

    // TODO: to be filled
    uint[16] public zeroCache = [
        1, //H0 = empty leaf
        2,  //H1 = hash(H0, H0)
        3,  //H2 = hash(H1, H1)
        4, //...and so on
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16
    ];

    constructor(address _poseidon2, address _poseidon4, address _poseidon5) {
        poseidon2 = Poseidon2(_poseidon2);
        poseidon4 = Poseidon4(_poseidon4);
        poseidon5 = Poseidon5(_poseidon5);
    }

    function getRootFromProof(uint256 _leaf, uint256[] memory _position, uint256[] memory _proof) public view returns(uint256) {

        uint256[] memory root = new uint256[](_proof.length);

        if (_position[0] == 0) {  // left leaf
            root[0] = poseidon2.poseidon([_leaf, _proof[0]]);
        } else if (_position[0] == 1) {  // right leaf
            root[0] = poseidon2.poseidon([_proof[0], _leaf]);
        }

        for (uint256 i = 1; i < _proof.length; i++) {
            if (_position[i] == 0) {  // left leaf
                root[i] = poseidon2.poseidon([root[i - 1], _proof[i]]);
            } else if (_position[0] == 1) {  // right leaf
                root[i] = poseidon2.poseidon([_proof[i], root[i - 1]]);
            }
        }

        return root[root.length - 1];
        
    }

    function hashPoseidon(uint256[] calldata _array) public view returns(uint256) {

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