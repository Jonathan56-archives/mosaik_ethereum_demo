var EnergyLib = artifacts.require("./Energy.sol");

module.exports = function(deployer) {
  deployer.deploy(EnergyLib);
};
