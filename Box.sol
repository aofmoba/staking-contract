//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Context.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";

contract BlindBox is Context, ERC1155{
    string public name;
    string public symbol;
    string public baseURL;

    mapping(address => bool) public minters;
    modifier onlyMinter() {
        require(minters[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    struct Box {
        uint    id;
        string  name;
        uint256 mintNum;
        uint256 openNum;
        uint256 totalSupply;
    }

    mapping(uint => Box) public boxMap;

    constructor(string memory url_) ERC1155(url_) {
        name = "Slime Blind Box";
        symbol = "SBOX";
        baseURL = url_;
        minters[_msgSender()] = true;
    }

    function newBox(uint boxID_, string memory name_, uint256 totalSupply_) public {
        //require(boxID_ > 0 &amp,&amp, boxMap[boxID_].id == 0, "box id invalid");
        boxMap[boxID_] = Box({
            id: boxID_,
            name: name_,
            mintNum: 0,
            openNum: 0,
            totalSupply: totalSupply_
        });
    }

    function updateBox(uint boxID_, string memory name_, uint256 totalSupply_) public {
        //require(boxID_ > 0 &amp,&amp, boxMap[boxID_].id == boxID_, "id invalid");
        require(totalSupply_ >= boxMap[boxID_].mintNum, "totalSupply err");

        boxMap[boxID_] = Box({
            id: boxID_,
            name: name_,
            mintNum: boxMap[boxID_].mintNum,
            openNum: boxMap[boxID_].openNum,
            totalSupply: totalSupply_
        });
    }

    function mint(address to_, uint boxID_, uint num_) public payable returns (bool) {
        require(num_ > 0, "mint number err");
        require(boxMap[boxID_].id != 0, "box id err");
        require(boxMap[boxID_].totalSupply >= boxMap[boxID_].mintNum + num_, "mint number is insufficient");

        boxMap[boxID_].mintNum += num_;
        _mint(to_, boxID_, num_, "");
        return true;
    }

    function mintBatch(address to_, uint[] memory boxIDs_, uint256[] memory nums_) public payable returns (bool) {
        require(boxIDs_.length == nums_.length, "array length unequal");

        for (uint i = 0; i < boxIDs_.length; i++) {
            require(boxMap[boxIDs_[i]].id != 0, "box id err");
            require(boxMap[boxIDs_[i]].totalSupply >= boxMap[boxIDs_[i]].mintNum + nums_[i], "mint number is insufficient");
            boxMap[boxIDs_[i]].mintNum += nums_[i];
        }

        _mintBatch(to_, boxIDs_, nums_, "");
        return true;
    }

    function burn(address from_, uint boxID_, uint256 num_) public {
        require(_msgSender() == from_ || isApprovedForAll(from_, _msgSender()), "burn caller is not owner nor approved");
        boxMap[boxID_].openNum += num_;
        _burn(from_, boxID_, num_);
    }

    function burnBatch(address from_, uint[] memory boxIDs_, uint256[] memory nums_) public {
        require(_msgSender() == from_ || isApprovedForAll(from_, _msgSender()), "burn caller is not owner nor approved");
        require(boxIDs_.length == nums_.length, "array length unequal");
        for (uint i = 0; i < boxIDs_.length; i++) {
            boxMap[boxIDs_[i]].openNum += nums_[i];
        }
        _burnBatch(from_, boxIDs_, nums_);
    }

    function setMinter(address newMinter, bool power) public {
        minters[newMinter] = power;
    }

    function boxURL(uint boxID_) public view returns (string memory) {
        require(boxMap[boxID_].id != 0, "box not exist");
        return string(abi.encodePacked(baseURL, boxID_));
    }

    function setURL(string memory newURL_) public {
        baseURL = newURL_;
    }

    //function setPause(bool isPause) public {
        //if (isPause) {
            //_pause();
        //} else {
           // _unpause();
        //}
    //}
}