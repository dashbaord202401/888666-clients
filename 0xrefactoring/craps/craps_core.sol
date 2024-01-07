// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CRAPSCORE {

    enum PUCK {
        OFF,
        NUMBER,
        OVER
    }


/*
    enum LINE {
        PASSLINE,
        PASSLINEODDS,
        DONTPASS,
        DONTPASSODDS,
        COME,
        COMEODDS,
        DONTCOME,
        DONTCOMEODDS
    }

    enum MULTIROLL {
        PLACE,
        BUY,
        LAY,
        PUT,
        HARDWAY,
        BIG6,
        BIG8
    }

    enum SINGLEROLL {
        SNAKEEYES,
        ACEDEUCE,
        YO,
        BOXCARS,
        ANYCRAPS,
        ANYSEVEN,
        FIELD
    }

    struct LINEBETS {
        LINE        line;
        uint256     wager;
        uint256     point;
    }

    struct MULTIROLLBETS {
        MULTIROLL   multiroll;
        uint256     wager;
        uint256     point;
    }

    struct SINGLEROLLBETS {
        SINGLEROLL  singleroll;
        uint256     wager;
    }

    struct BET {
        PUCK        puck;

    }


WAGERS      wager;
ACTION      action;
uint256     amount; 
uint256     number; 

    struct PUCK_STR {
        PUCK        puck;
        uint256     number; 
    }

    struct REQUEST {
        PUCK_STR    puck;     // Puck status
        BET[64]     bets;     // Craps bets

    struct BET {
        ROUND           round;
        HANDS[]         hands;
        bool            holecard;
        uint256[]       cards;
        address         player;
        bool            fulfilled;
    }
    mapping(uint256 => BET) public BETS;
*/

    uint256 BETSID;

    function get_betid() internal returns (uint256) {
        return BETSID++;
    }
}
