const CYTStakingRewards2 = artifacts.require("CYTStakingRewards2");


module.exports = async function (deployer) {
      await  deployer.deploy(CYTStakingRewards2,"0x297A03887539581AC84E49807D028Cbdf4350696","0x297A03887539581AC84E49807D028Cbdf4350696");
      
      let StakingPoolCoin = await CYTStakingRewards2.deployed();
      
};
