const { ethers } = require("hardhat");

async function main() {
  const HangingTrails = await ethers.getContractFactory("HangingTrailsToken");
  const hangingTrails = await HangingTrails.deploy();

  await hangingTrails.deployed();
  await hangingTrails.transferOwnership(
    "0x6FA6DA462CBA635b0193809332387cDC25Df3e8D"
  );

  console.log(hangingTrails.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
