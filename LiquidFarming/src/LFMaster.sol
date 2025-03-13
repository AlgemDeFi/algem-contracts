//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "src/interfaces/LF/ILFPool.sol";

library ByteConversion {
    function toString(bytes3 self) internal pure returns (string memory output) {
        bytes6 result = (bytes6(self) & 0xFFF000000000) | ((bytes6(self) & 0x000FFF000000) >> 12);
        result = (result & 0xFF0000FF0000) | ((result & 0x00F00000F000) >> 8);
        result = (result & 0xF000F0F000F0) | ((result & 0x0F00000F0000) >> 4);
        result = (result & 0xF0F0F0F0F0F0) >> 4;
        result =
            bytes6(0x303030303030 + uint48(result) + (((uint48(result) + 0x060606060606) >> 4) & 0x0F0F0F0F0F0F) * 7);

        output = string(abi.encodePacked(result));
    }
}

/// @title Liquid Farming Master contract
/// @notice This contract acts as a main source of truth
///         for protocol contracts
/// @custom:oz-upgrades-from LFMaster
contract LFMaster is OwnableUpgradeable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using ByteConversion for bytes3;

    struct Pool {
        address addr;
        uint256 totalAlloc;
        uint256 totalPaid;
        uint256 roundSupply;
        uint256 roundDistributed;
        uint256 deadline;
        string dappName;
        string pairName;
    }

    struct NFTSlot {
        address nft;
        uint256 id;
    }

    struct poolData {
        address poolAddr;
        string pairName;
        string chainName;
        string dappName;
        uint256 APR;
        uint256 liquidity;
    }

    struct userPoolData {
        address poolAddr;
        string dappName;
        string pairName;
        uint256 liquidity;
    }

    struct userReferralInfo {
        string referralCode;
        address referrer;
    }

    uint256 public START;
    uint256 public round;

    uint256 public totalBalance;
    uint256 public withdrawable;

    uint256 public poolCount;
    string public chain;

    IERC20 public ALGM;

    Pool[] public pools;

    mapping(address => uint256) public nftBonus;
    mapping(address => NFTSlot) public userSlots;
    mapping(address => uint256) public poolID;

    mapping(address => bool) public isRefUsedByAddress;
    mapping(string => address) public refToOwner;
    mapping(address => string) public addrToUsedRef;
    mapping(address => string) public ownerToRef;

    /// @notice User is already a referrer
    error AlreadyReferrer();

    /// @notice Referral codes have already been used by user
    error RefAlreadyUsed();

    /// @notice Not allowed to use own refcode
    error OwnRefcode();

    /// @notice Refcode does not exist
    error InvalidRefCode();

    event BecomeReferrer(address indexed user, string indexed refCode);
    event BecomeReferral(address indexed referrer, address referral);

    event LiquidStakingBonusSet(uint256 bonus);

    event NFTLocked(address indexed user, address indexed nft, uint256 id);
    event NFTUnlocked(address indexed user, address indexed nft, uint256 id);
    event NFTBonusSet(address indexed nft, uint256 bonus);

    event AddALGM(uint256 id, address indexed pool, uint256 added, uint256 roundSupply);
    event PoolAdded(address pool, string dapp, string pair);
    event PoolRemoved(address pool, uint256 ALGMReturned);
    event PoolDeadlineSet(uint256 id, address indexed pool, uint256 deadline);
    event Harvest(uint256 id, address indexed pool, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    ////INIT FUNCTIONS////
    /// @param _algm token address
    /// @param _chain name of chain deployed to
    function initialize(address _algm, string memory _chain) external initializer {
        __Ownable_init(msg.sender);
        ALGM = IERC20(_algm);
        chain = _chain;
    }

    /// @notice set round parameters for ALGM distribution
    /// @param _start timestamp
    /// @param _round duration
    function setRound(uint256 _start, uint256 _round) external onlyOwner {
        require(START == 0);
        require(_round > 0);
        require(_start >= block.timestamp);
        round = _round;
        START = _start;
    }

    ////ADMIN FUNCTIONS////
    //**ALGM DISTRIBUTION**//
    /// @notice allocate ALGM for pair
    /// @param _pid pool id
    /// @param _amount of tokens to alloc
    function addALGM(uint256 _pid, uint256 _amount) external onlyOwner {
        Pool storage p = pools[_pid];
        require(p.deadline > getCurrentRound(), "Invalid deadline!");
        ALGM.safeTransferFrom(msg.sender, address(this), _amount);
        p.totalAlloc += _amount;
        p.roundSupply += _amount / (p.deadline - getCurrentRound());

        emit AddALGM(_pid, p.addr, _amount, p.roundSupply);
    }

    /// @notice distribute algm rewards
    function harvest() external {
        Pool storage p = pools[poolID[msg.sender]];
        require(p.addr == msg.sender, "Only for pool");
        uint256 cr = getCurrentRound();
        if (p.roundDistributed >= cr) return;
        if (cr > p.deadline) return;
        uint256 amount = p.roundSupply * (cr - p.roundDistributed);
        p.totalPaid += amount;
        ALGM.safeIncreaseAllowance(msg.sender, amount);
        p.roundDistributed = cr;
        ILFPool(msg.sender).addALGM(amount);

        emit Harvest(poolID[msg.sender], msg.sender, amount);
    }

    //**POOL MANAGEMENT**//
    /// @notice set pair deadline
    /// @param _pid pool id
    /// @param _deadline deadline round
    function setPoolDeadline(uint256 _pid, uint256 _deadline) external onlyOwner {
        Pool storage p = pools[_pid];
        require(_deadline > getCurrentRound(), "Invalid deadline!");
        p.roundSupply = (p.totalAlloc - p.totalPaid) / (_deadline - p.roundDistributed);
        p.deadline = _deadline;

        emit PoolDeadlineSet(_pid, p.addr, _deadline);
    }

    /// @notice add pool
    /// @param _pool to add
    /// @param _dapp name
    /// @param _pair name
    function addPool(
        address _pool,
        uint256 _deadline,
        string calldata _dapp,
        string calldata _pair
    )
        external
        onlyOwner
    {
        require(_pool != address(0), "Invalid address!");
        require(poolID[_pool] == 0 && (poolCount == 0 || pools[0].addr != _pool), "Pool already added!");
        require(keccak256(bytes(_dapp)) != keccak256(""), "Invalid dApp name!");
        require(keccak256(bytes(_pair)) != keccak256(""), "Invalid pair name!");
        pools.push();
        Pool storage p = pools[poolCount];
        p.addr = _pool;
        p.dappName = _dapp;
        p.pairName = _pair;
        p.deadline = _deadline;
        p.roundDistributed = getCurrentRound();

        poolID[_pool] = poolCount;
        ++poolCount;

        emit PoolAdded(_pool, _dapp, _pair);
    }

    /// @notice remove pool and retrieve unpaid ALGMs
    /// @param _id pool id
    function removePool(uint256 _id) external onlyOwner {
        Pool memory p = pools[_id];
        require(p.addr != address(0), "Does not exist!");
        require(getCurrentRound() > p.deadline);
        require(_id < poolCount, "Invalid pool ID");
        uint256 unpaidAlloc = p.totalAlloc - p.totalPaid;
        if (unpaidAlloc > 0) {
            ALGM.safeTransfer(msg.sender, unpaidAlloc);
        }

        poolID[p.addr] = type(uint256).max;
        pools[_id] = pools[poolCount - 1];
        poolID[pools[_id].addr] = _id;
        pools.pop();
        --poolCount;

        emit PoolRemoved(p.addr, unpaidAlloc);
    }

    //**NFT LOCK MANAGEMENT**//
    /// @notice set parameters of nft
    /// @param _nft address
    /// @param _bonus ALGM APR
    function setNFT(address _nft, uint256 _bonus) external onlyOwner {
        require(_nft != address(0), "Invalid NFT address");
        nftBonus[_nft] = _bonus;
        emit NFTBonusSet(_nft, _bonus);
    }

    ////INTERNAL FUNCTIONS////

    ////REFERRAL FUNCTIONS////
    /// @notice To become a referrer
    /// @return ref Referral codesrc/LiquidCrowdloan.sol
    function becomeReferrer() external returns (string memory ref) {
        address user = msg.sender;

        if (bytes(ownerToRef[user]).length != 0) {
            revert AlreadyReferrer();
        }

        bytes3 data = bytes3(keccak256(abi.encode(user, block.timestamp)));
        ref = data.toString();

        refToOwner[ref] = user;
        ownerToRef[msg.sender] = ref;

        emit BecomeReferrer(msg.sender, ref);
    }

    /// @notice To become a referral
    /// @param _ref referral code
    function becomeReferral(string memory _ref) external {
        address user = msg.sender;
        if (bytes(_ref).length != 0) {
            if (refToOwner[_ref] == address(0)) revert InvalidRefCode();
            if (isRefUsedByAddress[user]) revert RefAlreadyUsed();
            if (user == refToOwner[_ref]) revert OwnRefcode();

            isRefUsedByAddress[user] = true;
            addrToUsedRef[user] = _ref;

            emit BecomeReferral(user, refToOwner[_ref]);
        }
    }

    ////NFT LOCK FUNCTIONS////
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice locks user's NFT to provide ALGM APR bonus
    /// @param _nft address
    /// @param _id NFT ID
    function lockNFT(address _nft, uint256 _id) external {
        require(userSlots[msg.sender].nft == address(0), "Already locked!");

        userSlots[msg.sender] = NFTSlot({nft: _nft, id: _id});

        IERC721(_nft).safeTransferFrom(msg.sender, address(this), _id);
        emit NFTLocked(msg.sender, _nft, _id);
    }

    /// @notice retreive locked NFT
    /// @param _nft address
    function unlockNFT(address _nft) external {
        require(userSlots[msg.sender].nft == _nft, "NFT not locked or wrong addr!");

        uint256 id = userSlots[msg.sender].id;
        userSlots[msg.sender].nft = address(0);
        userSlots[msg.sender].id = 0;

        IERC721(_nft).safeTransferFrom(address(this), msg.sender, id);
        emit NFTUnlocked(msg.sender, _nft, id);
    }

    ////VIEW FUNCTIONS////

    /// @notice returns the current round without top limit
    function getCurrentRound() public view returns (uint256) {
        if (block.timestamp <= START) return 0;
        else return (block.timestamp - START) / round;
    }

    /// @notice get data on registered pools
    /// @return pools_ coposed data on each pool
    function getPools() external view returns (poolData[] memory pools_) {
        pools_ = new poolData[](poolCount);
        for (uint256 i; i < poolCount;) {
            Pool memory p = pools[i];
            pools_[i].poolAddr = p.addr;
            pools_[i].pairName = p.pairName;
            pools_[i].chainName = chain;
            pools_[i].dappName = p.dappName;
            pools_[i].liquidity = ILFPool(p.addr).totalBalance();
            unchecked {
                ++i;
            }
        }
    }

    /// @notice find out which pools user has balances in
    /// @param _user to gather info on
    /// @return pools_ addresses
    function getUserPools(address _user) external view returns (userPoolData[] memory pools_) {
        require(_user != address(0), "Invalid address!");
        uint256 k = poolCount;
        pools_ = new userPoolData[](k);
        for (uint256 i; i < poolCount;) {
            Pool memory p = pools[i];
            uint256 pb = ILFPool(p.addr).balances(_user);
            if (pb > 0) {
                k--;
                pools_[i].poolAddr = p.addr;
                pools_[i].dappName = p.dappName;
                pools_[i].pairName = p.pairName;
                pools_[i].liquidity = pb;
            }
            unchecked {
                ++i;
            }
        }
        // shrink array 0 values
        assembly {
            mstore(pools_, sub(mload(pools_), k))
        }
    }

    /// @notice get composed info on user referrals
    /// @param _user address to look for
    /// @return uri_ user referral info
    function getUserReferralInfo(address _user) external view returns (userReferralInfo memory uri_) {
        uri_.referralCode = ownerToRef[_user];
        uri_.referrer = refToOwner[addrToUsedRef[_user]];
    }

    /// @notice get total ALGM APR for user
    /// @param _user to calculate APR
    /// @return bonus_ calculated
    function getUserBonus(address _user) external view returns (uint256 bonus_) {
        bonus_ = 100;
        bonus_ += nftBonus[userSlots[_user].nft];
        /// @dev add LS bonus check when conditions decided
    }
}
