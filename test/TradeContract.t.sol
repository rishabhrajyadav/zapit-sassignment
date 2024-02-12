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
        vm.startPrank(address(5));
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(address(5), address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(order.seller, address(5));
        assertEq(token.balanceOf(address(5)), 1000);
    }

    // Test listing multiple orders using ERC20Token 
    function testListMultipleOrdersWithERC20token() public {
        vm.startPrank(address(5));
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(address(5), address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        vm.startPrank(address(4));
        token._mint(address(4), 100);
        token.approve(address(tradeContract), 100);
        assertEq(token.allowance(address(4), address(tradeContract)), 100);

        tradeContract.listOrder(100, address(token));
        vm.stopPrank();

        uint256 totalOrders = tradeContract.totalOrders(); 
        assertEq(totalOrders, 2);
    }

    // Test listing an order using Ether 
    function testListOrderWithEther() public {
        hoax(address(1) , 2 ether);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(address(1).balance, 1 ether);
        assertEq(order.amount, 1 );
        assertEq(order.seller, address(1));
        assertEq(uint(order.state), 1);
        assertEq(order.tokenAddress, address(0));
        assertEq(order.buyers.length, 0);
        assertEq(order.messages.length, 0);
    }

    // Test listing Multiple orders using Ether
    function testListMultipleOrdersWithEther() public {
        hoax(address(1) , 2 ether);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);

        hoax(address(3) , 4 ether);
        tradeContract.listOrder{value : 4 ether}(4 , etherAddress);
        
        uint256 totalOrders = tradeContract.totalOrders(); 
        assertEq(totalOrders, 2);
    }

    // Test listing Multiple orders using Both Ether and ERC20
    function testListMultipleOrdersWithEtherAndERC20() public {
        hoax(address(1) , 2 ether);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);

        vm.startPrank(address(5));
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(address(5), address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();
        
        uint256 totalOrders = tradeContract.totalOrders(); 
        assertEq(totalOrders, 2);
    }

     // Test registering a buyer
    function testRegisterBuyer() public {
        vm.startPrank(address(5));
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(address(5), address(tradeContract)), 1000);

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
        vm.startPrank(address(5));
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(address(5), address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        vm.prank(address(1));
        tradeContract.registerBuyer(1, 123);

        vm.prank(address(3));
        tradeContract.registerBuyer(1, 345);

        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(order.buyers.length, 2);
        assertEq(tradeContract.getMessages(1, address(1)), 123);
        assertEq(tradeContract.getMessages(1, address(3)), 345);
        assertEq(order.buyers[0], address(1));
        assertEq(order.buyers[1], address(3));
    }


    // Test fetching order details
    function testFetchOrderDetails() public {
        vm.startPrank(address(5));
        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(address(5), address(tradeContract)), 1000);

        tradeContract.listOrder(1000, address(token));
        vm.stopPrank();

        TradeContract.Order memory order = tradeContract.fetchOrderDetails(1);
        assertEq(order.amount, 1000);
        assertEq(order.seller, address(5));
        assertEq(uint(order.state), 1);
        assertEq(order.tokenAddress, address(token));
        assertEq(order.buyers.length, 0);
        assertEq(order.messages.length, 0);
        // Add more assertions based on the expected order details
    }

    // Test releasing Ether as funds  
    function testReleaseEtherFunds() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        deal(seller , 2 ether);
       
        vm.startPrank(seller);
        tradeContract.listOrder{value : 1 ether}(1 , etherAddress);
        
        bytes32 messageHashh = keccak256(abi.encodePacked(address(2) , uint(456))); //msg.sender = buyer's Address
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh)); 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v); // note the order here is different from line above.
        address recoveredAddress =  messageHash.recover(signature);
        assertEq( recoveredAddress , seller);

        vm.stopPrank();
        
        vm.startPrank(address(2));

        tradeContract.registerBuyer(1, 456);
        address recoveredAddress2 = tradeContract.recover2(messageHashh, signature);
        assertEq(recoveredAddress , recoveredAddress2);

        tradeContract.releaseFunds(1, signature);
        assertEq(address(2).balance, 1 ether); 
        assertEq(address(seller).balance, 1 ether); 

        vm.stopPrank();

        vm.startPrank(address(3));
        
        vm.expectRevert();
        tradeContract.registerBuyer(2, 456); //orderid = 2 does not exist
        address recoveredAddress3 = tradeContract.recover2(messageHashh, signature);
        assertEq(recoveredAddress , recoveredAddress3);

        vm.stopPrank();
    }

    // Test releasing ERC20 as funds 
    function testReleaseERC20Funds() public {
        uint256 privateKey = 123;
        address seller = vm.addr(privateKey);
        token._mint(seller, 1000);
       
        vm.startPrank(seller);

        token.approve(address(tradeContract), 1000);
        assertEq(token.allowance(seller, address(tradeContract)), 1000);
        tradeContract.listOrder(1000, address(token));
        
        bytes32 messageHashh = keccak256(abi.encodePacked(address(2) , uint(456))); //msg.sender = buyer's Address
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashh)); 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v); // note the order here is different from line above.
        address recoveredAddress =  messageHash.recover(signature);
        assertEq( recoveredAddress , seller);

        vm.stopPrank();
        
        vm.startPrank(address(2));

        tradeContract.registerBuyer(1, 456);
        address recoveredAddress2 = tradeContract.recover2(messageHashh, signature);
        assertEq(recoveredAddress , recoveredAddress2);

        tradeContract.releaseFunds(1, signature);
        assertEq(token.balanceOf(address(2)), 1000); 
        assertEq(token.balanceOf(seller), 0); 
        vm.stopPrank();
    }

   
}
