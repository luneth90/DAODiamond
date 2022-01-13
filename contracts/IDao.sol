//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

interface IDao{

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address _user) external view returns(uint256 _balance);

    function totalStaked() external view returns(uint256 _balance);

    //function totalStakedAt() external view returns(uint256 _balance);

    //function votingPowerAtTs() external view returns(uint256 votingPower_);
    function activate() external;

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signers,
        bytes[] memory calldatas,
        string memory desc,
        string memory title
    ) external returns(uint256 newProposalId_);

    function getCounter() external view returns(uint256 counter_);

    function vote(uint256 proposalId, bool isFor) external;

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external payable;

}
