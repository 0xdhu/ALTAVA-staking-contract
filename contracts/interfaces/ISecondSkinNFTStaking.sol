//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

interface ISecondSkinNFTStaking {
    /**
     * @dev to calculate booster, we need to get nft number locked by user
     */
    function getUserLockedNFTCounter() external view returns(uint);    
}