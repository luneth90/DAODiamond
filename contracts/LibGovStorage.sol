//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

library LibGovStorage {
    bytes32 constant POSITION = keccak256("gov.storage");
    uint256 constant ACTIVATION_THRESHOLD = 400_000*10**18;
    uint256 constant PROPOSAL_MAX_ACTIONS = 10;
    uint256 constant WARMUP_DURATION= 4 days;
    uint256 constant ACTIVATE_DURATION= 4 days;
    uint256 constant QUEUE_DURATION= 4 days;
    uint256 constant ACCEPTANCE_THRESHOLD= 60;
    uint256 constant MIN_QUORUM= 40;
    
    struct ProposalParams {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
    } 

    enum ProposalState {
        WarmUp,
        Active,
        Canceled,
        Failed,
        Accepted,
        Queued,
        Expired,
        Executed
    }

    struct Receipt {
        bool hasVoted;
        uint256 votes;
        bool isFor;
    }
    
    struct Proposal {
        uint256 id;
        address proposer;
        string desc;
        string title;

        address[] targets;
        uint256[] values;
        string[] signers;
        bytes[] calldatas;

        uint256 createTime;
        uint256 eta;
        uint256 forVotes;
        uint256 againstVotes;

        bool canceled;
        bool executed;

        ProposalParams pr;

        mapping(address => Receipt) receipts;

    }



    struct GovStorage {
        mapping(uint256 => Proposal) proposals;
        mapping(address => uint256) userLatestProposals;
        mapping(bytes32 => bool) queuedTxs;
        uint256 lastProposalId;
        bool isActive;
        
    }

    function govStorage() internal pure returns(GovStorage storage s){
        bytes32 positon = POSITION;
        assembly{
            s.slot := positon
        }
    }

}
