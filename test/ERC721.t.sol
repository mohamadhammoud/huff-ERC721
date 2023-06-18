// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "../src/ERC721.sol";
import "../src/ERC721Receiver.sol";
import "../src/ERC721NonReceiver.sol";
import "../src/ERC721ReceiverEmpty.sol";
import "../src/ERC721ReceiverRevert.sol";

interface IERC721 {
    function uri(uint256) external view returns (string memory);

    function mint(address, uint) external;

    function balanceOfBatch(
        address[] calldata
    ) external view returns (uint[] memory);

    function safeTransferFrom(
        address,
        address,
        uint,
        bytes memory
    ) external returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] memory,
        bytes memory
    ) external returns (bytes memory);
}

contract ERC721Test is Test {
    YulDeployer public yulDeployer = new YulDeployer();

    ERC721 public solContract;
    ERC721 public yulContract;

    address public owner = 0x0000000000000000000000000000000000fffFfF;
    address public userA = 0x0000000000000000000000000000000000AbC123;
    address public userB = 0x0000000000000000000000000000000000123123;
    address public userC = 0x0000000000000000000000000000000000aBCabc;
    address public receiverContract;
    address public nonReceiverContract;
    address public receiverRevertContract;
    address public receiverEmptyContract;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function setUp() public {
        solContract = new ERC721("https://token.com/");
        yulContract = ERC721(yulDeployer.deployContract("ERC721"));

        solContract.mint(owner, 1);
        yulContract.mint(owner, 1);

        vm.startPrank(owner, msg.sender);
        receiverContract = address(new ERC721Receiver());
        nonReceiverContract = address(new ERC721NonReceiver());
        receiverEmptyContract = address(new ERC721ReceiverEmpty());
        receiverRevertContract = address(new ERC721ReceiverRevert());
    }

    function testUri() public {
        assertEq(solContract.uri(1), yulContract.uri(1), "Failed: mismatch");
    }

    function testBalanceOfOwner() public {
        assertEq(yulContract.balanceOf(owner), 1);
        assertEq(solContract.balanceOf(owner), 1);
    }

    function testBalanceOfWithZeroAddress(uint id) public {
        vm.expectRevert("ERC721: address zero is not a valid owner");
        yulContract.balanceOf(address(0));
        vm.expectRevert("ERC721: address zero is not a valid owner");
        solContract.balanceOf(address(0));
    }

    function testBatchBalance() public {
        address[] memory addresses = new address[](5);
        addresses[0] = 0xB4bbCc562A3D49A384aFf6481377f2a5c19cf1bF;
        addresses[1] = 0x2D1A0Ead2a42E8b2731E8F6169f0041EC38F7c9a;
        addresses[2] = 0xCA16B6d3D34F781c3E504EC16433EC44b4ac49e6;
        addresses[3] = 0x5fd1a905c827Fd2AdDBCa5D5C4d2170Adcc4c969;
        addresses[4] = 0xFbdc16F71155B583698cfE8658925E6ac94cEB6f;

        uint[] memory ids = new uint[](5);
        ids[0] = 32;
        ids[1] = 64;
        ids[2] = 128;
        ids[3] = 256;
        ids[4] = 512;

        yulContract.mint(addresses[0], ids[0]);
        yulContract.mint(addresses[1], ids[1]);
        yulContract.mint(addresses[2], ids[2]);
        yulContract.mint(addresses[3], ids[3]);
        yulContract.mint(addresses[4], ids[4]);

        solContract.mint(addresses[0], ids[0]);
        solContract.mint(addresses[1], ids[1]);
        solContract.mint(addresses[2], ids[2]);
        solContract.mint(addresses[3], ids[3]);
        solContract.mint(addresses[4], ids[4]);

        assertEq(
            yulContract.balanceOfBatch(addresses),
            solContract.balanceOfBatch(addresses)
        );
    }

    function testSetApprovalToSelf(bool approved) public {
        vm.expectRevert("ERC721: setting approval status for self");
        yulContract.setApprovalForAll(owner, approved);
        vm.expectRevert("ERC721: setting approval status for self");
        solContract.setApprovalForAll(owner, approved);
    }

    function testSafeTransferFromToReceiverContract() public {
        yulContract.safeTransferFrom(owner, receiverContract, 1, "");
    }

    function testSafeTransferFromToReceiverEmptyContract() public {
        vm.expectRevert("ERC721: transfer to non-ERC721Receiver implementer");
        solContract.safeTransferFrom(owner, receiverEmptyContract, 1, "");

        vm.expectRevert("ERC721: transfer to non-ERC721Receiver implementer");
        yulContract.safeTransferFrom(owner, receiverEmptyContract, 1, "");
    }

    function testSafeTransferFromToNonReceiverContract() public {
        vm.expectRevert("ERC721: ERC721Receiver rejected tokens");
        solContract.safeTransferFrom(owner, nonReceiverContract, 1, "");

        vm.expectRevert("ERC721: ERC721Receiver rejected tokens");
        yulContract.safeTransferFrom(owner, nonReceiverContract, 1, "");
    }

    function testSafeTransferFromToReceiverRevertContract() public {
        vm.expectRevert("Revert something");
        solContract.safeTransferFrom(owner, receiverRevertContract, 1, "");

        vm.expectRevert("Revert something");
        yulContract.safeTransferFrom(owner, receiverRevertContract, 1, "");
    }

    function testSafeTransferFromAsOwner(uint8 id) public {
        vm.assume(id != 1);
        address to = userA;

        assertEq(yulContract.balanceOf(owner), 1);
        assertEq(solContract.balanceOf(owner), 1);

        assertEq(yulContract.balanceOf(to), 0);
        assertEq(solContract.balanceOf(to), 0);

        yulContract.mint(owner, id);
        solContract.mint(owner, id);

        assertEq(yulContract.balanceOf(owner), 2);
        assertEq(solContract.balanceOf(owner), 2);

        vm.expectEmit(true, true, true, false);
        emit TransferSingle(owner, owner, to, id);
        solContract.safeTransferFrom(owner, to, id, "");

        vm.expectEmit(true, true, true, false);
        emit TransferSingle(owner, owner, to, id);
        yulContract.safeTransferFrom(owner, to, id, "");

        assertEq(yulContract.balanceOf(to), 1);
        assertEq(solContract.balanceOf(to), 1);

        assertEq(yulContract.balanceOf(owner), 1);
        assertEq(solContract.balanceOf(owner), 1);
    }

    function testSafeTransferFromAsOperator(uint8 id) public {
        vm.assume(id != 1);

        address to = userB;

        assertEq(yulContract.balanceOf(userA), 0);
        assertEq(solContract.balanceOf(userA), 0);

        assertEq(yulContract.balanceOf(to), 0);
        assertEq(solContract.balanceOf(to), 0);

        vm.stopPrank();
        vm.startPrank(userA, msg.sender);

        yulContract.setApprovalForAll(owner, true);
        solContract.setApprovalForAll(owner, true);

        vm.stopPrank();
        vm.startPrank(owner, msg.sender);

        yulContract.mint(userA, id);
        solContract.mint(userA, id);

        assertEq(yulContract.balanceOf(userA), 1);
        assertEq(solContract.balanceOf(userA), 1);

        yulContract.safeTransferFrom(userA, to, id, "");
        solContract.safeTransferFrom(userA, to, id, "");

        assertEq(yulContract.balanceOf(to), 1);
        assertEq(solContract.balanceOf(to), 1);

        assertEq(yulContract.balanceOf(userA), 0);
        assertEq(solContract.balanceOf(userA), 0);
    }

    function testSafeTransferFromNotOwner(uint8 id, uint8 amount) public {
        vm.assume(id != 1);

        address to = userB;

        assertEq(yulContract.balanceOf(userA), 0);
        assertEq(solContract.balanceOf(userA), 0);

        assertEq(yulContract.balanceOf(to), 0);
        assertEq(solContract.balanceOf(to), 0);

        yulContract.mint(userA, id);
        solContract.mint(userA, id);

        assertEq(yulContract.balanceOf(userA), 1);
        assertEq(solContract.balanceOf(userA), 1);

        vm.expectRevert("ERC721: caller is not token owner or approved");
        yulContract.safeTransferFrom(userA, to, id, "");
        vm.expectRevert("ERC721: caller is not token owner or approved");
        solContract.safeTransferFrom(userA, to, id, "");
    }

    function testSafeTransferFromToZeroAddress(uint8 id) public {
        vm.assume(id != 1);

        address to = address(0);

        yulContract.mint(owner, id);
        solContract.mint(owner, id);

        assertEq(yulContract.balanceOf(owner), 2);
        assertEq(solContract.balanceOf(owner), 2);

        vm.expectRevert("ERC721: transfer to the zero address");
        yulContract.safeTransferFrom(owner, to, id, "");
        vm.expectRevert("ERC721: transfer to the zero address");
        solContract.safeTransferFrom(owner, to, id, "");
    }

    function testBurnWithZeroAddress() public {
        vm.stopPrank();

        uint id = 1010;
        address zero = address(0);

        vm.prank(zero, msg.sender);
        vm.expectRevert("ERC721: burn from the zero address");
        yulContract.burn(id);
    }

    function testMintToZeroAddress(uint id, uint amount) public {
        vm.expectRevert("ERC721: mint to the zero address");
        yulContract.mint(address(0), id);
    }

    function testSafeBatchTransferFrom() public {
        vm.stopPrank();

        vm.startPrank(owner, msg.sender);

        address sender = owner;

        uint[] memory ids = new uint[](5);
        ids[0] = 0xa1;
        ids[1] = 0xb2;
        ids[2] = 0xc3;
        ids[3] = 0xd4;
        ids[4] = 0xe5;

        yulContract.mint(sender, ids[0]);
        yulContract.mint(sender, ids[1]);
        yulContract.mint(sender, ids[2]);
        yulContract.mint(sender, ids[3]);
        yulContract.mint(sender, ids[4]);

        solContract.mint(sender, ids[0]);
        solContract.mint(sender, ids[1]);
        solContract.mint(sender, ids[2]);
        solContract.mint(sender, ids[3]);
        solContract.mint(sender, ids[4]);

        vm.expectEmit(true, true, true, false);
        emit TransferBatch(sender, sender, userA, ids);
        yulContract.safeBatchTransferFrom(sender, userA, ids, "");

        vm.expectEmit(true, true, true, false);
        emit TransferBatch(sender, sender, userA, ids);
        solContract.safeBatchTransferFrom(sender, userA, ids, "");
    }

    function testSimpleMint() public {
        address to = userA;

        vm.expectEmit(true, true, true, false);
        emit TransferSingle(owner, address(0), to, 3);
        yulContract.mint(to, 3);

        vm.expectEmit(true, true, true, false);
        emit TransferSingle(owner, address(0), to, 3);
        solContract.mint(to, 3);
    }

    function testSimpleBurn() public {
        yulContract.mint(owner, 2);
        solContract.mint(owner, 2);

        vm.expectEmit(true, true, true, false);
        emit TransferSingle(owner, owner, address(0), 2);
        yulContract.burn(2);

        vm.expectEmit(true, true, true, false);
        emit TransferSingle(owner, owner, address(0), 2);
        solContract.burn(2);

        vm.stopPrank();
    }
}
