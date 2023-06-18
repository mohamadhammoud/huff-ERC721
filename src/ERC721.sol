// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

contract ERC721 {
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string private _uri;

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

    constructor(string memory uri_) {
        _setURI(uri_);
    }

    function uri(uint256) public view returns (string memory) {
        return _uri;
    }

    function mint(address account, uint id) public {
        _mint(account, id, "");
    }

    function burn(uint id) public {
        _burn(msg.sender, id);
    }

    function balanceOf(address account) public view returns (uint) {
        require(
            account != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[account];
    }

    function balanceOfBatch(
        address[] memory accounts
    ) public view returns (uint256[] memory) {
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovalForAll(
        address account,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public {
        require(
            from == msg.sender || isApprovalForAll(from, msg.sender),
            "ERC721: caller is not token owner or approved"
        );

        _safeTransferFrom(from, to, id, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data
    ) public {
        require(
            from == msg.sender || isApprovalForAll(from, msg.sender),
            "ERC721: caller is not token owner or approved"
        );

        _safeBatchTransferFrom(from, to, ids, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC721: transfer to the zero address");

        address operator = msg.sender;

        require(
            _owners[id] == from,
            "ERC721: caller is not token owner or approved"
        );

        unchecked {
            _balances[from] -= 1;
        }

        _owners[id] == to;

        _balances[to] += 1;

        emit TransferSingle(operator, from, to, id);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC721: transfer to the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];

            require(
                _owners[id] == from,
                "ERC721: caller is not token owner or approved"
            );

            unchecked {
                _balances[from] -= 1;
            }

            _owners[id] == to;

            _balances[to] += 1;
        }

        emit TransferBatch(operator, from, to, ids);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, data);
    }

    function _setURI(string memory newuri) internal {
        _uri = newuri;
    }

    function _mint(address to, uint256 id, bytes memory data) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[id] == address(0), "ERC721: token already exists");

        address operator = msg.sender;

        _balances[to] += 1;
        _owners[id] = to;

        emit TransferSingle(operator, address(0), to, id);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC721: mint to the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(_owners[id] == address(0), "ERC721: token already exists");

            unchecked {
                _balances[to] += 1;
            }

            _owners[id] == to;
        }

        emit TransferBatch(operator, address(0), to, ids);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            data
        );
    }

    function _burn(address from, uint256 id) internal {
        require(from != address(0), "ERC721: burn from the zero address");
        require(_owners[id] != address(0), "ERC721: token already exists");

        address operator = msg.sender;

        require(
            _owners[id] == from,
            "ERC721: caller is not token owner or approved"
        );

        unchecked {
            _balances[from] -= 1;
        }

        _owners[id] == address(0);

        emit TransferSingle(operator, from, address(0), id);
    }

    function _burnBatch(address from, uint256[] memory ids) internal {
        require(from != address(0), "ERC721: burn from the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(
                _owners[id] == from,
                "ERC721: caller is not token owner or approved"
            );

            unchecked {
                _balances[from] -= 1;
            }

            _owners[id] == address(0);
        }

        emit TransferBatch(operator, from, address(0), ids);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) private {
        uint size;
        assembly {
            size := extcodesize(to)
        }

        if (size > 0) {
            try
                IERC721Receiver(to).onERC721Received(operator, from, id, data)
            returns (bytes4 response) {
                if (response != IERC721Receiver.onERC721Received.selector) {
                    revert("ERC721: ERC721Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC721: transfer to non-ERC721Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data
    ) private {
        uint size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try
                IERC721Receiver(to).onERC721BatchReceived(
                    operator,
                    from,
                    ids,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC721Receiver.onERC721BatchReceived.selector
                ) {
                    revert("ERC721: ERC721Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC721: transfer to non-ERC721Receiver implementer");
            }
        }
    }

    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
