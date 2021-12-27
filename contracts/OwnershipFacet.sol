//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.10;
pragma abicoder v2;

import "./LibOwnership.sol";
import "./IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external {
        LibOwnership.enforceIsContractOwner();
        LibOwnership.setContractOwner(_newOwner);
    }

    function owner() external view returns(address owner_){
        owner_ = LibOwnership.contractOwner();
    }
}
