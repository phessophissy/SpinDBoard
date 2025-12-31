# SpinDBoard - Spinning Board Game on Base Chain

A decentralized spinning board game deployed on Base Chain Mainnet where players spin to win!

## Game Rules

1. **Board Range**: Numbers 1-10
2. **Players**: Minimum 2, Maximum 10 per game
3. **Entry Fee**: 0.00002 ETH per player
4. **Winner**: Player with the highest spin number wins
5. **Prize Distribution**:
   - 50% goes to the winner
   - 50% goes to the game creator (contract owner)

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:
- `DEPLOYER_PRIVATE_KEY`: Your deployer wallet private key
- `BASE_RPC_URL`: Base Mainnet RPC URL
- `BASESCAN_API_KEY`: For contract verification

### 3. Generate Test Wallets (Optional)

Generate 10 wallets for testing:

```bash
npx hardhat run scripts/generateWallets.js
```

Copy the generated private keys to your `.env` file.

### 4. Fund Wallets

Each wallet needs at least:
- 0.00002 ETH (entry fee)
- ~0.00008 ETH (gas fees)
- Recommended: 0.0001 ETH per wallet

## Deployment

### Deploy to Base Mainnet

```bash
npm run deploy:base
```

### Deploy to Base Sepolia (Testnet)

```bash
npm run deploy:baseSepolia
```

After deployment, copy the contract address to your `.env` file:
```
SPINDBOARD_CONTRACT_ADDRESS=0x...
```

## Testing

Run the test suite:

```bash
npm test
```

## Interaction Script

The interaction script allows you to play the game with multiple wallets.

### Check Game Status

```bash
npx hardhat run scripts/interact.js --network base -- --action=status
```

### Join Game with Players

```bash
# Join with 3 players (default)
npx hardhat run scripts/interact.js --network base -- --action=join --players=3

# Join with 5 players
npx hardhat run scripts/interact.js --network base -- --action=join --players=5
```

### Spin for All Joined Players

```bash
npx hardhat run scripts/interact.js --network base -- --action=spin
```

### Run Complete Game Demo

```bash
# Run demo with 3 players
npx hardhat run scripts/interact.js --network base -- --action=demo --players=3
```

### View Game Results

```bash
npx hardhat run scripts/interact.js --network base -- --action=results --gameId=1
```

## Contract Functions

### Player Functions

| Function | Description |
|----------|-------------|
| `joinGame()` | Join the current game (requires 0.00002 ETH) |
| `spin()` | Spin the board to get your number |

### View Functions

| Function | Description |
|----------|-------------|
| `getCurrentGame()` | Get current game details |
| `getGame(gameId)` | Get specific game details |
| `getGamePlayers(gameId)` | Get all players in a game |
| `getPlayerInfo(address)` | Get player status in current game |
| `canStartSpinning()` | Check if game can start |
| `playersNeededToStart()` | Number of players needed |
| `availableSlots()` | Open slots in current game |
| `getStats()` | Get contract statistics |

### Admin Functions (Owner Only)

| Function | Description |
|----------|-------------|
| `forceCompleteGame()` | Force complete a stuck game |
| `emergencyWithdraw()` | Emergency withdrawal |

## Contract Events

| Event | Description |
|-------|-------------|
| `GameCreated` | New game created |
| `PlayerJoined` | Player joined a game |
| `PlayerSpun` | Player completed their spin |
| `GameCompleted` | Game finished with winner |
| `WinnerPaid` | Winner received prize |
| `CreatorFeePaid` | Creator received fee |

## Security Notes

1. **Randomness**: The contract uses `block.prevrandao` for randomness. For higher stakes, consider using Chainlink VRF.
2. **Reentrancy**: Protected with OpenZeppelin's `ReentrancyGuard`.
3. **Access Control**: Admin functions protected with `Ownable`.

## Networks

| Network | Chain ID | RPC URL |
|---------|----------|---------|
| Base Mainnet | 8453 | https://mainnet.base.org |
| Base Sepolia | 84532 | https://sepolia.base.org |

## License

MIT
