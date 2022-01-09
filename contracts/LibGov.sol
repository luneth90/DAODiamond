//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "./LibGovStorage.sol";
import "./LibOwnership.sol";
import "./LibStake.sol";

library LibGov {
    using SafeMath for uint256;
    event ProposalCreated(uint256 indexed proposalId);
    event Vote(uint256 indexed proposalId, address indexed user, bool support, uint256 power);
    event VoteCanceled(uint256 indexed proposalId, address indexed user);
    event ProposalQueued(uint256 indexed proposalId, address caller, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId, address caller);
    event ProposalCanceled(uint256 indexed proposalId, address caller);
    
    function activate() internal {
        LibGovStorage.GovStorage storage s = LibGovStorage.govStorage();
        require(!s.isActive,"Already activate");
        LibOwnership.enforceIsContractOwner();
        require(LibStake.totalStaked() >= LibGovStorage.ACTIVATION_THRESHOLD,"Can not activate");
        s.isActive = true;
    }

    function state(uint256 proposalId) internal view returns (LibGovStorage.ProposalState) {
        LibGovStorage.GovStorage storage s = LibGovStorage.govStorage();
        require(0 < proposalId && proposalId <= s.lastProposalId, "invalid proposal id");
        LibGovStorage.Proposal storage proposal = s.proposals[proposalId];

        if (proposal.canceled) {
            return LibGovStorage.ProposalState.Canceled;
        }

        if (proposal.executed) {
            return LibGovStorage.ProposalState.Executed;
        }

        if (block.timestamp <= proposal.createTime + proposal.pr.warmUpDuration) {
            return LibGovStorage.ProposalState.WarmUp;
        }

        if (block.timestamp <= proposal.createTime + proposal.pr.warmUpDuration + proposal.pr.activeDuration) {
            return LibGovStorage.ProposalState.Active;
        }

        if ((proposal.forVotes + proposal.againstVotes) < _getQuorum(proposal) ||
            (proposal.forVotes < _getMinForVotes(proposal))) {
            return LibGovStorage.ProposalState.Failed;
        }

        if (proposal.eta == 0) {
            return LibGovStorage.ProposalState.Accepted;
        }

        if (block.timestamp < proposal.eta) {
            return LibGovStorage.ProposalState.Queued;
        }


        return LibGovStorage.ProposalState.Expired;
    }


    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signers,
        bytes[] memory calldatas,
        string memory desc,
        string memory title
    ) internal returns(uint256 newProposalId_){
        LibGovStorage.GovStorage storage s = LibGovStorage.govStorage();
        require(s.isActive,"Dao not activate");
        require(targets.length != 0, "Must provide actions");
        require(targets.length <= LibGovStorage.PROPOSAL_MAX_ACTIONS, "Too many actions on a vote");
        require(bytes(title).length > 0, "title can't be empty");
        require(bytes(desc).length > 0, "description can't be empty");
        uint256 prevUserProposalId = s.userLatestProposals[msg.sender];
        if(prevUserProposalId != 0){
            require(_isLiveProposal(prevUserProposalId),"Only one live proposal for one user");
        }

        newProposalId_ = s.lastProposalId + 1;
        LibGovStorage.Proposal storage newProposal = s.proposals[newProposalId_];
        newProposal.id = newProposalId_;
        newProposal.proposer = msg.sender;
        newProposal.desc= desc;
        newProposal.title = title;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signers= signers;
        newProposal.calldatas = calldatas;
        newProposal.createTime = block.timestamp - 1;
        newProposal.pr.warmUpDuration = LibGovStorage.WARMUP_DURATION;
        newProposal.pr.activeDuration = LibGovStorage.ACTIVATION_THRESHOLD;
        newProposal.pr.queueDuration = LibGovStorage.QUEUE_DURATION;
        newProposal.pr.acceptanceThreshold = LibGovStorage.ACTIVATION_THRESHOLD;
        newProposal.pr.minQuorum = LibGovStorage.MIN_QUORUM;

        s.lastProposalId = newProposalId_;
        s.userLatestProposals[msg.sender] = newProposalId_;

        emit ProposalCreated(newProposalId_);
    }

    function vote(uint256 proposalId, bool isFor) internal{
        require(state(proposalId) == LibGovStorage.ProposalState.Active, "Voting is closed");

        LibGovStorage.GovStorage storage s = LibGovStorage.govStorage();
        LibGovStorage.Proposal storage proposal = s.proposals[proposalId];
        LibGovStorage.Receipt storage receipt = proposal.receipts[msg.sender];

        // exit if user already voted
        require(receipt.hasVoted == false , "Already voted");

        uint256 votes = LibStake.votingPowerAtTs(msg.sender, _getVoteStartTimestamp(proposal));
        require(votes > 0, "no voting power");


        if (isFor) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.isFor= isFor;

        emit Vote(proposalId, msg.sender, isFor, votes);
    }



    function queue(uint256 proposalId) internal {
        require(state(proposalId) == LibGovStorage.ProposalState.Accepted, "Proposal can only be queued if it is succeeded");
        LibGovStorage.GovStorage storage s = LibGovStorage.govStorage();
        LibGovStorage.Proposal storage proposal = s.proposals[proposalId];
        uint256 eta = proposal.createTime + proposal.pr.warmUpDuration + proposal.pr.activeDuration + proposal.pr.queueDuration;
        proposal.eta = eta;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            require(
                !s.queuedTxs[_getTxHash(proposal.targets[i], proposal.values[i], proposal.signers[i], proposal.calldatas[i], eta)],
                "proposal action already queued at eta"
            );

            _queueTx(proposal.targets[i], proposal.values[i], proposal.signers[i], proposal.calldatas[i], eta);
        }

        emit ProposalQueued(proposalId, msg.sender, eta);
    }



    function _canBeExecuted(uint256 proposalId) internal view returns (bool) {
        return state(proposalId) == LibGovStorage.ProposalState.Queued;
    }

    function _getVoteStartTimestamp(LibGovStorage.Proposal storage proposal) internal view returns (uint256 voteStartTs_) {
        voteStartTs_ = proposal.createTime + proposal.pr.warmUpDuration;
    }

    function _getQuorum(LibGovStorage.Proposal storage proposal) internal view returns (uint256 quorum_) {
        LibGovStorage.GovStorage storage s = LibGovStorage.govStorage();
        quorum_ = LibStake.totalStakedAt(_getVoteStartTimestamp(proposal)).mul(proposal.pr.minQuorum).div(100);
    }
    
    function _getMinForVotes(LibGovStorage.Proposal storage proposal) internal view returns (uint256 minForVotes_) {
        minForVotes_ = (proposal.forVotes + proposal.againstVotes).mul(proposal.pr.acceptanceThreshold).div(100);
    }

    function _isLiveProposal(uint256 proposalId) internal view returns (bool isLive_) {
        LibGovStorage.ProposalState s = state(proposalId);
        isLive_ = (s == LibGovStorage.ProposalState.WarmUp ||
        s == LibGovStorage.ProposalState.Active ||
        s == LibGovStorage.ProposalState.Accepted ||
        s == LibGovStorage.ProposalState.Queued);
    }

    function _executeTx(address target, uint256 value, string memory signer, bytes memory data,uint256 eta) internal returns(bytes memory data_){
        require(block.timestamp >= eta,"error eta");
        LibGovStorage.GovStorage storage s= LibGovStorage.govStorage();
        bytes32 txHash_ = _getTxHash(target,value, signer,data,eta);
        s.queuedTxs[txHash_] = false;
        bytes memory callData;
        if(bytes(signer).length == 0) {
            callData = data;
        }else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signer))),data);
        }
        bool sucess;
        (sucess, data_) = target.call{value:value}(callData);
        require(sucess,string(data_));

    }

    function _queueTx(address target, uint256 value, string memory signer, bytes memory data,uint256 eta) internal returns(bytes32 txHash_){
        LibGovStorage.GovStorage storage s= LibGovStorage.govStorage();
        txHash_ = _getTxHash(target,value, signer,data,eta);
        s.queuedTxs[txHash_] = true;
    }

    function _cancelTx(address target, uint256 value, string memory signer, bytes memory data,uint256 eta) internal{
        LibGovStorage.GovStorage storage s= LibGovStorage.govStorage();
        bytes32 txHash_ = _getTxHash(target,value, signer,data,eta);
        s.queuedTxs[txHash_] = false;
    }



    function _getTxHash(address target, uint256 value, string memory signer, bytes memory data,uint256 eta) internal returns(bytes32 txHash_){
        txHash_ = keccak256(abi.encode(target,value,signer,data,eta));
    }


}
