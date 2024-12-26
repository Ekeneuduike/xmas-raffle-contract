// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DeploymentHelper} from "./deploymentHelper.s.sol";
import {XmasGame} from "../src/XmasGame.sol";

contract CounterScript is Script {
    DeploymentHelper public helper;
    XmasGame game;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
         helper = new  DeploymentHelper();
         
         game = new XmasGame(helper.getActiveConfig());
         console.logBytes32(game.getKeyhash());
         console.log(game.getvrf());

        vm.stopBroadcast();
    }
}
