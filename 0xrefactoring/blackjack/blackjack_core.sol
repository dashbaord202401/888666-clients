// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BLACKJACKCORE {
    event bet_request(uint256 betid, uint256 request);

    enum ROUND {
        INITIAL,
        ACTION,
        SETTLED
    }

    enum ACTION {
        HIT,
        STAND,
        DOUBLEDOWN,
        SPLIT,
        SURRENDER,
        INSURANCE
    }

    struct HANDS {
        ACTION          action;
        uint256[]       cards;
        uint256         wager;
    }

    struct BET {
        ROUND           round;
        HANDS[]         hands;
        bool            holecard;
        uint256[]       cards;
        address         player;
        bool            fulfilled;
    }
    mapping(uint256 => BET) public BETS;

    uint256 BETSID;

    function get_betid() internal returns (uint256) {
        return BETSID++;
    }

    function initial_hand(uint256 wager) internal pure returns (HANDS memory hand) {
        return HANDS({
            action: ACTION.HIT,
            cards: new uint256[](0),
            wager: wager
        });
    }

    function check_settle(uint256[] memory hand, bool settle) internal pure returns (bool) {
        // if settle is true, then the hand is settled; otherwise, the hand is not settled
        if (!settle) {
            return false;
        }
        return hand_value(hand) >= 21;
    }

    function hand_value(uint256[] memory hand) internal pure returns (uint256) {
        uint256 total = 0;
        uint256 aces = 0;

        // Combine the first and second pass
        for (uint256 i = 0; i < hand.length; i++) {
            if (hand[i] == 1) { // Ace
                aces += 1;
            } else {
                total += (hand[i] > 10) ? 10 : hand[i];
            }
        }

        // Add aces as 1 or 11 without exceeding 21
        while (aces > 0) {
            total += (total + 11 > 21) ? 1 : 11;
            aces--;
        }

        return total;
    }

    function view_bets(uint256 betid) public view returns (ROUND, HANDS[] memory, bool, uint256[] memory, address, bool) {
        return (BETS[betid].round, BETS[betid].hands, BETS[betid].holecard, BETS[betid].cards, BETS[betid].player, BETS[betid].fulfilled);
    }
}
