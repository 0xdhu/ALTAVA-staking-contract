async function main() {
  const secondskinNFT = "0x390708922E38E0e614574Ed9419a7103BAda5F6F";
  const TAVA = "0x9d7A56260516fEd6eBd255F0d82C483BC3D9DC3B";
  const [deployer] = await ethers.getSigners();
  console.log("Deployer: ", deployer.address);
  // // Deploy SecondskinNFT contract
  // const SecondSkinNFT = await ethers.getContractFactory(
  //   "SecondSkinNFT"
  // );
  // const SecondSkinNFTContract = await SecondSkinNFT.deploy(deployer.address);
  // await SecondSkinNFTContract.deployed();
  // const secondskinNFT = SecondSkinNFTContract.address;
  // console.log("SecondSkinNFT: ", secondskinNFT);

  // // Deploy TAVAC contract
  // const TAVAC = await ethers.getContractFactory(
  //   "TAVA"
  // );
  // const TAVAContract = await TAVAC.deploy();
  // await TAVAContract.deployed();
  // const TAVA = TAVAContract.address;
  // console.log("TAVA: ", TAVAContract.address);

  // // Deploy Booster Token contract
  // const BoosterController = await ethers.getContractFactory(
  //   "BoosterController"
  // );
  // const BoosterControllerContract = await BoosterController.deploy();
  // await BoosterControllerContract.deployed();
  // console.log("BoosterController: ", BoosterControllerContract.address);

  // // Deploy NFT Staking Contract
  // const NFTStaking = await ethers.getContractFactory("NFTStaking");
  // const NFTStakingContract = await NFTStaking.deploy(secondskinNFT);
  // await NFTStakingContract.deployed();
  // console.log("NFTStaking: ", NFTStakingContract.address);

  // // Deploy NFTMasterChef contract
  // const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");
  // const NFTMasterChefContract = await NFTMasterChef.deploy(
  //   TAVA,
  //   NFTStakingContract.address
  // );
  // await NFTMasterChefContract.deployed();
  // console.log("NFTMasterChef: ", NFTMasterChefContract.address);

  // Deploy MasterChef contract
  const MasterChef = await ethers.getContractFactory("MasterChef");
  console.log("Before")
  const MasterChefContract = await MasterChef.deploy(
    "0xb15a67F61d7250F5257A68e2D790AE03b913A59D"
    // NFTStakingContract.address
  );
  console.log("Middle", MasterChefContract)
  await MasterChefContract.deployed();
  console.log("MasterChef: ", MasterChefContract.address);
  //   return;
  // await NFTStakingContract.setMasterChef(MasterChefContract.address);
  // await NFTStakingContract.setNFTMasterChef(NFTMasterChefContract.address);

  // // Deploy token Factory contract
  // const TokenFactory = await ethers.getContractFactory("TokenFactory");
  // const TokenFactoryContract = await TokenFactory.deploy();
  // await TokenFactoryContract.deployed();
  // console.log("TokenFactory: ", TokenFactoryContract.address);

  // // Deploy NFT Factory contract
  // const NFTFactory = await ethers.getContractFactory("NFTFactory");
  // const NFTFactoryContract = await NFTFactory.deploy();
  // await NFTFactoryContract.deployed();
  // console.log("NFTFactory: ", NFTFactoryContract.address);

  // await TokenFactoryContract.deploy("Reward Test Token", "RTT");
  // await NFTFactoryContract.deploy("Bored Ape Golf Club", "BAGC");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
