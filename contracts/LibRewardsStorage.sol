pragma solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibRewardsStorage {
    bytes32 constant STORAGE_POSITION = keccak256("rewards.storage"); 

    struct RewardsPool {
        address treasury;
        uint256 startTs;
        uint256 endTs;
        uint256 duration;
        uint256 amount;
    }

    struct RewardsStorage {
        RewardsPool rp;
        uint256 lastFetchTs;
        uint256 lastBalance;
        uint256 lastMultiplier;
        mapping(address => uint256) userRewards;
        mapping(address => uint256) userMultiplier;
        IERC20 rewardsToken;
    }

    function rewardsStorage() internal pure returns(RewardsStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
