// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC7527Agency, ERC7527App, ERC7527Factory} from "../src/ERC7527.sol";
import {IERC7527App} from "../src/interfaces/IERC7527App.sol";
import {IERC7527Agency, Asset} from "../src/interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "../src/interfaces/IERC7527Factory.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {DotAgencyNFT} from "../src/DotAgencyNFT.sol";
import {SimpleENSRegistry} from "../src/SimpleENSRegistry.sol";
import {SimpleENSResolver} from "../src/SimpleENSResolver.sol";

contract ImplementationScript is Script {
    function run() public returns (
        ERC7527Agency agency,
        ERC7527App app,
        IERC7527Factory factory,
        SimpleENSRegistry ensRegistry,
        SimpleENSResolver ensResolver,
        DotAgencyNFT dotAgencyNFT
    ) {
        vm.startBroadcast();

        agency = new ERC7527Agency();
        app = new ERC7527App();
        factory = new ERC7527Factory();
        ensRegistry = new SimpleENSRegistry();
        ensResolver = new SimpleENSResolver();

        bytes32 ensRootNode = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));

        dotAgencyNFT = new DotAgencyNFT(
            "DotAgencyNFT",
            "DANFT",
            msg.sender,
            address(agency),
            address(app),
            address(factory),
            address(ensRegistry),
            address(ensResolver),
            ensRootNode
        );

        vm.stopBroadcast();
    }
}

contract DotAgencyNFTScript is Script {
    function run() public returns (uint256 tokenId, uint256 maxPremium, uint256 premium, uint256 senderBalance, uint256 nftBalance) {
        // The address of the deployed DotAgencyNFT contract
        address dotAgencyNFTAddress = 0x5067457698Fd6Fa1C6964e416b3f42713513B3dD;

        // The address to mint the NFT to
        address to = msg.sender;

        // The ENS name and salt
        string memory ensName = "myensname";
        bytes32 salt = keccak256(abi.encodePacked("random_salt"));

        // Create a commitment
        bytes32 commitment = keccak256(abi.encodePacked(to, ensName, salt));

        // Start broadcasting the transaction
        vm.startBroadcast();

        // Create an instance of the DotAgencyNFT contract
        DotAgencyNFT dotAgencyNFT = DotAgencyNFT(dotAgencyNFTAddress);

        // Commit the ENS name
        dotAgencyNFT.commitENSName(commitment);

        // Get the maximum premium value to send with the mint transaction
        maxPremium = dotAgencyNFT.getMaxPremium();

        // Get the current premium value
        premium = dotAgencyNFT.getPremium();

        // Call the mint function
        tokenId = dotAgencyNFT.mint{value: maxPremium}(to, ensName, salt);

        // Get the sender's balance after minting
        senderBalance = msg.sender.balance;

        // Query the NFT balance of the sender
        nftBalance = dotAgencyNFT.balanceOf(msg.sender);

        // Stop broadcasting the transaction
        vm.stopBroadcast();
    }
}

contract AgenctWithAppScript is Script {
    Asset public asset;
    AgencySettings public agencySettings;
    AppSettings public appSettings;

    address public agency;
    address public app;
    address public factory;

    function setUp() public {
        agency = address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        app = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        factory = address(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

        asset = Asset({
            currency: address(0),
            basePremium: 1 ether,
            feeRecipient: address(1),
            mintFeePercent: uint16(10),
            burnFeePercent: uint16(10)
        });

        agencySettings = AgencySettings({
            implementation: payable(agency),
            asset: asset,
            immutableData: bytes(""),
            initData: bytes("")
        });

        appSettings = AppSettings({implementation: app, immutableData: bytes(""), initData: bytes("")});
    }

    function run() public returns (address cloneAgency, address cloneApp) {
        vm.startBroadcast();
        (cloneApp, cloneAgency) = IERC7527Factory(factory).deployWrap(agencySettings, appSettings, bytes(""));
        vm.stopBroadcast();
    }
}
