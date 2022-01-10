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

    describe('DiamondCutFacet, DiamondLoupeFacet', async function(){
        let test1Facet: Contract, test2Facet: Contract;
        let snapId: any;
        beforeEach(async function(){
            snapId = await ethers.provider.send('evm_snapshot', []);
            test1Facet = await deploy.deployContract('Test1Facet');
            test2Facet = await deploy.deployContract('Test2Facet');
        });

        afterEach(async function () {
            await ethers.provider.send('evm_revert', [snapId]);
        });
        it('get all facets', async function(){
            const _facets = await loupe.getAllFacets();
            let allFacets = [[cutFacet.address,getSelectors(cutFacet)]];
            allFacets.push([loupeFacet.address,getSelectors(loupeFacet)]);
            allFacets.push([ownershipFacet.address,getSelectors(ownershipFacet)]);
            allFacets.push([daoFacet.address,getSelectors(daoFacet)]);
            expect(_facets).to.eql(allFacets);
        });

        it('get selctors by facetAddress', async function(){
            expect(await loupe.facetFunctionSelectors(daoFacet.address)).to.eql(getSelectors(daoFacet));
        });

        it('adding new functions', async function(){
            let selctors = getSelectors(test1Facet);
            const _diamondCut = [{
                facetAddress: test1Facet.address,
                action: FacetCutAction.Add,
                functionSelectors: selctors,
            }];
            await expect(cut.diamondCut(_diamondCut, zeroAddress, '0x')).to.not.be.reverted;
            const selectors_ = await loupe.facetFunctionSelectors(test1Facet.address);
            expect(selectors_).to.eql(selctors);

        });
    });

    describe('DaoFacet', async function(){
        let snapId: any,depositAmount: BigNumber;
        before(async function(){
            depositAmount = BigNumber.from(100).mul(decimals);
        });

        beforeEach(async function(){
            snapId = await ethers.provider.send('evm_snapshot', []);
            await initUser(user1,amount);
            await initUser(user2,amount);
            await initUser(user3,amount);
        });

        afterEach(async function () {
            await ethers.provider.send('evm_revert', [snapId]);
        });

       it('deposit and withdraw',async function(){
            await expect(dao.connect(user1).deposit(depositAmount)).to.be.not.reverted;
            expect(await voteMock.balanceOf(await user1.getAddress())).to.eql(amount.sub(depositAmount));
            expect(await voteMock.balanceOf(dao.address)).to.eql(depositAmount);
            expect(await dao.balanceOf(await user1.getAddress())).to.eql(depositAmount);

            await expect(dao.connect(user1).withdraw(depositAmount.add(amount))).to.be.reverted;
            await expect(dao.connect(user1).withdraw(depositAmount)).to.be.not.reverted;
            expect(await voteMock.balanceOf(await user1.getAddress())).to.eql(amount);
            expect(await dao.balanceOf(await user1.getAddress())).to.eql(BigNumber.from(0).mul(decimals));
       });

       it('one user rewards',async function(){
            const {start, end} = await setupRewards();
            await dao.connect(user1).deposit(depositAmount)
            const despositTs = await helpers.getLatestBlockTimestamp();
            const rewardsAmount_lucky = calcReward(start,despositTs,end-start,amount);

            await helpers.moveAtTimestamp(start + 60*60*24*1);
            let tx: Transaction = await rewards.connect(user1).claim();
            const claimTs = await helpers.getLatestBlockTimestamp();
            const rewardsAmount = calcReward(despositTs,claimTs,end-start,amount);
            expect(tx).to.emit(rewards, "Claim").withArgs(await user1.getAddress(),rewardsAmount_lucky.add(rewardsAmount));
            
       });

       it('multiple user rewards',async function(){
            const {start, end} = await setupRewards();
            await dao.connect(user1).deposit(depositAmount)
            const despositTs1 = await helpers.getLatestBlockTimestamp();
            const rewardsAmount_lucky = calcReward(start,despositTs1,end-start,amount);

            await dao.connect(user2).deposit(depositAmount)
            const despositTs2 = await helpers.getLatestBlockTimestamp();
            const rewardsAmount_2= calcReward(despositTs1,despositTs2,end-start,amount);

            await dao.connect(user3).deposit(depositAmount)
            const despositTs3 = await helpers.getLatestBlockTimestamp();
            const rewardsAmount_3= calcReward(despositTs2,despositTs3,end-start,amount);
            expect(await voteMock.balanceOf(rewards.address)).to.eql(rewardsAmount_lucky.add(rewardsAmount_2).add(rewardsAmount_3));


            await helpers.moveAtTimestamp(start + 60*60*24*1);

            let tx1: Transaction = await rewards.connect(user1).claim();
            const rewardsAmount1 = (await rewards.lastMultiplier()).mul(depositAmount).div(decimals);
            expect(tx1).to.emit(rewards, "Claim").withArgs(await user1.getAddress(),rewardsAmount1);
            
            /*
            await helpers.moveAtTimestamp(start + 60*60*24*1);

            let tx2: Transaction = await rewards.connect(user2).claim();
            const claimTs2 = await helpers.getLatestBlockTimestamp();
            const rewardsAmount2 = calcReward(despositTs2,claimTs2,end-start,amount);
            expect(tx2).to.emit(rewards, "Claim").withArgs(await user2.getAddress(),rewardsAmount2.add(rewardsAmount_3));

            let tx3: Transaction = await rewards.connect(user3).claim();
            const claimTs3 = await helpers.getLatestBlockTimestamp();
            const rewardsAmount3 = calcReward(despositTs3,claimTs3,end-start,amount);
            expect(tx3).to.emit(rewards, "Claim").withArgs(await user3.getAddress(),rewardsAmount3);
            */
            
       });

    });

    async function initUser(user: Signer, amount: BigNumber) {
        await voteMock.mint(await user.getAddress(),amount);
        await voteMock.connect(user).approve(daoDiamond.address,amount)
    }

    async function setupRewards (): Promise<{ start: number, end: number }> {
        await voteMock.mint(await treasury.getAddress(),amount );
        await voteMock.connect(treasury).approve(rewards.address,amount)

        const startAt = await helpers.getLatestBlockTimestamp();
        const endsAt = startAt + 60 * 60 * 24 * 7;
        await rewards.connect(owner).initRewardsPool(await treasury.getAddress(), startAt, endsAt,amount);
        return { start: startAt, end: endsAt };
    }

    function calcReward (startTs: number, endTs: number, totalDuration: number, totalAmount: BigNumber): BigNumber {
        const diff = endTs - startTs;
        const shareToPull = BigNumber.from(diff).mul(helpers.tenPow18).div(totalDuration);

        return shareToPull.mul(totalAmount).div(helpers.tenPow18);
    }

});
