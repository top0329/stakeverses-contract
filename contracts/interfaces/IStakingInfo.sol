// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingInfo {
  struct StakingTokenInfo {
    address productAddress;
    uint256 productId;
    uint256 ratio;
    bool consumable;
  }

  struct RewardTokenInfo {
    address tokenAddress;
    uint256 tokenId;
    uint256 ratio;
    bool isERC1155;
  }

  struct StakingInstance {
    address creator;
    address instanceAddress;
    StakingTokenInfo[] stakingTokenInfo;
    RewardTokenInfo[] rewardTokenInfo;
  }

  struct StakingUser {
    uint256 totalAmount;
    uint256 startTime;
    uint256 lastRewardDate;
    uint256 lastStakingPeriod;
    uint256 withdrawnAmount;
    bool withdrawed;
  }
}