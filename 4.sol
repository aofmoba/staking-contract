// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Timestake is Ownable {
    using SafeMath for uint256;
    address public token;
    uint256 public k;

    // Release every 30 days after the stake period
    //uint256 public constant BATCH_PERIOD = 24 * 60 * 60 * 30;
    uint256 public constant BATCH_PERIOD = 1;

    event profit(uint256 indexed k);
    event Withdrawn(address indexed m, uint256 n);

    struct Staker {
        // release cliff
        uint256 stakeTimestamp;
        // total staked amount per address
        uint256 stakedAmount;
        // number of batches to release total staked amount
        //uint256 releaseBatches;
        // persist getRewarded amount up to date
        uint256 getRewardedAmount;
    }

    struct Restaker {
        // release cliff
        uint256 stakeTimestamp;
        // total staked amount per address
        uint256 stakedAmount;
        // number of batches to release total staked amount
        //uint256 releaseBatches;
        // persist getRewarded amount up to date
        uint256 getRewardedAmount;
    }

    // staked amount and release time for each address
    mapping(address => Staker) public stakedBalances;
    mapping(uint256 => Restaker) private restakedBalances;
    mapping(address => uint256) public userStake;
    uint256 public totalstaked;

    event getRewards(address user, uint256 amount);

    constructor(address _token) {
        token = _token;
    }
    
    function setk(uint256 _k) external onlyOwner {
        k = _k;
        emit profit(k);
    }
    /**
     * @dev Token owner can use this function to release their fund after the stake period
     */
    function getReward() external {
        require(
            stakedBalances[msg.sender].stakeTimestamp < block.timestamp,
            "CYT staker: stake duration not passed"
        );
        uint256 _amount = releasedAmount(msg.sender);
        require(_amount > 0, "CYT staker: insufficient balance");

        //subBalance(msg.sender, _amount);
        emit getRewards(msg.sender, _amount);
        IERC20(token).transfer(msg.sender, _amount);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Cannot withdraw 0");
        emit Withdrawn(msg.sender, amount);
        stakedBalances[msg.sender].stakedAmount = stakedBalances[msg.sender].stakedAmount.sub(amount);
        totalstaked = totalstaked.sub(amount);
        IERC20(token).transfer(msg.sender, amount);
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
        uint256 stakedAmount = stakedBalances[_sender].stakedAmount;
        uint256 restakedAmount = restakedBalances[_id].stakedAmount;
        if(stakedAmount == 0){
        _id = 0;
        ERC20(token).transferFrom(msg.sender, address(this), _amount);
        stakedBalances[_sender].stakedAmount = _amount*k/100;
        stakedBalances[_sender].stakeTimestamp = block.timestamp.add(
            _stakePeriod
        );
        totalstaked = totalstaked.add(_amount*k/100);
        }

        require(restakedAmount == 0, "the id has been used!");

        if(stakedAmount > 0){
        ERC20(token).transferFrom(msg.sender, address(this), _amount);
        restakedBalances[_id].stakedAmount = _amount*k/100;
        restakedBalances[_id].stakeTimestamp = block.timestamp.add(
            _stakePeriod
        );
        totalstaked = totalstaked.add(_amount*k/100);
        }

    }

    /**
     * @notice Query released amount for the beneficient address
     * @param _beneficient Address of the beneficient
     */
    function releasedAmount(address _beneficient)
        public
        view
        returns (uint256 amounts)
    {
        uint256 _now = block.timestamp;
        Staker memory staker = stakedBalances[_beneficient];
        if (staker.stakeTimestamp == 0 || _now < staker.stakeTimestamp) {
            return 0;
        }
        //uint256 delta = _now.sub(staker.stakeTimestamp);
        //uint256 batches = delta.div(BATCH_PERIOD) + 1; // starting from 1
        //if (batches >= staker.releaseBatches) {
            //return (staker.stakedAmount - staker.getRewardedAmount);
        //}
        //return
            //((staker.stakedAmount * batches) /
            //staker.releaseBatches -
            //staker.getRewardedAmount);
        if ( staker.stakeTimestamp < _now) {
            return staker.stakedAmount;
        }
    }
    
    function subBalance(address _sender, uint256 _amount) private {
        stakedBalances[_sender].getRewardedAmount = stakedBalances[_sender]
            .getRewardedAmount
            .add(_amount);
        if (
            stakedBalances[_sender].stakedAmount <=
            stakedBalances[_sender].getRewardedAmount
        ) {
            delete stakedBalances[_sender]; // clean up storage for stakeTimestamp
        }
        totalstaked = totalstaked - _amount;
    }

    
}
