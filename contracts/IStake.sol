//SPDX-License-Identifier: Unlicense
pragma  solidity ^0.8.11;
pragma abicoder v2;

// Stake接口，定义了质押相关的基本方法
interface IStake{

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function lock(uint256 timestamp) external;



}
