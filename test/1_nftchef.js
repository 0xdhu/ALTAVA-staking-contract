const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

// ALTAVA Token (TAVA)
// const initialSupply = "5000";
// const initialSupplyWei = ethers.utils.parseEther(initialSupply);
const testId = "test_id";
const cannot_zero = "Cannot be zero address";
const zero_address = "0x0000000000000000000000000000000000000000";
const not_owner = "Ownable: caller is not the owner";

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
    const SecondSkinNFTContract = await SecondSkinNFT.deploy(owner.address);
    await SecondSkinNFTContract.deployed();

    // Deploy ThirdParty NFT contract
    const ThirdPartyNFT = await ethers.getContractFactory("ThirdPartyNFT");
    const ThirdPartyNFTContract = await ThirdPartyNFT.deploy(
      owner.address,
      "Test NFT Token",
      "TNT"
    );
    await ThirdPartyNFTContract.deployed();

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

    // Deploy NFTMasterChef contract
    const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");

    await expect(
      NFTMasterChef.deploy(
        NFTStakingContract.address,
        NFTStakingContract.address
      )
    ).to.be.revertedWithoutReason();

    const NFTMasterChefContract = await NFTMasterChef.deploy(
      TAVAContract.address,
      NFTStakingContract.address
    );
    await NFTMasterChefContract.deployed();

    await expect(
      NFTMasterChefContract.setNFTStaking(zero_address)
    ).to.be.revertedWith(cannot_zero);

    await expect(
      NFTMasterChefContract.connect(addr1).setNFTStaking(
        NFTStakingContract.address
      )
    ).to.be.revertedWith(not_owner);

    await NFTMasterChefContract.setNFTStaking(NFTStakingContract.address);

    await NFTStakingContract.setMasterChef(MasterChefContract.address);
    await NFTStakingContract.setNFTMasterChef(NFTMasterChefContract.address);

    await expect(
      NFTMasterChefContract.connect(addr1).deploy(
        testId,
        ThirdPartyNFTContract.address,
        [150, 250, 350]
      )
    ).to.be.revertedWith(not_owner);

    await expect(
      NFTMasterChefContract.deploy(testId, "", [150, 250, 350])
    ).to.be.revertedWith(cannot_zero);

    await expect(
      NFTMasterChefContract.deploy(
        testId,
        ThirdPartyNFTContract.address,
        [0, 250, 6000]
      )
    ).to.be.revertedWith("Booster rate: overflow 50%");

    await expect(
      NFTMasterChefContract.deploy(
        testId,
        ThirdPartyNFTContract.address,
        [0, 2500, 600]
      )
    ).to.be.revertedWith("Booster value: invalid");
    // Deploy NFTChef contract
    await NFTMasterChefContract.deploy(
      testId,
      ThirdPartyNFTContract.address,
      [150, 250, 350]
    );
    // This is just testing
    NFTMasterChefContract.deploy(
      testId,
      SecondSkinNFTContract.address,
      [150, 250, 350]
    );

    await expect(NFTMasterChefContract.getChefAddress(0)).to.be.revertedWith(
      "Chef: not exist"
    );

    // Index starts from 1
    const NFTChefAddres = await NFTMasterChefContract.getChefAddress(1);
    // Deployed contract
    const NFTChefContract = await ethers.getContractAt(
      "NFTChef",
      NFTChefAddres
    );

    await expect(
      NFTChefContract.initialize(
        TAVAContract.address,
        "TAVA Reward",
        owner.address,
        NFTStakingContract.address,
        [0, 2500, 600]
      )
    ).to.be.revertedWith("Already initialized");

    // Fixtures can return anything you consider useful for your tests
    return {
      TAVAContract,
      NFTStakingContract,
      SecondSkinNFTContract,
      ThirdPartyNFTContract,
      NFTMasterChefContract,
      NFTChefContract,
      owner,
      addr1,
      addr2,
    };
  }

  const getSecondsFromDays = (d) => {
    return d * 86400;
  };
  // You can nest describe calls to create subsections.
  describe("NFTMasterChef: Deployment should work correctly", function () {
    // If the callback function is async, Mocha will `await` it.
    it("Should set the right owner and secondskin nft", async function () {
      const { NFTStakingContract, NFTMasterChefContract, owner } =
        await loadFixture(deployFixture);

      // This test expects the owner variable stored in the contract to be
      // equal to our Signer's owner.
      expect(await NFTMasterChefContract.owner()).to.equal(owner.address);
      expect(await NFTMasterChefContract.nftstaking()).to.equal(
        NFTStakingContract.address
      );
    });

    it("Deploy same reward NFT chef should be failed", async function () {
      const { ThirdPartyNFTContract, NFTMasterChefContract } =
        await loadFixture(deployFixture);

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
      const { NFTMasterChefContract } = await loadFixture(deployFixture);

      expect(await NFTMasterChefContract.totalCount()).to.equal(2);
    });
  });
  // You can nest describe calls to create subsections.
  describe("NFTChef: Deployment should work correctly", function () {
    // If the callback function is async, Mocha will `await` it.
    it("Should set the right owner and right settings", async function () {
      const {
        TAVAContract,
        NFTStakingContract,
        ThirdPartyNFTContract,
        NFTMasterChefContract,
        NFTChefContract,
        owner,
      } = await loadFixture(deployFixture);
      // This test expects the owner variable stored in the contract to be
      // equal to our Signer's owner.
      expect(await NFTChefContract.owner()).to.equal(owner.address);
      expect(await NFTChefContract.nftMasterChefFactory()).to.equal(
        NFTMasterChefContract.address
      );
      expect(await NFTChefContract.nftstaking()).to.equal(
        NFTStakingContract.address
      );
      expect(await NFTChefContract.rewardNFT()).to.equal(
        ThirdPartyNFTContract.address
      );
      expect(await NFTChefContract.stakedToken()).to.equal(
        TAVAContract.address
      );
      expect(await NFTChefContract.boosterTotal()).to.equal(3);
      expect(await NFTChefContract.getBoosterValue(0)).to.equal(0);
      expect(await NFTChefContract.getBoosterValue(1)).to.equal(150);
      expect(await NFTChefContract.getBoosterValue(2)).to.equal(250);
      expect(await NFTChefContract.getBoosterValue(3)).to.equal(350);
      expect(await NFTChefContract.getBoosterValue(50)).to.equal(350);
    });

    // If the callback function is async, Mocha will `await` it.
    it("SetBoosterValue: Setting NFTChef should work", async function () {
      const { NFTChefContract, addr1 } = await loadFixture(deployFixture);
      // set another booster
      console.log("√ SetBoosterValue: Out range of index should failed");
      await expect(NFTChefContract.setBoosterValue(5, 100)).to.be.revertedWith(
        "Out of index"
      );

      console.log("√ SetBoosterValue: Index should not be zero");
      await expect(NFTChefContract.setBoosterValue(0, 100)).to.be.revertedWith(
        "Index should not be zero"
      );

      console.log("√ SetBoosterValue: Booster value should not be zero");
      await expect(NFTChefContract.setBoosterValue(1, 0)).to.be.revertedWith(
        "Booster value should not be zero"
      );

      console.log("√ SetBoosterValue: Amount in use");
      await expect(NFTChefContract.setBoosterValue(1, 150)).to.be.revertedWith(
        "Amount in use"
      );

      console.log("√ SetBoosterValue: Booster rate: overflow");
      await expect(NFTChefContract.setBoosterValue(1, 5001)).to.be.revertedWith(
        "Booster rate: overflow 50%"
      );

      console.log("√ SetBoosterValue: Booster value: invalid");
      await expect(NFTChefContract.setBoosterValue(1, 251)).to.be.revertedWith(
        "Booster value: invalid"
      );

      console.log("√ SetBoosterValue: Booster value: invalid");
      await expect(NFTChefContract.setBoosterValue(2, 351)).to.be.revertedWith(
        "Booster value: invalid"
      );

      console.log("√ SetBoosterValue: not admin");
      await expect(
        NFTChefContract.connect(addr1).setBoosterValue(1, 251)
      ).to.be.revertedWith(not_owner);

      // set booster value to 15.5%
      await NFTChefContract.setBoosterValue(1, 155);
      expect(await NFTChefContract.getBoosterValue(1)).to.equal(155);
      await NFTChefContract.setBoosterValue(4, 355);

      console.log("√ SetBoosterValue: Booster value: invalid");
      await NFTChefContract.setBoosterValue(2, 255);
      await expect(NFTChefContract.setBoosterValue(3, 250)).to.be.revertedWith(
        "Booster value: invalid"
      );
      await expect(NFTChefContract.setBoosterValue(2, 351)).to.be.revertedWith(
        "Booster value: invalid"
      );

      expect(await NFTChefContract.getBoosterValue(4)).to.equal(355);
      expect(await NFTChefContract.boosterTotal()).to.equal(4);

      await NFTChefContract.setBoosterValue(4, 0);
      await NFTChefContract.setBoosterValue(3, 0);
      await NFTChefContract.setBoosterValue(2, 0);
      await NFTChefContract.setBoosterValue(1, 351);
    });

    // If the callback function is async, Mocha will `await` it.
    it("setRequiredLockAmount: Setting NFTChef should work", async function () {
      const { NFTChefContract, addr1 } = await loadFixture(deployFixture);

      await expect(
        NFTChefContract.connect(addr1).setRequiredLockAmount(30, 1000, 1, true)
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await expect(
        NFTChefContract.setRequiredLockAmount(30, 1000, 1, true)
      ).to.be.revertedWith("Lock period: at least 1 day");
      // set required config
      // 30days, 1000 TAVA, 1 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(30),
        1000,
        1,
        true
      );
      // 60days, 2000 TAVA, 3 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(60),
        2000,
        3,
        true
      );
      // 90days, 3000 TAVA, 5 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(90),
        3000,
        5,
        true
      );

      // fetch 30days config
      const configdata = await NFTChefContract.getConfig(
        getSecondsFromDays(30)
      );

      expect(configdata.requiredLockAmount).to.equal(1000);
      expect(configdata.rewardNFTAmount).to.equal(1);
      expect(configdata.isLive).to.equal(true);

      // 90days, 3000 TAVA, 5 ThirdParty Reward NFT, false
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(90),
        3000,
        5,
        false
      );
      const config90Data = await NFTChefContract.getConfig(
        getSecondsFromDays(90)
      );
      expect(config90Data.isLive).to.equal(false);
    });
  });

  // You can nest describe calls to create subsections.
  describe("NFTChef: Stake && Unstake", function () {
    // get required amount for stake.
    const getRequiredAmount = async (
      NFTStakingContract,
      NFTChefContract,
      period,
      sender
    ) => {
      const nftBalance = await NFTStakingContract.getStakedNFTCount(sender);
      const configData = await NFTChefContract.getConfig(period);
      const boosterValue = await NFTChefContract.getBoosterValue(nftBalance);
      let requireAmount = ethers.utils.formatEther(
        configData.requiredLockAmount
      );
      const decreaseAmount =
        (parseFloat(requireAmount) * parseFloat(boosterValue)) / 10000;
      if (decreaseAmount > 0) {
        requireAmount = (parseFloat(requireAmount) - decreaseAmount).toString();
      }
      // console.log(requireAmount);
      return ethers.utils.parseEther(requireAmount);
    };
    // Before stake, need to set full configuration.
    const setConfig = async (NFTChefContract) => {
      // set required config
      // 30days, 1000 TAVA, 1 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(30),
        ethers.utils.parseEther("1000"),
        1,
        true
      );
      // 60days, 2000 TAVA, 3 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(60),
        ethers.utils.parseEther("2000"),
        3,
        true
      );
      // 90days, 3000 TAVA, 5 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(90),
        ethers.utils.parseEther("3000"),
        5,
        true
      );
    };

    it("stake should work when notPaused", async function () {
      const {
        TAVAContract,
        NFTStakingContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setConfig(NFTChefContract);

      const period = getSecondsFromDays(30); // 30days;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );

      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);

      await expect(
        NFTChefContract.connect(addr1).setPause(true)
      ).to.be.revertedWith(not_owner);

      await NFTChefContract.setPause(true);
      await expect(NFTChefContract.stake(period)).to.be.revertedWith(
        "Pausable: paused"
      );

      await NFTChefContract.setPause(false);
      await expect(NFTChefContract.stake(5)).to.be.revertedWith(
        "This option is not in live"
      );
      // stake 30days
      await NFTChefContract.stake(period);
    });

    it("Double stake should not work", async function () {
      const {
        TAVAContract,
        NFTStakingContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setConfig(NFTChefContract);

      const period = getSecondsFromDays(90); // 90days;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // stake 30days
      await NFTChefContract.stake(getSecondsFromDays(60));
      await expect(
        NFTChefContract.stake(getSecondsFromDays(60))
      ).to.be.revertedWith("Stake: Invalid period");
      await expect(
        NFTChefContract.stake(getSecondsFromDays(30))
      ).to.be.revertedWith("Stake: Invalid period");
    });

    it("Extend staking duration should work", async function () {
      const {
        TAVAContract,
        NFTStakingContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setConfig(NFTChefContract);

      const period = getSecondsFromDays(90); // 90days;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // stake 30days
      await expect(
        NFTChefContract.stake(getSecondsFromDays(30))
      ).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [
          ethers.utils.parseEther("1000"),
          ethers.utils.parseEther("1000").mul(-1),
        ]
      );
      const curStakerInfo1 = await NFTChefContract.getCurrentStakerInfo(
        owner.address
      );
      expect(curStakerInfo1.lockedAmount).to.be.equal(
        ethers.utils.parseEther("1000")
      );
      expect(curStakerInfo1.lockDuration).to.be.equal(getSecondsFromDays(30));
      expect(curStakerInfo1.rewardAmount).to.be.equal(1);
      expect(curStakerInfo1.unstaked).to.be.equal(false);

      await NFTChefContract.stake(getSecondsFromDays(60));
      const curStakerInfo2 = await NFTChefContract.getCurrentStakerInfo(
        owner.address
      );
      expect(curStakerInfo2.lockedAmount).to.be.equal(
        ethers.utils.parseEther("2000")
      );
      expect(curStakerInfo2.lockDuration).to.be.equal(getSecondsFromDays(60));
      expect(curStakerInfo2.rewardAmount).to.be.equal(3);
      expect(curStakerInfo2.unstaked).to.be.equal(false);

      expect(curStakerInfo1.lockedAt).to.be.equal(curStakerInfo2.lockedAt);
      expect(curStakerInfo2.unlockAt - curStakerInfo1.unlockAt).to.be.equal(
        getSecondsFromDays(30)
      );
      expect(curStakerInfo2.unlockAt - curStakerInfo1.lockedAt).to.be.equal(
        getSecondsFromDays(60)
      );
    });
    // Before stake, need to set full configuration.
    const setShortTimeConfig = async (NFTChefContract) => {
      // set required config
      // 3 days, 1000 TAVA, 1 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(3),
        ethers.utils.parseEther("1000"),
        1,
        true
      );
      // 6 days, 2000 TAVA, 3 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(6),
        ethers.utils.parseEther("2000"),
        3,
        true
      );
      // 9 days, 3000 TAVA, 5 ThirdParty Reward NFT, true
      await NFTChefContract.setRequiredLockAmount(
        getSecondsFromDays(9),
        ethers.utils.parseEther("3000"),
        5,
        true
      );
    };

    it("Unstake should not work before unlock", async function () {
      const { TAVAContract, NFTStakingContract, NFTChefContract, owner } =
        await loadFixture(deployFixture);

      await setShortTimeConfig(NFTChefContract);

      const period = getSecondsFromDays(9); // 9 seconds;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );
      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // stake 30days
      await NFTChefContract.stake(getSecondsFromDays(3));

      await expect(NFTChefContract.unstake("Address")).to.be.revertedWith(
        "Not able to withdraw"
      );
    });

    it("Unstake should work after unlocked", async function () {
      const {
        TAVAContract,
        NFTStakingContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setShortTimeConfig(NFTChefContract);

      const period = getSecondsFromDays(9); // 9 seconds;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );
      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // Lock 3 seconds
      await NFTChefContract.stake(getSecondsFromDays(3));
      // Wait 4 seconds for unlocking.
      await ethers.provider.send("evm_increaseTime", [getSecondsFromDays(4)]);

      await expect(NFTChefContract.unstake("")).to.be.revertedWith(cannot_zero);

      // Unstake and check balance changes
      await expect(NFTChefContract.unstake("Address")).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [
          ethers.utils.parseEther("1000").mul(-1),
          ethers.utils.parseEther("1000"),
        ]
      );

      const currentIndex = await NFTChefContract.getUserStakeIndex(
        owner.address
      );
      expect(currentIndex).to.be.equal(1);

      const curStakerInfo = await NFTChefContract.getStakerInfo(
        owner.address,
        currentIndex - 1
      );
      expect(curStakerInfo.lockedAmount).to.be.equal(
        ethers.utils.parseEther("1000")
      );
      expect(curStakerInfo.lockDuration).to.be.equal(getSecondsFromDays(3));
      expect(curStakerInfo.rewardAmount).to.be.equal(1);
      expect(curStakerInfo.unstaked).to.be.equal(true);

      await expect(NFTChefContract.unstake("Address")).to.be.revertedWith(
        "Your position not exist"
      );

      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // Lock 3 days
      await NFTChefContract.stake(getSecondsFromDays(3));
    });

    it("Booster value changes correctly based on NFT amount", async function () {
      const {
        TAVAContract,
        SecondSkinNFTContract,
        NFTStakingContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setShortTimeConfig(NFTChefContract);

      // SecondSkinNFT check.
      const ssn_balance = await NFTStakingContract.getStakedNFTCount(
        owner.address
      );
      expect(ssn_balance).to.be.equal(0);
      // mint ssn
      await SecondSkinNFTContract.mint("test_uri");
      await NFTStakingContract.stake([1]);

      const ssn_balance2 = await NFTStakingContract.getStakedNFTCount(
        owner.address
      );
      expect(ssn_balance2).to.be.equal(1);

      const period = getSecondsFromDays(3); // 9 seconds;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );
      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // stake 30days
      await expect(
        NFTChefContract.stake(getSecondsFromDays(3))
      ).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [requireAmount, requireAmount.mul(-1)]
      );
      // Get nft booster APR
      const apr = await NFTChefContract.getStakerBoosterValue(owner.address);
      console.log("APR discount rate:", apr);
      expect(await NFTChefContract.getPanaltyAmount(owner.address)).to.be.equal(
        0
      );

      // Wait 4 days for unlocking.
      await ethers.provider.send("evm_increaseTime", [getSecondsFromDays(4)]);
      // Unstake and check balance changes
      await expect(NFTChefContract.unstake("Address")).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [requireAmount.mul(-1), requireAmount]
      );
    });

    it("Check required amount and panalty", async function () {
      const {
        TAVAContract,
        SecondSkinNFTContract,
        NFTStakingContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setShortTimeConfig(NFTChefContract);

      // SecondSkinNFT check.
      const ssn_balance = await NFTStakingContract.getStakedNFTCount(
        owner.address
      );
      expect(ssn_balance).to.be.equal(0);
      // mint ssn
      await SecondSkinNFTContract.mint("test_uri");
      await SecondSkinNFTContract.mint("test_uri");
      await SecondSkinNFTContract.mint("test_uri");
      await SecondSkinNFTContract.mint("test_uri");
      await SecondSkinNFTContract.mint("test_uri");
      await SecondSkinNFTContract.mint("test_uri");
      await NFTStakingContract.stake([1]);
      await NFTStakingContract.stake([2]);
      await NFTStakingContract.stake([3]);
      await NFTStakingContract.stake([4]);
      await NFTStakingContract.stake([5]);
      await NFTStakingContract.stake([6]);

      const period = getSecondsFromDays(3); // 9 seconds;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );
      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // stake 30days
      await expect(
        NFTChefContract.stake(getSecondsFromDays(3))
      ).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [requireAmount, requireAmount.mul(-1)]
      );
      await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 2);
      // Get nft booster APR
      const apr = await NFTChefContract.getStakerBoosterValue(owner.address);
      console.log("APR discount rate:", apr);
      expect(await NFTChefContract.getPanaltyAmount(owner.address)).to.be.equal(
        0
      );

      // Wait 4 days for unlocking.
      await ethers.provider.send("evm_increaseTime", [getSecondsFromDays(4)]);
      // Unstake and check balance changes
      await expect(NFTChefContract.unstake("Address")).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [requireAmount.mul(-1), requireAmount]
      );
    });

    it("Extend days option: Booster value changes correctly based on NFT amount", async function () {
      const {
        TAVAContract,
        SecondSkinNFTContract,
        NFTStakingContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setShortTimeConfig(NFTChefContract);

      // SecondSkinNFT check.
      const ssn_balance = await NFTStakingContract.getStakedNFTCount(
        owner.address
      );
      expect(ssn_balance).to.be.equal(0);
      // mint ssn
      await SecondSkinNFTContract.mint("test_uri");
      await NFTStakingContract.stake([1]);

      const ssn_balance2 = await NFTStakingContract.getStakedNFTCount(
        owner.address
      );
      expect(ssn_balance2).to.be.equal(1);

      const period = getSecondsFromDays(3); // 9 seconds;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        owner.address
      );
      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.approve(NFTChefContract.address, requireAmount);
      // stake 3 seconds
      await expect(
        NFTChefContract.stake(getSecondsFromDays(3))
      ).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [requireAmount, requireAmount.mul(-1)]
      );

      // Extend from 3 seconds to 6 seconds
      const period2 = getSecondsFromDays(6);
      const requireAmount2 = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period2,
        owner.address
      );
      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.approve(
        NFTChefContract.address,
        requireAmount2.sub(requireAmount)
      );
      // Extend from 3 to 6 seconds periods
      await expect(
        NFTChefContract.stake(getSecondsFromDays(6))
      ).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [
          requireAmount2.sub(requireAmount),
          requireAmount2.sub(requireAmount).mul(-1),
        ]
      );

      // Wait 7 days for unlocking.
      await ethers.provider.send("evm_increaseTime", [getSecondsFromDays(7)]);
      // Unstake and check balance changes
      await expect(NFTChefContract.unstake("Address")).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, owner.address],
        [requireAmount2.mul(-1), requireAmount2]
      );
    });

    it("Panalty Check: Booster value changes correctly based on NFT amount", async function () {
      const {
        TAVAContract,
        NFTStakingContract,
        SecondSkinNFTContract,
        NFTChefContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await setShortTimeConfig(NFTChefContract);

      // Transfer TAVA token to addr1
      await TAVAContract.transfer(
        addr1.address,
        ethers.utils.parseEther("1000")
      );

      // SecondSkinNFT check.
      const ssn_balance = await NFTStakingContract.connect(
        addr1
      ).getStakedNFTCount(owner.address);
      expect(ssn_balance).to.be.equal(0);
      // mint ssn
      await SecondSkinNFTContract.mint("test_uri");
      await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 1);
      await NFTStakingContract.connect(addr1).stake([1]);

      const ssn_balance2 = await NFTStakingContract.getStakedNFTCount(
        addr1.address
      );
      expect(ssn_balance2).to.be.equal(1);

      const period = getSecondsFromDays(3); // 9 seconds;
      const requireAmount = await getRequiredAmount(
        NFTStakingContract,
        NFTChefContract,
        period,
        addr1.address
      );
      // console.log(requireAmount)
      // Before stake, need to approve token
      await TAVAContract.connect(addr1).approve(
        NFTChefContract.address,
        requireAmount
      );
      // stake 3 seconds
      await expect(
        NFTChefContract.connect(addr1).stake(getSecondsFromDays(3))
      ).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, addr1.address],
        [requireAmount, requireAmount.mul(-1)]
      );

      // Transfer NFT to others.
      await SecondSkinNFTContract.connect(addr1).transferFrom(
        addr1.address,
        owner.address,
        1
      ); // tokenID = 0

      const panaltyAmount = await NFTChefContract.connect(
        addr1
      ).getPanaltyAmount(addr1.address);
      expect(panaltyAmount).to.be.equal(
        ethers.utils.parseEther("1000").sub(requireAmount)
      );

      // Wait 4 days for unlocking.
      await ethers.provider.send("evm_increaseTime", [getSecondsFromDays(4)]);
      // Unstake and check balance changes
      await expect(
        NFTChefContract.connect(addr1).unstake("Address")
      ).to.changeTokenBalances(
        TAVAContract,
        [NFTChefContract.address, addr1.address, owner.address],
        [requireAmount.mul(-1), requireAmount, 0]
      );
    });
  });
});
