/// @title ERC-721 Token Contract in YUL (Assembly)
/// @author Mohamad Hammoud 
///
///  An ERC-721 token contract implemented in YUL (Assembly) language

// ╔══════════════════════════════════════════╗
// ║                 ERC721                   ║
// ╚══════════════════════════════════════════╝

object "ERC721" {
  code {
    // Store the initial URI
    sstore(4, "https://token.com/")
    
    // Copy the runtime code to memory and return it
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  
  // ╔══════════════════════════════════════════╗
  // ║                Runtime                   ║
  // ╚══════════════════════════════════════════╝

  object "Runtime" {
    // Return the calldata
    code {
        
      // Ensure no Ether was sent with the call
      require(iszero(callvalue()))

      // Load the function selector from calldata
      let s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)

      // Switch statement to handle different function calls
      switch s
        // Query the URI of a token
        case 0x0e89341c { // uri(uint256)
          uri(decodeAsUint(0))
        } 
        
        // balanceOf(address)
        case 0x70a08231 {
          returnUint(balanceOf(decodeAsAddress(0)))
        }
        
        // mint(address,uint256)
        case 0x40c10f19 {
          mint(decodeAsAddress(0), decodeAsUint(1))
        }
        
        // balanceOfBatch(address[])
        case 0x458c738e { 
          balanceOfBatch()
        }
        
        // setApprovalForAll(address,bool)
        case 0xa22cb465 { 
          setApprovalForAll(decodeAsAddress(0), decodeAsUint(1))
        }
        
        // isApprovalForAll(address,address)
        case 0xebd1d359 { 
          returnUint(isApprovalForAll(decodeAsAddress(0), decodeAsAddress(1)))
        }

        // safeTransferFrom(address,address,uint256,bytes)
        case 0xb88d4fde { 
          safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
        }
        
        // safeBatchTransferFrom(address,address,uint256[],bytes)
        case 0x28cfbd46 { 
          safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1))
        }

        // burn(uint256)
        case 0x42966c68 {
          burn(caller(), decodeAsUint(0))
        }
        
        // Revert for unknown function calls
        default {
          revert(0,0)
        }

      // ╔══════════════════════════════════════════╗
      // ║         Decoding Helper Functions        ║
      // ╚══════════════════════════════════════════╝

