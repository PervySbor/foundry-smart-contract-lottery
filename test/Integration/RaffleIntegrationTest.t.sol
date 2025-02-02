//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription} from "script/Interactions.s.sol";
import {LinkTokenInterface} from "test/interfaces/LinkTokenInterface.sol";

contract RaffleIntegrationTest is Test, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    Raffle public raffle;
    HelperConfig public helperConfig;
    CreateSubscription public createSubscription;
    FundSubscription public fundSubscription;

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
    }

    function testNothing() public {}

    function testCreateAndFundSubscription() public {
        address linkAddress = helperConfig.getActiveNetworkConfig().linkAddr;
        address account = helperConfig.getActiveNetworkConfig().account;
        console.log("==================================================");
        console.log("sender: %s", msg.sender);
        console.log("sender's balances before transfer:");
        console.log("ETH: %s", msg.sender.balance);
        console.log("LINK: %s", LinkTokenInterface(linkAddress).balanceOf(msg.sender));

        (uint256 subscriptionId, address vrfCoordinator) = createSubscription.createSubscriptionUsingConfig();
        fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, linkAddress, FUND_AMOUNT, account);
    }
}
