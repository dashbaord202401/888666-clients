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
     * Test play amount
     * - Straight bets amount
     * - Split bets amount
     * - Street bets amount
     * - Corner bets amount
     * - Sixline bets amount
     * - Dozencolumn bets amount
     * - Evenmoney bets amount
    */
    function test_play() public {
        uint256 amount = 15000 ether;
        ROULETTETEST.deposit(amount);

        ROULETTE.BET[] memory bets = new ROULETTE.BET[](14);


        // Straight bets
        bets[0].bet = ROULETTE.BETS.STRAIGHT;
        bets[0].wager = 5 ether;
        bets[0].number = new uint256[](1);
        for (uint256 i = 0; i < bets[0].number.length; i++) {
            bets[0].number[i] = i;
        }

        bets[1].bet = ROULETTE.BETS.STRAIGHT;
        bets[1].wager = 200 ether;
        bets[1].number = new uint256[](1);
        for (uint256 i = 0; i < bets[1].number.length; i++) {
            bets[1].number[i] = i;
        }

        // Split bets
        bets[2].bet = ROULETTE.BETS.SPLIT;
        bets[2].wager = 5 ether;
        bets[2].number = new uint256[](2);
        for (uint256 i = 0; i < bets[2].number.length; i++) {
            bets[2].number[i] = i;
        }

        bets[3].bet = ROULETTE.BETS.SPLIT;
        bets[3].wager = 400 ether;
        bets[3].number = new uint256[](2);
        for (uint256 i = 0; i < bets[3].number.length; i++) {
            bets[3].number[i] = i;
        }

        // Street bets
        bets[4].bet = ROULETTE.BETS.STREET;
        bets[4].wager = 5 ether;
        bets[4].number = new uint256[](3);
        for (uint256 i = 0; i < bets[4].number.length; i++) {
            bets[4].number[i] = i;
        }

        bets[5].bet = ROULETTE.BETS.STREET;
        bets[5].wager = 600 ether;
        bets[5].number = new uint256[](3);
        for (uint256 i = 0; i < bets[5].number.length; i++) {
            bets[5].number[i] = i;
        }

        // Corner bets
        bets[6].bet = ROULETTE.BETS.CORNER;
        bets[6].wager = 5 ether;
        bets[6].number = new uint256[](4);
        for (uint256 i = 0; i < bets[6].number.length; i++) {
            bets[6].number[i] = i;
        }

        bets[7].bet = ROULETTE.BETS.CORNER;
        bets[7].wager = 800 ether;
        bets[7].number = new uint256[](4);
        for (uint256 i = 0; i < bets[7].number.length; i++) {
            bets[7].number[i] = i;
        }

        // Sixline bets
        bets[8].bet = ROULETTE.BETS.SIXLINE;
        bets[8].wager = 5 ether;
        bets[8].number = new uint256[](6);
        for (uint256 i = 0; i < bets[8].number.length; i++) {
            bets[8].number[i] = i;
        }

        bets[9].bet = ROULETTE.BETS.SIXLINE;
        bets[9].wager = 1200 ether;
        bets[9].number = new uint256[](6);
        for (uint256 i = 0; i < bets[9].number.length; i++) {
            bets[9].number[i] = i;
        }

        // Dozencolumn bets
        bets[10].bet = ROULETTE.BETS.DOZENCOLUMN;
        bets[10].wager = 10 ether;
        bets[10].number = new uint256[](12);
        for (uint256 i = 0; i < bets[10].number.length; i++) {
            bets[10].number[i] = i;
        }

        bets[11].bet = ROULETTE.BETS.DOZENCOLUMN;
        bets[11].wager = 2500 ether;
        bets[11].number = new uint256[](12);
        for (uint256 i = 0; i < bets[11].number.length; i++) {
            bets[11].number[i] = i;
        }

        // Evenmoney bets
        bets[12].bet = ROULETTE.BETS.EVENMONEY;
        bets[12].wager = 10 ether;
        bets[12].number = new uint256[](18);
        for (uint256 i = 0; i < bets[12].number.length; i++) {
            bets[12].number[i] = i;
        }

        bets[13].bet = ROULETTE.BETS.EVENMONEY;
        bets[13].wager = 5000 ether;
        bets[13].number = new uint256[](18);
        for (uint256 i = 0; i < bets[13].number.length; i++) {
            bets[13].number[i] = i;
        }

        ROULETTETEST.play(bets);


        ROULETTETEST.withdraw(amount);
        check_deposit(0, 0);
    }

    /*
     * Test play bad bets
     * - Zero bets
     * - Extra amount
     */
    function test_bug() public {
        uint256 amount = 10000 ether;
        ROULETTETEST.deposit(amount);
        ROULETTE.BET[] memory bets;

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
     * deposit  amount needed for bet
     * bet      type of bet
     * length   bet number length
     * word     random word
     * wager    winning bet amount
     * payout   winning amount
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
     * - Straight-Split bets
     * - Split-Street bets
     * - Street-Corner bets
     * - Corner-Sixline bets
     * - Sixline-Dozencolumn bets
     * - Dozencolumn-Evenmoney bets
     * - Evenmoney-Straight bets
    */
    function test_process_multiple() public {
        ROULETTE.BETS[2] memory bet;
        uint256[2] memory length;


        bet[0] = ROULETTE.BETS.STRAIGHT;
        bet[1] = ROULETTE.BETS.SPLIT;
        length[0] = 1;
        length[1] = 2;
        process_multiple(200 ether, bet, length, 0, 200 ether, 5200 ether);
        process_multiple(200 ether, bet, length, 1, 100 ether, 1700 ether);

        bet[0] = ROULETTE.BETS.SPLIT;
        bet[1] = ROULETTE.BETS.STREET;
        length[0] = 2;
        length[1] = 3;
        process_multiple(200 ether, bet, length, 0, 200 ether, 2800 ether);
        process_multiple(200 ether, bet, length, 2, 100 ether, 1100 ether);

        bet[0] = ROULETTE.BETS.STREET;
        bet[1] = ROULETTE.BETS.CORNER;
        length[0] = 3;
        length[1] = 4;
        process_multiple(200 ether, bet, length, 0, 200 ether, 1900 ether);
        process_multiple(200 ether, bet, length, 3, 100 ether, 800 ether);

        bet[0] = ROULETTE.BETS.CORNER;
        bet[1] = ROULETTE.BETS.SIXLINE;
        length[0] = 4;
        length[1] = 6;
        process_multiple(200 ether, bet, length, 0, 200 ether, 1300 ether);
        process_multiple(200 ether, bet, length, 4, 100 ether, 500 ether);

        bet[0] = ROULETTE.BETS.SIXLINE;
        bet[1] = ROULETTE.BETS.DOZENCOLUMN;
        length[0] = 6;
        length[1] = 12;
        process_multiple(200 ether, bet, length, 0, 200 ether, 700 ether);
        process_multiple(200 ether, bet, length, 6, 100 ether, 200 ether);

        bet[0] = ROULETTE.BETS.DOZENCOLUMN;
        bet[1] = ROULETTE.BETS.EVENMONEY;
        length[0] = 12;
        length[1] = 18;
        process_multiple(200 ether, bet, length,  0, 200 ether, 300 ether);
        process_multiple(200 ether, bet, length, 12, 100 ether, 100 ether);

        bet[0] = ROULETTE.BETS.EVENMONEY;
        bet[1] = ROULETTE.BETS.STRAIGHT;
        length[0] = 18;
        length[1] = 1;
        process_multiple(200 ether, bet, length,  0, 200 ether, 3600 ether);
    }

    /*
     * deposit      deposit amount for bets
     * bet          both bet
     * length       roulette number according bet
     * word         random word for winning number
     * wager        winning bet amount
     * payout       winning amount
     */
    function process_multiple(uint256 deposit, ROULETTE.BETS[2] memory bet, uint256[2] memory length, uint256 word, uint256 wager, uint256 payout) private {
        ROULETTETEST.deposit(deposit);
        ROULETTE.BET[] memory bets = new ROULETTE.BET[](2);

        bets[0].bet = bet[0];
        bets[0].wager = 100 ether;
        bets[0].number = new uint256[](length[0]);
        for (uint256 i = 0; i < length[0]; i++) {
            bets[0].number[i] = i;
        }

        bets[1].bet = bet[1];
        bets[1].number = new uint256[](length[1]);
        bets[1].wager = 100 ether;
        for (uint256 i = 0; i < length[1]; i++) {
            bets[1].number[i] = i;
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

    function check_deposit(uint256 total, uint256 user) private {
        (uint256 d_total, uint256 d_user) = ROULETTETEST.deposits();
        Assert.equal(d_total, total, "Total deposit;");
        Assert.equal(d_user, user, "User deposit;");
    }
}
