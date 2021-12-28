//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

library LibStakeStorage {
    bytes32 constant STORAGE_POSITION = keccak256("dao.stake.storage");

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

        Checkpoint[] bondStakedHistory;

        mapping(address => Checkpoint[]) delegatedPowerHistory;

        //IERC20 bond;
        //IRewards rewards;
    }

    function stakeStorage() internal pure returns (Storage storage ds){
        bytes32 positon = STORAGE_POSITION;
        assembly {
            ds.slot := positon
        }
    }
}

