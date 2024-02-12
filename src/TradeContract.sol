// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TradeContract is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;

  enum OrderState{
    None,
    Listed,
    Released
  }

  struct Order {
    uint256 amount; //considering 1 eth = 1 token;
    address seller;
    address tokenAddress;
    OrderState state;
    address[] buyers;
    uint256[] messages;
  }
  
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

  event ListOrder(address indexed seller , uint256 indexed amount , address indexed tokenAddress , OrderState state);
  event RegisterBuyer(address indexed buyer , uint256 indexed orderId , uint256 indexed message);
  event ReleaseFunds(address indexed buyer, address indexed recoveredAddress , uint256 orderId , bytes indexed sign);
  
  uint256 private orderId;
  mapping(uint256 => Order) private orders;
  mapping(uint256 => mapping(address => uint256)) private bMessages;

  function listOrder(uint256 _amount, address _tokenAddress) external payable nonReentrant {
    if(_amount == 0) revert InvalidAmount();
    uint256 oId = ++orderId;
    Order storage order = orders[oId];
    order.seller = msg.sender;
    if(_tokenAddress == address(0)){
      // this checks whether the seller sends enough ether to this contract;
      if( _amount != msg.value/ 10**18 ) revert InsufficientFunds();
      order.amount = _amount;
    } else {
      //this checks whether the seller have enough tokens and the tokens are approved to this contract
      if(IERC20(_tokenAddress).balanceOf(msg.sender) < _amount || !IERC20(_tokenAddress).approve(address(this) , _amount) || IERC20(_tokenAddress).allowance(msg.sender , address(this)) != _amount ) revert InsufficientFunds(); //plus approve the contract
      order.amount = _amount;
    }
    order.tokenAddress = _tokenAddress;
    order.state = OrderState.Listed;

    emit ListOrder(msg.sender , _amount , _tokenAddress , OrderState.Listed);
  }

  function registerBuyer(uint256 _orderId , uint256 _message) external nonReentrant {
    if(orderId < _orderId) revert InvalidOrderId();
    Order memory order = orders[_orderId];
    if( order.seller == msg.sender) revert OnlyBuyersAllowed();
    if( inArray(msg.sender, _orderId) ) revert AlreadyRegistered(); //Be cautious as you can only register once
    if( order.state != OrderState.Listed ) revert NotListedOrReleased();
    
    orders[_orderId].buyers.push() = msg.sender;
    orders[_orderId].messages.push() = _message;
    bMessages[_orderId][msg.sender] = _message;

    emit RegisterBuyer(msg.sender, _orderId, _message);
  }
  
  //assuming buyer can release funds . 
  function releaseFunds(uint256 _orderId , bytes memory _sign) external nonReentrant  {
    Order memory order = orders[_orderId];
    if( order.state != OrderState.Listed ) revert NotListedOrReleased();
    if(!inArray(msg.sender , _orderId)) revert NotBuyer();

    orders[_orderId].state = OrderState.Released;

    uint256 _message = bMessages[orderId][msg.sender];
    bytes32 messageHashh = keccak256(abi.encodePacked(msg.sender , _message)); //msg.sender = buyer's Address
    bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh));
    address recoveredAddress = messageHash.recover(_sign);
    if(recoveredAddress != order.seller) revert NotActualSeller();

      if(order.tokenAddress != address(0)){
        IERC20 token = IERC20(order.tokenAddress);
         bool ok = token.transferFrom(order.seller, msg.sender , order.amount);
         if(!ok) revert TransactionFailed();
      } else{
        (bool ok,) = payable(msg.sender).call{value : order.amount * 10**18}("");
        if(!ok) revert TransactionFailed();
      }
    
    emit ReleaseFunds(msg.sender, recoveredAddress , _orderId , _sign );
  }

  function fetchOrderDetails(uint256 _orderId) external view returns(Order memory){
    return orders[_orderId];
  }

  function recover2(bytes32 _hash , bytes memory _sign) external pure returns(address){
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        address recoveredAddress = messageHash.recover(_sign);
        return recoveredAddress;
    }

  function getMessages(uint256 _orderId,address _buyer) external view returns (uint256){
    return bMessages[_orderId][_buyer];
  }

   function totalOrders() external view returns (uint256){
    return orderId;
  }   

  function inArray(address _user , uint256 _orderId) private view returns(bool) {
    Order memory order = orders[_orderId];
    for(uint256 i ; i < order.buyers.length; ){
      if(_user == order.buyers[i]){
        return true;
      } 
      unchecked{i++;}
    }
    return false;
  }   

}