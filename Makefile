# SpinDBoard - Spinning Board Game - Development Makefile

.PHONY: help compile deploy test clean install setup dev frontend serve-contracts interact sweep docker-build docker-run

# Default target
help: ## Show this help message
	@echo "SpinDBoard - Spinning Board Game - Development Commands"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Smart Contract Commands
compile: ## Compile smart contracts
	@echo "⚡ Compiling smart contracts..."
	npm run compile

deploy-base: ## Deploy to Base mainnet
	@echo "🚀 Deploying to Base mainnet..."
	npm run deploy:base

deploy-sepolia: ## Deploy to Base Sepolia testnet
	@echo "🧪 Deploying to Base Sepolia testnet..."
	npm run deploy:baseSepolia

interact-base: ## Interact with contract on Base mainnet
	@echo "🔗 Interacting with Base mainnet contract..."
	npm run interact

interact-sepolia: ## Interact with contract on Base Sepolia
	@echo "🔗 Interacting with Base Sepolia contract..."
	npm run interact:baseSepolia

sweep-base: ## Sweep balances on Base mainnet
	@echo "💰 Sweeping balances on Base mainnet..."
	npm run sweep

sweep-sepolia: ## Sweep balances on Base Sepolia
	@echo "💰 Sweeping balances on Base Sepolia..."
	npm run sweep:baseSepolia

# Testing
test: ## Run tests
	@echo "🧪 Running tests..."
	npm run test

test-gas: ## Run tests with gas reporting
	@echo "⛽ Running tests with gas reporting..."
	npx hardhat test --gas-reporter

test-coverage: ## Run tests with coverage
	@echo "📊 Running tests with coverage..."
	npx hardhat coverage

# Development
install: ## Install dependencies
	@echo "📦 Installing dependencies..."
	npm install

setup: ## Setup development environment
	@echo "🚀 Setting up development environment..."
	./setup.sh

dev: ## Start development mode (compile and watch)
	@echo "👀 Starting development mode..."
	npx hardhat compile --watch

# Frontend
frontend: ## Start frontend development server
	@echo "🌐 Starting frontend server..."
	cd frontend && python3 -m http.server 8000

serve-frontend: ## Serve frontend on port 8000
	@echo "🌐 Serving frontend on http://localhost:8000..."
	cd frontend && python3 -m http.server 8000

# Docker
docker-build: ## Build Docker image
	@echo "🐳 Building Docker image..."
	docker build -t spindboard .

docker-run: ## Run Docker container
	@echo "🐳 Running Docker container..."
	docker run -p 8000:8000 spindboard

docker-compose-up: ## Start services with docker-compose
	@echo "🐳 Starting services with docker-compose..."
	docker-compose up -d

docker-compose-down: ## Stop services with docker-compose
	@echo "🛑 Stopping services with docker-compose..."
	docker-compose down

# Hardhat Network
local-node: ## Start local Hardhat network
	@echo "🏃 Starting local Hardhat network..."
	npx hardhat node

# Verification
verify-base: ## Verify contract on Base mainnet
	@echo "🔍 Verifying contract on Base mainnet..."
	npx hardhat verify --network base $(shell cat .env | grep CONTRACT_ADDRESS | cut -d '=' -f2)

verify-sepolia: ## Verify contract on Base Sepolia
	@echo "🔍 Verifying contract on Base Sepolia..."
	npx hardhat verify --network baseSepolia $(shell cat .env | grep CONTRACT_ADDRESS | cut -d '=' -f2)

# Environment
env-check: ## Check environment setup
	@echo "🔍 Checking environment..."
	@node --version
	@npm --version
	@npx hardhat --version
	@echo "✅ Environment check complete"

# Cleanup
clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	rm -rf artifacts
	rm -rf cache
	rm -rf typechain-types
	rm -rf coverage

clean-all: ## Clean everything including node_modules
	@echo "🧹 Cleaning everything..."
	rm -rf artifacts
	rm -rf cache
	rm -rf typechain-types
	rm -rf coverage
	rm -rf node_modules

# Deployment helpers
deploy-local: ## Deploy to local network
	@echo "🏠 Deploying to local network..."
	npx hardhat run scripts/deploy.js --network localhost

# Utility
flatten-contract: ## Flatten contract for verification
	@echo "📄 Flattening contract..."
	npx hardhat flatten contracts/SpinDBoard.sol > contracts/SpinDBoard_Flattened.sol

gas-report: ## Generate gas usage report
	@echo "⛽ Generating gas usage report..."
	npx hardhat test --gas-reporter

# Game simulation
simulate-game: ## Simulate a game locally
	@echo "🎮 Simulating game..."
	npx hardhat run scripts/simulateGame.js --network localhost

# Balance checking
check-balances: ## Check contract balances
	@echo "💰 Checking contract balances..."
	npx hardhat run scripts/checkBalances.js --network base