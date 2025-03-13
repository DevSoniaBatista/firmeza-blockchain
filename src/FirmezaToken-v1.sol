// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {ERC1155PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FirmezaTokenLib.sol";

contract FirmezaTokenv1 is Initializable, ERC1155Upgradeable, ERC1155PausableUpgradeable, OwnableUpgradeable, ERC1155BurnableUpgradeable, ReentrancyGuard {

    // Estado do contrato
    uint256 private propertyIdCounter; 
    string internal baseURI;
    uint256 internal percentageRent;
    uint256 internal adminFeeRent;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
            _disableInitializers();
    }

    function initialize() public initializer {
        __ERC1155_init("FIRMEZA TOKEN");
        __ERC1155Pausable_init();
        __Ownable_init(msg.sender);
        __ERC1155Burnable_init();
           propertyIdCounter = 1; // Contador para IDs de propriedades
           percentageRent = 5; // Representado em base 1000 para 0.5%
           adminFeeRent = 10; // 10.0% representado em base 1000
           baseURI = "https://ipfs.io/ipfs/";
    }
    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155Upgradeable, ERC1155PausableUpgradeable)
    {
        super._update(from, to, ids, values);
    }

    // Mapeamentos
    mapping(uint256 => FirmezaTokenLib.Property) public properties; // Mapeia o ID da propriedade para os detalhes da propriedade
    mapping(uint256 => FirmezaTokenLib.Rent) public rents; // Mapeia o ID da propriedade para os detalhes do aluguel
    mapping(uint256 => mapping(address => FirmezaTokenLib.Investor)) private investors; // Mapeia o ID da propriedade e o endereço do investidor para os detalhes do investidor
    mapping(uint256 => address[]) private investorList; // Lista de investidores para cada propriedade

    function mintProperty(string memory _metadataURI, uint256 _propertyValue, address _seller) external onlyOwner {
        require(_seller != address(0), "Invalid seller address");

        uint256 propertyId = propertyIdCounter++;
        uint256 totalTokens = _propertyValue;

        FirmezaTokenLib.Property memory newProperty = FirmezaTokenLib.Property({
            propertyId: propertyId,
            metadataURI: string(abi.encodePacked(baseURI, _metadataURI)),
            propertyValue: _propertyValue * 100,
            totalTokens: totalTokens,
            availableTokensInvestors: totalTokens,
            availableTokensBuyer: totalTokens,
            percentageBuyer: 0,
            percentageInvestors: 0,
            seller: _seller,
            fundingComplete: false,
            availablePurchase: true
        });

        properties[propertyId] = newProperty;
        investorList[propertyId].push(_seller);

        FirmezaTokenLib.Investor memory initialInvestor = FirmezaTokenLib.Investor({
            wallet: _seller,
            propertyTokens: totalTokens,
            rentYield: 0,
            rentYieldFee: 0,
            nextRentPayment: 0,
            capitalValue: _propertyValue * 100,
            rePurchasedTokens: 0,
            percentageInvested: 10000,
            profile: FirmezaTokenLib.Profile.SELLER
        });

        investors[propertyId][_seller] = initialInvestor;

        _mint(_seller, propertyId, totalTokens, "");

        setRentValues(propertyId);
    }

    function setRentValues(uint256 _propertyId) internal {
        _validatePropertyExists(_propertyId);

        FirmezaTokenLib.Property storage property = properties[_propertyId];
        uint256 calculatedRent = (property.propertyValue * percentageRent) / 1000;

        rents[_propertyId] = FirmezaTokenLib.Rent({
            propertyId: _propertyId,
            initialRentValue: calculatedRent,
            currentRentValue: calculatedRent,
            currentRentAsOwnerValue: calculatedRent,
            percentageRentCalc: percentageRent,
            startDate: 0,
            nextDatePaymentRent: 0,
            nextDateAdjustment: 0,
            renter: address(0)
        });
    }

    function setRentDatesAndRenter(uint256 _propertyId, uint256 _startDate, address _renter) external onlyOwner {
        _validatePropertyExists(_propertyId);
        require(_renter != address(0), "Invalid Renter Address");

        uint256 startDate = _startDate == 0 ? block.timestamp : _startDate;

        rents[_propertyId].startDate = startDate;
        rents[_propertyId].nextDatePaymentRent = startDate + 30 days; // Adiciona 30 dias
        rents[_propertyId].nextDateAdjustment = startDate + 365 days; // Adiciona 365 dias
        rents[_propertyId].renter = _renter;
    }

    function setRentAdjustment(uint256 _propertyId, string memory _percentAdjustment) external onlyOwner {
        _validatePropertyExists(_propertyId);

        FirmezaTokenLib.Property storage property = properties[_propertyId];
        FirmezaTokenLib.Rent storage rent = rents[_propertyId];

        uint256 percentAdjustment = stringToUint(_percentAdjustment);
      //  if (percentAdjustment == 0) {
            // retorna o valor de reajuste do Oraculo
            // percentValue = stringToUint(_igpmOracle.getStringIGPM12Months());
           // percentAdjustment = 687; // 6.87% por exemplo
            //rent.nextDateAdjustment = block.timestamp + 365 days;
    //    }

        if (percentAdjustment > 0) {
            rent.nextDateAdjustment = block.timestamp + 365 days;
        }

        // Aplica o ajuste percentual (escala de 10000 para precisão de 2 casas decimais)
        rent.currentRentValue = (rent.currentRentValue * (10000 + percentAdjustment)) / 10000;

        // Calcula o novo valor de aluguel para o proprietário
        rent.currentRentAsOwnerValue = (rent.currentRentValue * (10000 - property.percentageBuyer)) / 10000;

        emit FirmezaTokenLib.RentAdjustmentByIGPM(
            tx.origin,
            _propertyId,
            rent.currentRentValue,
            percentAdjustment,
            rent.currentRentAsOwnerValue,
            block.timestamp
        );
    }

    function investInProperty(uint256 _propertyId, address _investor, uint256 _tokensToBuy) external {
        _validatePropertyExists(_propertyId);

        FirmezaTokenLib.Property storage property = properties[_propertyId];
        FirmezaTokenLib.Rent storage rent = rents[_propertyId];

        require(!property.fundingComplete, "Property funding is already complete");
        require(property.availableTokensInvestors >= _tokensToBuy, "Not enough tokens available");
        require(_investor != address(0), "Invalid investor address");

        address seller = property.seller;
        FirmezaTokenLib.Investor storage sellerInvestor = investors[_propertyId][seller];

        require(sellerInvestor.propertyTokens >= _tokensToBuy, "Seller does not have enough tokens");

        // Transferência segura dos tokens
        _safeTransferFrom(seller, _investor, _propertyId, _tokensToBuy, "");

        uint256 tokensToDistribute = property.totalTokens;

        // Atualizar saldo do vendedor
        unchecked {
            sellerInvestor.propertyTokens -= _tokensToBuy;
        }
        sellerInvestor.rePurchasedTokens += _tokensToBuy;

        // Atualizar saldo disponível da propriedade
        unchecked {
            property.availableTokensInvestors -= _tokensToBuy;
        }

        // Atualizar ou adicionar investidor
        FirmezaTokenLib.Investor storage investor = investors[_propertyId][_investor];

        if (investor.wallet != address(0)) {
            investor.propertyTokens += _tokensToBuy;
            investor.capitalValue += (_tokensToBuy * property.propertyValue) / tokensToDistribute;
        } else {
            investorList[_propertyId].push(_investor);
            investors[_propertyId][_investor] = FirmezaTokenLib.Investor({
                wallet: _investor,
                propertyTokens: _tokensToBuy,
                rentYield: 0,
                rentYieldFee: 0,
                nextRentPayment: 0,
                capitalValue: (_tokensToBuy * property.propertyValue) / tokensToDistribute,
                rePurchasedTokens: 0,
                percentageInvested: (_tokensToBuy * 10000) / tokensToDistribute, // 68,45% -> 6845
                profile: FirmezaTokenLib.Profile.INVESTOR
            });
        }

        // Atualizar porcentagens de investimento
        investor.percentageInvested = (investor.propertyTokens * 10000) / tokensToDistribute;
        sellerInvestor.percentageInvested = (sellerInvestor.propertyTokens * 10000) / tokensToDistribute;
        property.percentageInvestors += (_tokensToBuy * 10000) / tokensToDistribute;

        uint256 investorShare = investor.propertyTokens;
        uint256 distributionAmount = ((rent.currentRentAsOwnerValue / 100) * investorShare) / tokensToDistribute;
        investor.nextRentPayment = distributionAmount * 100;

        uint256 sellerShare = sellerInvestor.propertyTokens;
        uint256 distributionAmountSeller = ((rent.currentRentAsOwnerValue / 100) * sellerShare) / tokensToDistribute;

        sellerInvestor.nextRentPayment = distributionAmountSeller * 100;

        // Verificar se o funding foi concluído
        if (property.availableTokensInvestors == 0) {
            property.fundingComplete = true;
            property.percentageInvestors = 10000;
        }

        emit FirmezaTokenLib.InvestorJoined(
            _propertyId,
            _investor,
            _tokensToBuy,
            investor.capitalValue,
            block.timestamp
        );
    }

    function receiveRentalPayment(uint256 _propertyId, uint256 _amount) external nonReentrant onlyOwner {
        require(_amount > 0, "Payment amount must be greater than zero");
        _validatePropertyExists(_propertyId);

        FirmezaTokenLib.Property storage property = properties[_propertyId];
        FirmezaTokenLib.Rent storage rent = rents[_propertyId];

        require(rent.renter != address(0), "Renter not defined yet.");
        require(_amount >= rent.currentRentAsOwnerValue, "Insufficient rental payment");
        require(property.availablePurchase, "Purchase already completed");

        _amount = rent.currentRentValue;
        uint256 totalTokens = property.totalTokens;
        uint256 adminFee = (_amount * adminFeeRent) / 100;

        uint256 amountForInvestors = _amount - adminFee;

        // Atualizar a data do próximo pagamento
        uint256 actualDatePaymentRent = rent.nextDatePaymentRent;
        rent.nextDatePaymentRent = actualDatePaymentRent + 30 days;

        emit FirmezaTokenLib.RentalPaymentReceived(
            _propertyId,
            _amount,
            rent.currentRentAsOwnerValue,
            actualDatePaymentRent,
            block.timestamp
        );

        address[] storage investorsArray = investorList[_propertyId];
        uint256 investorsCount = investorsArray.length;

        for (uint256 i = 0; i < investorsCount; i++) {
            address investorAddress = investorsArray[i];
            FirmezaTokenLib.Investor storage investor = investors[_propertyId][investorAddress];

            uint256 distributionAmount = (_amount * investor.propertyTokens) / totalTokens;
            uint256 distributionAmountFee = (amountForInvestors * investor.propertyTokens) / totalTokens;

            investor.rentYield += distributionAmount;
            investor.rentYieldFee += distributionAmountFee;
            investor.nextRentPayment = distributionAmount;

            emit FirmezaTokenLib.DistributionToInvestor(
                _propertyId,
                investor.wallet,
                distributionAmount,
                distributionAmountFee,
                (distributionAmount - distributionAmountFee),
                block.timestamp
            );
        }
    }

    function purchaseTokens(uint256 _propertyId, uint256 _tokensToPurchase, uint256 _purchaseDate) external nonReentrant onlyOwner {
        _validatePropertyExists(_propertyId);
        require(_tokensToPurchase > 0, "Must purchase at least one token");

        FirmezaTokenLib.Property storage property = properties[_propertyId];
        FirmezaTokenLib.Rent storage rent = rents[_propertyId];

        require(rent.renter != address(0), "Renter need to be defined first");
        require(property.availablePurchase, "All tokens already purchased by buyer");

        address _buyer = rent.renter;
        uint256 totalTokens = property.totalTokens;

        uint256 totalTokensExcludingBuyer = 0;
        address[] storage investorsArray = investorList[_propertyId];

        // Calcular a soma total de tokens dos investidores (excluindo o comprador)
        for (uint256 i = 0; i < investorsArray.length; i++) {
            address investorAddress = investorsArray[i];
            if (investorAddress != _buyer) {
                totalTokensExcludingBuyer += investors[_propertyId][investorAddress].propertyTokens;
            }
        }

        require(totalTokensExcludingBuyer > 0, "No tokens available for transfer");

        // Transferir tokens proporcionalmente de todos os investidores para o comprador
        for (uint256 i = 0; i < investorsArray.length; i++) {
            address investorAddress = investorsArray[i];
            FirmezaTokenLib.Investor storage investor = investors[_propertyId][investorAddress];

            if (investorAddress != _buyer && investor.propertyTokens > 0) {
                uint256 tokensToSell = (_tokensToPurchase * investor.propertyTokens) / totalTokensExcludingBuyer;
                tokensToSell = tokensToSell > investor.propertyTokens ? investor.propertyTokens : tokensToSell; // Garante que não seja negativo

                if (tokensToSell > 0) {
                    _safeTransferFrom(investorAddress, _buyer, _propertyId, tokensToSell, "");
                    investor.propertyTokens -= tokensToSell;
                    investor.rePurchasedTokens += tokensToSell;
                    investor.percentageInvested = (investor.propertyTokens * 10000) / totalTokens;

                    uint256 investorShare = investor.propertyTokens;
                    uint256 distributionAmount = ((rent.currentRentAsOwnerValue / 100) * investorShare) / totalTokens;
                    investor.nextRentPayment = distributionAmount * 100;
                }
            }
        }

        // Atualizar ou adicionar o comprador como investidor
        FirmezaTokenLib.Investor storage buyerInvestor = investors[_propertyId][_buyer];

        if (buyerInvestor.wallet == address(0)) {
            investorList[_propertyId].push(_buyer);
            buyerInvestor.wallet = _buyer;
            buyerInvestor.propertyTokens = _tokensToPurchase;
            buyerInvestor.rentYield = 0;
            buyerInvestor.rentYieldFee = 0;
            buyerInvestor.capitalValue = calculateTokenCost(_propertyId) * _tokensToPurchase * 100;
            buyerInvestor.rePurchasedTokens = 0;
            buyerInvestor.percentageInvested = (_tokensToPurchase * 10000) / totalTokens;
            buyerInvestor.profile = FirmezaTokenLib.Profile.RENTER;
        } else {
            buyerInvestor.propertyTokens += _tokensToPurchase;
            buyerInvestor.capitalValue += calculateTokenCost(_propertyId) * _tokensToPurchase * 100;
            buyerInvestor.percentageInvested = (buyerInvestor.propertyTokens * 10000) / totalTokens;
        }
        
        property.availableTokensInvestors -= _tokensToPurchase;

        // Se o comprador adquiriu todos os tokens, a propriedade não pode mais ser comprada
        if (buyerInvestor.propertyTokens == totalTokens) {
            property.availablePurchase = false;
        }

        // Ajustar porcentagem do comprador e calcular novo valor de aluguel
        property.availableTokensBuyer -= _tokensToPurchase;

        uint256 percentPurchased = (_tokensToPurchase * 10000) / totalTokens;
        property.percentageBuyer += percentPurchased;
        rent.currentRentAsOwnerValue = (rent.currentRentValue * (10000 - property.percentageBuyer)) / 10000;

        if (_purchaseDate == 0) _purchaseDate = block.timestamp;
        uint256 calculatedToken = calculateTokenCost(_propertyId) * _tokensToPurchase;

        emit FirmezaTokenLib.TokensPurchased(_propertyId, _buyer, _tokensToPurchase, calculatedToken, _purchaseDate);

        emit FirmezaTokenLib.RentAdjustmentByPurchase(
            tx.origin,
            _propertyId,
            rent.currentRentValue,
            property.percentageBuyer,
            rent.currentRentAsOwnerValue,
            _purchaseDate
        );
    }

    function calculateTokenCost(uint256 _propertyId) internal view returns (uint256) {
        FirmezaTokenLib.Property storage property = properties[_propertyId];
        return (property.propertyValue / 100) / property.totalTokens;
    }

    function getPropertyDetails(uint256 _propertyId) external view returns (FirmezaTokenLib.Property memory) {
        return properties[_propertyId];
    }

    function getRentDetails(uint256 _propertyId) external view returns (FirmezaTokenLib.Rent memory) {
        return rents[_propertyId];
    }

    function getInvestorDetails(uint256 _propertyId, address _investor) external view returns (FirmezaTokenLib.Investor memory) {
        return investors[_propertyId][_investor];
    }

    function getInvestorsList(uint256 _propertyId) external view returns (FirmezaTokenLib.Investor[] memory) {
        address[] storage investorAddresses = investorList[_propertyId];
        FirmezaTokenLib.Investor[] memory investorInfoList = new FirmezaTokenLib.Investor[](investorAddresses.length);

        for (uint256 i = 0; i < investorAddresses.length; i++) {
            address investorAddress = investorAddresses[i];
            investorInfoList[i] = investors[_propertyId][investorAddress];
        }

        return investorInfoList;
    }

    function _validatePropertyExists(uint256 _propertyId) internal view {
        require(properties[_propertyId].propertyId == _propertyId, "Property does not exist");
    }

    function stringToUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        uint256 decimalPlaces = 0;
        bool decimalFound = false;

        for (uint256 i = 0; i < b.length; i++) {
            uint8 char = uint8(b[i]);

            if (char >= 48 && char <= 57) {
                // '0' a '9'
                result = result * 10 + (char - 48);
                if (decimalFound) {
                    decimalPlaces++;
                }
            } else if ((char == 46 || char == 44) && !decimalFound) {
                // '.' ou ','
                decimalFound = true;
            } else {
                revert("Invalid character");
            }
        }

        // Ajuste de escala para 2 casas decimais
        uint256 scale = (decimalPlaces == 0) ? 100 : (decimalPlaces == 1) ? 10 : 1;
        return result * scale;
    }

    function setPercentageRent(string memory _percentageRent) external onlyOwner {
        uint256 percent = stringToUint(_percentageRent);
        percentageRent = percent;
    }

    function setInitialValueRent(uint256 _propertyId, uint256 _valueRent) external onlyOwner {
        _validatePropertyExists(_propertyId);
        FirmezaTokenLib.Rent storage rent = rents[_propertyId];
        require(rent.renter == address(0), "Renter already defined. Is not possible change Rent Value");
        rents[_propertyId].initialRentValue = _valueRent;
        rents[_propertyId].currentRentValue = _valueRent;
        rents[_propertyId].currentRentAsOwnerValue = _valueRent;
        rents[_propertyId].percentageRentCalc = 0;
    }

}