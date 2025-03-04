// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FirmezaTokenLib.sol";

interface IFirmezaToken {

    function mintProperty(string memory _metadataURI, uint256 _propertyValue, address _seller) external;
    function setRentDatesAndRenter(uint256 _propertyId, uint256 _startDate, address _renter) external ;    
    function setRentAdjustment(uint256 _propertyId, string memory _percentAdjustment) external;
    function investInProperty(uint256 _propertyId, address _investor, uint256 _tokensToBuy) external;
    function receiveRentalPayment(uint256 _propertyId, uint256 _amount) external;
    function purchaseTokens(uint256 _propertyId, uint256 _tokensToPurchase, uint256 _purchaseDate) external;
    function getPropertyDetails(uint256 _propertyId) external view returns (FirmezaTokenLib.Property memory);
    function getRentDetails(uint256 _propertyId) external view returns (FirmezaTokenLib.Rent memory);
    function getInvestorDetails(uint256 _propertyId, address _investor) external view returns (FirmezaTokenLib.Investor memory);
    function getInvestorsList(uint256 _propertyId) external view returns (FirmezaTokenLib.Investor[] memory) ;
    function setPercentageRent(string memory _percentageRent) external;
    function setInitialValueRent(uint256 _propertyId, uint256 _valueRent) external;
   
}