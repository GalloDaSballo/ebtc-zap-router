// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {EbtcZapRouter} from "../src/EbtcZapRouter.sol";
import {ZapRouterBaseStorageVariables} from "../src/invariants/ZapRouterBaseStorageVariables.sol";
import {eBTCBaseInvariants} from "@ebtc/foundry_test/BaseInvariants.sol";
import {IBorrowerOperations} from "@ebtc/contracts/interfaces/IBorrowerOperations.sol";
import {IPositionManagers} from "@ebtc/contracts/interfaces/IPositionManagers.sol";
import {IERC20} from "@ebtc/contracts/Dependencies/IERC20.sol";
import {Mock1Inch} from "@ebtc/contracts/TestContracts/Mock1Inch.sol";
import {IEbtcZapRouter} from "../src/interface/IEbtcZapRouter.sol";

contract ZapRouterBaseInvariants is eBTCBaseInvariants, ZapRouterBaseStorageVariables {
    Mock1Inch internal mockDex;

    function setUp() public override virtual {
        super.setUp();

        mockDex = new Mock1Inch(address(eBTCToken), address(collateral));

        zapRouter = new EbtcZapRouter(IEbtcZapRouter.DeploymentParams({
            borrowerOperations: address(borrowerOperations),
            activePool: address(activePool),
            cdpManager: address(cdpManager),
            ebtc: address(eBTCToken),
            stEth: address(collateral),
            sortedCdps: address(sortedCdps),
            priceFeed: address(priceFeedMock),
            dex: address(mockDex)
        }));
    }

    function _ensureZapInvariants() internal {
        
    }

    function _createUserFromFixedPrivateKey() internal returns (address user) {
        user = vm.addr(userPrivateKey);
    }

    function _generatePermitSignature(
        address _signer,
        address _positionManager,
        IPositionManagers.PositionManagerApproval _approval,
        uint _deadline
    ) internal returns (bytes32) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                borrowerOperations.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        borrowerOperations.permitTypeHash(),
                        _signer,
                        _positionManager,
                        _approval,
                        borrowerOperations.nonces(_signer),
                        _deadline
                    )
                )
            )
        );
        return digest;
    }
}