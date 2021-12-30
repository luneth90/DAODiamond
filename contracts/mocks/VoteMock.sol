pragma solidity ^0.8.11;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VoteMock is ERC20("VoteMock","MCK") {
   function mint(address user, uint256 amount) external {
       _mint(user,amount);
   }  
}
