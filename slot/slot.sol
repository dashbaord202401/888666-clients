// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "https://github.com/chain-xz/clients/blob/main/core/core.sol";

contract SLOT is CORE {

    struct BET {
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

    constructor(bytes32 keyhash, uint64 subscription, address coordinator, address xz) CORE(keyhash, subscription, coordinator, xz) {
        NUMWORDS = 0;
        TABLEMIN = 10 ether;
        TABLEMAX = 10 ether;
    }

    function play(BET[] memory bets) public returns (uint256 request) {
        uint256 amount;
        NUMWORDS = uint32(bets.length) * 3;

        request = request_words(NUMWORDS);

        for (uint i = 0; i < bets.length; i++) {
            validate(bets[i].wager, TABLEMIN, TABLEMAX);
            REQUESTS[request].bets.push(bets[i]);
            amount += bets[i].wager;
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

        uint8[64] memory reel_1 =   [5, 0, 3, 5, 0, 4, 2, 5, 0, 0, 4, 0, 3, 1, 6, 1,
                                     3, 6, 4, 0, 0, 5, 0, 1, 6, 5, 2, 5, 0, 3, 6, 4,
                                     3, 0, 4, 6, 0, 4, 0, 0, 0, 2, 0, 6, 0, 3, 0, 1,
                                     0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 2, 2, 6, 0, 6, 0];

        uint8[64] memory reel_2  =  [6, 1, 5, 0, 4, 2, 4, 0, 1, 6, 0, 0, 0, 0, 0, 0,
                                     0, 6, 3, 3, 0, 0, 0, 0, 0, 2, 0, 2, 0, 4, 5, 0,
                                     6, 0, 0, 0, 2, 4, 0, 0, 3, 5, 0, 0, 6, 0, 6, 0,
                                     0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 3, 0, 0, 5, 5, 0];

        uint8[64] memory reel_3  =  [0, 4, 0, 0, 3, 0, 5, 0, 0, 0, 0, 0, 0, 4, 6, 6,
                                     0, 0, 0, 0, 2, 0, 0, 3, 0, 0, 5, 5, 0, 5, 1, 4,
                                     0, 0, 6, 0, 0, 5, 0, 0, 0, 0, 5, 3, 0, 0, 6, 6,
                                     0, 2, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 4];

        uint256 idx;
        for (uint256 i = 0; i < bets.length; i++) {

            uint256 slot_1 = words[idx + 0] % 64;
            uint256 slot_2 = words[idx + 1] % 64;
            uint256 slot_3 = words[idx + 2] % 64;
            idx += 3;


            if(reel_1[slot_1] == 1 && reel_2[slot_2] == 1 && reel_3[slot_3] == 1) {
                payout(bets[i].wager, user, 5000, 1);
            }
            else if(reel_1[slot_1] == 2 && reel_2[slot_2] == 2 && reel_3[slot_3] == 2) {
                payout(bets[i].wager, user, 1000, 1);
            }
            else if(reel_1[slot_1] == 3 && reel_2[slot_2] == 3 && reel_3[slot_3] == 3) {
                payout(bets[i].wager, user, 200, 1);
            }
            else if(reel_1[slot_1] == 4 && reel_2[slot_2] == 4 && reel_3[slot_3] == 4) {
                payout(bets[i].wager, user, 100, 1);
            }
            else if(reel_1[slot_1] == 5 && reel_2[slot_2] == 5 && reel_3[slot_3] == 5) {
                payout(bets[i].wager, user, 50, 1);
            }
            else if(reel_1[slot_1] == 6 && reel_2[slot_2] == 6 && reel_3[slot_3] == 6) {
                payout(bets[i].wager, user, 25, 1);
            }
            else if (((reel_1[slot_1] == 2) && (reel_2[slot_2] == 2)) ||
                     ((reel_1[slot_1] == 2) && (reel_3[slot_3] == 2)) ||
                     ((reel_2[slot_2] == 2) && (reel_3[slot_3] == 2))) {
                payout(bets[i].wager, user, 10, 1);
            }
            else if ((reel_1[slot_1] == 2) || (reel_2[slot_2] == 2) || (reel_3[slot_3] == 2)) {
                payout(bets[i].wager, user, 2, 1);
            }
        }
    }

    function view_request(uint256 request) public view returns (BET[] memory, uint256, address, uint256[] memory, bool, bool) {
        require(REQUESTS[request].exists, "Request does not exist;");
        return (REQUESTS[request].bets, REQUESTS[request].amount, REQUESTS[request].user, REQUESTS[request].words, REQUESTS[request].exists, REQUESTS[request].fulfilled);
    }
}
