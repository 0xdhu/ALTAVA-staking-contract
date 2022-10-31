const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { sleep } = require("./utils");

const testId = "test_id";

describe("Secondskin NFT Staking for booster", function () {
    // Network to that snapshot in every test.
    async function deployFixture() {
        // Get the ContractFactory and Signers here.
        const [owner, addr1, addr2] = await ethers.getSigners();
0
        // Deploy SecondskinNFT contract
        const SecondSkinNFT = await ethers.getContractFactory("SecondSkinNFT");
        const SecondSkinNFTContract = await SecondSkinNFT.deploy(
            owner.address
        );
        await SecondSkinNFTContract.deployed();


        // Deploy NFT Staking Contract
        const NFTStaking = await ethers.getContractFactory("NFTStaking");
        const NFTStakingContract = await NFTStaking.deploy(
            SecondSkinNFTContract.address
        );
        await NFTStakingContract.deployed();

     
        // Fixtures can return anything you consider useful for your tests
        return { 
            NFTStakingContract, SecondSkinNFTContract, owner, addr1, addr2
        };
    }

    // You can nest describe calls to create subsections.
    describe("NFTStaking: Deployment should work correctly", function () {
        // If the callback function is async, Mocha will `await` it.
        it("Should set the right owner and secondskin nft", async function () {
            const { NFTStakingContract, SecondSkinNFTContract, owner } = await loadFixture(deployFixture);

            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.            
            expect(await NFTStakingContract.owner()).to.equal(owner.address);
            expect(await NFTStakingContract.secondskinNFT()).to.equal(SecondSkinNFTContract.address);

        });
    });

    // You can nest describe calls to create subsections.
    describe("NFTStaking: Stake should work correctly", function () {
        it("Able to stake only owned NFT that exists", async function () {
            const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } = await loadFixture(deployFixture);

            // token id (1) has not been mint
            await expect(NFTStakingContract.stake([1])).to.be.revertedWith("ERC721: invalid token ID")
            
            await SecondSkinNFTContract.mint("token_uri"); // token id 1
            await SecondSkinNFTContract.mint("token_uri"); // token id 2
            await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 1);
            // only owned NFT
            await expect(NFTStakingContract.stake([1, 2])).to.be.revertedWith("You are not owner");
        });
        // If the callback function is async, Mocha will `await` it.
        it("Double Stake should work", async function () {
            const { NFTStakingContract, SecondSkinNFTContract, owner } = await loadFixture(deployFixture);

            await SecondSkinNFTContract.mint("token_uri"); // token id 1
            await SecondSkinNFTContract.mint("token_uri"); // token id 2
            await NFTStakingContract.stake([1, 2, 1]);

            await SecondSkinNFTContract.mint("token_uri"); // token id 3
            await SecondSkinNFTContract.mint("token_uri"); // token id 4
            await NFTStakingContract.stake([3, 4]);

            // Staked NFT addresses
            expect(await NFTStakingContract.check_staked(owner.address, 1)).to.be.equal(true)
            expect(await NFTStakingContract.check_staked(owner.address, 2)).to.be.equal(true)
            expect(await NFTStakingContract.check_staked(owner.address, 3)).to.be.equal(true)
            expect(await NFTStakingContract.check_staked(owner.address, 4)).to.be.equal(true)

            expect((await NFTStakingContract.getStakedTokenIds(owner.address)).toString()).to.be.equal(
                '1,2,3,4'
            );
            expect(await NFTStakingContract.getStakedNFTCount(owner.address)).to.be.equal(4);

            // const stakedIds = await NFTStakingContract.getStakedTokenIds(owner.address);
            // console.log(stakedIds)
        });


        // If the callback function is async, Mocha will `await` it.
        it("Double Stake should work", async function () {
            const { NFTStakingContract, SecondSkinNFTContract, owner, addr1 } = await loadFixture(deployFixture);

            await SecondSkinNFTContract.mint("token_uri"); // token id 1
            await SecondSkinNFTContract.mint("token_uri"); // token id 2
            await NFTStakingContract.stake([1, 2]);
            expect(await NFTStakingContract.getStakedNFTCount(owner.address)).to.be.equal(2);

            await SecondSkinNFTContract.transferFrom(owner.address, addr1.address, 2);
            expect(await NFTStakingContract.getStakedNFTCount(owner.address)).to.be.equal(1);
            
            await SecondSkinNFTContract.mint("token_uri"); // token id 3
            await SecondSkinNFTContract.mint("token_uri"); // token id 4
            await NFTStakingContract.stake([3, 4]);

            // Staked NFT addresses
            expect(await NFTStakingContract.check_staked(owner.address, 1)).to.be.equal(true)
            expect(await NFTStakingContract.check_staked(owner.address, 2)).to.be.equal(false)
            expect(await NFTStakingContract.check_staked(owner.address, 3)).to.be.equal(true)
            expect(await NFTStakingContract.check_staked(owner.address, 4)).to.be.equal(true)

            expect((await NFTStakingContract.getStakedTokenIds(owner.address)).toString()).to.be.equal(
                '1,3,4'
            );
            expect(await NFTStakingContract.getStakedNFTCount(owner.address)).to.be.equal(3);

            // const stakedIds = await NFTStakingContract.getStakedTokenIds(owner.address);
            // console.log(stakedIds)
        });
    });
});