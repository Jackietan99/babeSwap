// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libs/Erc20.sol";

contract StakingReward {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    // Duration of rewards to be paid out(in seconds)
    uint public duration;

    // Timestamp of when the rewards finish
    uint public finishAt;

    // minimum of last updated time and reward finish time
    uint public updatedAt;

    // Reward to be paid out per second;
    uint public rewardRate;

    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;

    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;

    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    //Total Stakeed
    uint public totalSupply;

    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earn(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function _mint(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _mint(finishAt, block.timestamp);
    }

    function setRewardDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt)) /
            totalSupply;
    }

    function earn(address _account) public view returns (uint) {
        return
            (balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) *
            1e18 +
            rewards[_account];
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount > 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount > 0 ");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        require(rewards[msg.sender] > 0, "0 rewards");
        rewardsToken.transfer(msg.sender, rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    function notifyRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }
}
