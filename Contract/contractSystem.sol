
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title UpgradeableProxy
 * @dev Transparent proxy contract that delegates calls to implementation contracts
 */
contract UpgradeableProxy {
    // Storage slot for implementation address (to avoid storage collisions)
    bytes32 private constant IMPLEMENTATION_SLOT = keccak256("proxy.implementation");
    // Storage slot for admin address
    bytes32 private constant ADMIN_SLOT = keccak256("proxy.admin");
    
    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "Only admin can call this function");
        _;
    }
    
    /**
     * @dev Constructor sets the initial implementation and admin
     */
    constructor(address _implementation, address _admin) {
        setImplementation(_implementation);
        setAdmin(_admin);
    }
    
    /**
     * @dev Upgrade the implementation contract
     * @param newImplementation Address of the new implementation contract
     */
    function upgrade(address newImplementation) external onlyAdmin {
        require(newImplementation != address(0), "Implementation cannot be zero address");
        setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    
    /**
     * @dev Change the admin of the proxy
     * @param newAdmin Address of the new admin
     */
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Admin cannot be zero address");
        address previousAdmin = getAdmin();
        setAdmin(newAdmin);
        emit AdminChanged(previousAdmin, newAdmin);
    }
    
    /**
     * @dev Get the current implementation address
     * @return impl The implementation address
     */
    function getImplementation() external view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
    
    /**
     * @dev Get the current admin address
     * @return adm The admin address
     */
    function getAdmin() public view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    
    /**
     * @dev Fallback function that delegates calls to the implementation
     */
    fallback() external payable {
        address impl = getImplementationAddress();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
    receive() external payable {}
    
    // Internal functions
    function setImplementation(address newImplementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
    
    function setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
    }
    
    function getImplementationAddress() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}

/**
 * @title CounterV1
 * @dev First version of implementation contract - Simple counter
 */
contract CounterV1 {
    // Storage variables
    uint256 public counter;
    address public owner;
    
    // Events
    event CounterIncremented(uint256 newValue);
    event CounterDecremented(uint256 newValue);
    event CounterReset();
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Initialize the contract (replaces constructor in proxy pattern)
     */
    function initialize(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
        counter = 0;
    }
    
    /**
     * @dev Increment the counter by 1
     */
    function increment() external {
        counter += 1;
        emit CounterIncremented(counter);
    }
    
    /**
     * @dev Decrement the counter by 1
     */
    function decrement() external {
        require(counter > 0, "Counter cannot go below zero");
        counter -= 1;
        emit CounterDecremented(counter);
    }
    
    /**
     * @dev Reset counter to zero (only owner)
     */
    function reset() external onlyOwner {
        counter = 0;
        emit CounterReset();
    }
    
    /**
     * @dev Get current counter value
     */
    function getValue() external view returns (uint256) {
        return counter;
    }
}

/**
 * @title CounterV2
 * @dev Second version of implementation contract - Enhanced counter with batch operations
 */
contract CounterV2 {
    // Storage variables (must match V1 layout)
    uint256 public counter;
    address public owner;
    
    // New storage variable
    uint256 public totalOperations;
    
    // Events
    event CounterIncremented(uint256 newValue);
    event CounterDecremented(uint256 newValue);
    event CounterReset();
    event BatchOperation(string operation, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Increment the counter by 1
     */
    function increment() external {
        counter += 1;
        totalOperations += 1;
        emit CounterIncremented(counter);
    }
    
    /**
     * @dev Decrement the counter by 1
     */
    function decrement() external {
        require(counter > 0, "Counter cannot go below zero");
        counter -= 1;
        totalOperations += 1;
        emit CounterDecremented(counter);
    }
    
    /**
     * @dev Reset counter to zero (only owner)
     */
    function reset() external onlyOwner {
        counter = 0;
        totalOperations += 1;
        emit CounterReset();
    }
    
    /**
     * @dev Get current counter value
     */
    function getValue() external view returns (uint256) {
        return counter;
    }
    
    /**
     * @dev NEW FUNCTION: Increment counter by specified amount
     * @param amount Amount to increment by
     */
    function incrementBy(uint256 amount) external {
        counter += amount;
        totalOperations += 1;
        emit BatchOperation("increment", amount);
    }
}
