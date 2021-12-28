//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

library LibDiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.storage");

    struct FacetItem{
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetItem) facets;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    function diamondStorage() internal pure returns(DiamondStorage storage ds){
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly{
            ds.slot := position
        }
    }
}
