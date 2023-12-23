// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "https://github.com/chain-xz/clients/blob/main/core/core.sol";

contract BACCARAT is CORE {

    enum HANDS {
        PLAYER,
        BANKER,
        TIE
    }

    struct BET {
        HANDS   hand;
        uint256 wager;
    }

    struct REQUEST {
        BET[]       bets;
        uint256     amount;
        address     user;
        uint256[]   words;
        bool        exists;
        bool        fulfilled;
    }

    mapping(uint256 => REQUEST) public REQUESTS;

    uint32 NUMWORDS;
    uint256[3] TABLEMIN;
    uint256[3] TABLEMAX;

    constructor(bytes32 keyhash, uint64 subscription, address coordinator, address xz) CORE(keyhash, subscription, coordinator, xz) {
        NUMWORDS = 6;
        TABLEMIN = [25 ether,     25 ether,  10 ether];
        TABLEMAX = [5000 ether, 5000 ether, 100 ether];
    }

    function play(BET[] memory bets) public returns (uint256 request) {
        uint256 amount;
        request = request_words(NUMWORDS);

        for (uint256 i = 0; i < bets.length; i++) {
            uint256 idx = uint256(bets[i].hand);

            validate(bets[i].wager, TABLEMIN[idx], TABLEMAX[idx]);
            REQUESTS[request].bets.push(bets[i]);
            amount += bets[i].wager;
        }

        REQUESTS[request].amount = amount;
        REQUESTS[request].user = msg.sender;
        REQUESTS[request].words = new uint256[](0);
        REQUESTS[request].exists = true;
        REQUESTS[request].fulfilled = false;

        require(bets.length > 0 && bets.length < 3, "Minimum 1 bet, maximum 2 bets;");
        require(amount <= DEPOSITS[msg.sender], "Insufficient user funds;");
        return request;
    }

    function request_process(uint256 request, uint256[] memory words) internal override {
        require(REQUESTS[request].exists, "Request not found;");
        require(!REQUESTS[request].fulfilled, "Request already fulfilled;");

        REQUESTS[request].fulfilled = true;
        REQUESTS[request].words = words;

        BET[] memory bets = REQUESTS[request].bets;
        uint256 amount = REQUESTS[request].amount;
        address user = REQUESTS[request].user;

        no_more_bets(amount, user);

        // Player and banker cards
        uint256 player_1 = card_get(words[0]);
        uint256 player_2 = card_get(words[1]);
        uint256 player_3 = card_get(words[2]);
        uint256 banker_1 = card_get(words[3]);
        uint256 banker_2 = card_get(words[4]);
        uint256 banker_3 = card_get(words[5]);

        // Player initial draw
        uint256 player_coup = card_value(player_1 + player_2);
        bool player_natural = (player_coup == 8 || player_coup == 9);
        bool player_draw = false;

        // Banker initial draw
        uint256 banker_coup = card_value(banker_1 + banker_2);
        bool banker_natural = (banker_coup == 8 || banker_coup == 9);

        // Player third card draw
        if (player_coup <= 5 && !banker_natural) {
            player_coup = card_value(player_coup + player_3);
            player_draw = true;
        }

        // Banker third card draw if player did not draw
        if (banker_coup <= 5 && !player_natural && !player_draw) {
            banker_coup = card_value(banker_coup + banker_3);
        }

        // Banker third card draw if player did draw
        if (banker_coup <= 6 && !player_natural && player_draw) {
            if (banker_coup <= 2) {
                banker_coup = card_value(banker_coup + banker_3);
            }
            else if (banker_coup == 3 && player_3 != 8) {
                banker_coup = card_value(banker_coup + banker_3);
            }
            else if (banker_coup == 4 && (player_3 >= 2 && player_3 <= 7)) {
                banker_coup = card_value(banker_coup + banker_3);
            }
            else if (banker_coup == 5 && (player_3 >= 4 && player_3 <= 7)) {
                banker_coup = card_value(banker_coup + banker_3);
            }
            else if (banker_coup == 6 && (player_3 == 6 || player_3 == 7)) {
                banker_coup = card_value(banker_coup + banker_3);
            }
        }

        // Payout
        for (uint256 i = 0; i < bets.length; i++) {
            if(player_coup > banker_coup && bets[i].hand == HANDS.PLAYER) {
                payout(bets[i].wager, user, 1, 1);
            }
            else if(player_coup < banker_coup && bets[i].hand == HANDS.BANKER) {
                payout(bets[i].wager, user, 19, 20);
            }
            else if(player_coup == banker_coup && bets[i].hand == HANDS.TIE) {
                payout(bets[i].wager, user, 8, 1);
            }

            // TIE player & banker push
            if(player_coup == banker_coup && bets[i].hand != HANDS.TIE) {
                payout(bets[i].wager, user, 0, 1);
            }
        }
    }

    function card_get(uint256 card) private pure returns (uint256) {
        return ((card % 13) > 9) ? 0 : card % 13;
    }

    function card_value(uint256 cards) private pure returns (uint256) {
        return (cards > 9) ? cards - 10 : cards;
    }

    function view_request(uint256 request) public view returns (BET[] memory, uint256, address, uint256[] memory, bool, bool) {
        require(REQUESTS[request].exists, "Request does not exist;");
        return (REQUESTS[request].bets, REQUESTS[request].amount, REQUESTS[request].user, REQUESTS[request].words, REQUESTS[request].exists, REQUESTS[request].fulfilled);
    }
}
