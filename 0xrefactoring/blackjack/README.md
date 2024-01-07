# blackjack

## Rules source

[wikipedia](https://en.wikipedia.org/wiki/Blackjack)

- Initial deal
- Player action
- Dealer's hand revealed
- Bets settled

## Local play

- [vrfcoordinatorv2mock](https://docs.chain.link/vrf/v2/subscription/examples/test-locally#deploy-vrfcoordinatorv2mock)
- vrfcoordinatorv2mock `createSubscription`
- vrfcoordinatorv2mock `fundSubscription`
- Deploy [XTOKEN](https://github.com/chainplay-x/chainplay-x/blob/main/x-token/x-token.sol)
- Deploy `Blackjack`
- vrfcoordinatorv2mock `addConsumer` Blackjack

### Play

```txt
[1000000000000000000000]
1 [2]
```
