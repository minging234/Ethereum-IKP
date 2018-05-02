import ikp_artifacts from '../../build/contracts/RIKP.json';
import dcp_artifacts from '../../build/contracts/DCP.json';
import rp_artifacts from '../../build/contracts/RP.json';

var IKP = contract(ikp_artifacts);
var DCP = contract(dcp_artifacts);
var RP = contract(rp_artifacts);

var account = 0xC55F5005e1AD3FB49734b50885105Ce6e0158CF1;

contract("IKP", function () {
	it("should register domain correctly.", function () {
		var ikp;
		var dcp;
		IKP.deployed().then(function (instance) {
			ikp = instance;
			return DCP.deployed();
		}).then(function(instance) {
			dcp = instance;
			ikp.domainRegister.call(web3.toHex("www.google.com"), dcp.address, 5, {from: account, value: web3.toWei(1, "ether")});
		});
	});
});