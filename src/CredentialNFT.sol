// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ICredentialNFT} from "./interfaces/ICredentialNFT.sol";
import {IIssuerRegistry} from "./interfaces/IIssuerRegistry.sol";
import {CredentialNFTStorage} from "./storage/CredentialNFTStorage.sol";

/// @title CredentialNFT
/// @author Karan Bharda (scarcemrk)
/// @notice Implements the verifiable credential NFT standard using ERC721Upgradeable and UUPSUpgradeable
/// @dev This contract manages verifiable credentials as NFTs with upgradeability support

contract CredentialNFT is Initializable, ERC721Upgradeable, UUPSUpgradeable, CredentialNFTStorage, ICredentialNFT {
    /// @notice
    /// @dev
    modifier onlyProtocolAdmin() {
        require(msg.sender == _protocolAdmin, "Not protocol admin");
        _;
    }

    modifier onlyIssuer() {
        require(IIssuerRegistry(_issuerRegistry).isAuthorizedIssuer(msg.sender), "Not an issuer");
        _;
    }

    /// @notice
    /// @dev
    constructor() {
        _disableInitializers();
    }

    /// @notice
    /// @dev
    /// @param name_ The name of the NFT
    /// @param symbol_ The symbol of the NFT
    /// @param issuerRegistry_ The address of the issuer registry contract
    /// @param admin_ The address of the protocol admin
    function initialize(string memory name_, string memory symbol_, address issuerRegistry_, address admin_)
        external
        initializer
    {
        require(issuerRegistry_ != address(0), "Invalid issuer registry address");
        require(admin_ != address(0), "Invalid admin address");
        __ERC721_init(name_, symbol_);
        _issuerRegistry = issuerRegistry_;
        _protocolAdmin = admin_;
    }

    /// @notice
    /// @dev
    /// @param _recipient The address of the recipient of the credential NFT
    /// @param _credentialhash The hash of the credential data
    /// @return tokenId The token ID of the newly minted credential NFT
    function mintCredential(address _recipient, bytes32 _credentialhash)
        external
        override
        onlyIssuer
        returns (uint256 tokenId)
    {
        require(_credentialhash != bytes32(0), "Invalid credential hash");
        require(_recipient != address(0), "Invalid recipient address");
        _tokenIdCounter++;
        tokenId = _tokenIdCounter;
        _mint(_recipient, tokenId);
        _credentialHash[tokenId] = _credentialhash;
        _credentialIssuer[tokenId] = msg.sender;
        _revoked[tokenId] = false;
        emit CredentialIssued(msg.sender, _recipient, tokenId, _credentialhash);
        return tokenId;
    }

    /// @notice
    /// @dev
    /// @param _tokenId The token ID of the credential to revoke
    /// @param _reason The reason for revoking the credential
    function revokeCredential(uint256 _tokenId, string calldata _reason) external override {
        require(_ownerOf(_tokenId) != address(0), "Token does not exist");
        require(_revoked[_tokenId] == false, "Credential already revoked");
        require(_credentialIssuer[_tokenId] == msg.sender, "Only issuer can revoke credential");
        _revoked[_tokenId] = true;
        emit CredentialRevoked(_tokenId, _reason);
    }

    /// @dev
    /// @param _tokenId The token ID of the credential to check
    /// @return isValid Whether the credential is valid (not revoked)
    function isValid(uint256 _tokenId) external view override returns (bool) {
        if (_ownerOf(_tokenId) == address(0)) {
            return false;
        }
        return !_revoked[_tokenId];
    }

    /// @dev
    /// @param _tokenId The token ID of the credential to retrieve the hash for
    /// @return credentialHash The hash of the credential data
    function getCredentialHash(uint256 _tokenId) external view override returns (bytes32) {
        return _credentialHash[_tokenId];
    }

    /// @dev
    /// @param _tokenId The token ID of the credential to retrieve the issuer for
    /// @return issuer The address of the issuer of the credential
    function getIssuer(uint256 _tokenId) external view override returns (address) {
        return _credentialIssuer[_tokenId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyProtocolAdmin {}

    // override a function that disable nft trasnfers
    function _update(address _to, uint256 _tokenId, address _auth) internal override returns (address) {
        address from = _ownerOf(_tokenId);

        require(from == address(0), "NFT is not transferable");
        return super._update(_to, _tokenId, _auth);
    }
}
