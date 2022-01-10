//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDao.sol";
import "./IRewards.sol";
import "hardhat/console.sol";

contract Rewards is IRewards,Ownable{
    using SafeMath for uint256;

    uint256 constant decimals = 10 ** 18;

    event Claim(address indexed user, uint256 amount);

    struct RewardsPool {
        address treasury;
        uint256 startTs;
        uint256 endTs;
        uint256 duration;
        uint256 amount;
    }

    RewardsPool rp;
    uint256 lastFetchTs;
    uint256 lastBalance;
    uint256 public lastMultiplier;
    mapping(address => uint256) userRewards;
    mapping(address => uint256) userMultiplier;
    IERC20 rewardsToken;
    IDao dao;

    constructor(address _owner, address _rewardsToken, address _dao){
        require(_rewardsToken != address(0),"Must not 0x00");
        transferOwnership(_owner);
        rewardsToken = IERC20(_rewardsToken);
        dao = IDao(_dao);
    }

    function initRewardsPool(address _treasury, uint256 _startTs,uint256 _endTs,uint256 _amount) external{
        require(msg.sender == owner(),"error");
        require(_treasury !=address(0),"Must not Ox00");
        require(_endTs > _startTs, "error");
        require(_amount > 0, "error");
        lastFetchTs = _startTs;
        rp.treasury = _treasury;
        rp.startTs = _startTs;
        rp.endTs = _endTs;
        rp.duration = _endTs.sub(_startTs);
        rp.amount = _amount;
    }

    function userAction(address user) external {
        require(user != address(0),"Must not 0");
        require(msg.sender == address(dao),"Only Dao can call");
        _calcRewards(user);
    }

    function claim() external returns(uint256 amount_){
        _calcRewards(msg.sender);
        amount_ = userRewards[msg.sender];
        require(amount_ > 0 ,"Must grater 0");
        rewardsToken.transfer(msg.sender,amount_);
        _updateBalance();
        emit Claim(msg.sender,amount_);
    }

    function _calcRewards(address user) internal {
        _fetchRewards();
        _updateBalance();
        uint256 userStaked = dao.balanceOf(user);
        uint256 _userMultiplier = userMultiplier[user];
        uint256 diffMultiplier = lastMultiplier.sub(_userMultiplier);
        uint256 _userRewards = userStaked.mul(diffMultiplier).div(decimals);
        userRewards[user] = userRewards[user].add(_userRewards);
        userMultiplier[user] = lastMultiplier;
    }

    function _fetchRewards() internal{
       uint256 ts = block.timestamp;
       if (ts < rp.startTs){
           return;
       }else if(ts >= rp.endTs) {
           ts = rp.endTs;
       }
       if(lastFetchTs >=  ts){
           return;
       }

       uint256 timeSinceLastFetch = ts.sub(lastFetchTs);
       uint256 share = timeSinceLastFetch.mul(decimals).div(rp.duration);
       uint256 fetchAmount = rp.amount.mul(share).div(decimals);
       lastFetchTs = ts;
       rewardsToken.transferFrom(rp.treasury,address(this),fetchAmount);

    }

    function _updateBalance() internal {
        uint256 balance = rewardsToken.balanceOf(address(this));
        if(balance ==0 || lastBalance >= balance){
            lastBalance = balance;
            return;
        }
        uint256 totalStaked = dao.totalStaked();
        if(totalStaked == 0){
            return;
        }

        uint256 diffAmount = balance.sub(lastBalance);
        lastMultiplier = lastMultiplier.add(diffAmount.mul(decimals).div(totalStaked));
        lastBalance = balance;
    }

}
