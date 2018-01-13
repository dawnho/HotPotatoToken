pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CelebrityToken.sol";


contract TestCelebrityToken {
  function testInitialBalanceUsingDeployedContract() public {
    CelebrityToken celeb = CelebrityToken(DeployedAddresses.CelebrityToken());

    uint expected = 0;

    Assert.equal(celeb.balanceOf(msg.sender), expected, "Owner should have 0 tokens initially");
  }

  function testInitialBalanceUsingCreatingPromoPerson() public {
    CelebrityToken celeb = CelebrityToken(DeployedAddresses.CelebrityToken());

    celeb.createPromoPerson(address(0), "Bobby");

    uint expected = 1;

    Assert.equal(celeb.balanceOf(msg.sender), expected, "Owner should have 0 tokens initially");
  }
}
