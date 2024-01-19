// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "remix_tests.sol"; 
import "https://github.com/chain-xz/chain-xz/blob/main/token.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import "../slot.sol";

contract testSuite {

    XZTOKEN XZ;
    SLOT SLOTTEST;
    VRFCoordinatorV2Mock COORDINATOR;

    function beforeAll() public {
        bytes32 KEYHASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

        COORDINATOR = new VRFCoordinatorV2Mock(1 ether, 1000000);
        uint64 SUBID = COORDINATOR.createSubscription();

        COORDINATOR.fundSubscription(SUBID, 1000000 ether);

        XZ = new XZTOKEN();

        SLOTTEST = new SLOT(KEYHASH, SUBID, address(COORDINATOR), address(XZ));

        COORDINATOR.addConsumer(SUBID, address(SLOTTEST));

        XZ.client_add(address(SLOTTEST));
        XZ.approve(address(SLOTTEST), 21000000 ether);
    }

    /*
     * Test play amount
     * Single bet
     * Multiple bets
     */
    function test_play() public {
        uint256 amount = 30 ether;
        SLOTTEST.deposit(amount);
        SLOT.BET[] memory bets;

        // Single bet
        bets = new SLOT.BET[](1);
        bets[0].wager = 10 ether;

        SLOTTEST.play(bets);

        // Multiple bets
        bets = new SLOT.BET[](3);
        bets[0].wager = 10 ether;
        bets[1].wager = 10 ether;
        bets[2].wager = 10 ether;

        SLOTTEST.play(bets);

        // Withdraw deposit amount
        check_deposit(amount, amount);
        SLOTTEST.withdraw(amount);
    }

    /*
     * Test play bad bet
     * - Zero bets
     * - Extra amount
     */
    function test_bug() public {
        uint256 amount = 10 ether;
        SLOTTEST.deposit(amount);
        SLOT.BET[] memory bets;

        // Zero bets
        bets = new SLOT.BET[](0);
        play_bug(bets);

        // Extra amount
        bets = new SLOT.BET[](2);
        bets[0].wager = 10 ether;
        bets[1].wager = 10 ether;
        play_bug(bets);

        // Withdraw deposit amount
        check_deposit(amount, amount);
        SLOTTEST.withdraw(amount);
    }

    /*
     * Process bad bet
     */
    function play_bug(SLOT.BET[] memory bets) private {
        try SLOTTEST.play(bets) {
            Assert.ok(false, "Bad bets accepted;");
        } catch {
            Assert.ok(true, "Bad bets rejected;");
        }
    }

    /*
     * Test single bet win
     * 3 Bar
     * 3 Cherry
     * 3 Plum
     * 3 Watermelon
     * 3 Orange
     * 3 Lemon
     * 2 Cherry
     * 1 Cherry
     */
    function test_single_bet() public {
        uint256[3] memory words;

        // 3 Bar
        words[0] = 13;
        words[1] = 1;
        words[2] = 30;
        process_single_bet(words, 10 ether, 50000 ether);

        // 3 Cherry
        words[0] = 6;
        words[1] = 5;
        words[2] = 20;
        process_single_bet(words, 10 ether, 10000 ether);

        // 3 Plum
        words[0] = 2;
        words[1] = 18;
        words[2] = 4;
        process_single_bet(words, 10 ether, 2000 ether);

        // 3 Watermelon
        words[0] = 5;
        words[1] = 4;
        words[2] = 1;
        process_single_bet(words, 10 ether, 1000 ether);

        // 3 Orange
        words[0] = 0;
        words[1] = 2;
        words[2] = 6;
        process_single_bet(words, 10 ether, 500 ether);

        // 3 Lemon
        words[0] = 14;
        words[1] = 0;
        words[2] = 14;
        process_single_bet(words, 10 ether, 250 ether);

        // 2 Cherry
        words[0] = 6;
        words[1] = 5;
        words[2] = 0;
        process_single_bet(words, 10 ether, 100 ether);

        // 2 Cherry
        words[0] = 6;
        words[1] = 0;
        words[2] = 20;
        process_single_bet(words, 10 ether, 100 ether);

        // 2 Cherry
        words[0] = 0;
        words[1] = 5;
        words[2] = 20;
        process_single_bet(words, 10 ether, 100 ether);

        // 1 Cherry
        words[0] = 6;
        words[1] = 0;
        words[2] = 0;
        process_single_bet(words, 10 ether, 20 ether);

        // 1 Cherry
        words[0] = 0;
        words[1] = 5;
        words[2] = 0;
        process_single_bet(words, 10 ether, 20 ether);

        // 1 Cherry
        words[0] = 0;
        words[1] = 0;
        words[2] = 20;
        process_single_bet(words, 10 ether, 20 ether);
    }

    /*
     * Process Single bet win
     */
    function process_single_bet(uint256[3] memory words, uint256 wager, uint256 payout) private {
        SLOTTEST.deposit(10 ether);

        SLOT.BET[] memory bets = new SLOT.BET[](1);
        bets[0].wager = wager;

        uint256 request = SLOTTEST.play(bets);

        uint256[] memory rand_word = new uint256[](words.length);
        for (uint256 i = 0; i < words.length; i++) {
            rand_word[i] = words[i];
        }

        COORDINATOR.fulfillRandomWordsWithOverride(request, address(SLOTTEST), rand_word);

        if (payout != 0) {
            SLOTTEST.withdraw(wager);
            SLOTTEST.withdraw(payout);
        }
        check_deposit(0, 0);
    }

    /*
     * Test multiple bet win
     */
    function test_multiple() public {
        XZ.client_zero(address(SLOTTEST));

        SLOT.BET[] memory bets = new SLOT.BET[](12);
        for (uint256 i = 0; i < bets.length; i++) {
            bets[i].wager = 10 ether;
        }

        SLOTTEST.deposit(120 ether);
        uint256 request = SLOTTEST.play(bets);

        uint256[] memory words = new uint256[](36);
        words[0] = 13;
        words[1] = 1;
        words[2] = 30;
        words[3] = 6;
        words[4] = 5;
        words[5] = 20;
        words[6] = 2;
        words[7] = 18;
        words[8] = 4;
        words[9] = 5;
        words[10] = 4;
        words[11] = 1;
        words[12] = 0;
        words[13] = 2;
        words[14] = 6;
        words[15] = 14;
        words[16] = 0;
        words[17] = 14;
        words[18] = 6;
        words[19] = 5;
        words[20] = 0;
        words[21] = 6;
        words[22] = 0;
        words[23] = 20;
        words[24] = 0;
        words[25] = 5;
        words[26] = 20;
        words[27] = 6;
        words[28] = 0;
        words[29] = 0;
        words[30] = 0;
        words[31] = 5;
        words[32] = 0;
        words[33] = 0;
        words[34] = 0;
        words[35] = 20;

        COORDINATOR.fulfillRandomWordsWithOverride(request, address(SLOTTEST), words);

        SLOTTEST.withdraw(120 ether);
        SLOTTEST.withdraw(64110 ether);
        check_deposit(0, 0);
    }

    function check_deposit(uint256 total, uint256 user) private {
        (uint256 d_total, uint256 d_user) = SLOTTEST.deposits();
        Assert.equal(d_total, total, "Total deposit;");
        Assert.equal(d_user, user, "User deposit;");
    }
}
