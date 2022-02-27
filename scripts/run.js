const main = async () => {
    const [owner, superCoder] = await hre.ethers.getSigners();
    const domainContractFactory = await hre.ethers.getContractFactory('Domains');
    // We pass in "whoami" to the constructor when deploying
    const domainContract = await domainContractFactory.deploy("whoami");
    await domainContract.deployed();
  
    console.log("Contract owner: ", owner.address);
    console.log("Contract deployed to:", domainContract.address);
  
    // We're passing in a second variable - value. This is the moneyyyyyyyyyy
    let txn = await domainContract.register("daniel",  {value: hre.ethers.utils.parseEther('1234')});
    await txn.wait();

    const address = await domainContract.getAddress("daniel");
    console.log("Owner of domain daniel:", address);

    // How much money is in here?
    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract balance:", hre.ethers.utils.formatEther(balance));

    // Quick! Grab the funds from the contract! (as superCoder)
    try {
      txn = await domainContract.connect(superCoder).withdraw();
      await txn.wait();
    } catch(error){
      console.log("Could not rob contract");
    }

    // Let's look in their wallet so we can compare later
    let ownerBalance = await hre.ethers.provider.getBalance(owner.address);
    console.log("Balance of owner before withdrawal:", hre.ethers.utils.formatEther(ownerBalance))

    txn = await domainContract.connect(owner).withdraw();
    await txn.wait();

    // Fetch balance of contract & owner
    const contractBalance = await hre.ethers.provider.getBalance(domainContract.address);
    ownerBalance = await hre.ethers.provider.getBalance(owner.address);

    console.log("Contract balance after withdrawal:", hre.ethers.utils.formatEther(contractBalance));
    console.log("Balance of owner after withdrawal:", hre.ethers.utils.formatEther(ownerBalance));
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