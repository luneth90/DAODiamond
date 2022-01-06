import {ethers} from 'hardhat';
import {expect} from 'chai';
import * as deploy from './helper/deploy';
import {Contract,Signer,BigNumber,Transaction,utils} from 'ethers';
import * as helpers from './helper/helper';
import { FacetCutAction, getSelectors,diamondAsFacet } from './helper/Diamond';
import {DiamondCutFacet,DiamondLoupeFacet, OwnershipFacet, DaoFacet, VoteMock, Rewards} from '../typechain';
describe('DaoDiamond',function(){
    const decimals = BigNumber.from(10).pow(18);
    const amount = BigNumber.from(1000).mul(decimals);
    let voteMock: Contract, cutFacet: Contract,  loupeFacet: Contract,daoDiamond: Contract, ownershipFacet: Contract, daoFacet: Contract;
    let owner: Signer, user1: Signer, treasury: Signer, user2: Signer, user3: Signer, user4: Signer;
    let cut: DiamondCutFacet, loupe: DiamondLoupeFacet,ownership: OwnershipFacet,dao: DaoFacet,rewards: Rewards;
    const zeroAddress = '0x0000000000000000000000000000000000000000';
    before(async () => {
        const signers = await ethers.getSigners();
        owner = signers[0];
        user1 = signers[1];
        user2 = signers[2];
        user3 = signers[3];
        treasury = signers[4];
        voteMock = (await deploy.deployContract('VoteMock')) as VoteMock;
        cutFacet = await deploy.deployContract('DiamondCutFacet');
        loupeFacet = await deploy.deployContract('DiamondLoupeFacet');
        ownershipFacet = await deploy.deployContract('OwnershipFacet');
        daoFacet = await deploy.deployContract('DaoFacet');
        daoDiamond = await deploy.deployDiamond('DaoDiamond',[cutFacet,loupeFacet,ownershipFacet,daoFacet],await owner.getAddress());
        //voteMock = await ethers.getContractAt("VoteMock", "0x4060af82f8deb4db4efdec28447533058bea9a03");
        //daoDiamond = await ethers.getContractAt("DaoDiamond", "0x94638bd3d52118a1004713156e34442be4a21e10");
        cut = (await diamondAsFacet(daoDiamond,'DiamondCutFacet')) as DiamondCutFacet;
        loupe = (await diamondAsFacet(daoDiamond,'DiamondLoupeFacet')) as DiamondLoupeFacet;
        ownership = (await diamondAsFacet(daoDiamond,'OwnershipFacet')) as OwnershipFacet;
        dao = (await diamondAsFacet(daoDiamond,'DaoFacet')) as DaoFacet;

        rewards = (await deploy.deployContract("Rewards",[await owner.getAddress(), voteMock.address,dao.address])) as Rewards;
        await dao.initDao(voteMock.address,rewards.address);
    });

    describe('Stake', async function(){
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

       it('stake test',async function(){
            //let selctors = getSelectors(cutFacet);
            //const selectors_ = await loupe.facetFunctionSelectors(cutFacet.address);
            //expect(selectors_).to.eql(selctors);

            //await ownership.connect(owner).transferOwnership(await user.getAddress());
            //await dao.setContractOwner(await user.getAddress());
            //expect(await ownership.owner()).to.eql(await user.getAddress());
           
            const depositAmount = BigNumber.from(100).mul(decimals);
            await setupRewards();
            await initUser(user1,amount);
            await dao.connect(user1).deposit(depositAmount)
            expect(await voteMock.balanceOf(dao.address)).to.eql(depositAmount);
            expect(await dao.balanceOf(await user1.getAddress())).to.eql(depositAmount);
            console.log(await ethers.provider.getBlockNumber());
            //await dao.connect(user1).withdraw(amount);;
            //expect(await voteMock.balanceOf(await user1.getAddress())).to.eql(amount);
       });

       it('rewards test',async function(){
            const depositAmount = BigNumber.from(10).mul(decimals);
            await dao.connect(user1).deposit(depositAmount)
            await dao.connect(user1).deposit(depositAmount)
            await dao.connect(user1).deposit(depositAmount)
            await dao.connect(user1).deposit(depositAmount)
            await dao.connect(user1).deposit(depositAmount)
            let tx: Transaction = await rewards.connect(user1).claim();
            expect(tx).to.emit(rewards, "Claim").withArgs(await user1.getAddress(),BigNumber.from("99999999999999997050"));
            
       });

    });

    async function initUser(user: Signer, amount: BigNumber) {
        await voteMock.mint(await user.getAddress(),amount);
        await voteMock.connect(user).approve(daoDiamond.address,amount)
    }

    async function setupRewards (): Promise<{ start: number, end: number }> {
        const _amount = BigNumber.from(600).mul(decimals);
        await voteMock.mint(await treasury.getAddress(),amount );
        await voteMock.connect(treasury).approve(rewards.address,amount)
        const startAt = await helpers.getLatestBlockTimestamp();
        const endsAt = startAt + 60;
        await rewards.connect(owner).initRewardsPool(await treasury.getAddress(), startAt, endsAt, _amount);
        return { start: startAt, end: endsAt };
    }
});
