// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import "https://github.com/chainplay-x/chainplay-x/blob/main/x-token/x-token.sol";

import "../blackjack.sol";

contract BLACKJACKTESTSUITE {

    XTOKEN XTOKENTEST;
    BLACKJACK BLACKJACKTEST;
    VRFCoordinatorV2Mock COORDINATOR;

    function before_all() internal {
        uint64 SUBID;

        bytes32 KEYHASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

        XTOKENTEST = new XTOKEN();
        COORDINATOR = new VRFCoordinatorV2Mock(1 ether, 1000000);

        SUBID = COORDINATOR.createSubscription();
        COORDINATOR.fundSubscription(SUBID, 1000000 ether);

        BLACKJACKTEST = new BLACKJACK(KEYHASH, SUBID, address(COORDINATOR), address(XTOKENTEST));

        COORDINATOR.addConsumer(SUBID, address(BLACKJACKTEST));

        XTOKENTEST.add_x(address(BLACKJACKTEST));
        XTOKENTEST.approve(address(BLACKJACKTEST), 21000000 ether);
    }

    function test_deposit(uint256 user, uint256 total) internal {
        (uint256 d_user, uint256 d_total) = BLACKJACKTEST.deposits();
        Assert.equal(d_user, user, "Fail: user deposit;");
        Assert.equal(d_total, total, "Fail: total deposit;");
    }
}
