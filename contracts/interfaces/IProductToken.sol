// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IProduct  {
    function factory() external view returns (address);
    function baseURI() external view returns (string memory);
    function totalMintedProductToken() external view returns (uint256);
    function isValidProductID(uint256 id) external view returns (bool);
    function productIDCreators(uint256 id) external view returns (address);
    function productIDMintedAmount(uint256 id) external view returns (uint256);
    function productIdUri(uint256 id) external view returns (string memory);

    event ProductCreated(uint256 indexed tokenId, address creator, uint256 indexed blueprintId);
    event ProductMinted(address indexed to, uint256 indexed id, uint256 amount, uint256 mintedAmountOfId, uint256 totalMintedAmount);
    event ProductBurned(address indexed to, uint256 indexed id, uint256 amount, uint256 mintedAmountOfId, uint256 totalMintedAmount);
    event ProductTransferred(address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    function createProduct(address creator, uint256 blueprintId, string memory blueprintUri) external returns (uint256);
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address to, uint256 id, uint256 amount) external;
    function productTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function getProductIDs() external view returns (uint256[] memory);
    function uri(uint256 tokenId) external view returns (string memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns(bool);
}
