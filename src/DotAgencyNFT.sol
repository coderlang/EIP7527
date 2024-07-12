// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PremiumFunction.sol";
import {IERC7527Agency, Asset} from "./interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "./interfaces/IERC7527Factory.sol";
import "./WrapCoin.sol";

contract DotAgencyNFT is ERC721Enumerable, Ownable {
    uint256 public tokenIdCounter;
    uint256 public basePremium;
    address public agency;
    address public app;
    address public factory;
    mapping(uint256 => address) public tokenToWrapAgency;
    uint256 public wrapCoinAmount = 5000;
    address public wrapCoinAddress = address(0);
    address public wrapCoinClaim = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    address public premiumDAOVault = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
    address public swapLPRewardVault = address(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
    address public NFTStakingRewardVault = address(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);

    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner_,
        address agency_,
        address app_,
        address factory_,
        address wrapCoinAddress_
    ) ERC721(name_, symbol_) Ownable(initialOwner_) {
        basePremium = 1 ether;
        tokenIdCounter = 0;
        agency = agency_;
        app = app_;
        factory = factory_;
        wrapCoinAddress = wrapCoinAddress_;
    }

    function mint(address to) public payable returns (uint256) {
        uint256 premium = getPremium();
        require(msg.value >= premium, "Insufficient funds to cover the premium");

        tokenIdCounter++;
        uint256 tokenId = tokenIdCounter;
        _mint(to, tokenId);

        if (msg.value > premium) {
            payable(msg.sender).transfer(msg.value - premium);
        }

        if (tokenId < 100_001) {
            uint256 dotAgencyDirect = (wrapCoinAmount * 4) / 100;
            uint256 dotAgencyVested = (wrapCoinAmount * 16) / 100;
            uint256 posStakingAmount = (wrapCoinAmount * 40) / 100;
            uint256 ethWrapLPAmount = (wrapCoinAmount * 10) / 100;
            uint256 premiumDAOAmount = wrapCoinAmount - dotAgencyDirect - dotAgencyVested - posStakingAmount - ethWrapLPAmount;
            WrapCoin wrapCoin = WrapCoin(wrapCoinAddress);
            wrapCoin.mint(msg.sender, dotAgencyDirect);
            wrapCoin.mint(wrapCoinClaim, dotAgencyVested);
            wrapCoin.mint(premiumDAOVault, premiumDAOAmount);
            wrapCoin.mint(swapLPRewardVault, ethWrapLPAmount);
            wrapCoin.mint(NFTStakingRewardVault, posStakingAmount);
        }

        return tokenId;
    }

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
