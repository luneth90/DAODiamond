//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.10;
pragma abicoder v2;

import './IDiamondCut.sol';
import './LibDiamondStorage.sol';
import  './LibDiamond.sol';
import "./LibOwnership.sol";
import "./IERC165.sol";
import "./IERC173.sol";
import "./IDiamondCut.sol";
import "./IDiamondLoupe.sol";

contract Dao{
    constructor(IDiamondCut.FacetCut[] memory _diamondCut, address _owner) payable {
        require(_owner != address(0),"owner must not be 0x0");
        LibDiamond.diamondCut(_diamondCut,address(0),new bytes(0));
        LibOwnership.setContractOwner(_owner);
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    }

     fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        address facet = address(bytes20(ds.facets[msg.sig].facetAddress));
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
