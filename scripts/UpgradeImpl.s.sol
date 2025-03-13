// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {console} from "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "src/FirmezaToken-v2.sol";

contract UpgradeImplScript is Script {
    function run() external {
        // Obtenha a chave privada do deployer a partir de uma variável de ambiente
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Desbloqueie a carteira do deployer
        vm.startBroadcast(deployerPrivateKey);

        // Deploy o novo contrato de lógica
        FirmezaTokenv2 newImpl = new FirmezaTokenv2();

        // Obtenha o endereço do contrato de proxy a partir de uma variável de ambiente
      //  address proxyAddress = vm.envAddress("0x61fBe15A14ab581DdF21656954DE74DB41D56Da3");
        address proxyAddress = address(0x61fBe15A14ab581DdF21656954DE74DB41D56Da3);

        // Obtenha o endereço do contrato de proxy admin a partir de uma variável de ambiente
       // address proxyAdminAddress = vm.envAddress("0xe93034e66dDa82Eaf62a5678C0D1634242D16880");

        address proxyAdminAddress = address(0xe93034e66dDa82Eaf62a5678C0D1634242D16880);

        bytes memory data = abi.encodeWithSignature("initialize()", "");

       //Verifique se o contrato de proxy já foi atualizado
        //if (ProxyAdmin(proxyAdminAddress).getProxyImplementation(proxyAddress) != address(newImpl)) {
            // Atualize o contrato de proxy
            ProxyAdmin(proxyAdminAddress).upgradeAndCall(
                ITransparentUpgradeableProxy(proxyAddress), 
                address(newImpl), 
                data
            );
       // }

        console.log("Carteira:", deployerAddress);
        console.log("Novo contrato de logica em:", address(newImpl));
        console.log("Contrato de proxy atualizado em:", proxyAddress);
    }
}