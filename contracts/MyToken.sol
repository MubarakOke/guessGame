// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyToken {
    using SafeMath for uint256;  
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply_;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    
    constructor() {
        totalSupply_ = 1000000;
        name = "MUBARAK";
        symbol = "MBK";
        decimals = 8;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function transfer(address recipient, uint256 amount) public returns(bool){
        require(balances[msg.sender] >= amount, "Insufficient funds");
        updateBalance(amount, msg.sender, recipient);
        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool){
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns(bool){
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        updateBalance(amount, sender, recipient);
        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount);
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function updateBalance(uint256 amount, address debitAccount, address creditAccount) private {
        balances[debitAccount] = balances[debitAccount].sub(amount);
        balances[creditAccount] = balances[creditAccount].add(amount);
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}