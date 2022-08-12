require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const FEE_WALLET = process.env.FEE_WALLET;
  const MEEM_TOKEN_ADDRESS = process.env.MEEM_TOKEN_ADDRESS;

  const MemeStonk = await hre.ethers.getContractFactory("MemeStonk");
  const memeStonk = await MemeStonk.deploy(MEEM_TOKEN_ADDRESS, 5, FEE_WALLET);
  await memeStonk.deployed();
  console.log("MemeStonk deployed to:", memeStonk.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
