# bitcoincom-solidity-swap

This repository contains smart-contracts for the swap between token A and token B or
token A to ETH / ETH to token A.


### Process and Testing

The package can be run as a CLI for testing purposes.

🔗 First start a local chain:

```
npm run chain
```

Then run test commands for contract deployment and testing


🚀 This command runs token tests:
```
npm run test-token
```


🌯 This command runs wrapped ether tests:
```
npm run test-wraps
```


🏭 This command runs swap router / swap factory tests:
```
npm run test-swaps
```

### Test coverage

🧪 To generate test-coverage report simply run this command (without starting local chain)

```
npm run test-coverage
```

🧪 expected-latest results:
```
---------------------|----------|----------|----------|----------|----------------|
File                 |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
---------------------|----------|----------|----------|----------|----------------|
 contracts/          |     89.2 |       60 |    87.91 |    89.46 |                |
  IERC20.sol         |      100 |      100 |      100 |      100 |                |
  ISwapsCallee.sol   |      100 |      100 |      100 |      100 |                |
  ISwapsERC20.sol    |      100 |      100 |      100 |      100 |                |
  ISwapsFactory.sol  |      100 |      100 |      100 |      100 |                |
  ISwapsPair.sol     |      100 |      100 |      100 |      100 |                |
  ISwapsRouter.sol   |      100 |      100 |      100 |      100 |                |
  IWETH.sol          |      100 |      100 |      100 |      100 |                |
  SwapsFactory.sol   |    97.81 |       70 |      100 |    99.27 |            226 |
  SwapsHelper.sol    |      100 |      100 |      100 |      100 |                |
  SwapsLibrary.sol   |      100 |       55 |      100 |      100 |                |
  SwapsRouter.sol    |    73.13 |    51.92 |    60.71 |    72.86 |... 9,1074,1090 |
  Token.sol          |      100 |      100 |      100 |      100 |                |
  TransferHelper.sol |      100 |       50 |      100 |      100 |                |
  WrappedEther.sol   |      100 |      100 |      100 |      100 |                |
---------------------|----------|----------|----------|----------|----------------|
All files            |     89.2 |       60 |    87.91 |    89.46 |                |
---------------------|----------|----------|----------|----------|----------------|
```

⛽ expected gas:
```
·--------------------------------------------------------------------------|---------------------------|-------------|----------------------------·
|                   Solc version: 0.8.10+commit.fc410830                   ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6718946 gas  │
···········································································|···························|·············|·····························
|  Methods                                                                                                                                        │
·················|·························································|·············|·············|·············|··············|··············
|  Contract      ·  Method                                                 ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsERC20    ·  approve                                                ·      25721  ·      45233  ·      40756  ·           9  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsERC20    ·  transfer                                               ·      36681  ·      51669  ·      44175  ·           8  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsERC20    ·  transferFrom                                           ·      29180  ·      38139  ·      32170  ·           6  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsFactory  ·  createPair                                             ·     222566  ·     237576  ·     230074  ·           8  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsFactory  ·  setFeeTo                                               ·          -  ·          -  ·      28531  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsFactory  ·  setFeeToSetter                                         ·          -  ·          -  ·      28453  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsPair     ·  skim                                                   ·          -  ·          -  ·      74282  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  addLiquidity                                           ·     155079  ·     246004  ·     184085  ·           9  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  addLiquidityETH                                        ·     152752  ·     244004  ·     196892  ·           5  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  removeLiquidity                                        ·          -  ·          -  ·     157661  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  removeLiquidityETH                                     ·          -  ·          -  ·     181951  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapETHForExactTokens                                  ·          -  ·          -  ·     117950  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapExactETHForTokens                                  ·          -  ·          -  ·     110006  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapExactETHForTokensSupportingFeeOnTransferTokens     ·          -  ·          -  ·     114692  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapExactTokensForETH                                  ·          -  ·          -  ·     128593  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapExactTokensForETHSupportingFeeOnTransferTokens     ·          -  ·          -  ·     130246  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapExactTokensForTokens                               ·          -  ·          -  ·     111779  ·           1  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapExactTokensForTokensSupportingFeeOnTransferTokens  ·          -  ·          -  ·     116555  ·           2  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapTokensForExactETH                                  ·          -  ·          -  ·     128585  ·           1  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  SwapsRouter   ·  swapTokensForExactTokens                               ·          -  ·          -  ·     111806  ·           1  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  Token         ·  approve                                                ·      29394  ·      44394  ·      31894  ·          12  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  Token         ·  transfer                                               ·          -  ·          -  ·      36085  ·           1  ·          -  │
·················|·························································|·············|·············|·············|··············|··············
|  Deployments                                                             ·                                         ·  % of limit  ·             │
···········································································|·············|·············|·············|··············|··············
|  SwapsRouter                                                             ·          -  ·          -  ·    3695699  ·        55 %  ·          -  │
·--------------------------------------------------------------------------|-------------|-------------|-------------|--------------|-------------·

```
