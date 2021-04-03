const hre = require("hardhat");

async function main() {
  const accounts = await hre.ethers.getSigners();
  const network = await hre.ethers.provider
  console.log(network._network === undefined);
  const VEEToken = await hre.ethers.getContractFactory("VEEToken");
  const veetoken = await VEEToken.deploy(
    process.env.NAME,
    process.env.SYMBOL,
    process.env.TOTAL_SUPPLY,

    network._network === undefined || network._network.name === 'mainnet' ?
      process.env.ADDRESS_CROWDSALE : accounts[0].address,
    network._network === undefined || network._network.name === 'mainnet' ?
      process.env.ADDRESS_INVESTORS : accounts[1].address,
    network._network === undefined || network._network.name === 'mainnet' ?
      process.env.ADDRESS_REWARDS : accounts[2].address,
    network._network === undefined || network._network.name === 'mainnet' ?
      process.env.ADDRESS_TEAM : accounts[3].address,
    network._network === undefined || network._network.name === 'mainnet' ?
      process.env.ADDRESS_LIQUIDITY : accounts[4].address,

    process.env.VOLUME_PRE_ICO,
    process.env.VOLUME_CROWDSALE,
    process.env.VOLUME_INVESTORS,
    process.env.VOLUME_REWARDS,
    process.env.VOLUME_TEAM,
    process.env.VOLUME_LIQUIDITY
  );

  console.log(`VEE token deployed to: ${veetoken.address}
  gasPrice: ${veetoken.deployTransaction.gasPrice.toString()}
  gasLimit: ${veetoken.deployTransaction.gasLimit.toString()}`);

  const VEECrowdsale = await hre.ethers.getContractFactory("VEECrowdsale");

  const veecrowdsale = await VEECrowdsale.deploy(
    process.env.RATE_ICO,
    process.env.RATE_PRE_ICO,
    network._network === undefined || network._network.name === 'mainnet' ?
      process.env.ETH_STORAGE : accounts[1].address,
    process.env.START_PRE_ICO,
    process.env.VOLUME_CROWDSALE,
    process.env.VOLUME_PRE_ICO
  );

  console.log(`VEELCrowdsale deployed to: ${veecrowdsale.address}
  gasPrice: ${veecrowdsale.deployTransaction.gasPrice.toString()}
  gasLimit: ${veecrowdsale.deployTransaction.gasLimit.toString()}`);

  const rater_address = network._network === undefined || network._network.name === 'mainnet' ?
    process.env.DEPOSIT_ROLE :
    accounts[0].address;

  const deposit_address = network._network === undefined || network._network.name === 'mainnet' ?
    process.env.RATER_ROLE :
    accounts[0].address;

  const admin_address = network._network === undefined || network._network.name === 'mainnet' ?
    process.env.ADMIN_ROLE :
    accounts[0].address;

  let rater_role = await veecrowdsale.RATER_ROLE();
  let deposit_role = await veecrowdsale.DEPOSIT_ROLE();
  let admin_role = await veecrowdsale.ADMIN_ROLE();

  // grant role rater
  await veecrowdsale.grantRole(
    rater_role,
    rater_address,
  );

  await veecrowdsale.grantRole(
    deposit_role,
    deposit_address,
  );
  
  await veecrowdsale.grantRole(
    admin_role,
    admin_address,
  );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });