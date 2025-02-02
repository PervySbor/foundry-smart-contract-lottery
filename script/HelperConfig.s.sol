//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 *  @notice This contract automaticaly selects chainlink VRF's address
 * for current chain
 */
import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 internal constant ETH_MAINNET_CHAIN_ID = 1;
    address internal constant ETH_MAINNET_LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    uint256 internal constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    address internal constant ETH_SEPOLIA_LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    /**
     * @dev The LINK provided by the Polygon Bridge is not ERC-677 compatible,
     *  @dev so you cannot use it with Chainlink services or oracle nodes.
     */
    //uint256 internal constant BNB_CHAIN_ID = 56;
    //address internal constant BNB_CHAIN_LINK_ADDRESS =
    uint256 internal constant ANVIL_CHAIN_ID = 31337;

    uint256 internal constant ENTRANCE_FEE = 0.01 ether;
    uint256 internal constant INTERVAL = 30; //in seconds
    uint256 internal constant SUBSCRIPTION_ID = 0;
    //101630672838009829741810970638149278588197349032244343236136849759809801912339;
    //105883548477720769771103458628655736802927049447604011585496973594056335356374;
    uint32 internal constant CALLBACK_GAS_LIMIT = 500000;

    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address linkAddr;
        address account;
    }

    /**
     * @dev keyHashes allow max gas fee = 500 Gwei
     */
    constructor() {
        s_NetworkConfigByChainId[ETH_MAINNET_CHAIN_ID] = getEthMainnetConfig();
        s_NetworkConfigByChainId[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        //s_NetworkConfigByChainId[BNB_CHAIN_ID] = getBNBConfig();
        s_VRFConfig = s_NetworkConfigByChainId[block.chainid];
    }

    NetworkConfig s_VRFConfig;
    mapping(uint256 chainId => NetworkConfig) private s_NetworkConfigByChainId;

    /**
     * Getters
     */
    function getActiveNetworkConfig() external returns (NetworkConfig memory) {
        if (s_NetworkConfigByChainId[block.chainid].vrfCoordinator != address(0)) {
            return s_NetworkConfigByChainId[block.chainid];
        } else if (block.chainid == ANVIL_CHAIN_ID) {
            s_NetworkConfigByChainId[ANVIL_CHAIN_ID] = getOrCreateAnvilConfig();
            return s_NetworkConfigByChainId[ANVIL_CHAIN_ID];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthMainnetConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig(
            ENTRANCE_FEE,
            INTERVAL,
            0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b,
            SUBSCRIPTION_ID,
            CALLBACK_GAS_LIMIT,
            ETH_MAINNET_LINK_ADDRESS,
            address(0)
        );
    }

    function getEthSepoliaConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig(
            ENTRANCE_FEE,
            INTERVAL,
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            SUBSCRIPTION_ID,
            CALLBACK_GAS_LIMIT,
            ETH_SEPOLIA_LINK_ADDRESS,
            0xa9FC12FE48989444F5f921a53eF9d270daA9c4Db
        );
    }

    /**
     * @dev The LINK provided by the Polygon Bridge is not ERC-677 compatible,
     *  @dev so you cannot use it with Chainlink services or oracle nodes.
     */
    /*function getBNBConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig(
                ENTRANCE_FEE,
                INTERVAL,
                0xd691f04bc0C9a24Edb78af9E005Cf85768F694C9,
                0xeb0f72532fed5c94b4caf7b49caf454b35a729608a441101b9269efb7efe2c6c,
                SUBSCRIPTION_ID,
                CALLBACK_GAS_LIMIT
            );
    }*/

    function getOrCreateAnvilConfig() private returns (NetworkConfig memory) {
        if (s_VRFConfig.vrfCoordinator != address(0)) {
            return s_VRFConfig;
        }
        vm.startBroadcast();
        LinkToken linkTokenMock = new LinkToken();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();
        console.logString("===================HelperConfig=================== ");
        console.log("Deployed LinkTokenMock to address: %s", address(linkTokenMock));
        console.log("Deployed VRFCoordinatorMock to address: %s", address(vrfCoordinatorMock));
        console.log("Minted this amt of LINK: %s", linkTokenMock.getBalance(msg.sender));
        return NetworkConfig(
            MOCK_BASE_FEE,
            INTERVAL,
            address(vrfCoordinatorMock),
            bytes32(0),
            SUBSCRIPTION_ID,
            CALLBACK_GAS_LIMIT,
            address(linkTokenMock),
            0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        );
    }
}
