pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "src/LFMaster.sol";
import "src/LWRAPPED.sol";
import "script/Workbench.s.sol";

contract MockLFPool {
    LFMaster public master;
    LWRAPPED public algm;

    constructor(address _master, address _algm) {
        master = LFMaster(_master);
        algm = LWRAPPED(_algm);
    }

    function addALGM(uint256 _amount) public {
        algm.transferFrom(msg.sender, address(this), _amount);
    }

    function harvest() public {
        master.harvest();
    }
}

contract MockNFT is ERC721Enumerable {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint() external returns (uint256 id) {
        id = totalSupply();
        _safeMint(msg.sender, totalSupply());
    }
}

contract LFMasterTest is Test, Workbench, IERC721Receiver {
    LFMaster master;
    LWRAPPED algm;
    MockLFPool pool;
    MockNFT nft;

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        algm = new LWRAPPED("Algem Token", "ALGM");
        lfcfg.algm = address(algm);
        nft = new MockNFT();

        address m = Upgrades.deployTransparentProxy(
            "LFMaster.sol:LFMaster", address(this), abi.encodeCall(LFMaster.initialize, (lfcfg.algm, "Testnet"))
        );
        lfcfg.master = m;
        master = LFMaster(m);

        pool = new MockLFPool(m, address(algm));
    }

    // ROUNDS
    function testRoundManagement() public {
        master.setRound(block.timestamp + 5, 3600);
        assertEq(master.START(), block.timestamp + 5);
        assertEq(master.round(), 3600);

        vm.expectRevert();
        master.setRound(969_696, 6300);

        vm.warp(master.START());
        assertEq(master.getCurrentRound(), 0);
        vm.warp(block.timestamp + master.round());
        assertEq(master.getCurrentRound(), 1);
        vm.warp(block.timestamp + master.round());
        assertEq(master.getCurrentRound(), 2);
        vm.warp(block.timestamp + master.round());
        assertEq(master.getCurrentRound(), 3);
    }

    // POOLS
    function testPoolManagement() public {
        master.setRound(block.timestamp + 5, 3600);
        vm.warp(master.START());
        master.addPool(address(pool), 20, "somedApp", "somePair");

        vm.expectRevert();
        master.addPool(address(pool), 20, "somedApp", "somePair");

        (address addr,,,, uint256 roundDistributed, uint256 deadline,,) = master.pools(0);
        assertEq(addr, address(pool));
        assertEq(roundDistributed, master.getCurrentRound());
        assertEq(deadline, 20);

        vm.expectRevert();
        master.removePool(0);

        vm.warp(block.timestamp + master.round() * (deadline + 1));
        master.removePool(0);

        vm.expectRevert();
        master.pools(0);
    }

    // ALGM
    function testALGMDistribution() public {
        uint256 someAmount = 2000 ether;
        master.setRound(block.timestamp + 5, 3600);
        vm.warp(master.START());

        master.addPool(address(pool), 50, "dApp", "Pair");

        algm.mint(address(this), someAmount);
        algm.approve(address(master), someAmount);
        master.addALGM(0, someAmount);

        (, uint256 totalAlloc, uint256 totalPaid, uint256 roundSupply,,,,) = master.pools(0);
        assertEq(totalAlloc, someAmount);
        assertEq(totalPaid, 0);
        assertEq(roundSupply, someAmount / 50);

        pool.harvest();
        (,, totalPaid,,,,,) = master.pools(0);
        assertEq(totalPaid, roundSupply * 0);
        assertEq(totalPaid, algm.balanceOf(address(pool)));
        vm.warp(block.timestamp + master.round());

        pool.harvest();
        (,, totalPaid,,,,,) = master.pools(0);
        assertEq(totalPaid, roundSupply * 1);
        assertEq(totalPaid, algm.balanceOf(address(pool)));
        vm.warp(block.timestamp + master.round());

        pool.harvest();
        (,, totalPaid,,,,,) = master.pools(0);
        assertEq(totalPaid, roundSupply * 2);
        assertEq(totalPaid, algm.balanceOf(address(pool)));
        vm.warp(block.timestamp + master.round());

        pool.harvest();
        (,, totalPaid,,,,,) = master.pools(0);
        assertEq(totalPaid, roundSupply * 3);
        assertEq(totalPaid, algm.balanceOf(address(pool)));
        vm.warp(block.timestamp + master.round());
    }
    // NFT

    function testNFTLock() public {
        master.setNFT(address(nft), 5);

        uint256 id = nft.mint();
        nft.approve(address(master), id);
        master.lockNFT(address(nft), id);

        (address lockedNFT, uint256 lockedId) = master.userSlots(address(this));
        assertEq(lockedNFT, address(nft));
        assertEq(lockedId, id);

        uint256 userBonus = master.getUserBonus(address(this));
        assertEq(userBonus, 105);

        master.unlockNFT(address(nft));
        (lockedNFT, lockedId) = master.userSlots(address(this));
        assertEq(lockedNFT, address(0));
        assertEq(lockedId, 0);
    }

    function testSetAndGetNFTBonus() public {
        master.setNFT(address(nft), 10);
        assertEq(master.nftBonus(address(nft)), 10);
    }
    // REFERRALS

    function testReferrals() public {
        string memory ref = master.becomeReferrer();
        assertEq(keccak256(abi.encodePacked(master.ownerToRef(address(this)))), keccak256(abi.encodePacked(ref)));

        address referrer = address(this);
        vm.expectRevert();
        master.becomeReferral(ref);
        vm.startPrank(address(0x1234));
        master.becomeReferral(ref);
        assertEq(master.isRefUsedByAddress(address(0x1234)), true);
        assertEq(keccak256(abi.encodePacked(master.addrToUsedRef(address(0x1234)))), keccak256(abi.encodePacked(ref)));
        vm.expectRevert();
        master.becomeReferral(ref);
        vm.stopPrank();

        vm.expectRevert();
        master.becomeReferral("invalidcode");
    }
}
