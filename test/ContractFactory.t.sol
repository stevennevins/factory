// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ContractFactory} from "../src/ContractFactory.sol";

contract ContractFactoryTest is Test {
    ContractFactory internal factory;

    function setUp() public {
        factory = new ContractFactory();
    }
}
