// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract TestProduct is ERC1155 {

    address public factory; // Factory contract address
    string public baseURI; // URI for Product contract
    uint256 public totalMintedProductToken; // Total Minted Product Token
    uint256[] private _productIDs; // Array of created product ids

    mapping(uint256 => bool) public isValidProductID; // key: Product ID, value: true or false, default: false
    mapping(uint256 => address) public productIDCreators; // key: Product ID, value: Creator
    mapping(uint256 => uint256) public productIDMintedAmount; // key: Product ID, value: minted amount
    mapping(uint256 => string) public productIdUri;

    event ProductCreated(uint256 indexed tokenId, address creator, uint256 indexed blueprintId);
    event ProductMinted(
        address indexed to, uint256 indexed id, uint256 amount, uint256 mintedAmountOfId, uint256 totalMintedAmount
    );
    event ProductBurned(address indexed to, uint256 indexed id, uint256 amount, uint256 mintedAmountOfId, uint256 totalMintedAmount);
    event ProductTransferred(address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    modifier onlyFactory() {
        _checkOwner();
        _;
    }

    constructor(string memory _uri) ERC1155(_uri) {
        factory = msg.sender;
        baseURI = _uri;
        _setURI(_uri); // set base URI
    }

    // Create a new Product
    function createProduct(
        address creator, uint256 blueprintId, string memory blueprintUri
    )
        external
        onlyFactory
        returns (uint256)
    { // create new Product token
        require(creator != address(0), "Invalid creator address"); // Check zero address

        uint256 newTokenID = blueprintId; // create new Product ID
        productIdUri[newTokenID] = blueprintUri;
        isValidProductID[newTokenID] = true; // Set newTokenID to valid Product ID
        productIDCreators[newTokenID] = creator; // Set creator of newTokenID
        _productIDs.push(newTokenID); // Add newTokenID to Product ID array

        emit ProductCreated(newTokenID, creator, blueprintId);
        return newTokenID;
    }

    // Mint Product
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyFactory {
        require(to != address(0), "Invalid Receiver address");
        require(isValidProductID[id], "Invalid Product ID");
        require(amount > 0, "Invalid Product Mint amount");

        _mint(to, id, amount, data); // Mint Product NFT
        totalMintedProductToken += amount;
        productIDMintedAmount[id] += amount;

        emit ProductMinted(to, id, amount, productIDMintedAmount[id], totalMintedProductToken);
    }

    // Burn Product NFT
    function burn(address to, uint256 id, uint256 amount) external onlyFactory {
        require(to != address(0), "Invalid account address");
        require(isValidProductID[id], "Invalid Product ID");
        require(amount > 0, "Invalid Product Burn amount");
        require(balanceOf(to, id) >= amount, "Exceeds Account Product ID amount");

        _burn(to, id, amount); // Burn Product NFT

        totalMintedProductToken -= amount;
        productIDMintedAmount[id] -= amount;

        emit ProductBurned(to, id, amount, productIDMintedAmount[id], totalMintedProductToken);
    }

    function productTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid receiver address");
        require(isValidProductID[id], "Invalid Product ID");
        require(amount > 0, "Invalid Product amount");
        require(balanceOf(from, id) >= amount, "Exceeds Account Product ID amount");

        safeTransferFrom(from, to, id, amount, data);
        emit ProductTransferred(from, to, id, amount);
    }

    function getProductIDs() external view returns (uint256[] memory) {
        return _productIDs;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(productIdUri[tokenId]));
    }

    function _checkOwner() internal view virtual {
        require(msg.sender == factory, "Only Factory can call this function");
    }
}