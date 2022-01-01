//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "./IDao.sol";
import "./LibStake.sol";

contract DaoFacet  {

    function initDao(address _vote) external {
        LibStake.init(_vote);
    }

    function deposit(uint256 _amount,address receiver) external {
        LibStake.deposit(_amount,receiver);
        //LibRewards.userAction(msg.sender);
    }

    function withdraw(uint256 _amount,address from) external {
        LibStake.withdraw(_amount,from);
        //LibRewards.userAction(msg.sender);
    }

    function balanceOf(address _user) external view returns(uint256 balance_){
        balance_ = LibStake.balanceOf(_user);
    }
}
