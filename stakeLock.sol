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
    uint256 public constant BATCH_PERIOD = 10;

    event profit(uint256 indexed k);

    struct Staker {
        // release cliff
        uint256 stakeTimestamp;
        // total staked amount per address
        uint256 stakedAmount;
        // number of batches to release total staked amount
        uint256 releaseBatches;
        // persist withdrawed amount up to date
        uint256 withdrawedAmount;
    }

    // staked amount and release time for each address
    mapping(address => Staker) public stakedBalances;
    uint256 public totalstaked;

    event Withdraw(address user, uint256 amount);

    constructor(address _token) {
        token = _token;
    }
    
    function setk(uint256 _k) external {
        k = _k;
        emit profit(k);
    }
    /**
     * @dev Token owner can use this function to release their fund after the stake period
     */
    function withdraw() external {
        require(
            stakedBalances[msg.sender].stakeTimestamp < block.timestamp,
            "CYT staker: stake duration not passed"
        );
        uint256 _amount = k*releasedAmount(msg.sender);
        require(_amount > 0, "CYT staker: insufficient balance");

        subBalance(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
        IERC20(token).transfer(msg.sender, _amount);
    }

    /**
     * @notice Mint Token to this contract, mark the owner and stake period
     * @dev Can only be called by owner
     * @param _sender The beneficient of the token
     * @param _amount Total staked up amount
     * @param _stakePeriod staked period before the first release
     * @param _batches Number of batches to release total amount
     */
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _stakePeriod,
        uint256 _batches
    ) external onlyOwner {
        uint256 stakedAmount = stakedBalances[_sender].stakedAmount;
        require(
            stakedAmount == 0,
            "CYT staker: cannot re-stake a staked address"
        );
        ERC20(token).transferFrom(msg.sender, address(this), _amount);
        stakedBalances[_sender].stakedAmount = _amount;
        stakedBalances[_sender].releaseBatches = _batches;
        stakedBalances[_sender].stakeTimestamp = block.timestamp.add(
            _stakePeriod
        );
        totalstaked = totalstaked.add(_amount);
    }

    /**
     * @notice Query released amount for the beneficient address
     * @param _beneficient Address of the beneficient
     */
    function releasedAmount(address _beneficient)
        public
        view
        returns (uint256)
    {
        uint256 _now = block.timestamp;
        Staker memory staker = stakedBalances[_beneficient];
        if (staker.stakeTimestamp == 0 || _now < staker.stakeTimestamp) {
            return 0;
        }
        uint256 delta = _now.sub(staker.stakeTimestamp);
        uint256 batches = delta.div(BATCH_PERIOD) + 1; // starting from 1
        if (batches >= staker.releaseBatches) {
            return (staker.stakedAmount - staker.withdrawedAmount)/100;
        }
        return
            ((staker.stakedAmount * batches) /
            staker.releaseBatches -
            staker.withdrawedAmount)/100;
    }

    function subBalance(address _sender, uint256 _amount) private {
        stakedBalances[_sender].withdrawedAmount = stakedBalances[_sender]
            .withdrawedAmount
            .add(_amount).mul(100).div(k);
        if (
            stakedBalances[_sender].stakedAmount <=
            stakedBalances[_sender].withdrawedAmount
        ) {
            delete stakedBalances[_sender]; // clean up storage for stakeTimestamp
        }
        totalstaked = totalstaked - _amount*100/k;
    }
}
