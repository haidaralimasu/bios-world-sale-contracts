const { ethers } = require("hardhat");

async function main() {
  const HangingTrailsSaleBSC = await ethers.getContractFactory(
    "HangingTrailsSaleBSC"
  );
  const hangingTrailsSaleBSC = await HangingTrailsSaleBSC.deploy();

  await hangingTrailsSaleBSC.deployed();

  console.log(hangingTrailsSaleBSC.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
