//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

interface INFTMasterChef {
    /**
     * Emit event from sub chef: Staked
     */
    function emitStakedEventFromSubChef(
        address sender, 
        uint256 stake_index,
        uint256 staked_amount, 
        uint256 locked_at, 
        uint256 lock_duration, 
        uint256 unlock_at,
        uint256 nft_balance,
        uint256 booster_percent
    ) external;

    /**
     * Emit event from sub chef: Unstaked
     */
    function emitUnstakedEventFromSubChef(
        address sender, 
        uint256 stake_index,
        uint256 withdraw_amount, 
        uint256 withdraw_at,
        uint256 nft_balance,
        uint256 booster_percent
    ) external;

    /**
     * Emit event from sub chef: AddedRequiredLockAmount
     */
    function emitAddedRequiredLockAmountEventFromSubChef(
        address sender, 
        uint256 period, 
        uint required_amount, 
        uint rewardnft_amount,
        bool is_live
    ) external;
    
}