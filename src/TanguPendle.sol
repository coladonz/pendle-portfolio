// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@pendle/v2-core/contracts/interfaces/IPAllActionV3.sol";

/// @title TanguPendle
/// @author coladonz
/// @notice A portfolio management contract of Pendle Assets to allow users to deposit, withdraw, and swap assets
contract TanguPendle is Ownable {
    using SafeERC20 for IERC20;

    /// @dev TokenType is used to represent the type of token
    enum TokenType {
        ERC20,
        SY,
        PT,
        YT,
        LP
    }

    /// @dev MarketInfo is used to store the market information
    struct MarketInfo {
        address uToken;
        address syToken;
        address ptToken;
        address ytToken;
        address lpToken;
    }

    IPAllActionV3 public constant pendleRouter =
        IPAllActionV3(0x888888888889758F76e7103c6CbF23ABbF58F946);

    mapping(address market => MarketInfo) public marketInfos;
    mapping(address user => mapping(bytes32 key => uint)) public balanceOf;

    /// @dev AddMarket event is emitted when a new market is added
    event AddMarket(
        address market,
        address uToken,
        address syToken,
        address ptToken,
        address ytToken,
        address lpToken
    );
    /// @dev Deposit event is emitted when a user deposits assets into the contract
    event Deposit(
        address indexed user,
        address indexed market,
        TokenType tokenType,
        uint amount
    );
    /// @dev Withdraw event is emitted when a user withdraws assets from the contract
    event Withdraw(
        address indexed user,
        address indexed market,
        TokenType tokenType,
        uint amount
    );
    /// @dev Swap event is emitted when a user swaps assets
    event Swap(
        address indexed user,
        address indexed market,
        TokenType fromTokenType,
        TokenType toTokenType,
        uint amountIn,
        uint amountOut
    );

    /// @dev Error codes
    error InvalidToken();
    error InvalidMarket();
    error InvalidTokenType();
    error InsufficientBalance();
    error InvalidSwap(TokenType fromTokenType, TokenType toTokenType);

    /// @dev Modifier to check if the market is valid
    modifier onlyValidMarket(address market) {
        if (marketInfos[market].uToken == address(0)) revert InvalidMarket();
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @dev SetMarket is used to set the market information
    function setMarket(
        address market,
        address uToken,
        address syToken,
        address ptToken,
        address ytToken,
        address lpToken
    ) external onlyOwner {
        if (
            market == address(0) ||
            uToken == address(0) ||
            syToken == address(0) ||
            ptToken == address(0) ||
            ytToken == address(0) ||
            lpToken == address(0)
        ) revert InvalidMarket();

        marketInfos[market] = MarketInfo(uToken, syToken, ptToken, ytToken, lpToken);
        emit AddMarket(market, uToken, syToken, ptToken, ytToken, lpToken);
    }

    /// @notice Deposit is used to deposit assets into the contract
    /// @param market The market to deposit assets into
    /// @param tokenType The type of token to deposit
    /// @param amount The amount of tokens to deposit
    function deposit(
        address market,
        TokenType tokenType,
        uint amount
    ) external onlyValidMarket(market) {
        address token = _getToken(market, tokenType);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender][_getKey(msg.sender, market, tokenType)] += amount;
        emit Deposit(msg.sender, market, tokenType, amount);
    }

    /// @notice Withdraw is used to withdraw assets from the contract
    /// @param market The market to withdraw assets from
    /// @param tokenType The type of token to withdraw
    /// @param amount The amount of tokens to withdraw
    function withdraw(
        address market,
        TokenType tokenType,
        uint amount
    ) external onlyValidMarket(market) {
        bytes32 key = _getKey(msg.sender, market, tokenType);
        uint balance = balanceOf[msg.sender][key];

        if (balance < amount) revert InsufficientBalance();

        balanceOf[msg.sender][key] -= amount;
        address token = _getToken(market, tokenType);
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, market, tokenType, amount);
    }

    /// @notice SwitchAsset is used to switch assets between different types
    /// @dev This function is only available for depositors
    /// @param market The market to switch assets between
    /// @param fromTokenType The type of token to switch from
    /// @param toTokenType The type of token to switch to
    function switchAsset(
        address market,
        TokenType fromTokenType,
        TokenType toTokenType
    ) external onlyValidMarket(market) {
        bytes32 fromKey = _getKey(msg.sender, market, fromTokenType);
        bytes32 toKey = _getKey(msg.sender, market, toTokenType);
        uint fromBalance = balanceOf[msg.sender][fromKey];

        if (fromBalance == 0) revert InsufficientBalance();

        uint netOut = _exchangeAssets(
            market,
            fromTokenType,
            toTokenType,
            fromBalance,
            address(this)
        );
        balanceOf[msg.sender][fromKey] = 0;
        balanceOf[msg.sender][toKey] += netOut;
        emit Swap(msg.sender, market, fromTokenType, toTokenType, fromBalance, netOut);
    }

    /// @notice SwapPublic is used for anyone to swap assets between different types
    /// @param market The market to swap assets between
    /// @param fromTokenType The type of token to swap from
    /// @param toTokenType The type of token to swap to
    /// @param amount The amount of tokens to swap
    /// @return netOut The amount of tokens received
    function swapPublic(
        address market,
        TokenType fromTokenType,
        TokenType toTokenType,
        uint amount
    ) external onlyValidMarket(market) returns (uint netOut) {
        address fromToken = _getToken(market, fromTokenType);
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
        netOut = _exchangeAssets(market, fromTokenType, toTokenType, amount, msg.sender);
        emit Swap(msg.sender, market, fromTokenType, toTokenType, amount, netOut);
    }

    function getMarketInfo(address market) external view returns (MarketInfo memory) {
        return marketInfos[market];
    }

    /// @dev _getToken is used to get the token address for a given market and token type
    /// @param market The market to get the token address from
    /// @param tokenType The type of token to get the address for
    /// @return The address of the token
    function _getToken(
        address market,
        TokenType tokenType
    ) internal view returns (address) {
        if (tokenType == TokenType.ERC20) {
            return marketInfos[market].uToken;
        } else if (tokenType == TokenType.SY) {
            return marketInfos[market].syToken;
        } else if (tokenType == TokenType.PT) {
            return marketInfos[market].ptToken;
        } else if (tokenType == TokenType.YT) {
            return marketInfos[market].ytToken;
        } else if (tokenType == TokenType.LP) {
            return marketInfos[market].lpToken;
        }

        revert InvalidTokenType();
    }

    /// @dev _getKey is used to generate a unique key for a given user, market, and token type
    /// @param user The user to generate the key for
    /// @param market The market to generate the key for
    /// @param tokenType The type of token to generate the key for
    /// @return The unique key for the given user, market, and token type
    function _getKey(
        address user,
        address market,
        TokenType tokenType
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(user, market, tokenType));
    }

    /// @dev _exchangeAssets is used to exchange assets between different types
    /// @param market The market to exchange assets between
    /// @param fromTokenType The type of token to exchange from
    /// @param toTokenType The type of token to exchange to
    /// @param fromBalance The amount of tokens to exchange
    /// @param to The address to receive the exchanged tokens
    /// @return netOut The amount of tokens received
    function _exchangeAssets(
        address market,
        TokenType fromTokenType,
        TokenType toTokenType,
        uint fromBalance,
        address to
    ) internal returns (uint netOut) {
        if (fromTokenType == toTokenType) revert InvalidSwap(fromTokenType, toTokenType);

        // Convert fromToken to syToken
        uint syOut;
        address syToken = _getToken(market, TokenType.SY);
        address fromToken = _getToken(market, fromTokenType);
        address toToken = _getToken(market, toTokenType);
        IERC20(fromToken).forceApprove(address(pendleRouter), fromBalance);
        if (fromTokenType == TokenType.ERC20) {
            syOut = pendleRouter.mintSyFromToken(
                address(this),
                syToken,
                0,
                createTokenInputSimple(fromToken, fromBalance)
            );
        } else if (fromTokenType == TokenType.PT) {
            (syOut, ) = pendleRouter.swapExactPtForSy(
                address(this),
                market,
                fromBalance,
                0,
                createEmptyLimitOrderData()
            );
        } else if (fromTokenType == TokenType.YT) {
            (syOut, ) = pendleRouter.swapExactYtForSy(
                address(this),
                market,
                fromBalance,
                0,
                createEmptyLimitOrderData()
            );
        } else if (fromTokenType == TokenType.LP) {
            (syOut, ) = pendleRouter.removeLiquiditySingleSy(
                address(this),
                market,
                fromBalance,
                0,
                createEmptyLimitOrderData()
            );
        } else if (fromTokenType == TokenType.SY) {
            syOut = fromBalance;
        }

        // Convert syToken to toToken
        IERC20(syToken).forceApprove(address(pendleRouter), syOut);
        if (toTokenType == TokenType.ERC20) {
            netOut = pendleRouter.redeemSyToToken(
                to,
                syToken,
                syOut,
                createTokenOutputSimple(toToken, 0)
            );
        } else if (toTokenType == TokenType.PT) {
            (netOut, ) = pendleRouter.swapExactSyForPt(
                to,
                market,
                syOut,
                0,
                createDefaultApproxParams(),
                createEmptyLimitOrderData()
            );
        } else if (toTokenType == TokenType.YT) {
            (netOut, ) = pendleRouter.swapExactSyForYt(
                to,
                market,
                syOut,
                0,
                createDefaultApproxParams(),
                createEmptyLimitOrderData()
            );
        } else if (toTokenType == TokenType.LP) {
            (netOut, ) = pendleRouter.addLiquiditySingleSy(
                to,
                market,
                syOut,
                0,
                createDefaultApproxParams(),
                createEmptyLimitOrderData()
            );
        } else if (toTokenType == TokenType.SY) {
            netOut = syOut;
            IERC20(syToken).safeTransfer(to, syOut);
        }
    }
}
