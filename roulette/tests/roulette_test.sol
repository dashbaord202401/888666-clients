// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "remix_tests.sol"; 
import "https://github.com/chain-xz/chain-xz/blob/main/token.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import "../roulette.sol";

contract testSuite {

    XZTOKEN XZ;
    ROULETTE ROULETTETEST;
    VRFCoordinatorV2Mock COORDINATOR;

    function beforeAll() public {
        bytes32 KEYHASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

        COORDINATOR = new VRFCoordinatorV2Mock(1 ether, 1000000);
        uint64 SUBID = COORDINATOR.createSubscription();

        COORDINATOR.fundSubscription(SUBID, 1000000 ether);

        XZ = new XZTOKEN();

        ROULETTETEST = new ROULETTE(KEYHASH, SUBID, address(COORDINATOR), address(XZ));

        COORDINATOR.addConsumer(SUBID, address(ROULETTETEST));

        XZ.client_add(address(ROULETTETEST));
        XZ.approve(address(ROULETTETEST), 21000000 ether);
    }

    /*
     * Test single bets
     * - Straight bets amount
     * - Split bets amount
     * - Street bets amount
     * - Corner bets amount
     * - Sixline bets amount
     * - Dozencolumn bets amount
     * - Evenmoney bets amount
    */
    function test_play_single() public {
        uint256 amount = 5000 ether;
        ROULETTETEST.deposit(amount);

        play_single(ROULETTE.BETS.STRAIGHT, 5 ether, 1);
        play_single(ROULETTE.BETS.STRAIGHT, 200 ether, 1);

        play_single(ROULETTE.BETS.SPLIT, 5 ether, 2);
        play_single(ROULETTE.BETS.SPLIT, 400 ether, 2);

        play_single(ROULETTE.BETS.STREET, 5 ether, 3);
        play_single(ROULETTE.BETS.STREET, 600 ether, 3);

        play_single(ROULETTE.BETS.CORNER, 5 ether, 4);
        play_single(ROULETTE.BETS.CORNER, 800 ether, 4);

        play_single(ROULETTE.BETS.SIXLINE, 5 ether, 6);
        play_single(ROULETTE.BETS.SIXLINE, 1200 ether, 6);

        play_single(ROULETTE.BETS.DOZENCOLUMN, 10 ether, 12);
        play_single(ROULETTE.BETS.DOZENCOLUMN, 2500 ether, 12);

        play_single(ROULETTE.BETS.EVENMONEY, 10 ether, 18);
        play_single(ROULETTE.BETS.EVENMONEY, 5000 ether, 18);

        ROULETTETEST.withdraw(amount);
        check_deposit(0, 0);
    }

    function play_single(ROULETTE.BETS bet, uint256 wager, uint256 length) private {
        ROULETTE.BET[] memory bets = new ROULETTE.BET[](1);

        bets[0].bet = bet;
        bets[0].number = new uint256[](length);
        bets[0].wager = wager;

        for (uint256 i = 0; i < length; i++) {
            bets[0].number[i] = i;
        }

        ROULETTETEST.play(bets);
    }

    /*
     * Test multiple bets
     * - Straight-Split bets amount
     * - Split-Street bets amount
     * - Street-Corner bets amount
     * - Corner-Sixline bets amount
     * - Sixline-Dozencolumn bets amount
     * - Dozencolumn-Evenmoney bets amount
     * - Evenmoney-Straight bets amount
    */
    function test_play_multiple() public {
        uint256 amount = 10000 ether;
        ROULETTETEST.deposit(amount);

        ROULETTE.BETS[2] memory bet;
        uint256[2] memory wager;
        uint256[2] memory length;

        bet[0] = ROULETTE.BETS.STRAIGHT;
        bet[1] = ROULETTE.BETS.SPLIT;
        wager[0] = 5 ether;
        wager[1] = 400 ether;
        length[0] = 1;
        length[1] = 2;
        play_multiple(bet, wager, length);

        bet[0] = ROULETTE.BETS.SPLIT;
        bet[1] = ROULETTE.BETS.STREET;
        wager[0] = 5 ether;
        wager[1] = 600 ether;
        length[0] = 2;
        length[1] = 3;
        play_multiple(bet, wager, length);

        bet[0] = ROULETTE.BETS.STREET;
        bet[1] = ROULETTE.BETS.CORNER;
        wager[0] = 5 ether;
        wager[1] = 800 ether;
        length[0] = 3;
        length[1] = 4;
        play_multiple(bet, wager, length);

        bet[0] = ROULETTE.BETS.CORNER;
        bet[1] = ROULETTE.BETS.SIXLINE;
        wager[0] = 5 ether;
        wager[1] = 1200 ether;
        length[0] = 4;
        length[1] = 6;
        play_multiple(bet, wager, length);

        bet[0] = ROULETTE.BETS.SIXLINE;
        bet[1] = ROULETTE.BETS.DOZENCOLUMN;
        wager[0] = 5 ether;
        wager[1] = 2500 ether;
        length[0] = 6;
        length[1] = 12;
        play_multiple(bet, wager, length);

        bet[0] = ROULETTE.BETS.DOZENCOLUMN;
        bet[1] = ROULETTE.BETS.EVENMONEY;
        wager[0] = 10 ether;
        wager[1] = 5000 ether;
        length[0] = 12;
        length[1] = 18;
        play_multiple(bet, wager, length);

        bet[0] = ROULETTE.BETS.EVENMONEY;
        bet[1] = ROULETTE.BETS.STRAIGHT;
        wager[0] = 10 ether;
        wager[1] = 200 ether;
        length[0] = 18;
        length[1] = 1;
        play_multiple(bet, wager, length);

        ROULETTETEST.withdraw(amount);
        check_deposit(0, 0);
    }

    function play_multiple(ROULETTE.BETS[2] memory bet, uint256[2] memory wager, uint256[2] memory length) private {
        ROULETTE.BET[] memory bets = new ROULETTE.BET[](2);

        bets[0].bet = bet[0];
        bets[1].bet = bet[1];

        bets[0].number = new uint256[](length[0]);
        bets[1].number = new uint256[](length[1]);

        bets[0].wager = wager[0];
        bets[1].wager = wager[1];

        for (uint256 i = 0; i < length[0]; i++) {
            bets[0].number[i] = i;
        }

        for (uint256 i = 0; i < length[1]; i++) {
            bets[1].number[i] = i;
        }

        ROULETTETEST.play(bets);
    }

    /*
     * Test buggy bets
     * - Bet limit
     * - Zero bets
     * - Extra amount
     */
    function test_play_bug() public {
        uint256 amount = 10000 ether;
        ROULETTETEST.deposit(amount);

        ROULETTE.BET[] memory bets;

        // Bet limit
        bug_single(ROULETTE.BETS.STRAIGHT, 4 ether, 1);
        bug_single(ROULETTE.BETS.STRAIGHT, 201 ether, 1);
        bug_single(ROULETTE.BETS.STRAIGHT, 5 ether, 0);
        bug_single(ROULETTE.BETS.STRAIGHT, 200 ether, 2);

        bug_single(ROULETTE.BETS.SPLIT, 4 ether, 2);
        bug_single(ROULETTE.BETS.SPLIT, 401 ether, 2);
        bug_single(ROULETTE.BETS.SPLIT, 5 ether, 1);
        bug_single(ROULETTE.BETS.SPLIT, 400 ether, 3);

        bug_single(ROULETTE.BETS.STREET, 4 ether, 3);
        bug_single(ROULETTE.BETS.STREET, 601 ether, 3);
        bug_single(ROULETTE.BETS.STREET, 5 ether, 2);
        bug_single(ROULETTE.BETS.STREET, 600 ether, 4);

        bug_single(ROULETTE.BETS.CORNER, 4 ether, 4);
        bug_single(ROULETTE.BETS.CORNER, 801 ether, 4);
        bug_single(ROULETTE.BETS.CORNER, 5 ether, 3);
        bug_single(ROULETTE.BETS.CORNER, 800 ether, 5);

        bug_single(ROULETTE.BETS.SIXLINE, 4 ether, 6);
        bug_single(ROULETTE.BETS.SIXLINE, 1201 ether, 6);
        bug_single(ROULETTE.BETS.SIXLINE, 4 ether, 5);
        bug_single(ROULETTE.BETS.SIXLINE, 1201 ether, 7);

        bug_single(ROULETTE.BETS.DOZENCOLUMN, 9 ether, 12);
        bug_single(ROULETTE.BETS.DOZENCOLUMN, 2501 ether, 12);
        bug_single(ROULETTE.BETS.DOZENCOLUMN, 10 ether, 11);
        bug_single(ROULETTE.BETS.DOZENCOLUMN, 2500 ether, 13);

        bug_single(ROULETTE.BETS.EVENMONEY, 9 ether, 18);
        bug_single(ROULETTE.BETS.EVENMONEY, 5001 ether, 18);
        bug_single(ROULETTE.BETS.EVENMONEY, 10 ether, 17);
        bug_single(ROULETTE.BETS.EVENMONEY, 5000 ether, 19);

        // Zero bets
        bets = new ROULETTE.BET[](0);

        try ROULETTETEST.play(bets) {
            Assert.ok(false, "Bad bet accepted;");
        } catch {
            Assert.ok(true, "Bad bet rejected;");
        }

        // Extra amount
        bets = new ROULETTE.BET[](3);

        bets[0].bet = ROULETTE.BETS.STRAIGHT;
        bets[1].bet = ROULETTE.BETS.STRAIGHT;
        bets[2].bet = ROULETTE.BETS.STRAIGHT;

        bets[0].number = new uint256[](1);
        bets[1].number = new uint256[](1);
        bets[2].number = new uint256[](1);

        bets[0].number[0] = 0;
        bets[1].number[0] = 1;
        bets[2].number[0] = 2;

        bets[0].wager = 5000 ether;
        bets[1].wager = 5000 ether;
        bets[2].wager = 5000 ether;

        try ROULETTETEST.play(bets) {
            Assert.ok(false, "Bad bet accepted;");
        } catch {
            Assert.ok(true, "Bad bet rejected;");
        }

        ROULETTETEST.withdraw(amount);
        check_deposit(0, 0);
    }

    function bug_single(ROULETTE.BETS bet, uint256 wager, uint256 length) private {
        ROULETTE.BET[] memory bets = new ROULETTE.BET[](1);

        bets[0].bet = bet;
        bets[0].number = new uint256[](length);
        bets[0].wager = wager;

        for (uint256 i = 0; i < length; i++) {
            bets[0].number[i] = i;
        }

        try ROULETTETEST.play(bets) {
            Assert.ok(false, "Bad bet accepted;");
        } catch {
            Assert.ok(true, "Bad bet rejected;");
        }
    }

    /*
     * Test process bets
     * - Straight bets
     * - Split bets
     * - Street bets
     * - Corner bets
     * - Sixline bets
     * - Dozencolumn bets
     * - Evenmoney bets
    */
    function test_process_single() public {
        // Winning bets
        process_single(100 ether, ROULETTE.BETS.STRAIGHT,     1,  0, 100 ether, 3500 ether);
        process_single(100 ether, ROULETTE.BETS.SPLIT,        2,  0, 100 ether, 1700 ether);
        process_single(100 ether, ROULETTE.BETS.STREET,       3,  0, 100 ether, 1100 ether);
        process_single(100 ether, ROULETTE.BETS.CORNER,       4,  0, 100 ether, 800 ether);
        process_single(100 ether, ROULETTE.BETS.SIXLINE,      6,  0, 100 ether, 500 ether);
        process_single(100 ether, ROULETTE.BETS.DOZENCOLUMN, 12,  0, 100 ether, 200 ether);
        process_single(100 ether, ROULETTE.BETS.EVENMONEY,   18,  0, 100 ether, 100 ether);

        // Losing bets
        process_single(100 ether, ROULETTE.BETS.STRAIGHT,     1,  1, 100 ether, 0);
        process_single(100 ether, ROULETTE.BETS.SPLIT,        2,  2, 100 ether, 0);
        process_single(100 ether, ROULETTE.BETS.STREET,       3,  3, 100 ether, 0);
        process_single(100 ether, ROULETTE.BETS.CORNER,       4,  4, 100 ether, 0);
        process_single(100 ether, ROULETTE.BETS.SIXLINE,      6,  6, 100 ether, 0);
        process_single(100 ether, ROULETTE.BETS.DOZENCOLUMN, 12, 12, 100 ether, 0);
        process_single(100 ether, ROULETTE.BETS.EVENMONEY,   18, 18, 100 ether, 0);
    }

    /*
     * deposit: Deposit amount
     * bet: Bet type
     * length: Bet length
     * word: Random word
     * wager: Bet amount
     * payout: Winning amount
     */
    function process_single(uint256 deposit, ROULETTE.BETS bet, uint16 length, uint256 word, uint256 wager, uint256 payout) private {
        ROULETTETEST.deposit(deposit);

        ROULETTE.BET[] memory bets = new ROULETTE.BET[](1);

        bets[0].bet = bet;
        bets[0].number = new uint256[](length);
        bets[0].wager = wager;

        for (uint256 i = 0; i < length; i++) {
            bets[0].number[i] = i;
        }

        uint256 request = ROULETTETEST.play(bets);

        uint256[] memory rand_word = new uint256[](1);
        rand_word[0] = word;
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(ROULETTETEST), rand_word);

        if (payout != 0) {
            ROULETTETEST.withdraw(wager);
            ROULETTETEST.withdraw(payout);
        }
        check_deposit(0, 0);
    }

    /*
     * Test multiple bets
     * - Straight-Split bets amount
     * - Split-Street bets amount
     * - Street-Corner bets amount
     * - Corner-Sixline bets amount
     * - Sixline-Dozencolumn bets amount
     * - Dozencolumn-Evenmoney bets amount
     * - Evenmoney-Straight bets amount
    */
    function test_process_multiple() public {
        ROULETTE.BETS[2] memory bet;
        uint256[2] memory length;
        uint256[2] memory wager;

        wager[0] = 100 ether;
        wager[1] = 100 ether;


        bet[0] = ROULETTE.BETS.STRAIGHT;
        bet[1] = ROULETTE.BETS.SPLIT;
        length[0] = 1;
        length[1] = 2;
        process_multiple(200 ether, bet, length, wager, 0, 200 ether, 5200 ether);
        process_multiple(200 ether, bet, length, wager, 1, 100 ether, 1700 ether);

        bet[0] = ROULETTE.BETS.SPLIT;
        bet[1] = ROULETTE.BETS.STREET;
        length[0] = 2;
        length[1] = 3;
        process_multiple(200 ether, bet, length, wager, 0, 200 ether, 2800 ether);
        process_multiple(200 ether, bet, length, wager, 2, 100 ether, 1100 ether);

        bet[0] = ROULETTE.BETS.STREET;
        bet[1] = ROULETTE.BETS.CORNER;
        length[0] = 3;
        length[1] = 4;
        process_multiple(200 ether, bet, length, wager, 0, 200 ether, 1900 ether);
        process_multiple(200 ether, bet, length, wager, 3, 100 ether, 800 ether);

        bet[0] = ROULETTE.BETS.CORNER;
        bet[1] = ROULETTE.BETS.SIXLINE;
        length[0] = 4;
        length[1] = 6;
        process_multiple(200 ether, bet, length, wager, 0, 200 ether, 1300 ether);
        process_multiple(200 ether, bet, length, wager, 4, 100 ether, 500 ether);

        bet[0] = ROULETTE.BETS.SIXLINE;
        bet[1] = ROULETTE.BETS.DOZENCOLUMN;
        length[0] = 6;
        length[1] = 12;
        process_multiple(200 ether, bet, length, wager, 0, 200 ether, 700 ether);
        process_multiple(200 ether, bet, length, wager, 6, 100 ether, 200 ether);

        bet[0] = ROULETTE.BETS.DOZENCOLUMN;
        bet[1] = ROULETTE.BETS.EVENMONEY;
        length[0] = 12;
        length[1] = 18;
        process_multiple(200 ether, bet, length, wager,  0, 200 ether, 300 ether);
        process_multiple(200 ether, bet, length, wager, 12, 100 ether, 100 ether);

        bet[0] = ROULETTE.BETS.EVENMONEY;
        bet[1] = ROULETTE.BETS.STRAIGHT;
        length[0] = 18;
        length[1] = 1;
        process_multiple(200 ether, bet, length, wager,  0, 200 ether, 3600 ether);
    }

    /*
     * deposit: Deposit amount
     * bet: two bet types
     * length: two bet length
     * wager: two bet amount
     * word: Random word
     * win_wager: winning bet amount
     * payout: winning amount
     */
    function process_multiple(uint256 deposit, ROULETTE.BETS[2] memory bet, uint256[2] memory length, uint256[2] memory wager, uint256 word, uint256 win_wager, uint256 payout) private {
        ROULETTETEST.deposit(deposit);
        ROULETTE.BET[] memory bets = new ROULETTE.BET[](2);

        bets[0].bet = bet[0];
        bets[1].bet = bet[1];

        bets[0].number = new uint256[](length[0]);
        bets[1].number = new uint256[](length[1]);

        bets[0].wager = wager[0];
        bets[1].wager = wager[1];

        for (uint256 i = 0; i < length[0]; i++) {
            bets[0].number[i] = i;
        }

        for (uint256 i = 0; i < length[1]; i++) {
            bets[1].number[i] = i;
        }

        uint256 request = ROULETTETEST.play(bets);

        uint256[] memory rand_word = new uint256[](1);
        rand_word[0] = word;
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(ROULETTETEST), rand_word);

        if (payout != 0) {
            ROULETTETEST.withdraw(win_wager);
            ROULETTETEST.withdraw(payout);
        }
        check_deposit(0, 0);
    }

    function check_deposit(uint256 total, uint256 user) private {
        (uint256 d_total, uint256 d_user) = ROULETTETEST.deposits();
        Assert.equal(d_total, total, "Total deposit;");
        Assert.equal(d_user, user, "User deposit;");
    }
}
