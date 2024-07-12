// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PremiumFunction.sol";
import {IERC7527Agency, Asset} from "./interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "./interfaces/IERC7527Factory.sol";

contract DotAgencyNFT is ERC721Enumerable, Ownable {
    uint256 public tokenIdCounter;
    uint256 public basePremium;
    address public agency;
    address public app;
    address public factory;
    mapping(uint256 => address) public tokenToWrapAgency;

    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner_,
        address agency_,
        address app_,
        address factory_
    ) ERC721(name_, symbol_) Ownable(initialOwner_) {
        basePremium = 1 ether;
        tokenIdCounter = 0;
        agency = agency_;
        app = app_;
        factory = factory_;
    }

    // Function to mint a new token with premium transfer
    function mint(address to) public payable returns (uint256) {
        uint256 premium = getPremium();
        require(msg.value >= premium, "Insufficient funds to cover the premium");

        tokenIdCounter++;
        uint256 tokenId = tokenIdCounter;
        _mint(to, tokenId);

        // Refund excess payment
        if (msg.value > premium) {
            payable(msg.sender).transfer(msg.value - premium);
        }

        return tokenId;
    }

    // Function to withdraw the contract balance
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function deployWrap(Asset memory asset, uint256 tokenId) public {
        require(ownerOf(tokenId) != address(0), "ERC721: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "ERC721: Caller is not the owner");
        require(tokenToWrapAgency[tokenId] == address(0), "ERC721: Token already has an associated agency");

        AgencySettings memory agencySettings = AgencySettings({
            implementation: payable(agency),
            asset: asset,
            immutableData: bytes(""),
            initData: bytes("")
        });

        AppSettings memory appSettings = AppSettings({
            implementation: app,
            immutableData: bytes(""),
            initData: bytes("")
            });

        (, address wrapAgency) = IERC7527Factory(factory).deployWrap(
            agencySettings,
            appSettings,
            bytes("")
        );

        tokenToWrapAgency[tokenId] = wrapAgency;
    }

    function getWrap(uint256 tokenId) public view returns (address) {
        require(ownerOf(tokenId) != address(0), "ERC721: Token does not exist");
        return tokenToWrapAgency[tokenId];
    }

    function getPremium(uint256 blocksSinceDeploy) public view returns (uint256) {
        return PremiumFunction.getPremium(blocksSinceDeploy, basePremium);
    }

    function getPremium() public view returns (uint256) {
        return PremiumFunction.getPremium(block.number, basePremium);
    }

    function getMaxPremium() public view returns (uint256) {
        return PremiumFunction.maxPremium(basePremium);
    }
}
