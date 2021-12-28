//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;

    }

    function getAllFacets() external view returns (Facet[] memory facets_);

    function facetFunctionSelectors(address _facetAddress) external view returns(bytes4 [] memory facetFunctionSelectors_);

    //function facetAddress() external view returns (address[] memory facetAddress_);

    //function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
