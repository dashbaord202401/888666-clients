// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "remix_tests.sol"; 
import "https://github.com/chain-xz/chain-xz/blob/main/token.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import "../baccarat.sol";

contract testSuite {

    XZTOKEN XZ;
    BACCARAT BACCARATTEST;
    VRFCoordinatorV2Mock COORDINATOR;

    function beforeAll() public {
        bytes32 KEYHASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

        COORDINATOR = new VRFCoordinatorV2Mock(1 ether, 1000000);
        uint64 SUBID = COORDINATOR.createSubscription();

        COORDINATOR.fundSubscription(SUBID, 1000000 ether);

        XZ = new XZTOKEN();

        BACCARATTEST = new BACCARAT(KEYHASH, SUBID, address(COORDINATOR), address(XZ));

        COORDINATOR.addConsumer(SUBID, address(BACCARATTEST));

        XZ.client_add(address(BACCARATTEST));
        XZ.approve(address(BACCARATTEST), 21000000 ether);
    }

    /*
     * Test single bets
     * - Player bets amount
     * - Banker bets amount
     * - Tie bets amount
    */
    function test_play_single() public {
        uint256 amount = 5000 ether;

        BACCARATTEST.deposit(amount);
        BACCARAT.BET[] memory bets;
        bets = new BACCARAT.BET[](1);

        // Player
        bets[0].hand = BACCARAT.HANDS.PLAYER;

        bets[0].wager = 25 ether;
        BACCARATTEST.play(bets);
        bets[0].wager = 5000 ether;
        BACCARATTEST.play(bets);

        // Banker
        bets[0].hand = BACCARAT.HANDS.BANKER;

        bets[0].wager = 25 ether;
        BACCARATTEST.play(bets);
        bets[0].wager = 5000 ether;
        BACCARATTEST.play(bets);

        // Tie
        bets[0].hand = BACCARAT.HANDS.TIE;

        bets[0].wager = 10 ether;
        BACCARATTEST.play(bets);
        bets[0].wager = 100 ether;
        BACCARATTEST.play(bets);


        check_deposit(amount, amount);
        BACCARATTEST.withdraw(amount);
    }

    /*
     * Test multiple bets
     * - Player and Tie
     * - Banker and Tie
    */
    function test_play_multiple() public {
        uint256 amount = 5000 ether;

        BACCARATTEST.deposit(amount);
        BACCARAT.BET[] memory bets;
        bets = new BACCARAT.BET[](2);

        // Player and Tie
        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 100 ether;
        bets[1].hand = BACCARAT.HANDS.TIE;
        bets[1].wager = 100 ether;
        BACCARATTEST.play(bets);

        // Banker and Tie
        bets[0].hand = BACCARAT.HANDS.BANKER;
        bets[0].wager = 100 ether;
        bets[1].hand = BACCARAT.HANDS.TIE;
        bets[1].wager = 100 ether;
        BACCARATTEST.play(bets);


        check_deposit(amount, amount);
        BACCARATTEST.withdraw(amount);
    }

    /*
     * Test buggy bets
     * - Player Limit
     * - Banker Limit
     * - Tie Limit
     * - Zero bets
     * - Extra bets
     * - Extra amount
     */
    function test_play_bug() public {
        uint256 amount = 5000 ether;

        BACCARATTEST.deposit(amount);
        BACCARAT.BET[] memory bets;
        bets = new BACCARAT.BET[](1);

        // Player Limit
        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 24 ether;
        play_bug(bets);

        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 5001 ether;
        play_bug(bets);

        // Banker Limit
        bets[0].hand = BACCARAT.HANDS.BANKER;
        bets[0].wager = 24 ether;
        play_bug(bets);

        bets[0].hand = BACCARAT.HANDS.BANKER;
        bets[0].wager = 5001 ether;
        play_bug(bets);

        // Tie Limit
        bets[0].hand = BACCARAT.HANDS.TIE;
        bets[0].wager = 9 ether;
        play_bug(bets);

        bets[0].hand = BACCARAT.HANDS.TIE;
        bets[0].wager = 101 ether;
        play_bug(bets);

        // Zero bets
        bets = new BACCARAT.BET[](0);
        play_bug(bets);

        // Extra bets
        bets = new BACCARAT.BET[](3);

        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 100 ether;
        bets[1].hand = BACCARAT.HANDS.BANKER;
        bets[1].wager = 100 ether;
        bets[2].hand = BACCARAT.HANDS.TIE;
        bets[2].wager = 100 ether;
        play_bug(bets);

        // Extra amount
        bets = new BACCARAT.BET[](2);

        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 5000 ether;

        bets[1].hand = BACCARAT.HANDS.TIE;
        bets[1].wager = 100 ether;
        play_bug(bets);


        check_deposit(amount, amount);
        BACCARATTEST.withdraw(amount);
    }

    function play_bug(BACCARAT.BET[] memory bets) private {
        try BACCARATTEST.play(bets) {
            Assert.ok(false, "Bad bets accepted;");
        } catch {
            Assert.ok(true, "Bad bets rejected;");
        }
    }

    /*
     * Player process
     */
    function test_process_player() public {
        BACCARAT.BET[] memory bets;
        uint256[6] memory rand_word;

        bets = new BACCARAT.BET[](1);
        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 100 ether;

        /*
         * Player 9 0
         * Banker 8 0
         */
        rand_word = [uint256(9), 0, 0, 8, 0, 0];
        test_bets(100 ether, bets, rand_word, 100 ether, 100 ether);

        /*
         * Player 2 3 4
         * Banker 7 0 0
         */
        rand_word = [uint256(2), 3, 4, 7, 0, 0];
        test_bets(100 ether, bets, rand_word, 100 ether, 100 ether);

        /*
         * Player 2 3
         * Banker 8 0
         * banker natural win
         */
        rand_word = [uint256(2), 3, 4, 8, 0, 0];
        test_bets(100 ether, bets, rand_word, 100 ether, 0);
    }

    /*
     * Banker process
     */
    function test_process_banker() public {
        BACCARAT.BET[] memory bets;
        uint256[6] memory rand_word;

        bets = new BACCARAT.BET[](1);
        bets[0].hand = BACCARAT.HANDS.BANKER;
        bets[0].wager = 100 ether;

        /*
         * Player 8 0
         * Banker 9 0
         */
        rand_word = [uint256(8), 0, 0, 9, 0, 0];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);

        /*
         * Player 7 0
         * Banker 2 3 4
         * player stood, banker regards only their own hand and acts according to the same rule as the player.
         */
        rand_word = [uint256(7), 0, 0, 2, 3, 4];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);

        /*
         * Player 8 0
         * Banker 2 3
         * player natural win
         */
        rand_word = [uint256(8), 0, 0, 2, 3, 4];
        test_bets(100 ether, bets, rand_word, 100 ether, 0);

        /*
         * Player 1 0 7
         * Banker 2 0 7
         * If the banker total is 2 or less, they draw a third card regardless of what the player's third card is.
         */
        rand_word = [uint256(1), 0, 7, 2, 0, 7];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);

        /*
         * Player 1 0 9
         * Banker 3 0 6
         * If the banker total is 3, they draw a third card unless the player's third card is an 8.
         */
        rand_word = [uint256(1), 0, 9, 3, 0, 6];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);

        /*
         * Player 1 0 2
         * Banker 4 0 5
         * If the banker total is 4, they draw a third card if the player's third card is 2, 3, 4, 5, 6, or 7.
         */
        rand_word = [uint256(1), 0, 2, 4, 0, 5];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);

        /*
         * Player 1 0 5
         * Banker 5 0 4
         * If the banker total is 5, they draw a third card if the player's third card is 4, 5, 6, or 7.
         */
        rand_word = [uint256(1), 0, 5, 5, 0, 4];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);

        /*
         * Player 1 0 6
         * Banker 6 0 3
         * If the banker total is 6, they draw a third card if the player's third card is a 6 or 7.
         */
        rand_word = [uint256(1), 0, 6, 6, 0, 3];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);

        /*
         * Player 1 0 5
         * Banker 7 0 5
         * If the banker total is 7, they stand.
         */
        rand_word = [uint256(1), 0, 5, 7, 0, 5];
        test_bets(100 ether, bets, rand_word, 100 ether, 95 ether);
    }

    /*
     * Tie process
     */
    function test_process_tie() public {
        BACCARAT.BET[] memory bets;
        uint256[6] memory rand_word;

        bets = new BACCARAT.BET[](1);
        bets[0].hand = BACCARAT.HANDS.TIE;
        bets[0].wager = 100 ether;

        /*
         * Player 9 0
         * Banker 9 0
         */
        rand_word = [uint256(9), 0, 0, 9, 0, 0];
        test_bets(100 ether, bets, rand_word, 100 ether, 800 ether);

        /*
         * Player 6 0 
         * Banker 6 0
         * Both are on stand
         */
        rand_word = [uint256(6), 0, 0, 6, 0, 0];
        test_bets(100 ether, bets, rand_word, 100 ether, 800 ether);

        /*
         * Player 8 3
         * Banker 1 0
         */
        rand_word = [uint256(8), 3, 0, 1, 0, 0];
        test_bets(100 ether, bets, rand_word, 100 ether, 800 ether);

    }

    /*
     * PUSH bet process
     */
    function test_process_push() public {
        // Player PUSH 50-50 ether withdraw
        BACCARAT.BET[] memory bets;
        uint256[6] memory rand_word;

        bets = new BACCARAT.BET[](1);
        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 100 ether;

        /*
         * Player 4 0 5
         * Banker 5 0 4
         */
        rand_word = [uint256(4), 0, 5, 5, 0, 4];
        test_bets(100 ether, bets, rand_word, 50 ether, 50 ether);        

        bets = new BACCARAT.BET[](1);
        bets[0].hand = BACCARAT.HANDS.BANKER;
        bets[0].wager = 100 ether;

        /*
         * Player 4 0 4
         * Banker 5 0 3
         */
        rand_word = [uint256(4), 0, 4, 5, 0, 3];
        test_bets(100 ether, bets, rand_word, 50 ether, 50 ether);
    }

    /*
     * Multiple process
     */
    function test_process_multiple() public {
        // Player PUSH 50-50 ether withdraw
        BACCARAT.BET[] memory bets;
        uint256[6] memory rand_word;

        bets = new BACCARAT.BET[](2);

        bets[0].hand = BACCARAT.HANDS.PLAYER;
        bets[0].wager = 100 ether;
        bets[1].hand = BACCARAT.HANDS.TIE;
        bets[1].wager = 100 ether;

        /*
         * Player 9 0
         * Banker 9 0
         * PUSH for player
         */
        rand_word = [uint256(9), 0, 0, 9, 0, 0];
        test_bets(200 ether, bets, rand_word, 200 ether, 800 ether);

        /*
         * Player 8 0
         * Banker 6 0
         */
        rand_word = [uint256(8), 0, 0, 6, 0, 0];
        test_bets(200 ether, bets, rand_word, 100 ether, 100 ether);

        bets[0].hand = BACCARAT.HANDS.BANKER;
        bets[0].wager = 100 ether;
        bets[1].hand = BACCARAT.HANDS.TIE;
        bets[1].wager = 100 ether;

        /*
         * Player 9 0
         * Banker 9 0
         * PUSH for Banker
         */
        rand_word = [uint256(9), 0, 0, 9, 0, 0];
        test_bets(200 ether, bets, rand_word, 200 ether, 800 ether);

        /*
         * Player 6 0
         * Banker 8 0
         */
        rand_word = [uint256(6), 0, 0, 8, 0, 0];
        test_bets(200 ether, bets, rand_word, 100 ether, 95 ether);
    }

    /*
     * deposit  amount needed to perform tx
     * bets     bets
     * words    random words for bets
     * wager    win bet wager amount
     * payout   win bet payout amount
     */
    function test_bets(uint256 deposit, BACCARAT.BET[] memory bets, uint256[6] memory words, uint256 wager, uint256 payout) private {
        BACCARATTEST.deposit(deposit);

        uint256 request = BACCARATTEST.play(bets);

        uint256[] memory rand_word = new uint256[](words.length);
        for (uint i = 0; i < rand_word.length; i++) {
            rand_word[i] = words[i];
        }
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(BACCARATTEST), rand_word);

        if (payout != 0) {
            BACCARATTEST.withdraw(wager);
            BACCARATTEST.withdraw(payout);
        }
        check_deposit(0, 0);
    }

    function check_deposit(uint256 total, uint256 user) private {
        (uint256 d_total, uint256 d_user) = BACCARATTEST.deposits();
        Assert.equal(d_total, total, "Total deposit;");
        Assert.equal(d_user, user, "User deposit;");
    }
}
