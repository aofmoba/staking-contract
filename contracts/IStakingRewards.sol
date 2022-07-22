/// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getPrice(uint256 tokenId) external view returns (uint256);

    function DaysNeededPrediction(uint256 tokenId, address account) external view returns(uint256);
    // Mutative

    function stake(uint256 amount) external payable;

    function withdraw(uint256 amount) external payable;

    function getReward() external payable;

    function choose (uint256 k ,uint256 tokenId) external returns(uint256);

    function exit() external payable;
    function ERC20toERC721() external payable;
}