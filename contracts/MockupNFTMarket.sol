// As specified by Gilbert's advised psuedo-interface

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract MockupNFTMarket {
  mapping (uint => address) tokens; // just for testing 
  uint price = 0.2 ether;

  function getPrice(uint _tokenId) external view returns (uint) {
    console.log(_tokenId);
    return price;
  }
  function purchase(uint _tokenId) external payable {
    tokens[_tokenId] = msg.sender;
  }
}