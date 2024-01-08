// SPDX-License-Identifier: GPL-2.0
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import "https://github.com/smart-casino/smart-core/blob/main/token/house.sol";

import "../slot.sol";

contract SLOTTEST is SLOT {

    constructor(uint64 id, bytes32 keyhash, address coordinator, address house) SLOT(id, keyhash, coordinator, house) {
        // initialize table;
    }

    function get_slot_words(uint256 request) public view returns (uint256[] memory, bool) {
        return (REQUESTS[request].words, REQUESTS[request].fulfilled);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity >=0.4.22 <0.9.0;

import "./testcore.sol";

contract testSuite is SLOTTESTSUITE {

    function beforeAll() public{
        before_all();
    }

    function test_wheel_min() public {
        deposit_amount(9 ether);
        test_play(9 ether);
        SLOTTABLE.withdraw(9 ether);
    }

    function test_table_max() public {
        deposit_amount(251 ether);
        test_play(251 ether);
        SLOTTABLE.withdraw(251 ether);
    }

    function test_table_zero() public {
        deposit_amount(10 ether);
        test_play(0);
        SLOTTABLE.withdraw(10 ether);
    }

    function test_extra_amount() public {
        deposit_amount(10 ether);
        test_play(20 ether);
        SLOTTABLE.withdraw(10 ether);
    }

    function test_divisible() public {
        deposit_amount(50 ether);
        test_play(50 ether - 1 ether);
        SLOTTABLE.withdraw(50 ether);
    }

    function test_play(uint256 bets) private {
        try SLOTTABLE.play(bets) {
            Assert.ok(false, "Fail: Bet accepted extra amount");
        } catch {
            Assert.ok(true, "Pass: Bet is not accepted;");
        }
    }
}



contract SLOTTESTSUITE {

    HOUSETOKEN  HOUSE;
    SLOTTEST   SLOTTABLE;
    VRFCoordinatorV2Mock COORDINATOR;
    bytes32 KEYHASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    function before_all() internal {
        HOUSE = new HOUSETOKEN();
        COORDINATOR = new VRFCoordinatorV2Mock(1 ether, 1000000);

        COORDINATOR.createSubscription();
        COORDINATOR.fundSubscription(1, 1000000 ether);

        SLOTTABLE = new SLOTTEST(1, KEYHASH, address(COORDINATOR), address(HOUSE));

        COORDINATOR.addConsumer(1, address(SLOTTABLE));

        HOUSE.add_table(address(SLOTTABLE));
        HOUSE.approve(address(SLOTTABLE), 21000000 ether);
    }

    function after_win(uint256 wager, uint256 payout) internal {
        SLOTTABLE.withdraw(wager);
        SLOTTABLE.withdraw(payout);
    }

    function check_request(uint256 request) internal returns (uint256[] memory) {
        (uint256[] memory words, bool fulfilled) = SLOTTABLE.get_slot_words(request);
        Assert.equal(fulfilled, true, "Fail: request fulfilled;");

        uint256[] memory lucky = new uint256[](75);
        for (uint256 i = 0; i < words.length; i++) {
            lucky[i] = words[i] % 64;
        }
        return lucky;
    }

    function deposit_amount(uint256 amount) internal {
        SLOTTABLE.deposit(amount);
        test_deposit(amount, amount);
    }

    function test_deposit(uint256 user, uint256 total) internal {
        (uint256 d_total, uint256 d_user) = SLOTTABLE.view_deposits();
        Assert.equal(d_user, user, "Fail: user deposit;");
        Assert.equal(d_total, total, "Fail: total deposit;");
    }
}


// SPDX-License-Identifier: GPL-2.0
pragma solidity >=0.4.22 <0.9.0;

import "./testcore.sol";

contract testSuite is SLOTTESTSUITE {

    uint256[] words;

    function beforeAll() public{
        before_all();

        words = new uint256[](75);
        for (uint256 i = 0; i < 75; i++) {
            words[i] = 0;
        }
    }

    /*
     * Read [reel_1_map, reel_2_map, reel_3_map] from `slot.sol`
     */
    function test_singal_bet() public {

        words[0] = 13;
        words[1] = 1;
        words[2] = 30;
        test_bets(10 ether, 10 ether, words, 10 ether, 50000 ether);

        words[0] = 6;
        words[1] = 5;
        words[2] = 20;
        test_bets(10 ether, 10 ether, words, 10 ether, 10000 ether);

        words[0] = 2;
        words[1] = 18;
        words[2] = 4;
        test_bets(10 ether, 10 ether, words, 10 ether, 2000 ether);

        words[0] = 5;
        words[1] = 4;
        words[2] = 1;
        test_bets(10 ether, 10 ether, words, 10 ether, 1000 ether);

        words[0] = 0;
        words[1] = 2;
        words[2] = 6;
        test_bets(10 ether, 10 ether, words, 10 ether, 500 ether);
        
        words[0] = 14;
        words[1] = 0;
        words[2] = 14;
        test_bets(10 ether, 10 ether, words, 10 ether, 250 ether);


        words[0] = 6;
        words[1] = 5;
        words[2] = 0;
        test_bets(10 ether, 10 ether, words, 10 ether, 100 ether);

        words[0] = 6;
        words[1] = 0;
        words[2] = 20;
        test_bets(10 ether, 10 ether, words, 10 ether, 100 ether);

        words[0] = 0;
        words[1] = 5;
        words[2] = 20;
        test_bets(10 ether, 10 ether, words, 10 ether, 100 ether);

        words[0] = 6;
        words[1] = 0;
        words[2] = 0;
        test_bets(10 ether, 10 ether, words, 10 ether, 20 ether);

        words[0] = 0;
        words[1] = 5;
        words[2] = 0;
        test_bets(10 ether, 10 ether, words, 10 ether, 20 ether);

        words[0] = 0;
        words[1] = 0;
        words[2] = 20;
        test_bets(10 ether, 10 ether, words, 10 ether, 20 ether);
    }
    
    function test_multiple() public {

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
        test_bets(120 ether, 120 ether, words, 120 ether, 64110 ether);
    }

    function test_bets(uint256 deposit, uint256 bets, uint256[] memory rand_word, uint256 wager, uint256 payout) private {
        deposit_amount(deposit);

        uint256 request = SLOTTABLE.play(bets);

        uint256[] memory _rand_word = new uint256[](rand_word.length);
        for (uint256 i = 0; i < rand_word.length; i++) {
            _rand_word[i] = rand_word[i];
        }
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(SLOTTABLE), _rand_word);

        uint256[] memory lucky = check_request(request);
        for (uint256 i = 0; i < lucky.length; i++) {
            Assert.equal(lucky[i], rand_word[i], "Fail: winning number;");
        }

        if (payout != 0) {
            after_win(wager, payout);
        } 
        test_deposit(0, 0);
    }
}
