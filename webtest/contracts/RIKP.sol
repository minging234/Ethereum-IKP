pragma solidity ^0.4.19;


import "./X509.sol";

contract RIKP {

    using BytesLib for bytes;

    struct CA {
        bytes name; // identify CA
        uint validFrom; // specify start period of information validity
        address payout; // authenticate and receive payments to CA
        address[] pubKeys; // list of CA’s public keys
        address[] updateAddrs; // (default empty) authorize updates to this information
        uint updateThold; // (default 1) threshold of payout/update addrs. for updates
    }

    struct DCP {
        bytes domainName; // identify domain for which the policy is active
        uint validFrom; // specify start period of DCP’s validity
        uint version; // identify version of this domain’s DCP
        address payout; // authenticate and receive payments for domain
        DCPChecker checker; // address of the DCP’s check contract
        address[] updateAddrs; // (default empty) authorize DCP updates
        uint updateThold; // (default 1) threshold of payout/update addrs. for DCP updates
    }

    struct RP {
        bytes domainName; // identify domain for which the RP is active
        bytes issuer; // CA who issued the RP
        uint validFrom; // specify start period of RP’s validity
        uint validTo; // specify end period of RP’s validity
        uint version; // version of domain’s DCP used to trigger RP
        RPReaction reaction; // address of the RP’s reaction contract
    }

    struct RPEscrow {
        bytes issuer;
        uint escrow;
    }

    struct CertEscrow {
        bytes issuer;
        uint escrow;
    }

    uint m = 5 ether; // report fee
    uint revokeFee = 1 ether; // revoke fee
    uint rpEscrowLimit = 15 ether; // RP escrow
    uint dregisterFee = 1 ether; // Domain register fee
    uint cregisterFee = 1 ether; // CA register fee
    uint updateFee = 1 ether; // update fee

    /* address private escrow; */
    mapping(bytes => CA) private cas;
    mapping(bytes => uint) private caBalances;
    /* mapping(address => uint) private domainBalances; */
    mapping(bytes => DCP) private dcps;
    mapping(bytes => RP[]) private rps;
    /* CA[] public cas; */
    mapping(bytes32 => RPEscrow) private rpEscrows;
    /* mapping(bytes32 => CertEscrow) private certEscrows; */
    mapping(bytes32 => address) private coms;
    mapping (bytes32 => bool) private crl;
    

    constructor () public {
        /* escrow = msg.sender; */
    }

    function caRegister (bytes _name, address[] _pubs, address[] _updates, uint _threshold) public payable {
        require(cas[_name].validFrom == 0 && msg.value >= cregisterFee);
        cas[_name] = CA({
            name: _name,
            validFrom: now,
            payout: msg.sender,
            pubKeys: _pubs,
            updateAddrs: _updates,
            updateThold: _threshold
        });
        caBalances[_name] = msg.value;
    }

    function caUpdate (bytes _name, address _payout, address[] _pubs, address[] _updates) public payable {
        require(cas[_name].updateThold > 0 && msg.value == updateFee);
        for (uint i = 0; i < cas[_name].updateAddrs.length; i++) {
            if (cas[_name].updateAddrs[i] == msg.sender) {
                cas[_name].payout = _payout;
                cas[_name].pubKeys = _pubs;
                cas[_name].updateAddrs = _updates;
                cas[_name].updateThold -= 1;
                return;
            }
        }
        require (false);
    }

    function showBalance (bytes _caName) public view returns (uint res) {
        return caBalances[_caName];
    }
    
    function withdrawl (bytes _caName, uint _amount) public {
        require(cas[_caName].payout == msg.sender && caBalances[_caName] - cregisterFee >= _amount);
        cas[_caName].payout.transfer(_amount);
        caBalances[_caName] -= _amount;
    }
    
    function domainRegister (bytes _name, address _chk, address[] _updates, uint _threshold) public payable {
        require(dcps[_name].validFrom == 0 && msg.value == dregisterFee);
        dcps[_name] = DCP({
            domainName: _name,
            validFrom: now,
            version: 1,
            payout: msg.sender,
            checker: DCPChecker(_chk),
            updateAddrs: _updates,
            updateThold: _threshold
        });
    }

    function domainUpdate (bytes _name, address _payout, address _chk, address[] _updates) public payable {
        require(dcps[_name].updateThold > 0 && msg.value == updateFee);
        for (uint i = 0; i < dcps[_name].updateAddrs.length; i++) {
            if (dcps[_name].updateAddrs[i] == msg.sender) {
                dcps[_name].payout = _payout;
                if (_chk != address(dcps[_name].checker)) {
                    dcps[_name].checker = DCPChecker(_chk);
                    dcps[_name].version += 1;
                }
                dcps[_name].updateAddrs = _updates;
                dcps[_name].updateThold -= 1;
                return;
            }
        }
        require (false);
    }

    function rpPurchase (bytes32 _rpHash, bytes _issuer) public payable {
        rpEscrows[_rpHash] = RPEscrow({issuer:_issuer, escrow:msg.value});
    }

    function rpIssue (bytes _domainName, bytes _issuer, uint _validFrom, uint _validTo, uint _version, address _reaction) public payable {
        require(msg.value >= rpEscrowLimit);
        bytes32 rpHash = keccak256(_domainName, _issuer, _validFrom,
                                    _validTo, _version, _reaction);
        require((keccak256(_issuer) == keccak256(rpEscrows[rpHash].issuer)) &&
                (msg.sender == cas[_issuer].payout) && dcps[_domainName].validFrom != 0);
        RP memory rp = RP({domainName: _domainName,
                    issuer: _issuer,
                    validFrom: _validFrom,
                    validTo: _validTo,
                    version: _version,
                    reaction: RPReaction(_reaction)});
        uint i;
        for (i = 0; i < rps[_domainName].length; i++) {
            if (rps[_domainName][i].validTo > _validTo) i++;
            else break;
        }
        if (i == rps[_domainName].length) {
            rps[_domainName].push(rp);
        } else {
            rps[_domainName].push(rps[_domainName][rps[_domainName].length - 1]);
            for (uint j = rps[_domainName].length - 1; j > i; j--) {
                rps[_domainName][j] = rps[_domainName][j-1];
            }
            rps[_domainName][i] = rp;
        }
        caBalances[_issuer] += msg.value;
        msg.sender.transfer(rpEscrows[rpHash].escrow);
    }

    /* function certPurchase(bytes32 certHash, bytes issuer) public payable {
        certEscrows[certHash] = CertEscrow({issuer:issuer, escrow:msg.value});
    }

    function certIssue(bytes cert) public {
        bytes32 certHash = keccak256(cert);
        require(msg.sender == cas[certEscrows[certHash].issuer].payout);
        msg.sender.transfer(rpEscrows[keccak256(cert)].escrow);
    } */

    function reportCommit (bytes32 com) public payable {
        require(msg.value == m);
        coms[com] = msg.sender;
    }

    function reportReveal (bytes cert, bytes secret) public {
        require(coms[keccak256(cert, secret)] == msg.sender);
        bytes memory dname = X509.getDName(cert);
        while (rps[dname].length > 0) {
            if (rps[dname][rps[dname].length-1].validTo < now || rps[dname][rps[dname].length-1].version != dcps[dname].version) {
                rps[dname][rps[dname].length-1].reaction.expire.value(rpEscrowLimit)(cas[rps[dname][rps[dname].length-1].issuer].payout);
                caBalances[rps[dname][rps[dname].length-1].issuer] -= rpEscrowLimit;
                delete(rps[dname][rps[dname].length-1]);
                rps[dname].length -= 1;
                continue;
            }
            break;
        }
        if (rps[dname].length == 0 || crl[keccak256(cert)]) {
            msg.sender.transfer(m);
            return;
        }
        if (dcps[dname].checker.check(cert)) {
            return;
        }
        bytes memory cname = X509.getCName(cert);
        bool _internal = true;
        if (cas[cname].validFrom == 0) {
            _internal = false;
        }
        uint time = (rps[dname][rps[dname].length-1].validTo - now) * 100 / (rps[dname][rps[dname].length-1].validTo - rps[dname][rps[dname].length-1].validFrom);
        rps[dname][rps[dname].length-1].reaction.trigger.value(rpEscrowLimit)(msg.sender, dcps[dname].payout,
                                                                              cas[rps[dname][rps[dname].length-1].issuer].payout,
                                                                              _internal, time);
        caBalances[rps[dname][rps[dname].length-1].issuer] -= rpEscrowLimit;
        delete(rps[dname][rps[dname].length-1]);
        rps[dname].length -= 1;
    }

    function terminateRP (bytes32 rpHash, bytes domain) public returns (bool) {
        require(dcps[domain].payout == msg.sender);
        uint i;
        for (i = 0; i < rps[domain].length; i++) {
            bytes32 tmpRPHash = keccak256(rps[domain][i].domainName, rps[domain][i].issuer,
                                          rps[domain][i].validFrom, rps[domain][i].validTo,
                                          rps[domain][i].version, address(rps[domain][i].reaction));
            if (tmpRPHash == rpHash) {
                uint time = (rps[domain][i].validTo - now) * 100 / (rps[domain][i].validTo - rps[domain][i].validFrom);
                rps[domain][i].reaction.terminate.value(rpEscrowLimit)(dcps[domain].payout, cas[rps[domain][i].issuer].payout, time);
                break;
            }
        }
        require(i != rps[domain].length);
        for (uint j = i; j < rps[domain].length-1; j++) {
            rps[domain][j] = rps[domain][j+1];
        }
        delete(rps[domain][rps[domain].length-1]);
        rps[domain].length -= 1;
    }
    

    function revoke (bytes cert) public payable {
        require(msg.value == revokeFee);
        bytes memory cname = X509.getCName(cert);
        require(cas[cname].payout == msg.sender);
        crl[keccak256(cert)] = true;
    }

    function isRevoked (bytes cert) public view returns (bool) {
        return crl[keccak256(cert)];
    }

}
