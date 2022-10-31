async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer: ", deployer.address);
    
    // Deploy TAVA Token contract
    const TAVA = "" // mainnet address
  
    // Deploy SecondskinNFT contract
    const SecondSkinNFT = "" // mainnet address
  
    // Deploy NFT Staking Contract
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    const NFTStakingContract = await NFTStaking.deploy(
        SecondSkinNFT
    );
    await NFTStakingContract.deployed();
    console.log("NFTStaking: ", NFTStakingContract.address);
  
    // Deploy ThirdParty NFT Generator contract
    const NFTFactory = await ethers.getContractFactory("NFTFactory");
    const NFTFactoryContract = await NFTFactory.deploy();
    await NFTFactoryContract.deployed();
    console.log("NFTFactory: ", NFTFactoryContract.address);
  
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
        TAVAContract.address,
        NFTStakingContract.address
    );
    await MasterChefContract.deployed();
    console.log("MasterChef: ", MasterChefContract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });