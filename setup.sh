#!/bin/bash

# SpinDBoard - Spinning Board Game - Development Setup Script
echo "🚀 Setting up SpinDBoard development environment..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d"." -f1 | cut -d"v" -f2)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Check if .env exists, if not create from .env.example
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo "📋 Setting up environment variables..."
    cp .env.example .env
    echo "✅ Created .env from .env.example"
    echo "   Please update .env with your actual configuration values"
fi

# Compile contracts to check if everything is working
echo "⚡ Compiling smart contracts..."
npm run compile

if [ $? -eq 0 ]; then
    echo "✅ Smart contracts compiled successfully"
else
    echo "❌ Smart contract compilation failed"
    exit 1
fi

echo "🎉 Setup complete!"
echo ""
echo "Available commands:"
echo "  make help              - Show all available commands"
echo "  make compile           - Compile smart contracts"
echo "  make test              - Run tests"
echo "  make frontend          - Start frontend server"
echo "  make local-node        - Start local Hardhat network"
echo "  make docker-compose-up - Start all services"
echo ""
echo "Deployment commands:"
echo "  make deploy-base       - Deploy to Base mainnet"
echo "  make deploy-sepolia    - Deploy to Base Sepolia testnet"
echo "  make interact-base     - Interact with Base mainnet contract"
echo "  make sweep-base        - Sweep balances on Base mainnet"
echo ""
echo "Next steps:"
echo "1. Update .env with your private key and RPC URLs"
echo "2. Run 'make local-node' to start a local blockchain for testing"
echo "3. Run 'make frontend' to start the frontend server"
echo "4. Run 'make test' to run the test suite"
echo ""
echo "For Base Chain deployment:"
echo "- Ensure you have ETH in your wallet for gas fees"
echo "- Update .env with Base mainnet/sepolia RPC URLs"
echo "- Use 'make deploy-base' for mainnet or 'make deploy-sepolia' for testnet"
echo ""
echo "Game Rules Reminder:"
echo "- Board range: 1-10"
echo "- Entry fee: 0.00002 ETH per player"
echo "- Winner takes 50%, creator takes 50%"
echo "- Minimum 2 players, maximum 10 players per game"