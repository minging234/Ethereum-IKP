pragma solidity ^0.4.0;


import "./X509.sol";

contract DCP {

    address approvedCA; // this time we only use 1 CA as its origin issuer
    bytes domainName;
    
    constructor (bytes _CA) public {
        domainName = _CA;  // the approvedCA
    }
    
    function check (bytes cert) public view returns(bool) { 
        bytes memory cname = X509.getCName(cert);
        if (keccak256(cname) != keccak256(approvedCA)) {
            return false;
        }
        return true;
    }

}