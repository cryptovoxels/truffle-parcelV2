const Parcels = artifacts.require("Parcel");

module.exports = function (deployer) {
  deployer.deploy(Parcels);
};
