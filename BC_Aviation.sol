// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Contract for IPFS hash storage
contract IPFSHashStorage {
    string public hydraulicSystemDataHash; // Stores the IPFS hash of hydraulic system data

    function setHydraulicSystemDataHash(string calldata hydraulicHash) external {
        hydraulicSystemDataHash = hydraulicHash; // Updates the IPFS hash with the provided value
    }
}

// Contract for stakeholder registry
contract StakeholderRegistry {
    IPFSHashStorage public ipfsHashStorage; // Reference to the IPFS hash storage contract

    address public immutable regulatoryAuthority; // Stores the address of the regulatory authority (unchangeable after deployment)
    address public maintenanceTeam; // Stores the address of the maintenance team
    address public manufacturer; // Stores the address of the manufacturer
    address public sparePartSupplier; // Stores the address of the spare parts supplier
    address public timeOracle; // Stores the address of the time oracle
    address public sparePartsOracle; // Stores the address of the spare parts oracle

    event SparePartsOracleRegistered(address sparePartsOracle); // Event emitted when a spare parts oracle is registered
    event StakeholdersRegistered(address regulatoryAuthority, address maintenanceTeam, address manufacturer, address sparePartSupplier); // Event emitted when stakeholders are set
    event TimeOracleRegistered(address timeOracle); // Event emitted when a time oracle is registered
    event AuthorizationStatus(bool isAuthorized); // Event emitted to indicate if an address is authorized

    constructor() {
        regulatoryAuthority = msg.sender; // Sets the contract deployer as the regulatory authority
    }

    function setupStakeholders(
        address maintenanceTeamAddr, 
        address manufacturerAddr, 
        address sparePartSupplierAddr, 
        address ipfsHashStorageAddr
    ) public {
        require(msg.sender == regulatoryAuthority, "Only the regulatory authority can setup stakeholders."); // Ensures only the regulatory authority can set stakeholders
        require(maintenanceTeamAddr != address(0), "Maintenance team address cannot be zero."); // Prevents setting an invalid address
        require(manufacturerAddr != address(0), "Manufacturer address cannot be zero.");
        require(sparePartSupplierAddr != address(0), "Spare part supplier address cannot be zero.");
        require(ipfsHashStorageAddr != address(0), "IPFS Hash Storage address cannot be zero.");

        maintenanceTeam = maintenanceTeamAddr; // Assigns the maintenance team
        manufacturer = manufacturerAddr; // Assigns the manufacturer
        sparePartSupplier = sparePartSupplierAddr; // Assigns the spare parts supplier
        ipfsHashStorage = IPFSHashStorage(ipfsHashStorageAddr); // Links the IPFS storage contract

        emit StakeholdersRegistered(regulatoryAuthority, maintenanceTeam, manufacturer, sparePartSupplier); // Emits an event after stakeholders are set
    }

    function checkAuthorization(address stakeholder) public {
        bool isAuthorized = (
            stakeholder == maintenanceTeam || 
            stakeholder == manufacturer || 
            stakeholder == sparePartSupplier || 
            stakeholder == regulatoryAuthority
        ); // Checks if the provided address belongs to a stakeholder
        emit AuthorizationStatus(isAuthorized); // Emits an event indicating authorization status
    }

    function registerSparePartsOracle(address sparePartsOracleAddr) public {
        require(msg.sender == regulatoryAuthority, "Only regulatory authority can set the spare parts oracle."); // Ensures only the regulatory authority can set the oracle
        require(sparePartsOracleAddr != address(0), "Spare parts oracle address cannot be zero."); // Prevents setting an invalid address
        sparePartsOracle = sparePartsOracleAddr; // Assigns the spare parts oracle

        emit SparePartsOracleRegistered(sparePartsOracle); // Emits an event after registration
    }

    function registerTimeOracle(address timeOracleAddr) public {
        require(msg.sender == regulatoryAuthority, "Only regulatory authority can set the time oracle."); // Ensures only the regulatory authority can set the oracle
        require(timeOracleAddr != address(0), "Time oracle address cannot be zero."); // Prevents setting an invalid address
        timeOracle = timeOracleAddr; // Assigns the time oracle

        emit TimeOracleRegistered(timeOracle); // Emits an event after registration
    }
}

