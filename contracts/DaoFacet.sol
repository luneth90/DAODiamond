//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "./IDao.sol";
import "./LibStake.sol";
import "./IRewards.sol";
import "./LibStakeStorage.sol";

contract DaoFacet is IDao  {

    function initDao(address _vote, address _rewards) external {
        LibStake.init(_vote, _rewards);
    }

    function deposit(uint256 _amount) external {
        LibStake.deposit(_amount);
    }

    function withdraw(uint256 _amount) external {
        LibStake.withdraw(_amount);
    }

    function balanceOf(address _user) external view returns(uint256 balance_){
        balance_ = LibStake.balanceOf(_user);
    }
    function totalStaked() external view returns(uint256 _balance){
        _balance = LibStake.totalStaked();
    }
}
