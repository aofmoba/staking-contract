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
    address CyberArm;
    address users;

    mapping(address => mapping(uint256 => Infos)) public Information;
    event purchaseInformation(uint256 k, uint256 _id, uint256 _timestamp, uint256 volumes, address arms, address users);

    struct Infos {
        uint256 amount;

        uint256 purchaseTimestamp;

        uint256 getRewardedAmount;

        uint256 releaseBatches;

    }

    constructor (
        address _CetCoin,
        address _CyberArmsRewards,
        address _admin
    ) {
        CetCoin = IERC20(_CetCoin);
        CyberArmsRewards = IERC1155(_CyberArmsRewards);
        CyberArm = _CyberArmsRewards;
        users = _admin;
    }


    //计算购买这些CET一共需要多少usdt
    function getCETpeice(uint256 k) internal returns(uint256){
        requestVolumeData();
        CETprice = volume;
        cost = k.mul(volume);
        return cost;
    }
    //购买cet获取ERC1155
    function purchaseCyberArms(address _sender, uint256 _id, uint256 k, uint256 _purchasePeriod) public{
        getCETpeice(k);
        uint256 _batches = 6;
        uint256 emitTimestamp = block.timestamp.add(_purchasePeriod);
        Information[_sender][_id].amount = cost;
        Information[_sender][_id].purchaseTimestamp = block.timestamp.add(
            _purchasePeriod
        );
        Information[_sender][_id].releaseBatches = _batches;
        CetCoin.transferFrom(_sender, users, cost);
        CyberArmsRewards.safeTransferFrom(address(this), _sender, _id, k, "0x7465737400000000000000000000000000000000000000000000000000000000");
        emit purchaseInformation(k, _id, emitTimestamp, CETprice, CyberArm, msg.sender);
    }
}
