const hre = require("hardhat");
async function main() {

  const MemeERC20 = await hre.ethers.getContractFactory("MemeERC20");
  const memeERC20 = await MemeERC20.deploy();
  await memeERC20.deployed();
  console.log("MemeERC20 deployed to:", memeERC20.address);

  const MemeERC721 = await hre.ethers.getContractFactory("MemeERC721");
  const memeERC721 = await MemeERC721.deploy();
  await memeERC721.deployed();
  console.log("MemeERC721 deployed to:", memeERC721.address);

  const MemePoolFactory = await hre.ethers.getContractFactory("MemePoolFactory");
  const memePoolFactory = await MemePoolFactory.deploy();
  await memePoolFactory.deployed();
  console.log("MemePoolFactory deployed to:", memePoolFactory.address);

  const MemePoolLiquidity = await hre.ethers.getContractFactory("MemePoolLiquidity");
  const memePoolLiquidity = await MemePoolLiquidity.deploy();
  await memePoolLiquidity.deployed();
  console.log("MemePoolLiquidity deployed to:", memePoolLiquidity.address);

  const MemePoolPair = await hre.ethers.getContractFactory("MemePoolPair");
  const memePoolPair = await MemePoolPair.deploy();
  await memePoolPair.deployed();
  console.log("MemePoolPair deployed to:", memePoolPair.address);

}
main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});