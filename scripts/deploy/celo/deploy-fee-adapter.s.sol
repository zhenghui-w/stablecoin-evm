/**
 * Copyright 2024 Circle Internet Financial, LTD. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.6.12;

import "forge-std/console.sol"; // solhint-disable no-global-import, no-console
import { Script } from "forge-std/Script.sol";
import {
    FiatTokenFeeAdapterProxy
} from "../../../contracts/v2/celo/FiatTokenFeeAdapterProxy.sol";
import {
    FiatTokenFeeAdapterV1
} from "../../../contracts/v2/celo/FiatTokenFeeAdapterV1.sol";

/**
 * A utility script to directly deploy Celo-specific fee adapter contract with the latest implementation.
 * The fee adapter contract sits behind a fee adapter proxy, which is also deployed in this script.
 */
contract DeployFeeAdapter is Script {
    address private adapterProxyAdminAddress;
    address payable private fiatTokenProxyAddress;

    uint8 private feeAdapterDecimals;

    uint256 private deployerPrivateKey;

    /**
     * @notice initialize variables from environment
     */
    function setUp() public {
        adapterProxyAdminAddress = vm.envAddress(
            "FEE_ADAPTER_PROXY_ADMIN_ADDRESS"
        );
        fiatTokenProxyAddress = payable(
            vm.envAddress("FIAT_TOKEN_PROXY_ADDRESS")
        );

        feeAdapterDecimals = uint8(vm.envUint("FEE_ADAPTER_DECIMALS"));

        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        console.log(
            "FEE_ADAPTER_PROXY_ADMIN_ADDRESS: '%s'",
            adapterProxyAdminAddress
        );
        console.log("FIAT_TOKEN_PROXY_ADDRESS: '%s'", fiatTokenProxyAddress);
        console.log("FEE_ADAPTER_DECIMALS: '%s'", feeAdapterDecimals);
    }

    /**
     * @notice main function that will be run by forge
     */
    function run() external returns (FiatTokenFeeAdapterProxy) {
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the implementation of the fee adapter
        FiatTokenFeeAdapterV1 feeAdapter = new FiatTokenFeeAdapterV1();
        feeAdapter.initializeV1(fiatTokenProxyAddress, feeAdapterDecimals);

        // Deploy the proxy contract for the fee adapter
        FiatTokenFeeAdapterProxy feeAdapterProxy = new FiatTokenFeeAdapterProxy(
            address(feeAdapter)
        );

        // Reassign the admin on the adapter proxy, as proxy admins aren't allowed
        // to call the fallback (delegate) functions. The call to initializeV1 won't
        // work if this isn't done.
        feeAdapterProxy.changeAdmin(adapterProxyAdminAddress);

        // Initialize the adapter proxy with proper values.
        feeAdapter.initializeV1(fiatTokenProxyAddress, feeAdapterDecimals);

        vm.stopBroadcast();

        return feeAdapterProxy;
    }
}
