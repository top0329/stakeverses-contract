// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStakingInfo} from "./IStakingInfo.sol";
// import "../ProductStaking.sol";

interface IProductStakingInstance is IStakingInfo {
    function currentInstanceId() external view returns (uint256);
    function instanceIds() external view returns (uint256[] memory);
    function creators() external view returns (address[] memory);
    function instanceIdCreator(uint256 instanceId) external view returns (address);
    function instanceInfo(uint256 instanceId) external view returns (StakingInstance memory);
    function instanceIdAddress(uint256 instanceId) external view returns (address);
    function idStakingStatus(uint256 instanceId) external view returns (bool);
    function instanceIdRewardBaseAmount(uint256 instanceId) external view returns (uint256);
    function isInstancePaused(uint256 instanceId) external view returns (bool);

    function createStakingInstance(
        ProductInfo[] memory productInfos,
        RewardTokenInfo[] memory rewardInfos,
        uint256 rewardBaseAmount
    ) external;

    function chargeReward(uint256 instanceId, uint256 rewardBaseAmount) external;
    function setPauseStatus(uint256 instanceId, bool status) external;
    function getCreators() external view returns (address[] memory);
    function getInstanceIds() external view returns (uint256[] memory);
    function getCreatorInstanceIds(address creator) external view returns (uint256[] memory);
    function getProductTokenArray(uint256 instanceId) external view returns (ProductInfo[] memory);
    function getRewardTokenArray(uint256 instanceId) external view returns (RewardTokenInfo[] memory);
    function devRegisterStaker(address staker, uint256 instanceId) external;
}
