// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC7527Agency, ERC7527App, ERC7527Factory} from "../src/ERC7527.sol";
import {IERC7527App} from "../src/interfaces/IERC7527App.sol";
import {IERC7527Agency, Asset} from "../src/interfaces/IERC7527Agency.sol";
import {IERC7527Factory, AgencySettings, AppSettings} from "../src/interfaces/IERC7527Factory.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {DotAgencyNFT} from "../src/DotAgencyNFT.sol";
import {PremiumFunction} from "../src/PremiumFunction.sol";
import "../src/WrapCoin.sol";

contract ImplementationScript is Script {
    function run() public returns (
        ERC7527Agency agency,
        ERC7527App app,
        IERC7527Factory factory,
        DotAgencyNFT dotAgencyNFT,
        WrapCoin wrapCoin,
        address wrapAgency
    ) {
        vm.startBroadcast();

        wrapCoin = new WrapCoin("WrapCoin", "WRAP");
        agency = new ERC7527Agency();
        app = new ERC7527App();
        factory = new ERC7527Factory();

        dotAgencyNFT = new DotAgencyNFT(
            "DotAgencyNFT",
            "DANFT",
            msg.sender,
            address(agency),
            address(app),
            address(factory),
            address(wrapCoin)
        );

        address to = msg.sender;
        uint256 maxPremium = dotAgencyNFT.getMaxPremium();
        uint256 tokenId = dotAgencyNFT.mint{value: maxPremium}(to);
        Asset memory asset = Asset({
            currency: address(0),
            basePremium: 1 ether,
            feeRecipient: address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            mintFeePercent: uint16(5),
            burnFeePercent: uint16(5)
            });


        dotAgencyNFT.deployWrap(asset, tokenId);
        wrapAgency = dotAgencyNFT.getWrap(tokenId);

        vm.stopBroadcast();
    }
}

contract DotAgencyNFTScript is Script {
    function run() public returns (uint256 tokenId, uint256 maxPremium, address wrapAgency) {
        // The address of the deployed DotAgencyNFT contract
        address dotAgencyNFTAddress = 0x6e374a88Ca77981Ca2c6502F164ADb8ACe9f7BB6;

        // The address to mint the NFT to
        address to = msg.sender;

        // Start broadcasting the transaction
        vm.startBroadcast();

        // Create an instance of the DotAgencyNFT contract
        DotAgencyNFT dotAgencyNFT = DotAgencyNFT(dotAgencyNFTAddress);

        // Get the maximum premium value to send with the mint transaction
        maxPremium = dotAgencyNFT.getMaxPremium();


        tokenId = dotAgencyNFT.mint{value: maxPremium}(to);

        Asset memory asset = Asset({
            currency: address(0),
            basePremium: 1 ether,
            feeRecipient: address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            mintFeePercent: uint16(5),
            burnFeePercent: uint16(5)
        });


        dotAgencyNFT.deployWrap(asset, tokenId);
        wrapAgency = dotAgencyNFT.getWrap(tokenId);

        // Stop broadcasting the transaction
        vm.stopBroadcast();
    }
}

contract AgencyWrapScript is Script {
    ERC7527Agency public agency;

    function setUp() public {
        // 通过地址实例化 ERC7527Agency 合约
        agency = ERC7527Agency(payable(0x137F08d546D1B5f24b6e991a09B1de9482F39259));
    }

    function run() public returns(uint256 totalSupply) {
        vm.startBroadcast();
        uint256 tokenId = 3;
        address to = msg.sender;
        (address _app, Asset memory _asset,) = agency.getStrategy();
        totalSupply = IERC721Enumerable(_app).totalSupply();

        bytes memory data = abi.encode(tokenId);

        uint256 valueToSend = 2 ether;

        // 直接调用 agency 的 wrap 函数
        (bool success, bytes memory result) = address(agency).call{value: valueToSend}(
            abi.encodeWithSignature("wrap(address,bytes)", to, data)
        );

        require(success, "Wrap function call failed");

        // 将 bytes 转换为 uint256
        tokenId = abi.decode(result, (uint256));

        vm.stopBroadcast();
    }
}


contract AgencyUnwrapScript is Script {
    ERC7527Agency public agency;

    function setUp() public {
        // 通过地址实例化 ERC7527Agency 合约
        agency = ERC7527Agency(payable(0x137F08d546D1B5f24b6e991a09B1de9482F39259));
    }


    function run() public returns(uint256 totalSupply) {
        vm.startBroadcast();

        uint256 tokenId = 1;
        address to = msg.sender;

        bytes memory data = abi.encode(tokenId);

        uint256 valueToSend = 0 ether;

        // 直接调用 agency 的 unwrap 函数
        (bool success, ) = address(agency).call{value: valueToSend}(
            abi.encodeWithSignature("unwrap(address,uint256,bytes)", to, tokenId, data)
        );

        require(success, "Unwrap function call failed");

        (address _app, Asset memory _asset,) = agency.getStrategy();
        totalSupply = IERC721Enumerable(_app).totalSupply();

        vm.stopBroadcast();
    }
}
