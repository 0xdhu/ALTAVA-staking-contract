//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

interface INFTStaking {
    // update staked nft infos
    function update_info(address _sender) external;

    // check if he already staked this token id
    function check_staked(address _sender, uint256 _tokenId)
        external
        view
        returns (bool);

    // get staked token ids
    function getStakedTokenIds(address _sender)
        external
        view
        returns (uint256[] memory result);

    // get current staked token count
    function getStakedNFTCount(address sender)
        external
        view
        returns (uint256 tempCount);
}
