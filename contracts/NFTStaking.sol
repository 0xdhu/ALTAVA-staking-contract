//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IterateMapping.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/INFTMasterChef.sol";
import "./interfaces/INFTStaking.sol";

/**
 * @notice SecondSkin NFT Staking contract
 * @dev Just register NFT token ID but not lock NFT in our contract
 */
contract NFTStaking is Ownable, INFTStaking {
    using IterableMapping for ItMap;

    /// @notice Includes registered token ID array
    struct StakedInfo {
        uint256[] tokenIds; // registered token id array
        uint256 size; // use this to avoid compile error
    }

    /// @notice Secondskin NFT contract
    IERC721 public immutable secondskinNFT;
    /// @notice MasterChef contract
    IMasterChef public masterChef;
    /// @notice NFT MasterChef contract
    INFTMasterChef public nftMasterChef;

    /// @notice Maximum register able NFT amount
    /// @dev This is used to avoid block gas limit
    uint256 public constant MAX_REGISTER_LIMIT = 10;
    /// @dev Use this instead of -1.
    /// This would be used for unknow index
    uint256 public constant MINUS_ONE = 999;

    /// @notice registered token id array in this contract
    /// @dev NOTE: secondskin nft has no tokenId: 0
    /// staker address => staking index => tokenId
    mapping(address => StakedInfo) public stakedIds;
    /// @notice need to track registered token IDs in smartchef
    /// so that we can provide booster option to secondskin NFT stakers
    /// We just check if registered "Secondskin NFT" token ID is hold in user wallet
    /// both at the beginning of stake and at end of unlock date
    /// user address => pool address => info
    mapping(address => mapping(address => ItMap)) public smartChefBoostData;
    /// @notice need to track registered token IDs in nftchef
    /// so that we can provide booster option to secondskin NFT stakers
    /// We just check if registered "Secondskin NFT" token ID is hold in user wallet
    /// both at the beginning of stake and at end of unlock date
    /// user address => pool address => info
    mapping(address => mapping(address => ItMap)) public nftChefBoostData;

    /// @dev when you register secondskin NFT in NFTStaking contract,
    event NFTStaked(address indexed sender, uint256 tokenId);
    /// @dev when you unregister secondskin NFT in NFTStaking contract,
    event NFTUnstaked(address indexed sender, uint256 tokenId);
    /// @dev if you have registered secondskin NFT in NFTStaking contract,
    /// you can get booster in smartchef contract
    event SmartChefBoosterAdded(
        address indexed sender,
        address smartchefAddress,
        uint256 tokenId,
        uint256 timestamp
    );
    /// @dev if you have registered secondskin NFT in NFTStaking contract,
    /// you can get booster in nftchef contract
    event NFTChefBoosterAdded(
        address indexed sender,
        address nftchefAddress,
        uint256 tokenId,
        uint256 timestamp
    );

    /// @notice Checks if the msg.sender is a owner of the NFT.
    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            secondskinNFT.ownerOf(tokenId) == msg.sender,
            "You are not owner"
        );
        _;
    }

    /// @notice Checks if the msg.sender is sub smartchef
    modifier onlySmartChef() {
        require(
            address(masterChef) != address(0x0),
            "masterchef: zero address"
        );
        bool flag = false;
        address[] memory smartchefAddresses = masterChef.getAllChefAddress();
        uint256 smartchefNum = smartchefAddresses.length;
        for (uint256 si = 0; si < smartchefNum; si++) {
            address smarchefAddress = smartchefAddresses[si];
            if (smarchefAddress == msg.sender) {
                flag = true;
            }
        }
        require(flag, "You are not subchef");
        _;
    }

    /// @notice Checks if the msg.sender is sub nftchef
    modifier onlyNFTChef() {
        require(
            address(nftMasterChef) != address(0x0),
            "nftMasterChef: zero address"
        );
        bool flag = false;
        address[] memory nftchefAddresses = nftMasterChef.getAllChefAddress();
        uint256 nftchefNum = nftchefAddresses.length;
        for (uint256 si = 0; si < nftchefNum; si++) {
            address nftchefAddress = nftchefAddresses[si];
            if (nftchefAddress == msg.sender) {
                flag = true;
            }
        }
        require(flag, "You are not subchef");
        _;
    }

    /// @notice Check if target is not zero address
    /// @param addr: target address
    modifier _realAddress(address addr) {
        require(addr != address(0), "Cannot be zero address");
        _;
    }

    /**
     * @notice Constructor
     * @param _secondskinNFT: Altava SecondSkin NFT contract
     */
    constructor(IERC721 _secondskinNFT) {
        secondskinNFT = _secondskinNFT;
    }

    /**
     * @notice Set MasterChef contract by only admin
     */
    function setMasterChef(address newMasterChef)
        external
        onlyOwner
        _realAddress(newMasterChef)
    {
        masterChef = IMasterChef(newMasterChef);
    }

    /**
     * @notice Set NFT MasterChef contract by only admin
     */
    function setNFTMasterChef(address newNFTMasterChef)
        external
        onlyOwner
        _realAddress(newNFTMasterChef)
    {
        nftMasterChef = INFTMasterChef(newNFTMasterChef);
    }

    /**
     * @notice Register secondskin NFT token IDs
     * @dev Only IDs that sender holds can be registered
     * @param tokenIds: secondskin NFT token ID array
     */
    function stake(uint256[] calldata tokenIds) external {
        require(
            address(masterChef) != address(0x0),
            "masterchef: zero address"
        );
        uint256 len = tokenIds.length;
        require(len > 0, "Empty array");
        address _sender = msg.sender;
        _removeUnholdNFTs(_sender);

        StakedInfo memory stakedInfo = stakedIds[_sender];
        uint256 curRegisteredAmount = stakedInfo.tokenIds.length;
        require(
            len + curRegisteredAmount <= MAX_REGISTER_LIMIT,
            "Overflow max registration limit"
        );

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokenIds[i];
            _stake(tokenId);

            address[] memory smartchefAddresses = masterChef
                .getAllChefAddress();
            uint256 smartchefNum = smartchefAddresses.length;
            uint256 timestamp = block.timestamp;
            for (uint256 si = 0; si < smartchefNum; si++) {
                address smarchefAddress = smartchefAddresses[si];
                ItMap storage smartchefData = smartChefBoostData[_sender][
                    smarchefAddress
                ];
                if (
                    !smartchefData.contains(tokenId) &&
                    smartchefData.stakeStarted &&
                    smartchefData.keys.length < MAX_REGISTER_LIMIT
                ) {
                    smartchefData.insert(tokenId, timestamp);
                    // emit event
                    emit SmartChefBoosterAdded(
                        _sender,
                        smarchefAddress,
                        tokenId,
                        timestamp
                    );
                }
            }
        }
    }

    /**
     * @notice Unregister token IDs
     * @param tokenId: token ID to unregister
     */
    function unstake(uint256 tokenId) external onlyTokenOwner(tokenId) {
        address _sender = msg.sender;
        _removeUnholdNFTs(_sender);
        uint256 currentIndex = _getStakedIndex(_sender, tokenId);
        require(currentIndex != MINUS_ONE, "Not staked yet");

        StakedInfo storage stakedInfo = stakedIds[_sender];
        uint256 lastIndex = stakedInfo.tokenIds.length - 1;
        if (lastIndex != currentIndex) {
            stakedInfo.tokenIds[currentIndex] = stakedInfo.tokenIds[lastIndex];
        }
        stakedInfo.tokenIds.pop();
        // If userInfo is empty, free up storage space and get gas refund
        if (lastIndex == 0) {
            delete stakedIds[_sender];
        }

        emit NFTUnstaked(_sender, tokenId);
    }

    /**
     * @notice when Stake TAVA or Extend locked period in SmartChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     * @param sender: user address
     */
    function stakeFromSmartChef(address sender)
        external
        override
        onlySmartChef
        returns (bool)
    {
        ItMap storage smartchefData = smartChefBoostData[sender][msg.sender];
        StakedInfo memory stakedInfo = stakedIds[sender];
        uint256 len = stakedInfo.tokenIds.length;
        uint256 curBlockTimestamp = block.timestamp;
        smartchefData.stakeStarted = true;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            smartchefData.insert(tokenId, curBlockTimestamp);
            // emit event
            emit SmartChefBoosterAdded(
                sender,
                msg.sender,
                tokenId,
                curBlockTimestamp
            );
        }
        return true;
    }

    /**
     * @notice when unstake TAVA in SmartChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromSmartChef(address sender)
        external
        override
        onlySmartChef
        returns (bool)
    {
        ItMap storage smartchefData = smartChefBoostData[sender][msg.sender];
        if (smartchefData.stakeStarted && smartchefData.keys.length > 0) {
            delete smartChefBoostData[sender][msg.sender];
        }
        return true;
    }

    /**
     * @notice when Stake TAVA or Extend locked period in NFTChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     * @param sender: user address
     */
    function stakeFromNFTChef(address sender)
        external
        override
        onlyNFTChef
        returns (bool)
    {
        ItMap storage nftchefData = nftChefBoostData[sender][msg.sender];
        StakedInfo memory stakedInfo = stakedIds[sender];
        uint256 len = stakedInfo.tokenIds.length;
        uint256 curBlockTimestamp = block.timestamp;
        nftchefData.stakeStarted = true;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            nftchefData.insert(tokenId, curBlockTimestamp);
            // emit event
            emit NFTChefBoosterAdded(
                sender,
                msg.sender,
                tokenId,
                curBlockTimestamp
            );
        }
        return true;
    }

    /**
     * @notice when unstake TAVA in NFTChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromNFTChef(address sender)
        external
        override
        onlyNFTChef
        returns (bool)
    {
        ItMap storage nftchefData = nftChefBoostData[sender][msg.sender];
        if (nftchefData.stakeStarted && nftchefData.keys.length > 0) {
            delete nftChefBoostData[sender][msg.sender];
        }
        return true;
    }

    /**
     * @notice get registered token IDs for smartchef
     * @param sender: target address
     * @param smartchef: smartchef address
     * return timestamp array, registered count array at that ts
     */
    function getSmartChefBoostData(address sender, address smartchef)
        external
        view
        override
        returns (uint256[] memory, uint256[] memory)
    {
        ItMap storage senderData = smartChefBoostData[sender][smartchef];
        uint256[] memory tempKeys = senderData.keys;

        uint256 stakedAmount = senderData.keys.length;
        uint256[] memory tempTss = new uint256[](stakedAmount);

        uint256 tempCount = 0;
        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = tempKeys[i];
            bool isOwned = secondskinNFT.ownerOf(tokenId) == sender;
            if (isOwned) {
                uint256 ts = senderData.data[tokenId];

                tempTss[tempCount] = ts;
                tempCount++;
            }
        }

        return _removeDuplicateBasedOnTimestamp(tempTss, tempCount);
    }

    /**
     * @notice get registered token IDs for nftchef
     * @param sender: target address
     * @param nftchef: nftchef address
     */
    function getNFTChefBoostCount(address sender, address nftchef)
        external
        view
        override
        returns (uint256)
    {
        ItMap storage data = nftChefBoostData[sender][nftchef];
        uint256 stakedAmount = data.keys.length;
        uint256 tempCount = 0;

        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = data.keys[i];
            bool isOwned = secondskinNFT.ownerOf(tokenId) == sender;
            if (isOwned) {
                tempCount++;
            }
        }
        return tempCount;
    }

    /**
     * @notice get registered token IDs
     * @param sender: target address
     */
    function getStakedTokenIds(address sender)
        external
        view
        override
        returns (uint256[] memory)
    {
        StakedInfo memory stakedInfo = stakedIds[sender];
        uint256 stakedAmount = stakedInfo.tokenIds.length;
        uint256 liveStakedAmount = getStakedNFTCount(sender);
        uint256 tempCount = 0;

        uint256[] memory tokenIds = new uint256[](liveStakedAmount);

        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            bool isOwned = secondskinNFT.ownerOf(tokenId) == sender;
            if (isOwned) {
                tokenIds[tempCount] = tokenId;
                tempCount++;
            }
        }
        return tokenIds;
    }

    /**
     * @notice Get registered amount by sender
     * @param sender: target address
     */
    function getStakedNFTCount(address sender)
        public
        view
        returns (uint256 amount)
    {
        StakedInfo memory stakedInfo = stakedIds[sender];

        uint256 stakedAmount = stakedInfo.tokenIds.length;
        amount = 0;
        for (uint256 i = 0; i < stakedAmount; i++) {
            bool isOwned = secondskinNFT.ownerOf(stakedInfo.tokenIds[i]) ==
                sender;
            if (isOwned) {
                amount++;
            }
        }
    }

    /**
     * @dev In case user unhold the NFTs, they should be removed from staked info.
     */
    function _removeUnholdNFTs(address _sender) private {
        StakedInfo memory stakedInfo = stakedIds[_sender];
        uint256 len = stakedInfo.tokenIds.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            if (secondskinNFT.ownerOf(tokenId) != _sender) {
                _removeHoldNFT(_sender, tokenId);
            }
        }
    }

    function _removeHoldNFT(address _sender, uint256 _tokenId) private {
        uint256 currentIndex = _getStakedIndex(_sender, _tokenId);

        StakedInfo storage stakedInfo = stakedIds[_sender];
        uint256 lastIndex = stakedInfo.tokenIds.length - 1;

        if (lastIndex != currentIndex) {
            stakedInfo.tokenIds[currentIndex] = stakedInfo.tokenIds[lastIndex];
        }
        stakedInfo.tokenIds.pop();
        emit NFTUnstaked(_sender, _tokenId);
    }

    /**
     * @notice Register secondskin NFT token ID
     * @dev Only ID that sender holds can be registered
     * @param tokenId: secondskin NFT token ID
     */
    function _stake(uint256 tokenId) private onlyTokenOwner(tokenId) {
        address _sender = msg.sender;

        uint256 currentIndex = _getStakedIndex(_sender, tokenId);

        /// Only for unregistered NFT
        if (currentIndex == MINUS_ONE) {
            StakedInfo storage stakedInfo = stakedIds[_sender];
            stakedInfo.tokenIds.push(tokenId);

            emit NFTStaked(_sender, tokenId);
        }
    }

    /**
     * @dev return registered index
     * if tokenId has not been registered, return MAX_LIMIT
     */
    function _getStakedIndex(address _sender, uint256 _tokenId)
        private
        view
        returns (uint256)
    {
        StakedInfo memory stakedInfo = stakedIds[_sender];

        uint256 stakedAmount = stakedInfo.tokenIds.length;
        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            if (tokenId == _tokenId) {
                return i;
            }
        }
        // return out of range
        return MINUS_ONE;
    }

    /// @notice remove duplicated items and calculate duplicated counts
    /// @param inputKeys: target array
    /// return (itemValue array, itemCount array)
    function _removeDuplicateBasedOnTimestamp(
        uint256[] memory inputKeys, // timestamp
        uint256 arrayLen
    ) private pure returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tempKeys = new uint256[](arrayLen);
        uint256[] memory tempValues = new uint256[](arrayLen);

        uint256 counter1 = 0;
        for (uint256 i = 0; i < arrayLen; ) {
            uint256 counter2 = 1;
            for (uint256 j = i + 1; j < arrayLen; j++) {
                if (inputKeys[i] == inputKeys[j]) {
                    counter2++;
                } else {
                    j = arrayLen;
                }
            }

            tempKeys[counter1] = inputKeys[i];
            tempValues[counter1] = counter2;
            counter1++;

            i += counter2;
        }

        uint256[] memory rltKeys = new uint256[](counter1);
        uint256[] memory rltValues = new uint256[](counter1);
        for (uint256 i = 0; i < counter1; i++) {
            rltKeys[i] = tempKeys[i];
            rltValues[i] = tempValues[i];
            if (i > 0) {
                rltValues[i] += rltValues[i - 1];
            }
        }

        return (rltKeys, rltValues);
    }
}
