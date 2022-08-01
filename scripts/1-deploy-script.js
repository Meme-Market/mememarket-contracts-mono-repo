const hre = require("hardhat");
async function main() {
  const FEE_WALLET = process.env.FEE_WALLET;

  const Memera = await hre.ethers.getContractFactory("Memera");
  const memera = await Memera.deploy();
  await memera.deployed();
  console.log("Memera deployed to:", memera.address);

  const MemeStonk = await hre.ethers.getContractFactory("MemeStonk");
  const memeStonk = await MemeStonk.deploy(memera.address, 5, FEE_WALLET);
  await memeStonk.deployed();
  console.log("MemeStonk deployed to:", memeStonk.address);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
