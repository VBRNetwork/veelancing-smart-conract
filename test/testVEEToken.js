const { expect } = require("chai");
const web3 = require("web3");
const BigNumber = require("bignumber.js");
const { ethers } = require("hardhat");

describe("Veelancing tests", async () => {

  let veetoken;
  let veecrowdsale;

  it("STEP 1. Create VEECrowdsale", async function () {
    const VEECrowdsale = await ethers.getContractFactory("VEECrowdsale");
    veecrowdsale = await VEECrowdsale.deploy(
      process.env.RATE_ICO,
      process.env.RATE_PRE_ICO,
      process.env.ETH_STORAGE,
      process.env.START_PRE_ICO,
      process.env.VOLUME_CROWDSALE,
      process.env.VOLUME_PRE_ICO
    );

    status = await veecrowdsale.getCurrentStatus();

    // console.log("Current status:", status);
  });

  it("STEP 2. Create VEE token and mint to account", async function () {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    const VEEToken = await ethers.getContractFactory("VEEToken");
    veetoken = await VEEToken.deploy(
      process.env.NAME,
      process.env.SYMBOL,
      process.env.TOTAL_SUPPLY,
      veecrowdsale.address,
      addr2.address,
      addr3.address,
      addr4.address,
      addr5.address,
      process.env.VOLUME_PRE_ICO,
      process.env.VOLUME_CROWDSALE,
      process.env.VOLUME_INVESTORS,
      process.env.VOLUME_REWARDS,
      process.env.VOLUME_TEAM,
      process.env.VOLUME_LIQUIDITY
    );

    CrowdsaleBalance = await veetoken.balanceOf(veecrowdsale.address);
    expect(CrowdsaleBalance).to.equal(ethers.utils.parseEther("510000000.0"));

    veecrowdsale.initialize(veetoken.address);
  });


  it("STEP 3. Check roles", async () => {
    const [owner] = await ethers.getSigners();

    let rater_role = await veecrowdsale.RATER_ROLE();
    let deposit_role = await veecrowdsale.DEPOSIT_ROLE();

    // grant role rater
    await veecrowdsale.grantRole(
      rater_role,
      owner.address,
    );

    await veecrowdsale.grantRole(
      deposit_role,
      owner.address,
    );
  });

  it("STEP 4. External ICO", async function () {
    const provider = await ethers.provider;

    const [...addr] = await ethers.getSigners();
    const [addr1] = await ethers.getSigners();
    let balanceVee = await veetoken.balanceOf(addr[6].address);
    expect(balanceVee).to.equal(0);

    let balanceEth = await provider.getBalance(addr[6].address);
    expect(balanceEth).to.equal(ethers.utils.parseEther("10000.0"));

    await addr[6].sendTransaction({
      to: veecrowdsale.address,
      value: ethers.utils.parseEther("2.0")
    });

    balanceVee = await veetoken.balanceOf(addr[6].address);
    expect(balanceVee).to.equal(ethers.utils.parseEther("0.5"));
  });

  it("STEP 5. ICO and change rate", async function () {
    const [...addr] = await ethers.getSigners();

    balanceVee = await veetoken.balanceOf(addr[1].address);
    expect(balanceVee).to.equal(ethers.utils.parseEther("0"));

    await veecrowdsale.updateRateICO(6000000);

    await addr[1].sendTransaction({
      to: veecrowdsale.address,
      value: ethers.utils.parseEther("1.0")
    });

    balanceVee = await veetoken.balanceOf(addr[1].address);
    expect(balanceVee).to.equal(ethers.utils.parseEther("6.0"));
  });


  it("STEP 6. Pre-ICO", async function () {
    const provider = await ethers.provider;
    const [...addr] = await ethers.getSigners();
    let balanceVee = await veetoken.balanceOf(addr[6].address);
    expect(balanceVee).to.equal(ethers.utils.parseEther("0.5"));

    await veecrowdsale.deposit(
      addr[6].address,
      ethers.utils.parseEther("5.0")
    )

    await veecrowdsale.deposit(
      addr[5].address,
      ethers.utils.parseEther("5.0")
    )

    await veecrowdsale.deposit(
      addr[4].address,
      ethers.utils.parseEther("5.0")
    )
    
    let preICO = await veecrowdsale.amountICO();
  });
});
