// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "./PendleBaseToken.sol";
import "../interfaces/IPPrincipalToken.sol";
import "../interfaces/ISuperComposableYield.sol";
import "./LiquidityMining/PendleGauge.sol";
import "./PendleMarket.sol";

import "../interfaces/IPMarket.sol";
import "../interfaces/IPMarketFactory.sol";
import "../interfaces/IPMarketSwapCallback.sol";
import "../interfaces/IPMarketAddRemoveCallback.sol";

import "../libraries/math/LogExpMath.sol";
import "../libraries/math/Math.sol";
import "../libraries/math/MarketMathAux.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// solhint-disable reason-string
// solhint-disable no-empty-blocks
contract PendleMarketRewards is PendleGauge, PendleMarket {
    constructor(
        address _PT,
        int256 _scalarRoot,
        int256 _initialAnchor,
        address _vePendle,
        address _gaugeController
    ) PendleMarket(_PT, _scalarRoot, _initialAnchor) PendleGauge(_vePendle, _gaugeController) {}

    function _getRewardTokens() internal view override returns (address[] memory rewardTokens) {
        address[] memory SCYRewards = ISuperComposableYield(SCY).getRewardTokens();
        for (uint256 i = 0; i < SCYRewards.length; ++i) {
            if (SCYRewards[i] == pendle) {
                return SCYRewards;
            }
        }
        rewardTokens = new address[](SCYRewards.length + 1);
        rewardTokens[0] = pendle;
        for (uint256 i = 0; i < SCYRewards.length; ++i) {
            rewardTokens[i + 1] = SCYRewards[i];
        }
    }

    function _stakedBalance(address user) internal view override returns (uint256) {
        return balanceOf(user);
    }

    function _totalStaked() internal view override returns (uint256) {
        return totalSupply();
    }

    function _redeemExternalReward() internal override {
        ISuperComposableYield(SCY).claimRewards(address(this));
        super._redeemExternalReward();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        _updateRewardIndex();
        if (from != address(0) && from != address(this)) _distributeUserReward(from);
        if (to != address(0) && to != address(this)) _distributeUserReward(to);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        if (from != address(0) && from != address(this)) {
            _updateUserActiveBalance(from);
        }
        if (to != address(0) && to != address(this)) {
            _updateUserActiveBalance(to);
        }
    }
}
