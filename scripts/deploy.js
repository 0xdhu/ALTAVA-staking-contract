async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer: ", deployer.address);
  
  // Deploy TAVA Token contract
  const TAVA = await ethers.getContractFactory("TAVA");
  const TAVAContract = await TAVA.deploy();
  await TAVAContract.deployed();
  console.log("TAVAContract: ", TAVAContract.address);

  // Deploy SecondskinNFT contract
  const SecondSkinNFT = await ethers.getContractFactory("SecondSkinNFT");
  const SecondSkinNFTContract = await SecondSkinNFT.deploy(
    deployer.address
  );
  await SecondSkinNFTContract.deployed();
  console.log("SecondSkinNFT: ", SecondSkinNFTContract.address);

  // Deploy ThirdParty NFT Generator contract
  const NFTFactory = await ethers.getContractFactory("NFTFactory");
  const NFTFactoryContract = await NFTFactory.deploy();
  await NFTFactoryContract.deployed();
  console.log("NFTFactory: ", NFTFactoryContract.address);

  // Deploy NFTMasterChef contract
  const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");
  const NFTMasterChefContract = await NFTMasterChef.deploy(
    TAVAContract.address,
    SecondSkinNFTContract.address
  );
  await NFTMasterChefContract.deployed();
  console.log("NFTMasterChef: ", NFTMasterChefContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });