//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
pragma abicoder v2;

interface IRewards {
    function userAction(address user) external;
}

