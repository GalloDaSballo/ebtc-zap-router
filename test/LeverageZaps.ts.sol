// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {EbtcZapRouter} from "../src/EbtcZapRouter.sol";
import {ZapRouterBaseInvariants} from "./ZapRouterBaseInvariants.sol";
import {IBorrowerOperations} from "@ebtc/contracts/interfaces/IBorrowerOperations.sol";
import {IPositionManagers} from "@ebtc/contracts/interfaces/IPositionManagers.sol";
import {IEbtcZapRouter} from "../src/interface/IEbtcZapRouter.sol";

contract LeverageZaps is ZapRouterBaseInvariants {
    function setUp() public override {
        super.setUp();
    }

    function seedActivePool() private {
        address whale = vm.addr(0xabc456);
        _dealCollateralAndPrepForUse(whale);

        vm.startPrank(whale);
        collateral.approve(address(borrowerOperations), type(uint256).max);

        // Seed AP
        borrowerOperations.openCdp(
            0.1e18,
            bytes32(0),
            bytes32(0),
            60 ether
        );

        vm.stopPrank();
    }

    function test_ZapOpenCdp_WithStEth_LowLeverage() public {
        seedActivePool();

        // Give stETH to mock dex
        mockDex.setPrice(priceFeedMock.fetchPrice());
        vm.deal(address(mockDex), type(uint96).max);
        vm.prank(address(mockDex));
        collateral.deposit{value: 10000 ether}();

        address user = _createUserFromFixedPrivateKey();

        uint _deadline = (block.timestamp + deadline);
        IPositionManagers.PositionManagerApproval _approval = IPositionManagers
            .PositionManagerApproval
            .OneTime;

        _dealCollateralAndPrepForUse(user);

        uint256 stEthBalance = 5 ether;

        vm.startPrank(user);

        // Generate signature to one-time approve zap
        bytes32 digest = _generatePermitSignature(
            user,
            address(zapRouter),
            _approval,
            _deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        IEbtcZapRouter.PositionManagerPermit memory pmPermit = IEbtcZapRouter
            .PositionManagerPermit(_deadline, v, r, s);

        collateral.approve(address(zapRouter), type(uint256).max);

        // Get before balances
        zapRouter.temp_openCdpWithLeverage(
            1e18,
            bytes32(0),
            bytes32(0),
            stEthBalance,
            pmPermit,
            abi.encodeWithSelector(
                mockDex.swap.selector,
                address(eBTCToken),
                address(collateral),
                1e18
            )
        );

        vm.stopPrank();
    }
}