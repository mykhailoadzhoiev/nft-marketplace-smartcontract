// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: contracts/TokensManager.sol

pragma solidity ^0.8.3;



contract TokensManager is IERC721Receiver {
  event TokenReceived(address _contract, address _from, uint256 _tokenId);
  event TokenTransfered(address _contract, uint256 _tokenId, address _newOwner);
  event TokenWithdraw(address _contract, uint256 _tokenId, address _to);

  struct ItemOwnership {
    address owner;
    address creator;
    bool isLocked;
  }

  mapping (address => mapping(uint256 => ItemOwnership)) owners;

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) override external returns(bytes4 value) {
    // Store token owner
    owners[msg.sender][_tokenId] = ItemOwnership(_from, _from, false);
    
    emit TokenReceived(msg.sender, _from, _tokenId);
    return 0x150b7a02;
  }

  function _getOwner(address _contract, uint256 _tokenId) internal view returns (address) {
    return owners[_contract][_tokenId].owner;
  }

  function _getCreator(address _contract, uint256 _tokenId) internal view returns (address) {
    return owners[_contract][_tokenId].creator;
  }

  function _innerTransfer(address _contract, uint256 _tokenId, address _newOwner) internal {
    require(_newOwner != address(0), "New owner cannot be zero address");
    
    owners[_contract][_tokenId].owner = _newOwner;

    emit TokenTransfered(_contract, _tokenId, _newOwner);
  } 

  function _withdrawItem(address _contract, uint256 _tokenId, address _to) internal {
    require(_to != address(0), "Cannot withdraw to zero address");
    require(msg.sender == owners[_contract][_tokenId].owner, "You are not owner of this item");
    require(!_isItemLocked(_contract, _tokenId), "Item is locked");

    delete owners[_contract][_tokenId];

    IERC721(_contract).safeTransferFrom(address(this), _to, _tokenId);

    emit TokenWithdraw(_contract, _tokenId, _to); 
  }

  function _lockItem(address _contract, uint256 _tokenId) internal {
    require(owners[_contract][_tokenId].isLocked == false, "Item already locked");
    owners[_contract][_tokenId].isLocked = true;
  }

  function _unlockItem(address _contract, uint256 _tokenId) internal {
    require(owners[_contract][_tokenId].isLocked == true, "Item already unlocked");
    owners[_contract][_tokenId].isLocked = false;
  }

  function _isItemLocked(address _contract, uint256 _tokenId) internal view returns (bool) {
    require(owners[_contract][_tokenId].owner != address(0), "Item does not exists");
    return owners[_contract][_tokenId].isLocked;
  }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/BalanceManager.sol

pragma solidity ^0.8.3;



