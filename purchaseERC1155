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

    mapping(uint256 => uint256) public _price;

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

    function getCETpeice(uint256 k) internal returns(uint256){
        requestVolumeData();
        CETprice = volume;
        cost = k.mul(volume);
        return cost;
    }

    function purchaseCyberArms(uint256 tokenId, uint256 k) public{
        getCETpeice(k);
        CetCoin.transferFrom(msg.sender, address(this), cost);
        CyberArmsRewards.safeTransferFrom(address(this), msg.sender, tokenId, k, "0x7465737400000000000000000000000000000000000000000000000000000000");
    }
    
    
    
}
