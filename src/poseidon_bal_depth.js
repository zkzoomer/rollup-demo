const poseidon = require("./poseidon.js");
const mimcjs = require("./mimc7.js");
const Account = require("./account.js");

const zeroCache = [];

// We will get a tree of height 16
const height = 16;

const zeroAccount = new Account();
const zeroHash = zeroAccount.hashAccount()
zeroCache.push(zeroHash.toString());

for (var i = 1; i < height; i++) {
    zeroCache.push(poseidon(
        [zeroCache[i-1], zeroCache[i-1]]
    ).toString())
} 

console.log(zeroCache);