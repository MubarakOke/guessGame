// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './MyToken.sol';

contract Game is MyToken {
    address owner;
    uint256 currentRound;
    uint256 roundExpiry;
    uint256 guessWinningPoint;

    struct Player {
        address user;
        uint256 points;
    }

    struct GameRound {
        uint256 roundID;
        Player[] roundPlayers;
        uint256 guessNumber;
        address winner;
        bool completed;
        uint256 endPeriod;
    }

    mapping(address=>Player) players;
    Player[] playersArray;

    mapping(uint256=>GameRound) gameRounds;
    GameRound[] gameRoundsArray;

    event RegistrationSuccessful(address indexed);

    modifier onlyOwner {
        require(msg.sender==owner, "Only owner is allowed");
        _;
    }

    modifier onlyPlayer {
        require(players[msg.sender].user==address(0), "Only player is allowed");
        _;
    }

    constructor(uint256 _roundExpiry, uint256 _guessWinningPoint){
        roundExpiry= _roundExpiry;
        guessWinningPoint= _guessWinningPoint;
    }

    function register() external {
        Player memory newPlayer = Player(msg.sender, 0);
        players[msg.sender] = newPlayer;

        playersArray.push(newPlayer);
        emit RegistrationSuccessful(msg.sender);
    }

    function updateRoundExpiry(uint256 _roundExpiry) external onlyOwner {
        roundExpiry= _roundExpiry;
    }

    function joinRound() external onlyPlayer {
        if (gameRounds[currentRound].completed){ createNewRound(); }
        if (gameRounds[currentRound].endPeriod <= block.timestamp){ createNewRound(); }

        GameRound storage gameRound = gameRounds[currentRound];
        gameRound.roundPlayers.push(players[msg.sender]);
    }

    function guess(uint256 guessNumber) external onlyPlayer {
        require(guessNumber != 0, "0 can't be guessed");
        if (gameRounds[currentRound].guessNumber == guessNumber){ 
            players[msg.sender].points= players[msg.sender].points + guessWinningPoint;
        }
        
    }

    function createNewRound() private {
        currentRound= currentRound + 1;
        GameRound memory newGameRound;
        newGameRound.roundID= currentRound;
        newGameRound.endPeriod= block.timestamp + (roundExpiry * 1 days);
    }

    function endRound() external {}

    function calculateReward() external {}

    function distributePrice() external {}
}
