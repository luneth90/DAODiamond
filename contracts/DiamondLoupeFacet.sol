//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
pragma abicoder v2;

import "hardhat/console.sol";
import "./IDiamondLoupe.sol";
import "./LibDiamondStorage.sol";
import "./IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165{

    function getAllFacets() external view returns (Facet[] memory facets_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        facets_ = new Facet[](selectorCount);
        uint8[] memory numSelectorsOfFacet = new uint8[](selectorCount); 
        uint256 numFacets;

        bool exist;
        
        for(uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++){
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress = ds.facets[selector].facetAddress;
            exist = false;
            for(uint256 facetIndex; facetIndex < selectorCount; facetIndex++){
                address _facetAddress = facets_[facetIndex].facetAddress;
                if (facetAddress == _facetAddress) {
                    facets_[facetIndex].functionSelectors[numSelectorsOfFacet[facetIndex]] = selector;
                    numSelectorsOfFacet[facetIndex]++;
                    exist = true;
                    break;
                }
            }
            if(!exist) {
                facets_[numFacets].facetAddress = facetAddress;
                facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numSelectorsOfFacet[numFacets] = 1;
                numFacets++;
            }
        }

        for(uint256 facetIndex; facetIndex < selectorCount; facetIndex++){
            uint256 numSelectors = numSelectorsOfFacet[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            assembly {
                mstore(selectors,numSelectors)
            }
        }

        assembly {
            mstore(facets_, numFacets)
        }
    

    }

    function facetFunctionSelectors(address _facetAddress) external view returns(bytes4 [] memory facetFunctionSelectors_){
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        facetFunctionSelectors_ = new bytes4[](selectorCount);
        uint256 numSelectors;
        for(uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++){
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress = ds.facets[selector].facetAddress;
            if(facetAddress == _facetAddress){
                facetFunctionSelectors_[numSelectors] = selector;
                numSelectors++;
            }
        }
        assembly {
            mstore(facetFunctionSelectors_,numSelectors)
        }

    }

    function supportsInterface(bytes4 _interfaceId) external view returns(bool isSupport_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        isSupport_ = ds.supportedInterfaces[_interfaceId];
    }
}
