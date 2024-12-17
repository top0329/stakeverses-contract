// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TestERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10 ** uint256(_decimals));
    }

    function mint(uint256 amount) external {
        require(amount < totalSupply, "Amount must be less than totalSupply");
        balanceOf[msg.sender] += amount;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[msg.sender] >= _value, "ERC20: insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[_from] >= _value, "ERC20: insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "ERC20: insufficient allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
