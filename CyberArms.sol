// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract CyberArms is Context, ERC1155{

    struct Box {
        uint    id;
        string  name;
        uint256 mintNum;
        uint256 openNum;
        uint256 totalSupply;
    }

    mapping(uint => Box) public boxMap;

    constructor(string memory url_) ERC1155(url_) {

    }

    function mint(address to_, uint boxID_, uint num_) public returns (bool) {
        boxMap[boxID_].mintNum += num_;
        _mint(to_, boxID_, num_, "");
        return true;
    }

    function mintBatch(address to_, uint[] memory boxIDs_, uint256[] memory nums_) public returns (bool) {
        require(boxIDs_.length == nums_.length, "array length unequal");

        for (uint i = 0; i < boxIDs_.length; i++) {
            require(boxMap[boxIDs_[i]].id != 0, "box id err");
            require(boxMap[boxIDs_[i]].totalSupply >= boxMap[boxIDs_[i]].mintNum + nums_[i], "mint number is insufficient");
            boxMap[boxIDs_[i]].mintNum += nums_[i];
        }

        _mintBatch(to_, boxIDs_, nums_, "");
        return true;
    }
}
