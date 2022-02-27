const main = async () => {
    const [owner, superCoder] = await hre.ethers.getSigners();
    const domainContractFactory = await hre.ethers.getContractFactory('Domains');
    // We pass in "whoami" to the constructor when deploying
    const domainContract = await domainContractFactory.deploy("whoami");
    await domainContract.deployed();
  
    console.log("Contract owner: ", owner.address);
    console.log("Contract deployed to:", domainContract.address);
  
    // Register several domains
    let txn = await domainContract.register("daniel",  {value: hre.ethers.utils.parseEther('0.1')});
    await txn.wait();
    txn = await domainContract.register("testing",  {value: hre.ethers.utils.parseEther('0.1')});
    await txn.wait();
    txn = await domainContract.register("adomain",  {value: hre.ethers.utils.parseEther('0.1')});
    await txn.wait();

    let names = await domainContract.getAllNames();
    console.log("Found registered domains: ", names);
  }
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();