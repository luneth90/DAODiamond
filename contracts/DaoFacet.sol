//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

import "./IDao.sol";
import "./LibStake.sol";
import "./LibGov.sol";
import "./IRewards.sol";
import "./LibStakeStorage.sol";

contract DaoFacet is IDao  {

    function initDao(address _vote, address _rewards) external {
        LibStake.init(_vote, _rewards);
    }

    function deposit(uint256 _amount) external {
        LibStake.deposit(_amount);
    }

    function withdraw(uint256 _amount) external {
        LibStake.withdraw(_amount);
    }

    function balanceOf(address _user) external view returns(uint256 balance_){
        balance_ = LibStake.balanceOf(_user);
    }

    function totalStaked() external view returns(uint256 _balance){
        _balance = LibStake.totalStaked();
    }

    function execute(uint256 proposalId) external payable {
        require(LibGov._canBeExecuted(proposalId), "Cannot be executed");
        LibGovStorage.GovStorage storage s = LibGovStorage.govStorage();
        LibGovStorage.Proposal storage proposal = s.proposals[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            LibGov._executeTx(proposal.targets[i], proposal.values[i], proposal.signers[i], proposal.calldatas[i], proposal.eta);
        }

        emit LibGov.ProposalExecuted(proposalId, msg.sender);
    }
    
    /*
    function totalStakedAt() external view returns(uint256 _balance){
        _balance = LibStake.totalStakedAt();
    }

    function votingPowerAtTs() external view returns(uint256 votingPower_){
        votingPower_ = LibStake.votingPowerAtTs();
    }
    */
}
