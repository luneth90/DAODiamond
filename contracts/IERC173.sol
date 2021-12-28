//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface IERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address owner_);

    function transferOwnership(address _newOwner) external;
}
