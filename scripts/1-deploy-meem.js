require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const MEEMToken = await hre.ethers.getContractFactory("MEEMToken");
  const meemToken = await MEEMToken.deploy();
  await meemToken.deployed();
  console.log("MEEMToken deployed to:", meemToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
