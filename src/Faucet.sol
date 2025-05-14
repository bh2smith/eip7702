pragma solidity ^0.8.28;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Faucet is Ownable {
    uint256 public ethDripAmount = 0.001 ether;
    uint256 public tokenDripAmount = 1 ether;
    uint256 public waitTime = 30 minutes;

    error TokenInsufficientBalance();
    error EthInsufficientBalance();

    mapping(address => uint256) lastAccessTime;

    constructor() Ownable(msg.sender) {}

    function dripToken(address tokenAddress) public {
        require(allowedToWithdraw(msg.sender));
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance < tokenDripAmount) {
            revert TokenInsufficientBalance();
        }
        token.transfer(msg.sender, tokenDripAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function dripEth() public {
        require(allowedToWithdraw(msg.sender));
        if (address(this).balance < ethDripAmount) {
            revert EthInsufficientBalance();
        }
        payable(msg.sender).transfer(ethDripAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if (lastAccessTime[_address] == 0) {
            return true;
        } else if (block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }

    function setEtherDrip(uint256 amount) public onlyOwner {
        ethDripAmount = amount;
    }

    function setTokenDrip(uint256 amount) public onlyOwner {
        tokenDripAmount = amount;
    }

    function setWaitTime(uint256 time) public onlyOwner {
        waitTime = time;
    }

    receive() external payable {}
}
