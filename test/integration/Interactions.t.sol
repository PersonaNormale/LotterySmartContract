// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract InteractionsTest is Test, CodeConstants {
    HelperConfig helperConfig;
    LinkToken linkToken;
    VRFCoordinatorV2_5Mock vrfCoordinator;
    address payable deployer;
    uint96 DEPLOYER_BASE_BALANCE = 100 ether;
    uint96 baseFee = 0.25 ether;
    uint96 gasPriceLink = 1e9;
    int256 weiPerUnitLink = 4e16;

    function setUp() external {
        deployer = payable(makeAddr("deployer"));
        vm.deal(deployer, DEPLOYER_BASE_BALANCE);

        vrfCoordinator = new VRFCoordinatorV2_5Mock(baseFee, gasPriceLink, weiPerUnitLink);

        linkToken = new LinkToken();

        helperConfig = new HelperConfig();
    }

    function testCreateSubscription() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();

        // Act
        (uint256 subId, address coordinator) = createSubscription.createSubscription(address(vrfCoordinator), deployer);

        // Assert
        assertNotEq(subId, 0);
        assertEq(coordinator, address(vrfCoordinator));
    }

    function testFundSubscription() public skipFork {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        FundSubscription fundSubscription = new FundSubscription();

        (uint256 subId,) = createSubscription.createSubscription(address(vrfCoordinator), deployer);

        // Act
        fundSubscription.fundSubscription(address(vrfCoordinator), subId, address(linkToken), deployer);

        // Assert
        (uint96 balance,,,,) = vrfCoordinator.getSubscription(subId);
        assertEq(balance, fundSubscription.FUND_AMOUNT()); // FUND_AMOUNT == 3 LINK
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }

        _;
    }
}
