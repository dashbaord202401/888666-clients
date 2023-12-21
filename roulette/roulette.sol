// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "https://github.com/chain-xz/clients/blob/main/core/core.sol";

contract ROULETTE is CORE {

    enum BETS {
        STRAIGHT,
        SPLIT,
        STREET,
        CORNER,
        SIXLINE,
        DOZENCOLUMN,
        EVENMONEY
    }

    struct BET {
        BETS        bet;
        uint256[]   number;
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
    uint256[7] NUMBER;
    uint256[7] PAYOUT;
    uint256[7] TABLEMIN;
    uint256[7] TABLEMAX;

    constructor(bytes32 keyhash, uint64 subscription, address coordinator, address xz) CORE(keyhash, subscription, coordinator, xz) {
        NUMWORDS = 1;
        NUMBER =   [        1,         2,         3,         4,           6,         12,         18];
        PAYOUT =   [       35,        17,        11,         8,           5,          2,          1];
        TABLEMIN = [  5 ether,   5 ether,   5 ether,   5 ether,     5 ether,   10 ether,   10 ether];
        TABLEMAX = [200 ether, 400 ether, 600 ether, 800 ether,  1200 ether, 2500 ether, 5000 ether];
    }

    function play(BET[] memory bets) public returns (uint256 request) {
        uint256 amount;
        request = request_words(NUMWORDS);

        for (uint256 i = 0; i < bets.length; i++) {
            uint16 idx = uint16(bets[i].bet);

            amount += bets[i].wager;
            validate(bets[i].wager, TABLEMIN[idx], TABLEMAX[idx]);
            REQUESTS[request].bets.push(bets[i]);

            require(NUMBER[idx] == bets[i].number.length, "Invalid bet length;");
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

        uint256 winning_number  = words[0] % 37;

        for (uint256 i = 0; i < bets.length; i++) {
            uint16 idx = uint16(bets[i].bet);

            /*
             * Go through all numbers to check winning number.
             * Initiate payout according to odds.
             */
            for (uint256 j = 0; j < NUMBER[idx]; j++) {
                if (bets[i].number[j] == winning_number) {
                    payout(bets[i].wager, user, PAYOUT[idx], 1);
                    break;
                }
            }
        }
    }

    function view_request(uint256 request) public view returns (BET[] memory, uint256, address, uint256[] memory, bool, bool) {
        require(REQUESTS[request].exists, "Request does not exist;");
        return (REQUESTS[request].bets, REQUESTS[request].amount, REQUESTS[request].user, REQUESTS[request].words, REQUESTS[request].exists, REQUESTS[request].fulfilled);
    }
}
