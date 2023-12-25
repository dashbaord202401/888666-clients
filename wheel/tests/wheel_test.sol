// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "remix_tests.sol"; 
import "https://github.com/chain-xz/chain-xz/blob/main/token.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import "../wheel.sol";

contract testSuite {

    XZTOKEN XZ;
    WHEEL WHEELTEST;
    VRFCoordinatorV2Mock COORDINATOR;

    function beforeAll() public {
        bytes32 KEYHASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

        COORDINATOR = new VRFCoordinatorV2Mock(1 ether, 1000000);
        uint64 SUBID = COORDINATOR.createSubscription();

        COORDINATOR.fundSubscription(SUBID, 1000000 ether);

        XZ = new XZTOKEN();

        WHEELTEST = new WHEEL(KEYHASH, SUBID, address(COORDINATOR), address(XZ));

        COORDINATOR.addConsumer(SUBID, address(WHEELTEST));

        XZ.client_add(address(WHEELTEST));
        XZ.approve(address(WHEELTEST), 21000000 ether);
    }

    /*
     * Test play bets
     * - One 
     * - Three
     * - Six
     * - Twelve
     * - Twentyfive
     * - Red
     * - Yellow
     */
    function test_play() public {
        uint256 amount = 5000 ether;
        WHEELTEST.deposit(amount);
        WHEEL.BET[] memory bets = new WHEEL.BET[](14);

        bets[0].bet  = WHEEL.BETS.ONE;
        bets[0].wager = 5 ether;

        bets[1].bet  = WHEEL.BETS.ONE;
        bets[1].wager = 500 ether;

        bets[2].bet  = WHEEL.BETS.THREE;
        bets[2].wager = 5 ether;

        bets[3].bet  = WHEEL.BETS.THREE;
        bets[3].wager = 500 ether;

        bets[4].bet  = WHEEL.BETS.SIX;
        bets[4].wager = 5 ether;

        bets[5].bet  = WHEEL.BETS.SIX;
        bets[5].wager = 500 ether;

        bets[6].bet  = WHEEL.BETS.TWELVE;
        bets[6].wager = 5 ether;

        bets[7].bet  = WHEEL.BETS.TWELVE;
        bets[7].wager = 500 ether;

        bets[8].bet  = WHEEL.BETS.TWENTYFIVE;
        bets[8].wager = 5 ether;

        bets[9].bet  = WHEEL.BETS.TWENTYFIVE;
        bets[9].wager = 500 ether;

        bets[10].bet  = WHEEL.BETS.RED;
        bets[10].wager = 5 ether;

        bets[11].bet  = WHEEL.BETS.RED;
        bets[11].wager = 500 ether;

        bets[12].bet  = WHEEL.BETS.YELLOW;
        bets[12].wager = 5 ether;

        bets[13].bet  = WHEEL.BETS.YELLOW;
        bets[13].wager = 500 ether;

        WHEELTEST.play(bets);

        WHEELTEST.withdraw(amount);
        check_deposit(0, 0);
    }

    /*
     * Test bug bet
     * - Zero bets
     * - Extra amount
     */
    function test_play_bug() public {
        uint256 amount = 1000 ether;
        WHEELTEST.deposit(amount);
        WHEEL.BET[] memory bets;


        bets = new WHEEL.BET[](0);

        try WHEELTEST.play(bets) {
            Assert.ok(false, "Zero bets accepted");
        } catch {
            Assert.ok(true, "Zero bets rejected;");
        }


        bets = new WHEEL.BET[](3);
        bets[0].bet  = WHEEL.BETS.ONE;
        bets[0].wager = 500 ether;
        bets[1].bet  = WHEEL.BETS.THREE;
        bets[1].wager = 500 ether;
        bets[2].bet  = WHEEL.BETS.SIX;
        bets[2].wager = 500 ether;

        try WHEELTEST.play(bets) {
            Assert.ok(false, "Extra amount accepted");
        } catch {
            Assert.ok(true, "Extra amount rejected;");
        }

        WHEELTEST.withdraw(amount);
        check_deposit(0, 0);
    }

    /*
     * Single bet processing
     * - One bet
     * - Three bet
     * - Six bet
     * - Twelve bet
     * - Twentyfive bet
     * - Red bet
     * - Yellow bet 
     */
    function test_process_single() public {

        process_single(100 ether, WHEEL.BETS.ONE, 0,  100 ether, 100 ether);
        process_single(100 ether, WHEEL.BETS.ONE, 25, 100 ether, 100 ether);
        process_single(100 ether, WHEEL.BETS.ONE, 53, 100 ether, 0 ether);
        process_single(100 ether, WHEEL.BETS.ONE, 26, 100 ether, 0 ether);

        process_single(100 ether, WHEEL.BETS.THREE, 26,  100 ether, 300 ether);
        process_single(100 ether, WHEEL.BETS.THREE, 38,  100 ether, 300 ether);
        process_single(100 ether, WHEEL.BETS.THREE, 25,  100 ether, 0 ether);
        process_single(100 ether, WHEEL.BETS.THREE, 39,  100 ether, 0 ether);

        process_single(100 ether, WHEEL.BETS.SIX, 39,  100 ether, 600 ether);
        process_single(100 ether, WHEEL.BETS.SIX, 45,  100 ether, 600 ether);
        process_single(100 ether, WHEEL.BETS.SIX, 38,  100 ether, 0 ether);
        process_single(100 ether, WHEEL.BETS.SIX, 46,  100 ether, 0 ether);

        process_single(100 ether, WHEEL.BETS.TWELVE, 46,  100 ether, 1200 ether);
        process_single(100 ether, WHEEL.BETS.TWELVE, 49,  100 ether, 1200 ether);
        process_single(100 ether, WHEEL.BETS.TWELVE, 45,  100 ether, 0 ether);
        process_single(100 ether, WHEEL.BETS.TWELVE, 50,  100 ether, 0 ether);

        process_single(100 ether, WHEEL.BETS.TWENTYFIVE, 50,  100 ether, 2500 ether);
        process_single(100 ether, WHEEL.BETS.TWENTYFIVE, 51,  100 ether, 2500 ether);
        process_single(100 ether, WHEEL.BETS.TWENTYFIVE, 49,  100 ether, 0 ether);
        process_single(100 ether, WHEEL.BETS.TWENTYFIVE, 52,  100 ether, 0 ether);

        process_single(100 ether, WHEEL.BETS.RED, 52,  100 ether, 5000 ether);
        process_single(100 ether, WHEEL.BETS.RED, 51,  100 ether, 0 ether);
        process_single(100 ether, WHEEL.BETS.RED, 53,  100 ether, 0 ether);

        process_single(100 ether, WHEEL.BETS.YELLOW, 53,  100 ether, 5000 ether);
        process_single(100 ether, WHEEL.BETS.YELLOW, 52,  100 ether, 0 ether);
        process_single(100 ether, WHEEL.BETS.YELLOW, 54,  100 ether, 0 ether);
    }

    /*
     * deposit  - Deposit amount
     * bet      - Bet type
     * word     - Random word
     * wager    - Wager amount
     * payout   - Payout amount
     */
    function process_single(uint256 deposit, WHEEL.BETS bet, uint256 word, uint256 wager, uint256 payout) private {
        WHEELTEST.deposit(deposit);
        WHEEL.BET[] memory bets = new WHEEL.BET[](1);

        bets[0].bet  = bet;
        bets[0].wager = wager;

        uint256 request = WHEELTEST.play(bets);

        uint256[] memory rand_word = new uint256[](1);
        rand_word[0] = word;
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(WHEELTEST), rand_word);

        if (payout != 0) {
            WHEELTEST.withdraw(wager);
            WHEELTEST.withdraw(payout);
        }
        check_deposit(0, 0);
    }

    /*
     * Test multiple bets
     * - One three bets
     * - Three six bets
     * - Six twelve bets
     * - Twelve twentyfive bets
     * - Twentyfive red bets
     * - Red tellow bets
     * - Yellow one bets
     */
    function test_process_multiple() public {
        WHEEL.BETS[2] memory bet;

        bet[0] = WHEEL.BETS.ONE;
        bet[1] = WHEEL.BETS.THREE;
        process_multiple(200 ether, bet,  0, 100 ether, 100 ether);
        process_multiple(200 ether, bet, 25, 100 ether, 100 ether);
        process_multiple(200 ether, bet, 26, 100 ether, 300 ether);

        bet[0] = WHEEL.BETS.THREE;
        bet[1] = WHEEL.BETS.SIX;
        process_multiple(200 ether, bet,  26, 100 ether, 300 ether);
        process_multiple(200 ether, bet,  38, 100 ether, 300 ether);
        process_multiple(200 ether, bet,  39, 100 ether, 600 ether);

        bet[0] = WHEEL.BETS.SIX;
        bet[1] = WHEEL.BETS.TWELVE;
        process_multiple(200 ether, bet,  39, 100 ether, 600 ether);
        process_multiple(200 ether, bet,  45, 100 ether, 600 ether);
        process_multiple(200 ether, bet,  46, 100 ether, 1200 ether);

        bet[0] = WHEEL.BETS.TWELVE;
        bet[1] = WHEEL.BETS.TWENTYFIVE;
        process_multiple(200 ether, bet,  46, 100 ether, 1200 ether);
        process_multiple(200 ether, bet,  49, 100 ether, 1200 ether);
        process_multiple(200 ether, bet,  50, 100 ether, 2500 ether);

        bet[0] = WHEEL.BETS.TWENTYFIVE;
        bet[1] = WHEEL.BETS.RED;
        process_multiple(200 ether, bet,  50, 100 ether, 2500 ether);
        process_multiple(200 ether, bet,  51, 100 ether, 2500 ether);
        process_multiple(200 ether, bet,  52, 100 ether, 5000 ether);

        bet[0] = WHEEL.BETS.RED;
        bet[1] = WHEEL.BETS.YELLOW;
        process_multiple(200 ether, bet,  52, 100 ether, 5000 ether);
        process_multiple(200 ether, bet,  53, 100 ether, 5000 ether);

        bet[0] = WHEEL.BETS.YELLOW;
        bet[1] = WHEEL.BETS.ONE;
        process_multiple(200 ether, bet,  53, 100 ether, 5000 ether);
        process_multiple(200 ether, bet,  54, 100 ether, 100 ether);
    }

    /*
     * deposit  - Deposit amount
     * bet      - Bets type
     * word     - Random word
     * wager    - Wager amount
     * payout   - Payout amount
     */
    function process_multiple(uint256 deposit, WHEEL.BETS[2] memory bet, uint256 word, uint256 wager, uint256 payout) private {
        WHEELTEST.deposit(deposit);

        WHEEL.BET[] memory bets = new WHEEL.BET[](2);

        bets[0].bet  = bet[0];
        bets[1].bet  = bet[1];

        bets[0].wager = 100 ether;
        bets[1].wager = 100 ether;

        uint256 request = WHEELTEST.play(bets);

        uint256[] memory rand_word = new uint256[](1);
        rand_word[0] = word;
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(WHEELTEST), rand_word);

        if (payout != 0) {
            WHEELTEST.withdraw(wager);
            WHEELTEST.withdraw(payout);
        }
        check_deposit(0, 0);
    }

    /*
     * Test all bets
     */
    function test_process_multix() public {

        // One
        process_multix(0,  100 ether);
        process_multix(16, 100 ether);
        process_multix(25, 100 ether);

        // Three
        process_multix(26, 300 ether);
        process_multix(30, 300 ether);
        process_multix(38, 300 ether);

        // Six
        process_multix(39, 600 ether);
        process_multix(42, 600 ether);
        process_multix(45, 600 ether);

        // Twelve
        process_multix(46, 1200 ether);
        process_multix(48, 1200 ether);
        process_multix(49, 1200 ether);

        // Twentyfive
        process_multix(50, 2500 ether);
        process_multix(51, 2500 ether);

        // Red
        process_multix(52, 5000 ether);

        // Yellow
        process_multix(53, 5000 ether);

        // One
        process_multix(54, 100 ether);
    }

    /*
     * word     - Random word
     * payout   - Payout amount
     */
    function process_multix(uint256 word, uint256 payout) private {
        WHEELTEST.deposit(700 ether);

        WHEEL.BET[] memory bets = new WHEEL.BET[](7);

        bets[0].bet  = WHEEL.BETS.ONE;
        bets[1].bet  = WHEEL.BETS.THREE;
        bets[2].bet  = WHEEL.BETS.SIX;
        bets[3].bet  = WHEEL.BETS.TWELVE;
        bets[4].bet  = WHEEL.BETS.TWENTYFIVE;
        bets[5].bet  = WHEEL.BETS.RED;
        bets[6].bet  = WHEEL.BETS.YELLOW;

        bets[0].wager = 100 ether;
        bets[1].wager = 100 ether;
        bets[2].wager = 100 ether;
        bets[3].wager = 100 ether;
        bets[4].wager = 100 ether;
        bets[5].wager = 100 ether;
        bets[6].wager = 100 ether;

        uint256 request = WHEELTEST.play(bets);

        uint256[] memory rand_word = new uint256[](1);
        rand_word[0] = word;
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(WHEELTEST), rand_word); 

        WHEELTEST.withdraw(100 ether);
        WHEELTEST.withdraw(payout);
        check_deposit(0, 0);
    }

    function check_deposit(uint256 total, uint256 user) private {
        (uint256 d_total, uint256 d_user) = WHEELTEST.deposits();
        Assert.equal(d_total, total, "Total deposit;");
        Assert.equal(d_user, user, "User deposit;");
    }
}
