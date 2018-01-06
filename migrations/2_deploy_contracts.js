var SingleTransferToken = artifacts.require("SingleTransferToken");

module.exports = function(deployer) {
  deployer.deploy(SingleTransferToken);
};
