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

## Code Quality and Standards

- The code should be structured for maintainability and efficiency.
- It should follow high-quality coding practices and be well-documented.
- NatSpec comments should be included for all functions and contracts to enhance clarity.
