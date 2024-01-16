# slot

[Source](<https://www.greo.ca/Modules/EvidenceCentre/files/Christensen%20et%20al(2005)Informing%20clients%20how%20slot.pdf>)

## Local setup

- Deploy [vrfcoordinatorv2mock](https://docs.chain.link/vrf/v2/subscription/examples/test-locally)
- Deploy [XZ](https://github.com/chain-xz/chain-xz/blob/main/token.sol)
- Deploy `Baccarat`

## Payout

```txt
3 [1-Bar]           5000:1
3 [2-Cherry]        1000:1
3 [3-Plum]          200:1
3 [4-Watermelon]    100:1
3 [5-Orange]        50:1
3 [6-Lemon]         25:1
2 [2-Cherry]        10:1
1 [2-Cherry]        2:1
```

## Virtual

```txt
Symbol      Reel_1  Reel_2  Reel_3
1-Bar           4       3       1
2-Cherry        5       4       2
3-Plum          6       4       3
4-Watermelon    6       5       4
5-Orange        7       5       6
6-Lemon         8       6       6
0-Blank         28      37      42
------------------------------------
Total           64      64      64
```

## Play

```txt
[10000000000000000000]
```
