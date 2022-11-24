//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface INFTMasterChef {
    /**
     * @notice get chef address with id
     * @dev index starts from 1 but not zero
     * @param id: index
     */
    function getChefAddress(uint256 id) external view returns (address);

    /**
     * @notice get all smartchef contract's address
     */
    function getAllChefAddress() external view returns (address[] memory);
}
