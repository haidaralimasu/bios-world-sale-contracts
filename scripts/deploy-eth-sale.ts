const { ethers } = require("hardhat");

async function main() {
  const HangingTrailsSaleETH = await ethers.getContractFactory(
    "HangingTrailsSaleETH"
  );
  const hangingTrailsSaleETH = await HangingTrailsSaleETH.deploy();

  await hangingTrailsSaleETH.deployed();

  console.log(hangingTrailsSaleETH.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
