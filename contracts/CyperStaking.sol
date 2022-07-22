// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./RewardsDistributionRecipient.sol";
import "./IStakingRewards.sol";
import "./CyberArms.sol";
import "./ERC20.sol";

/**pp
 * @dev Users pledge coins to obtain weapons
 * See https://github.com/cyberpopnw/staking-contract/blob/master/new%20StakingRewards.sol
 * Originally based on code by Enjin: https://github.com/Uniswap/liquidity-staker/blob/master/contracts/StakingRewards.sol
 *
 * _Available since v3.1._                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
 */
contract CyberStakingRewards is RewardsDistributionRecipient, ReentrancyGuard, ERC1155Holder{
    using SafeMath for uint256;
    IERC1155 public CyberArmsRewards;
    IERC20 public GoldCoin;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 private _totalSupply;

    // Mapping from account to userRewardPerTokenPaid
    mapping(address => uint256) public userRewardPerTokenPaid;
    // Mapping from account to account MiddleGoldCoin been exchanged
    mapping(address => uint256) public rewards;
    // Mapping from account to account GoldCoin been staked
    mapping(address => uint256) private _balances;
    mapping(uint256 => uint256) public _price;

    event RewardAdded (uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Reward(address _to, uint256 _id, uint256 k);

    /**
     * @dev See {_rewardsDistribution,
                _MiddleGoldCoin,
                _CyberArmsRewards}.
     */
    constructor (
        address _rewardsDistribution,
        address _GoldCoin,
        address _CyberArmsRewards
    ) {
        GoldCoin = IERC20(_GoldCoin);
        CyberArmsRewards = IERC1155(_CyberArmsRewards);
        rewardsDistribution = _rewardsDistribution;
        _price[1] = 10000;
        _price[2] = 30000;
        _price[3] = 60000;
    }

     modifier modifierfun(uint256 tokenId, uint256 n){
        _;  
    }

    /**
     * @dev See {IStakingRewards-getTotalSupply}.
     */
    function getTotalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IStakingRewards-getBalanceOf}.
     */
    function getBalanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IStakingRewards-lastTimeRewardApplicable}.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @dev See {IStakingRewards-rewardPerToken}.
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    /**
     * @dev See {IStakingRewards-earned}.
     */
    function earned(address account) public view returns (uint256) {
        uint256 earn = _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);    
        return earn;
    }

    /**
     * @dev See {IStakingRewards-getRewardForDuration}.
     */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /**
     * @dev See {IStakingRewards-DaysNeededPrediction}.
     */
    function DaysNeededPrediction(uint256 tokenId, address account)public view returns(uint256) {
        uint256 daysNeededNow = (_price[tokenId].sub(earned(account))).mul(1e18).div(rewardPerToken().mul(_balances[account]));
        return daysNeededNow;
    }

    /**
     * @dev get NFTs as Rewards.
     *
     * Emits a {Reward} event.
     *
     * Requirements:`
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function getNFT (uint256 k, uint256 tokenId) public nonReentrant updateReward(msg.sender){
        uint256 reward = rewards[msg.sender];
        uint256 cost = k.mul(_price[tokenId]);
        rewards[msg.sender] = rewards[msg.sender] - cost;
        CyberArmsRewards.safeTransferFrom(address(this), msg.sender, tokenId, k, "0x7465737400000000000000000000000000000000000000000000000000000000");
        emit Reward(msg.sender, tokenId, k);
    }

    /**
     * @dev See {IStakingRewards-stake}.
     */
    function stake(uint256 amount) external  nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        GoldCoin.transferFrom(msg.sender, address(this), amount);
        emit Staked(address(this), amount);
    }

    /**
     * @dev See {IStakingRewards-withdraw}.
     */
    function withdraw(uint256 amount) internal nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        //GoldCoin.approve(address(this), amount);
        //GoldCoin.transferFrom(address(this), msg.sender,amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev See {IStakingRewards-getReward}.
     */
    function getReward() internal nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev See {IStakingRewards-exit}.
     */
    function exit() external{
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /**
     * @dev how much MiddleCoin had been pulled in this pool.
     *
     * Emits a {RewardAdded} event.
     *
     * Requirements:`
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) override{
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /**
     * @dev update time and GoldCoin that had been got NFT.
     *
     * Requirements:`
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}