// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Withdrawable} from "../utility/Withdrawable.sol";

contract BiosWoeldSaleBSC is Ownable, Pausable, ReentrancyGuard, Withdrawable {
    using SafeERC20 for IERC20;

    IERC20 public s_usdt;

    address public i_bnb_usd_priceFeed;
    address public i_busd_usd_priceFeed;
    address public s_biosWorldToken;

    uint256 public s_usdtPrice = 6000;
    uint256 public s_minAmountToInvest = 100000000;
    uint256 public s_maxAmountToInvest = 5000000000;
    uint256 public s_tokensForSale = 80000000 ether;
    uint256 public s_tokenSold;

    uint256 public s_claimDate = 1716622822;

    mapping(address => uint256) public s_investemetByAddress;
    mapping(address => bool) public s_managers;

    event BoughtWithNativeToken(address user, uint256 amount, uint256 time);
    event BoughtWithUSDT(address user, uint256 amount, uint256 time);
    event BoughtWithAPI(address user, uint256 amount, uint256 time);

    modifier onlyManager() {
        require(s_managers[msg.sender], "Only manager function");
        _;
    }

    constructor() {
        s_managers[msg.sender] = true;

        if (block.chainid == 56) {
            i_bnb_usd_priceFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
            i_busd_usd_priceFeed = 0xcBb98864Ef56E9042e7d2efef76141f15731B82f;
            s_usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
            s_biosWorldToken = 0xeaCD3563a4622f84915B1694ea3f293ADA2a427E;
        } else {
            i_bnb_usd_priceFeed = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
            i_busd_usd_priceFeed = 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0;
            s_usdt = IERC20(0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832);
            s_biosWorldToken = 0x1B03969E71B5406a47bb1d48423a6102457872a1;
        }
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    receive() external payable {}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function _getDerivedPrice(
        address _base,
        address _quote,
        uint8 _decimals
    ) internal view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 decimals = int256(10 ** uint256(_decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = _scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = _scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals) / quotePrice;
    }

    function _scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function _getBNBPriceInUSDT() public view returns (int256) {
        return _getDerivedPrice(i_bnb_usd_priceFeed, i_busd_usd_priceFeed, 6);
    }

    function _getTokensForUSDT(
        uint256 usdt_amount
    ) public view returns (uint256) {
        return div(usdt_amount, s_usdtPrice);
    }

    function _getPriceOfGivenTokenInBNB(
        int256 amount
    ) public view returns (int256) {
        int256 usdtPriceInBNB = _getDerivedPrice(
            i_busd_usd_priceFeed,
            i_bnb_usd_priceFeed,
            18
        );

        int256 priceOfTokensInUsdt = int256(
            multiply(uint256(amount), s_usdtPrice)
        );

        int256 formmatedPriceOfTokensInUsdt = _scalePrice(
            priceOfTokensInUsdt,
            6,
            18
        );

        return ((formmatedPriceOfTokensInUsdt * usdtPriceInBNB) / 1e18);
    }

    function updateMaxInvestment(uint256 amount) external onlyOwner {
        s_maxAmountToInvest = amount;
    }

    function updateMinInvestment(uint256 amount) external onlyOwner {
        s_minAmountToInvest = amount;
    }

    function updateUsdt(IERC20 usdt) external onlyOwner {
        s_usdt = usdt;
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        s_usdtPrice = newPrice;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function buyTokensNative() external payable whenNotPaused nonReentrant {
        uint256 usdt_amount = multiply(
            msg.value,
            uint256(_getBNBPriceInUSDT())
        );
        uint256 tokenAmount = _getTokensForUSDT(usdt_amount);

        s_investemetByAddress[msg.sender] =
            s_investemetByAddress[msg.sender] +
            tokenAmount;
        s_tokenSold = s_tokenSold + tokenAmount;

        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Funds transfer unsuccesfull");
        emit BoughtWithNativeToken(msg.sender, tokenAmount, block.timestamp);
    }

    function buyTokensUSDT(uint256 amount) external whenNotPaused nonReentrant {
        uint256 tokenAmount = _getTokensForUSDT(amount);
        uint256 formattedToken = tokenAmount * 1 ether;
        s_investemetByAddress[msg.sender] =
            s_investemetByAddress[msg.sender] +
            formattedToken;
        s_tokenSold = s_tokenSold + formattedToken;
        s_usdt.safeTransferFrom(msg.sender, owner(), amount);
        emit BoughtWithUSDT(msg.sender, formattedToken, block.timestamp);
    }

    function buyTokensAPI(
        address user,
        uint256 tokenAmount
    ) external payable whenNotPaused nonReentrant onlyManager {
        s_investemetByAddress[user] = s_investemetByAddress[user] + tokenAmount;
        s_tokenSold = s_tokenSold + tokenAmount;

        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Funds transfer unsuccesfull");
        emit BoughtWithAPI(user, tokenAmount, block.timestamp);
    }

    function claim() external whenNotPaused nonReentrant {
        require(
            s_investemetByAddress[msg.sender] > 0,
            "You dont have enough tokens to claim"
        );
        require(block.timestamp >= s_claimDate, "You cannot claim now");
        uint256 claimableToken = s_investemetByAddress[msg.sender];
        require(
            IERC20(s_biosWorldToken).balanceOf(address(this)) >= claimableToken,
            "Not enough tokens"
        );
        require(IERC20(s_biosWorldToken).transfer(msg.sender, claimableToken));
    }

    function updateBiosWorldToken(address newToken) external onlyOwner {
        s_biosWorldToken = newToken;
    }

    function updateClaimDate(uint256 newClaimDate) external onlyOwner {
        s_claimDate = newClaimDate;
    }

    function addManager(address user, bool isManager) external onlyOwner {
        s_managers[user] = isManager;
    }
}
