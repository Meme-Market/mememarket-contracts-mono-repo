require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const FEE_WALLET = process.env.FEE_WALLET;
  const MEMERA_ADDRESS = process.env.MEMERA_ADDRESS;

  console.log(hre);

  const MemeStonk = await hre.ethers.getContractFactory("MemeStonk");
  const memeStonk = await MemeStonk.deploy(MEMERA_ADDRESS, 5, FEE_WALLET);
  await memeStonk.deployed();
  console.log("MemeStonk deployed to:", memeStonk.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
