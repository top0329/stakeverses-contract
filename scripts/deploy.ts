import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('Deploying contracts with the account:', deployer.address);

  const token = await ethers.getContractFactory('ProductStakingInstance');
  const factory = await token.deploy(
    '0xaaF0e2a505F074d8080B834c33a9ff44DD7946F1', //product token address on sepolia network
  );
  console.log('Token address:', await factory.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
