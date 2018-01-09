// Specifically request an abstraction for SingleTransferToken
let SingleTransferToken = artifacts.require("SingleTransferToken");
import expectThrow from "zeppelin-solidity/test/helpers/expectThrow";

contract('SingleTransferToken#setup', accounts => {
  it("should set contract up with proper attributes", async () => {
    let meta = await SingleTransferToken.deployed();
    const name = await meta.name.call();
    const owner = await meta.ownerOf.call(1);
    const symbol = await meta.symbol.call();
    const totalSupply = await meta.totalSupply.call();
    const balance = await meta.balanceOf.call(accounts[0]);
    assert.equal(name, "Test", "Name was set incorrectly");
    assert.equal(owner, accounts[0], "Owner wasn't account one");
    assert.equal(symbol, "TT", "Symbol was set incorrectly");
    assert.equal(totalSupply, 1, "Total Supply wasn't 1");
    assert.equal(balance.valueOf(), 1, "1 wasn't in the first account");
  });
});
contract('SingleTransferToken#transferFns', accounts => {
  it("#transfer should transfer coin correctly", async () => {
    let meta = await SingleTransferToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let account_one_starting_balance = await meta.balanceOf.call(account_one);
    let account_two_starting_balance = await meta.balanceOf.call(account_two);
    let account_one_ending_balance;
    let account_two_ending_balance;

    let tokenId = 1;

    return meta.transfer(account_two, tokenId, {from: account_one}).then(() => {
      return meta.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance - 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + 1, "Amount wasn't correctly sent to the receiver");
    });
  });

  it("#transferFrom should transfer coin correctly", async () => {
    let meta = await SingleTransferToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];
    let account_three = accounts[2];

    let account_one_starting_balance = (await meta.balanceOf.call(account_one)).toNumber();
    let account_two_starting_balance = (await meta.balanceOf.call(account_two)).toNumber();
    let account_one_ending_balance;
    let account_two_ending_balance;

    let tokenId = 1;

    return meta.approve(account_one, tokenId, {from: account_two}).then(() => {
      meta.transferFrom(account_two, account_one, tokenId, {from: account_three});
    }).then(() => {
      return meta.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance + 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance - 1, "Amount wasn't correctly sent to the receiver");
    });
  });

  it("#takeOwnership should transfer coin correctly", async () => {
    let meta = await SingleTransferToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let account_one_starting_balance = (await meta.balanceOf.call(account_one)).toNumber();
    let account_two_starting_balance = (await meta.balanceOf.call(account_two)).toNumber();
    let account_one_ending_balance;
    let account_two_ending_balance;

    let tokenId = 1;

    return meta.approve(account_two, tokenId, {from: account_one}).then(() => {
      meta.takeOwnership(tokenId, {from: account_two});
    }).then(() => {
      return meta.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance - 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + 1, "Amount wasn't correctly sent to the receiver");
    });
  });
});
