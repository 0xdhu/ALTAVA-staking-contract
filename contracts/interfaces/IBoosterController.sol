//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBoosterController {
    /**
     * @dev get Booster APR
     */
    function getBoosterAPR(uint256 _key, address _smartchef)
        external
        view
        returns (uint256);
}
