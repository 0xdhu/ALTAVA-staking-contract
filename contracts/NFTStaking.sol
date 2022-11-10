//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @dev SecondSKin NFT Staking
 */
contract NFTStaking is Ownable {
    // 0x82f371b47cc5b9cf23af60a9a31a9e7a6bef8a2d
    IERC721 public secondskinNFT;

    struct StakeInfo {
        uint256 tokenId;
        bool isStaked;
    }

    // Important: secondskin nft has no token_id: 0
    // staker address => staking index => token_id
    mapping(address => mapping(uint256 => StakeInfo)) public stakedIds;
    // staker address => staking amount
    mapping(address => uint256) public stakingAmounts;

    constructor(IERC721 _secondskinNFT) {
        secondskinNFT = _secondskinNFT;
    }

    event NFTStaked(address indexed sender, uint256 token_id);
    event NFTUnstaked(address indexed sender, uint256 token_id);

    /**
     * Stake NFT
     */
    function stake(uint256[] calldata token_ids) external {
        update_info(msg.sender);

        for (uint256 i = 0; i < token_ids.length; i++) {
            uint256 tokenId = token_ids[i];
            _stake(tokenId);
        }
    }

    /**
     * @dev stake each tokenID
     */
    function _stake(uint256 tokenId) private {
        address _sender = msg.sender;
        require(secondskinNFT.ownerOf(tokenId) == _sender, "You are not owner");

        uint256 stakedAmount = stakingAmounts[_sender];
        uint256 current_index = get_staked_index(_sender, tokenId);

        StakeInfo storage stakeInfo = stakedIds[_sender][current_index];

        if (current_index < stakedAmount) {
            if (stakeInfo.isStaked == false) {
                stakeInfo.isStaked = true;
                emit NFTStaked(_sender, tokenId);
            }
        } else {
            stakeInfo.tokenId = tokenId;
            stakeInfo.isStaked = true;

            stakingAmounts[_sender] = stakedAmount + 1;
            emit NFTStaked(_sender, tokenId);
        }
    }

    /**
     * @dev Unstake the staked token ID
     */
    function unstake(uint256 tokenId) external {
        address _sender = msg.sender;
        require(secondskinNFT.ownerOf(tokenId) == _sender, "You are not owner");

        uint256 stakedAmount = stakingAmounts[_sender];
        uint256 current_index = get_staked_index(_sender, tokenId);
        require(current_index != stakedAmount, "Not staked yet");

        StakeInfo storage stakeInfo = stakedIds[_sender][current_index];
        if (current_index < stakedAmount && stakeInfo.isStaked == true) {
            stakeInfo.isStaked = false;

            emit NFTUnstaked(_sender, tokenId);
        }
    }

    /**
     * @dev Since staker might transferred his NFT to others, staking info should be updated
     */
    function update_info(address _sender) public {
        uint256 stakedAmount = stakingAmounts[_sender];
        for (uint256 i = 0; i < stakedAmount; i++) {
            StakeInfo storage stakeInfo = stakedIds[_sender][i];
            if (stakeInfo.isStaked) {
                if (secondskinNFT.ownerOf(stakeInfo.tokenId) != _sender) {
                    stakeInfo.isStaked = false;
                    emit NFTUnstaked(_sender, stakeInfo.tokenId);
                }
            }
        }
    }

    /**
     * @dev return current staked index
     */
    function get_staked_index(address _sender, uint256 _tokenId)
        private
        view
        returns (uint256)
    {
        uint256 stakedAmount = stakingAmounts[_sender];
        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = stakedIds[_sender][i].tokenId;
            if (tokenId == _tokenId) {
                return i;
            }
        }
        return stakedAmount;
    }

    function check_staked(address _sender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        uint256 stakedAmount = stakingAmounts[_sender];
        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = stakedIds[_sender][i].tokenId;
            if (tokenId == _tokenId) {
                return stakedIds[_sender][i].isStaked;
            }
        }
        return false;
    }

    /**
     * @dev get staked info
     */
    function getStakedTokenIds(address _sender)
        external
        view
        returns (uint256[] memory)
    {
        uint256 stakedAmount = stakingAmounts[_sender];
        uint256 liveStakedAmount = getStakedNFTCount(_sender);
        uint256 tempCount = 0;

        uint256[] memory tokenIds = new uint256[](liveStakedAmount);

        for (uint256 i = 0; i < stakedAmount; i++) {
            StakeInfo memory stakeInfo = stakedIds[_sender][i];
            bool isOwned = secondskinNFT.ownerOf(stakeInfo.tokenId) == _sender;
            if (stakeInfo.isStaked && isOwned) {
                tokenIds[tempCount] = stakeInfo.tokenId;
                tempCount++;
            }
        }
        return tokenIds;
    }

    /**
     * @dev get staked balance
     */
    function getStakedNFTCount(address sender)
        public
        view
        returns (uint256 tempCount)
    {
        uint256 stakedAmount = stakingAmounts[sender];
        tempCount = 0;
        for (uint256 i = 0; i < stakedAmount; i++) {
            StakeInfo memory stakeInfo = stakedIds[sender][i];
            bool isOwned = secondskinNFT.ownerOf(stakeInfo.tokenId) == sender;
            if (stakeInfo.isStaked && isOwned) {
                tempCount++;
            }
        }
    }
}
