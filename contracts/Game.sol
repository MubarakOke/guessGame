// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Game is VRFConsumerBaseV2 {
    // Game states
    bool gameLaunched;
    address owner;
    uint256 public currentRound;
    uint256 public curentGuessNumber;
    uint256 roundExpiry;
    uint256 guessWinningPoint;

    mapping(address=>Player) public players;
    Player[] playersArray;

    mapping(uint256=>GameRound) public gameRounds;
    GameRound[] gameRoundsArray;

    mapping(uint256=>mapping(address=>bool)) playedInRound;
    mapping(uint256=>mapping(address=>bool)) joinedRound;

    uint256[] guessableNumbers= [1,2,3,4,5,6,7,8,9];

    struct Player {
        address user;
        uint256 points;
    }

    struct GameRound {
        uint256 roundID;
        Player[] roundPlayers;
        uint256 guessNumber;
        address[] winners;
        uint256 endPeriod;
    }

    // Token states
    IERC20 token;

    // VRF states
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 keyHash =0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint64 s_subscriptionId;
    mapping(uint256 => RequestStatus) public s_requests;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint16 requestConfirmations = 1;
    uint32 numWords = 1;
    uint32 callbackGasLimit = 100000;
    bool guessNumObtained;

    struct RequestStatus {
        bool fulfilled; 
        bool exists; 
        uint256[] randomWords;
    }


    event RegistrationSuccessful(address indexed);
    event JoinedRoundSuccessful(address indexed, uint256 round);
    event GuessSuccessful(address, uint256 guessNumber);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    modifier onlyOwner {
        require(msg.sender==owner, "Only owner is allowed");
        _;
    }

    modifier onlyPlayer {
        require(players[msg.sender].user!=address(0), "Only player is allowed");
        _;
    }

    modifier GameLaunched {
        require(gameLaunched, "Game not yet launched");
        _;
    }

    constructor(uint256 _roundExpiryInMinute, uint256 _guessWinningPoint, address _tokenAddress, uint64 subscriptionId) VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        roundExpiry= _roundExpiryInMinute;
        guessWinningPoint= _guessWinningPoint;
        token= IERC20(_tokenAddress);
        s_subscriptionId= subscriptionId;
    }

    function launchGame() external onlyOwner{
        createNewRound();
    }

    function register() external GameLaunched {
        Player memory newPlayer = Player(msg.sender, 0);
        players[msg.sender] = newPlayer;

        playersArray.push(newPlayer);
        emit RegistrationSuccessful(msg.sender);
    }

    function updateRoundExpiry(uint256 _roundExpiry) external onlyOwner GameLaunched {
        roundExpiry= _roundExpiry;
    }

    function joinGame() external onlyPlayer GameLaunched {
        if (block.timestamp >= gameRounds[currentRound].endPeriod){
            currentRound = currentRound + 1; 
            createNewRound(); 
            }
        require(!joinedRound[currentRound][msg.sender], "You already joind this round");

        gameRounds[currentRound].roundPlayers.push(players[msg.sender]);

        joinedRound[currentRound][msg.sender]= true;

        emit JoinedRoundSuccessful(msg.sender, currentRound);
    }

    function guess(uint256 guessNumber) external onlyPlayer GameLaunched{
        require(guessNumber != 0, "0 can't be guessed");
        require(checkGuessNumFulfilled(), "Computing Guessing Number");

        if (block.timestamp <= gameRounds[currentRound].endPeriod){
            currentRound = currentRound + 1;
            createNewRound();
        }
        else {
            require(!playedInRound[currentRound][msg.sender], "You've already played in round");
        }

        require(joinedRound[currentRound][msg.sender], "You've not joined this round, join game first");

        if (guessNumber == curentGuessNumber){ 
            gameRounds[currentRound].winners.push(msg.sender);
            players[msg.sender].points= players[msg.sender].points + guessWinningPoint;
        }

        playedInRound[currentRound][msg.sender] = true;

        emit GuessSuccessful(msg.sender, guessNumber);
    }

    function createNewRound() private {
        guessNumObtained= false;
        uint256 newCurrentRound= currentRound;
        requestGuessNum();
        GameRound storage newGameRound= gameRounds[newCurrentRound];
        newGameRound.roundID= newCurrentRound;
        newGameRound.endPeriod= block.timestamp + (roundExpiry * 60);
        
        if (currentRound != 0){
            gameRounds[currentRound-1].guessNumber = curentGuessNumber;
        }   
    }

    function getRoundPlayers(uint256 roundID) external view GameLaunched returns (Player[] memory) {
        return gameRounds[roundID].roundPlayers;
    }

    function getRoundWinner(uint256 roundID) external view GameLaunched returns (address[] memory) {
        return gameRounds[roundID].winners;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) internal view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function requestGuessNum() private {   
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        requestIds.push(requestId);
        lastRequestId = requestId;

        fulfillRandomWords(lastRequestId, guessableNumbers);
    }

    function checkGuessNumFulfilled() private returns (bool) {
       (bool fulfilled , uint256[] memory randomWords) = getRequestStatus(lastRequestId);
       if (fulfilled){
            guessNumObtained= fulfilled;
            curentGuessNumber= (randomWords[0] % 9) + 1;
       }
       else{
            guessNumObtained= false;
       }
       
       return guessNumObtained; 
    }

    function calculateReward() external {}

    function distributePrice() external {}
}
