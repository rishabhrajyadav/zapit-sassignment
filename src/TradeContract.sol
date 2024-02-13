// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ITradeContract.sol";
import "./ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title TradeContract
 * @dev Smart contract for handling trades between sellers and buyers.
 */
contract TradeContract is ITradeContract, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    uint256 private orderId;
    mapping(uint256 => Order) private orders;
    mapping(uint256 => mapping(address => uint256)) private bMessages;

    /**
     * @notice List a new trade order.
     * @param _amount The amount of tokens or ether to be traded.
     * @param _tokenAddress The address of the token to be traded. 
       (Use 0x000000000000000000 for ether.)
     */
    function listOrder(uint256 _amount, address _tokenAddress) external payable nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        uint256 oId = ++orderId;
        Order storage order = orders[oId];
        order.seller = msg.sender;
        if (_tokenAddress == address(0)) {
            if (_amount != msg.value / 10**18) revert InsufficientFunds();
            order.amount = _amount;
        } else {
            if (IERC20(_tokenAddress).balanceOf(msg.sender) < _amount || IERC20(_tokenAddress).allowance(msg.sender, address(this)) != _amount)
                revert InsufficientFunds();
            order.amount = _amount;
        }
        order.tokenAddress = _tokenAddress;
        order.state = OrderState.Listed;

        emit ListOrder(msg.sender, _amount, _tokenAddress, OrderState.Listed);
    }

    /**
     * @notice Register as a buyer for a specific trade order.
     * @param _orderId The ID of the trade order.
     * @param _message The message of the buyer.
     */
    function registerBuyer(uint256 _orderId, uint256 _message) external nonReentrant {
        if (orderId < _orderId) revert InvalidOrderId();
        Order memory order = orders[_orderId];
        if (order.seller == msg.sender) revert SellersNotAllowed();
        if (inArray(msg.sender, _orderId)) revert AlreadyRegistered(); // Be cautious as you can only register once
        if (order.state != OrderState.Listed) revert NotListedOrReleased();

        orders[_orderId].buyers.push() = msg.sender;
        orders[_orderId].messages.push() = _message;
        bMessages[_orderId][msg.sender] = _message;

        emit RegisterBuyer(msg.sender, _orderId, _message);
    }

    /**
     * @notice Release funds to the buyer upon successful trade.
     * @param _orderId The ID of the trade order.
     * @param _sign The signature by the seller.
     * @param _buyer The address of the buyer.
     */
    function releaseFunds(uint256 _orderId, bytes memory _sign, address _buyer) external nonReentrant {
        Order memory order = orders[_orderId];
        if (order.state != OrderState.Listed) revert NotListedOrReleased();
        if (msg.sender != order.seller) revert NotSeller();
        if (!inArray(_buyer, _orderId)) revert BuyerNotRegistered();

        orders[_orderId].state = OrderState.Released;

        uint256 _message = bMessages[orderId][_buyer];
        bytes32 messageHash = keccak256(abi.encodePacked(_buyer, _message)); //_buyer = buyer's Address
        address recoveredAddress = recover2( messageHash ,_sign);
        if (recoveredAddress != order.seller) revert NotActualSeller();

        if (order.tokenAddress != address(0)) {
            IERC20 token = IERC20(order.tokenAddress);
            bool ok = token.transferFrom(order.seller, _buyer, order.amount);
            if (!ok) revert TransactionFailed();
        } else {
            (bool ok, ) = payable(_buyer).call{value: order.amount * 10**18}("");
            if (!ok) revert TransactionFailed();
        }

        emit ReleaseFunds(_buyer, recoveredAddress, _orderId, _sign);
    }

    /**
     * @notice Fetch details of a specific trade order.
     * @param _orderId The ID of the trade order.
     * @return order The details of the trade order.
     */
    function fetchOrderDetails(uint256 _orderId) external view returns (Order memory order) {
        return orders[_orderId];
    }

    /**
     * @notice Recover the address from a signed hash.
     * @param _hash The hash to recover the address from.
     * @param _sign The signature to recover the address.
     * @return recoveredAddress The recovered address.
     */
    function recover2(bytes32 _hash, bytes memory _sign) public pure returns (address recoveredAddress) {
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        recoveredAddress = messageHash.recover(_sign);
    }

    /**
     * @notice Get the unique message for a specific buyer in a trade order.
     * @param _orderId The ID of the trade order.
     * @param _buyer The address of the buyer.
     * @return _message The unique message for the buyer.
     */
    function getMessages(uint256 _orderId, address _buyer) external view returns (uint256 _message) {
        if (msg.sender != orders[_orderId].seller) revert NotSeller();
        return bMessages[_orderId][_buyer];
    }

    /**
     * @notice Get the total number of trade orders.
     * @return orderId The total number of trade orders.
     */
    function totalOrders() external view returns (uint256) {
        return orderId;
    }

    /**
     * @notice Check if a user is in the list of buyers for a specific trade order.
     * @param _user The address of the user to check.
     * @param _orderId The ID of the trade order.
     * @return isInArray Whether the user is in the list of buyers.
     */
    function inArray(address _user, uint256 _orderId) private view returns (bool isInArray) {
        Order memory order = orders[_orderId];
        for (uint256 i; i < order.buyers.length; ) {
            if (_user == order.buyers[i]) {
                isInArray = true;
                return isInArray;
            }
            unchecked {
                i++;
            }
        }
        isInArray = false;
    }
}
