## Veelancing-ICO-Contracts

In order to deploy the smart contracts you have to create new file ".env" in the main directory. After that open the file ".env_example" and copy all code to ".env". Empty parameters must be filled.

INFURA_API_KEY - your Infura api key

MNEMONIC - your mnemonic

ADRRESS_... - the addresses of accounts for Investors, Rewards, Team and Liquidity respectively.

ETH_STORAGE - the address of account for Ether storage.

RATE_ICO - the ratio of Ether to VEE token in the ICO period.

RATE_PRE_ICO - the ratio of Ether to VEE token in the ICO period.

START_PRE_ICO - time of starting pre-ICO period.

RATER_ROLE - account that has an access to change the ratio of Ether to VEE in each period.

DEPOSIT_ROLE - account that has an access to deposit on smart contract. It is used for situations when someone buys VEE tokens by USD or BTC and backend sends equivalent amount of ETH to the smart contract. So depositor role should be granted to backend account.

ADMIN_ROLE - account with admin rules.

### Install dependecies
```bash
npm install
```

### Local deploy
```bash
npm run deploy
```

### Deploy to Rinkeby Testnet
```bash
npm run deploy-rinkeby
```
### Deploy to MAINNET Network
```bash
npm run deploy-mainnet
```
