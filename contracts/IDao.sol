//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

interface IDao{

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address _user) external view returns(uint256 _balance);

    function totalStaked() external view returns(uint256 _balance);

}