      /// @dev Function to decode calldata values as an address
      /// @param offset The position of the address in the calldata
      /// @return v The decoded address from the calldata
      function decodeAsAddress(offset) -> v {
        /// Ensure the decoded value is a valid address
        v := decodeAsUint(offset)

        /// If the decoded value is not a valid address, revert the transaction
        if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
          revert(0, 0)
        }
      }

      /// @dev Function to decode calldata values as a uint
      /// @param offset The position of the uint in the calldata
      /// @return v The decoded uint from the calldata
      function decodeAsUint(offset) -> v {
        /// Calculate the position of the uint in calldata
        let pos := add(4, mul(offset, 0x20))

        /// If the calldatasize is less than the position of the uint plus 0x20, revert the transaction
        if lt(calldatasize(), add(pos, 0x20)) {
            revert(0, 0)
        }

        /// Load the uint value from calldata at the calculated position
        v := calldataload(pos)
      }

    
      // ╔══════════════════════════════════════════╗
      // ║              Storage Layout              ║
      // ╚══════════════════════════════════════════╝
      
      /// @dev Function to get the URI position
      /// @return p The URI position, which is set to 0 in this implementation
      function uriPos() -> p { p := 4 }

      /// @dev Function to calculate the storage offset for a given account's balance
      /// @param account The address of the account
      /// @return offset The storage offset for the given account's balance
      function balanceOfStorageOffset(account) -> offset {
        /// Calculate the storage offset by adding 0x1000 to the account address
        offset := add(0x1000, account)
      }

      /// @dev Function to calculate the storage offset for a given account's allowance to a spender
      /// @param account The address of the account
      /// @param spender The address of the spender
      /// @return offset The storage offset for the given account's allowance to the spender
      function allowanceStorageOffset(account, spender) -> offset {
        /// Get the storage offset for the given account's balance
        offset := balanceOfStorageOffset(account)

        /// Store the balance offset and spender address in memory
        mstore(0x00, offset)
        mstore(0x20, spender)

        /// Calculate the storage offset for the account's allowance to the spender using keccak256
        offset := keccak256(0, 0x40)
      }

      // ╔══════════════════════════════════════════╗
      // ║            Contract Functions            ║
      // ╚══════════════════════════════════════════╝

      /// @dev Function to get the balance of a token for an address
      /// @param account The address of the account
      /// @return bal The balance of the token for the given account
      function balanceOf(account) -> bal {
        /// If the account address is the zero address, revert the transaction with an invalid owner error
        if eq(account, 0x0000000000000000000000000000000000000000) { 
          revertWithInvalidOwner()
        }

        /// Calculate the storage offset for the given account's balance and token ID
        mstore(0x00, balanceOfStorageOffset(account))
        // balance mapping slot
        mstore(0x20, 0x01)

        /// Load the balance from storage
        bal := sload(keccak256(0x00, 0x40))
      }

      /// @dev Function to query the balances of multiple token IDs for multiple accounts
      function balanceOfBatch() {
        /// Decode input parameters from calldata: address offset  offset
        let addressOffset := decodeAsUint(0)
        
        /// Load the lengths of the address and token ID arrays
        let addressArrayLength := calldataload(add(4, addressOffset))

        /// Set the initial memory offset for storing the result
        let memOffset := 0x40

        /// Store the length of the output array
        mstore(memOffset, 0x20)
        memOffset := add(memOffset, 0x20)
        mstore(memOffset, addressArrayLength)
        memOffset := add(memOffset, 0x20)

        /// Iterate through each address and token ID pair
        for { let i := 0 } lt(i, addressArrayLength) { i := add(i, 1) } {
          /// Load the address and token ID from the input arrays
          let account := calldataload(add(add(4, sub(memOffset, 0x60)), addressOffset))
          if eq(account, 0x0000000000000000000000000000000000000000) { 
            revertWithInvalidOwner()
          }
          
          /// Retrieve the balance for the current address and token ID
          mstore(memOffset, balanceOf(account))
          
          /// Move the memory offset for the next balance
          memOffset := add(memOffset, 0x20)
        }
        
        /// Return the memory containing the balances array
        return (0x40, memOffset)
      }

      /// @dev Function to set or unset approval for an operator
      /// @param operator The address of the operator
      /// @param approved A boolean value representing whether the operator is approved or not
      function setApprovalForAll(operator, approved) {
        /// If the operator is the same as the caller, revert the transaction with a self-approval error
        if eq(operator, caller()) { revertWithSelfApproval() }

        /// Update the allowance storage with the approval status for the operator
        sstore(allowanceStorageOffset(caller(), operator), approved)

        /// Emit the ApprovalForAll event
        emitApprovalForAll(caller(), operator, approved)
      }

      /// @dev Function to check if an operator is approved by an account
      /// @param account The address of the account
      /// @param operator The address of the operator
      /// @return allowed A boolean value representing whether the operator is approved by the account
      function isApprovalForAll(account, operator) -> allowed {
        /// Load the approval status from the allowance storage
        allowed := sload(allowanceStorageOffset(account, operator))
      }

      /// @dev Function to safely transfer tokens between addresses
      /// @param from The address of the sender
      /// @param to The address of the recipient
      /// @param id The token ID
      /// @param data Additional data to pass to the recipient's onERC721Received function (if implemented)
      function safeTransferFrom(from, to, id, data) {
        /// If the recipient address is the zero address, revert the transaction with a transfer to zero address error
        if iszero(to) {
          revertWithTransferToZeroAddress()
        }

        /// Check if the caller is the sender or has approval to transfer on behalf of the sender; if not, revert with a not owner or approved error
        if iszero(or(eq(caller(), from), isApprovalForAll(from, caller()))) { 
          revertWithNotOwnerOrApproved()
        }

        /// Transfer ownership of the token id to the recipient's address
        mstore(0x00, id)
        // slot 0 _owners mapping
        mstore(0x20, 0x00)
        let slot := keccak256(0x00, 0x40)

        sstore(slot, balanceOfStorageOffset(to))

        /// Load the sender's balance
        mstore(0x00, balanceOfStorageOffset(from))
        // slot 0 _balances mapping
        mstore(0x20, 0x01)
        let senderBalanceSlot := keccak256(0x00, 0x40)
        let senderBalance := sload(senderBalanceSlot)

        /// Load the recipient's balance
        mstore(0x00, balanceOfStorageOffset(to))
        // slot 0 _balances mapping
        mstore(0x20, 0x01)
        let recipientBalanceSlot := keccak256(0x00, 0x40)
        let recipientBalance := sload(recipientBalanceSlot)


        /// Update the sender's and recipient's balances
        sstore(senderBalanceSlot, safeSub(senderBalance, 0x01))
        sstore(recipientBalanceSlot, safeAdd(recipientBalance, 0x01))

        /// Emit the TransferSingle event
        emitTransferSingle(caller(), from, to, id)

        /// Perform a safe transfer acceptance check
        doSafeTransferAcceptanceCheck(from, to, id, data)
      }


      /// @dev Function to safely transfer multiple tokens between addresses in a batch
      /// @param from The address of the sender
      /// @param to The address of the recipient
      function safeBatchTransferFrom(from, to) {
        /// Check if the caller is either the 'from' address or has approval for all tokens; if not, revert with a not owner or approved error
        if iszero(or(eq(caller(), from), isApprovalForAll(from, caller()))) { revertWithNotOwnerOrApproved() } 
        
        /// Check if the 'to' address is valid; if not, revert with a transfer to zero address error
        if iszero(to) { revertWithTransferToZeroAddress() }
        
        /// Decode token IDs from calldata
        let idsOffset := decodeAsUint(2)
        
        // question: why did we add 4 ?
        /// Calculate lengths of token IDs arrays
        let lenIdsOffset := add(4, idsOffset)

        let lenIds := calldataload(lenIdsOffset)

        /// Initialize the current offset
        let currentOffset := 0x20

        /// Iterate through the token IDs and amounts arrays
        for { let i := 0 } lt(i, lenIds) { i := add(i, 1) } {

            /// Load the current token ID and amount
            let id := calldataload(add(lenIdsOffset, currentOffset))

            safeTransferFrom(from, to, id, "")
            
            /// Update the current offset
            currentOffset := add(currentOffset, 0x20)
        }

        /// Emit the TransferBatch event
        emitTransferBatch(caller(), from, to, idsOffset)
      }

      /// @dev Function to mint token to an account
      /// @param account The address of the account to mint token to
      /// @param id The token ID
      function mint(account, id) {
        /// If the account address is the zero address, revert the transaction with a mint to zero address error
        if iszero(account) {
          revertWithMintToZeroAddress()
        }

        // Mint for the account token id.
        // Store token id in memory
        mstore(0x00, id)
        // Store slot 0 in memory, slot 0 is for the _owners mapping
        mstore(0x20, 0x00)

        let loc := keccak256(0x00, 0x40)

        sstore(loc, balanceOfStorageOffset(account))

        /// Increase account's balance after minting.
        /// Store the caller in memory
        mstore(0x00, balanceOfStorageOffset(account))
        // Store slot 1 in memory, slot 1 is for the _balances mapping
        mstore(0x20, 0x01)
        // Generate the hash slot storage
        let slot := keccak256(0x00, 0x40)
        // store the balance of the deployer as 1 in the slot
        sstore(slot, safeAdd(sload(slot), 0x01))

        /// Emit the TransferSingle event
        emitTransferSingle(caller(), 0, account, id)

        /// Perform a safe transfer acceptance check
        doSafeTransferAcceptanceCheck(0, account, id, "")
      }

      /// @dev Function to burn tokens from an account
      /// @param account The address of the account to burn tokens from
      /// @param id The token ID
      /// @param amount The number of tokens to burn
      function burn(account, id) {
        /// If the account address is the zero address, revert the transaction with a burn from zero address error
        if iszero(account) {
          revertWithBurnFromZeroAddress()
        }

        // Burn for the account token id.
        // Store token 1 in memory
        mstore(0x00, id)
        // Store slot 0 in memory, slot 0 is for the _owners mapping
        mstore(0x20, 0x00)
        let loc := keccak256(0x00, 0x40)

        let owner := sload(loc)


        if iszero(eq(owner, balanceOfStorageOffset(account))) {
          revertWithNotOwnerOrApproved()
        }

        // Burn the token
        sstore(loc, 0x00)

        /// Decrease account's balance after minting.
        /// Store the caller in memory
        mstore(0x00, balanceOfStorageOffset(account))
        // Store slot 1 in memory, slot 1 is for the _balances mapping
        mstore(0x20, 0x01)
        // Generate the hash slot storage
        let slot := keccak256(0x00, 0x40)
        // store the balance of the deployer as 1 in the slot
        sstore(slot, safeSub(sload(slot), 0x01))

        /// Emit the TransferSingle event
        emitTransferSingle(caller(), account, 0, id)
      }

      /// @dev Function to return the token URI
      /// @param index The token index
      /// @return The memory address and length containing the token URI
      function uri(index) {
        /// Store the length of the URI and the URI itself in memory
        mstore(0x00, 0x20)
        mstore(0x20, 0x12)
        mstore(0x40, sload(uriPos()))

        /// Return the memory containing the token URI
        return(0x00, 0x60)
      }

      /// @dev Function to do a safe transfer acceptance check
      /// @param from The address of the sender
      /// @param to The address of the recipient
      /// @param id The token ID
      /// @param data Additional data to be passed to the recipient's onERC1155Received function
      function doSafeTransferAcceptanceCheck(from, to, id, data) {
        /// Check the size of the recipient's code
        let size := extcodesize(to)

        /// If the recipient's code size is greater than 0, it means it's a contract
        if gt(size, 0) {
            /// Set the onERC721Received function selector and error signature
            let selector := 0x150b7a0200000000000000000000000000000000000000000000000000000000
            let errorSig := 0x8c379a000000000000000000000000000000000000000000000000000000000

            /// Prepare calldata for onERC721Received(operator, from, id, data)
            mstore(0x100, selector)
            mstore(0x104, caller())
            mstore(0x124, from)
            mstore(0x144, id)
            // question: what is this ? 
            mstore(0x164, 0x184)

            // question: what is this ? 
            /// Copy data to memory
            let endPtr := copyDataToMem(0x1a0, data)

            /// Clear the first 32 bytes in memory for storing the call result
            mstore(0x00, 0x00)

            /// Perform the call to the recipient's onERC721Received function
            let res := call(gas(), to, 0, 0x100, endPtr, 0x00, 0x04)

            /// If the call result matches the error signature, revert the transaction with the returned error data
            if eq(mload(0x00), errorSig) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            /// If the call was unsuccessful, revert with a non-ERC721 receiver error
            if iszero(res) {
                revertWithNonERC721Receiver()
            }

            /// If the call result doesn't match the onERC721Received function selector, revert with a rejected tokens error
            if iszero(eq(mload(0x00), selector)) {
                revertWithRejectedTokens()
            }
        }
      }

      // ╔══════════════════════════════════════════╗
      // ║        Calldata Encoding Functions       ║
      // ╚══════════════════════════════════════════╝

      /// @dev Function to return a uint value in memory
      /// @param v The uint value to be returned
      function returnUint(v) {
        /// Store the uint value in memory
        mstore(0, v)
        /// Return the memory location and length
        return(0, 0x20)
      }

      // ╔══════════════════════════════════════════╗
      // ║            Utility Functions             ║
      // ╚══════════════════════════════════════════╝

      /// @dev Function to check if a <= b
      /// @param a The first number to compare
      /// @param b The second number to compare
      function lte(a, b) -> r {
        /// Check if a is less than or equal to b and return the result
        r := iszero(gt(a, b))      
      }

      /// @dev Function to check if a >= b
      /// @param a The first number to compare
      /// @param b The second number to compare
      function gte(a, b) -> r {
        /// Check if a is greater than or equal to b and return the result
        r := iszero(lt(a, b))
      }

      /// @dev Function to safely add two numbers, reverting if overflow occurs
      /// @param a The first number to add
      /// @param b The second number to add
      function safeAdd(a, b) -> r {
        /// Add the two numbers
        r := add(a, b)
        /// Check if the result is less than either of the inputs and revert if it is
        if or(lt(r, a), lt(r, b)) { revert(0x00, 0x00) }
      }

      /// @dev Function to safely subtract two numbers, reverting if overflow occurs
      /// @param a The number to subtract from
      /// @param b The number to subtract
      function safeSub(a, b) -> r {
        /// Subtract b from a
        r := sub(a, b)
        /// Check if the result is greater than a and revert if it is
        if gt(r, a) { revert(0x00, 0x00) }
      }

      /// @dev Function to require a condition is true, otherwise revert
      /// @param condition The condition to check
      function require(condition) {
        /// Check if the condition is false and revert if it is
        if iszero(condition) { revert(0, 0) }
      }

      /// @dev Function to copy data from calldata to memory
      /// @param memPtr The memory pointer to start writing to
      /// @param dataOff The offset in calldata where the data starts
      function copyDataToMem(memPtr, dataOff) -> updatedMemPtr {
        /// Get the offset of the data length in calldata
        let dataLengthOff := add(dataOff, 4)
        /// Load the data length from calldata
        let dataLength := calldataload(dataLengthOff)

        /// Calculate the total length of the data to copy
        let totalLength := add(0x20, dataLength) // dataLength+data
        let remainder := mod(dataLength, 0x20)
        if remainder {
            totalLength := add(totalLength, sub(0x20, remainder))
        }

        /// Copy the data from calldata to memory
        calldatacopy(memPtr, dataLengthOff, totalLength)

        /// Update the memory pointer to the next available location
        updatedMemPtr := add(memPtr, totalLength)
      }

      // ╔══════════════════════════════════════════╗
      // ║            Events Functions              ║
      // ╚══════════════════════════════════════════╝

      /// @dev Function to emit a TransferSingle event
      /// @param operator The address of the operator performing the transfer
      /// @param from The address sending the tokens
      /// @param to The address receiving the tokens
      /// @param id The ID of the token being transferred
      function emitTransferSingle(operator, from, to, id) {
        /// Get the signature hash for the TransferSingle event
        let signatureHash := 0x9e6acd20e3f2497dbc8f7c785e2922c6550e2c7182ab2da2637b302b65b416fd
        
        /// Store the token ID and amount in memory
        mstore(0x00, id)
        
        /// Emit the TransferSingle event using log4 opcode
        log4(0x00, 0x20, signatureHash, operator, from, to)
      }

      /// @dev Emits a TransferBatch event.
      /// @param operator The address of the operator performing the transfer.
      /// @param from The address of the sender.
      /// @param to The address of the recipient.
      /// @param ids An array containing the IDs of the tokens being transferred.
      function emitTransferBatch(operator, from, to, ids) {
        // The hash of the TransferBatch signature for the ERC721 standard
        let signatureHash := 0x2e75a6cf483a33fd7e40b01fc5b561361f6e9b2d5a492f866bd66ca430a8c557

        // Calculate lengths of token IDs arrays
        let lenIdsOffset := add(4, ids)

        let lenIds := calldataload(lenIdsOffset)

        let memptr := 0x00

        // Copy token IDs to memory
        mstore(memptr, 0x0000000000000000000000000000000000000000000000000000000000000040)
        memptr := add(memptr, 0x20)
        mstore(memptr, add(0x60, mul(lenIds, 0x20)))
        memptr := add(memptr, 0x20)

        let len := add(sub(calldatasize(), lenIdsOffset), 0x20)

        for { let i := 0 } lt(memptr, len) { i := add(i, 1) } {
              mstore(memptr, calldataload(add(sub(memptr, 0x40), lenIdsOffset)))
              memptr := add(memptr, 0x20)
        }
        // Emit TransferBatch event
        log4(0, memptr, signatureHash, operator, from, to)
      }

      /// @dev Emits an ApprovalForAll event.
      /// @param account The address of the account granting the approval.
      /// @param operator The address of the operator being approved.
      /// @param approved The new approval status.
      function emitApprovalForAll(account, operator, approved) {
          
        // The hash of the ApprovalForAll signature for the ERC1155 standard
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
          
        // Copy the approval status to memory
        mstore(0x00, approved)

        // Emit ApprovalForAll event
        log3(0x00, 0x20, signatureHash, account, operator)
      }

      /// @dev Emits an URI event.
      /// @param value The URI value to emit.
      /// @param id The token ID associated with the URI.
      function emitURI(value, id) {
        // The hash of the URI signature for the ERC1155 standard
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31

        // Copy the URI value to memory
        mstore(0x00, value)

        // Emit URI event
        log2(0x00, 0x20, signatureHash, id)
      }


      // ╔══════════════════════════════════════════╗
      // ║            Reverts Functions             ║
      // ╚══════════════════════════════════════════╝

      /// Function to revert with a custom message and size
      /// Reverts with message "ERC721: address zero is not a valid owner"
      function revertWithInvalidOwner() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 41)
        mstore(0x44, 0x4552433732313a2061646472657373207a65726f206973206e6f742061207661)
        mstore(0x64, 0x6c6964206f776e65720000000000000000000000000000000000000000000000)

        
        revert(0x00, 0x84)
      }

      /// Function to revert with a custom message and size
      /// Reverts with message "ERC721: setting approval status for self"
      function revertWithSelfApproval() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 40)        
        mstore(0x44, 0x4552433732313a2073657474696e6720617070726f76616c2073746174757320)
        mstore(0x64, 0x666f722073656c66000000000000000000000000000000000000000000000000)
                      
        revert(0x00, 0x84)
      }

        
      /// Function to revert with a custom message and size
      /// Reverts with message "ERC721: caller is not token owner or approved"
      function revertWithNotOwnerOrApproved() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 45)
        mstore(0x44, 0x4552433732313a2063616c6c6572206973206e6f7420746f6b656e206f776e65)
        mstore(0x64, 0x72206f7220617070726f76656400000000000000000000000000000000000000)
                      
        revert(0x00, 0x84)
      }

      
      /// Function to revert with a custom message and size
      /// @dev Reverts with message "ERC721: transfer to the zero address"
      function revertWithTransferToZeroAddress() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 36)
        mstore(0x44, 0x4552433732313a207472616e7366657220746f20746865207a65726f20616464)
        mstore(0x64, 0x7265737300000000000000000000000000000000000000000000000000000000)
        
        revert(0x00, 0x84)
      }

      /// Reverts with a custom message when attempting to mint to the zero address.
      /// Error: "ERC721: mint to the zero address"
      function revertWithMintToZeroAddress() {
          mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)  // Store error signature
          mstore(0x04, 0x20)  // Store size of error message
          mstore(0x24, 32)  // Store length of error message
          mstore(0x44, 0x4552433732313a206d696e7420746f20746865207a65726f2061646472657373)  // Store error message as ASCII
          revert(0x00, 0x64)  // Revert with error signature and message size
      }

      /// Function to revert with a custom message and size when burning tokens from the zero address.
      /// Error("ERC721: burn from the zero address")
      function revertWithBurnFromZeroAddress() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        mstore(0x24, 34)
        mstore(0x44, 0x4552433732313a206275726e2066726f6d20746865207a65726f206164647265)
        mstore(0x64, 0x7373000000000000000000000000000000000000000000000000000000000000)
  
        revert(0x00, 0x84)
      }

      /// Function to revert with a custom message and size when burn amount exceeds balance.
      /// "ERC1155: burn amount exceeds balance"
      function revertWithBurnAmountExceedsBalance() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        mstore(0x24, 36)
        mstore(0x44, 0x455243313135353a206275726e20616d6f756e7420657863656564732062616c)
        mstore(0x64, 0x616e636500000000000000000000000000000000000000000000000000000000)

        revert(0x00, 0x84)
      }

      /// Function to revert with a custom message and size when ERC721Receiver rejected tokens.
      // "ERC721: ERC721Receiver rejected tokens"
      function revertWithRejectedTokens() {
            // question: what is this ? 
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 38)
        mstore(0x44, 0x4552433732313a2045524337323152656365697665722072656a656374656420)
        mstore(0x64, 0x746f6b656e730000000000000000000000000000000000000000000000000000)

        revert(0x00, 0x84)
      }

      /// Function to revert with a custom message and size when transferring tokens to a non-ERC721Receiver implementer.
      // "ERC721: transfer to non-ERC721Receiver implementer"
      function revertWithNonERC721Receiver() {
            // question: what is this ? 
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 50)
        mstore(0x44, 0x4552433732313a207472616e7366657220746f206e6f6e2d4552433732315265)
        mstore(0x64, 0x63656976657220696d706c656d656e7465720000000000000000000000000000)
                          
        revert(0x00, 0x84)
      }
    }
  }
}

       
