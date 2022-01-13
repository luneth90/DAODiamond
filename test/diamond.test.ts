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
            await initUser(user2,amount.mul(2));
            await initUser(user3,amount.mul(3));
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

       it('propose',async function(){
            //await voteMock.mint(await treasury.getAddress(),amount );
            await expect(dao.connect(user2).deposit(depositAmount)).to.be.not.reverted;
            await dao.activate();
            const targets = [daoFacet.address];
            const values = [0];
            const signers = ['counterPlus(uint256)'];
            const calldatas = [ethers.utils.defaultAbiCoder.encode(['uint256'], [1])];
            //const caladatas = ['0x'];
            await expect(dao.connect(user2).propose(targets,values,signers,calldatas,"desc","title")).to.be.not.reverted;
            const ts = await helpers.getLatestBlockTimestamp();
            await helpers.moveAtTimestamp(ts + 60*60*24*4);
            await expect(dao.connect(user2).vote(1, true)).to.be.not.reverted;
            const ts1 = await helpers.getLatestBlockTimestamp();
            await helpers.moveAtTimestamp(ts1 + 60*60*24*4);
            await expect(dao.connect(user2).queue(1)).to.be.not.reverted;
            const ts2 = await helpers.getLatestBlockTimestamp();
            await helpers.moveAtTimestamp(ts2 + 60*60*24*1);
            await expect(dao.connect(user2).execute(1)).to.be.not.reverted;
            //diamond模式对dao设计不友好，任务自动执行时会调用call导致切换到target环境上下文，这导致整个系统上下文极其混乱，容易出bug
            expect(await daoFacet.connect(user2).getCounter()).to.be.eql(BigNumber.from(1));
       });





    });

    describe('Rewards', async function(){
        let snapId: any,depositAmount: BigNumber;
        before(async function(){
            depositAmount = BigNumber.from(100).mul(decimals);
        });

        beforeEach(async function(){
            snapId = await ethers.provider.send('evm_snapshot', []);
            await initUser(user1,amount);
            await initUser(user2,amount.mul(2));
            await initUser(user3,amount.mul(3));
        });

        afterEach(async function () {
            await ethers.provider.send('evm_revert', [snapId]);
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
            const fetchAmount_lucky = calcReward(start,despositTs1,end-start,amount);

            await dao.connect(user2).deposit(depositAmount.mul(2))
            const despositTs2 = await helpers.getLatestBlockTimestamp();
            const fetchAmount_2= calcReward(despositTs1,despositTs2,end-start,amount);
            //lucky rewards 加入总量计算
            const multiplier_2= fetchAmount_lucky.add(fetchAmount_2).mul(decimals).div(depositAmount);

            await dao.connect(user3).deposit(depositAmount.mul(3))
            const despositTs3 = await helpers.getLatestBlockTimestamp();
            const fetchAmount_3= calcReward(despositTs2,despositTs3,end-start,amount);
            const multiplier_3= fetchAmount_3.mul(decimals).div(depositAmount.add(depositAmount.mul(2)));
            expect(await voteMock.balanceOf(rewards.address)).to.eql(fetchAmount_lucky.add(fetchAmount_2).add(fetchAmount_3));
            expect(await rewards.lastMultiplier()).to.eql(multiplier_2.add(multiplier_3));

            await helpers.moveAtTimestamp(start + 60*60*24*1);

            //计算user2的rewards
            let tx2: Transaction = await rewards.connect(user2).claim();
            const claimTs2 = await helpers.getLatestBlockTimestamp();
            const fetchAmount_4= calcReward(despositTs3,claimTs2,end-start,amount);
            //user2 的multiplier需要手动计算
            const multiplier_4= fetchAmount_4.mul(decimals).div(depositAmount.add(depositAmount.mul(2)).add(depositAmount.mul(3)));
            const rewardsAmount_user2 = multiplier_3.add(multiplier_4).mul(depositAmount.mul(2)).div(decimals);
            expect(tx2).to.emit(rewards, "Claim").withArgs(await user2.getAddress(),rewardsAmount_user2);

            //计算user1的rewards
            let tx1: Transaction = await rewards.connect(user1).claim();
            const claimTs1 = await helpers.getLatestBlockTimestamp();
            const fetchAmount_5= calcReward(claimTs2,claimTs1,end-start,amount);
            const multiplier_5= fetchAmount_5.mul(decimals).div(depositAmount.add(depositAmount.mul(2)).add(depositAmount.mul(3)));
            //user1 包含了所有的multiplier，所以可以直接获取最新值,也可以手动计算
            const rewardsAmount_user1 = (await rewards.lastMultiplier()).mul(depositAmount).div(decimals);
            expect(tx1).to.emit(rewards, "Claim").withArgs(await user1.getAddress(),rewardsAmount_user1);

            //计算user3的rewards
            let tx3: Transaction = await rewards.connect(user3).claim();
            const claimTs3 = await helpers.getLatestBlockTimestamp();
            const fetchAmount_6= calcReward(claimTs1,claimTs3,end-start,amount);
            const multiplier_6= fetchAmount_6.mul(decimals).div(depositAmount.add(depositAmount.mul(2)).add(depositAmount.mul(3)));
            const rewardsAmount_user3 = multiplier_4.add(multiplier_5).add(multiplier_6).mul(depositAmount.mul(3)).div(decimals);
            expect(tx3).to.emit(rewards, "Claim").withArgs(await user3.getAddress(),rewardsAmount_user3);

            
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
