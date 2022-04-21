// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IStakingRewards.sol";

import "./ERC20.sol";
import "./ERC721.sol";
//import "./IStakingRewards.sol";
import "./ReentrancyGuard.sol";
import "./RewardsDistributionRecipient.sol";

contract StakingRewards is RewardsDistributionRecipient, ReentrancyGuard,ERC20{
    using SafeMath for uint256;
    //using ERC20 for IERC20;
    ERC721 public rewardsTokenx;
    ERC20 public rewardsToken;
    ERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 1 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor (
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _rewardsTokenx
    ) public payable{
        rewardsToken = ERC20(_rewardsToken);
        stakingToken = ERC20(_stakingToken);
        rewardsTokenx = ERC721(_rewardsTokenx);
        rewardsDistribution = _rewardsDistribution;
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function getBalanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    //function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        //require(amount > 0, "Cannot stake 0");
        //_totalSupply = _totalSupply.add(amount);
       // _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        //IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        //stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        //emit Staked(msg.sender, amount);
   // }
    function ERC20toERC721 () public payable{
        uint256 reward = rewards[msg.sender];
        uint256 tokenId = reward%10;
        rewards[msg.sender] = 0;
        rewardsToken.transferFrom(msg.sender, address(this), reward);
        rewardsTokenx.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function stake(uint256 amount) external payable nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.approve(address(this), amount);
        stakingToken.transferFrom(msg.sender,address(this),amount);
        //ERC20(msg.sender).transfer(address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public payable nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.approve(address(this), amount);
        stakingToken.transferFrom(address(this), msg.sender,amount);
        //ERC20(msg.sender).transfer(address(this), amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public payable nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.approve(address(this), reward);
            rewardsToken.transferFrom(address(this), msg.sender,reward);
            //ERC20(msg.sender).transfer(address(this), reward);
            emit RewardPaid(msg.sender, reward);
            //token.transferFrom(msg.sender, address(this), amount);
            //msg.sender.transfer(amount);
        }
    }

    function exit() external payable{
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external payable onlyRewardsDistribution updateReward(address(0)) override{
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    fallback() external payable{
       
    }
    

    /* ========== EVENTS ========== */

    event RewardAdded (uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

//interface IUniswapV2ERC20 {
    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

//}


