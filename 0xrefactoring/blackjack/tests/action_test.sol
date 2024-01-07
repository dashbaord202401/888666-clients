// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./testcore.sol";

contract testSuite is BLACKJACKTESTSUITE {

    function beforeAll() public{
        before_all();
    }

    /*
     * Dealer Blackjack
     * 1. Player Blackjack
     * 2. Player Blackjack Insurance
     * 3. Player Insurance
     * 4. Player HIT PUSH
     * 5. Player HIT BUST
     * 6. Player HIT LOSE
     */
    function test_1() public {
        uint256 betid;
        uint256 bets;
        uint256 amount;
        uint256[] memory rand;
        BLACKJACK.ACTION[] memory action;

        bets = 6;
        amount = 6000 ether;

        // 6 Players so 12 cards and 1 dealer card
        rand = new uint256[](13);

        uint256[13] memory rand_init = [uint256(1), 10,
                                                1,  11,
                                                10,  7,
                                                10,  7,
                                                10,  7,
                                                10,  7,
                                                1];

        for(uint i = 0; i < rand_init.length; i++) {
            rand[i] = rand_init[i];
        }

        betid = initial(amount, bets, rand);

        // Action
        amount = 1000 ether;

        action = new BLACKJACK.ACTION[](6);
        action[0] = BLACKJACKCORE.ACTION.STAND;
        action[1] = BLACKJACKCORE.ACTION.INSURANCE;
        action[2] = BLACKJACKCORE.ACTION.INSURANCE;
        action[3] = BLACKJACKCORE.ACTION.HIT;
        action[4] = BLACKJACKCORE.ACTION.HIT;
        action[5] = BLACKJACKCORE.ACTION.HIT;

        // 3 hit so 3 cards and 13 default dealer card
        rand = new uint256[](16);

        uint256[16] memory rand_action = [uint256(4),   // Player 4
                                                  5,    // Player 5
                                                  2,    // Player 6
                                                  10,   // Dealer Blackjack process_blackjack
                                                  69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action.length; i++) {
            rand[i] = rand_action[i];
        }

        /*
         * 1000 ether
         * 1000 ether   500 ether 1000 ether
         * 0 ether      500 ether 1000 ether
         * 1000 ether
         * 0 ether
         * 0 ether
        */
        actions(amount, betid, action, rand, 6000 ether);
    }

    /*
     * Dealer ACE soft 17
     * 1. Player Insurance WIN
     * 2. Player Insurance LOSE
     * 3. Player Insurance TIE
     * 4. Player Insurance Double down BUST
     */
    function test_2() public {
        uint256 betid;
        uint256 bets;
        uint256 amount;
        uint256[] memory rand;
        BLACKJACK.ACTION[] memory action;

        bets = 4;
        amount = 4000 ether;

        // 4 Players so 8 cards and 1 dealer card
        rand = new uint256[](9);

        uint256[9] memory rand_init = [uint256(1), 7,
                                               1,  5,
                                               1,  6,
                                               10, 7,
                                               1];

        for(uint i = 0; i < rand_init.length; i++) {
            rand[i] = rand_init[i];
        }

        betid = initial(amount, bets, rand);

        // Action 1
        amount = 2000 ether;

        action = new BLACKJACK.ACTION[](4);
        action[0] = BLACKJACKCORE.ACTION.INSURANCE;
        action[1] = BLACKJACKCORE.ACTION.INSURANCE;
        action[2] = BLACKJACKCORE.ACTION.INSURANCE;
        action[3] = BLACKJACKCORE.ACTION.INSURANCE;

        // 13 default dealer card
        rand = new uint256[](13);

        uint256[13] memory rand_action = [uint256(6),   // Dealer !Blackjack process_blackjack
                                                  69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action.length; i++) {
            rand[i] = rand_action[i];
        }

        actions(amount, betid, action, rand, 0);

        // Action 2
        amount = 1000 ether;

        action = new BLACKJACK.ACTION[](4);
        action[0] = BLACKJACKCORE.ACTION.STAND;
        action[1] = BLACKJACKCORE.ACTION.STAND;
        action[2] = BLACKJACKCORE.ACTION.STAND;
        action[3] = BLACKJACKCORE.ACTION.DOUBLEDOWN;

        // 1 Double down, so 1 cards and 13 default dealer card
        rand = new uint256[](14);

        uint256[14] memory rand_action2 = [uint256(5),   // 4 Player bust
                                                    6,   // Dealer soft 17 process_settled
                                                   69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action2.length; i++) {
            rand[i] = rand_action2[i];
        }

        /*
         * 1000 ether   1000 ether
         * 0 ether
         * 1000 ether
         * 0 ether
         */
        actions(amount, betid, action, rand, 3000 ether);
    }

    /*
     * Dealer soft 17
     * 1. Player TIE
     * 2. Player DOUBLEDOWN WIN
     * 3. Player DOUBLEDOWN LOSE
     * 4. Player DOUBLEDOWN TIE
     * 5. Player DOUBLEDOWN BUST
     */
    function test_3() public {
        uint256 betid;
        uint256 bets;
        uint256 amount;
        uint256[] memory rand;
        BLACKJACK.ACTION[] memory action;

        bets = 5;
        amount = 5000 ether;

        // 5 Players so 10 cards and 1 dealer card
        rand = new uint256[](11);

        uint256[11] memory rand_init = [uint256(10), 7,
                                                10,  5,
                                                10,  5,
                                                10,  5,
                                                10,  5,
                                                12];

        for(uint i = 0; i < rand_init.length; i++) {
            rand[i] = rand_init[i];
        }

        betid = initial(amount, bets, rand);

        // Action
        amount = 4000 ether;

        action = new BLACKJACK.ACTION[](5);
        action[0] = BLACKJACKCORE.ACTION.STAND;
        action[1] = BLACKJACKCORE.ACTION.DOUBLEDOWN;
        action[2] = BLACKJACKCORE.ACTION.DOUBLEDOWN;
        action[3] = BLACKJACKCORE.ACTION.DOUBLEDOWN;
        action[4] = BLACKJACKCORE.ACTION.DOUBLEDOWN;

        // 4 Double down, so 4 cards and 13 default dealer card
        rand = new uint256[](17);

        uint256[17] memory rand_action = [uint256(7),   // 7 Dealer !Blackjack process_blackjack
                                                   3,   // Player 2
                                                   1,   // Player 3
                                                   2,   // Player 4
                                                   7,   // Player 5
                                                   1,   // Dealer should not become blackjack test
                                                   7,   // Dealer get new non blackjack card
                                                  69, 69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action.length; i++) {
            rand[i] = rand_action[i];
        }


        /* 
         * 1000 ether
         * 2000 ether 2000 ether
         * 0 ether
         * 2000 ether
         * 0 ether
         */
        actions(amount, betid, action, rand, 7000 ether);
    }


    /*
     * Dealer Bust
     * 1. Player SURRENDER
     * 2. Player ACE SPLIT WIN Blackjack
     * 2. Player ACE SPLIT WIN
     */
    function test_4() public {
        uint256 betid;
        uint256 bets;
        uint256 amount;
        uint256[] memory rand;
        BLACKJACK.ACTION[] memory action;

        bets = 2;
        amount = 2000 ether;

        // 2 Players so 4 cards and 1 dealer card
        rand = new uint256[](5);

        uint256[5] memory rand_init = [uint256(1), 7,
                                               1,  1,
                                               9];

        for(uint i = 0; i < rand_init.length; i++) {
            rand[i] = rand_init[i];
        }

        betid = initial(amount, bets, rand);


        // Action
        amount = 1000 ether;

        action = new BLACKJACK.ACTION[](2);
        action[0] = BLACKJACKCORE.ACTION.SURRENDER;
        action[1] = BLACKJACKCORE.ACTION.SPLIT;

        // 1 Split, so 2 cards and 13 default dealer card

        rand = new uint256[](15);
        uint256[15] memory rand_action = [uint256(13), // Player 2.1
                                                    9, // Player 2.2
                                                  69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action.length; i++) {
            rand[i] = rand_action[i];
        }

        actions(amount, betid, action, rand, 0);


        // Action 2
        amount = 0;

        action = new BLACKJACK.ACTION[](3);
        action[0] = BLACKJACKCORE.ACTION.STAND;
        action[1] = BLACKJACKCORE.ACTION.STAND;
        action[2] = BLACKJACKCORE.ACTION.STAND;

        // 13 default dealer card
        rand = new uint256[](13);

        uint256[13] memory rand_action2 = [uint256(2),
                                                    3,
                                                    2,
                                                    8,
                                                   69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action2.length; i++) {
            rand[i] = rand_action2[i];
        }

        /*
         * 500 ether
         * 1000 ether 1500 ether 3:2
         * 1000 ether 1000 ether
         */
        actions(amount, betid, action, rand, 5000 ether);
    }

    /*
     * Dealer 5 cards [19]
     * 1. Player SURRENDER
     * 2. Player SPLIT WIN
     * 2. Player SPLIT PUSH
     * 3. Player SPLIT LOSE
     * 3. Player SPLIT BUST
     */
    function test_5() public {
        uint256 betid;
        uint256 bets;
        uint256 amount;
        uint256[] memory rand;
        BLACKJACK.ACTION[] memory action;

        bets = 3;
        amount = 3000 ether;

        // 3 Players so 6 cards and 1 dealer card
        rand = new uint256[](7);

        uint256[7] memory rand_init = [uint256(12), 2,
                                               1,    1,
                                               11,  11,
                                               1];

        for(uint i = 0; i < rand_init.length; i++) {
            rand[i] = rand_init[i];
        }

        betid = initial(amount, bets, rand);


        // Action 1
        amount = 2000 ether;

        action = new BLACKJACK.ACTION[](3);
        action[0] = BLACKJACKCORE.ACTION.SURRENDER;
        action[1] = BLACKJACKCORE.ACTION.SPLIT;
        action[2] = BLACKJACKCORE.ACTION.SPLIT;

        // 2 Split, so 4 cards and 13 default dealer card

        rand = new uint256[](17);
        uint256[17] memory rand_action = [uint256(9),  // 2.1 Player  20
                                                   8,  // 2.2 Player  19
                                                   8,  // 3.1 Player  18
                                                   8,  // 3.2 Player  18
                                                  69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action.length; i++) {
            rand[i] = rand_action[i];
        }

        actions(amount, betid, action, rand, 0);

        // Action 2
        amount = 1000 ether;

        action = new BLACKJACK.ACTION[](5);
        action[0] = BLACKJACKCORE.ACTION.SURRENDER;
        action[1] = BLACKJACKCORE.ACTION.STAND;
        action[2] = BLACKJACKCORE.ACTION.STAND;
        action[3] = BLACKJACKCORE.ACTION.STAND;
        action[4] = BLACKJACKCORE.ACTION.HIT;

        // 1 Hit, so 1 cards and 13 default dealer card

        rand = new uint256[](14);

        uint256[14] memory rand_action2 = [uint256(7),   // 3.2 Player  18+7
                                                    3,   // Baker
                                                    10,  // Baker
                                                    1,   // Baker
                                                    4,   // Baker
                                                   69, 69, 69, 69, 69, 69, 69, 69, 69];

        for(uint i = 0; i < rand_action2.length; i++) {
            rand[i] = rand_action2[i];
        }

        /*
         * 500 ether
         * 2000 ether 2000 ether
         * 2000 ether
         * 0 ether
         * 0 ether
         */
        actions(amount, betid, action, rand, 4500 ether);
    }

    function initial(uint256 amount, uint256 bets, uint256[] memory rand) private returns (uint256 betid) {
        uint256 request;
        BLACKJACKTEST.deposit(amount);

        uint256[] memory _bets = new uint256[](bets);
        for (uint i = 0; i < bets; i++) {
            _bets[i] = 1000 ether;
        }

        (betid, request) = BLACKJACKTEST.play_initial(_bets);

        COORDINATOR.fulfillRandomWordsWithOverride(request, address(BLACKJACKTEST), rand);
        test_deposit(0, 0);
    }

    function actions(uint256 amount, uint256 betid, BLACKJACK.ACTION[] memory action, uint256[] memory rand, uint256 withdraw) private {
        uint256 _betid;
        uint256 request;
        if (amount > 0) {
            BLACKJACKTEST.deposit(amount);
        }

        (_betid, request) = BLACKJACKTEST.play_action(betid, action);

        COORDINATOR.fulfillRandomWordsWithOverride(request, address(BLACKJACKTEST), rand);

        if (withdraw > 0) {
            test_deposit(withdraw, withdraw);
            BLACKJACKTEST.withdraw(withdraw);
        }
    }
}