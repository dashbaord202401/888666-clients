// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "https://github.com/chain-xz/clients/blob/main/core/core.sol";

contract WHEEL is CORE {

    enum BETS {
        ONE,
        THREE,
        SIX,
        TWELVE,
        TWENTYFIVE,
        RED,
        YELLOW
    }

    struct BET {
        BETS        bet;
        uint256     wager;
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
    uint256 TABLEMIN;
    uint256 TABLEMAX;
    uint256[7] PAYOUT;
    uint256[7] NUMBER;

    constructor(bytes32 keyhash, uint64 subscription, address coordinator, address xz) CORE(keyhash, subscription, coordinator, xz) {
        NUMWORDS = 1;
        TABLEMIN = 5 ether;
        TABLEMAX = 500 ether;
        PAYOUT = [ 1,  3, 6, 12, 25, 50, 50];
        NUMBER = [26, 13, 7,  4,  2,  1,  1];
    }

    function play(BET[] memory bets) public returns (uint256 request) {
        uint256 amount;
        request = request_words(NUMWORDS);

        for (uint i = 0; i < bets.length; i++) {
            amount += bets[i].wager;
            validate(bets[i].wager, TABLEMIN, TABLEMAX);
            REQUESTS[request].bets.push(bets[i]);
        }

        REQUESTS[request].amount = amount;
        REQUESTS[request].user = msg.sender;
        REQUESTS[request].words = new uint256[](0);
        REQUESTS[request].exists = true;
        REQUESTS[request].fulfilled = false;

        require(bets.length > 0, "Minimum 1 bet;");
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

        uint256 win_number  = words[0] % 54;

        /*
         * Find the winning index
         * Pay winning bets index
         */
        uint16 idx;
        uint256 number;

        for (uint256 i = 0; i < NUMBER.length; i++) {
            number += NUMBER[i];

            if (win_number < number) {
                idx = uint16(i);
                break;
            }
        }

        for (uint256 i = 0; i < bets.length; i++) {
            if (idx == uint16(bets[i].bet)) {
                payout(bets[i].wager, user, PAYOUT[idx], 1);
            }
        }
    }

    function view_request(uint256 request) public view returns (BET[] memory, uint256, address, uint256[] memory, bool, bool) {
        require(REQUESTS[request].exists, "Request does not exist;");
        return (REQUESTS[request].bets, REQUESTS[request].amount, REQUESTS[request].user, REQUESTS[request].words, REQUESTS[request].exists, REQUESTS[request].fulfilled);
    }
}
