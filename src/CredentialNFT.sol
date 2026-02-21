// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ICredentialNFT} from "./interfaces/ICredentialNFT.sol";
import {IIssuerRegistry} from "./interfaces/IIssuerRegistry.sol";
import {Errors} from "./errors/Errors.sol";
import {CredentialNFTStorage} from "./storage/CredentialNFTStorage.sol";

/// @title CredentialNFT
/// @author Karan Bharda (scarcemrk)
/// @notice Implements the verifiable credential NFT standard using ERC721Upgradeable and UUPSUpgradeable
/// @dev This contract manages verifiable credentials as NFTs with upgradeability support

contract CredentialNFT is Initializable, ERC721Upgradeable, UUPSUpgradeable, CredentialNFTStorage, ICredentialNFT {
    /// @notice Restricts access to protocol admin only
    /// @dev Reverts if caller is not the protocol admin
    modifier onlyProtocolAdmin() {
        require(msg.sender == _protocolAdmin, Errors.NotProtocolAdmin());
        _;
    }

    modifier onlyIssuer() {
        require(IIssuerRegistry(_issuerRegistry).isAuthorizedIssuer(msg.sender), Errors.NotAuthorizedIssuer());

        _;
    }

    /// @notice Disables initializers on the implementation contract
    /// @dev Prevents implementation contract from being initialized
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the credential NFT contract
    /// @dev Sets up ERC721 metadata, issuer registry, and protocol admin
    /// @param name_ The name of the NFT
    /// @param symbol_ The symbol of the NFT
    /// @param issuerRegistry_ The address of the issuer registry contract
    /// @param admin_ The address of the protocol admin
    function initialize(string memory name_, string memory symbol_, address issuerRegistry_, address admin_)
        external
        initializer
    {
        require(issuerRegistry_ != address(0), Errors.InvalidIssuerRegistryAddress());
        require(admin_ != address(0), Errors.InvalidAddress());
        __ERC721_init(name_, symbol_);
        _issuerRegistry = issuerRegistry_;
        _protocolAdmin = admin_;
    }

    /// @notice Mints a new credential NFT to a recipient
    /// @dev Only authorized issuers can mint credentials
    /// @param _recipient The address of the recipient of the credential NFT
    /// @param _credentialhash The hash of the credential data
    /// @return tokenId The token ID of the newly minted credential NFT
    function mintCredential(address _recipient, bytes32 _credentialhash)
        external
        override
        onlyIssuer
        returns (uint256 tokenId)
    {
        require(_credentialhash != bytes32(0), Errors.InvalidCredentialHash());
        require(_recipient != address(0), Errors.InvalidAddress());
        _tokenIdCounter++;
        tokenId = _tokenIdCounter;
        _mint(_recipient, tokenId);
        _credentialHash[tokenId] = _credentialhash;
        _credentialIssuer[tokenId] = msg.sender;
        _revoked[tokenId] = false;
        emit CredentialIssued(msg.sender, _recipient, tokenId, _credentialhash);
        return tokenId;
    }

    /// @notice Revokes an existing credential
    /// @dev Only the original issuer can revoke their credential
    /// @param _tokenId The token ID of the credential to revoke
    /// @param _reason The reason for revoking the credential
    function revokeCredential(uint256 _tokenId, string calldata _reason) external override {
        require(_ownerOf(_tokenId) != address(0), Errors.CredentialDoesNotExist());
        require(_revoked[_tokenId] == false, Errors.CredentialAlreadyRevoked());
        require(_credentialIssuer[_tokenId] == msg.sender, Errors.OnlyIssuerCanRevoke());
        _revoked[_tokenId] = true;
        emit CredentialRevoked(_tokenId, _reason);
    }

    /// @notice Checks if a credential is valid
    /// @dev Returns false if credential does not exist or is revoked
    /// @param _tokenId The token ID of the credential to check
    /// @return isValid Whether the credential is valid (not revoked)
    function isValid(uint256 _tokenId) external view override returns (bool) {
        if (_ownerOf(_tokenId) == address(0)) {
            return false;
        }
        return !_revoked[_tokenId];
    }

    /// @notice Returns the hash of a credential
    /// @dev Returns zero if credential does not exist
    /// @param _tokenId The token ID of the credential to retrieve the hash for
    /// @return credentialHash The hash of the credential data
    function getCredentialHash(uint256 _tokenId) external view override returns (bytes32) {
        return _credentialHash[_tokenId];
    }

    /// @notice Returns the issuer of a credential
    /// @dev Returns zero address if credential does not exist
    /// @param _tokenId The token ID of the credential to retrieve the issuer for
    /// @return issuer The address of the issuer of the credential
    function getIssuer(uint256 _tokenId) external view override returns (address) {
        return _credentialIssuer[_tokenId];
    }

    /// @notice Authorizes contract upgrades
    /// @dev Only protocol admin can authorize upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyProtocolAdmin {}

    /// @dev Overrides the default ERC721 _update function to prevent transfers and burns of credential NFTs
    /// @param _to The address to transfer the NFT to
    /// @param _tokenId The token ID of the NFT being transferred
    /// @param _auth The address authorized to perform the transfer (ignored in this override)
    /// @return The address of the owner of the NFT (always returns 0 for non-transferable NFTs)
    function _update(address _to, uint256 _tokenId, address _auth) internal override returns (address) {
        address from = _ownerOf(_tokenId);

        require(from == address(0), Errors.CredentialIsNotTransferable());
        return super._update(_to, _tokenId, _auth);
    }
}
