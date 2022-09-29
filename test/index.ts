import { default as cfg } from "../config/cfg.json";
import { default as consts } from "../config/consts.json";

import { run } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers, upgrades } from "hardhat";
import { abiERC20 } from "./abiERC20";


let signer: SignerWithAddress;
let acc: SignerWithAddress;
let accs: SignerWithAddress[];

let liquidStaking: Contract;
let nASTR: Contract;
let distr: Contract;
let dappsStaking: Contract;

const zeroHash = ethers.constants.HashZero;
const zeroAddress = ethers.constants.AddressZero;

let amount: BigNumber = ethers.utils.parseEther("1000");
let offset: BigNumber = BigNumber.from("1000000000");

let rewPerEra: BigNumber;
let unbPeriod: BigNumber;

//wait n sec
const wait = async (ms: number) => {
  console.log("Waiting", ms, "ms")
  await new Promise(f => setTimeout(f, ms));
}

let eraDuration = 30;
//wait n eras
async function waitEra(eras: number) {
  await new Promise(f => setTimeout(f, eras * eraDuration * 1000));
}

async function era() {
  return await liquidStaking.currentEra();
}

// wait till next era 
async function nextEra() {
  const _era = (await era()).add(1);
  while (true) {
    await new Promise(f => setTimeout(f, 10000));
    if ((await era()).gte(_era)) {
      console.log(' > next era');
      return;
    }
  }
}

function _ofset(x: BigNumber) {
  return x.div(offset).mul(offset);
}

async function info() {
  console.log('-------------------------------------');
  console.log('Current era         ', await era());
  console.log('Total dnt           ', await distr.totalDnt(consts.dnt));
  console.log('Total dnt in util   ', await distr.totalDntInUtil(consts.util));
  console.log('Total dnt in util2  ', await distr.totalDntInUtil(consts.util2));
  console.log('Signer dnt in util  ', await distr.getUserDntBalanceInUtil(signer.address, consts.util, consts.dnt));
  console.log('Signer dnt in util2 ', await distr.getUserDntBalanceInUtil(signer.address, consts.util2, consts.dnt));
  console.log('Acc dnt in util     ', await distr.getUserDntBalanceInUtil(acc.address, consts.util, consts.dnt));
  console.log('Acc dnt in util2    ', await distr.getUserDntBalanceInUtil(acc.address, consts.util2, consts.dnt));
  console.log('Preview signer rews ', await liquidStaking.getUserRewards(signer.address));
  console.log('Preview signer rews2', await liquidStaking.getUserRewards(signer.address));
  console.log('Preview acc rews    ', await liquidStaking.getUserRewards(acc.address));
  console.log('Preview acc rews2   ', await liquidStaking.getUserRewards(acc.address));
  console.log('Rewards pool        ', await liquidStaking.rewardPool());
  console.log('Unbonded pool       ', await liquidStaking.unbondedPool());
  console.log('Unstaking pool      ', await liquidStaking.unstakingPool());
  console.log('LiqStaking balance  ', await ethers.provider.getBalance(liquidStaking.address));
  console.log('-------------------------------------');
}


