// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TradeContract} from "../src/TradeContract.sol";
import {ERC20} from "../src/ERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TradeContractTest is Test{
    using ECDSA for bytes32;

    TradeContract public tradeContract;
    ERC20 public token;
    address public etherAddress;

    function setUp() public {
        tradeContract = new TradeContract();
        token = new ERC20("token" , "TKN");
        etherAddress = address(0);
        token._mint(address(5), 1000);
    }
     
    // Test listing an order using ERC20Token
    function testListOrderWithERC20token() public {
        address seller = address(5);
        vm.startPrank(seller);
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(order.seller, seller);
        assertEq(token.balanceOf(seller), 1000);
    }

    // Test listing multiple orders using ERC20Token 
    function testListMultipleOrdersWithERC20token() public {
        address seller = address(5);
        vm.startPrank(seller);
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();
        
        address seller2 = address(4);
        vm.startPrank(seller2);
        token._mint(seller2, 100);
        token.approve(address(tradeContract), 100);
        assertEq(token.allowance(seller2, address(tradeContract)), 100);

        tradeContract.listOrder(100, address(token));
        vm.stopPrank();

        uint256 totalOrders = tradeContract.totalOrders(); 
        assertEq(totalOrders, 2);
    }

    // Test listing an order using Ether 
    function testListOrderWithEther() public {
        address seller = address(1);
        hoax(seller , 2 ether);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(seller.balance, 1 ether);
        assertEq(order.amount, 1 );
        assertEq(order.seller, seller);
        assertEq(uint(order.state), 1);
        assertEq(order.tokenAddress, address(0));
        assertEq(order.buyers.length, 0);
        assertEq(order.messages.length, 0);
    }

    // Test listing Multiple orders using Ether
    function testListMultipleOrdersWithEther() public {
        //seller1
        hoax(address(1) , 2 ether);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);

        //seller2
        hoax(address(3) , 4 ether);
        tradeContract.listOrder{value : 4 ether}(4 , etherAddress);
        
        uint256 totalOrders = tradeContract.totalOrders(); 
        assertEq(totalOrders, 2);
    }

    // Test listing Multiple orders using Both Ether and ERC20
    function testListMultipleOrdersWithEtherAndERC20() public {
        //seller1 = address(1);
        hoax(address(1) , 2 ether);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        address seller2 = address(5);
        vm.startPrank(seller2);
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller2, address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();
        
        uint256 totalOrders = tradeContract.totalOrders(); 
        assertEq(totalOrders, 2);
    }

     // Test registering a buyer
    function testRegisterBuyer() public {
        address seller = address(5);
        vm.startPrank(seller);
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        vm.prank(address(1));
        tradeContract.registerBuyer(1, 123);

        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(order.buyers.length, 1);
        assertEq(order.buyers[0], address(1));
    }
     
     // Test registering multiple buyers
    function testRegisterMultipleBuyers() public {
        address seller = address(5);
        vm.startPrank(seller);
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        vm.prank(address(1));
        tradeContract.registerBuyer(1, 123);

        vm.prank(address(3));
        tradeContract.registerBuyer(1, 345);

        vm.startPrank(seller);
        assertEq(tradeContract.getMessages(1, address(1)), 123);
        assertEq(tradeContract.getMessages(1, address(3)), 345);
        vm.stopPrank();

        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(order.buyers.length, 2);
        assertEq(order.buyers[0], address(1));
        assertEq(order.buyers[1], address(3));
    }


    // Test fetching order details
    function testFetchOrderDetails() public {
        address seller = address(5);
        vm.startPrank(seller);
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(order.amount, 1000);
        assertEq(order.seller, seller);
        assertEq(uint(order.state), 1);
        assertEq(order.tokenAddress, address(token));
        assertEq(order.buyers.length, 0);
        assertEq(order.messages.length, 0);
    }

    // Test releasing Ether as funds  
    function testReleaseEtherFunds() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        address buyer = address(2);
        deal(seller , 2 ether);
        uint256 message = 456;

        vm.startPrank(seller);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        bytes32 messageHashh = keccak256(abi.encodePacked(address(2) ,message)); 
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh)); 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v); 
        address recoveredAddress =  messageHash.recover(signature);
        assertEq( recoveredAddress , seller);

        vm.stopPrank();
        
        vm.startPrank(buyer);

        tradeContract.registerBuyer(1, message);
        address recoveredAddress2 = tradeContract.recover2(messageHashh, signature);
        assertEq(recoveredAddress , recoveredAddress2);

        vm.stopPrank();

        vm.prank(seller);
        tradeContract.releaseFunds(1, signature , buyer);
        assertEq(address(2).balance, 1 ether); 
        assertEq(address(seller).balance, 1 ether); 
    }

    // Test releasing ERC20 as funds 
    function testReleaseERC20Funds() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        address buyer = address(2);

        token._mint(seller, 1000);
        uint256 message = 456;

        vm.startPrank(seller);

        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);
        tradeContract.listOrder(1000, address(token));
        
        bytes32 messageHashh = keccak256(abi.encodePacked(address(2) , message)); 
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh)); 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v); 
        address recoveredAddress =  messageHash.recover(signature);
        assertEq( recoveredAddress , seller);

        vm.stopPrank();
        
        vm.startPrank(buyer);

        tradeContract.registerBuyer(1, message);
        address recoveredAddress2 = tradeContract.recover2(messageHashh, signature);
        assertEq(recoveredAddress , recoveredAddress2);

        vm.stopPrank();

        vm.prank(seller);
        tradeContract.releaseFunds(1, signature , buyer);
        assertEq(token.balanceOf(buyer), 1000); 
        assertEq(token.balanceOf(seller), 0); 
    }

    // Failing Test : when the message is different then verified message
    function testFailReleaseToUnverifiedMessage() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        address buyer = address(2);

        token._mint(seller, 1000);
        uint256 message = 789;

        vm.startPrank(seller);

        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);
        tradeContract.listOrder(1000, address(token));
        
        bytes32 messageHashh = keccak256(abi.encodePacked(address(2) , message)); 
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh)); 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v); 
        address recoveredAddress =  messageHash.recover(signature);
        assertEq( recoveredAddress , seller);

        vm.stopPrank();
        
        vm.startPrank(buyer);
        //Buyer's Message Is Different
        uint256 buyersMessage = 456;
        tradeContract.registerBuyer(1, buyersMessage);

        vm.stopPrank();
        
        vm.prank(seller);
        tradeContract.releaseFunds(1, signature , buyer);
    }
    
    // Failing Test : when the funds already got released.
    function testFailForAlreadyReleasedFunds() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        address buyer = address(2);

        deal(seller , 2 ether);
        uint256 message = 456;

        vm.startPrank(seller);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        bytes32 messageHashh = keccak256(abi.encodePacked(address(2) ,message)); 
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh)); 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v); 
        address recoveredAddress =  messageHash.recover(signature);
        assertEq( recoveredAddress , seller);

        vm.stopPrank();
        
        vm.startPrank(buyer);

        tradeContract.registerBuyer(1, message);

        vm.stopPrank();

        vm.prank(seller);
        tradeContract.releaseFunds(1, signature , buyer);
        assertEq(buyer.balance, 1 ether); 
        assertEq(address(seller).balance, 1 ether); 

        vm.prank(address(3));
        //Funds are already released for orderId = 1
        tradeContract.registerBuyer(1, 456);  
        
    }

       // Failing Test : when the buyer tries to register to an Invalid Order Id   
    function testFailBuyersInvalidId() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        deal(seller , 2 ether);
        
        vm.prank(address(3));
        //orderid = 2 does not exist
        tradeContract.registerBuyer(2, 456);     
     }

    // Failing Test : when the same buyer tries to register himself agian
    function testFailBuyerRegistersAgian() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        deal(seller , 2 ether);

        vm.prank(seller);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        vm.startPrank(address(3));  
        tradeContract.registerBuyer(1, 456);
        //buyer tries to register again
        tradeContract.registerBuyer(1, 456);
        vm.stopPrank();
    }

    // Failing Test : when a buyer tries to release the funds
    function testFailBuyerCantReleaseFunds() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        address buyer = address(2);
        deal(seller , 2 ether);
        uint256 message = 456;

        vm.startPrank(seller);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        bytes32 messageHashh = keccak256(abi.encodePacked(address(2) ,message)); 
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh)); 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v); 
        address recoveredAddress =  messageHash.recover(signature);
        assertEq( recoveredAddress , seller);

        vm.stopPrank();
        
        //buyer = address(2)
        vm.startPrank(buyer);
        //Buyer tries  to release the funds  
        tradeContract.releaseFunds(1, signature , buyer); 

        vm.stopPrank();

    }
    
    // Failing Test : when the seller tries to register as the buyer
    function testFailSellerRegisterAsBuyer() public {
        vm.startPrank(address(5));
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(address(5), address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        //Seller tries to register as Buyer
        tradeContract.registerBuyer(1, 123);
        vm.stopPrank();
    }

   
}
