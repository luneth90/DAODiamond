// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {Contract,Signer,BigNumber} from 'ethers';
import * as deploy from '../test/helper/deploy';
import {IStarknetCore} from '../typechain';
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
    let owner: Signer;
    let cutFacet: Contract,loupeFacet: Contract,ownershipFacet: Contract,daoFacet:Contract,daoDiamond:Contract,l1: Contract;
    let starknetCore: IStarknetCore;
    const signers = await ethers.getSigners();
    owner = signers[0];
    //cutFacet = await ethers.getContractAt("DiamondCutFacet", "0xAb7298a5FcC429050401aD9908D0AB3c644eFe3E");
    //loupeFacet = await deploy.deployContract('DiamondLoupeFacet');
    //ownershipFacet = await deploy.deployContract('OwnershipFacet');
    //daoFacet = await deploy.deployContract('DaoFacet');
    //daoDiamond = await deploy.deployDiamond('DaoDiamond',[cutFacet,loupeFacet,ownershipFacet,daoFacet],await owner.getAddress());

    //starknetCore = (await ethers.getContractAt("IStarknetCore", "0xde29d060D45901Fb19ED6C6e959EB22d8626708e")) as IStarknetCore;
    l1 = await deploy.deployContract('StarknetL1',["0xde29d060D45901Fb19ED6C6e959EB22d8626708e"]);

    console.log("deployed to:", l1.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
