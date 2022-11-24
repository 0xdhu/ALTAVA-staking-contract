const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const testId = "test_id";
// ALTAVA Token (TAVA)
const zero_address = "0x0000000000000000000000000000000000000000";
const not_owner = "Ownable: caller is not the owner";
const cannot_zero = "Cannot be zero address";

describe("MasterChef and SmartChef", function () {
  let rewardPerBlock = ethers.utils.parseEther("10");
  let blockNumber;
  let startBlock;
  let endBlock;

  // Booster structure
  const BS = (key, apr) => {
    return { key, apr };
  };
  const booster = [BS(1, 150), BS(2, 250), BS(3, 350)];

  const largeBooster = () => {
    let arr = [];
    for (let i = 1; i < 50; i++) {
      arr.push(BS(i, i * 10));
    }
    return arr;
  };

  const increaseBlockNumber = async (num) => {
    for (let i = 0; i < num; i++) {
      await ethers.provider.send("evm_mine");
    }
  };
  const increaseDays = async (num) => {
    const secondOfDays = num * 24 * 60 * 60;
    await ethers.provider.send("evm_increaseTime", [secondOfDays]);
  };
  const getSecondsFromDays = (num) => {
    const secondOfDays = num * 24 * 60 * 60;
    return secondOfDays;
  };

  // Direct Reward testing
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

    // Deploy Booster Token contract
    const BoosterController = await ethers.getContractFactory(
      "BoosterController"
    );
    const BoosterControllerContract = await BoosterController.deploy();
    await BoosterControllerContract.deployed();

    // Deploy SecondskinNFT contract
    const SecondSkinNFT = await ethers.getContractFactory("SecondSkinNFT");
    const SecondSkinNFTContract = await SecondSkinNFT.deploy(owner.address);
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

    // Deploy NFTMasterChef contract
    const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");
    const NFTMasterChefContract = await NFTMasterChef.deploy(
      TAVAContract.address,
      NFTStakingContract.address
    );
    await NFTMasterChefContract.deployed();

    await NFTStakingContract.setMasterChef(MasterChefContract.address);
    await NFTStakingContract.setNFTMasterChef(NFTMasterChefContract.address);

    // Deploy SmartChef contract
    await MasterChefContract.deploy(
      testId,
      ThirdPartyTokenContract.address.toString(),
      TAVAContract.address,
      ThirdPartyTokenContract.address,
      rewardPerBlock,
      startBlock,
      endBlock,
      false,
      BoosterControllerContract.address
    );
    // Deploy SmartChef contract
    await MasterChefContract.deploy(
      testId,
      ThirdPartyTokenContract.address.toString(),
      ThirdPartyTokenContract.address,
      ThirdPartyTokenContract.address,
      rewardPerBlock,
      startBlock,
      endBlock,
      false,
      BoosterControllerContract.address
    );

    const SmartChefAddres = await MasterChefContract.chefAddress(1);

    // Deployed contract
    const SmartChefContract = await ethers.getContractAt(
      "SmartChef",
      SmartChefAddres
    );

    await expect(
      SmartChefContract.initialize(
        TAVAContract.address,
        ThirdPartyTokenContract.address,
        ThirdPartyTokenContract.address.toString(),
        rewardPerBlock,
        startBlock,
        endBlock,
        owner.address,
        NFTStakingContract.address,
        false,
        BoosterControllerContract.address
      )
    ).to.be.revertedWith("Already initialized");

    await expect(
      SmartChefContract.connect(addr1).setBoosterController(
        BoosterControllerContract.address
      )
    ).to.be.revertedWith(not_owner);
    await expect(
      SmartChefContract.setBoosterController(zero_address)
    ).to.be.revertedWith(cannot_zero);

    await SmartChefContract.setBoosterController(
      BoosterControllerContract.address
    );
    // Fixtures can return anything you consider useful for your tests
    return {
      TAVAContract,
      NFTStakingContract,
      SecondSkinNFTContract,
      BoosterControllerContract,
      ThirdPartyTokenContract,
      MasterChefContract,
      NFTMasterChefContract,
      SmartChefContract,
      owner,
      addr1,
      addr2,
    };
  }

  // Airdrop Reward testing
  async function deployFixture2() {
    // Get the ContractFactory and Signers here.
    const [owner, addr1, addr2] = await ethers.getSigners();

    blockNumber = await ethers.provider.getBlockNumber();

    startBlock = blockNumber + 100;
    endBlock = blockNumber + 500;

    // Deploy TAVA Token contract
    const TAVA = await ethers.getContractFactory("TAVA");
    const TAVAContract = await TAVA.deploy();
    await TAVAContract.deployed();

    // Deploy TAVA Token contract
    const BoosterController = await ethers.getContractFactory(
      "BoosterController"
    );
    const BoosterControllerContract = await BoosterController.deploy();
    await BoosterControllerContract.deployed();

    // Deploy SecondskinNFT contract
    const SecondSkinNFT = await ethers.getContractFactory("SecondSkinNFT");
    const SecondSkinNFTContract = await SecondSkinNFT.deploy(owner.address);
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
    await expect(MasterChef.deploy(zero_address)).to.be.revertedWith(
      "Cannot be zero address"
    );

    const MasterChefContract = await MasterChef.deploy(
      NFTStakingContract.address
    );
    await MasterChefContract.deployed();

    await expect(
      MasterChefContract.setNFTStaking(zero_address)
    ).to.be.revertedWith("Cannot be zero address");
    await expect(
      MasterChefContract.connect(addr1).setNFTStaking(
        NFTStakingContract.address
      )
    ).to.be.revertedWith(not_owner);
    await MasterChefContract.setNFTStaking(NFTStakingContract.address);

    // Deploy NFTMasterChef contract
    const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");
    const NFTMasterChefContract = await NFTMasterChef.deploy(
      TAVAContract.address,
      NFTStakingContract.address
    );
    await NFTMasterChefContract.deployed();

    await NFTStakingContract.setMasterChef(MasterChefContract.address);
    await NFTStakingContract.setNFTMasterChef(NFTMasterChefContract.address);

    await expect(
      MasterChefContract.connect(addr1).deploy(
        testId,
        ThirdPartyTokenContract.address.toString(),
        TAVAContract.address,
        ThirdPartyTokenContract.address,
        rewardPerBlock,
        startBlock,
        endBlock,
        true,
        BoosterControllerContract.address
      )
    ).to.be.revertedWith(not_owner);

    await expect(
      MasterChefContract.deploy(
        testId,
        ThirdPartyTokenContract.address.toString(),
        zero_address,
        ThirdPartyTokenContract.address,
        rewardPerBlock,
        startBlock,
        endBlock,
        true,
        BoosterControllerContract.address
      )
    ).to.be.revertedWithoutReason();
    await expect(
      MasterChefContract.deploy(
        testId,
        ThirdPartyTokenContract.address.toString(),
        TAVAContract.address,
        zero_address,
        rewardPerBlock,
        startBlock,
        endBlock,
        false,
        BoosterControllerContract.address
      )
    ).to.be.revertedWithoutReason();

    await expect(
      MasterChefContract.deploy(
        testId,
        "",
        TAVAContract.address,
        ThirdPartyTokenContract.address,
        rewardPerBlock,
        startBlock,
        endBlock,
        true,
        BoosterControllerContract.address
      )
    ).to.be.revertedWith(cannot_zero);

    // Deploy SmartChef contract
    await MasterChefContract.deploy(
      testId,
      ThirdPartyTokenContract.address.toString(),
      TAVAContract.address,
      ThirdPartyTokenContract.address,
      rewardPerBlock,
      startBlock,
      endBlock,
      true,
      BoosterControllerContract.address
    );
    const SmartChefAddres = await MasterChefContract.chefAddress(1);

    // Deployed contract
    const SmartChefContract = await ethers.getContractAt(
      "SmartChef",
      SmartChefAddres
    );

    // Fixtures can return anything you consider useful for your tests
    return {
      TAVAContract,
      NFTStakingContract,
      SecondSkinNFTContract,
      BoosterControllerContract,
      ThirdPartyTokenContract,
      MasterChefContract,
      NFTMasterChefContract,
      SmartChefContract,
      owner,
      addr1,
      addr2,
    };
  }

  // You can nest describe calls to create subsections.
  describe("SmartChef: Deployment should work correctly", function () {
    // If the callback function is async, Mocha will `await` it.
    it("Should set the right owner and secondskin nft", async function () {
      const {
        NFTStakingContract,
        SecondSkinNFTContract,
        MasterChefContract,
        SmartChefContract,
        owner,
      } = await loadFixture(deployFixture);

      // This test expects the owner variable stored in the contract to be
      // equal to our Signer's owner.
      expect(await NFTStakingContract.owner()).to.equal(owner.address);
      expect(await NFTStakingContract.secondskinNFT()).to.equal(
        SecondSkinNFTContract.address
      );
      expect(await SmartChefContract.owner()).to.equal(owner.address);
      expect(await MasterChefContract.owner()).to.equal(owner.address);
    });
    it("Should set the right configurations", async function () {
      const {
        TAVAContract,
        ThirdPartyTokenContract,
        SmartChefContract,
        MasterChefContract,
        BoosterControllerContract,
        addr1,
      } = await loadFixture(deployFixture);

      await ThirdPartyTokenContract.transfer(SmartChefContract.address, 100);

      await expect(
        BoosterControllerContract.setBoosterArray(
          largeBooster(),
          SmartChefContract.address
        )
      ).to.be.revertedWith("Limit max booster pair");

      await expect(
        BoosterControllerContract.connect(addr1).setBoosterArray(
          [{ key: 1, apr: 10 }],
          SmartChefContract.address
        )
      ).to.be.revertedWith(not_owner);

      await expect(
        SmartChefContract.connect(addr1).emergencyRewardWithdraw(100)
      ).to.be.revertedWith(not_owner);

      SmartChefContract.emergencyRewardWithdraw(100);

      await expect(
        SmartChefContract.connect(addr1).updateRewardPerBlock(rewardPerBlock)
      ).to.be.revertedWith(not_owner);

      await expect(
        SmartChefContract.connect(addr1).updateStartAndEndBlocks(
          startBlock,
          endBlock
        )
      ).to.be.revertedWith(not_owner);

      await expect(
        SmartChefContract.updateStartAndEndBlocks(endBlock, endBlock - 1)
      ).to.be.revertedWith("startBlock too higher");

      await expect(
        SmartChefContract.updateStartAndEndBlocks(0, endBlock - 1)
      ).to.be.revertedWith("startBlock too lower");
      // This test expects the owner variable stored in the contract to be
      await SmartChefContract.updateRewardPerBlock(rewardPerBlock);
      await SmartChefContract.updateStartAndEndBlocks(startBlock, endBlock);

      await increaseBlockNumber(startBlock + 1);

      await expect(
        SmartChefContract.updateRewardPerBlock(rewardPerBlock)
      ).to.be.revertedWith("Pool has started");

      await expect(
        SmartChefContract.updateStartAndEndBlocks(startBlock, endBlock)
      ).to.be.revertedWith("Pool has started");

      // Deploy SmartChef contract
      await MasterChefContract.deploy(
        testId,
        TAVAContract.address.toString(),
        TAVAContract.address,
        TAVAContract.address,
        rewardPerBlock,
        startBlock,
        endBlock,
        false,
        BoosterControllerContract.address
      );
      const SmartChefAddres = await MasterChefContract.chefAddress(2);
      // Deployed contract
      const SmartChefContract2 = await ethers.getContractAt(
        "SmartChef",
        SmartChefAddres
      );

      await expect(
        SmartChefContract2.emergencyRewardWithdraw(100)
      ).to.be.revertedWith("Not able to withdraw");
    });

    // If the callback function is async, Mocha will `await` it.
    it("SetBoosterArray should work", async function () {
      const { SmartChefContract, BoosterControllerContract, addr1 } =
        await loadFixture(deployFixture);

      await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );

      expect(
        await BoosterControllerContract.getBoosterAPR(
          1,
          SmartChefContract.address
        )
      ).to.equal("0");

      await BoosterControllerContract.setBoosterArray(
        booster,
        SmartChefContract.address
      );
      expect(
        await BoosterControllerContract.getTotalPairCount(
          SmartChefContract.address
        )
      ).to.equal(3);
      expect(
        await BoosterControllerContract.getBoosterAPR(
          1,
          SmartChefContract.address
        )
      ).to.equal("150");
      expect(
        await BoosterControllerContract.getBoosterAPR(
          2,
          SmartChefContract.address
        )
      ).to.equal("250");
      expect(
        await BoosterControllerContract.getBoosterAPR(
          3,
          SmartChefContract.address
        )
      ).to.equal("350");

      expect(
        await BoosterControllerContract.getBoosterAPR(
          10,
          SmartChefContract.address
        )
      ).to.equal("350");
      await expect(
        BoosterControllerContract.setBoosterValue(
          BS("1", "250"),
          SmartChefContract.address
        )
      ).to.be.revertedWith("Booster value: invalid");
      await expect(
        BoosterControllerContract.setBoosterValue(
          BS("2", "100"),
          SmartChefContract.address
        )
      ).to.be.revertedWith("Booster value: invalid");

      await expect(
        BoosterControllerContract.setBoosterValue(
          BS("0", "200"),
          SmartChefContract.address
        )
      ).to.be.revertedWith("Inputs cannot be zero");

      await expect(
        BoosterControllerContract.setBoosterValue(
          BS(1, 50010),
          SmartChefContract.address
        )
      ).to.be.revertedWith("Booster rate: overflow max");

      await expect(
        BoosterControllerContract.connect(addr1).setBoosterValue(
          BS(1, 180),
          SmartChefContract.address
        )
      ).to.be.revertedWith(not_owner);

      await expect(
        BoosterControllerContract.setBoosterValue(BS(1, 180), zero_address)
      ).to.be.revertedWith(cannot_zero);

      await BoosterControllerContract.setBoosterValue(
        BS("1", "180"),
        SmartChefContract.address
      );

      expect(
        await BoosterControllerContract.getBoosterAPR(
          1,
          SmartChefContract.address
        )
      ).to.equal("180");

      expect(
        await BoosterControllerContract.getTotalPairCount(
          SmartChefContract.address
        )
      ).to.equal(3);

      await BoosterControllerContract.setBoosterValue(
        BS("4", "450"),
        SmartChefContract.address
      );

      expect(
        await BoosterControllerContract.getTotalPairCount(
          SmartChefContract.address
        )
      ).to.equal(4);

      await BoosterControllerContract.setBoosterValue(
        BS(2, 255),
        SmartChefContract.address
      );

      await expect(
        BoosterControllerContract.setBoosterValue(
          BS(2, 0),
          SmartChefContract.address
        )
      ).to.be.revertedWith("Inputs cannot be zero");

      expect(
        await BoosterControllerContract.getBoosterAPR(
          4,
          SmartChefContract.address
        )
      ).to.equal(450);

      expect(
        await BoosterControllerContract.getTotalPairCount(
          SmartChefContract.address
        )
      ).to.equal(4);

      // remove -----

      await expect(
        BoosterControllerContract.removeBoosterValue(50, zero_address)
      ).to.be.revertedWith(cannot_zero);
      await expect(
        BoosterControllerContract.connect(addr1).removeBoosterValue(
          50,
          SmartChefContract.address
        )
      ).to.be.revertedWith(not_owner);

      await BoosterControllerContract.removeBoosterValue(
        50,
        SmartChefContract.address
      );
      await BoosterControllerContract.removeBoosterValue(
        4,
        SmartChefContract.address
      );
      // confirm count after remove
      expect(
        await BoosterControllerContract.getTotalPairCount(
          SmartChefContract.address
        )
      ).to.equal(3);

      // higher keys
      await BoosterControllerContract.setBoosterValue(
        BS(7, 450),
        SmartChefContract.address
      );

      for (let i = 4; i < 8; i++) {
        expect(
          await BoosterControllerContract.getBoosterAPR(
            i,
            SmartChefContract.address
          )
        ).to.equal(450);
      }

      const boostPairs = await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );
      const boostPairsJson = boostPairs.map((item) => {
        return { key: item.key.toString(), apr: item.apr.toString() };
      });
      expect(JSON.stringify(boostPairsJson)).to.be.equal(
        '[{"key":"1","apr":"180"},{"key":"2","apr":"255"},{"key":"3","apr":"350"},{"key":"7","apr":"450"}]'
      );

      await BoosterControllerContract.removeBoosterValue(
        1,
        SmartChefContract.address
      );

      const boostPairs2 = await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );
      const boostPairsJson2 = boostPairs2.map((item) => {
        return { key: item.key.toString(), apr: item.apr.toString() };
      });
      expect(JSON.stringify(boostPairsJson2)).to.be.equal(
        '[{"key":"2","apr":"255"},{"key":"3","apr":"350"},{"key":"7","apr":"450"}]'
      );
    });

    it("Quicksort test", async function () {
      const { SmartChefContract, BoosterControllerContract, owner, addr1 } =
        await loadFixture(deployFixture);

      await BoosterControllerContract.setBoosterValue(
        BS("1", "180"),
        SmartChefContract.address
      );
      await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("2", "280"),
        SmartChefContract.address
      );
      await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("3", "380"),
        SmartChefContract.address
      );
      await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("4", "384"),
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("5", "385"),
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("6", "386"),
        SmartChefContract.address
      );

      await BoosterControllerContract.removeBoosterValue(
        "1",
        SmartChefContract.address
      );

      await BoosterControllerContract.removeBoosterValue(
        "2",
        SmartChefContract.address
      );
      await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );
      await BoosterControllerContract.removeBoosterValue(
        "3",
        SmartChefContract.address
      );
      await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("9", "986"),
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("8", "886"),
        SmartChefContract.address
      );

      await BoosterControllerContract.setBoosterValue(
        BS("7", "786"),
        SmartChefContract.address
      );
      await BoosterControllerContract.setBoosterValue(
        BS("1", "86"),
        SmartChefContract.address
      );
      await BoosterControllerContract.getBoosterKeysValues(
        SmartChefContract.address
      );
    });

    // Stake should work
    it("Stake should work", async function () {
      const {
        SmartChefContract,
        TAVAContract,
        ThirdPartyTokenContract,
        NFTStakingContract,
        SecondSkinNFTContract,
        BoosterControllerContract,
        owner,
        addr1,
      } = await loadFixture(deployFixture);
      await increaseBlockNumber(startBlock);

      await expect(
        BoosterControllerContract.setBoosterArray(booster, zero_address)
      ).to.be.revertedWith(cannot_zero);

      await expect(
        BoosterControllerContract.setBoosterArray([], SmartChefContract.address)
      ).to.be.revertedWith("Invalid inputs");

      await BoosterControllerContract.setBoosterArray(
        booster,
        SmartChefContract.address
      );

      const lockAmount = ethers.utils.parseEther("1000");
      const lockDuration = 7 * 3600 * 24; // 7 days

      await SecondSkinNFTContract.mint("token_uri"); // token id 1
      await SecondSkinNFTContract.mint("token_uri"); // token id 2
      await NFTStakingContract.stake([1, 2, 1]);

      // Minimum lock period is one week
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await expect(
        SmartChefContract.stake(lockAmount, lockDuration / 2)
      ).to.be.revertedWith("Minimum lock period is one week");
      await expect(SmartChefContract.stake(0, 0)).to.be.revertedWith(
        "Nothing to deposit"
      );

      // Stake should work.
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await SmartChefContract.setPause(true);

      await expect(
        SmartChefContract.stake(lockAmount, lockDuration)
      ).to.be.revertedWith("Pausable: paused");
      await expect(
        SmartChefContract.connect(addr1).setPause(false)
      ).to.be.revertedWith(not_owner);

      await SmartChefContract.setPause(false);

      await SmartChefContract.stake(lockAmount, lockDuration);

      await SecondSkinNFTContract.mint("token_uri"); // token id 1
      await SecondSkinNFTContract.mint("token_uri"); // token id 2
      await NFTStakingContract.stake([1, 3, 4]);

      await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 1);
      // const smartchefBoostData = await SmartChefContract.getStakerBoosterValue(
      //   owner.address
      // );
      // console.log("BoosterAPR", smartchefBoostData.toString());

      // "Extend lock duration"
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await expect(
        SmartChefContract.stake(lockAmount, lockDuration)
      ).to.be.revertedWith("Extend lock duration");

      // "Extend lock duration"
      await expect(
        SmartChefContract.stake("0", lockDuration)
      ).to.be.revertedWith("Not enough duration to extends");

      await expect(
        SmartChefContract.stake("0", lockDuration / 2)
      ).to.be.revertedWith("Not enough duration to extends");

      await increaseDays(9);
      await ThirdPartyTokenContract.transfer(
        SmartChefContract.address,
        ethers.utils.parseEther("10000")
      );
      // Now unlock should work.
      await SmartChefContract.unlock("");

      await SecondSkinNFTContract.mint("token_uri"); // token id 5
      await NFTStakingContract.stake([5]);
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await SmartChefContract.stake(lockAmount, lockDuration);
      await increaseBlockNumber(endBlock);
      await SmartChefContract.stake(0, lockDuration * 2);

      await SecondSkinNFTContract.mint("token_uri"); // token id 5
      await NFTStakingContract.stake([6]);
      await increaseBlockNumber(5);
      await SmartChefContract.stake(0, lockDuration * 3);
      await expect(
        SmartChefContract.stake(0, getSecondsFromDays(1500))
      ).to.be.revertedWith("Maximum lock period exceeded");
      await increaseDays(lockDuration * 4);
      await SmartChefContract.unlock("");
    });

    // Extend Stake should work
    it("Extend stake should work", async function () {
      const {
        SmartChefContract,
        TAVAContract,
        BoosterControllerContract,
        owner,
        addr1,
        addr2,
      } = await loadFixture(deployFixture);

      await BoosterControllerContract.setBoosterArray(
        booster,
        SmartChefContract.address
      );

      const lockAmount = ethers.utils.parseEther("1000");
      const lockDuration = 7 * 3600 * 24; // 7 days

      // Stake should work.
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await SmartChefContract.stake(lockAmount, lockDuration);

      // Extend staking
      SmartChefContract.stake("0", lockDuration * 2);

      // Check staker infos
      await TAVAContract.transfer(addr1.address, lockAmount);
      await TAVAContract.transfer(addr2.address, lockAmount);

      // Alice stake
      await TAVAContract.connect(addr1).approve(
        SmartChefContract.address,
        lockAmount
      );
      await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);
      // Bob stake
      await TAVAContract.connect(addr2).approve(
        SmartChefContract.address,
        lockAmount
      );
      await SmartChefContract.connect(addr2).stake(lockAmount, lockDuration);

      // Check detail infos
      const userInfo = await SmartChefContract.userInfo(owner.address);
      const aliceInfo = await SmartChefContract.userInfo(addr1.address);
      const bobInfo = await SmartChefContract.userInfo(addr2.address);

      expect(userInfo.lockedAmount).to.equal(lockAmount);
      expect(userInfo.lockEndTime.sub(userInfo.lockStartTime)).to.equal(
        lockDuration * 2
      );
      expect(userInfo.locked).to.equal(true);
      expect(userInfo.rewardDebt).to.equal(ethers.utils.parseEther("0"));
      expect(userInfo.rewards).to.equal(ethers.utils.parseEther("0"));

      expect(aliceInfo.lockedAmount).to.equal(lockAmount);
      expect(bobInfo.lockedAmount).to.equal(lockAmount);
    });

    // Reward Debt check
    it("Reward Debt should work", async function () {
      const {
        SmartChefContract,
        BoosterControllerContract,
        TAVAContract,
        addr1,
        addr2,
      } = await loadFixture(deployFixture);
      await BoosterControllerContract.setBoosterArray(
        booster,
        BoosterControllerContract.address
      );

      const lockAmount = ethers.utils.parseEther("1000");
      const lockDuration = getSecondsFromDays(7); // 7 days

      await increaseBlockNumber(startBlock);
      // Stake should work.
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await SmartChefContract.stake(lockAmount, lockDuration);

      // Token from owner to alice
      await TAVAContract.transfer(addr1.address, lockAmount);
      await TAVAContract.transfer(addr2.address, lockAmount);

      // Alice stake
      await TAVAContract.connect(addr1).approve(
        SmartChefContract.address,
        lockAmount
      );
      await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);

      const aliceInfo0 = await SmartChefContract.userInfo(addr1.address);
      // Third party token reward starts.
      await increaseBlockNumber(5);

      // Alice extends
      await SmartChefContract.connect(addr1).stake(
        ethers.utils.parseEther("0"),
        lockDuration * 2
      );
      const precisionFactor = await SmartChefContract.precisionFactor();
      // precisionFactor = uint256(10**(uint256(30) - decimalsRewardToken));
      expect(precisionFactor).to.equal(
        ethers.utils.parseUnits("1", `${30 - 18}`)
      );

      const accTokenPerShare = await SmartChefContract.accTokenPerShare();
      const pending = aliceInfo0.lockedAmount
        .mul(accTokenPerShare)
        .div(precisionFactor)
        .sub(aliceInfo0.rewardDebt);

      const reward = pending;

      const aliceInfo = await SmartChefContract.userInfo(addr1.address);
      expect(aliceInfo.rewards).to.equal(reward);

      const rewardDebt = aliceInfo.lockedAmount
        .mul(accTokenPerShare)
        .div(precisionFactor);
      expect(aliceInfo.rewardDebt).to.equal(rewardDebt);
    });
  });

  describe("SmartChef: airdrop part", function () {
    // Unlock should work
    it("Unlock should work", async function () {
      const {
        SmartChefContract,
        BoosterControllerContract,
        TAVAContract,
        addr1,
        addr2,
      } = await loadFixture(deployFixture2);
      await BoosterControllerContract.setBoosterArray(
        booster,
        SmartChefContract.address
      );

      const lockAmount = ethers.utils.parseEther("1000");
      const lockDuration = getSecondsFromDays(7); // 7 days

      await increaseBlockNumber(startBlock);
      // Stake should work.
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await SmartChefContract.stake(lockAmount, lockDuration);

      // Token from owner to alice
      await TAVAContract.transfer(addr1.address, lockAmount);
      await TAVAContract.transfer(addr2.address, lockAmount);

      // Alice stake
      await TAVAContract.connect(addr1).approve(
        SmartChefContract.address,
        lockAmount
      );
      await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);

      // Third party token reward starts.
      await increaseBlockNumber(5);

      // Alice extends
      await SmartChefContract.connect(addr1).stake(
        ethers.utils.parseEther("0"),
        lockDuration * 2
      );

      // Unlock should not work before unlock days
      await expect(SmartChefContract.unlock("Address")).to.be.revertedWith(
        "Still in locked"
      );

      await increaseDays(9);

      await expect(SmartChefContract.unlock("")).to.be.revertedWith(
        "Cannot be zero address"
      );

      // Now unlock should work.
      await SmartChefContract.unlock("Address");

      // Double unlock should not work
      await expect(SmartChefContract.unlock("Address")).to.be.revertedWith(
        "Empty to unlock"
      );

      // ---- Alice
      // Unlock should not work before unlock days
      await expect(
        SmartChefContract.connect(addr1).unlock("Address")
      ).to.be.revertedWith("Still in locked");
      await increaseDays(9);
      // Now unlock should work.
      SmartChefContract.connect(addr1).unlock("Address");
      // Double unlock should not work
      await expect(
        SmartChefContract.connect(addr1).unlock("Address")
      ).to.be.revertedWith("Empty to unlock");
    });

    // Airdrop Stake should work
    it("Airdrop Stake should work", async function () {
      const {
        SmartChefContract,
        TAVAContract,
        ThirdPartyTokenContract,
        NFTStakingContract,
        SecondSkinNFTContract,
        BoosterControllerContract,
        owner,
      } = await loadFixture(deployFixture2);
      await increaseBlockNumber(startBlock);

      await BoosterControllerContract.setBoosterArray(
        booster,
        SmartChefContract.address
      );

      const lockAmount = ethers.utils.parseEther("1000");
      const lockDuration = 7 * 3600 * 24; // 7 days

      await SecondSkinNFTContract.mint("token_uri"); // token id 1
      await SecondSkinNFTContract.mint("token_uri"); // token id 2
      await NFTStakingContract.stake([1, 2, 1]);

      // Minimum lock period is one week
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await expect(
        SmartChefContract.stake(lockAmount, lockDuration / 2)
      ).to.be.revertedWith("Minimum lock period is one week");

      // Stake should work.
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await SmartChefContract.stake(lockAmount, lockDuration);

      await SecondSkinNFTContract.mint("token_uri"); // token id 1
      await SecondSkinNFTContract.mint("token_uri"); // token id 2
      await NFTStakingContract.stake([1, 3, 4]);

      const smartchefBoostData = await SmartChefContract.getStakerBoosterValue(
        owner.address
      );
      console.log("BoosterAPR", smartchefBoostData.toString());

      // "Extend lock duration"
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await expect(
        SmartChefContract.stake(lockAmount, lockDuration)
      ).to.be.revertedWith("Extend lock duration");

      // "Extend lock duration"
      await expect(
        SmartChefContract.stake("0", lockDuration)
      ).to.be.revertedWith("Not enough duration to extends");

      await expect(
        SmartChefContract.stake("0", lockDuration / 2)
      ).to.be.revertedWith("Not enough duration to extends");

      await increaseDays(9);
      await ThirdPartyTokenContract.transfer(
        SmartChefContract.address,
        ethers.utils.parseEther("10000")
      );
      // Now unlock should work.
      await SmartChefContract.unlock("Address");
    });

    // Admin should be able to unlock user's token
    it("Admin should be able to unlock user's token", async function () {
      const {
        SmartChefContract,
        TAVAContract,
        BoosterControllerContract,
        addr1,
        addr2,
      } = await loadFixture(deployFixture2);
      await BoosterControllerContract.setBoosterArray(
        booster,
        SmartChefContract.address
      );

      const lockAmount = ethers.utils.parseEther("1000");
      const lockDuration = getSecondsFromDays(7); // 7 days

      await increaseBlockNumber(startBlock);
      // Stake should work.
      await TAVAContract.approve(SmartChefContract.address, lockAmount);
      await SmartChefContract.stake(lockAmount, lockDuration);

      // Token from owner to alice
      await TAVAContract.transfer(addr1.address, lockAmount);
      await TAVAContract.transfer(addr2.address, lockAmount);

      // Alice stake
      await TAVAContract.connect(addr1).approve(
        SmartChefContract.address,
        lockAmount
      );
      await SmartChefContract.connect(addr1).stake(lockAmount, lockDuration);

      // Third party token reward starts.
      await increaseBlockNumber(5);

      // Alice extends
      await SmartChefContract.connect(addr1).stake(
        ethers.utils.parseEther("0"),
        lockDuration * 2
      );

      // ---- Alice
      // Unlock should not work before unlock days
      await expect(
        SmartChefContract.connect(addr1).unlock("Address")
      ).to.be.revertedWith("Still in locked");

      await increaseDays(18);
      // Now unlock should work.
      await SmartChefContract.connect(addr1).unlock("Address");
      // Double unlock should not work
      await expect(
        SmartChefContract.connect(addr1).unlock("Address")
      ).to.be.revertedWith("Empty to unlock");
    });
  });
});
