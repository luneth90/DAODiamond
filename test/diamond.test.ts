import {ethers} from 'hardhat';
import {expect} from 'chai';
import * as deploy from './helper/deploy';
import {Contract,Signer} from 'ethers';
import { FacetCutAction, getSelectors,diamondAsFacet } from './helper/diamond';
import {DiamondCutFacet,DiamondLoupeFacet, OwnershipFacet, IDiamondCut} from '../typechain';
describe('Diamond',function(){
    let cutFacet: Contract,  loupeFacet: Contract,dao: Contract, ownershipFacet: Contract;
    let owner: Signer, user: Signer;
    let cut: DiamondCutFacet, loupe: DiamondLoupeFacet,ownership: OwnershipFacet;
    const zeroAddress = '0x0000000000000000000000000000000000000000';
    before(async () => {
        const signers = await ethers.getSigners();
        owner = signers[0];
        user = signers[1];
        cutFacet = await deploy.deployContract('DiamondCutFacet');
        loupeFacet = await deploy.deployContract('DiamondLoupeFacet');
        ownershipFacet = await deploy.deployContract('OwnershipFacet');
        dao = await deploy.deployDiamond('Dao',[cutFacet,loupeFacet,ownershipFacet],await owner.getAddress());
        cut = (await diamondAsFacet(dao,'DiamondCutFacet')) as DiamondCutFacet;
        loupe = (await diamondAsFacet(dao,'DiamondLoupeFacet')) as DiamondLoupeFacet;
        ownership = (await diamondAsFacet(dao,'OwnershipFacet')) as OwnershipFacet;
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
            let selctors = getSelectors(cutFacet);
            const selectors_ = await loupe.facetFunctionSelectors(cutFacet.address);
            expect(selectors_).to.eql(selctors);

            await ownership.connect(owner).transferOwnership(await user.getAddress());
            //await dao.setContractOwner(await user.getAddress());
            expect(await ownership.owner()).to.eql(await user.getAddress());
       });

    });

});
