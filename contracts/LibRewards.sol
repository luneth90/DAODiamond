pragma solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LibRewardsStorage.sol";
import "./LibStake.sol";

library LibRewards {
    using SafeMath for uint256;

    uint256 constant decimals = 10 ** 18;

    event Claim(address indexed user, uint256 amount);

    function init(address _treasury,address _rewardsToken, uint256 _startTs,uint256 _endTs,uint256 _amount) internal {
        require(_rewardsToken != address(0),"Must not 0x00");
        require(_treasury !=address(0),"Must not Ox00");
        require(_endTs > _startTs, "error");
        require(_amount > 0, "error");
        LibRewardsStorage.RewardsStorage storage s = LibRewardsStorage.rewardsStorage();
        s.rewardsToken = IERC20(_rewardsToken);
        s.lastFetchTs = _startTs;
        s.rp.treasury = _treasury;
        s.rp.startTs = _startTs;
        s.rp.endTs = _endTs;
        s.rp.duration = _endTs.sub(_startTs);
        s.rp.amount = _amount;
    }

    function userAction(address user) internal {
        require(user != address(0),"Must not 0");
        _calcRewards(user);
    }

    function claim() internal returns(uint256 amount_){
        LibRewardsStorage.RewardsStorage storage s = LibRewardsStorage.rewardsStorage();
        _calcRewards(msg.sender);
        amount_ = s.userRewards[msg.sender];
        require(amount_ > 0 ,"Must grater 0");
        s.rewardsToken.transfer(msg.sender,amount_);
        _updateBalance();
        emit Claim(msg.sender,amount_);
    }

    function _calcRewards(address user) internal {
        _fetchRewards();
        _updateBalance();
        LibRewardsStorage.RewardsStorage storage s = LibRewardsStorage.rewardsStorage();
        uint256 userStaked = LibStake.balanceOf(user);
        uint256 userMultiplier = s.userMultiplier[user];
        uint256 diffMultiplier = s.lastMultiplier.sub(userMultiplier);
        uint256 userRewards = userStaked.mul(diffMultiplier).div(decimals);
        s.userRewards[user] = userRewards;
        s.userMultiplier[user] = s.lastMultiplier;
    }

    function _fetchRewards() internal{
        LibRewardsStorage.RewardsStorage storage s = LibRewardsStorage.rewardsStorage();
        uint256 ts = block.timestamp;
       if (ts < s.rp.startTs){
           return;
       }else if(ts >= s.rp.endTs) {
           ts = s.rp.endTs;
       }
       if(s.lastFetchTs >=  ts){
           return;
       }

       uint256 timeSinceLastFetch = ts.sub(s.lastFetchTs);
       uint256 share = timeSinceLastFetch.mul(decimals).div(s.rp.duration);
       uint256 fetchAmount = s.rp.amount.mul(share).div(decimals);
       s.lastFetchTs = ts;
       s.rewardsToken.transferFrom(s.rp.treasury,address(this),fetchAmount);

    }

    function _updateBalance() internal {
        LibRewardsStorage.RewardsStorage storage s = LibRewardsStorage.rewardsStorage();
        uint256 balance = s.rewardsToken.balanceOf(address(this));
        if(balance ==0 || s.lastBalance >= balance){
            s.lastBalance = balance;
            return;
        }
        uint256 totalStaked = LibStake.totalStaked();
        if(totalStaked == 0){
            return;
        }

        uint256 diffAmount = balance.sub(s.lastBalance);
        s.lastMultiplier = s.lastMultiplier.add(diffAmount.mul(decimals).div(totalStaked));
        s.lastBalance = balance;
    }

}
