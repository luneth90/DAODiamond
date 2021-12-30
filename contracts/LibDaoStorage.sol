//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibDaoStorage {
    bytes32 constant STORAGE_POSITION = keccak256("dao.storage");

    struct Checkpoint{
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegateTo;
    }

    struct Storage {
        bool initialized;
        mapping(address => Stake[]) userStakeHistory;

        Checkpoint[] voteStakedHistory;

        mapping(address => Checkpoint[]) delegatedPowerHistory;

        IERC20 vote;
        //IRewards rewards;
    }

    function daoStorage() internal pure returns (Storage storage ds){
        bytes32 positon = STORAGE_POSITION;
        assembly {
            ds.slot := positon
        }
    }
}

