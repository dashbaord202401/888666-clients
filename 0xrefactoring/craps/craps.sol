// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/smart-casino/smart-core/blob/main/table/table.sol";

contract CRAPS is TABLE {

    struct BET {
        WAGERS      wager;
        ACTION      action;
        uint256     amount; 
        uint256     number; 
    }

    struct PUCK_STR {
        PUCK        puck;
        uint256     number; 
    }

    struct REQUEST {
        PUCK_STR    puck;     // Puck status
        BET[64]     bets;     // Craps bets
        uint256     request;  // Original request
        uint256     total;    // Total amount
        address     user;     // Player address
        uint256     paid;     // Paid in link
    }
    mapping(uint256 => REQUEST) public requests;

    enum BETTYPE {
        NEW,
        CONTINUE
    }
    struct REQUESTTYPE{
        BETTYPE     bettype;
        uint256     request;
    }

    constructor(address house_address) TABLE(house_address) {
        // init
    }

    function init_requests(uint256 requestID, uint256 paid) internal {
        requests[requestID].puck.puck = PUCK.OFF;
        requests[requestID].user = msg.sender;
        requests[requestID].paid = paid;
    }

    function current_bet(REQUESTTYPE memory requesttype) public returns (uint256 index, uint256 requestID) {
        uint256 paid;
        uint256 request = requesttype.request;

        if (requesttype.bettype == BETTYPE.NEW) {
            (requestID, paid) = get_requestID();
            init_requests(requestID, paid);
            requests[requestID].request = 0;
        } 

        if (requesttype.bettype == BETTYPE.CONTINUE) {
            require(requests[request].user == msg.sender, "Wrong user request;");
            require(requests[request].puck.puck == PUCK.NUMBER, "Puck is not on POINT;");

            (requestID, paid) = get_requestID();
            init_requests(requestID, paid);
            requests[requestID].request = request;

            requestID = request;
            for (uint256 i = 0; i < requests[request].bets.length; i++) {
                if (requests[request].bets[i].amount == 0) {
                    index = i;
                    break;
                }
            }
        }
        return (index, requestID);
    }

    function place_bets(uint256 index, uint256 i, uint256 requestID, BET[] memory bets) private returns (uint256 amount) {
        requests[requestID].bets[index].wager =  bets[i].wager;
        requests[requestID].bets[index].action = bets[i].action;
        requests[requestID].bets[index].amount = bets[i].amount;
        requests[requestID].bets[index].number = bets[i].number;
        validate_bet(bets[i].amount, 50, 1000);
        return bets[i].amount;
    }

    function line_bets(uint256 total_bets, uint256 index, uint256 i, uint256 requestID, BET[] memory bets) private returns (uint256 amount) {
        if (bets[i].wager == WAGERS.PASSLINE || bets[i].wager == WAGERS.DONT_PASS) {
            require(requests[requestID].puck.puck == PUCK.OFF, "Puck is not OFF;");
            return place_bets(index, i, requestID, bets);
        }

        if (bets[i].wager == WAGERS.PASSLINE_ODDS || bets[i].wager == WAGERS.DONT_PASS_ODDS) {
            require(requests[requestID].puck.puck == PUCK.NUMBER, "Puck is not on POINT;");

            uint256 find_index = 69; // So zero becomes a valid index
            for (uint256 j = 0; j < total_bets; j++) {
                if (bets[i].wager == WAGERS.PASSLINE_ODDS && (requests[requestID].bets[j].wager == WAGERS.PASSLINE || requests[requestID].bets[j].wager == WAGERS.PUT)) {
                    find_index = j;
                    break;
                }
                if (bets[i].wager == WAGERS.DONT_PASS_ODDS && requests[requestID].bets[j].wager == WAGERS.DONT_PASS) {
                    find_index = j;
                    break;
                }
            }
            require(find_index != 69, "Index not found;");
            return place_bets(index, i, requestID, bets);
        }

        if (bets[i].wager == WAGERS.COME || bets[i].wager == WAGERS.DONT_COME) {
            require(requests[requestID].puck.puck == PUCK.NUMBER, "Puck is not on POINT;");
            return place_bets(index, i, requestID, bets);
        }

        if (bets[i].wager == WAGERS.COME_ODDS || bets[i].wager == WAGERS.DONT_COME_ODDS) {
            require(requests[requestID].puck.puck == PUCK.NUMBER, "Puck is not on POINT;");

            uint256 find_index = 69; // So zero becomes a valid index
            for (uint256 j = 0; j < total_bets; j++) {
                if (bets[i].wager == WAGERS.COME_ODDS && requests[requestID].bets[j].wager == WAGERS.COME) {
                    find_index = j;
                    break;
                }
                if (bets[i].wager == WAGERS.DONT_COME_ODDS && requests[requestID].bets[j].wager == WAGERS.DONT_COME) {
                    find_index = j;
                    break;
                }
            }
            require(find_index != 69, "Index not found;");
            return place_bets(index, i, requestID, bets);
        }
    }

    function multi_roll_bets(uint256 index, uint256 i, uint256 requestID, BET[] memory bets) private returns (uint256 amount) {
        if (bets[i].wager == WAGERS.PLACE ||
            bets[i].wager == WAGERS.BUY || bets[i].wager == WAGERS.LAY ||
            bets[i].wager == WAGERS.PUT || bets[i].wager == WAGERS.HARD_WAY ||
            bets[i].wager == WAGERS.BIG_6 || bets[i].wager == WAGERS.BIG_8) {
            require(requests[requestID].puck.puck != PUCK.OVER, "Puck is over;");
            return place_bets(index, i, requestID, bets);
        }
    }

    function single_roll_bets(uint256 index, uint256 i, uint256 requestID, BET[] memory bets) private returns (uint256 amount) {
        if (bets[i].wager == WAGERS.SNAKE_EYES || bets[i].wager == WAGERS.ACE_DEUCE ||
            bets[i].wager == WAGERS.YO || bets[i].wager == WAGERS.BOXCARS ||
            bets[i].wager == WAGERS.ANYCRAPS || bets[i].wager == WAGERS.ANYSEVEN ||
            bets[i].wager == WAGERS.FIELD) {
            require(requests[requestID].puck.puck != PUCK.OVER, "Puck is not OVER;");
            return place_bets(index, i, requestID, bets);
        }
    }

    function play_craps(REQUESTTYPE memory requesttype, BET[] memory bets) public {
        uint256 total;
        (uint256 index, uint256 requestID) = current_bet(requesttype);
        uint256 total_bets = index;
        require(bets.length <= index, "Too many bets;");

        for (uint256 i = 0; i < bets.length; i++) {
            uint256 amount;
            amount = line_bets(total_bets, index, i, requestID, bets);
            if (amount > 0) {
                total += amount;
                index += 1;
                continue;
            }
            amount = multi_roll_bets(index, i, requestID, bets);
            if (amount > 0) {
                total += amount;
                index += 1;
                continue;
            }
            amount = single_roll_bets(index, i, requestID, bets);
            if (amount > 0) {
                total += amount;
                index += 1;
                continue;
            }
        }

        requests[requestID].total = total;
        require(total != 0, "Sum of bet is Zero;");
        require(total <= user_deposit[msg.sender], "Insufficient funds;");
    }

    function execute_table(uint256 request, uint256[] memory random_words) internal override {
        require(requests[request].paid > 0, "request not found;");

        address user = requests[request].user;
        if (requests[request].request == 0) {
            craps_table(request, random_words, user);
        } else {
            craps_table(requests[request].request, random_words, user);
        }

        total_deposits -= requests[request].total;
        user_deposit[user] -= requests[request].total;
    }

    function craps_table(uint256 request, uint256[] memory random_words, address user) private {
        uint256 roll1 = random_words[0] % 6;
        uint256 roll2 = random_words[1] % 6;
        if (roll1 == 0) {roll1 = 6;}
        if (roll2 == 0) {roll2 = 6;}
        uint256 roll = roll1 + roll2;

        for (uint256 i = 0; i < requests[request].bets.length; i++) {
            if (requests[request].bets[i].amount == 0) {
                break;
            }

            if(requests[request].bets[i].wager == WAGERS.PASSLINE && requests[request].bets[i].action == ACTION.ROLL) {
                if(requests[request].puck.puck == PUCK.OFF) {
                    if (roll == 7 || roll == 11) {
                        requests[request].bets[i].action = ACTION.COME_OUT;
                        reward_compile(requests[request].bets[i].amount, 1, user);
                    }
                    if (roll == 2 || roll == 3 || roll == 12) {
                        requests[request].bets[i].action = ACTION.COME_OUT;
                        reward_compile(requests[request].bets[i].amount, 0, user);
                    }
                    requests[request].bets[i].action = ACTION.ROLL;
                    requests[request].puck.number = roll;
                }

                if(requests[request].puck.puck == PUCK.NUMBER) {
                    if (roll == 7) {
                        requests[request].bets[i].action = ACTION.SEVEN_OUT;
                    }
                    if (roll == requests[request].puck.number) {
                        requests[request].bets[i].action = ACTION.COME_OUT;
                        reward_compile(requests[request].bets[i].amount, 1, user);
                    }
                }
            }
        }

    }

    //puck_table(request, roll);
    function puck_table(uint256 requestID, uint256 roll) private {
        if(requests[requestID].puck.puck == PUCK.OFF) {
            uint256[5] memory number = [uint256(7), 11, 2, 3, 12];
            for (uint256 i = 0; i < number.length; i++) {
                if (roll == number[i]) {
                    requests[requestID].puck.puck = PUCK.OVER;
                    break;
                }
            }
            requests[requestID].puck.puck = PUCK.NUMBER;
        }

        if(requests[requestID].puck.puck == PUCK.NUMBER && roll == 7) {
            requests[requestID].puck.puck = PUCK.OVER;
        }
        requests[requestID].puck.number = roll;
    }
}