contract BalanceManager is TokensManager {
    
    mapping (address => uint256) internal balanceOf;

    receive() external payable {
      balanceOf[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Your balance is insufficient");
        balanceOf[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function changeInnerBalanceOwner(address _newOwner) public {
        require(balanceOf[msg.sender] != 0, "msg.sender balance is empty");
        require(_newOwner != address(0), "cannot change owner to zero address");

        balanceOf[_newOwner] += balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
    }
}

// File: contracts/ExchangeCore.sol

pragma solidity ^0.8.3;



contract ExchangeCore is BalanceManager {
    event NewOrder(bytes32 indexed hash);
    event NewBid(bytes32 indexed hash, uint256 value);

    address feeTakerAddress1 = 0xFbc147659f5297983D2fBdf6C6aE45Ae9ceCF2E9;
    address feeTakerAddress2 = 0x2e11d23151e595211e63D2724764477B0F4Fad1E;
    address feeTakerAddress3 = 0x2D045410f002A95EFcEE67759A92518fA3FcE677;

    mapping(bytes32 => Order) public orders;

    enum OrderType { FIXED, MAX_BID }
    enum PaymentType { BNB, INNER }

    struct Order {
        address maker;
        address taker;
        OrderType orderType;
        uint256 creationTimespamp;
        uint256 saleFinishTimestamp;
        uint256 price;
        uint256 extra;
        uint256 itemId;
        IERC721 itemContract;
    }

    function _calculateDistribution(uint256 _price, bool _isResell) internal pure returns (uint256[5] memory _distribution) {
        _distribution[0] = _price * (_isResell ? 75 : 90) / 100; // maker
        _distribution[1] = _price * (_isResell ? 15 : 0) / 100; // creator
        _distribution[2] = _price * 3 / 100; // fee 1
        _distribution[3] = _price * 3 / 100; // fee 2
        _distribution[4] = _price * 4 / 100; // fee 3
    }

    function createOrder(Order memory order) public {
        require(msg.sender == order.maker, "msg.sender should be order maker");
        require(_getOwner(address(order.itemContract), order.itemId) == msg.sender, "you need to transfer this item to us first");
        require(!_isItemLocked(address(order.itemContract), order.itemId), "Item already on sale");

        require(order.maker != address(0), "Empty maker address");
        require(order.price != 0, "Price cannot be zero");
        require(
            order.creationTimespamp != 0,
            "creationTimespamp cannot be zero"
        );
        require(
            order.creationTimespamp < order.saleFinishTimestamp,
            "Sale start timestamp cannot be greater than finish"
        );

        bytes32 orderHash = keccak256(abi.encode(order));
        require(
            orders[orderHash].maker == address(0),
            "Order already exists"
        );

        if (order.orderType == OrderType.MAX_BID) {
            require(order.extra == 0, "Extra must be 0");
        }

        // Stores new order in mapping
        orders[orderHash] = order;
        _lockItem(address(order.itemContract), order.itemId);

        emit NewOrder(orderHash);
    }

    // Use for auction
    function placeBid(bytes32 id, PaymentType payment, uint256 bid) public payable {
        require(orders[id].maker != address(0), "Order does not found");
        require(orders[id].orderType == OrderType.MAX_BID, "Order has auction type, use placeBid instead");

        if (payment == PaymentType.BNB) {
            require(msg.value > orders[id].price + orders[id].extra, "Insufficient msg.value");
            if (orders[id].taker != address(0)) {
                payable(orders[id].taker).send(orders[id].price + orders[id].extra); // Return prev bid
            }
            
            orders[id].taker = msg.sender;
            orders[id].extra = msg.value - orders[id].price;
            emit NewBid(id, msg.value);
        } else {
            require(balanceOf[msg.sender] >= bid, "Insufficient funds");

            if (orders[id].taker != address(0)) {
                balanceOf[orders[id].taker] += (orders[id].price + orders[id].extra); // Return prev bid
            }

            balanceOf[msg.sender] -= (orders[id].price + orders[id].extra);

            orders[id].taker = msg.sender;
            orders[id].extra = msg.value - orders[id].price;

            emit NewBid(id, bid);
        }
    }

    function finishAuction(bytes32 id) public {
        require(orders[id].maker != address(0), "Order does not found");
        require(orders[id].taker != address(0), "Use cancelOrder instead");

        if (orders[id].saleFinishTimestamp < block.timestamp) {
            require(msg.sender == orders[id].maker);    // Only maker can finish auction before lifetime exceeded
        }

        address itemCreator = _getCreator(address(orders[id].itemContract), orders[id].itemId);
        bool isResell = (orders[id].maker != itemCreator);
        uint256[5] memory distribution = _calculateDistribution(orders[id].price + orders[id].extra, isResell); 

        balanceOf[orders[id].maker] += distribution[0];
        balanceOf[itemCreator]      += distribution[1];
        balanceOf[feeTakerAddress1] += distribution[2];
        balanceOf[feeTakerAddress2] += distribution[3];
        balanceOf[feeTakerAddress3] += distribution[4];

        _innerTransfer(address(orders[id].itemContract), orders[id].itemId, orders[id].taker);

        _unlockItem(address(orders[id].itemContract), orders[id].itemId);
        delete orders[id];
    }

    function cancelOrder(bytes32 id) public {
        require(orders[id].maker != address(0), "Order does not found");
        require(msg.sender == orders[id].maker);
        require(orders[id].taker == address(0), "Auction already has bids");

        _unlockItem(address(orders[id].itemContract), orders[id].itemId);
        delete orders[id];
    }

    function buyOrder(bytes32 id, PaymentType payment) public payable {
        require(orders[id].maker != address(0), "Order does not found");
        require(orders[id].orderType == OrderType.FIXED, "Order has auction type, use placeBid instead");
        
        address itemCreator = _getCreator(address(orders[id].itemContract), orders[id].itemId);

        if (payment == PaymentType.BNB) {
            require(msg.value == orders[id].price, "msg.value must be equal item price");
            // balanceOf[orders[id].maker] += msg.value; 
            bool isResell = (orders[id].maker != itemCreator);
            uint256[5] memory distribution = _calculateDistribution(msg.value, isResell); 

            balanceOf[orders[id].maker] += distribution[0];
            balanceOf[itemCreator]      += distribution[1];
            balanceOf[feeTakerAddress1] += distribution[2];
            balanceOf[feeTakerAddress2] += distribution[3];
            balanceOf[feeTakerAddress3] += distribution[4];

            // balance updates
            _innerTransfer(address(orders[id].itemContract), orders[id].itemId, msg.sender);
        } else {
            require(balanceOf[msg.sender] >= orders[id].price, "Insufficient funds");
            balanceOf[msg.sender] -= orders[id].price;

            bool isResell = (orders[id].maker != itemCreator);
            uint256[5] memory distribution = _calculateDistribution(msg.value, isResell);

            balanceOf[orders[id].maker] += distribution[0];
            balanceOf[itemCreator]      += distribution[1];
            balanceOf[feeTakerAddress1] += distribution[2];
            balanceOf[feeTakerAddress2] += distribution[3];
            balanceOf[feeTakerAddress3] += distribution[4]; 

            // balance updates
            _innerTransfer(address(orders[id].itemContract), orders[id].itemId, msg.sender);
        }

        _unlockItem(address(orders[id].itemContract), orders[id].itemId);
        delete orders[id];
    }
}
