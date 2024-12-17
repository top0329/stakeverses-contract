// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IStakingInfo} from "./interfaces/IStakingInfo.sol";
import "./ProductStaking.sol";
import "./interfaces/IERC20.sol";
import "hardhat/console.sol";

contract ProductStakingInstance is IStakingInfo{
  uint256 public currentInstanceId; // Current staking instance id
  uint256[] public instanceIds;  // Array of instance ids created
  address[] public creators; // Array of creators
	address internal _productTokenAddress; // Product token address

	// ProductStaking private _productStaking;  // Product staking contract instance

  mapping(uint256 => address) public instanceIdCreator; // Mapping of instance id to creator
	mapping(uint256 => address) public instanceIdAddress; // Mapping of instance id to Product staking contract address
	mapping(uint256 => uint256) public instanceIdRewardBaseAmount; // Mapping of instance id to reward base amount
	mapping(uint256 => bool) public isInstancePaused; // Mapping of instance id to pausing status
	mapping(uint256 => StakingInstance) internal _instanceInfo; // Mapping of instance id to staking instance details
	mapping(uint256 => ProductStaking) internal _instanceIdProductStaking; // Mapping of instance id to ProductStaking contract instance
  mapping(address => uint256[]) internal _creatorInstanceIds; // Mapping of creator to array of instance ids created
	mapping(address => uint256[]) internal _userInstanceIds; // Mapping of user to array of instance ids joined

	event CreateInstance(uint256 indexed instanceId, address indexed creator, address indexed instanceAddress, uint256 creatingTime);

	constructor(address productTokenAddress) {
		currentInstanceId = 0;
		_productTokenAddress = productTokenAddress;
	}

	// @dev Create Staking instance function
	// @desc This function creates the staking instance.
	//       It has Product token, Reward token information, Reward Amount for depositing reward tokens, stkToken name and symbol as parameters
	//       In this function, the necessary datas are stored and instance is created new instance by calling new ProductStaking contract.
	function createStakingInstance(
		StakingTokenInfo[] memory stakingTokenInfos,
		RewardTokenInfo[] memory rewardInfos,
		uint256 rewardBaseAmount
	)
		external
	{
		require(stakingTokenInfos.length <= 4, "Product token count exceeded");
		require(rewardInfos.length <= 4, "Reward token count exceeded");

		for(uint i = 0; i < rewardInfos.length; i++) {
      if(rewardInfos[i].isERC1155 == true) {
        IERC1155(rewardInfos[i].tokenAddress).safeTransferFrom(msg.sender, address(this), rewardInfos[i].tokenId, rewardBaseAmount * rewardInfos[i].ratio, "");
      } else {
        IERC20(rewardInfos[i].tokenAddress).transferFrom(msg.sender, address(this), rewardBaseAmount * rewardInfos[i].ratio * (10 ** IERC20(rewardInfos[i].tokenAddress).decimals()));
      }
    }

		ProductStaking _productStaking = new ProductStaking(
			stakingTokenInfos,
			rewardInfos,
			rewardBaseAmount,
			_productTokenAddress,
			msg.sender,
			currentInstanceId + 1
		);

		currentInstanceId++;
		creators.push(msg.sender);
		_creatorInstanceIds[msg.sender].push(currentInstanceId);
		instanceIdRewardBaseAmount[currentInstanceId] = rewardBaseAmount;
		instanceIds.push(currentInstanceId);
		_instanceIdProductStaking[currentInstanceId] = _productStaking;
		instanceIdCreator[currentInstanceId] = msg.sender;
		StakingInstance storage stakingInstance = _instanceInfo[currentInstanceId];
		stakingInstance.creator = msg.sender;
		stakingInstance.instanceAddress = address(_productStaking);
		instanceIdAddress[currentInstanceId] = address(_productStaking);
		for(uint256 i = 0; i < stakingTokenInfos.length; i++) {
			stakingInstance.stakingTokenInfo.push(stakingTokenInfos[i]);
		}
		for(uint256 i = 0; i < rewardInfos.length; i++) {
			stakingInstance.rewardTokenInfo.push(rewardInfos[i]);
		}

		for(uint i = 0; i < rewardInfos.length; i++) {
      if(rewardInfos[i].isERC1155 == true) {
				IERC1155(rewardInfos[i].tokenAddress).setApprovalForAll(address(_productStaking), true);
        IERC1155(rewardInfos[i].tokenAddress).safeTransferFrom(address(this), address(_productStaking), rewardInfos[i].tokenId, rewardBaseAmount * rewardInfos[i].ratio, "");
      } else {
				IERC20(rewardInfos[i].tokenAddress).transfer(address(_productStaking), rewardBaseAmount * rewardInfos[i].ratio * (10 ** IERC20(rewardInfos[i].tokenAddress).decimals()));
      }
    }

		emit CreateInstance(currentInstanceId, msg.sender, address(_productStaking), block.timestamp);
	}

	function chargeReward(
		uint256 instanceId, // id of staking instance
		uint256 rewardBaseAmount // amount of charge reward
	)
		external
	{
		require(msg.sender == instanceIdCreator[instanceId], "Invalid creator");
		ProductStaking _productStaking = _instanceIdProductStaking[instanceId];
		_productStaking.chargeReward(rewardBaseAmount);
		instanceIdRewardBaseAmount[instanceId] += rewardBaseAmount;
	}

	function getInstancePausingStatus(uint256 instanceId) external view returns (bool) {
		return isInstancePaused[instanceId];
	}

	function getCreators() external view returns(address[] memory) {
		return creators;
	}

	function getInstanceIds() external view returns(uint256[] memory) {
		return instanceIds;
	}

	function getCreatorInstanceIds(address creator) external view returns(uint256[] memory) {
		return _creatorInstanceIds[creator];
	}

	function getProductTokenArray(uint256 instanceId) external view returns(StakingTokenInfo[] memory) {
		return _instanceInfo[instanceId].stakingTokenInfo;
	}

	function getStakingInfo(uint256 instanceId) external view returns(StakingInstance memory) {
		return _instanceInfo[instanceId];
	}

	function getRewardTokenArray(uint256 instanceId) external view returns(RewardTokenInfo[] memory) {
		return _instanceInfo[instanceId].rewardTokenInfo;
	}

	function getProductStakingInstace(uint256 instanceId) external view returns(ProductStaking) {
		return _instanceIdProductStaking[instanceId];
	}

	function _updatePauseStatus(uint256 instanceId, bool status) internal {
		ProductStaking _productStaking = _instanceIdProductStaking[instanceId];
		isInstancePaused[instanceId] = _productStaking.paused();
	}

	//@dev function on development environment

	function devRegisterStaker(address staker, uint256 instanceId) external {
		// console.log("Staker on devRegisterStaker", staker);
		// console.log("Instance Id on devRegisterStaker", instanceId);
		_userInstanceIds[staker].push(instanceId);
	}

	function getInstanceIdsForUser(address staker) external view returns(uint256[] memory) {
		return _userInstanceIds[staker];
	}
}