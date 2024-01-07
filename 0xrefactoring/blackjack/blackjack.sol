// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/chainplay-x/chainplay-x/blob/main/x-engine/x-engine.sol";
import "./blackjack_core.sol";

contract BLACKJACK is BLACKJACKCORE, XENGINE {

    struct REQUEST {
        uint256     bets;
        uint256     amount;
        address     user;
        uint256[]   words;
        bool        exists;
        bool        fulfilled;
    }
    mapping(uint256 => REQUEST) public REQUESTS;

    uint256 TABLEMIN;
    uint256 TABLEMAX;

    constructor(bytes32 keyhash, uint64 subscription, address coordinator, address xtoken) XENGINE(keyhash, subscription, coordinator, xtoken) {
        TABLEMIN = 25 ether;
        TABLEMAX = 5000 ether;
    }

    function play_initial(uint256[] memory bets) public returns (uint256, uint256) {
        require(bets.length >= 1, "bets are less then 1;");
        require(bets.length <= 8, "bets are more then 8;");

        uint256 amount;
        uint256 betid = get_betid();

        for (uint i = 0; i < bets.length; i++) {
            BETS[betid].hands.push(initial_hand(bets[i]));
            validate(bets[i], TABLEMIN, TABLEMAX);
            amount += bets[i];
        }

        BETS[betid].round = ROUND.INITIAL;
        BETS[betid].holecard  = false;
        BETS[betid].cards = new uint256[](0);
        BETS[betid].player = msg.sender;
        BETS[betid].fulfilled = false;

        // Per hand 2 cards + 1 Dealer card;
        uint32 words = (uint32(bets.length) * 2) + 1;
        uint256 request = play(betid, amount, words);

        emit bet_request(betid, request);
        return (betid, request);
    }

    function play_action(uint256 betid, ACTION[] memory action) public returns (uint256, uint256) {
        require(BETS[betid].player == msg.sender, "not your round;");
        require(BETS[betid].round != ROUND.SETTLED, "round is settled;");
        require(BETS[betid].hands.length == action.length, "action and hands are not equal;");
        require(BETS[betid].fulfilled == true, "round is not fulfilled yet;");

        BETS[betid].round = ROUND.ACTION;
        BETS[betid].fulfilled = false;

        uint256 amount;
        // initialize with dealers 13 cards;
        uint32 words = 13;

        for (uint i = 0; i < action.length; i++) {
            require(uint8(action[i]) <= uint8(ACTION.INSURANCE), "bad action;");

            // STAND, DOUBLEDOWN, SURRENDER cannot be altered again;
            if(BETS[betid].hands[i].action == ACTION.STAND ||
               BETS[betid].hands[i].action == ACTION.DOUBLEDOWN ||
               BETS[betid].hands[i].action == ACTION.SURRENDER) {
                continue; 
            }
            // When hand is busted, it cannot be altered again;
            if(hand_value(BETS[betid].hands[i].cards) > 21) {
                BETS[betid].hands[i].action = ACTION.STAND;
            }

            if(action[i] == ACTION.HIT) {
                BETS[betid].hands[i].action = ACTION.HIT;
                words += 1;
            }
            else if(action[i] == ACTION.STAND) {
                BETS[betid].hands[i].action = ACTION.STAND;
            }
            else if(action[i] == ACTION.DOUBLEDOWN) {
                require(BETS[betid].hands[i].cards.length == 2, "DOUBLEDOWN with two cards;");
                BETS[betid].hands[i].action = ACTION.DOUBLEDOWN;

                // Increase the wager by 2x;
                amount += BETS[betid].hands[i].wager;
                BETS[betid].hands[i].wager *= 2;
                words += 1;
            }
            else if(action[i] == ACTION.SPLIT) {
                require(BETS[betid].hands[i].cards.length == 2, "SPLIT with two cards;");
                require(BETS[betid].hands[i].cards[0] == BETS[betid].hands[i].cards[1], "SPLIT cards are not same;");
                BETS[betid].hands[i].action = ACTION.SPLIT;

                // Add a new replica of the hand;
                BETS[betid].hands.push(BETS[betid].hands[i]);
                amount += BETS[betid].hands[i].wager;
                words += 2;
            }
            else if(action[i] == ACTION.SURRENDER) {
                require(BETS[betid].hands[i].cards.length == 2, "SURRENDER with two cards;");
                BETS[betid].hands[i].action = ACTION.SURRENDER;
            }
            else if(action[i] == ACTION.INSURANCE) {
                require(BETS[betid].holecard == false, "holecard is used;");
                require(BETS[betid].hands[i].cards.length == 2, "INSURANCE with two cards;");
                BETS[betid].hands[i].action = ACTION.INSURANCE;

                // half amount of the wager;
                amount += BETS[betid].hands[i].wager / 2;
            }
        }

        uint256 request = play(betid, amount, words);

        emit bet_request(betid, request);
        return (betid, request);
    }

    // Process request data;
    function request_process(uint256 request, uint256[] memory words) internal override {
        require(REQUESTS[request].exists, "request not found;");
        require(!REQUESTS[request].fulfilled, "request already fulfilled;");

        REQUESTS[request].fulfilled = true;
        REQUESTS[request].words = words;

        uint256 betid = REQUESTS[request].bets;
        uint256 amount = REQUESTS[request].amount;
        address user = REQUESTS[request].user;

        betid_process(betid, amount, user, words);
    }

    function betid_process(uint256 betid, uint256 amount, address user, uint256[] memory words) internal {
        BETS[betid].fulfilled = true;

        if(amount != 0) {
            initialize_amount(amount, user);
        }

        if(BETS[betid].round == ROUND.INITIAL) {
            process_initial(betid, words);
        }
        else if(BETS[betid].round == ROUND.ACTION) {
            uint idx;
            bool settle;
            bool blackjack;

            (idx, settle) = process_action(betid, words, idx);

            if(!BETS[betid].holecard) {
                (idx, blackjack) = process_blackjack(betid, words, idx);
            }

            if(blackjack || settle) {
                process_settled(betid, words, idx);
                BETS[betid].round = ROUND.SETTLED;
            }
        }
    }

    function process_initial(uint256 betid, uint256[] memory words) private {
        uint idx;
        for (uint i = 0; i < BETS[betid].hands.length; i++) {
            BETS[betid].hands[i].cards.push(get_card(words[idx]));
            idx += 1;

            BETS[betid].hands[i].cards.push(get_card(words[idx]));
            idx += 1;
        }
        BETS[betid].cards.push(get_card(words[idx]));
    }

    function process_action(uint256 betid, uint256[] memory words, uint idx) private returns (uint, bool) {
        bool settle = true;

        // Counter start from idx;
        for (uint i = 0; i < BETS[betid].hands.length; i++) {
            if(BETS[betid].hands[i].action == ACTION.HIT) {
                BETS[betid].hands[i].cards.push(get_card(words[idx]));
                settle = check_settle(BETS[betid].hands[i].cards, settle);
                idx += 1;
            }
            else if(BETS[betid].hands[i].action == ACTION.DOUBLEDOWN) {
                BETS[betid].hands[i].cards.push(get_card(words[idx]));
                BETS[betid].hands[i].action = ACTION.STAND;
                idx += 1;
            }
            else if(BETS[betid].hands[i].action == ACTION.SPLIT) {
                // update the second card;
                BETS[betid].hands[i].cards[1] = get_card(words[idx]);

                // check if this is a blackjack;
                settle = check_settle(BETS[betid].hands[i].cards, settle);
                idx += 1;
            }
            else if(BETS[betid].hands[i].action == ACTION.INSURANCE) {
                // check if this is a blackjack;
                settle = check_settle(BETS[betid].hands[i].cards, settle);
            }
        }
        return (idx, settle);
    }

    function process_blackjack(uint256 betid, uint256[] memory words, uint idx) private returns (uint, bool blackjack) {
        if (BETS[betid].cards[0] == 1 || BETS[betid].cards[0] <= 10) {
            uint256[] memory dealer = new uint256[](2);
            dealer[0] = BETS[betid].cards[0];
            dealer[1] = get_card(words[idx]);

            if (hand_value(dealer) == 21) {
                BETS[betid].cards.push(get_card(words[idx]));
                blackjack = true;
            }

            BETS[betid].holecard = true;
            idx += 1;
        }
        return (idx, blackjack);
    }

    function process_settled(uint256 betid, uint256[] memory words, uint idx) private {
        address player = BETS[betid].player;

        // Get a new card after `holecard`, total should not be 21;
        if (BETS[betid].holecard && BETS[betid].cards.length == 1) {
            // Add a new card with value 0;
            BETS[betid].cards.push(0);

            // Counter start from idx;
            for (uint i = idx; i < words.length; i++) {
                BETS[betid].cards[1] = get_card(words[i]);
                if (hand_value(BETS[betid].cards) != 21) {
                    idx = i + 1;
                    break;
                }
            }

        }

        // stand on soft 17;
        for (uint i = idx; i < words.length; i++) {
            if(hand_value(BETS[betid].cards) < 17 ) {
                BETS[betid].cards.push(get_card(words[i]));
            } else {
                break;
            }
        }

        // Dealer cards value;
        uint256 dealer = hand_value(BETS[betid].cards);

        for (uint i = 0; i < BETS[betid].hands.length; i++) {
            uint256 wager = BETS[betid].hands[i].wager;
            uint256 hand = hand_value(BETS[betid].hands[i].cards);

            // Player Surrender return half of the wager;
            // payout dose not returns the wager;
            if (BETS[betid].hands[i].action == ACTION.SURRENDER) {
                payout(wager / 2, player, 0, 1);
                continue;
            }

            // Player Insurance win when dealer has blackjack; Pay 2:1 on half of the wager for insurance;
            if (BETS[betid].hands[i].action == ACTION.INSURANCE && (dealer == 21 && BETS[betid].cards.length == 2)) {
                payout(wager / 2, player, 2, 1);
            }

            // Player is busted;
            if (hand > 21) {
                continue;
            }
            // Player Push it won't be over 21;
            else if (hand == dealer) {
                payout(wager, player, 0, 1);
                continue;
            }

            // Player hit blackjack in two cards; Pay 3:2 on wager;
            // We already checked for dealer blackjack;
            else if(hand == 21 && BETS[betid].hands[i].cards.length == 2) {
                payout(wager, player, 3, 2);
                continue;
            }
            // Dealer is busted OR Player has a better hand;
            else if(dealer > 21 || hand > dealer) {
                payout(wager, player, 1, 1);
            }
        }
    }

    function play(uint256 betid, uint256 amount, uint32 words) private returns (uint256) {
        uint256 request = request_words(words);

        REQUESTS[request] = REQUEST({
            bets: betid,
            amount: amount,
            user: msg.sender,
            words: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        require(amount <= DEPOSITS[msg.sender], "Insufficient user funds;");
        return request;
    }

    function get_card(uint256 source) private pure returns (uint256) {
        return (source % 13) == 0 ? 13 : (source % 13);
    }

    function view_request(uint256 request) public view returns (uint256, uint256, address, uint256[] memory, bool, bool) {
        return (REQUESTS[request].bets, REQUESTS[request].amount, REQUESTS[request].user, REQUESTS[request].words, REQUESTS[request].exists, REQUESTS[request].fulfilled);
    }
}
