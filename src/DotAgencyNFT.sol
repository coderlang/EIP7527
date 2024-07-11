// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PremiumFunction.sol";
import {IERC7527Agency, Asset} from "./interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "./interfaces/IERC7527Factory.sol";
import "ens-contracts/contracts/registry/ENS.sol"; // Import ENS interface

contract DotAgencyNFT is ERC721Enumerable, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public deployBlock;
    uint256 public basePremium;
    address public agency;
    address public app;
    address public factory;
    ENS public ens;
    bytes32 public ensRootNode;
    mapping(uint256 => address) public tokenToWrapAgency;
    mapping(uint256 => string) public tokenIdToEnsName;
    mapping(string => uint256) public ensNameToTokenId;

    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner_,
        address agency_,
        address app_,
        address factory_,
        address ens_,
        bytes32 ensRootNode_
    ) ERC721(name_, symbol_) Ownable(initialOwner_) {
        deployBlock = block.number;
        basePremium = 1 ether;
        _tokenIdCounter = 0;
        agency = agency_;
        app = app_;
        factory = factory_;
        ens = ENS(ens_);
        ensRootNode = ensRootNode_;
    }

    // Function to mint a new token with premium transfer and ENS name
    function mint(address to, string memory ensName) public payable onlyOwner returns (uint256) {
        require(ensNameToTokenId[ensName] == 0, "ENS name already exists");

        uint256 currentBlock = block.number;
        uint256 premium = PremiumFunction.getPremium(currentBlock - deployBlock, basePremium);
        require(msg.value >= premium, "Insufficient funds to cover the premium");

        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        _mint(to, tokenId);

        // Associate ENS name with tokenId
        ensNameToTokenId[ensName] = tokenId;
        tokenIdToEnsName[tokenId] = ensName;

        // Register ENS name
        bytes32 label = keccak256(abi.encodePacked(ensName));
        bytes32 node = keccak256(abi.encodePacked(ensRootNode, label));
        ens.setSubnodeOwner(ensRootNode, label, to);
        ens.setResolver(node, to);

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

    function getPremium() public view returns (uint256) {
        uint256 currentBlock = block.number;
        return PremiumFunction.getPremium(currentBlock - deployBlock, basePremium);
    }

    // Function to get the maximum premium
    function getMaxPremium() public view returns (uint256) {
        return PremiumFunction.maxPremium(basePremium);
    }

    // Function to get ENS name associated with a tokenId
    function getEnsName(uint256 tokenId) public view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "ERC721: Token does not exist");
        return tokenIdToEnsName[tokenId];
    }

    // Function to get tokenId associated with an ENS name
    function getTokenIdByEnsName(string memory ensName) public view returns (uint256) {
        return ensNameToTokenId[ensName];
    }
}
