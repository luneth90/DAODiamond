//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "./IDiamondCut.sol";
import "./LibDiamondStorage.sol";
import "hardhat/console.sol";

library LibDiamond {
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCutInit(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata) internal{
            uint256 selectorCount =LibDiamondStorage.diamondStorage().selectors.length;
            
            for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex ++) {
                selectorCount = executeDiamondCut(selectorCount, _diamondCut[facetIndex]);
            }
            emit DiamondCut(_diamondCut,_init,_calldata);
            initializeDiamondCut(_init, _calldata);
    }

    function executeDiamondCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256 selectorCount_) {
        if (cut.action == IDiamondCut.FacetCutAction.Add) {
            require(cut.facetAddress != address(0), "error");
            enforceHasContractCode(cut.facetAddress, "no code");

            selectorCount_ = _handleAddCut(selectorCount,cut);
        }
    }

    function _handleAddCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256 selectorCount_){
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        for(uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex ++){
            bytes4 selector = cut.functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facets[selector].facetAddress;
            require(oldFacetAddress == address(0),"Can not add , already exists.");

            ds.facets[selector] = LibDiamondStorage.FacetItem(
                cut.facetAddress,
                uint16(selectorCount)
            ); 
            ds.selectors.push(selector);
            selectorCount ++;
        }
        selectorCount_ = selectorCount;
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0,"empty");
            return;
        }

        require(_calldata.length >0, "empyt");
        if (_init != address(this)) {
            enforceHasContractCode(_init , "no code");
        }

        (bool sucess, bytes memory error) = _init.delegatecall(_calldata);
        if (!sucess) {
            if(error.length >0){
                revert(string(error));
            }else {
                revert("reverted");
            } 
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

}
