// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ERC721ReceiverRevert {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        revert("Revert something");
    }

    function onERC721BatchReceived(
        address,
        address,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4) {
        revert("Revert something");
    }
}
