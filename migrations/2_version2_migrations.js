const CyberStakingRewards2 = artifacts.require("CyberStakingRewards2");

module.exports = async function (deployer) {
      await  deployer.deploy(CyberStakingRewards2,"0xf7fB89554f842F550499AEf4FDa2d1898039851f","0x297A03887539581AC84E49807D028Cbdf4350696","0xD4c27B5A5c15B1524FC909F0FE0d191C4e893695");
      
      let StakingPoolCoin = await CyberStakingRewards2.deployed();
      
};
