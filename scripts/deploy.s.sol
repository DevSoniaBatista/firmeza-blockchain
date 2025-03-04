// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FirmezaTokenv7c.sol";

contract FirmezaTokenv7cScript is Script {
    function setUp() public {}

    function run() public returns (FirmezaTokenv7c token) {
        // load variables from envinronment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        // deploying the contract
        vm.startBroadcast(deployerPrivateKey);

        token = new FirmezaToken();

        vm.stopBroadcast();
    }
}