pragma solidity ^0.4.0;


import "./BytesLib.sol";

library X509 {

    using BytesLib for bytes;

    function getDName (bytes cert) public pure returns (bytes) {
        bytes memory certSeq = getValue(getValue(cert));
        bytes memory subjectName = getValue(tlvSeqAccess(certSeq, 6));
        uint8[5] memory commonName = [0x06, 0x03, 0x55, 0x04, 0x03];
        bytes memory nameSeq;
        bytes memory rest;
        (nameSeq, rest) = popTLV(subjectName);
        while (nameSeq.length > 0) {
            bytes memory oid;
            bytes memory str;
            (oid, str) = popTLV(getValue(getValue(nameSeq)));
            bool ok = true;
            for (uint i = 0; i < 5; i++) {
                if (uint8(oid[i]) != commonName[i]) {
                    ok = false;
                    break;
                }
            }
            if (oid.length != 5 || !ok) {
                (nameSeq, rest) = popTLV(rest);
                continue;
            }
            return getValue(str);
        }
        require(false);
    }

    function getCName (bytes cert) public pure returns (bytes) {
        bytes memory certSeq = getValue(getValue(cert));
        bytes memory issuerName = getValue(tlvSeqAccess(certSeq, 4));
        uint8[5] memory commonName = [0x06, 0x03, 0x55, 0x04, 0x03];
        bytes memory nameSeq;
        bytes memory rest;
        (nameSeq, rest) = popTLV(issuerName);
        uint j = 0;
        while (nameSeq.length > 0) {
            bytes memory oid;
            bytes memory str;
            (oid, str) = popTLV(getValue(getValue(nameSeq)));
            bool ok = true;
            for (uint i = 0; i < 5; i++) {
                if (uint8(oid[i]) != commonName[i]) {
                    ok = false;
                    break;
                }
            }
            if (oid.length != 5 || !ok) {
                (nameSeq, rest) = popTLV(rest);
                j += 1;
                continue;
            }
            return getValue(str);
        }
        require(false);
    }

    function tlvSeqAccess (bytes tlvs, uint n) private pure returns (bytes) {
        uint pos = 0;
        uint st = 0;
        for (uint i = 0; i < n; i++) {
            if (i == n-1) {
                st = pos;
            }
            require(tlvs.length > pos + 2);
            if (tlvs[pos+1] > 0x80) {
                uint lenlen = uint(tlvs[pos+1]) - 0x80;
                require(tlvs.length > pos + 2 + lenlen);
                uint len = bytesToUint(tlvs.slice(pos+2, lenlen));
                require(tlvs.length >= pos + 2 + lenlen + len);
                pos += 2 + lenlen + len;
            } else if (tlvs[pos+1] < 0x80) {
                require(tlvs.length >= pos + 2 + uint(tlvs[pos+1]));
                pos += 2 + uint(tlvs[pos+1]);
            } else {
                bool bad = true;
                for (uint j = pos + 2; j < tlvs.length-1; j++) {
                    if (tlvs[j] == 0x00 && tlvs[j+1] == 0x00) {
                        pos = j + 2;
                        bad = false;
                        break;
                    }
                }
                if (bad) {
                    require(false);
                }
            }
        }
        return tlvs.slice(st, pos-st);
    }

    function popTLV (bytes tlvs) private pure returns (bytes, bytes) {
        require(tlvs.length > 2);
        if (tlvs[1] > 0x80) {
            uint lenlen = uint(tlvs[1]) - 0x80;
            require(tlvs.length > 2 + lenlen);
            uint len = bytesToUint(tlvs.slice(2, lenlen));
            require(tlvs.length >= 2 + lenlen + len);
            return (tlvs.slice(0, 2+lenlen+len),
                    tlvs.slice(2+lenlen+len, tlvs.length-(2+lenlen+len)));
        }
        if (tlvs[1] < 0x80) {
            require(tlvs.length >= 2 + uint(tlvs[1]));
            return (tlvs.slice(0, 2+uint(tlvs[1])),
                    tlvs.slice(2+uint(tlvs[1]), tlvs.length-(2+uint(tlvs[1]))));
        }
        for (uint i = 2; i < tlvs.length-1; i++) {
            if (tlvs[i] == 0x00 && tlvs[i+1] == 0x00) {
                return (tlvs.slice(0, i+2),
                        tlvs.slice(i+2, tlvs.length-(i+2)));
            }
        }
        require(false);
    }

    function getValue (bytes tlv) private pure returns (bytes) {
        require(tlv.length > 2);
        if (tlv[1] > 0x80) {
            uint lenlen = uint(tlv[1]) - 0x80;
            require(tlv.length > 2 + lenlen);
            uint len = bytesToUint(tlv.slice(2, lenlen));
            require(tlv.length >= 2 + lenlen + len);
            return tlv.slice(2+lenlen, len);
        }
        if (tlv[1] < 0x80) {
            require(tlv.length >= 2 + uint(tlv[1]));
            return tlv.slice(2, uint(tlv[1]));
        }
        for (uint i = 2; i < tlv.length-1; i++) {
            if (tlv[i] == 0x00 && tlv[i+1] == 0x00) {
                return tlv.slice(2, i-2);
            }
        }
        require(false);
    }

    function bytesToUint (bytes b) private pure returns (uint u) {
        require(b.length <= 32);
        bytes32 tmp;
        for (uint i = 0; i < b.length; i++) {
            tmp |= bytes32(b[i] & 0xFF) >> ((32-b.length+i) * 8);
        }
        return uint(tmp);
    }

}

contract CheckContract {

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