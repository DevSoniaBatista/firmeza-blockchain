// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";

import "src/FirmezaToken-v1.sol";
import "src/FirmezaToken-v2.sol";


import {
    TransparentUpgradeableProxy,
    ProxyAdmin,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TestFirmezaToken is Test {
    FirmezaTokenv1 public firmezav1;

    TransparentUpgradeableProxy public contractProxy;
    address public owner;

    function setUp() public {
        vm.startPrank(owner);
        firmezav1 = new FirmezaTokenv1();
       // firmezav1.initialize();
        contractProxy = new TransparentUpgradeableProxy(address(firmezav1), owner, "");

       console.log("Contract proxy", address(contractProxy));
        vm.stopPrank();
}
    function test_RunSetUp() public {
        // run setUp
    }

       function upgradetoV2() internal {
        vm.startPrank(owner);
        //upgrading steps
        // 1. deploy the new implementation
        // 2. Call the ProxyAdmin upgrade function
        // 2a. ProxyAdmin will forward the call to the proxy and upgrade
        //This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 data = vm.load(address(contractProxy), adminSlot);

        FirmezaTokenv2 firmezav2 = new FirmezaTokenv2();
        //uint256 initialNumber = 222;
        bytes memory initData = abi.encodeWithSelector(FirmezaTokenv2.initialize.selector, "");

        address proxyAdmin = address(uint160(uint256(data)));
        ProxyAdmin(proxyAdmin).upgradeAndCall(
            ITransparentUpgradeableProxy(address(contractProxy)), address(firmezav2), initData
        );
        vm.stopPrank();
    }

    function test_upgradeToV2() public {
        upgradetoV2();
       // assertEq(FirmezaTokenv2(address(contractProxy))., 222);

    }

}
