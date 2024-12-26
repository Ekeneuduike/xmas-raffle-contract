// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Type} from './types.sol';

contract XmasGame is VRFConsumerBaseV2Plus {
    /// @dev Ekene Uduike
    /// @notice the commented out functions where written to allow for testing
    uint256 private constant MIN_INTERVAL = 1 hours;
    uint256 private constant MIN_AMOUNT = 0.0004 ether;
    uint256 private immutable i_startTime;
    uint256 private lastUpdateTime;
    address payable[] private players;
    State private raffleState;
    Winner private lastestWinner;

    ///////////////////////////////////////
    //          VRF Variables           //
    //////////////////////////////////////

    uint256 s_subscriptionId;
    address immutable i_vrfCoordinator;
    bytes32 immutable i_keyHash;
    uint32 constant Gas_Limit = 40000;
    uint16 immutable i_requestConfirmations = 3;
    uint32 immutable i_numWords = 1;
    address immutable i_owner;
    uint256 s_requestId;
    address payable constant OWNER_ADDRESS = payable(0xA5A8CC4bBB5C98ca2333c5E54e29db9748125b95);

    enum State {
        progress,
        calculating,
        ended
    }

    struct Winner {
        address payable winner;
        uint256 amount;
    }

    constructor(Type.InitiazationObject memory intializationObject) VRFConsumerBaseV2Plus(intializationObject.vrf) {
        i_startTime = block.timestamp;
        lastUpdateTime = block.timestamp;
        i_owner = msg.sender;
        i_vrfCoordinator = intializationObject.vrf;
        i_keyHash = intializationObject.key_hash;
    }

    modifier _onlyOwner() {
        if (msg.sender != i_owner) {
            revert("this function is only callable by the owner");
        }
        _;
    }

    modifier canEnter() {
        if (msg.value < MIN_AMOUNT) {
            revert("amount must be equal or greater than 0.0004 ether");
        }
        if (raffleState != State.progress) {
            revert("likely calculating winner check back in a few minutes");
        }
        _;
    }

    error Raffle_upkeepNotNeeded(uint256 balance, uint256 player, uint256 raffleState, uint256 elapsedTime);
    error raffle_Notended();
    error paymentFailed();

    /// @notice
    // use some kind callnack functiont to get automate calling and distributing the token

    function setSubId(uint256 _subscriptionId) external _onlyOwner {
        s_subscriptionId = _subscriptionId;
    }

    function enterRaffle() public payable canEnter {
        players.push(payable(msg.sender));
    }

    function checkUpKeep(bytes memory) public view returns (bool upKeepNeeded, bytes memory) {
        bool timehaspassed = ((block.timestamp - lastUpdateTime) >= MIN_INTERVAL);
        bool isopen = raffleState == State.progress;
        bool hasbalance = address(this).balance > (5 * MIN_AMOUNT);
        bool hasplayers = players.length > 0;
        upKeepNeeded = (timehaspassed && isopen && hasbalance && hasplayers);
        return (upKeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */ ) internal {
        (bool upKeepNeeded,) = checkUpKeep("");
        if (!upKeepNeeded) {
            revert Raffle_upkeepNotNeeded(
                address(this).balance, players.length, uint256(raffleState), block.timestamp - MIN_INTERVAL
            );
        }

        if ((block.timestamp - lastUpdateTime) < MIN_INTERVAL) {
            revert raffle_Notended();
        }

        raffleState = State.calculating;

        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: i_requestConfirmations,
                callbackGasLimit: Gas_Limit,
                numWords: i_numWords,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
    }

    function setRequestid(uint256 value) external {
     s_requestId = value;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {
        if (s_requestId != requestId) {
            revert("requestId do not match please retry");
        }
        uint32 winningNum = uint32(randomWords[0] % players.length);
        address payable recentWinner = players[winningNum];
        raffleState = State.progress;
        players = new address payable[](0);
        lastestWinner = Winner(recentWinner, (address(this).balance * 80) / 100);
        (bool success,) = recentWinner.call{value: (address(this).balance * 80) / 100}("");
        if (!success) {
            revert paymentFailed();
        }

        (bool feeSuccess,) = OWNER_ADDRESS.call{value: (address(this).balance * 20) / 100}("");
        if (!feeSuccess) {
            revert("fee payment failed");
        }
    }

    function callWinner(uint256[] calldata words,uint256 requestid) external{
        (bool upKeepNeeded,) = checkUpKeep("");
        if(upKeepNeeded){
           fulfillRandomWords(requestid,words);
        }
    }

    fallback() external payable {
        enterRaffle();
    }

    receive() external payable {
        enterRaffle();
    }

    ///////////////////////////////////
    //       view functions
    /////////////////////////////////
    function getWinner() public view returns (Winner memory) {
        return lastestWinner;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
    function getOwner() public view returns (address ){
        return i_owner;
    }
    function getvrf() external view returns(address){
      return i_vrfCoordinator;
    }
    function getKeyhash() external view returns(bytes32 ){
     return i_keyHash;
    }
}
