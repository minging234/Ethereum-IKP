var Greeter = artifacts.require("./Greeter.sol");
var DCP= artifacts.require("./DCP.sol");
var IKP = artifacts.require("./RIKP.sol");
var RP = artifacts.require("./RP.sol");
var BLib = artifacts.require("./BytesLib.sol");
var X509 = artifacts.require("./X509.sol")

module.exports = function(deployer) {
  deployer.deploy(Greeter);
  deployer.deploy(BLib);
  deployer.link(BLib, X509);
  deployer.deploy(X509);
  deployer.link(X509, [IKP, DCP]);
  deployer.deploy(DCP, "InCommon RSA Server CA");
  deployer.deploy(IKP).then(function (instance) {
  	return instance, deployer.deploy(RP, IKP.address);
  });
};
