
const ABI = [
    "function joinGame() external payable",
    "function spin() external",
    "function getCurrentGame() external view returns (tuple(uint256 gameId, uint8 status, uint256 totalPool, uint256 playerCount, address winner, uint256 winningNumber, uint256 createdAt, uint256 completedAt))",
    "function getGamePlayers(uint256 gameId) external view returns (tuple(address playerAddress, uint256 spinResult, bool hasSpun)[])",
    "function getPlayerInfo(address player) external view returns (bool hasJoined, bool hasSpun, uint256 spinResult)",
    "event PlayerJoined(uint256 indexed gameId, address indexed player, uint256 playerCount)",
    "event PlayerSpun(uint256 indexed gameId, address indexed player, uint256 spinResult)",
    "event GameCompleted(uint256 indexed gameId, address indexed winner, uint256 winningNumber, uint256 prize)"
];

async function connectWallet() {
    if (typeof window.ethereum === 'undefined') {
        alert('Please install MetaMask!');
        return;
    }
    
    try {
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        provider = new ethers.providers.Web3Provider(window.ethereum);
        signer = provider.getSigner();
        contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
        
        const address = await signer.getAddress();
        document.getElementById('connectBtn').textContent = 
            address.slice(0, 6) + '...' + address.slice(-4);
        
        loadGameInfo();
    } catch (error) {
        console.error('Connection error:', error);
    }
}

async function loadGameInfo() {
    try {
        const game = await contract.getCurrentGame();
        const statusNames = ['Waiting', 'Spinning', 'Completed'];
        
        document.getElementById('gameInfo').innerHTML = `
            <div class="game-stats">
                <div class="stat">
                    <span class="stat-label">Game ID</span>
                    <span class="stat-value">#${game.gameId}</span>
                </div>
                <div class="stat">
                    <span class="stat-label">Status</span>
                    <span class="stat-value">${statusNames[game.status]}</span>
                </div>
                <div class="stat">
                    <span class="stat-label">Players</span>
                    <span class="stat-value">${game.playerCount}/10</span>
                </div>
                <div class="stat">
                    <span class="stat-label">Prize Pool</span>
                    <span class="stat-value">${ethers.utils.formatEther(game.totalPool)} ETH</span>
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error loading game:', error);
    }
}

document.getElementById('connectBtn').addEventListener('click', connectWallet);
