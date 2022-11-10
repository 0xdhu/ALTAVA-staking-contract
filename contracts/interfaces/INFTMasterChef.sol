//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface INFTMasterChef {
    /**
     * Emit event from sub chef: Staked
     */
    function emitStakedEventFromSubChef(
        address sender,
        uint256 stakeIndex,
        uint256 stakedAmount,
        uint256 lockedAt,
        uint256 lockDuration,
        uint256 unlockAt,
        uint256 nftBalance,
        uint256 boosterPercent
    ) external;

    /**
     * Emit event from sub chef: Unstaked
     */
    function emitUnstakedEventFromSubChef(
        address sender,
        uint256 stakeIndex,
        uint256 withdrawAmount,
        uint256 withdrawAt,
        uint256 nftBalance,
        uint256 boosterPercent
    ) external;

    /**
     * Emit event from sub chef: AddedRequiredLockAmount
     */
    function emitAddedRequiredLockAmountEventFromSubChef(
        address sender,
        uint256 period,
        uint requiredAmount,
        uint rewardnftAmount,
        bool isLive
    ) external;
}
