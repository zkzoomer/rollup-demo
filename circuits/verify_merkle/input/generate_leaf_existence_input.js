const fs = require("fs");
const poseidon = require("../../helpers/poseidon.js");
const poseidonMerkle = require('./poseidonMerkle.js')

// Using BigInt to avoid a TypeError in the poseidon hash function
const leaf1 = poseidon([BigInt(1),BigInt(2),BigInt(3)])
const leaf2 = poseidon([BigInt(4),BigInt(5),BigInt(6)])
const leaf3 = poseidon([BigInt(7),BigInt(8),BigInt(9)])
const leaf4 = poseidon([BigInt(9),BigInt(8),BigInt(7)])
const leafArray = [leaf1,leaf2,leaf3,leaf4]
console.log(leafArray)
const tree = poseidonMerkle.treeFromLeafArray(leafArray)
console.log(tree)
const root = tree[0][0];
const leaf1Proof = poseidonMerkle.getProof(0, tree, leafArray)
const leaf1Pos = [0, 0]

const inputs = {
    "leaf": leaf1.toString(),
    "root": root.toString(),
    "paths2_root": [leaf1Proof[0].toString(),leaf1Proof[1].toString()],
    "paths2_root_pos": [leaf1Pos[0].toString(), leaf1Pos[1].toString()],
}

fs.writeFileSync(
    "./input.json",
    JSON.stringify(inputs),
    "utf-8"
);

// LEFT:
// Suspected bug in getProof, not found to have any effect tho