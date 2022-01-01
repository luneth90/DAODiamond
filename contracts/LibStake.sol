//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LibOwnership.sol";
import "./LibStakeStorage.sol";
import "hardhat/console.sol";

library LibStake {
    using SafeMath for uint256;
    
    event Deposit(address indexed sender, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed receiver, uint256 amount, uint256 newBalance);

    function init(address _vote) internal {
        LibStakeStorage.StakeStorage storage s = LibStakeStorage.stakeStorage();
        require(_vote != address(0),"Must not 0");
        require(!s.initialized,"Already initialized");
        LibOwnership.enforceIsContractOwner();
        s.initialized = true;
        s.vote = IERC20(_vote);
    }

    function deposit(uint256 amount,address receiver) internal {
        require(amount > 0,"Amount must grater than 0");
        LibStakeStorage.StakeStorage storage s = LibStakeStorage.stakeStorage();
        uint256 allowance = s.vote.allowance(msg.sender,address(this));
        require(allowance >= amount, "Token allowance too small");

        uint256 newBalance = balanceOf(msg.sender).add(amount);
        _updateUserBalance(s.userStakeHistory[msg.sender],newBalance);
        s.vote.transferFrom(msg.sender,receiver,amount);
        emit Deposit(msg.sender,amount,newBalance);
    }

    //diamond 模式存在局限性，同一token不能分区用途，由于执行上下文的关系，也没法方便的把token分配到不同contract中
    function withdraw(uint256 amount,address from) internal {
        require(amount > 0, "Amount must grater than 0");
        uint256 balance = balanceOf(msg.sender);
        require(amount <= balance,"Amount must smaller than balance");
        uint256 newBalance = balance.sub(amount);
        LibStakeStorage.StakeStorage storage s = LibStakeStorage.stakeStorage();
        _updateUserBalance(s.userStakeHistory[msg.sender],newBalance);
        s.vote.transferFrom(from,msg.sender,amount);
        emit Withdraw(msg.sender,amount,newBalance);
    }

    function balanceOf(address user) internal view returns(uint256 balance_){
        balance_ = _balanceAt(user, block.timestamp);
    }

    function totalStaked() internal view returns(uint256 stakedAmount_){
        stakedAmount_ = 0; 
    }

    function _updateUserBalance(LibStakeStorage.Stake[] storage stakes, uint256 newBalance) internal {
        if(stakes.length == 0){
            stakes.push(LibStakeStorage.Stake(block.timestamp,newBalance,block.timestamp,address(0)));
        }else {
            LibStakeStorage.Stake storage old = stakes[stakes.length-1];
            if(old.timestamp == block.timestamp){
                old.amount = newBalance;
            }else{
                stakes.push(LibStakeStorage.Stake(block.timestamp,newBalance,old.expiryTimestamp,old.delegateTo));
            }
        } 
    }


    function _balanceAt(address user, uint256 timestamp) internal view returns(uint256 balance_){
        LibStakeStorage.Stake memory stake = _stakeAt(user,timestamp);
        balance_ = stake.amount;
    }

    function _stakeAt(address user, uint256 timestamp) internal view returns(LibStakeStorage.Stake memory stake_){
        LibStakeStorage.StakeStorage storage s = LibStakeStorage.stakeStorage();
        LibStakeStorage.Stake[] storage stakeHistory = s.userStakeHistory[user];
        if(stakeHistory.length == 0 || timestamp < stakeHistory[0].timestamp){
            stake_ = LibStakeStorage.Stake(block.timestamp,0,block.timestamp,address(0));
            return stake_;
        }

        uint256 min = 0;
        uint256 max = stakeHistory.length - 1;

        if(timestamp >= stakeHistory[max].timestamp){
            stake_ = stakeHistory[max];
            return stake_;
        }

        while(max > min){
            uint256 mid = (max + min + 1) / 2;
            if (stakeHistory[mid].timestamp == timestamp) {
                stake_ = stakeHistory[mid];
                return stake_;
            }else if(stakeHistory[mid].timestamp < timestamp) {
                min = mid + 1;
            }else {
                max = mid - 1;
            }
        }
    }


}

