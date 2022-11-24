//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface INFTStaking {
    /**
     * @notice when Stake TAVA or Extend locked period in SmartChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     */
    function stakeFromSmartChef(address sender) external returns (bool);

    /**
     * @notice when unstake TAVA in SmartChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromSmartChef(address sender) external returns (bool);

    /**
     * @notice when Stake TAVA or Extend locked period in NFTChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     * @param sender: user address
     */
    function stakeFromNFTChef(address sender) external returns (bool);

    /**
     * @notice when unstake TAVA in NFTChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromNFTChef(address sender) external returns (bool);

    /**
     * @notice get registered token IDs
     * @param sender: target address
     */
    function getStakedTokenIds(address sender)
        external
        view
        returns (uint256[] memory result);

    /**
     * @notice get registered token IDs for smartchef
     * @param sender: target address
     * @param smartchef: smartchef address
     * return timestamp array, registered count array at that ts
     */
    function getSmartChefBoostData(address sender, address smartchef)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    /**
     * @notice get registered token IDs for nftchef
     * @param sender: target address
     * @param nftchef: nftchef address
     */
    function getNFTChefBoostCount(address sender, address nftchef)
        external
        view
        returns (uint256);

    /**
     * @notice Get registered amount by sender
     * @param sender: target address
     */
    function getStakedNFTCount(address sender)
        external
        view
        returns (uint256 amount);
}
