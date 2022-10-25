const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { sleep } = require("./utils");

// ALTAVA Token (TAVA)
// const initialSupply = "5000";
// const initialSupplyWei = ethers.utils.parseEther(initialSupply);
const testId = "test_id";

describe("Third-Party NFT Chef", function () {
    // Network to that snapshot in every test.
    async function deployFixture() {
        // Get the ContractFactory and Signers here.
        const [owner, addr1, addr2] = await ethers.getSigners();

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
        // Deploy ThirdParty NFT contract
        const ThirdPartyNFT = await ethers.getContractFactory("ThirdPartyNFT");
        const ThirdPartyNFTContract = await ThirdPartyNFT.deploy(
            owner.address
        );
        await ThirdPartyNFTContract.deployed();

        // Deploy NFTMasterChef contract
        const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");
        const NFTMasterChefContract = await NFTMasterChef.deploy(
            TAVAContract.address,
            SecondSkinNFTContract.address
        );
        await NFTMasterChefContract.deployed();

        // Deploy NFTChef contract
        await NFTMasterChefContract.deploy(
            testId,
            ThirdPartyNFTContract.address,
            [150, 250, 350]
        )
        const NFTChefAddres = await NFTMasterChefContract.getChefAddress(0);
        // Deployed contract
        const NFTChefContract = await ethers.getContractAt("NFTChef", NFTChefAddres);

        // Fixtures can return anything you consider useful for your tests
        return { 
            TAVAContract, SecondSkinNFTContract, ThirdPartyNFTContract, NFTMasterChefContract, NFTChefContract, owner, addr1, addr2
        };
    }

    // You can nest describe calls to create subsections.
    describe("NFTMasterChef: Deployment should work correctly", function () {
        // If the callback function is async, Mocha will `await` it.
        it("Should set the right owner and secondskin nft", async function () {
            const { SecondSkinNFTContract, NFTMasterChefContract, owner } = await loadFixture(deployFixture);

            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.            
            expect(await NFTMasterChefContract.owner()).to.equal(owner.address);
            expect(await NFTMasterChefContract.secondskinNFT()).to.equal(SecondSkinNFTContract.address);

        });

        it("Deploy same reward NFT chef should be failed", async function () {
            const { ThirdPartyNFTContract, NFTMasterChefContract } = await loadFixture(deployFixture);

            // Deploy NFTChef contract
            await expect(
                NFTMasterChefContract.deploy(   
                    testId,             
                    ThirdPartyNFTContract.address,
                    [150, 250, 350]
                )
            ).to.be.revertedWithoutReason();
        });

        it("Deployed Chef counter should work", async function () {
            const { SecondSkinNFTContract, NFTMasterChefContract } = await loadFixture(deployFixture);

            // Deploy NFTChef contract
            await NFTMasterChefContract.deploy(   
                testId,
                // for testing.             
                SecondSkinNFTContract.address,
                [150, 250, 350]
            )
            expect(await NFTMasterChefContract.total_count()).to.equal(2);
        });

    });


    // You can nest describe calls to create subsections.
    describe("NFTChef: Deployment should work correctly", function () {
        // If the callback function is async, Mocha will `await` it.
        it("Should set the right owner and right settings", async function () {
            const { TAVAContract, SecondSkinNFTContract, ThirdPartyNFTContract, NFTMasterChefContract, NFTChefContract, owner } = await loadFixture(deployFixture);
            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.            
            expect(await NFTChefContract.owner()).to.equal(owner.address);
            expect(await NFTChefContract.NFT_MASTER_CHEF_FACTORY()).to.equal(NFTMasterChefContract.address);
            expect(await NFTChefContract.secondSkinNFT()).to.equal(SecondSkinNFTContract.address);
            expect(await NFTChefContract.rewardNFT()).to.equal(ThirdPartyNFTContract.address);
            expect(await NFTChefContract.stakedToken()).to.equal(TAVAContract.address);
            expect(await NFTChefContract.booster_total()).to.equal(3);
            expect(await NFTChefContract.getBoosterValue(0)).to.equal(0);
            expect(await NFTChefContract.getBoosterValue(1)).to.equal(150);
            expect(await NFTChefContract.getBoosterValue(2)).to.equal(250);
            expect(await NFTChefContract.getBoosterValue(3)).to.equal(350);
            expect(await NFTChefContract.getBoosterValue(50)).to.equal(350);
        });

        // If the callback function is async, Mocha will `await` it.
        it("SetBoosterValue: Setting NFTChef should work", async function () {
            const { TAVAContract, SecondSkinNFTContract, ThirdPartyNFTContract, NFTMasterChefContract, NFTChefContract, owner } = await loadFixture(deployFixture);
            // set another booster
            console.log("√ SetBoosterValue: Out range of index should failed");
            await expect(
                NFTChefContract.setBoosterValue(5, 100)
            ).to.be.revertedWith("Out of index")

            console.log("√ SetBoosterValue: Index should not be zero");
            await expect(
                NFTChefContract.setBoosterValue(0, 100)
            ).to.be.revertedWith("Index should not be zero")

            console.log("√ SetBoosterValue: Booster value should not be zero");
            await expect(
                NFTChefContract.setBoosterValue(1, 0)
            ).to.be.revertedWith("Booster value should not be zero")

            console.log("√ SetBoosterValue: Amount in use");
            await expect(
                NFTChefContract.setBoosterValue(1, 150)
            ).to.be.revertedWith("Amount in use")

            console.log("√ SetBoosterValue: Booster value should not be over than 50%");
            await expect(
                NFTChefContract.setBoosterValue(1, 5001)
            ).to.be.revertedWith("Booster value should not be over than 50%")

            console.log("√ SetBoosterValue: Booster value should be increased");
            await expect(
                NFTChefContract.setBoosterValue(1, 251)
            ).to.be.revertedWith("Booster value should be increased")

            // set booster value to 15.5%
            await NFTChefContract.setBoosterValue(1, 155)
            expect(await NFTChefContract.getBoosterValue(1)).to.equal(155);
            await NFTChefContract.setBoosterValue(4, 355)
            expect(await NFTChefContract.getBoosterValue(4)).to.equal(355);
            expect(await NFTChefContract.booster_total()).to.equal(4);
        });

        // If the callback function is async, Mocha will `await` it.
        it("setRequiredLockAmount: Setting NFTChef should work", async function () {
            const { NFTChefContract } = await loadFixture(deployFixture);
            
            // set required config
            // 30days, 1000 TAVA, 1 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                30, 1000, 1, true
            );
            // 60days, 2000 TAVA, 3 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                60, 2000, 3, true
            );
            // 90days, 3000 TAVA, 5 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                90, 3000, 5, true
            );

            // fetch 30days config
            const configdata = await NFTChefContract.getConfig(30);

            expect(configdata.requiredLockAmount).to.equal(1000);
            expect(configdata.rewardNFTAmount).to.equal(1);
            expect(configdata.isLive).to.equal(true);


            // 90days, 3000 TAVA, 5 ThirdParty Reward NFT, false
            await NFTChefContract.setRequiredLockAmount(
                90, 3000, 5, false
            );
            const config90Data = await NFTChefContract.getConfig(90);
            expect(config90Data.isLive).to.equal(false);
        });
    });

    // You can nest describe calls to create subsections.
    describe("NFTChef: Stake && Unstake", function () {
        // get required amount for stake.
        const getRequiredAmount = async (SecondSkinNFTContract, NFTChefContract, period, sender) => {
            const nftBalance = await SecondSkinNFTContract.balanceOf(sender);
            const configData = await NFTChefContract.getConfig(period);
            const boosterValue = await NFTChefContract.getBoosterValue(nftBalance);
            let requireAmount = ethers.utils.formatEther(configData.requiredLockAmount);
            const decreaseAmount = parseFloat(requireAmount) * parseFloat(boosterValue) / 10000;
            if(decreaseAmount > 0) {
                requireAmount = (parseFloat(requireAmount) - decreaseAmount).toString();
            }
            // console.log(requireAmount);
            return ethers.utils.parseEther(requireAmount);
        }
        // Before stake, need to set full configuration.
        const setConfig = async (NFTChefContract) => {
            // set required config
            // 30days, 1000 TAVA, 1 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                30, ethers.utils.parseEther("1000"), 1, true
            );
            // 60days, 2000 TAVA, 3 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                60, ethers.utils.parseEther("2000"), 3, true
            );
            // 90days, 3000 TAVA, 5 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                90, ethers.utils.parseEther("3000"), 5, true
            );
        }

        it("stake should work", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setConfig(NFTChefContract);

            const period = 30; // 30days;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, owner.address);

            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount);
            // stake 30days
            await NFTChefContract.stake(period);
        });

        it("Double stake should not work", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setConfig(NFTChefContract);

            const period = 90; // 90days;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, owner.address);
            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount);
            // stake 30days
            await NFTChefContract.stake(60);
            await expect(
                NFTChefContract.stake(60)
            ).to.be.revertedWith("Stake: Invalid period")
            await expect(
                NFTChefContract.stake(30)
            ).to.be.revertedWith("Stake: Invalid period")
        });

        it("Extend staking duration should work", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setConfig(NFTChefContract);

            const period = 90; // 90days;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, owner.address);
            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount);
            // stake 30days
            await expect(NFTChefContract.stake(30)).to.changeTokenBalances(
                TAVAContract, [NFTChefContract.address, owner.address],
                [ethers.utils.parseEther("1000"), ethers.utils.parseEther("1000").mul(-1)]
            );
            const curStakerInfo1 = await NFTChefContract.getCurrentStakerInfo(owner.address);
            expect(curStakerInfo1.lockedAmount).to.be.equal(ethers.utils.parseEther("1000"));
            expect(curStakerInfo1.lockDuration).to.be.equal(30);
            expect(curStakerInfo1.rewardAmount).to.be.equal(1);
            expect(curStakerInfo1.unstaked).to.be.equal(false);

            await NFTChefContract.stake(60);
            const curStakerInfo2 = await NFTChefContract.getCurrentStakerInfo(owner.address);
            expect(curStakerInfo2.lockedAmount).to.be.equal(ethers.utils.parseEther("2000"));
            expect(curStakerInfo2.lockDuration).to.be.equal(60);
            expect(curStakerInfo2.rewardAmount).to.be.equal(3);
            expect(curStakerInfo2.unstaked).to.be.equal(false);

            expect(curStakerInfo1.lockedAt).to.be.equal(curStakerInfo2.lockedAt);
            expect(curStakerInfo2.unlockAt - curStakerInfo1.unlockAt).to.be.equal(30);
            expect(curStakerInfo2.unlockAt - curStakerInfo1.lockedAt).to.be.equal(60);
        });

        // Before stake, need to set full configuration.
        const setShortTimeConfig = async (NFTChefContract) => {
            // set required config
            // 3 seconds, 1000 TAVA, 1 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                3, ethers.utils.parseEther("1000"), 1, true
            );
            // 6 seconds, 2000 TAVA, 3 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                6, ethers.utils.parseEther("2000"), 3, true
            );
            // 9 seconds, 3000 TAVA, 5 ThirdParty Reward NFT, true
            await NFTChefContract.setRequiredLockAmount(
                9, ethers.utils.parseEther("3000"), 5, true
            );
        }

        it("Unstake should not work before unlock", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setShortTimeConfig(NFTChefContract);

            const period = 9; // 9 seconds;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, owner.address);
            // console.log(requireAmount)
            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount);
            // stake 30days
            await NFTChefContract.stake(3);

            await expect(
                NFTChefContract.unstake()
            ).to.be.revertedWith("Not able to withdraw");
        });

        it("Unstake should work after unlocked", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setShortTimeConfig(NFTChefContract);

            const period = 9; // 9 seconds;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, owner.address);
            // console.log(requireAmount)
            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount);
            // Lock 3 seconds
            await NFTChefContract.stake(3);
            // Wait 4 seconds for unlocking.
            await sleep(4*1000);
            // Unstake and check balance changes
            await expect(
                NFTChefContract.unstake()
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, owner.address], 
                [ethers.utils.parseEther("1000").mul(-1), 
                ethers.utils.parseEther("1000")]
            )

            const currentIndex = await NFTChefContract.getUserStakeIndex(owner.address);
            expect(currentIndex).to.be.equal(1);

            const curStakerInfo = await NFTChefContract.getStakerInfo(owner.address, currentIndex-1);
            expect(curStakerInfo.lockedAmount).to.be.equal(ethers.utils.parseEther("1000"));
            expect(curStakerInfo.lockDuration).to.be.equal(3);
            expect(curStakerInfo.rewardAmount).to.be.equal(1);
            expect(curStakerInfo.unstaked).to.be.equal(true);

        });

        it("Booster value changes correctly based on NFT amount", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setShortTimeConfig(NFTChefContract);

            // SecondSkinNFT check.
            const ssn_balance = await SecondSkinNFTContract.balanceOf(owner.address);
            expect(ssn_balance).to.be.equal(0);
            // mint ssn
            await SecondSkinNFTContract.mint("test_uri");
            const ssn_balance2 = await SecondSkinNFTContract.balanceOf(owner.address);
            expect(ssn_balance2).to.be.equal(1);

            const period = 3; // 9 seconds;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, owner.address);
            // console.log(requireAmount)
            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount);
            // stake 30days
            await expect(
                NFTChefContract.stake(3)
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, owner.address], 
                [requireAmount, requireAmount.mul(-1)]
            )
            // Wait 4 seconds for unlocking.
            await sleep(4*1000);
            // Unstake and check balance changes
            await expect(
                NFTChefContract.unstake()
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, owner.address], 
                [requireAmount.mul(-1), requireAmount]
            )
        });

        it("Extend days option: Booster value changes correctly based on NFT amount", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setShortTimeConfig(NFTChefContract);

            // SecondSkinNFT check.
            const ssn_balance = await SecondSkinNFTContract.balanceOf(owner.address);
            expect(ssn_balance).to.be.equal(0);
            // mint ssn
            await SecondSkinNFTContract.mint("test_uri");
            const ssn_balance2 = await SecondSkinNFTContract.balanceOf(owner.address);
            expect(ssn_balance2).to.be.equal(1);

            const period = 3; // 9 seconds;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, owner.address);
            // console.log(requireAmount)
            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount);
            // stake 3 seconds
            await expect(
                NFTChefContract.stake(3)
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, owner.address], 
                [requireAmount, requireAmount.mul(-1)]
            )
            
            // Extend from 3 seconds to 6 seconds
            const period2 = 6;
            const requireAmount2 = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period2, owner.address);
            // console.log(requireAmount)
            // Before stake, need to approve token
            await TAVAContract.approve(NFTChefContract.address, requireAmount2.sub(requireAmount));
            // Extend from 3 to 6 seconds periods
            await expect(
                NFTChefContract.stake(6)
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, owner.address], 
                [requireAmount2.sub(requireAmount), requireAmount2.sub(requireAmount).mul(-1)]
            )

            // Wait 7 seconds for unlocking.
            await sleep(7*1000);
            // Unstake and check balance changes
            await expect(
                NFTChefContract.unstake()
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, owner.address], 
                [requireAmount2.mul(-1), requireAmount2]
            )
        });

        it("Panalty Check: Booster value changes correctly based on NFT amount", async function () {
            const { TAVAContract, SecondSkinNFTContract, NFTChefContract, owner, addr1 } = await loadFixture(deployFixture);
            await setShortTimeConfig(NFTChefContract);

            // Transfer TAVA token to addr1
            await TAVAContract.transfer(addr1.address, ethers.utils.parseEther("1000"));

            // SecondSkinNFT check.
            const ssn_balance = await SecondSkinNFTContract.connect(addr1).balanceOf(owner.address);
            expect(ssn_balance).to.be.equal(0);
            // mint ssn
            await SecondSkinNFTContract.mint("test_uri");
            await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 0);

            const ssn_balance2 = await SecondSkinNFTContract.balanceOf(addr1.address);
            expect(ssn_balance2).to.be.equal(1);

            const period = 3; // 9 seconds;
            const requireAmount = await getRequiredAmount(SecondSkinNFTContract, NFTChefContract, period, addr1.address);
            // console.log(requireAmount)
            // Before stake, need to approve token
            await TAVAContract.connect(addr1).approve(NFTChefContract.address, requireAmount);
            // stake 3 seconds
            await expect(
                NFTChefContract.connect(addr1).stake(3)
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, addr1.address], 
                [requireAmount, requireAmount.mul(-1)]
            )
            
            // Transfer NFT to others.
            await SecondSkinNFTContract.connect(addr1).transferFrom(addr1.address, owner.address, 0); // tokenID = 0
            
            const panaltyAmount = await NFTChefContract.connect(addr1).getPanaltyAmount(addr1.address);
            expect(panaltyAmount).to.be.equal(ethers.utils.parseEther("1000").sub(requireAmount));

            // Wait 4 seconds for unlocking.
            await sleep(4*1000);
            // Unstake and check balance changes
            await expect(
                NFTChefContract.connect(addr1).unstake()
            ).to.changeTokenBalances(
                TAVAContract, 
                [NFTChefContract.address, addr1.address, owner.address], 
                [requireAmount.mul(-1), requireAmount.sub(panaltyAmount), panaltyAmount]
            )
        });
    })
})