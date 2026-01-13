// SpinDBoard Frontend
const CONTRACT_ADDRESS = '0x...'; // Set your contract address
const ENTRY_FEE = '0.00002';

let provider, signer, contract;

async function joinGame() {
    if (!contract) {
        alert('Please connect wallet first!');
        return;
    }
    
    try {
        const btn = document.getElementById('joinBtn');
        btn.disabled = true;
        btn.textContent = 'Joining...';
        
        const tx = await contract.joinGame({
            value: ethers.utils.parseEther(ENTRY_FEE)
        });
        await tx.wait();
        
        btn.textContent = 'Joined!';
        loadGameInfo();
    } catch (error) {
        console.error('Join error:', error);
        document.getElementById('joinBtn').textContent = 'Join Game (0.00002 ETH)';
        document.getElementById('joinBtn').disabled = false;
    }
}
