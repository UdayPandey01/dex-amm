//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WETH {
    error InsufficientBalance(uint256 available, uint256 required);
    error UseDeposit();

    string public constant NAME = "Wrapped Ether";
    string public constant SYMBOL = "WETH";
    uint8 public constant DECIMALS = 18;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawal(address indexed from, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowances;

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        revert UseDeposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        if(amount > balanceOf[msg.sender]) {
            revert InsufficientBalance({
                available: balanceOf[msg.sender],
                required: amount
            });
        }

        balanceOf[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "WETH: withdraw failed");
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    } 

    function transfer(address to, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if(amount > balanceOf[from]) {
            revert InsufficientBalance({
                available: balanceOf[from],
                required: amount
            });
        }

        if(from != msg.sender) {
            uint256 allowed = allowances[from][msg.sender];
            if(allowed != type(uint256).max){
                if(amount > allowed) {
                    revert InsufficientBalance({
                        available: allowed,
                        required: amount
                    });
                }
                allowances[from][msg.sender] = allowed - amount;
            }
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
}