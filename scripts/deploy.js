async function main() {
  const [deployer] = await ethers.getSigners();
  
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

  // Deploy ThirdParty NFT Generator contract
  const NFTFactory = await ethers.getContractFactory("NFTFactory");
  const NFTFactoryContract = await NFTFactory.deploy();
  await NFTFactoryContract.deployed();

  // Deploy NFTMasterChef contract
  const NFTMasterChef = await ethers.getContractFactory("NFTMasterChef");
  const NFTMasterChefContract = await NFTMasterChef.deploy(
    TAVAContract.address,
    SecondSkinNFTContract.address
  );
  await NFTMasterChefContract.deployed();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });