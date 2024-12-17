import { ethers } from 'hardhat';
import { expect } from 'chai';
import { Contract } from 'hardhat/internal/hardhat-network/stack-traces/model';
import ProductTokenAbi from './TestProductABI.json';
import ProductStakingAbiFile from '../artifacts/contracts/ProductStaking.sol/ProductStaking.json';
import { time } from '@nomicfoundation/hardhat-network-helpers';

const { constants, expectRevert } = require('@openzeppelin/test-helpers');

describe('Product Staking Platform Test', function () {
  let productStakingInstance: any;
  let productToken: any;
  let erc20Contract: any;
  let erc1155Contract: any;
  let owner: any;
  let user: any;
  let ProductStakingAbi = ProductStakingAbiFile.abi;

  beforeEach('Deploy Contracts', async function () {
    [owner, user] = await ethers.getSigners();

    const ProductTokenContract = await ethers.getContractFactory('TestProduct');
    productToken = await ProductTokenContract.deploy(
      'https://apricot-geographical-jaguar-420.mypinata.cloud/ipfs/Qmdp97dmYPJrzh4CCQSWAQM8TPzTeemgNsZJj1PTb6ZyLV'
    );

    const productStakingInstanceContract = await ethers.getContractFactory(
      'ProductStakingInstance'
    );
    productStakingInstance = await productStakingInstanceContract.deploy(
      await productToken.getAddress()
    );

    const erc20ContractInstance = await ethers.getContractFactory('TestERC20');
    erc20Contract = await erc20ContractInstance.deploy(
      'SpaceCredit',
      'SPC',
      18,
      100000
    );

    const erc1155ContractInstance = await ethers.getContractFactory(
      'TestERC1155'
    );
    erc1155Contract = await erc1155ContractInstance.deploy();
  });

  it('contracts must be deployed', async function () {
    console.log(await productToken.getAddress());
    console.log(await productStakingInstance.getAddress());
    console.log(await erc1155Contract.getAddress());
    console.log(await erc20Contract.getAddress());
  });

  describe('createStakingInstance function testing', function () {
    let ProductTokens: any;
    let ProductTokens_revert: any;
    let RewardTokens: any;

    beforeEach(
      'Initialize the Product tokens and Reward tokens',
      async function () {
        ProductTokens_revert = [
          {
            productAddress: await productToken.getAddress(),
            productId: 1,
            ratio: 3,
            consumable: true,
          },
          {
            productAddress: await productToken.getAddress(),
            productId: 2,
            ratio: 3,
            consumable: false,
          },
          {
            productAddress: await productToken.getAddress(),
            productId: 3,
            ratio: 3,
            consumable: false,
          },
          {
            productAddress: await productToken.getAddress(),
            productId: 4,
            ratio: 3,
            consumable: true,
          },
          {
            productAddress: await productToken.getAddress(),
            productId: 5,
            ratio: 3,
            consumable: true,
          },
        ];

        ProductTokens = [
          {
            productAddress: await productToken.getAddress(),
            productId: 1,
            ratio: 3,
            consumable: false,
          },
          {
            productAddress: await productToken.getAddress(),
            productId: 2,
            ratio: 3,
            consumable: true,
          },
        ];

        RewardTokens = [
          {
            tokenAddress: await erc20Contract.getAddress(),
            tokenId: 0,
            ratio: 3,
            isERC1155: false,
          },
          {
            tokenAddress: await erc20Contract.getAddress(),
            tokenId: 0,
            ratio: 4,
            isERC1155: false,
          },
        ];
      }
    );

    it("'Product token count exceeded' error must be occured", async function () {
      await expect(
        productStakingInstance.createStakingInstance(
          ProductTokens_revert,
          RewardTokens,
          5
        )
      ).to.be.revertedWith('Product token count exceeded');
    });

    it('Product staking instance must be created', async function () {
      await erc20Contract.approve(
        await productStakingInstance.getAddress(),
        await ethers.parseEther('1000')
      );
      await erc20Contract.mint(await ethers.parseEther('1000'));

      // console.log(
      //   'Owner balance',
      //   await erc20Contract.balanceOf(await owner.getAddress())
      // );

      expect(
        await productStakingInstance.createStakingInstance(
          ProductTokens,
          RewardTokens,
          5
        )
      ).to.not.be.reverted;
    });

    // @dev Test other functions after createStaking Instace

    describe('Testing after createStakingInstance suceed', function () {
      beforeEach(
        'execution of createStakingInstance function',
        async function () {
          await erc20Contract.approve(
            await productStakingInstance.getAddress(),
            await ethers.parseEther('1000')
          );
          await erc20Contract.mint(await ethers.parseEther('1000'));

          await productStakingInstance.createStakingInstance(
            ProductTokens,
            RewardTokens,
            50
          );
        }
      );

      it('Product staking contract must have reward tokens', async function () {
        const stakingInstance = await productStakingInstance.getStakingInfo(1);
        const stakingContractAddress = stakingInstance.instanceAddress;
      });

      it('currentInstanceId must be 1', async function () {
        expect(await productStakingInstance.currentInstanceId()).to.equal(1);
      });

      it('instanceIdCreator must be current owner', async function () {
        expect(await productStakingInstance.instanceIdCreator(1)).to.equal(
          await owner.getAddress()
        );
      });

      describe('Test Staking function on ProductStaking contract', function () {
        let stakingContractAddress: any;
        let stakingInstance: any;
        let stakingContractInstance: any;
        beforeEach(
          'get product staking instance contract address and mint Product token to owner',
          async function () {
            stakingInstance = await productStakingInstance.getStakingInfo(1);
            stakingContractAddress = stakingInstance.instanceAddress;

            stakingContractInstance = new ethers.Contract(
              stakingContractAddress,
              ProductStakingAbi,
              owner
            );

            await productToken.createProduct(
              await owner.getAddress(),
              1,
              'https://apricot-geographical-jaguar-420.mypinata.cloud/ipfs/Qmdp97dmYPJrzh4CCQSWAQM8TPzTeemgNsZJj1PTb6ZyLV'
            );
            await productToken.mint(await owner.getAddress(), 1, 100000, '0x');

            await productToken.createProduct(
              await owner.getAddress(),
              2,
              'https://apricot-geographical-jaguar-420.mypinata.cloud/ipfs/Qmdp97dmYPJrzh4CCQSWAQM8TPzTeemgNsZJj1PTb6ZyLV'
            );
            await productToken.mint(await owner.getAddress(), 2, 100000, '0x');

            await erc20Contract.mint(await ethers.parseEther('1000'));
          }
        );
        it('should return the staking instance information', async function () {
          expect(await stakingInstance.instanceAddress).be.equal(
            stakingContractAddress
          );
        });

        it('should return the minted product token ids', async function () {
          expect((await productToken.getProductIDs())[1]).to.equal(2);
        });

        it('product token transfer must be approved', async function () {
          await productToken.setApprovalForAll(
            await stakingContractInstance.getAddress(),
            true
          );

          expect(
            await productToken.isApprovedForAll(
              await owner.getAddress(),
              await stakingContractInstance.getAddress()
            )
          ).to.be.true;
        });

        it('staking must be successed', async function () {
          stakingContractInstance = new ethers.Contract(
            stakingContractAddress,
            ProductStakingAbi,
            owner
          );

          await productToken.setApprovalForAll(
            await stakingContractInstance.getAddress(),
            true
          );

          expect(await stakingContractInstance.staking(3)).to.be.reverted;
        });

        it('check all values after staking', async function () {
          stakingContractInstance = new ethers.Contract(
            stakingContractAddress,
            ProductStakingAbi,
            owner
          );

          await productToken.setApprovalForAll(
            await stakingContractInstance.getAddress(),
            true
          );

          const timestamp: any = (await ethers.provider.getBlock('latest'))
            ?.timestamp;
          // console.log(timestamp);

          await stakingContractInstance.staking(3);
          const newTimeStamp = Number(
            await stakingContractInstance.devGetStakingEndTime()
          );

          expect(
            Number(Math.floor((newTimeStamp - timestamp) / (3600 * 24)))
          ).to.equal(16);
        });

        it('should be return the instance ids which are one staker staked', async function () {
          stakingContractInstance = new ethers.Contract(
            stakingContractAddress,
            ProductStakingAbi,
            owner
          );

          await productToken.setApprovalForAll(
            await stakingContractInstance.getAddress(),
            true
          );

          await stakingContractInstance.staking(3);
        });

        // @dev Test for Claim function
        describe('Test Claim Function', function () {
          beforeEach('Staking product tokens to platform', async function () {
            stakingContractInstance = new ethers.Contract(
              stakingContractAddress,
              ProductStakingAbi,
              owner
            );

            await productToken.setApprovalForAll(
              await stakingContractInstance.getAddress(),
              true
            );

            await stakingContractInstance.staking(1);
          });

          it('Should be claimed after 3 days', async function () {
            await time.increase(3600 * 24 * 4);
            console.log(
              'Get Periods:',
              await stakingContractInstance.devGetPeriods()
            );
            expect(
              await stakingContractInstance.claim(await owner.getAddress())
            ).to.be.not.reverted;
          });
        });

        describe('Test for withdraw function', async function () {
          beforeEach('Staking product tokens to platform', async function () {
            stakingContractInstance = new ethers.Contract(
              stakingContractAddress,
              ProductStakingAbi,
              owner
            );

            await productToken.setApprovalForAll(
              await stakingContractInstance.getAddress(),
              true
            );

            await stakingContractInstance.staking(1);
          });

          it('should be withdrawed after 3 days', async function () {
            await time.increase(3600 * 24 * 3);
            expect(await stakingContractInstance.withdraw()).to.be.not.reverted;
          });
        });
      });
    });
  });

  describe('>>>Test for exception cases including overtime', function () {
    let ProductTokens: Object;
    let RewardTokens: Object;
    let stakingContractAddress: string;
    let stakingContractInstance: any;

    beforeEach(
      'Create Staking and Staking first Product Tokens',
      async function () {
        ProductTokens = [
          {
            productAddress: await productToken.getAddress(),
            productId: 1,
            ratio: 3,
            consumable: false,
          },
          {
            productAddress: await productToken.getAddress(),
            productId: 2,
            ratio: 3,
            consumable: false,
          },
        ];

        RewardTokens = [
          {
            tokenAddress: await erc20Contract.getAddress(),
            tokenId: 0,
            ratio: 3,
            isERC1155: false,
          },
          {
            tokenAddress: await erc20Contract.getAddress(),
            tokenId: 0,
            ratio: 4,
            isERC1155: false,
          },
        ];

        await erc20Contract.approve(
          await productStakingInstance.getAddress(),
          ethers.parseEther('1000')
        );

        await erc20Contract.mint(await ethers.parseEther('1000'));

        await erc20Contract
          .connect(user)
          .approve(
            await productStakingInstance.getAddress(),
            ethers.parseEther('1000')
          );

        await erc20Contract.connect(user).mint(ethers.parseEther('1000'));

        await productToken.createProduct(
          await owner.getAddress(),
          1,
          'https://apricot-geographical-jaguar-420.mypinata.cloud/ipfs/Qmdp97dmYPJrzh4CCQSWAQM8TPzTeemgNsZJj1PTb6ZyLV'
        );
        await productToken.mint(await owner.getAddress(), 1, 100000, '0x');

        await productToken.mint(await user.getAddress(), 1, 100000, '0x');

        await productToken.createProduct(
          await owner.getAddress(),
          2,
          'https://apricot-geographical-jaguar-420.mypinata.cloud/ipfs/Qmdp97dmYPJrzh4CCQSWAQM8TPzTeemgNsZJj1PTb6ZyLV'
        );
        await productToken.mint(await owner.getAddress(), 2, 100000, '0x');

        await productToken.mint(await user.getAddress(), 2, 100000, '0x');

        await productStakingInstance.createStakingInstance(
          ProductTokens,
          RewardTokens,
          30
        );

        stakingContractAddress = await productStakingInstance.instanceIdAddress(
          await productStakingInstance.currentInstanceId()
        );

        stakingContractInstance = new ethers.Contract(
          stakingContractAddress,
          ProductStakingAbi,
          owner
        );
      }
    );

    it('Test staking after staking period', async function () {
      await productToken.setApprovalForAll(
        await stakingContractInstance.getAddress(),
        true
      );
      await stakingContractInstance.staking(2);

      await time.increase(3600 * 24 * 15);
      await productToken
        .connect(user)
        .setApprovalForAll(await stakingContractInstance.getAddress(), true);
      await expect(
        stakingContractInstance.connect(user).staking(3)
      ).to.be.revertedWith('Staking is invalid');
    });

    it('Test for claim function in exception case', async function () {
      await productToken.setApprovalForAll(
        await stakingContractInstance.getAddress(),
        true
      );
      const oldTimeStamp: any = (await ethers.provider.getBlock('latest'))
        ?.timestamp;
      await stakingContractInstance.staking(3);
      await time.increase(3600 * 24 * 2);

      await productToken
        .connect(user)
        .setApprovalForAll(await stakingContractInstance.getAddress(), true);
      await stakingContractInstance.connect(user).staking(3);
      await time.increase(3600 * 24 * 8);
      await stakingContractInstance.claim(await owner.getAddress());
      await time.increase(3600 * 24 * 10);
      await stakingContractInstance
        .connect(user)
        .claim(await user.getAddress());
    });

    it('Test for withdraw function in exception case', async function () {
      await productToken.setApprovalForAll(
        await stakingContractInstance.getAddress(),
        true
      );
      await stakingContractInstance.staking(3);
      const startTime = (await ethers.provider.getBlock('latest'))?.timestamp;
      const endStakingTime: BigInt =
        await stakingContractInstance.devGetStakingEndTime();
      await time.increase(3600 * 24 * 30);
      await stakingContractInstance.withdraw();
    });

    it('Test for charge reward function', async function () {
      await productToken.setApprovalForAll(
        await stakingContractInstance.getAddress(),
        true
      );
      await stakingContractInstance.staking(3);
      await time.increase(3600 * 24 * 30);

      await erc20Contract.approve(
        await stakingContractInstance.getAddress(),
        await ethers.parseEther('1000')
      );

      // expect(await stakingContractInstance.paused()).to.be.equal(true);
      await stakingContractInstance.chargeReward(10);
      expect(await stakingContractInstance.paused()).to.be.equal(false);
    });
  });
});
