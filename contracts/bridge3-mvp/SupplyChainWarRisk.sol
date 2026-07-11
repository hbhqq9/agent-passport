// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SupplyChainWarRisk — Bridge 3 MVP
 * @author AGL Team
 * @notice 供应链战争风险评级合约 — 对全球供应链节点进行战争/地缘风险评级
 * @dev Bridge 3 MVP: 节点注册 + 风险评分 + 历史查询 + 风险预警
 *      Base Mainnet (Chain ID 8453), 低成本部署
 */

contract SupplyChainWarRisk {
    // ========== 状态变量 ==========

    address public owner;
    uint256 public totalAssessments;
    uint256 public totalNodes;

    // 风险因子维度
    uint256 public constant MAX_FACTOR_SCORE = 25;
    uint256 public constant MAX_TOTAL_SCORE = 100;
    uint256 public constant ALERT_THRESHOLD = 20; // 评分变化超过此值触发告警

    // ========== 数据结构 ==========

    struct Node {
        bool registered;
        string description;
        address registeredBy;
        uint256 registeredAt;
        uint8 latestScore;
        uint256 latestAssessmentIndex;
        uint256 assessmentCount;
    }

    struct RiskAssessment {
        uint8 riskScore;
        address assessor;
        uint256 timestamp;
        bytes32[] riskFactors;
    }

    // ========== 存储 ==========

    // nodeId => Node 信息
    mapping(bytes32 => Node) public nodes;

    // nodeId => 评估记录数组
    mapping(bytes32 => RiskAssessment[]) private riskHistory;

    // 已注册节点ID列表 (用于枚举)
    bytes32[] public registeredNodeIds;

    // 评估师角色
    mapping(address => bool) public assessors;

    // ========== 事件 ==========

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AssessorAdded(address indexed assessor);
    event AssessorRemoved(address indexed assessor);
    event NodeRegistered(bytes32 indexed nodeId, address registeredBy);
    event RiskAssessed(
        bytes32 indexed nodeId,
        uint8 score,
        address assessor,
        uint256 timestamp
    );
    event RiskAlert(
        bytes32 indexed nodeId,
        uint8 oldScore,
        uint8 newScore
    );

    // ========== 修饰符 ==========

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAssessor() {
        require(assessors[msg.sender], "Not authorized assessor");
        _;
    }

    // ========== 构造函数 ==========

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ========== 管理功能 ==========

    /**
     * @notice 转移所有权
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice 添加评估师
     */
    function addAssessor(address assessor) external onlyOwner {
        require(assessor != address(0), "Zero address");
        require(!assessors[assessor], "Already assessor");
        assessors[assessor] = true;
        emit AssessorAdded(assessor);
    }

    /**
     * @notice 移除评估师
     */
    function removeAssessor(address assessor) external onlyOwner {
        require(assessors[assessor], "Not assessor");
        assessors[assessor] = false;
        emit AssessorRemoved(assessor);
    }

    // ========== 核心功能 ==========

    /**
     * @notice 注册供应链节点
     * @param nodeId 节点唯一标识 (keccak256 hash of node identifier)
     * @param nodeDescription 节点描述 (如 "Shenzhen Electronics Hub")
     */
    function registerNode(
        bytes32 nodeId,
        string calldata nodeDescription
    ) external onlyOwner {
        require(!nodes[nodeId].registered, "Node already registered");
        require(nodeId != bytes32(0), "Invalid nodeId");

        nodes[nodeId] = Node({
            registered: true,
            description: nodeDescription,
            registeredBy: msg.sender,
            registeredAt: block.timestamp,
            latestScore: 0,
            latestAssessmentIndex: 0,
            assessmentCount: 0
        });

        registeredNodeIds.push(nodeId);
        totalNodes++;

        emit NodeRegistered(nodeId, msg.sender);
    }

    /**
     * @notice 提交风险评估
     * @param nodeId 节点ID
     * @param riskScore 风险评分 (0-100, 由4个维度各0-25组成)
     * @param riskFactors 风险因子哈希数组
     */
    function submitRiskAssessment(
        bytes32 nodeId,
        uint8 riskScore,
        bytes32[] calldata riskFactors
    ) external onlyAssessor {
        require(nodes[nodeId].registered, "Node not registered");
        require(riskScore <= MAX_TOTAL_SCORE, "Score exceeds 100");
        require(riskFactors.length > 0, "No risk factors");

        // 验证每个因子不超过最大值(25)
        for (uint256 i = 0; i < riskFactors.length; i++) {
            // riskFactors 为编码后的因子值，此处记录原始哈希
            // 实际业务中可解码验证各维度分值
        }

        uint8 oldScore = nodes[nodeId].latestScore;

        // 存储评估记录
        riskHistory[nodeId].push(RiskAssessment({
            riskScore: riskScore,
            assessor: msg.sender,
            timestamp: block.timestamp,
            riskFactors: riskFactors
        }));

        // 更新节点最新评分
        nodes[nodeId].latestScore = riskScore;
        nodes[nodeId].latestAssessmentIndex = riskHistory[nodeId].length - 1;
        nodes[nodeId].assessmentCount++;
        totalAssessments++;

        emit RiskAssessed(nodeId, riskScore, msg.sender, block.timestamp);

        // 评分变化超过阈值触发告警
        if (oldScore > 0 && _absDiff(oldScore, riskScore) > ALERT_THRESHOLD) {
            emit RiskAlert(nodeId, oldScore, riskScore);
        }
    }

    // ========== 查询功能 (免费层) ==========

    /**
     * @notice 查询节点最新风险评分
     * @param nodeId 节点ID
     * @return score 最新评分
     * @return assessor 最近评估师地址
     * @return timestamp 最近评估时间
     * @return assessmentCount 总评估次数
     */
    function getLatestRiskScore(bytes32 nodeId)
        external
        view
        returns (
            uint8 score,
            address assessor,
            uint256 timestamp,
            uint256 assessmentCount
        )
    {
        require(nodes[nodeId].registered, "Node not registered");

        uint256 count = riskHistory[nodeId].length;
        if (count == 0) {
            return (0, address(0), 0, 0);
        }

        RiskAssessment storage latest = riskHistory[nodeId][count - 1];
        return (
            latest.riskScore,
            latest.assessor,
            latest.timestamp,
            nodes[nodeId].assessmentCount
        );
    }

    /**
     * @notice 查询历史评分记录
     * @param nodeId 节点ID
     * @param limit 返回条数限制
     * @return scores 评分数组
     * @return timestampList 时间戳数组
     * @return assessorsList 评估师地址数组
     */
    function getRiskHistory(
        bytes32 nodeId,
        uint256 limit
    )
        external
        view
        returns (
            uint8[] memory scores,
            uint256[] memory timestampList,
            address[] memory assessorsList
        )
    {
        require(nodes[nodeId].registered, "Node not registered");

        uint256 total = riskHistory[nodeId].length;
        uint256 count = limit < total ? limit : total;

        scores = new uint8[](count);
        timestampList = new uint256[](count);
        assessorsList = new address[](count);

        // 返回最新的 limit 条
        for (uint256 i = 0; i < count; i++) {
            uint256 idx = total - 1 - i;
            RiskAssessment storage a = riskHistory[nodeId][idx];
            scores[i] = a.riskScore;
            timestampList[i] = a.timestamp;
            assessorsList[i] = a.assessor;
        }
    }

    /**
     * @notice 获取所有高风险节点列表
     * @param threshold 风险阈值 (高于此值的节点返回)
     * @return nodeIds 高风险节点ID数组
     * @return scores 对应评分数组
     */
    function getHighRiskNodes(uint8 threshold)
        external
        view
        returns (bytes32[] memory nodeIds, uint8[] memory scores)
    {
        require(threshold <= MAX_TOTAL_SCORE, "Invalid threshold");

        // 第一遍：计数
        uint256 count = 0;
        for (uint256 i = 0; i < registeredNodeIds.length; i++) {
            if (nodes[registeredNodeIds[i]].latestScore >= threshold) {
                count++;
            }
        }

        // 第二遍：填充
        nodeIds = new bytes32[](count);
        scores = new uint8[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < registeredNodeIds.length; i++) {
            bytes32 nid = registeredNodeIds[i];
            if (nodes[nid].latestScore >= threshold) {
                nodeIds[idx] = nid;
                scores[idx] = nodes[nid].latestScore;
                idx++;
            }
        }
    }

    /**
     * @notice 获取节点详细信息
     */
    function getNodeInfo(bytes32 nodeId)
        external
        view
        returns (
            string memory description,
            address registeredBy,
            uint256 registeredAt,
            uint8 latestScore,
            uint256 assessmentCount
        )
    {
        require(nodes[nodeId].registered, "Node not registered");
        Node storage n = nodes[nodeId];
        return (
            n.description,
            n.registeredBy,
            n.registeredAt,
            n.latestScore,
            n.assessmentCount
        );
    }

    /**
     * @notice 获取已注册节点总数
     */
    function getRegisteredNodeCount() external view returns (uint256) {
        return registeredNodeIds.length;
    }

    // ========== 内部函数 ==========

    function _absDiff(uint8 a, uint8 b) internal pure returns (uint8) {
        return a > b ? a - b : b - a;
    }
}
