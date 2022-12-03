// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libs/Erc20.sol";
import "./libs/UniswapV2.sol";

contract Swap {
    address private constant UNISWAP_V2_ROUTER =
        0xBf5140A22578168FD562DCcF235E5D43A02ce9B1;

    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IUniswapV2Router private router = IUniswapV2Router(UNISWAP_V2_ROUTER);

    IERC20 private wbnb = IERC20(WBNB);
    IERC20 private dai = IERC20(DAI);
    IERC20 private usdt = IERC20(USDT);

    // DAI -> WBNB -> USDT
    function swapMultiHopExactAmountIn(
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut) {
        dai.transferFrom(msg.sender, address(this), amountIn);
        dai.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = DAI;
        path[1] = WBNB;
        path[2] = USDT;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOut,
            path,
            msg.sender,
            block.timestamp
        );

        return amounts[2];
    }

    // USDT -> WBNB -> DAI
    function swapMultiHopExactAmountOut(
        uint amountOutDesired,
        uint amountInMax
    ) external returns (uint amountOut) {
        usdt.transferFrom(msg.sender, address(this), amountInMax);
        usdt.approve(address(router), amountInMax);

        address[] memory path;
        path[0] = DAI;
        path[1] = WBNB;
        path[2] = USDT;

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );

        if (amounts[0] < amountInMax) {
            dai.transfer(msg.sender, amountInMax - amounts[0]);
        }
        return amounts[2];
    }
}
