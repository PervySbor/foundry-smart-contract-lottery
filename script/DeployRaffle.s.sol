//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console, Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    uint256 private constant ENTRANCE_FEE = 0.01 ether;
    uint256 private constant INTERVAL = 30; //in seconds
    uint32 private constant CALLBACK_GAS_LIMIT = 500000;
    uint256 private constant LINK_FUND_AMOUNT = 3 ether;

    address private i_VRFFeed;
    bytes32 private i_keyHash;

    function run() external {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        CreateSubscription subscriptionContract = new CreateSubscription();
        FundSubscription fundSubscriptionContract = new FundSubscription();
        AddConsumer addConsumerContract = new AddConsumer();

        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        if (config.subscriptionId == 0) {
            (config.subscriptionId, config.vrfCoordinator) =
                subscriptionContract.createSubscription(config.vrfCoordinator, config.account);

            fundSubscriptionContract.fundSubscription(
                config.vrfCoordinator, config.subscriptionId, config.linkAddr, LINK_FUND_AMOUNT, config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        addConsumerContract.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);
        return (raffle, helperConfig);
    }
}
