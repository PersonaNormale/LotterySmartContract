// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subID,) = createSubscription(vrfCoordinator, account);

        return (subID, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console2.log("Creating Subscription on Chain ID: %s", block.chainid);

        vm.startBroadcast(account);
        uint256 subID = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console2.log("Your Subscription ID is: %", subID);
        console2.log("Please Update your Subscription ID in HelperConfig.s.sol.");

        return (subID, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 300 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig config = new HelperConfig();

        address vrfCoordinator = config.getConfig().vrfCoordinator;
        uint256 subscriptionID = config.getConfig().subscriptionID;
        address linkToken = config.getConfig().link;
        address account = config.getConfig().account;

        fundSubscription(vrfCoordinator, subscriptionID, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionID, address linkToken, address account)
        public
    {
        console2.log("Funding Subscription: ", subscriptionID);
        console2.log("Using VRF Coordinator: ", vrfCoordinator);
        console2.log("On Chain ID: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionID, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionID));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subID = helperConfig.getConfig().subscriptionID;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinator, subID, account);
    }

    function addConsumer(address contractToAddVRF, address vrfCoordinator, uint256 subID, address account) public {
        console2.log("Adding Consumer Contract: ", contractToAddVRF);
        console2.log("To VRF Coordinator: ", vrfCoordinator);
        console2.log("On Chain ID: ", block.chainid);
        vm.startBroadcast(account);

        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subID, contractToAddVRF);

        vm.stopBroadcast();
    }
}
