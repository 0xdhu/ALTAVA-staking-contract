//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IterateMapping.sol";

/**
 * @notice BoosterController for smartchef contract
 */
contract BoosterController is Ownable {
    using IterableMapping for ItMap;

    /// @dev use this struct to get param in setBoosterArray and setBoosterValue
    struct BoosterStruct {
        uint256 key; // staked/registered secondskin NFT amount
        uint256 apr; // boosted APR
    }

    /// @notice APR is based on yearly. But it cannot be over 500%
    uint256 public constant MAX_BOOSTER_VALUE = 50000; // 500% in 365 days APR
    /// @notice Maximum limit to set booster key-value pair
    /// @dev this is needed to avoid gas limit
    uint256 public constant MAX_BOOSTER_OPTION = 10; // key-value pair limit

    /// @dev smartchef address => booster key-aprs
    /// Here, key means amount of registered secondskin NFT in nftstaking contract
    mapping(address => ItMap) private _smartchefBooster;

    /// @notice whenever booster data is updated, this event is emitted
    /// @param sender: this should be owner/signer
    /// @param smartchef: smartchef contract address
    /// @param nftAmount: means registered secondskin NFT amount
    /// @param boosterAPR: booster APR based on nftAmount
    event BoosterUpdated(
        address sender,
        address smartchef,
        uint256 nftAmount,
        uint256 boosterAPR
    );

    /// @notice whenever booster data is removed, this event is emitted
    /// @param sender: this should be owner/signer
    /// @param smartchef: smartchef contract address
    /// @param nftAmount: means registered secondskin NFT amount
    event BoosterDeleted(address sender, address smartchef, uint256 nftAmount);

    /**
     * @notice set Booster rate in array
     * @dev index of booster is registered secondskin NFT amount
     * @param _boosters: array of booster rates.
     * @param _smartchef: SmartChef contract address
     */
    function setBoosterArray(
        BoosterStruct[] calldata _boosters,
        address _smartchef
    ) external onlyOwner {
        require(_smartchef != address(0x0), "Cannot be zero address");

        uint256 arraySize = _boosters.length;
        require(arraySize > 0, "Invalid inputs");

        for (uint256 i = 0; i < arraySize; i++) {
            BoosterStruct memory _booster = _boosters[i];
            _setBoosterValue(_booster, _smartchef);
        }
    }

    /**
     * @dev set booster APR on key
     * Here, key means amount of registered secondskin NFT in nftstaking contract
     * @param _booster: array of booster rates.
     * @param _smartchef: SmartChef contract address
     */
    function setBoosterValue(
        BoosterStruct memory _booster,
        address _smartchef
    ) external onlyOwner {
        require(_smartchef != address(0x0), "Cannot be zero address");

        _setBoosterValue(_booster, _smartchef);
    }

    /**
     * @notice remove booster key-apr pair
     * @param _key: registered secondskin NFT amount
     * @param _smartchef: SmartChef contract
     */
    function removeBoosterValue(
        uint256 _key,
        address _smartchef
    ) external onlyOwner {
        require(_smartchef != address(0x0), "Cannot be zero address");
        ItMap storage smartchefBooster = _smartchefBooster[_smartchef];
        smartchefBooster.remove(_key);

        emit BoosterDeleted(_msgSender(), _smartchef, _key);
    }

    /**
     * @notice get Booster APR
     * @dev return APR based on registered secondskin NFT amount
     * @param _key: registered secondskin NFT amount
     * @param _smartchef: SmartChef contract
     */
    function getBoosterAPR(
        uint256 _key,
        address _smartchef
    ) external view returns (uint256) {
        ItMap storage smartchefBooster = _smartchefBooster[_smartchef];
        if (smartchefBooster.contains(_key)) {
            return smartchefBooster.data[_key];
        }
        uint256[] memory keys = smartchefBooster.keys;

        (uint256 topKey, uint256 bottomKey) = _getTopDownKeys(keys, _key);

        if (topKey < 10000) {
            return smartchefBooster.data[topKey];
        } else if (bottomKey > 0) {
            return smartchefBooster.data[bottomKey];
        } else return 0;
    }

    /**
     * @notice Get sorted array for booster key-values
     */
    function getBoosterKeysValues(
        address _smartchef
    ) external view returns (BoosterStruct[] memory boosterData) {
        ItMap storage smartchefBooster = _smartchefBooster[_smartchef];

        uint256[] memory keys = smartchefBooster.keys;
        uint256 keySize = keys.length;
        if (keySize > 0) {
            _quickSort(keys, int(0), int(keys.length - 1));
        }

        boosterData = new BoosterStruct[](keySize);
        for (uint256 i = 0; i < keySize; i++) {
            uint256 key = keys[i];
            uint256 apr = smartchefBooster.data[key];
            boosterData[i] = BoosterStruct(key, apr);
        }
    }

    /**
     * @notice Get total number of booster key-apr array
     * @param _smartchef: SmartChef contract address
     */
    function getTotalPairCount(
        address _smartchef
    ) external view returns (uint256) {
        ItMap storage smartchefBooster = _smartchefBooster[_smartchef];
        return smartchefBooster.keys.length;
    }

    /**
     * @dev set booster APR based on key
     */
    function _setBoosterValue(
        BoosterStruct memory _booster,
        address _smartchef
    ) private {
        uint256 key = _booster.key;
        uint256 apr = _booster.apr;
        require(key > 0 && apr > 0, "Inputs cannot be zero");
        require(apr < MAX_BOOSTER_VALUE, "Booster rate: overflow max");

        ItMap storage smartchefBooster = _smartchefBooster[_smartchef];
        require(
            smartchefBooster.keys.length < MAX_BOOSTER_OPTION,
            "Limit max booster pair"
        );

        uint256[] memory keys = smartchefBooster.keys;
        (uint256 topKey, uint256 bottomKey) = _getTopDownKeys(keys, key);

        if (topKey != 10000) {
            uint256 topAPR = smartchefBooster.data[topKey];
            require(topAPR > apr, "Booster value: invalid");
        }
        if (bottomKey != 0) {
            uint256 bottomAPR = smartchefBooster.data[bottomKey];
            require(bottomAPR < apr, "Booster value: invalid");
        }

        smartchefBooster.insert(key, apr);

        emit BoosterUpdated(_msgSender(), _smartchef, key, apr);
    }

    /// @notice return sorted Array as increased
    /// @dev quicksort algorithm to sort array
    function _quickSort(uint[] memory arr, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    // Return top and down keys based on main key in array
    function _getTopDownKeys(
        uint256[] memory keys,
        uint256 _key
    ) private pure returns (uint256, uint256) {
        uint256 keySize = keys.length;
        uint256 maxKey = 10000; // secondskin NFT supply is less than 10,000
        uint256 minKey = 0; // secondskin NFT supply is less than 10,000
        for (uint256 i = 0; i < keySize; i++) {
            if (keys[i] > _key && keys[i] < maxKey) {
                maxKey = keys[i];
            }

            if (keys[i] < _key && keys[i] > minKey) {
                minKey = keys[i];
            }
        }
        return (maxKey, minKey);
    }
}
