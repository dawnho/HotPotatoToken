// Specifically request an abstraction for CelebrityToken
let CelebrityToken = artifacts.require("CelebrityToken");
// import expectThrow from "zeppelin-solidity/test/helpers/expectThrow";

contract('CelebrityToken#setup', accounts => {
  it("should set contract up with proper attributes", async () => {
    let meta = await CelebrityToken.deployed();
    const name = await meta.name.call();
    const symbol = await meta.symbol.call();
    const totalSupply = await meta.totalSupply.call();
    const balance = await meta.balanceOf.call(accounts[0]);
    assert.equal(name, "CryptoCelebrities", "Name was set incorrectly");
    assert.equal(symbol, "CelebrityToken", "Symbol was set incorrectly");
    assert.equal(totalSupply, 0, "Total Supply wasn't 0");
    assert.equal(balance.valueOf(), 0, "0 wasn't in the first account");
  });
});

contract('CelebrityToken#transferFns', accounts => {
  it("#transfer should transfer coin correctly", async () => {
    let meta = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let tokenId = 0;

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    return meta.createPromoPerson(accounts[0], "Bob", {from: account_one}).then(() => {
      return meta.balanceOf.call(account_one);
    }).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return meta.transfer(account_two, tokenId, {from: account_one});
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

  it("#transferFrom should transfer coin correctly", async () => {
    let meta = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];
    let account_three = accounts[2];

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    let tokenId = 0;

    return meta.balanceOf.call(account_one).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return meta.approve(account_one, tokenId, {from: account_two});
    }).then(() => {
      return meta.transferFrom(account_two, account_one, tokenId, {from: account_three});
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
    let meta = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    let tokenId = 0;

    return meta.balanceOf.call(account_one).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return meta.approve(account_two, tokenId, {from: account_one});
    }).then(() => {
      return meta.takeOwnership(tokenId, {from: account_two});
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
