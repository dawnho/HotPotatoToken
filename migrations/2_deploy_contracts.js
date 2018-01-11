var CelebrityToken = artifacts.require("CelebrityToken");

module.exports = function(deployer, network) {
  if (network === "development") {
    deployer.deploy(CelebrityToken);
  } else {

  }
};
