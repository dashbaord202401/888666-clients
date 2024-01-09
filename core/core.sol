// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

interface IERC20XZ is IERC20 {
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
}

contract CORE is VRFConsumerBaseV2, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event request_sent(uint256 request, uint32 words);
    event request_fulfilled(uint256 request, uint256[] words);

    bytes32 KEYHASH;
    uint64 SUBSCRIPTION;
    VRFCoordinatorV2Interface COORDINATOR;

    IERC20XZ private XZ;
    uint256 private TOTAL;
    EnumerableSet.AddressSet private USERS;
    mapping(address => uint256) internal DEPOSITS;

    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant CALLBACK_GAS_LIMIT = 2500000;

    constructor(bytes32 keyhash, uint64 subscription, address coordinator, address xz) VRFConsumerBaseV2(coordinator) Ownable(msg.sender) {
        KEYHASH = keyhash;
        SUBSCRIPTION = subscription;
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        XZ = IERC20XZ(xz);
    }

    // Call `approve` before calling `deposit` 
    function deposit(uint256 amount) public {
        require(amount > 0, "Deposit amount is zero;");
        USERS.add(msg.sender);
        TOTAL += amount;
        DEPOSITS[msg.sender] += amount;
        XZ.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdraw amount is zero;");
        require(DEPOSITS[msg.sender] >= amount, "Insufficient user balance;");
        TOTAL -= amount;
        DEPOSITS[msg.sender] -= amount;
        XZ.transfer(msg.sender, amount);
    }

    function deposits() public view returns (uint256, uint256) {
        return (TOTAL, DEPOSITS[msg.sender]);
    }

    function maintain_fund() internal {
        uint256 balance = XZ.balanceOf(address(this));
        if (balance > TOTAL) {
            uint256 amount = balance - TOTAL;
            XZ.burn(amount);
        } else if (balance < TOTAL) {
            uint256 amount = TOTAL - balance;
            XZ.mint(amount);
        }
    }

    function liquidate_contract() public onlyOwner {
        maintain_fund();
        uint256 users = USERS.length();
        uint256 iterations = users > 128 ? 128 : users;

        for (uint256 i = 0; i < iterations; i++) {
            address user = USERS.at(i);
            uint256 amount = DEPOSITS[user];

            if(amount > 0) {
                DEPOSITS[user] = 0;
                XZ.transfer(user, amount);
            }

            USERS.remove(user);
        }

        if(USERS.length() == 0) {
            TOTAL = 0;
            XZ = IERC20XZ(address(0));
        }
    }

    // Inherited contracts functions
    function request_words(uint32 words) internal returns (uint256 request) {
        request = COORDINATOR.requestRandomWords(
            KEYHASH,
            SUBSCRIPTION,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            words
        );
        emit request_sent(request, words);
        return request;
    }

    // Chainlink VRF
    function fulfillRandomWords(uint256 request, uint256[] memory words) internal override {
        request_process(request, words);
        maintain_fund();
        emit request_fulfilled(request, words);
    }

    // Override by inherited contracts
    function request_process(uint256, uint256[] memory) internal virtual {
        return;
    }

    function validate(uint256 amount, uint256 minimum, uint256 maximum) internal pure {
        require(amount % 1 ether == 0, "Amount is not full token;");
        require(amount >= minimum && amount <= maximum, "Amount failed validate limits;");
    }

    /*
     * Return the wager
     * Pay Winnings
     */
    function payout(uint256 amount, address user, uint256 numerator, uint256 denominator) internal {
        amount += (amount * numerator) / denominator;

        TOTAL += amount;
        DEPOSITS[user] += amount;
    }

    function no_more_bets(uint256 amount, address user) internal {
        require(amount <= DEPOSITS[user], "Insufficient user funds;");
        TOTAL -= amount;
        DEPOSITS[user] -= amount;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("renounceOwnership is disabled;");
    }

    function transferOwnership(address) public view override onlyOwner {
        revert("transferOwnership is disabled;");
    }
}
