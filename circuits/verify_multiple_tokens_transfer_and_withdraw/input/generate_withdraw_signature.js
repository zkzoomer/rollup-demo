const eddsa = require("../../../src/eddsa.js");
const snarkjs = require("snarkjs");
const fs = require("fs");
const poseidon = require("../../../src/poseidon.js");
const {stringifyBigInts, unstringifyBigInts} = require('../../../src/stringifybigint.js')

var prvKey = Buffer.from("4".padStart(64,'0'), "hex");

var pubKey = eddsa.prv2pub(prvKey);

var nonce = 0;
var txRoot = BigInt('14053325031894235002744541221369412510941171790893507881802249870625790656164')
var recipient = BigInt('0xC33Bdb8051D6d2002c0D80A1Dd23A1c9d9FC26E4');
var m = poseidon([nonce, recipient])

var signature = eddsa.signPoseidon(prvKey, m);

var verify = eddsa.verifyPoseidon(m, signature, pubKey)
console.log(verify)

const inputs = {
    Ax: stringifyBigInts(pubKey[0]),
    Ay: stringifyBigInts(pubKey[1]),
    R8x: stringifyBigInts(signature.R8[0]),
    R8y: stringifyBigInts(signature.R8[1]),
    S: stringifyBigInts(signature.S),
    M: stringifyBigInts(m)
}

fs.writeFileSync(
    "withdraw_input.json",
    JSON.stringify(inputs, (key, value) => 
        typeof value === 'bigint'
            ? value.toString() 
            : value // return everything else unchanged
    ),
    "utf-8"
);