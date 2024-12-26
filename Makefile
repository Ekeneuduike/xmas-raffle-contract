-include .env
.PHONY: format , deploy-test, deploy ,deploy-sepolia
format:; forge fmt 
deploy-test:;  forge script script/xmasGame.s.sol --rpc-url  http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 broadcast -vvvvv
deploy:; @forge script script/xmasGame.s.sol --rpc-url ${ARB_RPC_URL} --private-key ${PRIVATE_KEY} --etherscan-api-key ${ARB_SCAN_KEY} --verify --broadcast -vvvvv
deploy-sepolia:; @forge script script/xmasGame.s.sol --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --etherscan-api-key ${ETHERSCAN_API_KEY} --verify --broadcast -vvvvv
