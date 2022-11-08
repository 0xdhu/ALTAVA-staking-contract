const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { sleep } = require("./utils");

const testId = "test_id";
// ALTAVA Token (TAVA)

describe("MasterChef and SmartChef", function () {
    let poolLimitPerUser = ethers.utils.parseEther("0");
    let rewardPerBlock = ethers.utils.parseEther("10");
    let blockNumber;
    let startBlock;
    let endBlock;
    const booster = [150, 250, 350]
    
    const increaseBlockNumber = async (num) => {
        for(let i=0; i<num; i++) {
            await ethers.provider.send('evm_mine');
        }
    }
    const increaseDays = async (num) => {
        const secondOfDays = num * 24 * 60 * 60;
        await ethers.provider.send('evm_increaseTime', [secondOfDays]);
    }
    const getSecondsFromDays = (num) => {
        const secondOfDays = num * 24 * 60 * 60;
        return secondOfDays;
    }

    // Network to that snapshot in every test.
    async function deployFixture() {
        // Get the ContractFactory and Signers here.
        const [owner, addr1, addr2] = await ethers.getSigners();

        blockNumber = await ethers.provider.getBlockNumber();

        startBlock = blockNumber + 100;
        endBlock = blockNumber + 500;

        // Deploy TAVA Token contract
        const TAVA = await ethers.getContractFactory("TAVA");
        const TAVAContract = await TAVA.deploy();
        await TAVAContract.deployed();

        // Deploy SecondskinNFT contract
        const SecondSkinNFT = await ethers.getContractFactory("SecondSkinNFT");
        const SecondSkinNFTContract = await SecondSkinNFT.deploy(
            owner.address
        );
        await SecondSkinNFTContract.deployed();

        // Deploy ThirdPartyToken contract
        const ThirdPartyToken = await ethers.getContractFactory("ThirdPartyToken");
        const ThirdPartyTokenContract = await ThirdPartyToken.deploy(
            "Test NFT Token",
            "TNT"
        );
        await ThirdPartyTokenContract.deployed();

        // Deploy NFT Staking Contract
        const NFTStaking = await ethers.getContractFactory("NFTStaking");
        const NFTStakingContract = await NFTStaking.deploy(
            SecondSkinNFTContract.address
        );
        await NFTStakingContract.deployed();

        // Deploy MasterChef contract
        const MasterChef = await ethers.getContractFactory("MasterChef");
        const MasterChefContract = await MasterChef.deploy(
            NFTStakingContract.address
        );
        await MasterChefContract.deployed();

        // Deploy SmartChef contract
        await MasterChefContract.deploy(
            testId,
            TAVAContract.address,
            ThirdPartyTokenContract.address,
            rewardPerBlock,
            startBlock,
            endBlock,
            poolLimitPerUser,
            "0",
            owner.address
        )
        const SmartChefAddres = await MasterChefContract.getChefAddress(0);

        // Deployed contract
        const SmartChefContract = await ethers.getContractAt("SmartChef", SmartChefAddres);

        // Fixtures can return anything you consider useful for your tests
        return { 
            TAVAContract, NFTStakingContract, SecondSkinNFTContract, ThirdPartyTokenContract, MasterChefContract, SmartChefContract, owner, addr1, addr2
        };
    }

    // You can nest describe calls to create subsections.
    describe("NFTStaking: Deployment should work correctly", function () {
        // If the callback function is async, Mocha will `await` it.
        it("Should set the right owner and secondskin nft", async function () {
            const { NFTStakingContract, SecondSkinNFTContract, MasterChefContract, SmartChefContract, owner } = await loadFixture(deployFixture);

            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.            
            expect(await NFTStakingContract.owner()).to.equal(owner.address);
            expect(await NFTStakingContract.secondskinNFT()).to.equal(SecondSkinNFTContract.address);
            expect(await SmartChefContract.owner()).to.equal(owner.address);
            expect(await MasterChefContract.owner()).to.equal(owner.address);
        });

        // If the callback function is async, Mocha will `await` it.
        it("SetBoosterArray should work", async function () {
            const { SmartChefContract, owner } = await loadFixture(deployFixture);

            await SmartChefContract.setBoosterArray(booster);
            expect(await SmartChefContract.booster_total()).to.equal(3);
            expect(await SmartChefContract.getBoosterValue(1)).to.equal("150");
            expect(await SmartChefContract.getBoosterValue(2)).to.equal("250");
            expect(await SmartChefContract.getBoosterValue(3)).to.equal("350");

            await SmartChefContract.setBoosterValue("1", "180");
            expect(await SmartChefContract.booster_total()).to.equal(3);
            expect(await SmartChefContract.getBoosterValue(1)).to.equal("180");
            await SmartChefContract.setBoosterValue("4", "450");
            expect(await SmartChefContract.booster_total()).to.equal(4);

            await expect(
                SmartChefContract.setBoosterValue("0", "200")
            ).to.be.revertedWith("Index should not be zero")

            await expect(
                SmartChefContract.setBoosterValue("1", "270")
            ).to.be.revertedWith("Booster value should be increased")

            await expect(
                SmartChefContract.setBoosterValue("6", "270")
            ).to.be.revertedWith("Out of index")
        });

        // Stake should work
        it("Stake should work", async function () {
            const { SmartChefContract, TAVAContract, owner } = await loadFixture(deployFixture);

            await SmartChefContract.setBoosterArray(booster);

            const lockAmount = ethers.utils.parseEther("1000");
            const lockDuration = 7 * 3600 * 24 // 7 days

            // Minimum lock period is one week
            await TAVAContract.approve(SmartChefContract.address, lockAmount)
            await expect(
                SmartChefContract.stake(lockAmount, lockDuration/2)
            ).to.be.revertedWith("Minimum lock period is one week")

            // Stake should work.
            await TAVAContract.approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.stake(lockAmount, lockDuration);

            // "Extend lock duration"
            await TAVAContract.approve(SmartChefContract.address, lockAmount)
            await expect(
                SmartChefContract.stake(lockAmount, lockDuration)
            ).to.be.revertedWith("Extend lock duration")

            // "Extend lock duration"
            await expect(
                SmartChefContract.stake("0", lockDuration)
            ).to.be.revertedWith("Not enough duration to extends")

            await expect(
                SmartChefContract.stake("0", lockDuration/2)
            ).to.be.revertedWith("Not enough duration to extends")
        });

        // Extend Stake should work
        it("Extend stake should work", async function () {
            const { SmartChefContract, TAVAContract, owner, addr1, addr2 } = await loadFixture(deployFixture);

            await SmartChefContract.setBoosterArray(booster);

            const lockAmount = ethers.utils.parseEther("1000");
            const lockDuration = 7 * 3600 * 24 // 7 days

            // Stake should work.
            await TAVAContract.approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.stake(lockAmount, lockDuration);

            // Extend staking
            SmartChefContract.stake("0", lockDuration * 2)

            // Check staker infos
            await TAVAContract.transfer(addr1.address, lockAmount)
            await TAVAContract.transfer(addr2.address, lockAmount)

            // Alice stake
            await TAVAContract.connect(addr1).approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);
            // Bob stake
            await TAVAContract.connect(addr2).approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.connect(addr2).stake(lockAmount, lockDuration);

            // Check detail infos
            const userInfo = await SmartChefContract.userInfo(owner.address);
            const aliceInfo = await SmartChefContract.userInfo(addr1.address);
            const bobInfo = await SmartChefContract.userInfo(addr2.address);

            expect(userInfo.lockedAmount).to.equal(lockAmount)
            expect(userInfo.lockEndTime.sub(userInfo.lockStartTime)).to.equal(lockDuration * 2);
            expect(userInfo.locked).to.equal(true);
            expect(userInfo.boosterValue).to.equal(ethers.utils.parseEther("0"));
            expect(userInfo.rewardDebt).to.equal(ethers.utils.parseEther("0"));
            expect(userInfo.rewards).to.equal(ethers.utils.parseEther("0"));

            expect(aliceInfo.lockedAmount).to.equal(lockAmount)
            expect(bobInfo.lockedAmount).to.equal(lockAmount)
        });


        // Reward Debt check
        it("Reward Debt should work", async function () {
            const { SmartChefContract, TAVAContract, owner, addr1, addr2 } = await loadFixture(deployFixture);
            await SmartChefContract.setBoosterArray(booster);

            const lockAmount = ethers.utils.parseEther("1000");
            const lockDuration = getSecondsFromDays(7) // 7 days

            await increaseBlockNumber(startBlock);
            // Stake should work.
            await TAVAContract.approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.stake(lockAmount, lockDuration);
            
            // Token from owner to alice
            await TAVAContract.transfer(addr1.address, lockAmount)
            await TAVAContract.transfer(addr2.address, lockAmount)

            // Alice stake
            await TAVAContract.connect(addr1).approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);

            const aliceInfo0 = await SmartChefContract.userInfo(addr1.address);
            // Third party token reward starts.
            await increaseBlockNumber(5);

            // Alice extends
            await SmartChefContract.connect(addr1).stake(
                ethers.utils.parseEther("0"), lockDuration * 2
            );
            const PRECISION_FACTOR = await SmartChefContract.PRECISION_FACTOR();
            // PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));
            expect(PRECISION_FACTOR).to.equal(ethers.utils.parseUnits("1", `${30-18}`))

            const accTokenPerShare = await SmartChefContract.accTokenPerShare();
            const pending = aliceInfo0.lockedAmount.
                mul(accTokenPerShare).
                div(PRECISION_FACTOR).
                sub(aliceInfo0.rewardDebt);
                
            const reward = pending;

            const aliceInfo = await SmartChefContract.userInfo(addr1.address);
            expect(aliceInfo.rewards).to.equal(reward);

            const rewardDebt = aliceInfo.lockedAmount.mul(accTokenPerShare).div(PRECISION_FACTOR)
            expect(aliceInfo.rewardDebt).to.equal(rewardDebt);
        });

        // Unlock should work
        it("Unlock should work", async function () {
            const { SmartChefContract, TAVAContract, owner, addr1, addr2 } = await loadFixture(deployFixture);
            await SmartChefContract.setBoosterArray(booster);

            const lockAmount = ethers.utils.parseEther("1000");
            const lockDuration = getSecondsFromDays(7) // 7 days

            await increaseBlockNumber(startBlock);
            // Stake should work.
            await TAVAContract.approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.stake(lockAmount, lockDuration);
            
            // Token from owner to alice
            await TAVAContract.transfer(addr1.address, lockAmount)
            await TAVAContract.transfer(addr2.address, lockAmount)

            // Alice stake
            await TAVAContract.connect(addr1).approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);

            // Third party token reward starts.
            await increaseBlockNumber(5);

            // Alice extends
            await SmartChefContract.connect(addr1).stake(
                ethers.utils.parseEther("0"), lockDuration * 2
            );

            // Unlock should not work before unlock days
            await expect(
                SmartChefContract.unlock(owner.address)
            ).to.be.revertedWith("Still in locked");

            await increaseDays(9);

            // Now unlock should work.
            SmartChefContract.unlock(owner.address)

            // Double unlock should not work
            await expect(
                SmartChefContract.unlock(owner.address)
            ).to.be.revertedWith("Empty to unlock");

            // ---- Alice
            // Unlock should not work before unlock days
            await expect(
                SmartChefContract.connect(addr1).unlock(addr1.address)
            ).to.be.revertedWith("Still in locked");
            await increaseDays(9);
            // Now unlock should work.
            SmartChefContract.connect(addr1).unlock(addr1.address)
            // Double unlock should not work
            await expect(
                SmartChefContract.connect(addr1).unlock(addr1.address)
            ).to.be.revertedWith("Empty to unlock");
        });

        // Admin should be able to unlock user's token
        it("Admin should be able to unlock user's token", async function () {
            const { SmartChefContract, TAVAContract, owner, addr1, addr2 } = await loadFixture(deployFixture);
            await SmartChefContract.setBoosterArray(booster);

            const lockAmount = ethers.utils.parseEther("1000");
            const lockDuration = getSecondsFromDays(7) // 7 days

            await increaseBlockNumber(startBlock);
            // Stake should work.
            await TAVAContract.approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.stake(lockAmount, lockDuration);
            
            // Token from owner to alice
            await TAVAContract.transfer(addr1.address, lockAmount)
            await TAVAContract.transfer(addr2.address, lockAmount)

            // Alice stake
            await TAVAContract.connect(addr1).approve(SmartChefContract.address, lockAmount)
            await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);

            // Third party token reward starts.
            await increaseBlockNumber(5);

            // Alice extends
            await SmartChefContract.connect(addr1).stake(
                ethers.utils.parseEther("0"), lockDuration * 2
            );
          
            // ---- Alice
            // Unlock should not work before unlock days
            await expect(
                SmartChefContract.unlock(addr1.address)
            ).to.be.revertedWith("Still in locked");

            await increaseDays(18);
            // Now unlock should work.
            SmartChefContract.unlock(addr1.address)
            // Double unlock should not work
            await expect(
                SmartChefContract.connect(addr1).unlock(addr1.address)
            ).to.be.revertedWith("Empty to unlock");
        });
    });
});