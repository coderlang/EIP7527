// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PremiumFunction.sol";
import {IERC7527Agency, Asset} from "./interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "./interfaces/IERC7527Factory.sol";
import "./SimpleENSRegistry.sol";
import "./SimpleENSResolver.sol";

contract DotAgencyNFT is ERC721Enumerable, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public deployBlock;
    uint256 public basePremium;
    address public agency;
    address public app;
    address public factory;
    SimpleENSRegistry public ensRegistry;
    SimpleENSResolver public ensResolver;
    bytes32 public ensRootNode;
    mapping(uint256 => address) public tokenToWrapAgency;
    mapping(uint256 => string) public tokenIdToEnsName;
    mapping(string => uint256) public ensNameToTokenId;
    mapping(bytes32 => Commitment) public commitments;

    struct Commitment {
        address committer;
        uint256 blockNumber;
    }

    uint256 public constant COMMITMENT_EXPIRATION = 128;

    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner_,
        address agency_,
        address app_,
        address factory_,
        address ensRegistry_,
        address ensResolver_,
        bytes32 ensRootNode_
    ) ERC721(name_, symbol_) Ownable(initialOwner_) {
        deployBlock = block.number;
        basePremium = 1 ether;
        _tokenIdCounter = 0;
        agency = agency_;
        app = app_;
        factory = factory_;
        ensRegistry = SimpleENSRegistry(ensRegistry_);
        ensResolver = SimpleENSResolver(ensResolver_);
        ensRootNode = ensRootNode_;
    }

    // Function to commit to an ENS name
    function commitENSName(bytes32 commitment) public {
        Commitment memory existingCommitment = commitments[commitment];

        if (existingCommitment.committer != address(0)) {
            require(block.number > existingCommitment.blockNumber + COMMITMENT_EXPIRATION, "Commitment still valid");
        }

        commitments[commitment] = Commitment({committer: msg.sender, blockNumber: block.number});
    }

    // Function to mint a new token with premium transfer and reveal ENS name
    function mint(address to, string memory ensName, bytes32 salt) public payable returns (uint256) {
        bytes32 commitment = keccak256(abi.encodePacked(to, ensName, salt));
        Commitment memory committed = commitments[commitment];

        require(committed.committer != address(0), "Invalid commitment");
        require(committed.committer == msg.sender, "Caller is not the committer");
        require(block.number <= committed.blockNumber + COMMITMENT_EXPIRATION, "Commitment has expired");

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

        // Register ENS name and set subnode owner
        bytes32 label = keccak256(abi.encodePacked(ensName));
        bytes32 node = keccak256(abi.encodePacked(ensRootNode, label));
        ensRegistry.register(label, address(this)); // Register under the contract's ownership
        ensRegistry.setSubnodeOwner(ensRootNode, label, address(this)); // Transfer ownership to the contract
        ensRegistry.transferOwnership(label, to); // Transfer ownership to the actual owner
        ensRegistry.setResolver(node, address(ensResolver));
        ensResolver.setAddr(node, to);

        // Mark commitment as used
        delete commitments[commitment];

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

    function deployWrap(Asset memory asset, uint256 tokenId, string memory subdomain) public {
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

        // Register subdomain
        string memory ensName = tokenIdToEnsName[tokenId];
        bytes32 label = keccak256(abi.encodePacked(ensName));
        bytes32 subdomainLabel = keccak256(abi.encodePacked(subdomain));
        bytes32 subdomainNode = keccak256(abi.encodePacked(keccak256(abi.encodePacked(ensRootNode, label)), subdomainLabel));

        ensRegistry.setSubnodeOwner(keccak256(abi.encodePacked(ensRootNode, label)), subdomainLabel, wrapAgency);
        ensResolver.setAddr(subdomainNode, wrapAgency);
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
