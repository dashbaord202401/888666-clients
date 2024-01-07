// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./testcore.sol";

contract testSuite is BLACKJACKTESTSUITE {

    function beforeAll() public{
        before_all();
    }

    // Test deposit minimum and maximum
    function test_minmax() public {
        BLACKJACKTEST.deposit(10000 ether);
        uint256[] memory bets = new uint256[](1);

        // set to minimum
        bets[0] = 25 ether;
        BLACKJACKTEST.play_initial(bets);

        // set to maximum
        bets[0] = 5000 ether;
        BLACKJACKTEST.play_initial(bets);

        // Set to below minimum
        bets[0] = 24 ether;
        test_play_initial(bets);

        // Set to above maximum
        bets[0] = 5001 ether;
        test_play_initial(bets);

        BLACKJACKTEST.withdraw(10000 ether);
        test_deposit(0, 0);
    }

    // Test total bet limit
    function test_bet_length() public {
        BLACKJACKTEST.deposit(10000 ether);
        uint256[] memory bets;

        // Set to min bet
        bets = new uint256[](1);
        bets[0] = 1000 ether;
        BLACKJACKTEST.play_initial(bets);

        // Set to max bet
        bets = new uint256[](8);
        for (uint256 i = 0; i < bets.length; i++) {
            bets[i] = 1000 ether;
        }
        BLACKJACKTEST.play_initial(bets);

        // Set to zero bets
        bets = new uint256[](0);
        test_play_initial(bets);

        // Set to above max bet
        bets = new uint256[](9);
        for (uint256 i = 0; i < bets.length; i++) {
            bets[i] = 1000 ether;
        }
        test_play_initial(bets);

        BLACKJACKTEST.withdraw(10000 ether);
        test_deposit(0, 0);
    }

    // Test more bets then deposit
    function test_more_bets() public {
        BLACKJACKTEST.deposit(1000 ether);
        uint256[] memory bets = new uint256[](2);

        bets[0] = 1000 ether;
        bets[1] = 1000 ether;

        test_play_initial(bets);

        BLACKJACKTEST.withdraw(1000 ether);
        test_deposit(0, 0);
    }

    function test_play_initial(uint256[] memory bets) private {
        try BLACKJACKTEST.play_initial(bets) {
            Assert.ok(false, "Fail play_initial;");
        } catch {
            Assert.ok(true, "Pass play_initial;");
        }
    }

    // Test initial bet fulfillRandomWords
    function test_process_initial() public {
        BLACKJACKTEST.deposit(1000 ether);

        uint256 betid;
        uint256 request;
        uint256[] memory bets = new uint256[](1);

        bets[0] = 1000 ether;
        (betid, request) = BLACKJACKTEST.play_initial(bets);

        // fulfill the random words
        uint256[3] memory word = [uint256(1), 2, 3];

        uint256[] memory rand_word = new uint256[](3);
        for (uint i = 0; i < rand_word.length; i++) {
            rand_word[i] = word[i];
        }

        COORDINATOR.fulfillRandomWordsWithOverride(request, address(BLACKJACKTEST), rand_word);
        test_deposit(0, 0);
    }
}
