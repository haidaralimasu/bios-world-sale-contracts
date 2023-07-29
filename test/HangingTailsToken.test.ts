import { expect } from "chai";
import { ethers } from "hardhat";

describe("Hanging Trails Unit Tests", async () => {
  let HangingTrailsToken;
  let hangingTrailsToken;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addr4;

  beforeEach(async () => {
    HangingTrailsToken = await ethers.getContractFactory("HangingTrailsToken");
    [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    hangingTrailsToken = await HangingTrailsToken.deploy();
    await hangingTrailsToken.deployed();
  });

  describe("Deployment and Constructor", () => {
    it("should check native amount to swap is working or not", async () => {
      // await hangingTrailsToken.setFeeAccount(addr4.address, true);
      await hangingTrailsToken.transfer(
        hangingTrailsToken.address,
        "10000000000000000000000000"
      );
      await hangingTrailsToken.transfer(addr1.address, "100000000000000000000");

      await hangingTrailsToken.transfer(addr2.address, "1000000000000000000");
    });
  });
});
