//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IMasterChef {
    /**
     * Emit event from sub chef: Staked
     */
    function emitStakedEventFromSubChef(
        address sender,
        uint256 lockedAmount,
        uint256 lockStartTime,
        uint256 lockEndTime,
        uint256 lastUserActionTime,
        uint256 rewards,
        uint256 rewardDebt,
        uint256 boosterValue
    ) external;

    /**
     * Emit event from sub chef: Unstaked
     */
    function emitUnstakedEventFromSubChef(
        address sender,
        uint256 lastUserActionTime,
        uint256 rewards,
        uint256 boosterValue
    ) external;
}
