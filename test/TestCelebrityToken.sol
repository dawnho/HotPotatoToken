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
}
