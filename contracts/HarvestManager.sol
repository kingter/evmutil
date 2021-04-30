// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Adminable {
    address public admin;
    address public pendingAdmin;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);

    constructor (address admin_) {
        admin = admin_;
        emit NewAdmin(admin);
    }

    /**
    * @dev Throws if called by any account other than the admin.
    */
    modifier onlyAdmin() {
        require(admin == msg.sender, "Adminable: caller is not the admin");
        _;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Adminable::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "Adminable::setPendingAdmin: Call must come from Timelock.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

interface HarvestContract {
    function harvest() external;
    function pause() external;
    function unpause() external;
}

contract HarvestManager is Ownable, Adminable{
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint) public harvestInterval;
    mapping (address => uint) public lastHarvest;
    uint public nextHarvestTime;
    EnumerableSet.AddressSet private _harvestAddresses;


    event RegisteredHarvestContract(address harvestContract, uint interval);
    event DeregisteredHarvestContract(address harvestContract);
    event TriggeredHarvest(address harvestContract);
    event HarvestFailed(address harvestContract, string reason);
    event PausedHarvest(address harvestContract);
    event PausedAll();
    event UnpausedHarvest(address harvestContract);

    constructor(address admin_) Adminable(admin_) {
    }

    function register(address[] calldata harvestContract_,  uint[] calldata interval_) external onlyAdmin {
        require(harvestContract_.length == interval_.length, "Value lengths do not match.");
        require(harvestContract_.length > 0, "The length is 0");
        for(uint i = 0; i < harvestContract_.length; i++) {
            require(harvestContract_[i] != address(0));
            harvestInterval[harvestContract_[i]] = interval_[i];
            _harvestAddresses.add(harvestContract_[i]);
            emit RegisteredHarvestContract(harvestContract_[i], interval_[i]);
            _setNextHarvestTime(block.timestamp + harvestInterval[harvestContract_[i]]);
        }
    }

    function harvest() external onlyAdmin returns (bool) {
        require(_harvestAddresses.length() > 0, "No harvest contract is registered.");
        uint length = _harvestAddresses.length();
        bool success = true;
        // reset nextHarvestTime
        _setNextHarvestTime(0);
        for (uint i = 0; i < length; i++) {
            address harvestAddr = _harvestAddresses.at(i);
            // no need to do harvest this time.
            if (block.timestamp < harvestInterval[harvestAddr] + lastHarvest[harvestAddr]) {
                _setNextHarvestTime(harvestInterval[harvestAddr] + lastHarvest[harvestAddr]);
                continue;
            }
            HarvestContract harvestContract = HarvestContract(harvestAddr);
            try harvestContract.harvest() {
                emit TriggeredHarvest(harvestAddr);
            } catch Error(string memory reason) {
                emit HarvestFailed(harvestAddr, reason);
                success = false;
            } catch {
                emit HarvestFailed(harvestAddr, "harvest contract encountered internal error.");
                success = false;
            }
            lastHarvest[harvestAddr] = block.timestamp;
            _setNextHarvestTime(harvestInterval[harvestAddr] + lastHarvest[harvestAddr]);
        }
        return success;
    }

    function pause(address[] calldata harvestContract_) external onlyAdmin {
        require(harvestContract_.length > 0, "length is 0.");
        for (uint i = 0; i < harvestContract_.length; i++) {
            _pause(harvestContract_[i]);
        }
    }

    function pauseAll() external onlyAdmin {
        uint length = _harvestAddresses.length();
        require(length > 0, "No harvest contract is registered.");
        for (uint i = 0; i < length; i++) {
            _pause(_harvestAddresses.at(i));
        }
        emit PausedAll();
    }

    function unpause(address[] calldata harvestContract_) external onlyAdmin {
        require(harvestContract_.length > 0, "length is 0.");
        for (uint i = 0; i < harvestContract_.length; i++) {
            require(harvestContract_[i] != address(0));
            HarvestContract harvestContract = HarvestContract(harvestContract_[i]);
            harvestContract.unpause();
            emit UnpausedHarvest(harvestContract_[i]);
        }
    }

    function deregister(address[] calldata harvestContract_) external onlyAdmin {
        require(harvestContract_.length > 0, "The length is 0");
        for(uint i = 0; i < harvestContract_.length; i++){
            require(harvestContract_[i] != address(0));

            require(_harvestAddresses.remove(harvestContract_[i]), "HarvestManager:: contract not registered");
            delete harvestInterval[harvestContract_[i]];
            delete lastHarvest[harvestContract_[i]];

            emit DeregisteredHarvestContract(harvestContract_[i]);
        }
    }

    function harvestCount() public view returns (uint) {
        return _harvestAddresses.length();
    }

    function harvestAtIndex(uint index) public view returns (address) {
        require(index < _harvestAddresses.length(), "HarvestManager:: index out of bounds");
        return _harvestAddresses.at(index);
    }

    function _pause(address harvestAddr) internal {
        require(harvestAddr != address(0));
        HarvestContract harvestContract = HarvestContract(harvestAddr);
        harvestContract.pause();
        emit PausedHarvest(harvestAddr);
    }

    function _setNextHarvestTime(uint nextHarvestTime_) internal {
        if (nextHarvestTime == 0 || nextHarvestTime > nextHarvestTime_)
            nextHarvestTime = nextHarvestTime_;
    }
}
