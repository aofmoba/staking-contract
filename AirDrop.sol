//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC20.sol";
contract AirDrop is Ownable, CyberPopToken {
    CyberPopToken public DropToken;
    bytes32 immutable public root; // Merkle书的根
    mapping(address => uint256) public mintedAddress;   // 记录已经mint的地址
    mapping(address => bool) public minted;

    // 构造函数，初始化NFT合集的名称、代号、Merkle树的根
    constructor(address token, bytes32 merkleroot)
    {
        DropToken = CyberPopToken(token);
        root = merkleroot;
    }

    // 利用Merkle书验证地址并mint
    function getDrop(address account, uint256 amount, bytes32[] calldata proof)
    external
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); // Merkle检验通过
        require(!minted[account], "Already minted!");
        require(
            DropToken.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        DropToken.mint(account, amount); // mint
        mintedAddress[account] += amount; // 记录mint过的地址
        minted[account] = true;
    }

    // 计算Merkle书叶子的哈希值
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    // Merkle树验证，调用MerkleProof库的verify()函数
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
