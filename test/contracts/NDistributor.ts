import { ethers } from "hardhat";

export default function suite(){
    describe("Role management", function () {
        it("Should add managers", async function() {
            (await this.distr.addManager(this.dnt.address)).should.satisfy;
            (await this.distr.addManager(this.ls.address)).should.satisfy;
        });

    });

    describe("Asset management", function () {
        it("Should add LS utility", async function () {
            await this.distr.addUtility("LiquidStaking")
            const uid = await this.distr.utilityId("LiquidStaking");
            uid.should.equal(0);
        });
        it("Should revert if utility exists", async function () {
            this.distr.addUtility("LiquidStaking").should.be.reverted();
        });

        it("Should add dnt", async function () {
            const dntName = await this.dnt.name();
            const res = await this.distr.addDnt(dntName, this.dnt)
            (await this.distr.dntContracts["nASTR"])
                .should.not.equal(ethers.constants.AddressZero);
        });
        it("Should revert if strangers try to add dnt", async function () {
            this.distr.connect(this.accounts[1])
                .addDnt("Whateva", this.accounts[2].address)
                    .should.be.reverted();
        });
        it("Should revert if dnt already registered", async function () {
            this.distr.dntContracts["nASTR"].should.be.reveered();
        });

        it("changeDntAddress");
        it("setDntStatus");
    });

    describe("Admin", function () {
        it("Should set liquid staking addr", async function () {
            (await this.distr.setLiquidStaking(this.ls.address)).should.satisfy;
        });
        it("Should not change LS address", function () {
            this.distr.setLiquidStaking(this.ls.address).should.be.reverted;
        });

        it("transferDntContractOwnership");
    });
}