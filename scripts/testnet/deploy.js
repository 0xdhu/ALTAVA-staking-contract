async function main() {
  // const secondskinNFT = "0x03222f6Ee842c079b3d88e7abDb362193FC5BE26";
  // const TAVA = "0x5Bd94A8Be93F2F9e918B8C08104962Bcd22a9B2D";
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

  // Deploy TAVAC contract
  const TAVAC = await ethers.getContractFactory(
    "TAVA"
  );
  const TAVAContract = await TAVAC.deploy();
  await TAVAContract.deployed();
  const TAVA = TAVAContract.address;
  console.log("TAVA: ", TAVAContract.address);

  // Deploy Booster Token contract
  const BoosterController = await ethers.getContractFactory(
    "BoosterController"
  );
  const BoosterControllerContract = await BoosterController.deploy();
  await BoosterControllerContract.deployed();
  console.log("BoosterController: ", BoosterControllerContract.address);

  // Deploy NFT Staking Contract
  const NFTStaking = await ethers.getContractFactory("NFTStaking");
  const NFTStakingContract = await NFTStaking.deploy(secondskinNFT);
  await NFTStakingContract.deployed();
  console.log("NFTStaking: ", NFTStakingContract.address);

  // Deploy NFTMasterChef contract
  const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");
  const NFTMasterChefContract = await NFTMasterChef.deploy(
    TAVA,
    NFTStakingContract.address
  );
  await NFTMasterChefContract.deployed();
  console.log("NFTMasterChef: ", NFTMasterChefContract.address);

  // Deploy MasterChef contract
  const MasterChef = await ethers.getContractFactory("MasterChef");
  const MasterChefContract = await MasterChef.deploy(
    NFTStakingContract.address
  );
  await MasterChefContract.deployed();
  console.log("MasterChef: ", MasterChefContract.address);

  await NFTStakingContract.setMasterChef(MasterChefContract.address);
  await NFTStakingContract.setNFTMasterChef(NFTMasterChefContract.address);

  // Deploy token Factory contract
  const TokenFactory = await ethers.getContractFactory("TokenFactory");
  const TokenFactoryContract = await TokenFactory.deploy();
  await TokenFactoryContract.deployed();
  console.log("TokenFactory: ", TokenFactoryContract.address);

  // Deploy NFT Factory contract
  const NFTFactory = await ethers.getContractFactory("NFTFactory");
  const NFTFactoryContract = await NFTFactory.deploy();
  await NFTFactoryContract.deployed();
  console.log("NFTFactory: ", NFTFactoryContract.address);

  // await TokenFactoryContract.deploy("AltavaStakingTestToken", "ASTT");
  // await NFTFactoryContract.deploy("AltavaStakingTestNFT", "ASTN");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
