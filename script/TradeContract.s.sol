// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/TradeContract.sol";

contract TradeContractScript is Script {
    function setUp() public {}

    function run() public {
        //provide info at .env
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);
        
        console.log("Account" , account);

        vm.startBroadcast();
        //deploy contract
        TradeContract tradeContract = new TradeContract();
        vm.stopBroadcast();
    }
}
