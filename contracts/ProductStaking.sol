// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStakingInfo} from "./interfaces/IStakingInfo.sol";
import {IProductStakingInstance} from './interfaces/IProductStakingInstance.sol';
import {IProduct} from "./interfaces/IProductToken.sol";
import "./StkToken.sol";
import "hardhat/console.sol";

contract ProductStaking is IStakingInfo {
  address public creator;
  address createInstanceContractAddress;
  uint256 public rewardBaseAmount;
  uint256 public totalStakingBaseAmount;
  uint256 public instanceId;
  bool public paused;
  bool public isIncludingConsumable;
  address[] public stakers;
  StakingTokenInfo[] public stakingTokens;
  RewardTokenInfo[] public rewardTokens;

  uint256 internal _stakingEndTime;
  uint256 internal _pausingPeriod;

  // @dev Set the time unit is 10 min for testing
  // uint256 internal unitTime = 10 minutes;

  uint256 internal unitTime = 1 days;
  // StakingInstance internal _instance;
  IProduct internal _productToken;

  mapping(address => StakingUser) public stakingUser;

  event Staking(address indexed staker, uint256 amount, uint256 stakingDate, uint256 indexed instanceId);
  event MintStkToken(address indexed staker, address indexed stkTokenAddress, uint256 amount, uint256 stakingDate);

  constructor(
    StakingTokenInfo[] memory stakingTokenInfos,
    RewardTokenInfo[] memory rewardInfos,
    uint256 rewardBaseAmountValue,
    address productTokenAddress,
    address _creator,
    uint256 _instanceId
  ) {

    rewardBaseAmount = rewardBaseAmountValue;
    for(uint i = 0; i < stakingTokenInfos.length; i++) {
      if(stakingTokenInfos[i].consumable == true) {
        isIncludingConsumable = true;
      }
      stakingTokens.push(stakingTokenInfos[i]);
    }
    for(uint i = 0; i < rewardInfos.length; i++) {
      rewardTokens.push(rewardInfos[i]);
    }

    paused = false;
    _pausingPeriod = 0;
    _productToken = IProduct(productTokenAddress);
    creator = _creator;
    instanceId = _instanceId;
    _stakingEndTime = block.timestamp;
    createInstanceContractAddress = msg.sender;
  }

  function staking(uint256 stakingBaseAmount) external {
    require(validateStaking(stakingBaseAmount), "Staking is invalid");

    require(paused == false, "Staking is paused");
    StakingUser storage staker = stakingUser[msg.sender];
    require(staker.totalAmount == 0, "Already Staked");
    staker.totalAmount = stakingBaseAmount;
    staker.startTime = block.timestamp;
    staker.lastRewardDate = block.timestamp;
    staker.withdrawnAmount = 0;
    staker.withdrawed = false;
    staker.lastStakingPeriod = 0;
    totalStakingBaseAmount += stakingBaseAmount;
    for(uint i = 0; i < stakingTokens.length; i++){
      _productToken.productTransferFrom(
        msg.sender,
        address(this),
        stakingTokens[i].productId,
        stakingTokens[i].ratio * stakingBaseAmount,
        "0x"
      );
    }

    stakers.push(msg.sender);

    _calculateStakingEndtime();
    IProductStakingInstance(createInstanceContractAddress).devRegisterStaker(msg.sender, instanceId);

    emit Staking(msg.sender, stakingBaseAmount, block.timestamp, instanceId);
  }

  function claim(address receiver) public returns (bool) {
    if(_getRemainingRewardTokens() == 0) {
      paused = true;
    }

    StakingUser memory staker = stakingUser[receiver];
    (uint256 stakingPeriod, uint256 claimPeriod) = _getPeriods(receiver);

    uint256[] memory claimableRewards = _claimableReward(staker, claimPeriod);

    require(
      block.timestamp - staker.lastRewardDate > unitTime,
      "Invaild Claim time"
    );

    for(uint i = 0; i < claimableRewards.length; i++) {
      // console.log("claimable tokens:", claimableRewards[i]);
      if(rewardTokens[i].isERC1155 == true) {
        IERC1155(rewardTokens[i].tokenAddress).setApprovalForAll(receiver, true); // Approve ERC1155 Token
        IERC1155(rewardTokens[i].tokenAddress).safeTransferFrom(address(this), receiver, rewardTokens[i].tokenId, claimableRewards[i], "");
      } else {
        IERC20(rewardTokens[i].tokenAddress).transfer(receiver, claimableRewards[i] * (10 ** IERC20(rewardTokens[i].tokenAddress).decimals()));
      }
    }
    staker.lastStakingPeriod = stakingPeriod;
    staker.lastRewardDate = block.timestamp;
    staker.withdrawnAmount = claimPeriod;

    _calculateStakingEndtime();
    return true;
  }

  function withdraw() external {
    if(_getRemainingRewardTokens() == 0) {
      paused = true;
    }
    StakingUser memory staker = stakingUser[msg.sender];
    require(claim(msg.sender), "Claim is failed");

    (uint256 stakingPeriod, ) = _getPeriods(msg.sender);
    _productToken.setApprovalForAll(creator, true);
    _productToken.setApprovalForAll(msg.sender, true);


    for(uint i = 0; i < stakingTokens.length; i++) {
      if(stakingTokens[i].consumable == true) {
        // console.log("Staker Total Amount:", staker.totalAmount);
        // console.log("stakingPeriod / unitTime", stakingPeriod / unitTime);
        uint256 _sendingAmount = stakingTokens[i].ratio * (stakingPeriod / unitTime);
        uint256 _remainingAmount = stakingTokens[i].ratio * (staker.totalAmount - stakingPeriod / unitTime);
        _productToken.productTransferFrom(address(this), creator, stakingTokens[i].productId, _sendingAmount, "0x");
        if (_remainingAmount != 0) {
          _productToken.productTransferFrom(address(this), msg.sender, stakingTokens[i].productId, _remainingAmount, "0x");
        }
      } else {
        uint256 _sendingAmount = stakingTokens[i].ratio * staker.totalAmount;
        _productToken.productTransferFrom(address(this), creator, stakingTokens[i].productId, _sendingAmount, "0x");
      }
    }
    staker.withdrawed = true;
    totalStakingBaseAmount -= staker.totalAmount;
    staker.withdrawnAmount = stakingPeriod;
    staker.totalAmount = 0;
    staker.lastRewardDate = block.timestamp;
    _calculateStakingEndtime();
  }

  function chargeReward(uint256 rewardBaseAmountValue) external {
    uint256 oldEndTime = _calculateStakingEndtime();
    rewardBaseAmount += rewardBaseAmountValue;
    uint256 newEndTime = _calculateStakingEndtime();
    if(oldEndTime < block.timestamp) {
      _pausingPeriod = _pausingPeriod + (newEndTime - oldEndTime);
      paused = false;
    }

    for(uint i = 0; i < rewardTokens.length; i++) {
      if(rewardTokens[i].isERC1155 == true) {
        IERC1155(rewardTokens[i].tokenAddress).safeTransferFrom(msg.sender, address(this), rewardTokens[i].tokenId, rewardTokens[i].ratio * rewardBaseAmountValue, "");
      } else {
        IERC20(rewardTokens[i].tokenAddress).transferFrom(msg.sender, address(this), rewardTokens[i].ratio * rewardBaseAmountValue);
      }
    }
  }

  function getStakers() external view returns(address[] memory) {
    return stakers;
  }

  function getClaimableReward(address receiver) external view returns(uint256[] memory) {
    StakingUser memory staker = stakingUser[receiver];
    (uint256 stakingPeriod, uint256 claimPeriod) = _getPeriods(receiver);
    console.log("claimPeriod:", claimPeriod);
    require(claimPeriod > 0, "Claim Period must not be 0");
    uint256[] memory claimableRewards = _claimableReward(staker, claimPeriod);
    return claimableRewards;
  }

  function getInstanceId() external view returns(uint256) {
    return instanceId;
  }

  function _claimableReward(StakingUser memory staker, uint256 elapsedDate) internal view returns (uint256[] memory) {
    uint256[] memory rewardTokenAmount = new uint256[](rewardTokens.length);
    for(uint8 i = 0; i < rewardTokens.length; i++) {
      uint256 _tempAmount = rewardTokens[i].ratio * elapsedDate * staker.totalAmount / unitTime;
      rewardTokenAmount[i] = _tempAmount;
    }
    return rewardTokenAmount;
  }

  function _calculateStakingEndtime() internal returns(uint256) {
    uint256 remainingTokens = _getRemainingRewardTokens();
    if(paused == true) {
      _stakingEndTime = _stakingEndTime + remainingTokens * unitTime;
    } else {
      if(totalStakingBaseAmount == 0) {
        _stakingEndTime = block.timestamp;
      } else {
        _stakingEndTime = block.timestamp + (remainingTokens / totalStakingBaseAmount) * unitTime;
      }
    }

    return _stakingEndTime;
  }

  // @return UnixTimeZone
  function _getPeriods(address _staker) internal view returns(uint256, uint256) {
    StakingUser memory staker = stakingUser[_staker];
    uint256 stakingPeriod; // Staking Period is period from first to current point
    uint256 claimPeriod; // claimPeriod is the period from last claimed date to current point

    // Consumable Token is only. When consumable token run out, the staking must be stopped.
    uint256 stakerLimitPeriod = staker.totalAmount * unitTime;
    // console.log("Staker Limit Period:", stakerLimitPeriod);
    if(block.timestamp > _stakingEndTime) {
      stakingPeriod = _stakingEndTime - staker.startTime - _pausingPeriod;
      claimPeriod = stakingPeriod - staker.lastStakingPeriod;
    } else {
      stakingPeriod = block.timestamp - staker.startTime - _pausingPeriod;
      claimPeriod = stakingPeriod - staker.lastStakingPeriod;
    }

    if((isIncludingConsumable == true) && (stakingPeriod > stakerLimitPeriod)) {
      stakingPeriod = stakerLimitPeriod;
      claimPeriod = stakingPeriod - staker.lastStakingPeriod;
    }

    return (stakingPeriod, claimPeriod);
  }

  function _getRemainingRewardTokens() internal view returns(uint256){
    uint256 consumedRewardToken = 0;
    for(uint i = 0; i < stakers.length; i++) {
      StakingUser memory staker = stakingUser[stakers[i]];
      if(staker.withdrawed == true) {
        consumedRewardToken += staker.withdrawnAmount;
      } else {
        uint256 elapsedTime = ((block.timestamp) - staker.startTime - _pausingPeriod) / unitTime;
        consumedRewardToken += staker.totalAmount * elapsedTime; // The unit is 1 per day, so elapsed time is same with elapesed reward token amount
      }
    }

    // console.log("Consumable reward token: ", consumedRewardToken);

    if(consumedRewardToken > rewardBaseAmount) {
      return 0;
    } else {
      return rewardBaseAmount - consumedRewardToken;
    }
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  )
    public
    pure
    returns (bytes4)
  {
    return this.onERC1155Received.selector;
  }

  // @dev Dev Mode
  function calculateStakingEndTime() external {
    _calculateStakingEndtime();
  }

  function devGetStakingEndTime() external view returns(uint256) {
    return _stakingEndTime;
  }

  function devGetPeriods() external view returns(uint256, uint256) {
    return _getPeriods(msg.sender);
  }

  function devGetRemainingTokens() external view returns(uint256) {
    uint256 remainingToken = _getRemainingRewardTokens();
    return remainingToken;
  }

  function validateStaking(uint256 stakingBaseAmount) internal view returns(bool) {
    uint256 remainingAmount = _getRemainingRewardTokens();
    if(remainingAmount / (totalStakingBaseAmount + stakingBaseAmount) < 1) {
      return false;
    }
    return true;
  }
}