const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const testId = "test_id";

const cannot_zero = "Cannot be zero address";
const zero_address = "0x0000000000000000000000000000000000000000";
const not_owner = "Ownable: caller is not the owner";

describe("Secondskin NFT Staking for booster", function () {
  async function deployFixtureTest() {
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

    // Deploy NFT Staking Contract
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    await expect(NFTStaking.deploy(zero_address)).to.be.revertedWithoutReason;

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

    // Fixtures can return anything you consider useful for your tests
    return {
      NFTStakingContract,
      SecondSkinNFTContract,
      MasterChefContract,
      NFTMasterChefContract,
      owner,
      addr1,
      addr2,
    };
  }

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

    // Fixtures can return anything you consider useful for your tests
    return {
      NFTStakingContract,
      SecondSkinNFTContract,
      MasterChefContract,
      NFTMasterChefContract,
      owner,
      addr1,
      addr2,
    };
  }

  // You can nest describe calls to create subsections.
  describe("NFTStaking: Deployment should work correctly", function () {
    // If the callback function is async, Mocha will `await` it.
    it("Should set the right owner and secondskin nft", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner } =
        await loadFixture(deployFixture);

      // This test expects the owner variable stored in the contract to be
      // equal to our Signer's owner.
      expect(await NFTStakingContract.owner()).to.equal(owner.address);
      expect(await NFTStakingContract.MAX_REGISTER_LIMIT()).to.equal(10);
      expect(await NFTStakingContract.MINUS_ONE()).to.equal(999);
      expect(await NFTStakingContract.secondskinNFT()).to.equal(
        SecondSkinNFTContract.address
      );
    });

    it("Only owner can set invalid masterchef addresses", async function () {
      const {
        NFTStakingContract,
        MasterChefContract,
        NFTMasterChefContract,
        addr1,
      } = await loadFixture(deployFixtureTest);

      await expect(
        NFTStakingContract.connect(addr1).setMasterChef(
          MasterChefContract.address
        )
      ).to.be.revertedWith(not_owner);

      await expect(
        NFTStakingContract.connect(addr1).setNFTMasterChef(
          NFTMasterChefContract.address
        )
      ).to.be.revertedWith(not_owner);

      await expect(
        NFTStakingContract.setMasterChef(zero_address)
      ).to.be.revertedWith(cannot_zero);

      await expect(
        NFTStakingContract.setNFTMasterChef(zero_address)
      ).to.be.revertedWith(cannot_zero);
    });

    it("Test onlySmartChef & onlyNFTChef", async function () {
      const {
        NFTStakingContract,
        MasterChefContract,
        NFTMasterChefContract,
        addr1,
      } = await loadFixture(deployFixtureTest);

      await expect(
        NFTStakingContract.connect(addr1).stakeFromSmartChef(addr1.address)
      ).to.be.revertedWith("masterchef: zero address");

      await expect(
        NFTStakingContract.connect(addr1).stakeFromNFTChef(addr1.address)
      ).to.be.revertedWith("nftMasterChef: zero address");

      await expect(
        NFTStakingContract.connect(addr1).unstakeFromSmartChef(addr1.address)
      ).to.be.revertedWith("masterchef: zero address");

      await expect(
        NFTStakingContract.connect(addr1).unstakeFromNFTChef(addr1.address)
      ).to.be.revertedWith("nftMasterChef: zero address");

      await NFTStakingContract.setMasterChef(MasterChefContract.address);
      await NFTStakingContract.setNFTMasterChef(NFTMasterChefContract.address);

      await expect(
        NFTStakingContract.connect(addr1).stakeFromSmartChef(addr1.address)
      ).to.be.revertedWith("You are not subchef");

      await expect(
        NFTStakingContract.connect(addr1).stakeFromNFTChef(addr1.address)
      ).to.be.revertedWith("You are not subchef");

      await expect(
        NFTStakingContract.connect(addr1).unstakeFromSmartChef(addr1.address)
      ).to.be.revertedWith("You are not subchef");

      await expect(
        NFTStakingContract.connect(addr1).unstakeFromNFTChef(addr1.address)
      ).to.be.revertedWith("You are not subchef");
    });

    it("Without setting masterchefs, stake should not work", async function () {
      const { NFTStakingContract } = await loadFixture(deployFixtureTest);

      // This test expects the owner variable stored in the contract to be
      // equal to our Signer's owner.
      await expect(NFTStakingContract.stake([1])).to.be.revertedWith(
        "masterchef: zero address"
      );
    });
  });

  // You can nest describe calls to create subsections.
  describe("NFTStaking: Stake should work correctly", function () {
    it("Able to stake only owned NFT that exists", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } =
        await loadFixture(deployFixture);

      // token id (1) has not been mint
      await expect(NFTStakingContract.stake([1])).to.be.revertedWith(
        "ERC721: invalid token ID"
      );

      await SecondSkinNFTContract.mint("token_uri"); // token id 1
      await SecondSkinNFTContract.mint("token_uri"); // token id 2
      await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 1);
      // only owned NFT
      await expect(NFTStakingContract.stake([1, 2])).to.be.revertedWith(
        "You are not owner"
      );
      await expect(NFTStakingContract.unstake([1])).to.be.revertedWith(
        "You are not owner"
      );
    });
    // If the callback function is async, Mocha will `await` it.
    it("Double Stake should work", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner } =
        await loadFixture(deployFixture);

      await SecondSkinNFTContract.mint("token_uri"); // token id 1
      await SecondSkinNFTContract.mint("token_uri"); // token id 2
      await NFTStakingContract.stake([1, 2, 1]);

      await SecondSkinNFTContract.mint("token_uri"); // token id 3
      await SecondSkinNFTContract.mint("token_uri"); // token id 4
      await NFTStakingContract.stake([3, 4]);

      expect(
        (await NFTStakingContract.getStakedTokenIds(owner.address)).toString()
      ).to.be.equal("1,2,3,4");
      expect(
        await NFTStakingContract.getStakedNFTCount(owner.address)
      ).to.be.equal(4);

      // const stakedIds = await NFTStakingContract.getStakedTokenIds(owner.address);
      // console.log(stakedIds)
    });

    // If the callback function is async, Mocha will `await` it.
    it("Double Stake should work", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } =
        await loadFixture(deployFixture);

      await SecondSkinNFTContract.mint("token_uri"); // token id 1
      await SecondSkinNFTContract.mint("token_uri"); // token id 2
      await NFTStakingContract.stake([1, 2]);
      expect(
        await NFTStakingContract.getStakedNFTCount(owner.address)
      ).to.be.equal(2);

      await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 2);
      expect(
        await NFTStakingContract.getStakedNFTCount(owner.address)
      ).to.be.equal(1);

      await SecondSkinNFTContract.mint("token_uri"); // token id 3
      await SecondSkinNFTContract.mint("token_uri"); // token id 4
      await NFTStakingContract.stake([3, 4]);

      // Staked NFT addresses
      expect(
        (await NFTStakingContract.getStakedTokenIds(owner.address)).toString()
      ).to.be.equal("1,3,4");
      expect(
        await NFTStakingContract.getStakedNFTCount(owner.address)
      ).to.be.equal(3);
    });

    // If the callback function is async, Mocha will `await` it.
    it("Mass Stake should not work", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } =
        await loadFixture(deployFixture);
      for (let i = 0; i < 15; i++) {
        await SecondSkinNFTContract.mint("token_uri"); // token id 1
      }

      await expect(
        NFTStakingContract.stake([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
      ).to.be.revertedWith("Overflow max registration limit");
    });

    // If the callback function is async, Mocha will `await` it.
    it("Unstake should work", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } =
        await loadFixture(deployFixture);
      for (let i = 0; i < 5; i++) {
        await SecondSkinNFTContract.mint("token_uri"); // token id 1
      }
      await NFTStakingContract.stake([1, 2, 3]);
      await NFTStakingContract.unstake(3);
      expect(
        (await NFTStakingContract.getStakedTokenIds(owner.address)).toString()
      ).to.be.equal("1,2");
    });

    // If the callback function is async, Mocha will `await` it.
    it("Unregistered token cannot be unstake", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } =
        await loadFixture(deployFixture);
      for (let i = 0; i < 5; i++) {
        await SecondSkinNFTContract.mint("token_uri"); // token id 1
      }
      await NFTStakingContract.stake([1, 2, 3]);
      await expect(NFTStakingContract.unstake(4)).to.be.revertedWith(
        "Not staked yet"
      );
    });

    // If the callback function is async, Mocha will `await` it.
    it("_removeHoldNFT should work", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } =
        await loadFixture(deployFixture);
      for (let i = 0; i < 5; i++) {
        await SecondSkinNFTContract.mint("token_uri"); // token id 1
      }
      await NFTStakingContract.stake([1, 2, 3]);
      await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 1);
      await NFTStakingContract.stake([4]);
      expect(
        (await NFTStakingContract.getStakedTokenIds(owner.address)).toString()
      ).to.be.equal("3,2,4");
      await NFTStakingContract.unstake([3]);
      await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 2);
      expect(
        (await NFTStakingContract.getStakedTokenIds(owner.address)).toString()
      ).to.be.equal("4");
      await NFTStakingContract.unstake([4]);
      expect(
        (await NFTStakingContract.getStakedTokenIds(owner.address)).toString()
      ).to.be.equal("");
    });

    // If the callback function is async, Mocha will `await` it.
    it("Stake with empty should not work", async function () {
      const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } =
        await loadFixture(deployFixture);
      for (let i = 0; i < 5; i++) {
        await SecondSkinNFTContract.mint("token_uri"); // token id 1
      }
      await expect(NFTStakingContract.stake([])).to.be.revertedWith(
        "Empty array"
      );
    });
  });
});
