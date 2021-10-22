// As specified by Gilbert's advised psuedo-interface

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract MockupNFTMarket {
    mapping(uint256 => address) tokens; // just for testing
    uint256 price = 0.2 ether;

    function getPrice(uint256 _tokenId) external view returns (uint256) {
        console.log(_tokenId); // for the unused variable warning
        return price;
    }

    function purchase(uint256 _tokenId) external payable {
        tokens[_tokenId] = msg.sender;
    }
}
