// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
 interface ITradeContract {
    /* -------------------------------------------------------------------------- */
    /*                                   ENUMS                                    */
    /* -------------------------------------------------------------------------- */

    enum OrderState{
      None,
      Listed,
      Released
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event ListOrder(address indexed seller , uint256 indexed amount , address indexed tokenAddress , OrderState state);
    event RegisterBuyer(address indexed buyer , uint256 indexed orderId , uint256 indexed message);
    event ReleaseFunds(address indexed buyer, address indexed recoveredAddress , uint256 orderId , bytes indexed sign);

    /* -------------------------------------------------------------------------- */
    /*                                   STRUCTS                                  */
    /* -------------------------------------------------------------------------- */
   
    struct Order {
     uint256 amount; //considering 1 eth = 1 token;
     address seller;
     address tokenAddress;
     OrderState state;
     address[] buyers;
     uint256[] messages;
   }

   /* -------------------------------------------------------------------------- */
   /*                                   ERRORS                                   */
   /* -------------------------------------------------------------------------- */
    
    error InvalidOrderId();
    error InsufficientFunds();
    error AlreadyListed();
    error InvalidAmount();
    error NotListedOrReleased();
    error NotBuyer();
    error TransactionFailed();
    error NotActualSeller();
    error OnlyBuyersAllowed();
    error AlreadyRegistered();

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    function listOrder(uint256 _amount, address _tokenAddress) external payable;

    function registerBuyer(uint256 _orderId , uint256 _message) external;

    function releaseFunds(uint256 _orderId , bytes memory _sign) external;

    function fetchOrderDetails(uint256 _orderId) external view returns(Order memory);

    function recover2(bytes32 _hash , bytes memory _sign) external pure returns(address);

    function getMessages(uint256 _orderId,address _buyer) external view returns (uint256);

    function totalOrders() external view returns (uint256);

 }