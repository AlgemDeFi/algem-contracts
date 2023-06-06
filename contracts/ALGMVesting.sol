// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract ALGMVesting is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    IERC20Upgradeable public token;

    bytes32 public constant MANAGER = keccak256("MANAGER");
    uint256 public vestingsTotalAmount;

    mapping(address => uint256) public managerIds;
    mapping(bytes32 => Vesting) private vestings;
    mapping(address => uint256) public holdersVestingCount;

    address[] public managers;
    bytes32[] private vestingIds;

    struct Vesting {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriod;
        bool revocable;
        uint256 amountTotal;
        uint256 released;
        bool revoked;
    }

    event AddManager(address indexed who, address indexed newManager);
    event RevokeManager(address indexed who, address indexed deletedManager);
    event CreateVesting(address indexed who, address indexed beneficiary, bytes32 indexed vestingId);
    event Claim(address indexed who, bytes32 indexed vestingId, uint256 indexed amount);
    event RevokeVesting(address indexed who, bytes32 indexed vestingId);

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(IERC20Upgradeable _token) public initializer {
        _grantRole(MANAGER, msg.sender);
        token = _token;
    }

    modifier onlyIfVestingNotRevoked(bytes32 vestingId) {
        require(vestings[vestingId].initialized == true);
        require(vestings[vestingId].revoked == false);
        _;
    }

    /* to remove ❗️ */ receive() external payable {}

    // @notice Add new manager
    // @param _manager Manager address
    function addManager(address _manager) public onlyRole(MANAGER) {
        require(!hasRole(MANAGER, _manager), "Allready manager");
        require(_manager != address(0), "Cannot be zero address");
        managerIds[_manager] = managers.length;
        managers.push(_manager);
        _grantRole(MANAGER, _manager);

        emit AddManager(msg.sender, _manager);
    }

    // @notice Revoke manager
    // @param _manager Manager address
    function revokeManager(address _manager) public onlyRole(MANAGER) {
        require(hasRole(MANAGER, _manager), "Is not a manager");
        require(msg.sender != _manager, "Can't revoke a role from yourself");
        uint256 id = managerIds[_manager];
        managers[id] = managers[managers.length - 1];
        managerIds[managers[managers.length - 1]] = id;
        managers.pop();
        managerIds[_manager] = 0;
        _revokeRole(MANAGER, _manager);

        emit RevokeManager(msg.sender, _manager);
    }

    //@notion Creates a new vesting by manager for beneficiary
    //@param _beneficiary token recepient address
    //@param _cliff delay in seconds before first unlock
    //@param _startTime start time of the vesting period
    //@param _duration Duration of vesting
    //@param _slicePeriod duration of a slice period for the vesting in seconds
    //@param _revocable whether the vesting is revocable or not
    //@param _amount total amount of tokens to distribute
    function createVesting(
        address _beneficiary,
        uint256 _cliff,
        uint256 _startTime,
        uint256 _duration,
        uint256 _slicePeriod,
        bool _revocable,
        uint256 _amount
    ) external onlyRole(MANAGER) {
        require(
            getWithdrawableAmount() >= _amount,
            "Cannot create vesting schedule because not sufficient tokens"
        );
        require(_duration > 0, "Duration must be > 0");
        require(_amount > 0, "Amount must be > 0");
        require(_beneficiary != address(0), "Beneficiary must be non-zero address");
        require(_slicePeriod > 0, "Slice period must be > 0");

        bytes32 vestingId = computeNextVestingIdForHolder(_beneficiary);
        uint256 cliff = _startTime + _cliff;

        vestings[vestingId] = Vesting(
            true,
            _beneficiary,
            cliff,
            _startTime,
            _duration,
            _slicePeriod,
            _revocable,
            _amount,
            0,
            false
        );

        vestingsTotalAmount += _amount;
        vestingIds.push(vestingId);
        holdersVestingCount[_beneficiary] += 1;

        emit CreateVesting(msg.sender, _beneficiary, vestingId);
    }

    // @notice Claim vested tokens by beneficiary
    // @param _vestingId Vesting index
    // @param _amount Amount of tokens
    function claim(
        bytes32 _vestingId,
        uint256 _amount
    ) public nonReentrant onlyIfVestingNotRevoked(_vestingId) {
        Vesting storage vesting = vestings[_vestingId];
        require(
            msg.sender == vesting.beneficiary || hasRole(MANAGER, msg.sender),
            "Only beneficiary and manager can release vested tokens"
        );

        uint256 vestedAmount = _computeReleasableAmount(vesting);
        require(vestedAmount >= _amount, "Not enough vested tokens");
        vesting.released += _amount;
        vestingsTotalAmount -= _amount;
        
        token.transfer(vesting.beneficiary, _amount);

        emit Claim(msg.sender, _vestingId, _amount);
    }

    // @notice Allows manager to revoke vesting
    //         if the vesting can be revoked
    // @param _vestingId Vesting index
    function revokeVesting(
        bytes32 _vestingId
    ) external onlyRole(MANAGER) onlyIfVestingNotRevoked(_vestingId) {
        Vesting storage vesting = vestings[_vestingId];
        require(vesting.revocable == true, "Vesting is not revocable");
        uint256 vestedAmount = _computeReleasableAmount(vesting);
        if (vestedAmount > 0) {
            claim(_vestingId, vestedAmount);
        }
        uint256 unreleased = vesting.amountTotal - vesting.released;
        vestingsTotalAmount -= unreleased;
        vesting.revoked = true;

        emit RevokeVesting(msg.sender, _vestingId);
    }

    // @notice Computes the vested amount of tokens for the given vesting schedule identifier.
    // @return Vested amount
    function computeReleasableAmount(
        bytes32 _vestingId
    ) public view onlyIfVestingNotRevoked(_vestingId) returns (uint256) {
        Vesting memory vesting = vestings[_vestingId];
        return _computeReleasableAmount(vesting);
    }

    function _computeReleasableAmount(
        Vesting memory vesting
    ) public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if ((currentTime < vesting.cliff) || vesting.revoked == true) {
            return 0;
        } else if (currentTime >= vesting.start + vesting.duration) {
            return vesting.amountTotal - vesting.released;
        } else {
            uint256 timeFromStart = currentTime - vesting.start;
            uint256 secondsPerSlice = vesting.slicePeriod;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            uint256 vestedAmount = (vesting.amountTotal *
                vestedSeconds) / vesting.duration;
            vestedAmount = vestedAmount - vesting.released;
            return vestedAmount;
        }
    }

    // @notice Get withdrawable amount
    function getWithdrawableAmount()
        public
        view
        returns(uint256){
        return token.balanceOf(address(this)) - vestingsTotalAmount;
    }

    // @notice Returns the next vesting ID for a given holder address
    function computeNextVestingIdForHolder(address holder)
        public
        view
        returns(bytes32){
        return computeVestingIdForAddressAndIndex(holder, holdersVestingCount[holder]);
    }

    // @notice Returns the last vesting schedule for a given holder address
    function getLastVestingScheduleForHolder(address holder)
        public
        view
        returns(Vesting memory){
        return vestings[computeVestingIdForAddressAndIndex(holder, holdersVestingCount[holder] - 1)];
    }

    // @notice Computes the vesting schedule ID for an address and an index
    function computeVestingIdForAddressAndIndex(address holder, uint256 index)
        public
        pure
        returns(bytes32){
        return keccak256(abi.encodePacked(holder, index));
    }

    // @notice Returns the number of vesting schedules managed by this contract
    // @return The number of vesting schedules
    function getVestingSchedulesCount()
        public
        view
        returns(uint256){
        return vestingIds.length;
    }

    // @notice Returns the vesting schedule information for a given holder and index
    // @return The vesting schedule structure information
    function getVestingByAddressAndIndex(address holder, uint256 index)
    external
    view
    returns(Vesting memory){
        return getVesting(computeVestingIdForAddressAndIndex(holder, index));
    }

    // @notice Returns the vesting schedule information for a given identifier
    // @return The vesting schedule structure information
    function getVesting(bytes32 vestingScheduleId)
        public
        view
        returns(Vesting memory){
        return vestings[vestingScheduleId];
    }

    // @notice Returns the vesting schedule id at the given index
    // @return The vesting ID
    function getVestingIdAtIndex(uint256 index)
    external
    view
    returns(bytes32){
        require(index < getVestingSchedulesCount(), "TokenVesting: index out of bounds");
        return vestingIds[index];
    }

    // @notice Returns the number of vesting schedules associated to a beneficiary
    // @return The number of vesting schedules
    function getVestingCountByBeneficiary(address _beneficiary)
    external
    view
    returns(uint256){
        return holdersVestingCount[_beneficiary];
    }

    // @notice Returns the array of managers
    function getManagers() public view returns (address[] memory) {
        return managers;
    }
    
    /* to remove */ function sendALGM(address who, uint256 amount) public onlyRole(MANAGER) {
        token.transfer(who, amount);
    }
}
