// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
// import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
// import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol"; // Importa a interface

import {
    TransparentUpgradeableProxy,
    ProxyAdmin,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "src/FirmezaToken-v1.sol";
import "src/FirmezaToken-v2.sol";

contract TestFirmezaToken2 is Test {
    FirmezaTokenv1 public firmezav1;
    FirmezaTokenv2 public firmezav2;

    TransparentUpgradeableProxy public contractProxy;
    ProxyAdmin public proxyAdmin;

    address public owner;

    function setUp() public {
        owner = address(this); // Inicializa o owner com o endereço do contrato de teste
        vm.startPrank(owner);
        firmezav1 = new FirmezaTokenv1();
        proxyAdmin = new ProxyAdmin(owner); // Passa o owner como argumento para o ProxyAdmin
        contractProxy = new TransparentUpgradeableProxy(
            address(firmezav1),
            address(proxyAdmin),
            abi.encodeWithSelector(FirmezaTokenv1.initialize.selector, owner, address(0))
        );
        vm.stopPrank(); // Para o prank
    }

    function test_RunSetUp() public {
        // run setUp
    }

    function testTransparent() public {
        vm.startPrank(owner);
        firmezav2 = new FirmezaTokenv2();

        // Usa upgradeAndCall para realizar o upgrade
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(contractProxy)), // Converte para ITransparentUpgradeableProxy
            address(firmezav2),
            abi.encodeWithSelector(FirmezaTokenv2.initialize.selector) // Certifique-se de que a função initialize existe
        );

       // address implAddrV1 = address(firmezav1);
        //address implAddrV2 = proxyAdmin.(address(contractProxy)); // Obtém a implementação atual do proxy

        // assertEq(proxyAdmin.getProxyAdmin(address(contractProxy)), address(proxyAdmin)); // Verifica o admin do proxy
        // assertFalse(implAddrV1 == implAddrV2); // Verifica se a implementação foi atualizada

        vm.stopPrank(); // Para o prank
    }
}