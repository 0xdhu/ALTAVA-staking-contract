//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IMasterChef {
    /**
     * @notice get all smartchef contract's address deployed by MasterChef
     */
    function getAllChefAddress() external view returns (address[] memory);
}
