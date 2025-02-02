//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
//import {LinkTokenMock} from "test/mocks/LinkTokenMock.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {LinkTokenInterface} from "test/interfaces/LinkTokenInterface.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256 subId, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        address account = helperConfig.getActiveNetworkConfig().account;
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256 subId, address) {
        console.logString("===================CreateSubscription=================== ");
        console.log("Creating subscription on chain id: %s", block.chainid);

        vm.startBroadcast(account);
        /**
         * @dev using mock as an interface here, so it works both in Anvil and real chains
         */
        subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subId: %s", subId);
        console.log("Please update the subId in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() external {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // equals 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        fundSubscription(config.vrfCoordinator, config.subscriptionId, config.linkAddr, FUND_AMOUNT, config.account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken,
        uint256 amount,
        address account
    ) public {
        console.logString("===================FundSubscription===================== ");
        console.log("Link token contract address: %s", linkToken);
        console.log("Funding subscription on chain id: %s", block.chainid);
        console.log("Using vrfCoordinator: %s", vrfCoordinator);
        console.log("Using subscriptionId: %s", subscriptionId);
        // uint256 balance = ERC20(linkToken).balanceOf(address(this));
        //console.log("LINK balance before transfer: %s", balance);

        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            /**
             * @dev if local => funding with ETH
             */
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, amount);
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(linkToken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkTokenInterface(linkToken).balanceOf(address(this)));
            console.log(address(this));
            console.log("==================================================");
            console.log("sender: %s", msg.sender);
            console.log("sender's balances before transfer:");
            console.log("ETH: %s", msg.sender.balance);
            console.log("LINK: %s", LinkTokenInterface(linkToken).balanceOf(msg.sender));

            vm.startBroadcast(account);
            LinkTokenInterface(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();

            console.log("==================================================");
            console.log("sender: %s", msg.sender);
            console.log("sender's balances after transfer:");
            console.log("ETH: %s", msg.sender.balance);
            console.log("LINK: %s", LinkTokenInterface(linkToken).balanceOf(msg.sender));
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address contractToAddToVrf) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getActiveNetworkConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        address account = helperConfig.getActiveNetworkConfig().account;
        addConsumer(contractToAddToVrf, vrfCoordinator, subId, account);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("===================AddConsumer======================== ");
        console.log("Adding consumer contract: %s to VRF coordinator", contractToAddToVrf);
        console.log("Using vrfCoordinator: %s", vrfCoordinator);
        console.log("Using subscriptionId: %s", subId);
        console.log("On chain: %s", block.chainid);
        vm.startBroadcast(account);
        /**
         * @dev using mock as an interface here, so it works both in Anvil and real chains
         */
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployedRaffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployedRaffle);
    }
}
