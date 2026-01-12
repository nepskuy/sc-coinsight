// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ResearchMarketplace
 * @notice Decentralized marketplace for on-chain research requests and reports
 * @dev Manages research requests, bounties, and report submissions
 */
contract ResearchMarketplace is Ownable, ReentrancyGuard, Pausable {
    
    // ============ Enums ============
    
    enum RequestStatus {
        Pending,
        InProgress,
        Completed,
        Cancelled,
        Disputed
    }
    
    enum ReportStatus {
        Submitted,
        Selected,
        Rejected,
        Disputed
    }
    
    // ============ Structs ============
    
    struct ResearchRequest {
        uint256 id;
        address requester;
        string query;
        uint256 bounty;
        uint256 deadline;
        RequestStatus status;
        uint256[] submittedReports;
        uint256 selectedReport;
        uint256 createdAt;
    }
    
    struct ResearchReport {
        uint256 id;
        address researcher;
        uint256 requestId;
        string ipfsHash;
        bytes32 commitment;
        uint256 stakeAmount;
        ReportStatus status;
        uint256 createdAt;
    }
    
    // ============ State Variables ============
    
    uint256 public requestCount;
    uint256 public reportCount;
    uint256 public minBounty = 0.01 ether;
    uint256 public minStake = 0.005 ether;
    uint256 public platformFeePercentage = 5; // 5%
    uint256 public accumulatedFees;
    
    mapping(uint256 => ResearchRequest) public requests;
    mapping(uint256 => ResearchReport) public reports;
    mapping(address => uint256) public researcherReputation;
    mapping(uint256 => mapping(address => bool)) public hasSubmitted;
    
    // ============ Events ============
    
    event RequestCreated(
        uint256 indexed requestId,
        address indexed requester,
        string query,
        uint256 bounty,
        uint256 deadline
    );
    
    event ReportSubmitted(
        uint256 indexed reportId,
        uint256 indexed requestId,
        address indexed researcher,
        string ipfsHash
    );
    
    event ReportSelected(
        uint256 indexed requestId,
        uint256 indexed reportId,
        address researcher,
        uint256 reward
    );
    
    event RequestCancelled(uint256 indexed requestId);
    
    event DisputeRaised(
        uint256 indexed reportId,
        address indexed disputer
    );
    
    event StakeSlashed(
        address indexed researcher,
        uint256 amount
    );
    
    // ============ Modifiers ============
    
    modifier validRequest(uint256 _requestId) {
        require(_requestId < requestCount, "Invalid request ID");
        _;
    }
    
    modifier validReport(uint256 _reportId) {
        require(_reportId < reportCount, "Invalid report ID");
        _;
    }
    
    modifier onlyRequester(uint256 _requestId) {
        require(
            requests[_requestId].requester == msg.sender,
            "Not the requester"
        );
        _;
    }
    
    // ============ Constructor ============
    
    constructor() Ownable(msg.sender) {}
    
    // ============ External Functions ============
    
    /**
     * @notice Create a new research request
     * @param _query Research query description
     * @param _deadline Deadline timestamp for submissions
     */
    function createRequest(
        string calldata _query,
        uint256 _deadline
    ) external payable whenNotPaused nonReentrant {
        require(msg.value >= minBounty, "Bounty below minimum");
        require(_deadline > block.timestamp, "Invalid deadline");
        require(bytes(_query).length > 0, "Empty query");
        
        uint256 requestId = requestCount++;
        
        ResearchRequest storage request = requests[requestId];
        request.id = requestId;
        request.requester = msg.sender;
        request.query = _query;
        request.bounty = msg.value;
        request.deadline = _deadline;
        request.status = RequestStatus.Pending;
        request.createdAt = block.timestamp;
        
        emit RequestCreated(
            requestId,
            msg.sender,
            _query,
            msg.value,
            _deadline
        );
    }
    
    /**
     * @notice Submit a research report for a request
     * @param _requestId ID of the research request
     * @param _ipfsHash IPFS hash of the report
     * @param _commitment Hash commitment of findings
     */
    function submitReport(
        uint256 _requestId,
        string calldata _ipfsHash,
        bytes32 _commitment
    ) external payable validRequest(_requestId) whenNotPaused nonReentrant {
        ResearchRequest storage request = requests[_requestId];
        
        require(
            request.status == RequestStatus.Pending ||
            request.status == RequestStatus.InProgress,
            "Request not accepting submissions"
        );
        require(block.timestamp < request.deadline, "Deadline passed");
        require(msg.value >= minStake, "Stake below minimum");
        require(
            !hasSubmitted[_requestId][msg.sender],
            "Already submitted"
        );
        require(bytes(_ipfsHash).length > 0, "Empty IPFS hash");
        
        uint256 reportId = reportCount++;
        
        ResearchReport storage report = reports[reportId];
        report.id = reportId;
        report.researcher = msg.sender;
        report.requestId = _requestId;
        report.ipfsHash = _ipfsHash;
        report.commitment = _commitment;
        report.stakeAmount = msg.value;
        report.status = ReportStatus.Submitted;
        report.createdAt = block.timestamp;
        
        request.submittedReports.push(reportId);
        hasSubmitted[_requestId][msg.sender] = true;
        
        if (request.status == RequestStatus.Pending) {
            request.status = RequestStatus.InProgress;
        }
        
        emit ReportSubmitted(reportId, _requestId, msg.sender, _ipfsHash);
    }
    
    /**
     * @notice Select winning report for a request
     * @param _requestId ID of the research request
     * @param _reportId ID of the selected report
     */
    function selectReport(
        uint256 _requestId,
        uint256 _reportId
    )
        external
        validRequest(_requestId)
        validReport(_reportId)
        onlyRequester(_requestId)
        nonReentrant
    {
        ResearchRequest storage request = requests[_requestId];
        ResearchReport storage report = reports[_reportId];
        
        require(
            request.status == RequestStatus.InProgress,
            "Invalid request status"
        );
        require(report.requestId == _requestId, "Report not for this request");
        require(
            report.status == ReportStatus.Submitted,
            "Invalid report status"
        );
        
        // Calculate platform fee
        uint256 fee = (request.bounty * platformFeePercentage) / 100;
        uint256 reward = request.bounty - fee;
        
        // Update states
        request.status = RequestStatus.Completed;
        request.selectedReport = _reportId;
        report.status = ReportStatus.Selected;
        
        // Update researcher reputation
        researcherReputation[report.researcher] += 10;
        
        // Accumulate fees
        accumulatedFees += fee;
        
        // Transfer reward + stake back to researcher
        uint256 totalPayout = reward + report.stakeAmount;
        
        (bool success, ) = report.researcher.call{value: totalPayout}("");
        require(success, "Transfer failed");
        
        emit ReportSelected(_requestId, _reportId, report.researcher, reward);
    }
    
    /**
     * @notice Cancel a research request (only if no submissions)
     * @param _requestId ID of the research request
     */
    function cancelRequest(
        uint256 _requestId
    ) external validRequest(_requestId) onlyRequester(_requestId) nonReentrant {
        ResearchRequest storage request = requests[_requestId];
        
        require(
            request.status == RequestStatus.Pending,
            "Cannot cancel request with submissions"
        );
        require(
            request.submittedReports.length == 0,
            "Has submissions"
        );
        
        request.status = RequestStatus.Cancelled;
        
        // Refund bounty to requester
        (bool success, ) = request.requester.call{value: request.bounty}("");
        require(success, "Refund failed");
        
        emit RequestCancelled(_requestId);
    }
    
    /**
     * @notice Raise dispute for a selected report
     * @param _reportId ID of the report
     */
    function raiseDispute(
        uint256 _reportId
    ) external payable validReport(_reportId) {
        ResearchReport storage report = reports[_reportId];
        ResearchRequest storage request = requests[report.requestId];
        
        require(
            report.status == ReportStatus.Selected,
            "Report not selected"
        );
        require(
            msg.sender == request.requester ||
            hasSubmitted[report.requestId][msg.sender],
            "Not authorized to dispute"
        );
        
        report.status = ReportStatus.Disputed;
        request.status = RequestStatus.Disputed;
        
        emit DisputeRaised(_reportId, msg.sender);
    }
    
    /**
     * @notice Return stake to rejected researchers after selection
     * @param _reportId ID of the report
     */
    function returnStake(
        uint256 _reportId
    ) external validReport(_reportId) nonReentrant {
        ResearchReport storage report = reports[_reportId];
        ResearchRequest storage request = requests[report.requestId];
        
        require(msg.sender == report.researcher, "Not the researcher");
        require(
            request.status == RequestStatus.Completed,
            "Request not completed"
        );
        require(
            report.status == ReportStatus.Submitted,
            "Report was selected or disputed"
        );
        require(report.stakeAmount > 0, "Stake already returned");
        
        uint256 stakeToReturn = report.stakeAmount;
        report.stakeAmount = 0;
        
        (bool success, ) = msg.sender.call{value: stakeToReturn}("");
        require(success, "Transfer failed");
    }
    
    // ============ View Functions ============
    
    function getRequest(
        uint256 _requestId
    ) external view validRequest(_requestId) returns (ResearchRequest memory) {
        return requests[_requestId];
    }
    
    function getReport(
        uint256 _reportId
    ) external view validReport(_reportId) returns (ResearchReport memory) {
        return reports[_reportId];
    }
    
    function getRequestReports(
        uint256 _requestId
    ) external view validRequest(_requestId) returns (uint256[] memory) {
        return requests[_requestId].submittedReports;
    }
    
    // ============ Admin Functions ============
    
    function setMinBounty(uint256 _minBounty) external onlyOwner {
        minBounty = _minBounty;
    }
    
    function setMinStake(uint256 _minStake) external onlyOwner {
        minStake = _minStake;
    }
    
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10, "Fee too high");
        platformFeePercentage = _feePercentage;
    }
    
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Slash stake for malicious behavior (only owner)
     * @param _reportId ID of the report
     */
    function slashStake(
        uint256 _reportId
    ) external onlyOwner validReport(_reportId) nonReentrant {
        ResearchReport storage report = reports[_reportId];
        
        require(
            report.status == ReportStatus.Disputed,
            "Report not disputed"
        );
        require(report.stakeAmount > 0, "No stake to slash");
        
        uint256 slashedAmount = report.stakeAmount;
        report.stakeAmount = 0;
        report.status = ReportStatus.Rejected;
        
        // Reduce researcher reputation
        if (researcherReputation[report.researcher] >= 5) {
            researcherReputation[report.researcher] -= 5;
        } else {
            researcherReputation[report.researcher] = 0;
        }
        
        // Add slashed amount to platform fees
        accumulatedFees += slashedAmount;
        
        emit StakeSlashed(report.researcher, slashedAmount);
    }
}
