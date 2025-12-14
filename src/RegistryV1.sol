// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract RegistryV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    error Unauthorized();
    error PoolNotRegistered();
    error PoolAlreadyRegistered();

    struct PoolInfo {
        address poolContract;
        uint256 poolId;
        address owner;
        string metadata;
        uint256 registeredAt;
        bool active;
    }

    event PoolRegistered(bytes32 indexed registryId, address indexed poolContract, uint256 indexed poolId);
    event PoolMetadataUpdated(bytes32 indexed registryId, string metadata);
    event PoolStatusUpdated(bytes32 indexed registryId, bool active);

    mapping(bytes32 => PoolInfo) private _registry;
    mapping(address => bytes32[]) private _ownerPools;
    bytes32[] private _allPools;

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function register(address poolContract, uint256 poolId, string calldata metadata)
        external
        whenNotPaused
        returns (bytes32 registryId)
    {
        registryId = keccak256(abi.encodePacked(poolContract, poolId));
        if (_registry[registryId].poolContract != address(0)) revert PoolAlreadyRegistered();

        _registry[registryId] = PoolInfo({
            poolContract: poolContract,
            poolId: poolId,
            owner: msg.sender,
            metadata: metadata,
            registeredAt: block.timestamp,
            active: true
        });

        _ownerPools[msg.sender].push(registryId);
        _allPools.push(registryId);

        emit PoolRegistered(registryId, poolContract, poolId);
    }

    function updateMetadata(bytes32 registryId, string calldata metadata) external whenNotPaused {
        if (_registry[registryId].owner != msg.sender) revert Unauthorized();
        _registry[registryId].metadata = metadata;
        emit PoolMetadataUpdated(registryId, metadata);
    }

    function setStatus(bytes32 registryId, bool active) external whenNotPaused {
        if (_registry[registryId].owner != msg.sender) revert Unauthorized();
        _registry[registryId].active = active;
        emit PoolStatusUpdated(registryId, active);
    }

    function getPool(bytes32 registryId) external view returns (PoolInfo memory) {
        return _registry[registryId];
    }

    function getOwnerPools(address owner) external view returns (bytes32[] memory) {
        return _ownerPools[owner];
    }

    function getAllPools() external view returns (bytes32[] memory) {
        return _allPools;
    }

    function getPoolCount() external view returns (uint256) {
        return _allPools.length;
    }

    // Allow delegatecall during UUPS upgradeToAndCall with empty data
    fallback() external payable {}
    receive() external payable {}
}
