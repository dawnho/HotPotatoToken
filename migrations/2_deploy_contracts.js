var CelebrityToken = artifacts.require("CelebrityToken");

module.exports = function(deployer, network) {
  if (network === "development") {
    deployer.deploy(CelebrityToken, 1, 2000);
  } else {

  }
};
