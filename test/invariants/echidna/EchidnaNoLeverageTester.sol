// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TargetFunctionsNoLeverage} from "../TargetFunctionsNoLeverage.sol";

contract EchidnaTester is TargetFunctionsNoLeverage {
    constructor() payable {
        super.setUp();
        super.setUpActors();
    }
}