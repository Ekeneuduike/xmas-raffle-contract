// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {XmasGame} from "../src/XmasGame.sol";
import {DeploymentHelper} from "../script/deploymentHelper.s.sol";



contract CounterTest is Test {
    XmasGame public game;
    DeploymentHelper public helper;

    uint256 AMOUNT = 10 ether;
    address wrong = makeAddr("user");

    function setUp() public {
           helper = new  DeploymentHelper();
         game = new XmasGame(helper.getActiveConfig());
    }

    function test_EnterRaffle_Adds_User_To_Array() public {
        uint256 count = game.getPlayers().length;
        game.enterRaffle{value: 0.0004 ether}();
        assertEq(game.getPlayers().length, count + 1);
    }

    function test_enterRaffle_fails_if_amount_is_less_than_0_0004_ether() public {
        try game.enterRaffle{value: 0.0003 ether}() {
            assert(false);
        } catch Error(string memory reason) {
            assertEq(reason, "amount must be equal or greater than 0.0004 ether");
        }
    }

    function test_withdrawal_works_fine_when_all_conditions_are_meet() public {
        uint16 i;
        uint256[] memory words = new uint256[](1);
        words[0] = 378743736767789298877787777476467583847464455;
        for (i = 0; i < 10; i++) {
            address user = makeAddr(string(abi.encodePacked("user", i)));
            vm.prank(user);
            vm.deal(user, AMOUNT);
            game.enterRaffle{value: 0.0004 ether}();
            vm.stopPrank();   
            console.log(game.getPlayers()[i]);
        }
        vm.warp(block.timestamp + 3609);
        (bool canwin,) = game.checkUpKeep("");
        assert(canwin);
        game.setRequestid(12);
        game.callWinner(words, 12);
        assertEq(game.getPlayers().length, 0);
        assert(game.getWinner().amount == (0.0004 ether * 8));
    }

    function test_only_owner_can_call_update_subId() public {
        vm.prank(wrong);
        vm.expectRevert("this function is only callable by the owner");
        game.setSubId(245);
        assertEq(game.getOwner(),address(this));
    }

    function testFuzz_SetNumber(uint256 x) public {
        // counter.setNumber(x);
        // assertEq(counter.number(), x);
    }
}
