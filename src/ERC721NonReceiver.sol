// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ERC721NonReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return 0xaabbccdd;
    }

    function onERC721BatchReceived(
        address,
        address,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4) {
        return 0xaabbccdd;
    }
}
