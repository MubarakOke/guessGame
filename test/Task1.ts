import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect, assert } from "chai";
import { ethers } from "hardhat";


describe("Staking Contract Test", function () {
  async function deployStaking(){
    const Task = await ethers.getContractFactory("Task");
    const task = await Task.deploy();

    const ONE_MINUTE_IN_SECS = 60 * 60;
    const timing = (await time.latest()) + ONE_MINUTE_IN_SECS;
    
    const [account1, account2] = await ethers.getSigners();
    const amount = ethers.parseUnits("1", 18);

    approveERC20(account1.address, task.target, amount, task)
    return { task, account1, account2, amount };
  };

  async function approveERC20(account: any, address: any, amount: any, contract: any){
    const address2Signer= await ethers.getSigner(account.address);
    await contract.connect(address2Signer).approve(address, amount);
  };


  describe("Contract", async () => {
      it("deployed successfully", async () => {
          const { task, account1, amount} = await loadFixture(deployStaking);

      });

      it("can not stake zero successfully", async () => {
        const { task, account1, amount} = await loadFixture(deployStaking);
      });

  })     
         
});

