async function main() {
  
    const TAVA = "0x9d7A56260516fEd6eBd255F0d82C483BC3D9DC3B";
    const [deployer] = await ethers.getSigners();
    console.log("Deployer: ", deployer.address);
  
    // Deploy SecondskinNFT contract
    const SecondSkinNFT = await ethers.getContractFactory(
      "SecondSkinNFT"
    );
    const SecondSkinNFTContract = await SecondSkinNFT.deploy(deployer.address);
    await SecondSkinNFTContract.deployed();
    const secondskinNFT = SecondSkinNFTContract.address;
    console.log("SecondSkinNFT: ", secondskinNFT);

    // Deploy NFT Staking Contract
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    const NFTStakingContract = await NFTStaking.deploy(secondskinNFT);
    await NFTStakingContract.deployed();
    console.log("NFTStaking: ", NFTStakingContract.address);

    // Deploy SendOBT contract
    const SendOBT = await ethers.getContractFactory(
      "SendOBT",
    );
    const SendOBTContract = await SendOBT.deploy();
    await SendOBTContract.deployed();
    const sendOBTAddress = SendOBTContract.address;
    console.log("sendOBT Address: ", sendOBTAddress);
    
    await SendOBTContract.updateTavaAddress(TAVA);

    const nftmasterchefAddress = "0x2409379591922072ffCd097D0f8d6A52e93ab9dE";
    const NFTMasterChefContract = await ethers.getContractAt(
      "NFTMasterChef",
      nftmasterchefAddress
    );
    const masterchefAddress = "0x39931aDF1De4d068A5747e4c5d7B81f9CfADCfbE";
    const MasterChefContract = await ethers.getContractAt(
      "MasterChef",
      masterchefAddress
    );

  await NFTStakingContract.setMasterChef(masterchefAddress);
  await NFTStakingContract.setNFTMasterChef(nftmasterchefAddress);
  await MasterChefContract.setNFTStaking(NFTStakingContract.address);
  await NFTMasterChefContract.setNFTStaking(NFTStakingContract.address);

  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  