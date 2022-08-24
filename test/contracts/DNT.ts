export default function suite(){
    it("Should pause/unpause by owner", async function (){
        (await this.dnt.pause()).should.satisfy;
        (await this.dnt.unpause()).should.satisfy;
    });
    it("Should not pause/unpause by others", async function (){
        this.dnt.connect(this.accounts[3]).pause().should.be.reverted;
        this.dnt.connect(this.accounts[3]).unpause().should.be.reverted;
    });
    it("Snapshot");
}