//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AlgemantisNautilusPass is ERC721, AccessControl {

    uint public maxTotal = 7885;
    uint public totalSupply;
    uint public reserved = 50;
    string private uri;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event MinterAdd(address indexed minter);
    event MinterRemove(address indexed minter);
    event Mint(address indexed to, uint256 id);

    modifier mintPossible(address to, uint256 id) {
        require(id < 7886, "Invalid id");
        require(totalSupply < maxTotal, "Total supply limit!");
        require(to != address(0), "Invalid address!");
        require(!_exists(id), "ID already occupied!");
        _;
    }

    constructor(string memory _uri) ERC721("Algemantis Nautilus Pass", "ANP")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        uri = _uri;
    }

    function setBaseURI(string memory _uri)
             external onlyRole(DEFAULT_ADMIN_ROLE) {
        uri = _uri;
    }

    function addMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "Invalid address");
        require(!hasRole(MINTER_ROLE, msg.sender), "Already minter");

        _grantRole(MINTER_ROLE, _minter);

        emit MinterAdd(_minter);
    }

    function removeMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "Invalid address");
        require(hasRole(MINTER_ROLE, msg.sender), "Not a minter");

        _revokeRole(MINTER_ROLE, _minter);

        emit MinterRemove(_minter);
    }

    function safeMint(address to, uint256 id) external mintPossible(to, id) onlyRole(MINTER_ROLE) {
        require(maxTotal - totalSupply > reserved, "Only reserved left!");

        _safeMint(to, id);
        totalSupply++;

        emit Mint(to, id);
    }

    function reservedMint(address to, uint256 id) external mintPossible(to, id) onlyRole(MINTER_ROLE) {
        require(reserved > 0, "No more reserved left!");

        _safeMint(to, id);
        totalSupply++;
        reserved--;

        emit Mint(to, id);
    }

    function alarMint(address to, uint256 id) external mintPossible(to, id) onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMint(to, id);
        totalSupply++;

        emit Mint(to, id);
    }

    function _baseUri() public view returns (string memory uri_) {
        uri_ = uri;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist!");

        string memory _id = Strings.toString(id);

        return string(abi.encodePacked(uri, "metadata/", _id, ".json"));
    }

    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function supportsInterface(bytes4 interfaceID) public view override(ERC721, AccessControl)returns (bool) 
    {
        return super.supportsInterface(interfaceID);
    }

}
