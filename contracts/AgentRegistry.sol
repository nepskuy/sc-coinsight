// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AgentRegistry
 * @notice Registry for AI research agents with staking and reputation
 * @dev Manages agent registration, verification, and performance tracking
 */
contract AgentRegistry is Ownable, ReentrancyGuard {
    
    // ============ Enums ============
    
    enum Specialization {
        DeFiAnalysis,
        NFTMarket,
        SecurityAudit,
        Tokenomics,
        MarketSentiment,
        WhaleTracking,
        Governance
    }
    
    // ============ Structs ============
    
    struct Agent {
        address owner;
        string name;
        Specialization specialization;
        uint256 reputationScore;
        uint256 totalCompleted;
        uint256 accuracyScore; // 0-10000 (basis points for 2 decimals)
        bool isVerified;
        uint256 stakedAmount;
        uint256 registeredAt;
        bool isActive;
    }
    
    // ============ State Variables ============
    
    uint256 public agentCount;
    uint256 public minStakeAmount = 0.1 ether;
    uint256 public verificationThreshold = 100; // Reputation needed for verification
    
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256) public ownerToAgentId;
    mapping(address => bool) public hasAgent;
    address public marketplaceContract;
    
    // ============ Events ============
    
    event AgentRegistered(
        uint256 indexed agentId,
        address indexed owner,
        string name,
        Specialization specialization,
        uint256 stakeAmount
    );
    
    event AgentVerified(uint256 indexed agentId);
    
    event ReputationUpdated(
        uint256 indexed agentId,
        uint256 oldScore,
        uint256 newScore
    );
    
    event StakeIncreased(uint256 indexed agentId, uint256 amount);
    
    event StakeWithdrawn(uint256 indexed agentId, uint256 amount);
    
    event AgentDeactivated(uint256 indexed agentId);
    
    event AgentReactivated(uint256 indexed agentId);
    
    // ============ Modifiers ============
    
    modifier onlyAgentOwner(uint256 _agentId) {
        require(
            agents[_agentId].owner == msg.sender,
            "Not agent owner"
        );
        _;
    }
    
    modifier onlyMarketplace() {
        require(
            msg.sender == marketplaceContract,
            "Only marketplace can call"
        );
        _;
    }
    
    modifier validAgentId(uint256 _agentId) {
        require(_agentId < agentCount, "Invalid agent ID");
        _;
    }
    
    // ============ Constructor ============
    
    constructor() Ownable(msg.sender) {}
    
    // ============ External Functions ============
    
    /**
     * @notice Register a new AI agent
     * @param _name Agent name
     * @param _specialization Agent specialization type
     */
    function registerAgent(
        string calldata _name,
        Specialization _specialization
    ) external payable nonReentrant {
        require(!hasAgent[msg.sender], "Already has an agent");
        require(msg.value >= minStakeAmount, "Insufficient stake");
        require(bytes(_name).length > 0, "Empty name");
        
        uint256 agentId = agentCount++;
        
        Agent storage agent = agents[agentId];
        agent.owner = msg.sender;
        agent.name = _name;
        agent.specialization = _specialization;
        agent.stakedAmount = msg.value;
        agent.registeredAt = block.timestamp;
        agent.isActive = true;
        agent.accuracyScore = 7500; // Start at 75%
        
        ownerToAgentId[msg.sender] = agentId;
        hasAgent[msg.sender] = true;
        
        emit AgentRegistered(
            agentId,
            msg.sender,
            _name,
            _specialization,
            msg.value
        );
    }
    
    /**
     * @notice Increase stake for an agent
     * @param _agentId Agent ID
     */
    function increaseStake(
        uint256 _agentId
    ) external payable validAgentId(_agentId) onlyAgentOwner(_agentId) nonReentrant {
        require(msg.value > 0, "No value sent");
        
        agents[_agentId].stakedAmount += msg.value;
        
        emit StakeIncreased(_agentId, msg.value);
    }
    
    /**
     * @notice Withdraw stake (only if agent inactive)
     * @param _agentId Agent ID
     * @param _amount Amount to withdraw
     */
    function withdrawStake(
        uint256 _agentId,
        uint256 _amount
    ) external validAgentId(_agentId) onlyAgentOwner(_agentId) nonReentrant {
        Agent storage agent = agents[_agentId];
        
        require(!agent.isActive, "Agent must be inactive");
        require(_amount <= agent.stakedAmount, "Insufficient stake");
        require(
            agent.stakedAmount - _amount >= minStakeAmount || _amount == agent.stakedAmount,
            "Must maintain minimum stake or withdraw all"
        );
        
        agent.stakedAmount -= _amount;
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit StakeWithdrawn(_agentId, _amount);
    }
    
    /**
     * @notice Update agent reputation (only marketplace)
     * @param _agentOwner Owner of the agent
     * @param _reputationDelta Change in reputation
     * @param _accuracyScore New accuracy score
     */
    function updateAgentReputation(
        address _agentOwner,
        int256 _reputationDelta,
        uint256 _accuracyScore
    ) external onlyMarketplace {
        require(hasAgent[_agentOwner], "No agent for this owner");
        
        uint256 agentId = ownerToAgentId[_agentOwner];
        Agent storage agent = agents[agentId];
        
        uint256 oldScore = agent.reputationScore;
        
        // Update reputation
        if (_reputationDelta > 0) {
            agent.reputationScore += uint256(_reputationDelta);
        } else if (_reputationDelta < 0) {
            uint256 decrease = uint256(-_reputationDelta);
            if (agent.reputationScore > decrease) {
                agent.reputationScore -= decrease;
            } else {
                agent.reputationScore = 0;
            }
        }
        
        // Update accuracy score (0-10000 basis points)
        if (_accuracyScore <= 10000) {
            agent.accuracyScore = _accuracyScore;
        }
        
        // Check for verification
        if (!agent.isVerified && agent.reputationScore >= verificationThreshold) {
            agent.isVerified = true;
            emit AgentVerified(agentId);
        }
        
        emit ReputationUpdated(agentId, oldScore, agent.reputationScore);
    }
    
    /**
     * @notice Increment completed tasks for agent
     * @param _agentOwner Owner of the agent
     */
    function incrementCompleted(address _agentOwner) external onlyMarketplace {
        require(hasAgent[_agentOwner], "No agent for this owner");
        
        uint256 agentId = ownerToAgentId[_agentOwner];
        agents[agentId].totalCompleted++;
    }
    
    /**
     * @notice Deactivate an agent
     * @param _agentId Agent ID
     */
    function deactivateAgent(
        uint256 _agentId
    ) external validAgentId(_agentId) onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        require(agent.isActive, "Already inactive");
        
        agent.isActive = false;
        
        emit AgentDeactivated(_agentId);
    }
    
    /**
     * @notice Reactivate an agent
     * @param _agentId Agent ID
     */
    function reactivateAgent(
        uint256 _agentId
    ) external validAgentId(_agentId) onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        require(!agent.isActive, "Already active");
        require(agent.stakedAmount >= minStakeAmount, "Insufficient stake");
        
        agent.isActive = true;
        
        emit AgentReactivated(_agentId);
    }
    
    // ============ View Functions ============
    
    function getAgent(
        uint256 _agentId
    ) external view validAgentId(_agentId) returns (Agent memory) {
        return agents[_agentId];
    }
    
    function getAgentByOwner(
        address _owner
    ) external view returns (Agent memory) {
        require(hasAgent[_owner], "No agent for this owner");
        return agents[ownerToAgentId[_owner]];
    }
    
    function isAgentActive(uint256 _agentId) external view returns (bool) {
        return _agentId < agentCount && agents[_agentId].isActive;
    }
    
    // ============ Admin Functions ============
    
    function setMarketplaceContract(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid address");
        marketplaceContract = _marketplace;
    }
    
    function setMinStakeAmount(uint256 _amount) external onlyOwner {
        minStakeAmount = _amount;
    }
    
    function setVerificationThreshold(uint256 _threshold) external onlyOwner {
        verificationThreshold = _threshold;
    }
    
    /**
     * @notice Slash agent stake for malicious behavior
     * @param _agentId Agent ID
     * @param _amount Amount to slash
     */
    function slashStake(
        uint256 _agentId,
        uint256 _amount
    ) external onlyOwner validAgentId(_agentId) nonReentrant {
        Agent storage agent = agents[_agentId];
        
        require(_amount <= agent.stakedAmount, "Amount exceeds stake");
        
        agent.stakedAmount -= _amount;
        
        // Reduce reputation significantly
        if (agent.reputationScore > 50) {
            agent.reputationScore -= 50;
        } else {
            agent.reputationScore = 0;
        }
        
        // Transfer slashed amount to owner
        (bool success, ) = owner().call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