// Contract for maintenance activities with failure detection and document review
contract MaintenanceContract {
    StakeholderRegistry public immutable registry; // Stores a reference to the StakeholderRegistry contract
    string private lastMaintenanceDocumentHash; // Stores the IPFS hash of the last maintenance document
    address private lastMaintenancePerformedBy; // Stores the address of the last maintenance performer

    event MaintenanceAnnounced(); // Event emitted when maintenance is announced
    event MaintenancePerformed(); // Event emitted when maintenance is performed
    event MaintenanceCompleted(); // Event emitted when maintenance is completed
    event MaintenanceFailureDetected(); // Event emitted when a failure is detected
    event AccountablePartyIdentified(address accountableParty); // Event emitted when an accountable party is identified

    constructor(address registryAddr) {
        require(registryAddr != address(0), "Registry address cannot be the zero address."); // Ensures the registry address is valid
        registry = StakeholderRegistry(registryAddr); // Assigns the registry contract
    }

    function announceMaintenance() external {
        require(msg.sender == registry.timeOracle(), "Only time oracle can announce maintenance"); // Ensures only the time oracle can announce maintenance
        emit MaintenanceAnnounced(); // Emits an event
    }

    function performMaintenance() external {
        require(msg.sender == registry.maintenanceTeam(), "Only maintenance team can perform maintenance"); // Ensures only the maintenance team can perform maintenance
        emit MaintenancePerformed(); // Emits an event
    }

    function completeMaintenance(string calldata documentHash) external {
        require(msg.sender == registry.maintenanceTeam(), "Only maintenance team can complete maintenance"); // Ensures only the maintenance team can complete maintenance
        lastMaintenanceDocumentHash = documentHash; // Stores the maintenance document hash
        lastMaintenancePerformedBy = msg.sender; // Stores the address of the maintenance performer
        emit MaintenanceCompleted(); // Emits an event
    }

    function detectFailureAndReviewDocuments() external {
        require(msg.sender == registry.regulatoryAuthority(), "Only regulatory authority can detect failures and review documents"); // Ensures only the regulatory authority can detect failures
        emit MaintenanceFailureDetected(); // Emits an event
    }

    function identifyAccountableParty(address accountableParty) external {
        require(msg.sender == registry.regulatoryAuthority(), "Only regulatory authority can identify the accountable party"); // Ensures only the regulatory authority can assign accountability
        emit AccountablePartyIdentified(accountableParty); // Emits an event
    }

    function getLastMaintenanceDetails() external view returns (string memory documentHash, address performedBy) {
        require(msg.sender == registry.regulatoryAuthority(), "Only regulatory authority can retrieve the maintenance document details"); // Ensures only the regulatory authority can access maintenance details
        return (lastMaintenanceDocumentHash, lastMaintenancePerformedBy); // Returns the last maintenance details
    }
}

// Contract for managing spare parts
contract SparePartsContract {
    StakeholderRegistry public immutable registry; // Stores a reference to the StakeholderRegistry contract
    uint public constant criticalLevel = 10; // Defines the minimum threshold for spare parts
    uint public sparePartsCount = 5; // Stores the current spare parts count

    event SparePartsNeeded(); // Event emitted when spare parts are required
    event SparePartsDispatched(); // Event emitted when spare parts are dispatched

    constructor(address registryAddr) {
        require(registryAddr != address(0), "Registry address cannot be the zero address."); // Ensures the registry address is valid
        registry = StakeholderRegistry(registryAddr); // Assigns the registry contract
    }

    function checkAndDispatchSpareParts() external {
        require(msg.sender == registry.sparePartsOracle(), "Only the spare parts oracle can check and dispatch spare parts."); // Ensures only the spare parts oracle can trigger spare parts dispatch
        if (sparePartsCount < criticalLevel) { // Checks if the spare parts count is below the critical level
            sparePartsCount += 10; // Refills the spare parts count
            emit SparePartsDispatched(); // Emits an event
        }
    }
}

