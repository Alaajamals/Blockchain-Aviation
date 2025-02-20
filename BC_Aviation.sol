// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Contract for IPFS hash storage
contract IPFSHashStorage {
    string public hydraulicSystemDataHash;

    function setHydraulicSystemDataHash(string calldata hydraulicHash) external {
        hydraulicSystemDataHash = hydraulicHash;
    }
}

// Contract for stakeholder registry
contract StakeholderRegistry {
    IPFSHashStorage public ipfsHashStorage;

    address public immutable regulatoryAuthority;
    address public maintenanceTeam;
    address public manufacturer;
    address public sparePartSupplier;
    address public timeOracle;
    address public sparePartsOracle;

    event SparePartsOracleRegistered(address sparePartsOracle);
    event StakeholdersRegistered(address regulatoryAuthority, address maintenanceTeam, address manufacturer, address sparePartSupplier);
    event TimeOracleRegistered(address timeOracle);
    event AuthorizationStatus(bool isAuthorized);

    constructor() {
        regulatoryAuthority = msg.sender;
    }

    function setupStakeholders(
        address maintenanceTeamAddr, 
        address manufacturerAddr, 
        address sparePartSupplierAddr, 
        address ipfsHashStorageAddr
    ) public {
        require(msg.sender == regulatoryAuthority, "Only the regulatory authority can setup stakeholders.");
        require(maintenanceTeamAddr != address(0), "Maintenance team address cannot be zero.");
        require(manufacturerAddr != address(0), "Manufacturer address cannot be zero.");
        require(sparePartSupplierAddr != address(0), "Spare part supplier address cannot be zero.");
        require(ipfsHashStorageAddr != address(0), "IPFS Hash Storage address cannot be zero.");

        maintenanceTeam = maintenanceTeamAddr;
        manufacturer = manufacturerAddr;
        sparePartSupplier = sparePartSupplierAddr;
        ipfsHashStorage = IPFSHashStorage(ipfsHashStorageAddr);
        
        emit StakeholdersRegistered(regulatoryAuthority, maintenanceTeam, manufacturer, sparePartSupplier);
    }

    function checkAuthorization(address stakeholder) public {
        bool isAuthorized = (
            stakeholder == maintenanceTeam || 
            stakeholder == manufacturer || 
            stakeholder == sparePartSupplier || 
            stakeholder == regulatoryAuthority
        );
        emit AuthorizationStatus(isAuthorized);
    }

    function registerSparePartsOracle(address sparePartsOracleAddr) public {
        require(msg.sender == regulatoryAuthority, "Only regulatory authority can set the spare parts oracle.");
        require(sparePartsOracleAddr != address(0), "Spare parts oracle address cannot be zero.");
        sparePartsOracle = sparePartsOracleAddr;

        emit SparePartsOracleRegistered(sparePartsOracle);
    }

    function registerTimeOracle(address timeOracleAddr) public {
        require(msg.sender == regulatoryAuthority, "Only regulatory authority can set the time oracle.");
        require(timeOracleAddr != address(0), "Time oracle address cannot be zero.");
        timeOracle = timeOracleAddr;

        emit TimeOracleRegistered(timeOracle);
    }
}

// Contract for maintenance activities with failure detection and document review
contract MaintenanceContract {
    StakeholderRegistry public immutable registry;
    string private lastMaintenanceDocumentHash;
    address private lastMaintenancePerformedBy;

    event MaintenanceAnnounced();
    event MaintenancePerformed();
    event MaintenanceCompleted();
    event MaintenanceFailureDetected();
    event AccountablePartyIdentified(address accountableParty);

    constructor(address registryAddr) {
        require(registryAddr != address(0), "Registry address cannot be the zero address.");
        registry = StakeholderRegistry(registryAddr);
    }

    function announceMaintenance() external {
        require(msg.sender == registry.timeOracle(), "Only time oracle can announce maintenance");
        emit MaintenanceAnnounced();
    }

    function performMaintenance() external {
        require(msg.sender == registry.maintenanceTeam(), "Only maintenance team can perform maintenance");
        emit MaintenancePerformed();
    }

    function completeMaintenance(string calldata documentHash) external {
        require(msg.sender == registry.maintenanceTeam(), "Only maintenance team can complete maintenance");
        lastMaintenanceDocumentHash = documentHash;
        lastMaintenancePerformedBy = msg.sender; // Store the address of the maintenance performer
        emit MaintenanceCompleted();
    }

    function detectFailureAndReviewDocuments() external {
        require(msg.sender == registry.regulatoryAuthority(), "Only regulatory authority can detect failures and review documents");
        emit MaintenanceFailureDetected();
    }

    function identifyAccountableParty(address accountableParty) external {
        require(msg.sender == registry.regulatoryAuthority(), "Only regulatory authority can identify the accountable party");
        emit AccountablePartyIdentified(accountableParty);
    }

    // function getLastMaintenanceDocumentHash() external view returns (string memory) {
    //     require(msg.sender == registry.regulatoryAuthority(), "Only regulatory authority can retrieve the maintenance document hash");
    //     return lastMaintenanceDocumentHash;
    // }
    function getLastMaintenanceDetails() external view returns (string memory documentHash, address performedBy) {
        require(msg.sender == registry.regulatoryAuthority(), "Only regulatory authority can retrieve the maintenance document details");
        return (lastMaintenanceDocumentHash, lastMaintenancePerformedBy);
    }
}

// Contract for managing spare parts
contract SparePartsContract {
    StakeholderRegistry public immutable registry;
    uint public constant criticalLevel = 10;
    uint public sparePartsCount = 5;

    event SparePartsNeeded();
    event SparePartsDispatched();

    constructor(address registryAddr) {
        require(registryAddr != address(0), "Registry address cannot be the zero address.");
        registry = StakeholderRegistry(registryAddr);
    }

    function checkAndDispatchSpareParts() external {
        require(msg.sender == registry.sparePartsOracle(), "Only the spare parts oracle can check and dispatch spare parts.");
        if (sparePartsCount < criticalLevel) {
            sparePartsCount += 10;
            emit SparePartsDispatched();
        }
    }
}
