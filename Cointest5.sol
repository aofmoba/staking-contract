// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Timestake is Ownable {
    using SafeMath for uint256;
    uint256 public k;
    IERC20 public rewardsToken;
    ERC20 public stakingToken;
    // Release every 30 days after the stake period
    //uint256 public constant BATCH_PERIOD = 24 * 60 * 60 * 30;
    uint256 public constant BATCH_PERIOD = 1;

    event profit(uint256 indexed k);
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
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = ERC20(_stakingToken);
    }
    
    function setk(uint256 _k) external onlyOwner {
        k = _k;
        emit profit(k);
    }
    /**
     * @dev Token owner can use this function to release their fund after the stake period
     */
    function getReward(uint256 _id) external {
        require(
            stakedBalances[msg.sender][_id].stakeTimestamp < block.timestamp,
            "CYT staker: stake duration not passed"
        );
        uint256 _amount = releasedAmount(msg.sender, _id);
        require(_amount > 0, "CYT staker: insufficient balance");
        
        emit getRewards(msg.sender, _amount);
        subBalance(msg.sender, _amount, _id);
        IERC20(rewardsToken).transfer(msg.sender, _amount);
    }

    function withdraw(uint256 amount, uint256 _id) public {
        require(amount > 0, "Cannot withdraw 0");
        emit Withdrawn(msg.sender, amount);
        stakedBalances[msg.sender][_id].stakedAmount = stakedBalances[msg.sender][_id].stakedAmount.sub(amount);
        totalstaked.sub(amount);
        IERC20(rewardsToken).transfer(msg.sender, amount);
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
        uint256 stakedAmount = stakedBalances[_sender][_id].stakedAmount;
        require(_id > 0, "id > 0");
        require(stakedAmount == 0, "the id has been used!");

        ERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
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
        if ( staker.stakeTimestamp < _now) {
            return staker.stakedAmount;
        }
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
