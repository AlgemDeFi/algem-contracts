// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./NFTDistributor.sol";

contract AlgemLiquidStakingDiscount is ERC721PresetMinterPauserAutoIdUpgradeable {

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    NFTDistributor public nftDistr;

    string public utilName;
    uint256 public maxSupply;

    bool public initialized;

    enum TokenType {
        ALGEM, ARTHSWAP, ASTARCORE, ASTARDEGENS
    }
    mapping(uint256 => TokenType) public idToType;
    mapping(TokenType => string) public typeToURI;

    modifier updates() {
        nftDistr.updates();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }  

    function initialize(
        string memory name, 
        string memory symbol, 
        string memory baseTokenURI
    ) public override initializer {
        super.initialize(name, symbol, baseTokenURI);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }   

    function initialize2(
        address _nftDistr,
        string memory _utilName,
        uint256 _maxSupply
    ) external onlyRole(MANAGER_ROLE) {
        require(!initialized, "Already initialized!");
        initialized = true;
        nftDistr = NFTDistributor(_nftDistr);
        utilName = _utilName;
        maxSupply = _maxSupply;
    }

    function haveTokens(address account) external view returns (bool) {
        return ERC721Upgradeable.balanceOf(account) > 0;
    }

    function changeMaxSupply(uint256 _maxSupply) external onlyRole(MANAGER_ROLE) {
        require(_maxSupply >= totalSupply(), "Incorrect supply value");
        maxSupply = _maxSupply;
    }

    function setTypeURI(TokenType _type, string memory _uri) external onlyRole(MANAGER_ROLE) {
        typeToURI[_type] = _uri;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist!");
        return typeToURI[idToType[id]];
    }

    function mintBatch(address[] memory accounts, TokenType _type) external onlyRole(MINTER_ROLE) {
        uint256 l = accounts.length;
        require(totalSupply() + l - 1 < maxSupply, "Token limit reached");

        for (uint256 i = 0; i < l; ) {
            mint(accounts[i], _type);
            unchecked { ++i; }
        }
    }

    function mint(address to, TokenType _type) public updates onlyRole(MINTER_ROLE) {
        require(totalSupply() < maxSupply, "Token limit reached");
        uint256 id = totalSupply();
        idToType[id] = _type;
        super.mint(to);
    }

    function burn(uint256 _tokenId) public override {
        revert("Cant burn tokens");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        nftDistr.transferNft(utilName, from, to, 1);
    }

    function addManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MANAGER_ROLE, account);
    }

    function removeManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MANAGER_ROLE, account);
    }

    /// @notice disabled revoke ownership functionality
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        require(role != DEFAULT_ADMIN_ROLE, "Not allowed to revoke admin role");
        _revokeRole(role, account);
    }

}  
