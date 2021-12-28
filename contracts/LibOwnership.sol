//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
pragma  abicoder v2;

import "./LibDiamondStorage.sol";

library LibOwnership {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal{
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        address previousOwner = ds.contractOwner;
        require(previousOwner != _newOwner, "Must be different");
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner,_newOwner);
    }

    function contractOwner() internal view returns(address contractOwner_) {
        contractOwner_ = LibDiamondStorage.diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view{
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner,"Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner,"Must be contract owner");
        _;
    }
}


