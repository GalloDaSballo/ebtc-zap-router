// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {IERC3156FlashLender} from "@ebtc/contracts/Interfaces/IERC3156FlashLender.sol";
import {LeverageZapRouterBase} from "./LeverageZapRouterBase.sol";
import {ICdpManagerData} from "@ebtc/contracts/Interfaces/ICdpManagerData.sol";
import {ICdpManager} from "@ebtc/contracts/Interfaces/ICdpManager.sol";
import {IBorrowerOperations} from "@ebtc/contracts/Interfaces/IBorrowerOperations.sol";
import {IPositionManagers} from "@ebtc/contracts/Interfaces/IPositionManagers.sol";
import {IERC20} from "@ebtc/contracts/Dependencies/IERC20.sol";
import {SafeERC20} from "@ebtc/contracts/Dependencies/SafeERC20.sol";
import {IStETH} from "./interface/IStETH.sol";
import {IWrappedETH} from "./interface/IWrappedETH.sol";
import {IEbtcLeverageZapRouter} from "./interface/IEbtcLeverageZapRouter.sol";
import {IWstETH} from "./interface/IWstETH.sol";

contract EbtcLeverageZapRouter is LeverageZapRouterBase, IEbtcLeverageZapRouter {
    using SafeERC20 for IERC20;

    constructor(
        IEbtcLeverageZapRouter.DeploymentParams memory params
    ) LeverageZapRouterBase(params) {}

    function openCdpWithEth(
        uint256 _debt,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint256 _stEthLoanAmount,
        uint256 _ethBalance,
        uint256 _stEthDepositAmount,
        PositionManagerPermit calldata _positionManagerPermit,
        bytes calldata _exchangeData
    ) external payable returns (bytes32 cdpId) {
        uint256 _collVal = _convertRawEthToStETH(_ethBalance);

        return
            _openCdp(
                _debt,
                _upperHint,
                _lowerHint,
                _stEthLoanAmount,
                _collVal,
                _stEthDepositAmount,
                _positionManagerPermit,
                _exchangeData
            );
    }

    function openCdpWithWstEth(
        uint256 _debt,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint256 _stEthLoanAmount,
        uint256 _wstEthBalance,
        uint256 _stEthDepositAmount,
        PositionManagerPermit calldata _positionManagerPermit,
        bytes calldata _exchangeData
    ) external returns (bytes32 cdpId) {
        uint256 _collVal = _convertWstEthToStETH(_wstEthBalance);

        return
            _openCdp(
                _debt,
                _upperHint,
                _lowerHint,
                _stEthLoanAmount,
                _collVal,
                _stEthDepositAmount,
                _positionManagerPermit,
                _exchangeData
            );
    }

    function openCdpWithWrappedEth(
        uint256 _debt,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint256 _stEthLoanAmount,
        uint256 _wethBalance,
        uint256 _stEthDepositAmount,
        PositionManagerPermit calldata _positionManagerPermit,
        bytes calldata _exchangeData
    ) external returns (bytes32 cdpId) {
        uint256 _collVal = _convertWrappedEthToStETH(_wethBalance);

        return
            _openCdp(
                _debt,
                _upperHint,
                _lowerHint,
                _stEthLoanAmount,
                _collVal,
                _stEthDepositAmount,
                _positionManagerPermit,
                _exchangeData
            );
    }

    function openCdp(
        uint256 _debt,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint256 _stEthLoanAmount,
        uint256 _stEthMarginAmount,
        uint256 _stEthDepositAmount,
        PositionManagerPermit calldata _positionManagerPermit,
        bytes calldata _exchangeData
    ) external returns (bytes32 cdpId) {
        return
            _openCdp(
                _debt,
                _upperHint,
                _lowerHint,
                _stEthLoanAmount,
                _stEthMarginAmount,
                _stEthDepositAmount,
                _positionManagerPermit,
                _exchangeData
            );
    }

    function _openCdp(
        uint256 _debt,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint256 _stEthLoanAmount,
        uint256 _stEthMarginAmount,
        uint256 _stEthDepositAmount,
        PositionManagerPermit calldata _positionManagerPermit,
        bytes calldata _exchangeData
    ) internal returns (bytes32 cdpId) {
        // TODO: calculate this for real, need to figure out how to specify leverage ratio
        // TODO: check max leverage here once we know how leverage will be specified
        //uint256 flAmount = _debtToCollateral(_debt);

        // We need to deposit slightly less collateral to account for fees / slippage
        // COLLATERAL_BUFFER is a temporary solution to make the tests pass
        // TODO: discuss this and see if it's better to pass in some sort of slippage setting
        //  uint256 totalCollateral = ;

        // TODO: compute CR >= MSCR (minimum safe collateral ratio)
        // TODO: check fetchPrice gas

        _permitPositionManagerApproval(_positionManagerPermit);

        cdpId = sortedCdps.toCdpId(msg.sender, block.number, sortedCdps.nextCdpNonce());

        OpenCdpForOperation memory cdp;

        cdp.eBTCToMint = _debt;
        cdp._upperHint = _upperHint;
        cdp._lowerHint = _lowerHint;
        cdp.stETHToDeposit = _stEthDepositAmount;
        cdp.borrower = msg.sender;

        _openCdpOperation({
            _cdpId: cdpId,
            _cdp: cdp,
            _flAmount: _stEthLoanAmount,
            _stEthBalance: _stEthMarginAmount,
            _exchangeData: _exchangeData
        });

        // TODO: emit event
    }

    function closeCdp(
        bytes32 _cdpId,
        PositionManagerPermit calldata _positionManagerPermit,
        uint256 _stEthAmount,
        bytes calldata _exchangeData
    ) external {
        ICdpManagerData.Cdp memory cdpInfo = cdpManager.Cdps(_cdpId);

        _permitPositionManagerApproval(_positionManagerPermit);

        _closeCdpOperation({
            _cdpId: _cdpId,
            _debt: cdpInfo.debt,
            _stEthAmount: _stEthAmount,
            _exchangeData: _exchangeData
        });
    }

    function adjustCdp(
        bytes32 _cdpId,
        AdjustCdpParams calldata params,
        PositionManagerPermit calldata _positionManagerPermit,
        bytes calldata _exchangeData
    ) external {

    }
}
