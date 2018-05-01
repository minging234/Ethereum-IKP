pragma solidity ^0.4.19;


contract RP {

    address private ikp;
 
    uint256 a = 5 ether; // affected-domain payout
    uint256 t = 5 ether; // termination payout
    uint256 delta = 5 ether; // detection payout \delta
    uint256 tau = 3 ether; // mininum amount that Domain is guaranteed to receive \tau
    uint256 m = 3 ether; // if detector reports misbehavior by an unregistered CA, it receives a smaller payout

	constructor (address _ikp) public {
	    ikp = _ikp;
	}

	function trigger (address detector, address domain, address issuerR, bool _internal, uint256 time) public payable {
		require(msg.sender == ikp);
		uint terminationFeeDomain = (t - tau) * time / 100 + tau;
		if (_internal) {
		    domain.transfer(a); // affected-domain payout
		    detector.transfer(delta); // detection payout
		    domain.transfer(terminationFeeDomain); // termination payout
		    issuerR.transfer(t - terminationFeeDomain); // termination payout
		}
		else {
		    detector.transfer(m); // detection payout
		    domain.transfer(terminationFeeDomain); // termination payout
		    issuerR.transfer(t - terminationFeeDomain); // termination payout
		}
		kill();
	}

    function terminate (address domain, address issuerR, uint256 time) public payable {
    	require(msg.sender == ikp);
		uint terminationFeeDomain = (t - tau) * time / 100 + tau;
		domain.transfer(terminationFeeDomain); // termination payout
		issuerR.transfer(t - terminationFeeDomain); // termination payout
		kill();
    } 

    function expire (address issuerR) public payable {
    	require(msg.sender == ikp);
        issuerR.transfer(t); // termination payout
        kill();
    }

    function kill () private {
        selfdestruct(ikp);
    }

}