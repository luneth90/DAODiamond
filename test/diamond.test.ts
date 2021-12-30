import {ethers} from 'hardhat';
import {expect} from 'chai';
import * as deploy from './helper/deploy';
import {Contract,Signer,BigNumber} from 'ethers';
import { FacetCutAction, getSelectors,diamondAsFacet } from './helper/diamond';
import {DiamondCutFacet,DiamondLoupeFacet, OwnershipFacet, DaoFacet, VoteMock} from '../typechain';
describe('DaoDiamond',function(){
    const amount = BigNumber.from(100).mul(BigNumber.from(10).pow(18));
    let voteMock: Contract, cutFacet: Contract,  loupeFacet: Contract,daoDiamond: Contract, ownershipFacet: Contract, daoFacet: Contract;
    let owner: Signer, user: Signer;
    let cut: DiamondCutFacet, loupe: DiamondLoupeFacet,ownership: OwnershipFacet,dao: DaoFacet;
    const zeroAddress = '0x0000000000000000000000000000000000000000';
    before(async () => {
        const signers = await ethers.getSigners();
        owner = signers[0];
        user = signers[1];
        voteMock = (await deploy.deployContract('VoteMock')) as VoteMock;
        cutFacet = await deploy.deployContract('DiamondCutFacet');
        loupeFacet = await deploy.deployContract('DiamondLoupeFacet');
        ownershipFacet = await deploy.deployContract('OwnershipFacet');
        daoFacet = await deploy.deployContract('DaoFacet');
        daoDiamond = await deploy.deployDiamond('DaoDiamond',[cutFacet,loupeFacet,ownershipFacet,daoFacet],await owner.getAddress());
        cut = (await diamondAsFacet(daoDiamond,'DiamondCutFacet')) as DiamondCutFacet;
        loupe = (await diamondAsFacet(daoDiamond,'DiamondLoupeFacet')) as DiamondLoupeFacet;
        ownership = (await diamondAsFacet(daoDiamond,'OwnershipFacet')) as OwnershipFacet;
        dao = (await diamondAsFacet(daoDiamond,'DaoFacet')) as DaoFacet;
        await dao.initDao(voteMock.address);
    });

    describe('DiamondCut', async function(){
        let test1Facet: Contract, test2Facet: Contract;
        let snapId: any;
        beforeEach(async function(){
            //snapId = await ethers.provider.send('evm_snapshot', []);
            //test1Facet = await deploy.deployContract('Test1Facet');
            //test2Facet = await deploy.deployContract('Test2Facet');
        });

        afterEach(async function () {
            //await ethers.provider.send('evm_revert', [snapId]);
        });

        /*
        it('allows adding new functions', async function(){
            let selctors = getSelectors(test1Facet);
            const _diamondCut = [{
                facetAddress: test1Facet.address,
                action: FacetCutAction.Add,
                functionSelectors: selctors,
            }];
            await expect(cut.diamondCut(_diamondCut, zeroAddress, '0x')).to.not.be.reverted;
            const selectors_ = await cut.facetFunctionSelectors(test1Facet.address);
            expect(selectors_).to.eql(selctors);

        });
        */

       it('dao test',async function(){
            //let selctors = getSelectors(cutFacet);
            //const selectors_ = await loupe.facetFunctionSelectors(cutFacet.address);
            //expect(selectors_).to.eql(selctors);

            //await ownership.connect(owner).transferOwnership(await user.getAddress());
            //await dao.setContractOwner(await user.getAddress());
            //expect(await ownership.owner()).to.eql(await user.getAddress());
            await initUser(user,amount);
            await dao.connect(user).deposit(amount);
            expect(await dao.balanceOf(await user.getAddress())).to.eql(amount);
       });

    });

    async function initUser(user: Signer, amount: BigNumber) {
        await voteMock.mint(await user.getAddress(),amount);
        await voteMock.connect(user).approve(dao.address,amount)
    }

});
