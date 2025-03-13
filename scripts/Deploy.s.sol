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

        vm.startBroadcast();

        // Implanta o contrato lógico
        FirmezaTokenv1 logic = new FirmezaTokenv1();

        // Cria um ProxyAdmin para gerenciar atualizações
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployerAddress);

        // Codifica a chamada de inicialização
       // bytes memory data = abi.encodeWithSignature(FirmezaTokenv1.initialize.selector, "");

        // Implanta o proxy apontando para o contrato lógico
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(logic),
            address(proxyAdmin),
            ""
        );


        console.log("Contrato logico em:", address(logic));
        console.log("ProxyAdmin em:", address(proxyAdmin));
        console.log("Proxy em:", address(proxy));
    }
}
