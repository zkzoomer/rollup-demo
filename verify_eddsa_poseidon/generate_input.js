const fs = require("fs");
const eddsa = require("../helpers/eddsa.js");
const poseidon = require("../helpers/poseidon.js");

// Using BigInt to avoid TypeError in the multiHash function below
const preimage = [BigInt(123),BigInt(456),BigInt(789)];
const M = poseidon(preimage);
const prvKey = Buffer.from('1'.toString().padStart(64,'0'), "hex");
const pubKey = eddsa.prv2pub(prvKey);
const signature = eddsa.signPoseidon(prvKey, M);

const inputs = {
    "from_x": pubKey[0].toString(),
    "from_y": pubKey[1].toString(),
    "R8x": signature['R8'][0].toString(),
    "R8y": signature['R8'][1].toString(),
    "S": signature['S'].toString(),
    "M": M.toString()
}

fs.writeFileSync(
    "./input.json",
    JSON.stringify(inputs),
    "utf-8"
);