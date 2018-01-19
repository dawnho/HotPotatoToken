const Web3 = require('web3');
const Accounts = require('web3-eth-accounts');
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");

const fs = require('fs');
const path = require('path');
const jsonPath = path.join(__dirname, '..', 'build', 'contracts', 'CelebrityToken.json');
const contractInterface = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

let contract = new web3.eth.Contract(contractInterface['abi']);

let accounts = new Accounts('ws://localhost:8546');

console.log(accounts);