describe("App", function () {

  describe("Algem", function () {

    before(async function () {
      accs = await ethers.getSigners();
      signer = accs[0];
      acc = accs[1];

      // get contracts if set in config
      if (cfg.distr !== "") {
        distr = await ethers.getContractAt('NDistributor', cfg.distr);
      }
      if (cfg.nASTR !== "") {
        nASTR = await ethers.getContractAt('NASTR', cfg.nASTR);
      }
      if (cfg.liquidStaking !== "") {
        liquidStaking = await ethers.getContractAt('LiquidStaking', cfg.liquidStaking);
      }
      dappsStaking = await ethers.getContractAt('DappsStaking', cfg.dappsStaking);

      //give initial money to some addresses
      for (let i = 0; i < 15; i++) {
        await run("giveMoney", { to: accs[i].address, amount: "1000" });
        await wait(2000);
      }

      console.log('signer:  ', signer.address);
      console.log('balance: ', await signer.getBalance());
      console.log('--------------------');
      console.log('acc:  ', acc.address);
      console.log('balance: ', await acc.getBalance());
      console.log('--------------------');
      console.log('unb period:  ', await dappsStaking.read_unbonding_period());
      console.log('current era: ', await dappsStaking.read_current_era());
    });

    describe("Deploy contracts", function () {

      it("Should deploy NDistributor", async () => {
        if (distr !== undefined) {
          console.log("Using already deployed contract at", distr.address);
        } else {
          const distrF = await ethers.getContractFactory("NDistributor");
          distr = await upgrades.deployProxy(distrF);
          await distr.deployed();
        }
        expect(distr.address).not.to.be.eq(zeroAddress);
      });

      it("Should deploy DNT", async () => {
        if (nASTR !== undefined) {
          console.log("Using already deployed contract at", nASTR.address);
        } else {
          nASTR = await upgrades.deployProxy(
            await ethers.getContractFactory("NASTR"),
            [distr.address]);
          await nASTR.deployed();
        }
        expect(nASTR.address).to.be.not.eq(zeroAddress);
      });

      it("Should deploy LiquidStaking", async () => {
        if (liquidStaking !== undefined) {
          console.log("Using already deployed contract at", liquidStaking.address);
        } else {
          liquidStaking = await upgrades.deployProxy(
            await ethers.getContractFactory("LiquidStaking"),
            [
              consts.dnt, consts.util,
              distr.address, nASTR.address
            ]);
          await liquidStaking.deployed();
        }
        expect(liquidStaking.address).to.be.not.eq(zeroAddress);
      });

    });

    describe("Initial setup", function () {

      it("Should add dnt in distributor", async () => {
        expect(await distr.addDnt(consts.dnt, nASTR.address)).to.satisfy;
      });

      it("Should set util in distributor", async () => {
        expect(await distr.addUtility(consts.util)).to.satisfy;
      });

      it("Should set liquid staking addr in distributor", async () => {
        expect(await distr.setLiquidStaking(liquidStaking.address)).to.satisfy;
      });

      it("Should set dnt as manager in distributor", async () => {
        expect(await distr.addManager(nASTR.address)).to.satisfy;
      });

      it("Should add liquid staking as manager in distributor", async () => {
        expect(await distr.addManager(liquidStaking.address)).to.satisfy;
      });

      it("Should register dApp", async () => {
        await run("registerDapp", { contract: liquidStaking.address });
        await wait(2000);
      });

    });

    describe("Admin functions", function () {

      describe("NDistributor", function () {

        it("Should add manager", async () => {
          expect(
            await distr.connect(signer).addManager(accs[5].address)
          ).to.satisfy;
          expect(
            await distr.connect(signer).addManager(accs[6].address)
          ).to.satisfy;
          expect(distr.connect(accs[1]).addManager(accs[2].address)).to.be.reverted;
        });

        it("Should not add zero manager", () => {
          expect(distr.connect(signer).addManager(zeroAddress)).to.be.reverted;
        })

        it("Should remove manager", async () => {
          expect(distr.connect(accs[1]).removeManager(accs[5].address)).to.be.reverted;
          expect(
              await distr.connect(signer).removeManager(accs[5].address)
          ).to.satisfy;
        });

        it("Should change manager", async () => {
          expect(distr.connect(accs[1]).changeManagerAddress(accs[6].address)).to.be.reverted;
          expect(
            await distr.connect(signer).changeManagerAddress(accs[6].address, accs[9].address)
          ).to.satisfy;
        });

        it("Should add utility to disallow list", async () => {
          expect(distr.connect(accs[1]).addUtilityToDisallowList("TestDisallow")).to.be.reverted;
          expect(
            await distr.connect(accs[9]).addUtilityToDisallowList("TestDisallow")
          ).to.satisfy;
        });

        it("Should add utility", async () => {
          expect(distr.connect(accs[1]).addUtility("TestUtil")).to.be.reverted;
          expect(
            await distr.addUtility("TestUtil")
          ).to.satisfy;
        });

        it("Should not add non-contract as dnt", async () => {
          expect(distr.addDnt(accs[8].address)).to.be.reverted;
        });

        it("Should not change dnt address to non-contract", async () => {
          expect(distr.changeDntAddress("nASTR", accs[9].address)).to.be.reverted;
        });
      });

      describe("NASTR", function () {

        it("Should pause", async () => {
          expect(nASTR.connect(accs[1]).pause()).to.be.reverted;
          expect(
            await nASTR.pause()
          ).to.satisfy;
          await wait(2000);
        });

        it("Should unpause", async () => {
          expect(nASTR.connect(accs[1]).unpause()).to.be.reverted;
          expect(
            await nASTR.unpause()
          ).to.satisfy;
          await wait(2000);
        });
      });

      describe("LiquidStaking", function () {

        // @notice add new partner dapp
        // @param [string] => dapp utility name
        // @param [address] => dapp address
        //function addDapp(string memory _utility, address _dapp) public {  // onyRole

        // @notice activate or deactivate interaction with dapp
        // @param [string] => dapp utility name
        // @param [bool] => state variable
        //function setDappStatus(string memory _utility, bool _state) external {  // onyRole
        it("Should add partner", async () => {
          // @notice add partner address to calc nTokens share for users
          //function addPartner(address _partner) external onlyRole(MANAGER) {
        });

        it("Should set min stake amount", async () => {
          // @notice sets min stake amount
          //function setMinStakeAmount(uint _amount) public onlyRole(MANAGER) {
        })

        it("Should set partners limit", async () => {
          // @notice sets max amount of partners
          //function setPartnersLimit(uint _value) external onlyRole(MANAGER) {
        });

        it("Should remove partner", async () => {
          // @notice removing partner address
          //function removePartner(address _partner) external onlyRole(MANAGER) {
        });

        it("Should sync by hand", async () => {
          // @notice utility function in case of excess gas consumption
          //function sync(uint _era) external onlyRole(MANAGER) {
        });

        it("Should sync & harvest rewards", async () => {
          // @notice utility harvest function
          //function syncHarvest(address _user, string[] memory _utilities) 
        });

        it("Should withdraw revenue", async () => {
          // @notice withdraw revenu function
          //function withdrawRevenue(uint _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        });
      });
    });

    describe("Core functions", function () {

      describe("Staking", function () {

        it("Should stake", async () => {

          let signerRewardsBefore = await liquidStaking.getUserRewards(signer.address);
          let accRewardsBefore = await liquidStaking.getUserRewards(acc.address);

          expect(signerRewardsBefore).to.be.eq(0);
          expect(accRewardsBefore).to.be.eq(0);

          await nextEra();
          console.log('Before staking:');
          await info();

          let tx = await liquidStaking.connect(signer).stake({ value: amount });
          await tx.wait();

          //expect(await liquidStaking.initialize2()).to.satisfy;

          //tx = await liquidStaking.setting();
          //await tx.wait();

          tx = await liquidStaking.connect(acc).stake({ value: amount });
          await tx.wait();

          // signer balance = amount
          // acc balance = amount

          //expect(liquidStaking.stake([consts.unknownUtil], [amount], { value: amount })).to.be.revertedWith("Dapp not active");
          //expect(liquidStaking.stake([consts.util], [0], { value: amount })).to.be.revertedWith("Not enough stake amount");
          //expect(liquidStaking.stake([consts.util], [amount], { value: amount.div(2) })).to.be.revertedWith("Incorrect value");

          console.log('After staking:');
          await info();
          await nextEra();
          
          expect(
              await liquidStaking.setDest(false)
            ).to.satisfy;


          tx = await liquidStaking.sync(await era());
          await tx.wait();


          await run("eraShot", {user: signer.address, 
                        util: consts.util,
                        dnt: consts.dnt});

          await run("eraShot", {user: acc.address, 
                        util: consts.util,
                        dnt: consts.dnt});

          let signerRewardsAfter = await liquidStaking.getUserRewards(signer.address);
          let accRewardsAfter = await liquidStaking.getUserRewards(acc.address);
          let rewardsBefore = await liquidStaking.rewardPool();

          expect(signerRewardsAfter).to.be.eq(0);
          expect(accRewardsAfter).to.be.eq(0);

          await info();
          await nextEra();
          tx = await liquidStaking.sync(await era());
          await tx.wait();

          await run("eraShot", {user: signer.address, 
                        util: consts.util,
                        dnt: consts.dnt});
          await run("eraShot", {user: acc.address, 
                        util: consts.util,
                        dnt: consts.dnt});
          signerRewardsAfter = await liquidStaking.getUserRewards(signer.address);
          accRewardsAfter = await liquidStaking.getUserRewards(acc.address);
          let rewardsAfter = await liquidStaking.rewardPool();
          let eraRewards = rewardsAfter.sub(rewardsBefore);

          await info();

          expect(signerRewardsAfter).not.be.eq(0);
          expect(accRewardsAfter).not.be.eq(0);

          console.log(signerRewardsAfter, accRewardsAfter);
          expect(signerRewardsAfter).to.be.eq(accRewardsAfter);

          rewPerEra = _ofset(eraRewards.div(2));
          expect(signerRewardsAfter).to.be.eq(rewPerEra);
        });

        it("Should transfer received dnt", async () => {
          let tx = await nASTR.transfer(acc.address, amount);
          await expect(() => tx)
            .changeTokenBalances(nASTR, [signer, acc], ['-' + amount.toString(), amount])

          await info();

          expect(await distr.getUserDntBalanceInUtil(acc.address, consts.util, consts.dnt)).to.be.eq(amount.mul(2));
          expect(await distr.getUserDntBalanceInUtil(signer.address, consts.util, consts.dnt)).to.be.eq(0);

          await nextEra();
          tx = await liquidStaking.sync(await era());
          await tx.wait();

          let signerRewardsBefore = await liquidStaking.getUserRewards(signer.address);
          let accRewardsBefore = await liquidStaking.getUserRewards(acc.address);

          await info();
          await nextEra();
          tx = await liquidStaking.sync(await era());
          await tx.wait();

          let signerRewardsAfter = await liquidStaking.getUserRewards(signer.address);
          let accRewardsAfter = await liquidStaking.getUserRewards(acc.address);

          await info();

          console.log(rewPerEra);
          console.log(signerRewardsAfter.sub(signerRewardsBefore));
          expect(signerRewardsAfter.sub(signerRewardsBefore)).to.be.eq(0);
          console.log(accRewardsAfter.sub(accRewardsBefore));
          expect(accRewardsAfter.sub(accRewardsBefore)).to.be.eq(rewPerEra.mul(2));
        });
      });

      describe("Rewards", function () {
        it("harvest test", async function () {
          await nextEra();
          await info();

          let tx = await liquidStaking.sync(await era());
          await tx.wait();

          let previewRewards = await liquidStaking.getUserRewards(acc.address);

          tx = await liquidStaking.syncHarvest(acc.address, [consts.util]);
          await tx.wait();

          let accRewards = await liquidStaking.getUserRewardsFromUtility(acc.address, consts.util);
          console.log(previewRewards, accRewards);
          expect(previewRewards).to.be.eq(accRewards);
        });
        it("claim test", async function () {
          await nextEra();
          let tx = await liquidStaking.sync(await era());
          await tx.wait();
          tx = await liquidStaking.syncHarvest(acc.address, [consts.util]);
          await tx.wait();

          await info();

          let previewRewards = await liquidStaking.getUserRewards(acc.address);
          let toClaim = previewRewards.div(2);

          let accBalanceBefore = await acc.getBalance();
          await info();

          tx = await liquidStaking.connect(acc).claim([consts.util], [toClaim]);
          await expect(() => tx).changeEtherBalance(acc, toClaim);

          await info();

          let accBalanceAfter = await acc.getBalance();
          expect(accBalanceBefore.add(toClaim)).to.be.eq(accBalanceAfter);

          let previewRewardsAfter = await liquidStaking.getUserRewards(acc.address);
          expect(previewRewardsAfter).to.be.eq(previewRewards.sub(toClaim));
        });

        it("claimAll test", async function () {
          await nextEra();
          let tx = await liquidStaking.sync(await era());
          await tx.wait();
          tx = await liquidStaking.syncHarvest(acc.address, [consts.util]);
          await tx.wait();

          await info();

          let previewRewards = await liquidStaking.getUserRewards(acc.address);

          tx = await liquidStaking.connect(acc).claimAll();
          await expect(() => tx).changeEtherBalance(acc, previewRewards);

          await info();

          expect(await liquidStaking.getUserRewards(acc.address)).to.be.eq(0);
        });

        // @notice claim user rewards from utilities
        // @param  [string[]] _utilities => utilities from claim
        // @param  [uint256[]] _amounts => amounts from claim
        //function claim(string[] memory _utilities, uint256[] memory _amounts) 
      });

      describe("Unstaking", function () {

        // @notice unstake tokens from dapps
        // @param  [string[]] _utilities => dapps utilities
        // @param  [uint256[]] _amount => amounts of tokens to unstake
        // @param  [bool] _immediate => receive tokens from unstaking pool, create a withdrawal otherwise
        //function unstake(string[] memory _utilities, uint256[] memory _amounts, bool _immediate) 
      });

      describe("Withdraw", function () {

        // @notice finish previously opened withdrawal
        // @param  [uint] _id => withdrawal index
        //function withdraw(uint _id) external updateAll() {
      });

      describe("Liquid staking", function () {
        //transfer dnt, wait some eras, claim 
      });

    });

    /*
    describe("Adapters", function () {
        it("rewards from dapps tets", async function () {
            await nextEra();
            let tx = await liquidStaking.sync(await era());
            await tx.wait();
            await info();

            let rewardsBefore = await liquidStaking.rewardPool();
            let signerRewards1Before = await liquidStaking.getUserRewards(consts.util, signer.address);
            let signerRewards2Before = await liquidStaking.getUserRewards(consts.util2, signer.address);
            let accRewards1Before = await liquidStaking.getUserRewards(consts.util, acc.address);
            let accRewards2Before = await liquidStaking.getUserRewards(consts.util2, acc.address);

            await nextEra();
            tx = await liquidStaking.sync(await era());
            await tx.wait();
            await info();

            let rewardsAfter = await liquidStaking.rewardPool();
            let signerRewards1After = await liquidStaking.getUserRewards(consts.util, signer.address);
            let signerRewards2After = await liquidStaking.getUserRewards(consts.util2, signer.address);
            let accRewards1After = await liquidStaking.getUserRewards(consts.util, acc.address);
            let accRewards2After = await liquidStaking.getUserRewards(consts.util2, acc.address);

            let eraRewards = rewardsAfter.sub(rewardsBefore);
            let signerRewards1 = signerRewards1After.sub(signerRewards1Before);
            let signerRewards2 = signerRewards2After.sub(signerRewards2Before);
            let accRewards1 = accRewards1After.sub(accRewards1Before);
            let accRewards2 = accRewards2After.sub(accRewards2Before);

            expect(signerRewards1).to.be.eq(accRewards1);
            expect(accRewards2).to.be.eq(0);
            expect(signerRewards1.add(signerRewards2).add(accRewards1).add(accRewards2)).to.be.eq(eraRewards);
            expect(signerRewards2).to.be.eq(signerRewards1);
        });

    });
    */
  });

  describe.skip("SiriusAdapter", function () {
    // users vars
    let deployer: SignerWithAddress,
      user1: SignerWithAddress,
      user2: SignerWithAddress;

    // contracts vars
    let nastr: Contract,
      lp: Contract,
      gauge: Contract,
      srs: Contract,
      pool: Contract,
      farm: Contract,
      minter: Contract,
      adapter: Contract;


    // instances
    let nastrInst: Contract,
      lpInst: Contract,
      gaugeInst: Contract,
      srsInst: Contract,
      poolInst: Contract,
      farmInst: Contract,
      minterInst: Contract,
      adapterInst: Contract;

    // connected users
    let user1Adapter: Contract,
      user1Ntoken: Contract,
      user1SRSToken: Contract,
      user1Farm: Contract,
      user1Minter: Contract;

    let user1Lp: Contract;
    let user1Gauge: Contract;
    let user2Adapter: Contract;
    let user2Ntoken: Contract;
    let user2SRSToken: Contract;
    let user2Farm: Contract;
    let user2Minter: Contract;
    let deployerAdapter: Contract;

    // other vars
    let eth: BigNumber,
      oneHour: Number;

    before(async function () {
      // assign users
      [deployer, user1, user2] = await ethers.getSigners();

      // set vars
      eth = ethers.utils.parseEther("1")
      oneHour = 60 * 60

      // tokens factories
      const NastrFactory = await ethers.getContractFactory("MockERC20");
      const LpFactory = await ethers.getContractFactory("MockERC20");
      const GaugeFactory = await ethers.getContractFactory("MockERC20");
      const SrsFactory = await ethers.getContractFactory("MockERC20");

      // Sirius contracts
      const PoolFactory = await ethers.getContractFactory("MockSiriusPool");
      const FarmFactory = await ethers.getContractFactory("MockSiriusFarm");
      const MinterFactory = await ethers.getContractFactory("MockSiriusMinter");
      const AdapterFactory = await ethers.getContractFactory("SiriusAdapter")

      // deploy contracts
      nastr = await NastrFactory.deploy("nASTR", "nASTR token")
      lp = await LpFactory.deploy("LP", "LP token")
      gauge = await GaugeFactory.deploy("Gauge", "Gauge token")
      srs = await SrsFactory.deploy("SRS", "SRS token")
      pool = await PoolFactory.deploy(lp.address, nastr.address)
      farm = await FarmFactory.deploy(gauge.address, lp.address)
      minter = await MinterFactory.deploy(farm.address, srs.address)
      adapter = await upgrades.deployProxy(AdapterFactory, [pool.address, farm.address, lp.address, nastr.address, gauge.address, srs.address, minter.address])

      // set instances
      nastrInst = nastr;//new ethers.Contract(nastr.address, abiERC20, ethers.provider)
      lpInst = lp;//new ethers.Contract(lp.address, abiERC20, ethers.provider)
      gaugeInst = gauge;//new ethers.Contract(gauge.address, abiERC20, ethers.provider)
      srsInst = srs;//new ethers.Contract(srs.address, abiERC20, ethers.provider)
      poolInst = pool;//new ethers.Contract(pool.address, abiPool, ethers.provider)
      farmInst = farm;//new ethers.Contract(farm.address, abiFarm, ethers.provider)
      minterInst = minter;//new ethers.Contract(minter.address, abiMinter, ethers.provider)
      adapterInst = adapter;//new ethers.Contract(adapter.address, abiAdapter, ethers.provider)

      // connected users
      user1Adapter = adapterInst.connect(user1)
      user1Ntoken = nastrInst.connect(user1)
      user1SRSToken = srsInst.connect(user1)
      user1Farm = farmInst.connect(user1)
      user1Minter = minterInst.connect(user1)
      user1Lp = lpInst.connect(user1)
      user1Gauge = gaugeInst.connect(user1)

      user2Adapter = adapterInst.connect(user1)
      user2Ntoken = nastrInst.connect(user1)
      user2SRSToken = srsInst.connect(user1)
      user2Farm = farmInst.connect(user1)
      user2Minter = minterInst.connect(user1)

      deployerAdapter = adapterInst.connect(deployer)

      // mint tokens to users
      const deployerNastr = new ethers.Contract(nastr.address, abiERC20, deployer)
      await deployerNastr.mint(user1.address, ethers.utils.parseEther("100"))
      await deployerNastr.mint(user2.address, ethers.utils.parseEther("100"))

      // add liquidity to pool
      const deployerLp = new ethers.Contract(lp.address, abiERC20, deployer)
      await deployerLp.mint(pool.address, ethers.utils.parseEther("200"))
    });


    describe("Check that variables have right values", function () {
      it("lp address is nonzero", async function () {
        expect(await adapterInst.lp()).to.equal(lp.address)
      })
      it("pool address is nonzero", async function () {
        expect(await adapterInst.pool()).to.equal(pool.address)
      })
      it("farm address is nonzero", async function () {
        expect(await adapterInst.farm()).to.equal(farm.address)
      })
      it("nToken address is nonzero", async function () {
        expect(await adapterInst.nToken()).to.equal(nastr.address)
      })
      it("gauge address is nonzero", async function () {
        expect(await adapterInst.gauge()).to.equal(gauge.address)
      })
      it("srs address is nonzero", async function () {
        expect(await adapterInst.srs()).to.equal(srs.address)
      })
      it("minter address is nonzero", async function () {
        expect(await adapterInst.minter()).to.equal(minter.address)
      })
    })

    describe("Check balances", async function () {
      it("Balance of user1 should be equal to 100", async function () {
        const contract = new ethers.Contract(nastr.address, abiERC20, ethers.provider)
        expect(await contract.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("100"));
      })

      it("Balance of user2 should be equal to 100", async function () {
        const contract = new ethers.Contract(nastr.address, abiERC20, ethers.provider)
        expect(await contract.balanceOf(user2.address)).to.equal(ethers.utils.parseEther("100"));
      })

      it("Pool LP balance is equal to 200", async function () {
        expect(await lpInst.balanceOf(pool.address)).to.be.equal(ethers.utils.parseEther("200"))
      })
    })

    describe("Testing addLiquidity function", function () {
      it("Adding liquidity with _autoStake = false", async function () {
        const adapterBalanceBefore = await ethers.provider.getBalance(adapter.address)
        const adapterLpBalanceBefore = await lpInst.balanceOf(adapter.address)
        const poolBalanceBefore = await ethers.provider.getBalance(pool.address)

        await user1Ntoken.approve(adapter.address, eth)
        await user1Adapter.addLiquidity([eth, eth], false, { value: eth })

        const adapterBalanceAfter = await ethers.provider.getBalance(adapter.address)
        const adapterLpBalanceAfter = await lpInst.balanceOf(adapter.address)
        const poolBalanceAfter = await ethers.provider.getBalance(pool.address)
        const share = await adapterInst.calc(user1.address)

        expect(adapterBalanceAfter).to.be.equal(adapterBalanceBefore)
        expect(adapterLpBalanceAfter - adapterLpBalanceBefore).to.be.equal(eth.mul(2));
        expect(poolBalanceAfter.sub(poolBalanceBefore)).to.be.equal(eth);
        expect(parseInt(share)).to.be.equal(eth)
      })

      it("Adding liquidity with _autoStake = true", async function () {
        const signerAdapter = adapterInst.connect(user1)
        const signerNtoken = nastrInst.connect(user1)

        await signerNtoken.approve(adapter.address, eth)

        const adapterBalanceBefore = await ethers.provider.getBalance(adapter.address)
        const adapterLpBalanceBefore = await lpInst.balanceOf(adapter.address)
        const poolBalanceBefore = await ethers.provider.getBalance(pool.address)
        const adapterGaugeBalanceBefore = await gaugeInst.balanceOf(adapter.address)

        await signerAdapter.addLiquidity([eth, eth], true, { value: eth })

        const adapterBalanceAfter = await ethers.provider.getBalance(adapter.address)
        const adapterLpBalanceAfter = await lpInst.balanceOf(adapter.address)
        const poolBalanceAfter = await ethers.provider.getBalance(pool.address)
        const adapterGaugeBalanceAfter = await gaugeInst.balanceOf(adapter.address)

        expect(adapterBalanceAfter).to.be.equal(adapterBalanceBefore)
        expect(adapterLpBalanceAfter).to.be.equal(adapterLpBalanceBefore)
        expect(poolBalanceAfter.sub(poolBalanceBefore)).to.be.equal(eth);
        expect(adapterGaugeBalanceAfter.sub(adapterGaugeBalanceBefore)).to.be.equal(eth.mul(2))
      })
    })

    describe("Adding liquidity and receiving rewards for one user", function () {

      it("User1 added liquidity with flag 'true'. User1 gauge bal increased. Total staked increased. Adapter gauge bal increased", async function () {
        const gaugeBalanceBefore = await user1Adapter.gaugeBalances(user1.address)
        await user1Ntoken.approve(adapter.address, eth)
        await user1Adapter.addLiquidity([eth, eth], true, { value: eth })
        const gaugeBalanceAfter = await user1Adapter.gaugeBalances(user1.address)
        expect(gaugeBalanceAfter - gaugeBalanceBefore).to.be.equal(eth.mul(2));
        expect(await user1Adapter.totalStaked()).to.be.gt(0)
        expect(await gaugeInst.balanceOf(adapter.address)).to.be.gt(0)
      })

      it("StartTime for adapter is setted", async function () {
        expect(await farmInst.startTime(adapter.address)).to.be.gt(0)
      })

      it.skip("Check if one hour and one block passed", async function () {
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        //await ethers.provider.send('evm_increaseTime', [oneHour]);
        //await ethers.provider.send('evm_mine');

        const blockNumAfter = await ethers.provider.getBlockNumber();
        const blockAfter = await ethers.provider.getBlock(blockNumAfter);
        const timestampAfter = blockAfter.timestamp;

        expect(blockNumAfter).to.be.equal(blockNumBefore + 1);
        // expect(timestampAfter).to.be.equal(timestampBefore + oneHour);
        expect(timestampAfter - timestampBefore).to.be.gt(60 * 50)
      })

      it("User1 added liq second time with same values. At this time flag 'false'. User1 lp bal inreased, gauge bal the same", async function () {
        const gaugeBalanceBefore = await user1Adapter.gaugeBalances(user1.address)
        const lpBalBefore = await user1Adapter.lpBalances(user1.address)
        await user1Ntoken.approve(adapter.address, eth)
        await user1Adapter.addLiquidity([eth, eth], false, { value: eth })
        const gaugeBalanceAfter = await user1Adapter.gaugeBalances(user1.address)
        const lpBalAfter = await user1Adapter.lpBalances(user1.address)
        expect(gaugeBalanceAfter - gaugeBalanceBefore).to.be.equal(0)
        expect(lpBalAfter - lpBalBefore).to.be.equal(eth.mul(2));
      })

      it("User1 deposit LP. His gauge bal increased. Adapter gauge bal increased", async function () {
        const amountLP = await user1Adapter.lpBalances(user1.address)
        const gaugeBalBefore = await user1Adapter.gaugeBalances(user1.address)
        const adapterGaugeBalBefore = await gaugeInst.balanceOf(adapter.address)
        await user1Adapter.depositLP(amountLP)
        const adapterGaugeBalAfter = await gaugeInst.balanceOf(adapter.address)
        const gaugeBalAfter = await user1Adapter.gaugeBalances(user1.address)
        expect(gaugeBalAfter - gaugeBalBefore).to.be.equal(parseInt(ethers.utils.formatUnits(amountLP, 0)))
        expect(adapterGaugeBalAfter - adapterGaugeBalBefore).to.be.equal(parseInt(ethers.utils.formatUnits(amountLP, 0)))
      })

      it("Amount of rewards for user1 was increased", async function () {
        expect(await user1Adapter.rewards(user1.address)).to.be.gt(0)
      })

      it("User1 has successfully claimed his rewards", async function () {
        const rewardsAmountTotal = await user1Adapter.rewards(user1.address)
        const rewards = rewardsAmountTotal - rewardsAmountTotal * 0.1
        const srsBalBefore = await srsInst.balanceOf(user1.address)
        await user1Adapter.claim()
        const srsBalAfter = await srsInst.balanceOf(user1.address)
        expect(srsBalAfter - srsBalBefore).to.be.equal(rewards)
      })
    })

    describe("Check if the founded after audit issue QSP-1 was solved", function () {
      it("User1 added liquidity with flag 'true", async function () {
        await user1Ntoken.approve(adapter.address, eth)
        await user1Adapter.addLiquidity([eth, eth], true, { value: eth })
      })

      it.skip("Check if one hour and one block passed", async function () {
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        //await ethers.provider.send('evm_increaseTime', [oneHour]);
        //await ethers.provider.send('evm_mine');

        const blockNumAfter = await ethers.provider.getBlockNumber();
        const blockAfter = await ethers.provider.getBlock(blockNumAfter);
        const timestampAfter = blockAfter.timestamp;

        expect(blockNumAfter).to.be.equal(blockNumBefore + 1);
        // expect(timestampAfter).to.be.equal(timestampBefore + oneHour);
        expect(timestampAfter - timestampBefore).to.be.gt(60 * 50)
      })

      it("User2 added liquidity with flag 'true", async function () {
        await user2Ntoken.approve(adapter.address, eth)
        await user2Adapter.addLiquidity([eth, eth], true, { value: eth })
      })

      it("User1 has claimed his rewards. His srs balance was increased", async function () {
        const rewardsAmountTotal = await user1Adapter.rewards(user1.address)
        const rewards = rewardsAmountTotal - rewardsAmountTotal * 0.1
        const srsBalBefore = await srsInst.balanceOf(user1.address)
        await user1Adapter.claim()
        const srsBalAfter = await srsInst.balanceOf(user1.address)
        expect(srsBalAfter.sub(srsBalBefore)).to.be.equal(rewards)
      })

      it.skip("Check if one hour and one block passed", async function () {
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        //await ethers.provider.send('evm_increaseTime', [oneHour]);
        //await ethers.provider.send('evm_mine');

        const blockNumAfter = await ethers.provider.getBlockNumber();
        const blockAfter = await ethers.provider.getBlock(blockNumAfter);
        const timestampAfter = blockAfter.timestamp;

        expect(blockNumAfter).to.be.equal(blockNumBefore + 1);
        // expect(timestampAfter).to.be.equal(timestampBefore + oneHour);
        expect(timestampAfter - timestampBefore).to.be.gt(60 * 50)
      })

      it("User2 has claimed his rewards. His srs balance was increased", async function () {
        const rewardsAmountTotal = await user2Adapter.rewards(user2.address)
        const rewards = rewardsAmountTotal - rewardsAmountTotal * 0.1
        const srsBalBefore = await srsInst.balanceOf(user2.address)
        await user1Adapter.claim()
        const srsBalAfter = await srsInst.balanceOf(user2.address)
        expect(srsBalAfter.sub(srsBalBefore)).to.be.equal(rewards)
      })
    })

    describe("Removing liquidity", function () {

      it("User1 added liquidity with flag 'true'. User1 gauge bal increased. Total staked increased. Adapter gauge bal increased", async function () {
        const gaugeBalanceBefore = await user1Adapter.gaugeBalances(user1.address)
        await user1Ntoken.approve(adapter.address, eth)
        await user1Adapter.addLiquidity([eth, eth], true, { value: eth })
        const gaugeBalanceAfter = await user1Adapter.gaugeBalances(user1.address)
        expect(gaugeBalanceAfter.sub(gaugeBalanceBefore)).to.be.equal(eth.mul(2))
        expect(await user1Adapter.totalStaked()).to.be.gt(0)
        expect(await gaugeInst.balanceOf(adapter.address)).to.be.gt(0)
      })

      it("Withdraw LP tokens without removing liquidity", async function () {
        const adapterLPbalBefore = await lpInst.balanceOf(adapter.address)
        await user1Adapter.withdrawLP(eth, false)
        const adapterLPbalAfter = await lpInst.balanceOf(adapter.address)
        expect(adapterLPbalAfter.sub(adapterLPbalBefore)).to.be.equal(eth)
      })

      it("Adapter LP bal == user1 LP bal", async function () {
        expect(await lpInst.balanceOf(adapter.address)).to.be.equal(await adapterInst.lpBalances(user1.address))
      })

      it("Remove liquidity after withdraw LP", async function () {
        const lpBalance = await adapterInst.lpBalances(user1.address)
        const nastrBalanceBefore = await nastrInst.balanceOf(user1.address)
        const astrBalanceBefore = await ethers.provider.getBalance(user1.address)
        const amounts = await adapterInst.calculateRemoveLiquidity(lpBalance)
        await user1Adapter.removeLiquidity(lpBalance)
        const nastrBalanceAfter = await nastrInst.balanceOf(user1.address)
        const astrBalanceAfter = await ethers.provider.getBalance(user1.address)
        expect(nastrBalanceAfter.sub(nastrBalanceBefore)).to.be.equal(amounts[1])
        expect(astrBalanceAfter.sub(astrBalanceBefore)).to.be.gt(amounts[0] * 0.999);
      })
    })

    describe("Withdraw revenue", function () {
      it("Add liquidity", async function () {
        const gaugeBalanceBefore = await user1Adapter.gaugeBalances(user1.address)
        await user1Ntoken.approve(adapter.address, eth)
        await user1Adapter.addLiquidity([eth, eth], false, { value: eth })
        const gaugeBalanceAfter = await user1Adapter.gaugeBalances(user1.address)
      })

      it.skip("One hour later", async function () {
        //await ethers.provider.send('evm_increaseTime', [oneHour]);
        //await ethers.provider.send('evm_mine');
      })

      it("Add liquidity and deposit LP by user1 - second", async function () {
        const gaugeBalanceBefore = await user1Adapter.gaugeBalances(user1.address)
        await user1Ntoken.approve(adapter.address, eth)
        await user1Adapter.addLiquidity([eth, eth], true, { value: eth })
        const gaugeBalanceAfter = await user1Adapter.gaugeBalances(user1.address)
        expect(gaugeBalanceAfter.sub(gaugeBalanceBefore)).to.be.equal(eth.mul(2));
        expect(await user1Adapter.totalStaked()).to.be.gt(0)
        expect(await gaugeInst.balanceOf(adapter.address)).to.be.gt(0)
      })

      it("Claim rewards by user1", async function () {
        const rewardsAmountTotal = await user1Adapter.rewards(user1.address)
        const rewards = rewardsAmountTotal - rewardsAmountTotal * 0.1
        const srsBalBefore = await srsInst.balanceOf(user1.address)
        expect(await adapterInst.pendingRewards(user1.address)).to.be.gt(0)
        await user1Adapter.claim()
        const srsBalAfter = await srsInst.balanceOf(user1.address)
        expect(srsBalAfter.sub(srsBalBefore)).to.be.equal(rewards)
      })

      it("Withdraw revenue by owner", async function () {
        const revenueTotal = await adapterInst.revenuePool();
        const srsBalanceBefore = await srsInst.balanceOf(deployer.address)
        await deployerAdapter.withdrawRevenue(revenueTotal)
        const srsBalanceAfter = await srsInst.balanceOf(deployer.address)
        expect(srsBalanceAfter.sub(srsBalanceBefore)).to.be.equal(revenueTotal)
      })
    })

    describe("setAbilityToAddLpAndGauge", async function () {
      it("Switch", async function () {
        const previousValue = await adapterInst.abilityToAddLpAndGauge()
        await deployerAdapter.setAbilityToAddLpAndGauge(!previousValue)
        expect(await adapterInst.abilityToAddLpAndGauge()).not.to.be.equal(previousValue)
      })
    })

    describe("Adding LP and Gauge tokens by user", function () {
      it("Mint LP and Gauge to user", async function () {
        const lpBalBefore = await lpInst.balanceOf(user1.address)
        const gaugeBalBefore = await gaugeInst.balanceOf(user1.address)
        await user1Lp.mint(user1.address, eth)
        await user1Gauge.mint(user1.address, eth)
        const lpBalAfter = await lpInst.balanceOf(user1.address)
        const gaugeBalAfter = await gaugeInst.balanceOf(user1.address)
        expect(lpBalAfter.sub(lpBalBefore)).to.be.equal(eth)
        expect(gaugeBalAfter.sub(gaugeBalBefore)).to.be.equal(eth)
      })

      it("Add LP with autodeposit", async function () {
        const notDisabled = await adapterInst.abilityToAddLpAndGauge()
        if (!notDisabled) {
          const tx = await deployerAdapter.setAbilityToAddLpAndGauge(true)
        }
        const gaugeBalBefore = await adapterInst.gaugeBalances(user1.address)
        const lpAmount = await lpInst.balanceOf(user1.address)
        await user1Lp.approve(adapter.address, lpAmount)
        await user1Adapter.addLp(lpAmount, true)
        const gaugeBalAfter = await adapterInst.gaugeBalances(user1.address)
        expect(gaugeBalAfter.sub(gaugeBalBefore)).to.be.equal(lpAmount)
      })

      it("Add Gauge", async function () {
        const gaugeBefore = await adapterInst.gaugeBalances(user1.address)
        const gaugeAmount = await gaugeInst.balanceOf(user1.address)
        await user1Gauge.approve(adapter.address, gaugeAmount)
        await user1Adapter.addGauge(gaugeAmount)
        const gaugeAfter = await adapterInst.gaugeBalances(user1.address)
        expect(gaugeAfter.sub(gaugeBefore)).to.be.gt(0)
        expect(gaugeAfter.sub(gaugeBefore)).to.be.equal(gaugeAmount)
      })
    })


    describe("Try to renounce ownership", function () {
      it("Attempt", async function () {
        await expect(deployerAdapter.renounceOwnership()).to.be.revertedWith("It is not possible to renounce ownership")
      })
    })

  });
});
