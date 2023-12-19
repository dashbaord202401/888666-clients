// SPDX-License-Identifier: GPL-2.0
pragma solidity >=0.4.22 <0.9.0;

import "https://github.com/chain-xz/chain-xz/blob/main/token.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import "./test-core.sol";
import "remix_tests.sol"; 

contract testSuite {

    XZTOKEN XZ;
    TESTCORE CORETEST;
    VRFCoordinatorV2Mock COORDINATOR;

    bytes32 KEYHASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    function beforeAll() public {
        XZ = new XZTOKEN();
        COORDINATOR = new VRFCoordinatorV2Mock(1 ether, 1000000000);

        COORDINATOR.createSubscription();
        COORDINATOR.fundSubscription(1, 100 ether);

        CORETEST = new TESTCORE(KEYHASH, 1, address(COORDINATOR), address(XZ));

        COORDINATOR.addConsumer(1, address(CORETEST));

        XZ.client_add(address(CORETEST));

        XZ.approve(address(CORETEST), 21000000 ether);
    }

    function test_fund() public {
        CORETEST.deposit(1000 ether);
        check_deposit(1000 ether, 1000 ether);

        CORETEST.withdraw(500 ether);
        check_deposit(500 ether, 500 ether);

        CORETEST.deposit(1000 ether);
        check_deposit(1500 ether, 1500 ether);

        CORETEST.withdraw(1500 ether);
        check_deposit(0, 0);
    }

    function test_overwithdraw() public {
        CORETEST.deposit(1000 ether);

        try CORETEST.withdraw(1001 ether) {
            Assert.ok(false, "Withdraw successful;");
        } catch {
            Assert.ok(true, "Withdraw fail;");
        }
        CORETEST.withdraw(1000 ether);
        check_deposit(0, 0);
    }

    function test_vrf_random() public {
        uint256 request = CORETEST.request_words_public(1);

        COORDINATOR.fulfillRandomWords(request, address(CORETEST));

        (uint256 REQUEST, uint256[] memory WORDS) = CORETEST.request_processed();

        Assert.equal(REQUEST, request, "Request is different;");
        Assert.notEqual(WORDS[0], 0, "Random word is zero");
    }

    function test_vrf_nonrandom() public {
        uint256[] memory words = new uint256[](1);
        words[0] = 69;

        uint256 request = CORETEST.request_words_public(1);
        COORDINATOR.fulfillRandomWordsWithOverride(request, address(CORETEST), words);

        (uint256 REQUEST, uint256[] memory WORDS) = CORETEST.request_processed();

        Assert.equal(REQUEST, request, "Request is different;");
        Assert.equal(WORDS[0], words[0], "Random word is not 69;");
    }

    function test_validate() public {
        uint256 MIN = 10 ether;
        uint256 MAX = 100 ether;

        CORETEST.public_validate(10 ether, MIN, MAX);
        CORETEST.public_validate(69 ether, MIN, MAX);
        CORETEST.public_validate(100 ether, MIN, MAX);

        try CORETEST.public_validate(9 ether, MIN, MAX) {
            Assert.ok(false, "Validate pass;");
        } catch {
            Assert.ok(true, "Validate fail;");
        }

        try CORETEST.public_validate(101 ether, MIN, MAX) {
            Assert.ok(false, "Validate pass;");
        } catch {
            Assert.ok(true, "Validate fail;");
        }
    }

    function test_payout() public {
        CORETEST.public_payout(100 ether, address(this), 1, 1);
        check_deposit(200 ether, 200 ether);

        // test maintain_fund
        CORETEST.public_maintain_fund();
        CORETEST.withdraw(200 ether);

        CORETEST.public_payout(100 ether, address(this), 2, 1);
        check_deposit(300 ether, 300 ether);

        // test maintain_fund
        CORETEST.public_maintain_fund();
        CORETEST.withdraw(300 ether);

        CORETEST.public_payout(100 ether, address(this), 0, 1);
        check_deposit(100 ether, 100 ether);

        // test maintain_fund
        CORETEST.public_maintain_fund();
        CORETEST.withdraw(100 ether);

        Assert.equal(XZ.totalSupply(), 21000600 ether, "Supply is not +600;");
    }

    function test_no_more_bets() public {
        CORETEST.deposit(600 ether);

        CORETEST.public_no_more_bets(600 ether, address(this));
        check_deposit(0, 0);

        try CORETEST.public_no_more_bets(1 ether, address(this)) {
            Assert.ok(false, "Bets are accepted;");
        } catch {
            Assert.ok(true, "Bets are not accepted;");
        }

        CORETEST.public_maintain_fund();
        Assert.equal(XZ.totalSupply(), 21000000 ether, "Supply is not -600;");
    }

    function test_liquidate() public {
        CORETEST.deposit(1000 ether);
        check_deposit(1000 ether, 1000 ether);

        CORETEST.liquidate_contract();
        check_deposit(0, 0);

        try CORETEST.deposit(100 ether) {
            Assert.ok(false, "Deposit successful;");
        } catch {
            Assert.ok(true, "Deposit fail;");
        }
    }

    function check_deposit(uint256 total, uint256 user) private {
        (uint256 d_total, uint256 d_user) = CORETEST.deposits();
        Assert.equal(d_total, total, "Total deposit;");
        Assert.equal(d_user, user, "User deposit;");
    }
}
