// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./APIConsumer.sol";
import "./ERC20.sol";
import "./CyberArms.sol";
import "./CETtransact.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Reward {
    IERC20 public CetCoin;

    uint256 amount;
    uint256 purchaseTimestamp;
    uint256 getRewardedAmount;
    uint256 releaseBatches;


    uint256 public constant BATCH_PERIOD = 1;
    CETtransact public Information;

    constructor (
        address _Inform,
        address _CetCoin
    ) {
        Information = CETtransact(_Inform);
        CetCoin = IERC20(_CetCoin);
    }

    function readInformation(address user, uint256 id) public returns(uint256 _amount,

        uint256 _purchaseTimestamp,

        uint256 _getRewardedAmount,

        uint256 _releaseBatches) {
        
        amount = _amount;
        purchaseTimestamp = _purchaseTimestamp;
        getRewardedAmount = _getRewardedAmount;
        releaseBatches = _releaseBatches;

        return(Information.Information(user, id));
    }

    //获取奖励(奖励数额等于购买CET花费的USDT数额)
    function getReward(uint256 _id) external {
        readInformation(msg.sender, _id);
        require(
            purchaseTimestamp < block.timestamp,
            "CYT Infos: stake duration not passed"
        );
        uint256 _amount = releasedAmount(msg.sender, _id);
        require(_amount > 0, "CYT Infos: insufficient balance");
        
        subBalance(msg.sender, _amount, _id);
        CetCoin.transfer(msg.sender, _amount);
    }
    //计算一共需要给用户分多少usdt
    function releasedAmount(address _beneficient, uint256 _id)
        public
        
        returns (uint256 amounts)
    {
        readInformation(_beneficient, _id);
        uint256 _now = block.timestamp;
        if (purchaseTimestamp == 0 || _now < purchaseTimestamp) {
            return 0;
        }
        uint256 delta = _now-(purchaseTimestamp);
        uint256 batches = delta/BATCH_PERIOD + 1; // starting from 1
        if (batches >= releaseBatches) {
            return amount - getRewardedAmount;
        }
        return
            (amount * batches) /
            releaseBatches -
            getRewardedAmount;
    }
    //计算
    function subBalance(address _sender, uint256 _amount, uint256 _id) private {
        readInformation(_sender, _id);
        require( amount <= getRewardedAmount, "can be deleted");
        getRewardedAmount = 
            getRewardedAmount
            +_amount;
    }
    
}
