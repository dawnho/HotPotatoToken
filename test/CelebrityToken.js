// Specifically request an abstraction for CelebrityToken
let CelebrityToken = artifacts.require("CelebrityToken");
import expectThrow from "zeppelin-solidity/test/helpers/expectThrow";

contract('CelebrityToken#setup', accounts => {
  it("should set contract up with proper attributes", async () => {
    let celeb = await CelebrityToken.deployed();
    const name = await celeb.name.call();
    const symbol = await celeb.symbol.call();
    const totalSupply = await celeb.totalSupply.call();
    const balance = await celeb.balanceOf.call(accounts[0]);
    assert.equal(name, "CryptoCelebrities", "Name was set incorrectly");
    assert.equal(symbol, "CelebrityToken", "Symbol was set incorrectly");
    assert.equal(totalSupply, 0, "Total Supply wasn't 0");
    assert.equal(balance.valueOf(), 0, "0 wasn't in the first account");
  });
});

contract('CelebrityToken#transferFns', accounts => {
  it("#transfer should transfer coin correctly", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let tokenId = 0;

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    return celeb.createPromoPerson(accounts[0], "Bob", {from: account_one}).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return celeb.transfer(account_two, tokenId, {from: account_one});
    }).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance - 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + 1, "Amount wasn't correctly sent to the receiver");
    });
  });

  it("#transferFrom should transfer coin correctly", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];
    let account_three = accounts[2];

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    let tokenId = 0;

    return celeb.balanceOf.call(account_one).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return celeb.approve(account_one, tokenId, {from: account_two});
    }).then(() => {
      return celeb.transferFrom(account_two, account_one, tokenId, {from: account_three});
    }).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance + 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance - 1, "Amount wasn't correctly sent to the receiver");
    });
  });

  it("#takeOwnership should transfer coin correctly", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    let tokenId = 0;

    return celeb.balanceOf.call(account_one).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return celeb.approve(account_two, tokenId, {from: account_one});
    }).then(() => {
      return celeb.takeOwnership(tokenId, {from: account_two});
    }).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance - 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + 1, "Amount wasn't correctly sent to the receiver");
    });
  });
});

contract('CelebrityToken#purchaseFns', accounts => {
  it("#purchase should operate correctly and update price", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let tokenId = 0;

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    let token_starting_price;
    let token_ending_price;

    return celeb.createPromoPerson(accounts[0], "Bob", {from: account_one}).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return celeb.priceOf.call(tokenId);
    }).then(price => {
      token_starting_price = price.toNumber();
      return celeb.purchase(tokenId, {from: account_two, value: 100000000000000000});
    }).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      return celeb.priceOf.call(tokenId);
    }).then(price => {
      token_ending_price = price.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance - 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + 1, "Amount wasn't correctly sent to the receiver");
      assert.equal(token_ending_price, parseInt(token_starting_price * 200 / 94), "Price didn't scale right");
    });
  });
  it("#purchasing again should operate correctly", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let tokenId = 0;

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    let token_starting_price;
    let token_ending_price;

    return celeb.balanceOf.call(account_one).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_starting_balance = balance.toNumber();
      return celeb.priceOf.call(tokenId);
    }).then(price => {
      token_starting_price = price.toNumber();
      return celeb.purchase(tokenId, {from: account_one, value: 100000000000000000});
    }).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      return celeb.balanceOf.call(account_two);
    }).then(balance => {
      account_two_ending_balance = balance.toNumber();
      return celeb.priceOf.call(tokenId);
    }).then(price => {
      token_ending_price = price.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance + 1, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance - 1, "Amount wasn't correctly sent to the receiver");
      assert.equal(token_ending_price, parseInt(token_starting_price * 200 / 94), "Price didn't scale right");
    });
  });
  it("#purchasing again with too low price should not work", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first and second account.
    let account_one = accounts[0];
    let account_two = accounts[1];

    let tokenId = 1;

    return celeb.createPromoPerson(accounts[0], "Kid", {from: account_one}).then(() => {
      return expectThrow(celeb.purchase(tokenId, {from: account_two, value: 1}));
    })
  });
});
contract('CelebrityToken#createFns', accounts => {
  it("#createContractPerson tokens should be purchaseable", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first account.
    let account_one = accounts[0];

    let tokenId = 0;

    let account_one_starting_balance;
    let account_one_ending_balance;

    return celeb.createContractPerson("Bobby", {from: account_one}).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return celeb.purchase(tokenId, {from: account_one, value: 1000000000000000});
    }).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance + 1, "Amount wasn't correctly taken from the sender");
    });
  });
  it("#createContractPerson with null address should assign to coo", async () => {
    let celeb = await CelebrityToken.deployed();

    // Get initial balances of first account.
    let account_one = accounts[0];

    let tokenId = 1;

    let account_one_starting_balance;
    let account_one_ending_balance;

    return celeb.balanceOf.call(account_one).then(balance => {
      account_one_starting_balance = balance.toNumber();
      return celeb.createPromoPerson(null, "Bobby", {from: account_one});
    }).then(() => {
      return celeb.balanceOf.call(account_one);
    }).then(balance => {
      account_one_ending_balance = balance.toNumber();
      assert.equal(account_one_ending_balance, account_one_starting_balance + 1, "Amount wasn't correctly taken from the sender");
    });
  });
});
