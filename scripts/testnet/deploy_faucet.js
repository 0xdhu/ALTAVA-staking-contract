async function main() {
    const secondskinNFT = "0x322baa6c6290D48a0b64139997aa7E4247A2d40F";
    const TAVA = "0x9d7A56260516fEd6eBd255F0d82C483BC3D9DC3B";
    const [deployer] = await ethers.getSigners();
    console.log("Deployer: ", deployer.address);
  
    // Deploy SendOBT contract
    const SendOBT = await ethers.getContractFactory(
      "SendOBT",
    );
    const SendOBTContract = await SendOBT.deploy();
    await SendOBTContract.deployed();
    const sendOBTAddress = SendOBTContract.address;
    console.log("sendOBT Address: ", sendOBTAddress);
  
  
    await SendOBTContract.updateTavaAddress(TAVA);
    await SendOBTContract.updateAltavaSecondskinAddress(secondskinNFT);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  