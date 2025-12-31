// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SpinDBoard
 * @dev A spinning board game where players spin to get a number (1-10).
 * The player with the highest number wins 50% of the pool.
 * The game creator receives the other 50%.
 */
contract SpinDBoard is Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant ENTRY_FEE = 0.00002 ether;
    uint256 public constant MIN_PLAYERS = 2;
    uint256 public constant MAX_PLAYERS = 10;
    uint256 public constant BOARD_RANGE = 10;
    uint256 public constant WINNER_PERCENTAGE = 50;
    uint256 public constant CREATOR_PERCENTAGE = 50;

    // Game status enum
    enum GameStatus {
        Waiting,    // Waiting for players to join
        Spinning,   // Game is spinning (all players joined and spun)
        Completed   // Game completed, winner declared
    }

    // Player struct
    struct Player {
        address playerAddress;
        uint256 spinResult;
        bool hasSpun;
    }

    // Game struct
    struct Game {
        uint256 gameId;
        GameStatus status;
        uint256 totalPool;
        uint256 playerCount;
        address winner;
        uint256 winningNumber;
        uint256 createdAt;
        uint256 completedAt;
    }

    // State variables
    uint256 public currentGameId;
    uint256 public totalGamesPlayed;
    uint256 public totalFeesCollected;

    // Mappings
    mapping(uint256 => Game) public games;
    mapping(uint256 => Player[]) public gamePlayers;
    mapping(uint256 => mapping(address => bool)) public hasJoinedGame;
    mapping(uint256 => mapping(address => uint256)) public playerIndex;

    // Events
    event GameCreated(uint256 indexed gameId, uint256 timestamp);
    event PlayerJoined(uint256 indexed gameId, address indexed player, uint256 playerCount);
    event PlayerSpun(uint256 indexed gameId, address indexed player, uint256 spinResult);
    event GameCompleted(uint256 indexed gameId, address indexed winner, uint256 winningNumber, uint256 prize);
    event CreatorFeePaid(uint256 indexed gameId, address indexed creator, uint256 amount);
    event WinnerPaid(uint256 indexed gameId, address indexed winner, uint256 amount);

    constructor() Ownable(msg.sender) {
        _createNewGame();
    }

    /**
     * @dev Creates a new game internally
     */
    function _createNewGame() internal {
        currentGameId++;
        games[currentGameId] = Game({
            gameId: currentGameId,
            status: GameStatus.Waiting,
            totalPool: 0,
            playerCount: 0,
            winner: address(0),
            winningNumber: 0,
            createdAt: block.timestamp,
            completedAt: 0
        });

        emit GameCreated(currentGameId, block.timestamp);
    }

    /**
     * @dev Join the current game by paying the entry fee
     */
    function joinGame() external payable nonReentrant {
        require(msg.value == ENTRY_FEE, "Incorrect entry fee");
        
        Game storage game = games[currentGameId];
        require(game.status == GameStatus.Waiting, "Game not accepting players");
        require(game.playerCount < MAX_PLAYERS, "Game is full");
        require(!hasJoinedGame[currentGameId][msg.sender], "Already joined this game");

        // Add player
        hasJoinedGame[currentGameId][msg.sender] = true;
        playerIndex[currentGameId][msg.sender] = game.playerCount;
        
        gamePlayers[currentGameId].push(Player({
            playerAddress: msg.sender,
            spinResult: 0,
            hasSpun: false
        }));

        game.playerCount++;
        game.totalPool += msg.value;

        emit PlayerJoined(currentGameId, msg.sender, game.playerCount);
    }

    /**
     * @dev Spin the board to get a random number (1-10)
     */
    function spin() external nonReentrant {
        Game storage game = games[currentGameId];
        require(game.status == GameStatus.Waiting, "Game not in spinning phase");
        require(hasJoinedGame[currentGameId][msg.sender], "Not a player in this game");
        require(game.playerCount >= MIN_PLAYERS, "Not enough players");
        
        uint256 idx = playerIndex[currentGameId][msg.sender];
        Player storage player = gamePlayers[currentGameId][idx];
        require(!player.hasSpun, "Already spun");

        // Generate pseudo-random number 1-10
        uint256 spinResult = _generateRandomNumber(msg.sender, idx);
        player.spinResult = spinResult;
        player.hasSpun = true;

        emit PlayerSpun(currentGameId, msg.sender, spinResult);

        // Check if all players have spun
        if (_allPlayersSpun(currentGameId)) {
            game.status = GameStatus.Spinning;
            _completeGame(currentGameId);
        }
    }

    /**
     * @dev Generate a pseudo-random number between 1 and 10
     * @notice This uses block data for randomness. For production,
     * consider using Chainlink VRF or similar oracle service.
     */
    function _generateRandomNumber(address player, uint256 index) internal view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    player,
                    index,
                    currentGameId,
                    gamePlayers[currentGameId].length
                )
            )
        );
        return (random % BOARD_RANGE) + 1;
    }

    /**
     * @dev Check if all players have spun
     */
    function _allPlayersSpun(uint256 gameId) internal view returns (bool) {
        Player[] storage players = gamePlayers[gameId];
        for (uint256 i = 0; i < players.length; i++) {
            if (!players[i].hasSpun) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Complete the game and distribute prizes
     */
    function _completeGame(uint256 gameId) internal {
        Game storage game = games[gameId];
        Player[] storage players = gamePlayers[gameId];

        // Find winner (highest spin result)
        uint256 highestSpin = 0;
        address winnerAddress = address(0);

        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].spinResult > highestSpin) {
                highestSpin = players[i].spinResult;
                winnerAddress = players[i].playerAddress;
            }
        }

        game.winner = winnerAddress;
        game.winningNumber = highestSpin;
        game.status = GameStatus.Completed;
        game.completedAt = block.timestamp;
        totalGamesPlayed++;
        totalFeesCollected += game.totalPool;

        // Calculate prizes
        uint256 winnerPrize = (game.totalPool * WINNER_PERCENTAGE) / 100;
        uint256 creatorFee = game.totalPool - winnerPrize;

        // Pay winner
        (bool winnerSuccess, ) = payable(winnerAddress).call{value: winnerPrize}("");
        require(winnerSuccess, "Winner payment failed");
        emit WinnerPaid(gameId, winnerAddress, winnerPrize);

        // Pay creator
        (bool creatorSuccess, ) = payable(owner()).call{value: creatorFee}("");
        require(creatorSuccess, "Creator payment failed");
        emit CreatorFeePaid(gameId, owner(), creatorFee);

        emit GameCompleted(gameId, winnerAddress, highestSpin, winnerPrize);

        // Create new game
        _createNewGame();
    }

    // ============ View Functions ============

    /**
     * @dev Get current game info
     */
    function getCurrentGame() external view returns (
        uint256 gameId,
        GameStatus status,
        uint256 totalPool,
        uint256 playerCount,
        address winner,
        uint256 winningNumber
    ) {
        Game storage game = games[currentGameId];
        return (
            game.gameId,
            game.status,
            game.totalPool,
            game.playerCount,
            game.winner,
            game.winningNumber
        );
    }

    /**
     * @dev Get game details by ID
     */
    function getGame(uint256 gameId) external view returns (Game memory) {
        return games[gameId];
    }

    /**
     * @dev Get all players in a game
     */
    function getGamePlayers(uint256 gameId) external view returns (Player[] memory) {
        return gamePlayers[gameId];
    }

    /**
     * @dev Get player info in current game
     */
    function getPlayerInfo(address playerAddress) external view returns (
        bool hasJoined,
        uint256 spinResult,
        bool hasSpun
    ) {
        hasJoined = hasJoinedGame[currentGameId][playerAddress];
        if (hasJoined) {
            uint256 idx = playerIndex[currentGameId][playerAddress];
            Player storage player = gamePlayers[currentGameId][idx];
            spinResult = player.spinResult;
            hasSpun = player.hasSpun;
        }
        return (hasJoined, spinResult, hasSpun);
    }

    /**
     * @dev Check if current game can start spinning
     */
    function canStartSpinning() external view returns (bool) {
        Game storage game = games[currentGameId];
        return game.status == GameStatus.Waiting && game.playerCount >= MIN_PLAYERS;
    }

    /**
     * @dev Get number of players needed to start
     */
    function playersNeededToStart() external view returns (uint256) {
        Game storage game = games[currentGameId];
        if (game.playerCount >= MIN_PLAYERS) {
            return 0;
        }
        return MIN_PLAYERS - game.playerCount;
    }

    /**
     * @dev Get available slots in current game
     */
    function availableSlots() external view returns (uint256) {
        Game storage game = games[currentGameId];
        return MAX_PLAYERS - game.playerCount;
    }

    /**
     * @dev Get contract stats
     */
    function getStats() external view returns (
        uint256 _totalGamesPlayed,
        uint256 _totalFeesCollected,
        uint256 _currentGameId,
        uint256 _currentPlayerCount
    ) {
        return (
            totalGamesPlayed,
            totalFeesCollected,
            currentGameId,
            games[currentGameId].playerCount
        );
    }

    // ============ Admin Functions ============

    /**
     * @dev Force complete a game if stuck (emergency only)
     * @notice Only use if game is stuck with enough players
     */
    function forceCompleteGame() external onlyOwner {
        Game storage game = games[currentGameId];
        require(game.status == GameStatus.Waiting, "Game not in waiting status");
        require(game.playerCount >= MIN_PLAYERS, "Not enough players");

        // Auto-spin for players who haven't spun
        Player[] storage players = gamePlayers[currentGameId];
        for (uint256 i = 0; i < players.length; i++) {
            if (!players[i].hasSpun) {
                players[i].spinResult = _generateRandomNumber(players[i].playerAddress, i);
                players[i].hasSpun = true;
                emit PlayerSpun(currentGameId, players[i].playerAddress, players[i].spinResult);
            }
        }

        game.status = GameStatus.Spinning;
        _completeGame(currentGameId);
    }

    /**
     * @dev Emergency withdraw (only if contract is stuck)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
