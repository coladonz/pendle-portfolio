# pendle-portfolio

## Asset Management Functionalities

- Deposits

  Users should be able to deposit any of the following assets

  - ERC20 tokens (underlying tokens supported by Pendle)
  - Pendle SY tokens
  - Pendle PT tokens
  - Pendle YT tokens
  - Pendle LP tokens

- Conversions

  Users should be able to convert deposited assets into other supported assets

  - ERC20 tokens → SY, PT, YT or LP
  - SY tokens → ERC20, PT, YT or LP
  - PT tokens → ERC20, SY, YT or LP
  - YT tokens → ERC20, SY, PT or LP
  - LP tokens → ERC20, SY, PT or YT

- Withdrawals

  Users should be able to withdraw their assets in any of the following assets

  - ERC20 tokens (underlying tokens supported by Pendle)
  - Pendle SY tokens
  - Pendle PT tokens
  - Pendle YT tokens
  - Pendle LP tokens

- Swaps
  Users should be able to directly swap their assets for other types of assets without requiring an initial deposit.

## Testings

- Comprehensive testing including fuzz testing for edge cases.
- All the possible cases should be covered
  - Deposit: 5 cases
  - Conversion: 20 cases
  - Withdrawal: 5 cases
  - Swap: 20 cases

### Coverage

```
Ran 8 tests for test/TanguPendle.t.sol:TanguPendleTest
[PASS] test_0_setMarket() (gas: 33670)
[PASS] test_1_deposit() (gas: 100829)
[PASS] test_2_withdraw() (gas: 115987)
[PASS] test_3_switchAsset_from_erc20_to_sy() (gas: 242846)
[PASS] test_4_switchAsset_from_erc20_to_sy_and_withdraw() (gas: 276075)
[PASS] test_5_swapPublic_from_erc20_to_sy() (gas: 222324)
[PASS] test_7_fuzz_switchAsset(uint8,uint8,uint64) (runs: 259, μ: 550725, ~: 582048)
[PASS] test_8_fuzz_swapPublic(uint8,uint8,uint64) (runs: 259, μ: 536096, ~: 549572)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 39.35s (90.50s CPU time)

Ran 1 test suite in 39.35s (39.35s CPU time): 8 tests passed, 0 failed, 0 skipped (8 total tests)

╭---------------------+----------------+------------------+----------------+-----------------╮
| File                | % Lines        | % Statements     | % Branches     | % Funcs         |
+============================================================================================+
| src/TanguPendle.sol | 98.99% (98/99) | 95.50% (106/111) | 75.76% (25/33) | 100.00% (12/12) |
|---------------------+----------------+------------------+----------------+-----------------|
| Total               | 98.99% (98/99) | 95.50% (106/111) | 75.76% (25/33) | 100.00% (12/12) |
╰---------------------+----------------+------------------+----------------+-----------------╯
```

## Code Quality and Standards

- The code should be structured for maintainability and efficiency.
- It should follow high-quality coding practices and be well-documented.
- NatSpec comments should be included for all functions and contracts to enhance clarity.
