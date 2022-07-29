const CoinStakingRewards = artifacts.require("CoinStakingRewards");


module.exports = async function (deployer) {
      await  deployer.deploy(CoinStakingRewards,"0xf7fB89554f842F550499AEf4FDa2d1898039851f", "0x297A03887539581AC84E49807D028Cbdf4350696","0x297A03887539581AC84E49807D028Cbdf4350696");
      
      let StakingPoolCoin = await CoinStakingRewards.deployed();
      
};
