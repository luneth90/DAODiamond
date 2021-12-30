//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LibOwnership.sol";
import "./IDao.sol";
import "./LibDaoStorage.sol";



contract DaoFacet is IDao {
    using SafeMath for uint256;

    event Deposit(address indexed sender, uint256 amount, uint256 newBalance);

    function initDao(address _vote) external {
        LibDaoStorage.Storage storage ds = LibDaoStorage.daoStorage();
        require(_vote != address(0),"vote must not be 0");
        require(!ds.initialized,"Dao Already Initialized");
        LibOwnership.enforceIsContractOwner();
        ds.initialized = true;
        ds.vote = IERC20(_vote);
    }

    function deposit(uint256 amount) external {
        require(amount > 0,"Amount must grater than 0");
        LibDaoStorage.Storage storage ds = LibDaoStorage.daoStorage();
        uint256 allowance = ds.vote.allowance(msg.sender,address(this));
        require(allowance >= amount, "Token allowance too small");

        uint256 newBalance = balanceOf(msg.sender).add(amount);
        updateUserBalance(ds.userStakeHistory[msg.sender],newBalance);
        ds.vote.transferFrom(msg.sender,address(this),amount);
        emit Deposit(msg.sender,amount,newBalance);
    }

    function updateUserBalance(LibDaoStorage.Stake[] storage stakes, uint256 newBalance) internal {
        if(stakes.length == 0){
            stakes.push(LibDaoStorage.Stake(block.timestamp,newBalance,block.timestamp,address(0)));
        }else {
            LibDaoStorage.Stake storage old = stakes[stakes.length-1];
            if(old.timestamp == block.timestamp){
                old.amount = newBalance;
            }else{
                stakes.push(LibDaoStorage.Stake(block.timestamp,newBalance,old.expiryTimestamp,old.delegateTo));
            }
        } 
    }

    function balanceOf(address user) public view returns(uint256 balance_){
        balance_ = balanceAt(user, block.timestamp);
    }

    function balanceAt(address user, uint256 timestamp) internal view returns(uint256 balance_){
        LibDaoStorage.Stake memory stake = stakeAt(user,timestamp);
        balance_ = stake.amount;
    }

    function stakeAt(address user, uint256 timestamp) internal view returns(LibDaoStorage.Stake memory stake_){
        LibDaoStorage.Storage storage ds = LibDaoStorage.daoStorage();
        LibDaoStorage.Stake[] storage stakeHistory = ds.userStakeHistory[user];
        if(stakeHistory.length == 0 || timestamp < stakeHistory[0].timestamp){
            stake_ = LibDaoStorage.Stake(block.timestamp,0,block.timestamp,address(0));
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
