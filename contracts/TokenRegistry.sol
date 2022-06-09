// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract TokenRegistry {

    address public coordinator;
    address public rollup;

    mapping(address => bool) public pendingTokens;
    mapping(uint256 => address) public registeredTokens;
    uint256 public numTokens;

    modifier fromRollup(){
        assert(msg.sender == rollup);
        _;
    }

    modifier onlyCoordinator(){
        assert(msg.sender == coordinator);
        _;
    }

    constructor(address _coordinator)  {
        coordinator = _coordinator;
        numTokens = 1;  // Rollup starts supporting ETH by default
    }

    function setRollup(address _rollup) external onlyCoordinator {
        rollup = _rollup;
    }

    function registerToken(address tokenContract) external {
        require(pendingTokens[tokenContract] == false, "Token already registered");
        pendingTokens[tokenContract] = true;
    }

    function approveToken(address tokenContract) public fromRollup {
        require(pendingTokens[tokenContract], "Token was not registered");
        numTokens++;
        registeredTokens[numTokens] = tokenContract; 
    }

}