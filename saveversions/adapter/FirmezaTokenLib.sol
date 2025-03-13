// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library FirmezaTokenLib {

    // Estruturas de Dados
    struct Property {
        uint256 propertyId;
        string metadataURI;
        uint256 propertyValue; // Valor total do imóvel
        uint256 totalTokens; // Quantidade total de tokens representando o imóvel
        uint256 availableTokensInvestors;
        uint256 availableTokensBuyer;
        uint256 percentageBuyer;
        uint256 percentageInvestors;
        address seller; // Vendedor inicial do imóvel
        bool fundingComplete; // Indica se a captação de investidores foi concluída
        bool availablePurchase;
    }

    struct Rent {
        uint256 propertyId;
        uint256 percentageRentCalc;
        uint256 initialRentValue; // Valor do aluguel inicial
        uint256 currentRentValue;
        uint256 currentRentAsOwnerValue;
        uint256 startDate;
        uint256 nextDatePaymentRent;
        uint256 nextDateAdjustment;
        address renter; // locatário (renter)
    }

    enum Profile {
        ADMIN,
        SELLER,
        RENTER,
        INVESTOR
    } //0,1,2,3

    struct Investor {
        address wallet;
        uint256 propertyTokens; // Quantidade de tokens que o investidor possui da propriedade
        uint256 rentYield; // Rentabilidade acumulada do aluguel
        uint256 rentYieldFee; // Rentabilidade acumulada do aluguel
        uint256 nextRentPayment;
        uint256 capitalValue; // Valor total de compras efetuadas
        uint256 rePurchasedTokens; //Tokens recomprados pelo Inquilino
        uint256 percentageInvested;
        Profile profile;
    }

   struct Investment {
        address investor;  // Armazena o investidor que possui os tokens de propriedade
        Property property;   // Armazena as informaç�es sobre a propriedade
        uint256 currentTokens;     // Quantidade de tokens da propriedade atual para o investidor
    }


    // Eventos
    // event PropertyMinted(uint256 propertyId, address seller, uint256 totalTokens, uint256 propertyValue, uint256 date);
    event InvestorJoined(
        uint256 indexed propertyId,
        address indexed investor,
        uint256 tokensInvested,
        uint256 capitalValue,
        uint256 date
    );
    event DistributionToInvestor(
        uint256 indexed propertyId,
        address indexed investor,
        uint256 amount,
        uint256 amountFee,
        uint256 valueDiscount,
        uint256 date
    );
    event TokensPurchased(
        uint256 indexed propertyId,
        address buyer,
        uint256 tokensPurchased,
        uint256 amountPaid,
        uint256 date
    );
    event RentAdjustmentByPurchase(
        address admin,
        uint256 indexed propertyId,
        uint256 currentRentValue,
        uint256 percentAdjustment,
        uint256 newRentValue,
        uint256 date
    );
    event RentAdjustmentByIGPM(
        address admin,
        uint256 indexed propertyId,
        uint256 currentRentValue,
        uint256 percentAdjustment,
        uint256 newRentValue,
        uint256 date
    );
    event RentalPaymentReceived(
        uint256 indexed propertyId,
        uint256 amount,
        uint256 amountRenter,
        uint256 datePaymentRentExpected,
        uint256 datePaymentRent
    );
  
}
