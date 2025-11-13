// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract SplitBaseUpgradeable is Initializable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Split {
        address[] recipients;
        uint256[] shares;
        uint256 totalShares;
        bool active;
    }

    address internal _admin;
    uint256 internal _version;
    Split internal _split;
    
    mapping(address => uint256) public pendingETH;
    mapping(address => mapping(address => uint256)) public pendingTokens;
    
    uint256 public totalETHReceived;
    mapping(address => uint256) public totalTokensReceived;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event SplitUpdated(address[] recipients, uint256[] shares, uint256 totalShares);
    event PaymentReceived(address indexed from, uint256 amount);
    event TokenPaymentReceived(address indexed token, address indexed from, uint256 amount);
    event ETHWithdrawn(address indexed recipient, uint256 amount);
    event TokenWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event SplitActivated();
    event SplitDeactivated();

    error InvalidSharesLength();
    error ZeroTotalShares();
    error InvalidRecipient();
    error NoSplitConfigured();
    error SplitNotActive();
    error NoFundsToWithdraw();
    error TransferFailed();
    error OnlyAdmin();
    error ZeroAddress();

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert OnlyAdmin();
        _;
    }

    function initialize(address admin_) external initializer {
        if (admin_ == address(0)) revert ZeroAddress();
        _admin = admin_;
        _version = 1;
    }

    function bootstrapAdmin(address admin_) external {
        if (_admin != address(0)) revert OnlyAdmin();
        if (admin_ == address(0)) revert ZeroAddress();
        _admin = admin_;
        emit AdminTransferred(address(0), admin_);
    }

    function admin() external view returns (address) {
        return _admin;
    }

    function getVersion() external view returns (uint256) {
        return _version;
    }

    function setVersion(uint256 v) external onlyAdmin {
        _version = v;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        emit AdminTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }

    function configureSplit(
        address[] calldata recipients,
        uint256[] calldata shares
    ) external onlyAdmin {
        if (recipients.length != shares.length || recipients.length == 0) {
            revert InvalidSharesLength();
        }

        uint256 totalShares = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert InvalidRecipient();
            if (shares[i] == 0) revert InvalidSharesLength();
            totalShares += shares[i];
        }

        if (totalShares == 0) revert ZeroTotalShares();

        _split.recipients = recipients;
        _split.shares = shares;
        _split.totalShares = totalShares;
        _split.active = true;

        emit SplitUpdated(recipients, shares, totalShares);
        emit SplitActivated();
    }

    function deactivateSplit() external onlyAdmin {
        _split.active = false;
        emit SplitDeactivated();
    }

    function activateSplit() external onlyAdmin {
        if (_split.recipients.length == 0) revert NoSplitConfigured();
        _split.active = true;
        emit SplitActivated();
    }

    function getSplitConfig() external view returns (
        address[] memory recipients,
        uint256[] memory shares,
        uint256 totalShares,
        bool active
    ) {
        return (_split.recipients, _split.shares, _split.totalShares, _split.active);
    }

    receive() external payable {
        if (msg.value > 0) {
            _distributeETH(msg.value);
            emit PaymentReceived(msg.sender, msg.value);
        }
    }

    function depositETH() external payable {
        if (msg.value > 0) {
            _distributeETH(msg.value);
            emit PaymentReceived(msg.sender, msg.value);
        }
    }

    function depositToken(address token, uint256 amount) external {
        if (amount == 0) revert NoFundsToWithdraw();
        
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        _distributeToken(token, amount);
        
        emit TokenPaymentReceived(token, msg.sender, amount);
    }

    function _distributeETH(uint256 amount) internal {
        if (!_split.active || _split.recipients.length == 0) {
            return;
        }

        totalETHReceived += amount;

        for (uint256 i = 0; i < _split.recipients.length; i++) {
            uint256 share = (amount * _split.shares[i]) / _split.totalShares;
            pendingETH[_split.recipients[i]] += share;
        }
    }

    function _distributeToken(address token, uint256 amount) internal {
        if (!_split.active || _split.recipients.length == 0) {
            return;
        }

        totalTokensReceived[token] += amount;

        for (uint256 i = 0; i < _split.recipients.length; i++) {
            uint256 share = (amount * _split.shares[i]) / _split.totalShares;
            pendingTokens[_split.recipients[i]][token] += share;
        }
    }

    function withdrawETH() external {
        uint256 amount = pendingETH[msg.sender];
        if (amount == 0) revert NoFundsToWithdraw();

        pendingETH[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit ETHWithdrawn(msg.sender, amount);
    }

    function withdrawToken(address token) external {
        uint256 amount = pendingTokens[msg.sender][token];
        if (amount == 0) revert NoFundsToWithdraw();

        pendingTokens[msg.sender][token] = 0;
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);

        emit TokenWithdrawn(token, msg.sender, amount);
    }

    function getPendingETH(address recipient) external view returns (uint256) {
        return pendingETH[recipient];
    }

    function getPendingToken(address recipient, address token) external view returns (uint256) {
        return pendingTokens[recipient][token];
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    uint256[44] private __gap;
}
