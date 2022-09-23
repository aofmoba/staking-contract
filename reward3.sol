// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Rewards is Ownable {
    using SafeMath for uint256;
    uint256 public k;
    IERC20 public rewardsToken;
    
    uint256 public BATCH_PERIOD = 5;
    uint256 releaseBatches = 6;

    event profit(uint256 indexed k, uint256 indexed m, uint256 indexed t);
    event Withdrawn(address indexed m, uint256 n);

    struct Staker {
        
        uint256 stakeTimestamp;
        
        uint256 stakedAmount;
        
        uint256 getRewardedAmount;
    }

    mapping(address => mapping(uint256 => Staker)) public stakedBalances;
    
    uint256 public totalstaked;

    event getRewards(address user, uint256 amount);

    constructor(
        address _rewardsToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
    }
    
    function settings(uint256 _k, uint256 _BATCH_PERIOD, uint256 _releaseBatches) external onlyOwner {
        k = _k;
        BATCH_PERIOD = _BATCH_PERIOD;
        releaseBatches = _releaseBatches;
        emit profit(k, BATCH_PERIOD, releaseBatches);
    }
    /**
     * @dev Token owner can use this function to release their fund after the stake period
     */
    function getReward(address user, uint256 _id) external {
        require(
            stakedBalances[user][_id].stakeTimestamp < block.timestamp,
            "CYT staker: stake duration not passed"
        );
        uint256 _amount = releasedAmount(user, _id);
        require(_amount > 0, "CYT staker: insufficient balance");
        
        emit getRewards(user, _amount);
        subBalance(user, _amount, _id);
        IERC20(rewardsToken).transfer(user, _amount);
    }

    /**
     * @notice Mint Token to this contract, mark the owner and stake period
     * @dev Can only be called by owner
     * @param _sender The beneficient of the token
     * @param _amount Total staked up amount
     * @param _stakePeriod staked period before the first release
     */
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _stakePeriod,
        uint256 _id
    ) external {
        require(stakedBalances[_sender][_id].stakedAmount == 0, "the id has been used!");
        uint256 stakedAmount = stakedBalances[_sender][_id].stakedAmount;
        require(_id > 0, "id > 0");
        require(stakedBalances[_sender][_id].stakedAmount == 0, "the id has been used!");

        stakedBalances[_sender][_id].stakedAmount = _amount*k/100;
        stakedBalances[_sender][_id].stakeTimestamp = block.timestamp.add(
            _stakePeriod
        );
        totalstaked = totalstaked.add(_amount*k/100);
    }

    /**
     * @notice Query released amount for the beneficient address
     * @param _beneficient Address of the beneficient
     */
    function releasedAmount(address _beneficient, uint256 _id)
        public
        view
        returns (uint256 amounts)
    {
        uint256 _now = block.timestamp;
        Staker memory staker = stakedBalances[_beneficient][_id];
        if (staker.stakeTimestamp == 0 || _now < staker.stakeTimestamp) {
            return 0;
        }
        uint256 delta = _now.sub(staker.stakeTimestamp);
        uint256 batches = delta.div(BATCH_PERIOD) + 1; // starting from 1
        if (batches >= releaseBatches) {
            return staker.stakedAmount - staker.getRewardedAmount;
        }
        return
            (staker.getRewardedAmount * batches) /
            releaseBatches -
            staker.getRewardedAmount;
    }

    function subBalance(address _sender, uint256 _amount, uint256 _id) private {
        stakedBalances[_sender][_id].getRewardedAmount = stakedBalances[_sender][_id]
            .getRewardedAmount
            .add(_amount);
        if (
            stakedBalances[_sender][_id].stakedAmount <=
            stakedBalances[_sender][_id].getRewardedAmount
        ) {
            delete stakedBalances[_sender][_id]; // clean up storage for stakeTimestamp
        }
        totalstaked = totalstaked - _amount;
    }
}
