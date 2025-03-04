// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FirmezaTokenLib.sol";
import "./IFirmezaToken.sol";

contract FirmezaTokenAdapter {

    IFirmezaToken private firmeza;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function getImplementationAddress() external view returns (address){
        return address(firmeza);
    }

    function mintProperty(string memory _metadataURI, uint256 _propertyValue, address _seller) external  upgraded restricted {
        return firmeza.mintProperty(_metadataURI, _propertyValue, _seller);
    }

    function setRentDatesAndRenter(uint256 _propertyId, uint256 _startDate, address _renter) external  upgraded restricted {
        return firmeza.setRentDatesAndRenter(_propertyId, _startDate, _renter);
    }

    function setRentAdjustment(uint256 _propertyId, string memory _percentAdjustment) external  upgraded restricted {
        return firmeza.setRentAdjustment(_propertyId, _percentAdjustment);
    }

    function investInProperty(uint256 _propertyId, address _investor, uint256 _tokensToBuy) external  upgraded restricted {
        return firmeza.investInProperty(_propertyId, _investor, _tokensToBuy);
    }

    function receiveRentalPayment(uint256 _propertyId, uint256 _amount) external  upgraded restricted {
        return firmeza.receiveRentalPayment(_propertyId, _amount);
    }

    function purchaseTokens(uint256 _propertyId, uint256 _tokensToPurchase, uint256 _purchaseDate) external  upgraded restricted {
        return firmeza.purchaseTokens(_propertyId, _tokensToPurchase, _purchaseDate);
    } 

    function getPropertyDetails(uint256 _propertyId) external view upgraded returns (FirmezaTokenLib.Property memory)  {
        return firmeza.getPropertyDetails(_propertyId);
    }

    function getRentDetails(uint256 _propertyId) external view upgraded returns (FirmezaTokenLib.Rent memory){
        return firmeza.getRentDetails(_propertyId);
    }
    
    function getInvestorDetails(uint256 _propertyId, address _investor) external view upgraded returns (FirmezaTokenLib.Investor memory){
         return firmeza.getInvestorDetails(_propertyId, _investor);
    }
    
    function getInvestorsList(uint256 _propertyId) external view upgraded returns (FirmezaTokenLib.Investor[] memory) {
        return firmeza.getInvestorsList(_propertyId);
    }

    function setPercentageRent(string memory _percentageRent) external upgraded restricted {
        return firmeza.setPercentageRent(_percentageRent);
    }

    function setInitialValueRent(uint256 _propertyId, uint256 _valueRent) external upgraded restricted{
        return firmeza.setInitialValueRent(_propertyId, _valueRent);
    }

    modifier restricted(){
        require(owner == msg.sender, "You do not have permission");
        _;
    }

    modifier upgraded(){
        require( address(firmeza) != address(0), "You must upgrade first");
        _;
    }

    function upgrade( address newImplementation) external {
        require(msg.sender == owner, "You do not have permission");
        require(newImplementation != address(0), "Empty address is not permitted");
        firmeza = IFirmezaToken(newImplementation);
    }
}