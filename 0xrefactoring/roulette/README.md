# Roulette

[Table limit](https://dicechip.com/roulette-min-max-bets/)

## Local setup

- Deploy [vrfcoordinatorv2mock](https://docs.chain.link/vrf/v2/subscription/examples/test-locally)
- Deploy [XZ](https://github.com/chain-xz/chain-xz/blob/main/token.sol)
- Deploy `Baccarat`

## Bets

```txt
STRAIGHT
SPLIT
STREET
CORNER
SIXLINE
DOZENCOLUMN
EVENMONEY
```

## Play

```txt
[0, [0], 10000000000000000000]
[1, [0, 1], 10000000000000000000]

[[0, [0], 10000000000000000000], [1, [6, 9], 10000000000000000000]]
```
