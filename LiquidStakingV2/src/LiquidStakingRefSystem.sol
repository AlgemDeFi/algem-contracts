//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


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

contract LiquidStakingRefSystem is Initializable {
    using ByteConversion for bytes3;

    struct userReferralInfo {
        string referralCode;
        address referrer;
    }

    mapping(address => bool) public isRefUsedByAddress;
    mapping(string => address) public refToOwner;
    mapping(address => string) public addrToUsedRef;
    mapping(address => string) public ownerToRef;

    event BecomeReferrer(address indexed user, string indexed refCode);
    event BecomeReferral(address indexed referrer, address referral);

    /// @notice User is already a referrer
    error AlreadyReferrer();

    /// @notice Referral codes have already been used by user
    error RefAlreadyUsed();

    /// @notice Not allowed to use own refcode
    error OwnRefcode();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }  

    function initialize() public initializer {} 

    ////REFERRAL FUNCTIONS////
    /// @notice To become a referrer
    /// @return ref Referral codesrc/LiquidCrowdloan.sol
    function becomeReferrer() external returns (string memory ref) {
        address user = msg.sender;

        if (bytes(ownerToRef[user]).length != 0) {
            revert AlreadyReferrer();
        }

        bytes3 data = bytes3(keccak256(abi.encode(user)));
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
            if (isRefUsedByAddress[user]) revert RefAlreadyUsed();
            if (user == refToOwner[_ref]) revert OwnRefcode();

            isRefUsedByAddress[user] = true;
            addrToUsedRef[user] = _ref;

            emit BecomeReferral(user, refToOwner[_ref]);
        }
    }

    /// @notice get composed info on user referrals
    /// @param _user address to look for
    /// @return uri_ user referral info
    function getUserReferralInfo(address _user) external view returns (userReferralInfo memory uri_) {
        uri_.referralCode = ownerToRef[_user];
        uri_.referrer = refToOwner[addrToUsedRef[_user]];
    }
}