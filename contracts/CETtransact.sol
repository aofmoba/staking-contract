// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./APIConsumer.sol";
import "./ERC20.sol";
import "./CyberArms.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract CETtransact is APIConsumer, ERC1155Holder{
    using SafeMath for uint256;
    IERC1155 public CyberArmsRewards;
    IERC20 public CetCoin;
    uint256 CETprice;
    uint256 cost;
    uint256 public constant BATCH_PERIOD = 1;

    mapping(uint256 => uint256) public _price;
    mapping(address => mapping(uint256 => Infos)) public Information;

    struct Infos {
        uint256 amount;

        uint256 purchaseTimestamp;

        uint256 getRewardedAmount;

        uint256 releaseBatches;

    }

    constructor (
        address _CetCoin,
        address _CyberArmsRewards
    ) {
        CetCoin = IERC20(_CetCoin);
        CyberArmsRewards = IERC1155(_CyberArmsRewards);
        _price[1] = 100;
        _price[2] = 300;
        _price[3] = 600;
    }
    //计算购买这些CET一共需要多少usdt
    function getCETpeice(uint256 k) internal returns(uint256){
        requestVolumeData();
        CETprice = volume;
        cost = k.mul(volume);
        return cost;
    }
    //购买cet
    function purchaseCyberArms(address _sender, uint256 _id, uint256 k, uint256 _purchasePeriod, uint256 _batches) public{
        getCETpeice(k);
        Information[_sender][_id].amount = cost;
        Information[_sender][_id].purchaseTimestamp = block.timestamp.add(
            _purchasePeriod
        );
        Information[_sender][_id].releaseBatches = _batches;
        CetCoin.transferFrom(_sender, address(this), cost);
        CyberArmsRewards.safeTransferFrom(address(this), _sender, _id, k, "0x7465737400000000000000000000000000000000000000000000000000000000");
    }
    //获取奖励(奖励数额等于购买CET花费的USDT数额)
    function getReward(uint256 _id) external {
        require(
            Information[msg.sender][_id].purchaseTimestamp < block.timestamp,
            "CYT Infos: stake duration not passed"
        );
        uint256 _amount = releasedAmount(msg.sender, _id);
        require(_amount > 0, "CYT Infos: insufficient balance");
        
        subBalance(msg.sender, _amount, _id);
        IERC20(CetCoin).transfer(msg.sender, _amount);
    }
    //计算一共需要给用户分多少usdt
    function releasedAmount(address _beneficient, uint256 _id)
        public
        view
        returns (uint256 amounts)
    {
        uint256 _now = block.timestamp;
        if (Information[_beneficient][_id].purchaseTimestamp == 0 || _now < Information[_beneficient][_id].purchaseTimestamp) {
            return 0;
        }
        uint256 delta = _now.sub(Information[_beneficient][_id].purchaseTimestamp);
        uint256 batches = delta.div(BATCH_PERIOD) + 1; // starting from 1
        if (batches >= Information[_beneficient][_id].releaseBatches) {
            return Information[_beneficient][_id].amount - Information[_beneficient][_id].getRewardedAmount;
        }
        return
            (Information[_beneficient][_id].amount * batches) /
            Information[_beneficient][_id].releaseBatches -
            Information[_beneficient][_id].getRewardedAmount;
    }
    //计算
    function subBalance(address _sender, uint256 _amount, uint256 _id) private {
        Information[_sender][_id].getRewardedAmount = Information[_sender][_id]
            .getRewardedAmount
            .add(_amount);
        if (
            Information[_sender][_id].amount <=
            Information[_sender][_id].getRewardedAmount
        ) {
            delete Information[_sender][_id]; // clean up storage for purchaseTimestamp
        }
    }
    
}
