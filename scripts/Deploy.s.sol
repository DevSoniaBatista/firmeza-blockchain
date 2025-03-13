// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {console} from "forge-std/console.sol";

import "src/FirmezaToken-v1.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Unlock the wallet
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the logic contract
        FirmezaTokenv1 logic = new FirmezaTokenv1();

        // Create a ProxyAdmin to manage upgrades
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployerAddress);
        bytes memory data = abi.encodeWithSignature("initialize()", "");

        // Deploy the proxy pointing to the logic contract
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(logic),
            address(proxyAdmin),
            data
        );

        console.log("wallet:", address(deployerAddress));
        console.log("Logic contract at:", address(logic));
        console.log("ProxyAdmin at:", address(proxyAdmin));
        console.log("Proxy at:", address(proxy));
    }
}
