const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SpinDBoard", function () {
  let spinDBoard;
  let owner;
  let player1, player2, player3, player4, player5;
  let players;
  
  const ENTRY_FEE = ethers.parseEther("0.00002");

  beforeEach(async function () {
    [owner, player1, player2, player3, player4, player5] = await ethers.getSigners();
    players = [player1, player2, player3, player4, player5];

    const SpinDBoard = await ethers.getContractFactory("SpinDBoard");
    spinDBoard = await SpinDBoard.deploy();
    await spinDBoard.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await spinDBoard.owner()).to.equal(owner.address);
    });

    it("Should have correct constants", async function () {
      expect(await spinDBoard.ENTRY_FEE()).to.equal(ENTRY_FEE);
      expect(await spinDBoard.MIN_PLAYERS()).to.equal(2n);
      expect(await spinDBoard.MAX_PLAYERS()).to.equal(10n);
      expect(await spinDBoard.BOARD_RANGE()).to.equal(10n);
      expect(await spinDBoard.WINNER_PERCENTAGE()).to.equal(50n);
      expect(await spinDBoard.CREATOR_PERCENTAGE()).to.equal(50n);
    });

    it("Should create initial game with ID 1", async function () {
      expect(await spinDBoard.currentGameId()).to.equal(1n);
    });
  });

  describe("Joining Game", function () {
    it("Should allow player to join with correct fee", async function () {
      await expect(spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE }))
        .to.emit(spinDBoard, "PlayerJoined")
        .withArgs(1n, player1.address, 1n);

      const [hasJoined] = await spinDBoard.getPlayerInfo(player1.address);
      expect(hasJoined).to.be.true;
    });

    it("Should reject join with incorrect fee", async function () {
      const wrongFee = ethers.parseEther("0.00001");
      await expect(
        spinDBoard.connect(player1).joinGame({ value: wrongFee })
      ).to.be.revertedWith("Incorrect entry fee");
    });

    it("Should not allow same player to join twice", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await expect(
        spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE })
      ).to.be.revertedWith("Already joined this game");
    });

    it("Should allow up to 10 players", async function () {
      const signers = await ethers.getSigners();
      for (let i = 1; i <= 10; i++) {
        await spinDBoard.connect(signers[i]).joinGame({ value: ENTRY_FEE });
      }

      const [, , , playerCount] = await spinDBoard.getCurrentGame();
      expect(playerCount).to.equal(10n);
    });

    it("Should reject 11th player", async function () {
      const signers = await ethers.getSigners();
      for (let i = 1; i <= 10; i++) {
        await spinDBoard.connect(signers[i]).joinGame({ value: ENTRY_FEE });
      }

      await expect(
        spinDBoard.connect(signers[11]).joinGame({ value: ENTRY_FEE })
      ).to.be.revertedWith("Game is full");
    });
  });

  describe("Spinning", function () {
    beforeEach(async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });
    });

    it("Should not allow spin with less than MIN_PLAYERS", async function () {
      const SpinDBoard = await ethers.getContractFactory("SpinDBoard");
      const newGame = await SpinDBoard.deploy();
      await newGame.waitForDeployment();

      await newGame.connect(player1).joinGame({ value: ENTRY_FEE });
      await expect(newGame.connect(player1).spin()).to.be.revertedWith(
        "Not enough players"
      );
    });

    it("Should not allow non-player to spin", async function () {
      await expect(spinDBoard.connect(player3).spin()).to.be.revertedWith(
        "Not a player in this game"
      );
    });

    it("Should emit PlayerSpun event on spin", async function () {
      await expect(spinDBoard.connect(player1).spin())
        .to.emit(spinDBoard, "PlayerSpun");
    });

    it("Should not allow double spin", async function () {
      await spinDBoard.connect(player1).spin();
      await expect(spinDBoard.connect(player1).spin()).to.be.revertedWith(
        "Already spun"
      );
    });

    it("Should generate spin result between 1 and 10", async function () {
      await spinDBoard.connect(player1).spin();
      const [, spinResult] = await spinDBoard.getPlayerInfo(player1.address);
      expect(spinResult).to.be.gte(1n);
      expect(spinResult).to.be.lte(10n);
    });
  });

  describe("Game Completion", function () {
    it("Should complete game when all players spin", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });

      await spinDBoard.connect(player1).spin();
      await expect(spinDBoard.connect(player2).spin())
        .to.emit(spinDBoard, "GameCompleted");

      // New game should be created
      expect(await spinDBoard.currentGameId()).to.equal(2n);
    });

    it("Should distribute prizes correctly", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });

      const totalPool = ENTRY_FEE * 2n;
      const expectedPrize = totalPool / 2n; // 50%

      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);
      
      await spinDBoard.connect(player1).spin();
      await spinDBoard.connect(player2).spin();

      const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);
      
      // Owner should receive 50% as creator fee
      expect(ownerBalanceAfter - ownerBalanceBefore).to.equal(expectedPrize);
    });

    it("Should track total games played", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player1).spin();
      await spinDBoard.connect(player2).spin();

      const [totalGamesPlayed] = await spinDBoard.getStats();
      expect(totalGamesPlayed).to.equal(1n);
    });
  });

  describe("View Functions", function () {
    it("Should return correct current game info", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });

      const [gameId, status, totalPool, playerCount] = await spinDBoard.getCurrentGame();
      
      expect(gameId).to.equal(1n);
      expect(status).to.equal(0n); // Waiting
      expect(totalPool).to.equal(ENTRY_FEE * 2n);
      expect(playerCount).to.equal(2n);
    });

    it("Should return correct available slots", async function () {
      expect(await spinDBoard.availableSlots()).to.equal(10n);
      
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      expect(await spinDBoard.availableSlots()).to.equal(9n);
    });

    it("Should return correct players needed to start", async function () {
      expect(await spinDBoard.playersNeededToStart()).to.equal(2n);
      
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      expect(await spinDBoard.playersNeededToStart()).to.equal(1n);
      
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });
      expect(await spinDBoard.playersNeededToStart()).to.equal(0n);
    });

    it("Should correctly report canStartSpinning", async function () {
      expect(await spinDBoard.canStartSpinning()).to.be.false;
      
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      expect(await spinDBoard.canStartSpinning()).to.be.false;
      
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });
      expect(await spinDBoard.canStartSpinning()).to.be.true;
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to force complete game", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player1).spin();

      await expect(spinDBoard.forceCompleteGame())
        .to.emit(spinDBoard, "GameCompleted");
    });

    it("Should not allow non-owner to force complete", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });
      await spinDBoard.connect(player2).joinGame({ value: ENTRY_FEE });

      await expect(
        spinDBoard.connect(player1).forceCompleteGame()
      ).to.be.revertedWithCustomError(spinDBoard, "OwnableUnauthorizedAccount");
    });

    it("Should not force complete with insufficient players", async function () {
      await spinDBoard.connect(player1).joinGame({ value: ENTRY_FEE });

      await expect(spinDBoard.forceCompleteGame()).to.be.revertedWith(
        "Not enough players"
      );
    });
  });
});
