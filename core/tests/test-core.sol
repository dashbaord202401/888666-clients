// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "../core.sol";

contract TESTCORE is CORE {

    uint256 REQUEST;
    uint256[] WORDS;

    constructor(bytes32 keyhash, uint64 subscription, address coordinator, address xz) CORE(keyhash, subscription, coordinator, xz) {
        // init
    }

    // Request words from Chainlink VRF
    function request_words_public(uint32 words) public returns (uint256 request) {
        request = request_words(words);
    }

    function request_process(uint256 request, uint256[] memory words) internal virtual override {
        REQUEST = request;
        WORDS = words;
    }

    function request_processed() public view returns (uint256, uint256[] memory) {
        return (REQUEST, WORDS);
    }

    // Make internal functions public for testing
    function public_maintain_fund() public {
        maintain_fund();
    }

    function public_validate(uint256 amount, uint256 minimum, uint256 maximum) public pure {
        validate(amount, minimum, maximum);
    }

    function public_payout(uint256 amount, address user, uint256 numerator, uint denominator) public {
        payout(amount, user, numerator, denominator);
    }

    function public_no_more_bets(uint256 amount, address user) public {
        no_more_bets(amount, user);
    }
}
