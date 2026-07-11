# 供应链战争风险实时评级系统白皮书

**基于 CompliancePassport 合约架构的链上韧性证书体系**

> 版本 1.0 | 2026-07-11

---

## 摘要

**霍尔木兹海峡正经历自 1980 年代以来最严重的通行中断。** 战前日均通行 125–140 艘，2026 年 7 月降至不足正常吞吐量的 2%，仅 48 小时窗口内记录到 2 艘通行 [(National Security Journal)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/) [(Discovery Alert)](https://discoveryalert.com.au/strait-hormuz-tanker-traffic-standstill-oil-supply-crisis/)。VLCC 中东-中国航线 TCE 飙升至 **$296,175/天**，较战前水平翻倍以上 [(Lloyd's List)](https://www.lloydslist.com/LL1157747/VLCCs-and-suezmaxes-riding-high-as-peace-deal-hikes-Hormuz-flows)；船舶战争险费率从船体价值的 0.25% 暴涨至峰值 10%，目前仍在 2%–6% 区间 [(新华网)](http://www.xinhuanet.com/fortune/20260711/e5a0070252ee42faa74cea3b4f694b50/c.html) [(gCaptain/Bloomberg)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/)。然而，全球尚无任何链上解决方案能将地缘风险数据实时转化为可验证的供应链韧性凭证。地缘风险分析平台市场规模 2025 年为 **$40.2 亿**，预计 2035 年达 **$152.6 亿**（CAGR 14.30%）[(SNS Insider)](https://www.snsinsider.com/press-release/global-geopolitical-risk-analytics-platform-market)，但现有参与者（Resilinc、Interos、Everstream）均为传统 SaaS 架构，无链上验证层。

**本白皮书提出将 CompliancePassport 合约的「评分→证书→验证」链路扩展至供应链战争风险评级场景。** 核心映射：`agentId` → `supplyChainRouteId` / `companyId`；风险评分输入源从 AI Agent 行为数据切换为地缘风险实时数据流（AIS 船舶追踪、油价 API、网络安全威胁情报、保险费率）；输出从合规等级变为「韧性证书」（Resilience Certificate, Level 1–5）。这是全球首个将战争风险评级锚定在区块链上的可验证凭证体系——当一枚导弹击中海峡中的 LNG 运输船，评级在分钟级更新，韧性证书随之重签或撤销。

---

## 1. 市场背景与机会规模

### 1.1 霍尔木兹危机：实时数据印证的系统性断裂

霍尔木兹海峡承载全球约五分之一的石油海运贸易和约 25% 的 LNG 贸易 [(Discovery Alert)](https://discoveryalert.com.au/strait-hormuz-tanker-traffic-standstill-oil-supply-crisis/)。2026 年 2 月 28 日美以联合对伊朗发动袭击后，这条 33 公里宽的咽喉水道在数日内从全球贸易动脉变为战争禁区。

| 指标 | 战前基线 | 当前状态 | 变化幅度 |
|------|----------|----------|----------|
| 日均通行量 | 125–140 艘/天 | <2% 正常吞吐量（7 月 9 日仅 2 艘/48h） | **↓ >98%** |
| 恢复期日均 | — | ~40 艘/天（6 月 MOU 后） | 仍 <1/3 正常 |
| 日本商船队在湾内 | ~45 艘 | 4 艘 | **↓ 91%** |
| VLCC TCE（中东-中国） | ~$90K–100K/天 | $296,175/天 | **↑ 3×** |
| 战争险费率 | 0.25% 船体价值/7天 | 2%–6%（峰值 10%） | **↑ 8–40×** |
| 一艘 $1 亿油轮单次保费 | $25 万 | $200 万–$600 万 | **↑ 8–24×** |

数据来源：[(National Security Journal, 2026-07-11)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/) [(Lloyd's List, 2026-07-06)](https://www.lloydslist.com/LL1157747/VLCCs-and-suezmaxes-riding-high-as-peace-deal-hikes-Hormuz-flows) [(新华网, 2026-07-11)](http://www.xinhuanet.com/fortune/20260711/e5a0070252ee42faa74cea3b4f694b50/c.html) [(gCaptain/Bloomberg, 2026-07-09)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/) [(Real Tribune, 2026-07-10)](https://english.realtribune.ru/insurance-in-the-strait-of-hormuz-six-minutes-to-protect-a-vessel-and-6-million-for-a-single-passage)

更关键的是，越来越多船舶选择关闭 AIS 应答器通过海峡——Kpler 和 LSEG 依赖卫星图像和海事情报进行补充追踪，但追踪精度显著下降 [(National Security Journal, 2026-07-11)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/)。**当数据源本身变得不可靠，对多源交叉验证的需求就不是锦上添花而是生存必需。**

### 1.2 费率传导链：从保险到贸易的一切重定价

战争险费率已成为霍尔木兹安全形势最敏感的市场指标。Marsh 全球海事主管 Marcus Baker 明确表示："费率不太可能下降，直到市场真正相信风险环境已经改变" [(gCaptain/Bloomberg, 2026-07-09)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/)。Lloyd's 与 Chubb 于 6 月 19 日联合组建了新的海事战争险联合体，为船体和责任各提供最高 **$2 亿**覆盖，货物另加 $2 亿 [(Real Tribune, 2026-07-10)](https://english.realtribune.ru/insurance-in-the-strait-of-hormuz-six-minutes-to-protect-a-vessel-and-6-million-for-a-single-passage)。

费率传导路径清晰：战争险费率 → 航次成本 → 运价 → 原油到岸价 → 终端消费者价格。**任何一个环节缺乏透明、可验证的风险评级，都会导致定价偏差和资源错配。** 目前，这种评级完全依赖劳埃德市场的闭门承保讨论，外人无法验证、无法审计、无法实时获取。

### 1.3 市场规模：TAM / SAM / SOM

| 层级 | 定义 | 规模 | 来源 |
|------|------|------|------|
| **TAM** | 全球供应链风险管理与地缘风险分析市场 | $152.6B（2035E） | SNS Insider + GlobeNewsWire 合并估算 [(SNS Insider, 2026-07-08)](https://www.snsinsider.com/press-release/global-geopolitical-risk-analytics-platform-market) [(GlobeNewsWire, 2026-07-06)](https://www.globenewswire.com/news-release/2026/07/06/3322173/0/en/Vendor-Risk-Management-Market-Size-to-Surpass-USD-47-95-Billion-by-2035-SNS-Insider.html) |
| **SAM** | 地缘风险分析 + 海运战争风险评级 SaaS | $8–12B（2035E） | 地缘风险分析平台 $15.26B 的海运/战争风险子集 |
| **SOM** | 链上韧性证书 + API 服务（3 年内可触达） | $200–500M | 航运公司 + 保险公司 + 主权基金，假设 1–3% 渗透率 |

### 1.4 竞品格局：零链上、全部 SaaS

| 竞品 | 架构 | 链上验证 | 战争风险专精 | 实时评级 |
|------|------|----------|------------|----------|
| Resilinc | 传统 SaaS | ❌ | 部分（供应链风险） | 事件驱动告警 |
| Interos | 传统 SaaS | ❌ | 部分（地缘政治维度） | AI 评分（i-Score） |
| Everstream | 传统 SaaS | ❌ | 部分 | 监控告警 |
| Prewave | 传统 SaaS | ❌ | 部分（社交媒体预测） | AI 预测 |
| **本方案** | **链上合约 + 预言机** | **✅** | **✅ 核心** | **✅ 分钟级** |

数据来源：[(ToolRadar, 2026-06-16)](https://toolradar.com/compare/interos-vs-resilinc) [(SaaSworthy, 2026-07-04)](https://www.saasworthy.com/product-alternative/37122/resilinc)

**竞争真空：没有任何现有平台提供基于区块链的、可验证的战争风险韧性证书。** 这是一个结构性空白，不是功能迭代差距。

---

## 2. 技术架构设计

### 2.1 CompliancePassport 架构映射

CompliancePassport 合约的核心链路是 **评分→证书→验证**（Score → Certificate → Verify），三层依次递进：

```
CompliancePassport 原始架构          供应链战争风险扩展
─────────────────────────          ──────────────────────
agentId                     →     supplyChainRouteId / companyId
RiskScoreRecord (0-100)     →     RouteRiskScore (0-100, 多维度加权)
ComplianceCheck enum        →     WarRiskCheck enum (海峡通航量/油价/网攻/保险)
ComplianceCertificate       →     ResilienceCertificate (韧性等级 1-5)
SCORER_ROLE                 →     SCORER_ROLE (评分预言机)
COMPLIANCE_ORACLE_ROLE      →     WAR_RISK_ORACLE_ROLE
ERC-8126 风险评分接口        →     预言机聚合风险评分接口
ERC-8226 合规委托            →     战争风险委托/限额机制
```

**核心设计原则：不修改 CompliancePassport 的接口语义，仅扩展枚举类型和数据源映射。** 这确保了与 ERC-8126 / ERC-8226 标准的完全兼容性，同时将适用域从 AI Agent 合规切换至供应链战争风险。

### 2.2 数据预言机架构

[图1：预言机数据流架构图]

```
┌─────────────────────────────────────────────────────────────────┐
│                    链下数据源层 (Off-Chain)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────┐   │
│  │ AIS 船舶  │  │ 油价 API │  │ 网攻频率  │  │ 保险费率 API  │   │
│  │ 追踪数据  │  │Brent/WTI│  │STIX/TAXII│  │ Lloyd's/Marsh │   │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └───────┬───────┘   │
│        │             │             │               │            │
│        ▼             ▼             ▼               ▼            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           评分引擎 (Scoring Engine)                      │    │
│  │   多维度加权评分算法 → 0-100 分 → 映射韧性等级 1-5      │    │
│  └─────────────────────┬───────────────────────────────────┘    │
│                        │ EIP-712 签名                             │
│                        ▼                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           预言机节点 (Oracle Node)                        │    │
│  │   SCORER_ROLE 持有者 · 多节点共识 · 数据哈希锚定         │    │
│  └─────────────────────┬───────────────────────────────────┘    │
└────────────────────────┼─────────────────────────────────────────┘
                         │ 链上交易
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    链上合约层 (On-Chain)                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  WarRiskPassport (extends CompliancePassport)            │    │
│  │  recordRouteRiskScore() → RiskScoreRecord[]             │    │
│  │  issueResilienceCertificate() → ResilienceCertificate   │    │
│  │  verifyResilienceProof() → bool                         │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

**预言机安全设计要点：**

1. **多源交叉验证**：每个维度至少 2 个独立数据源（如 AIS 数据同时从 MarineTraffic 和 VesselFinder 获取），任一数据源中断不导致评分停滞
2. **数据哈希锚定**：每次评分提交必须附带 `evidenceHash`（keccak256(abi.encode(rawData, timestamp, sourceId))），原始数据存 IPFS，评分逻辑可审计
3. **多节点共识**：至少 3/5 预言机节点对同一评分达成一致方可上链，防止单点操纵
4. **时间衰减**：评分自动设置 `validUntil`（默认 24 小时），超时后自动失效，确保时效性
5. **AIS 关闭检测**：当某航线的 AIS 应答器关闭率异常升高时，该维度评分自动降级并触发警告标志

### 2.3 评分算法：多维度加权模型

**总分公式：**

```
RouteRiskScore = Σ(Wi × Si)  其中 i ∈ {transit, oil, cyber, insurance, geopolitical}

Si = normalize(raw_value_i, min_i, max_i) → [0, 100]
Wi = 维度权重，ΣWi = 1.0
```

| 维度 | 权重 (Wi) | 原始数据 | 归一化方法 | 数据源 |
|------|-----------|----------|-----------|--------|
| 海峡通航量 | 0.30 | 日均通行船只数 | 0 = 0艘, 100 = ≥140艘（线性反向：通行越少分越高） | MarineTraffic API, VesselFinder |
| 油价波动率 | 0.25 | Brent/WTI 30日波动率 | 0 = 波动率<5%, 100 = 波动率>50% | EIA API, Oilprice.com |
| 网络攻击频率 | 0.15 | 24h 内针对海事基础设施的攻击事件数 | 0 = 0次, 100 = ≥20次 | AlienVault OTX, IBM X-Force, STIX/TAXII feeds |
| 保险费率水平 | 0.20 | 当前战争险费率占船体价值百分比 | 0 = ≤0.25%, 100 = ≥10% | Lloyd's, Marsh 经纪数据 |
| 地缘政治指数 | 0.10 | 军事冲突等级（1-5）+ 外交状态 | 0 = 全面停火, 100 = 全面战争 | ACLED 数据, Council on Foreign Relations |

**注意：** 通航量维度采用反向归一化——通行量越低，风险评分越高。这反映了"市场用脚投票"的现实：当船东集体回避某航线，通航量本身即是最真实的风险指标。

**综合韧性等级映射：**

| 韧性等级 | 综合评分区间 | 含义 | 典型场景 |
|----------|------------|------|----------|
| Level 5 | 0–15 | 极低风险，全面韧性 | 正常运营，多替代路径，保险费率基线 |
| Level 4 | 16–35 | 低风险，良好韧性 | 局部紧张但未影响通航，替代路径可用 |
| Level 3 | 36–55 | 中等风险，部分韧性 | 通航量下降 30–50%，保险费率上升但可控 |
| Level 2 | 56–75 | 高风险，韧性不足 | 通航量下降 50–80%，保险费率飙升，替代路径拥挤 |
| Level 1 | 76–100 | 极高风险，韧性崩溃 | 通航几近停滞，保险拒保或费率 >5%，军事冲突活跃 |

### 2.4 WarRiskCheck 枚举扩展

```solidity
enum WarRiskCheck {
    STRAIT_TRANSIT_NORMAL,      // 海峡通航量正常
    OIL_PRICE_STABLE,           // 油价波动率在可接受范围
    CYBER_THREAT_LOW,           // 海事网络攻击频率低
    INSURANCE_COVERAGE_ACTIVE,  // 战争险可获取且费率合理
    GEOPOLITICAL_STABLE,        // 地缘政治状态稳定
    ALTERNATIVE_ROUTE_AVAILABLE,// 替代航线/管道可用
    AIS_DATA_RELIABLE           // AIS 追踪数据可靠（关闭率 <10%）
}
```

与 CompliancePassport 的 `ComplianceCheck` 枚举对应：原 6 项检查（身份验证、钱包清洁、行为正常、代码审计、委托有效、KYC 通过）映射为 7 项战争风险检查。`_calculateComplianceLevel` 函数的评分逻辑完全复用，仅替换检查项名称。

---

## 3. 合约接口规范

### 3.1 核心函数签名

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title WarRiskPassport
 * @notice 供应链战争风险实时评级 — 基于 CompliancePassport 扩展
 * @dev 架构层级: L3 — War Risk Compliance Layer
 * 标准依赖: ERC-8126 (Risk Score), ERC-8226 (Regulated Mandate), ERC-8004 (Identity)
 */

import "./CompliancePassport.sol";

contract WarRiskPassport is CompliancePassport {

    // ========== 新增角色 ==========
    bytes32 public constant WAR_RISK_ORACLE_ROLE = keccak256("WAR_RISK_ORACLE_ROLE");

    // ========== 新增数据结构 ==========

    /// @notice 航线风险评分记录（扩展自 RiskScoreRecord）
    struct RouteRiskScoreRecord {
        uint256 routeId;              // 供应链航线 ID
        uint8 transitScore;           // 通航量维度评分 (0-100)
        uint8 oilPriceScore;          // 油价波动维度评分 (0-100)
        uint8 cyberScore;             // 网络攻击维度评分 (0-100)
        uint8 insuranceScore;         // 保险费率维度评分 (0-100)
        uint8 geopoliticalScore;      // 地缘政治维度评分 (0-100)
        uint8 compositeScore;         // 加权综合评分 (0-100)
        uint256 scoredAt;
        uint256 validUntil;           // 默认 24h 有效期
        bytes32 evidenceHash;         // 原始数据哈希 (IPFS CID)
        string scorerURI;             // 评分引擎 URI
        bool revoked;
    }

    /// @notice 韧性证书（扩展自 ComplianceCertificate）
    struct ResilienceCertificate {
        uint256 certId;
        uint256 routeId;              // 航线或企业 ID
        uint8 compositeRiskScore;     // 综合战争风险评分
        uint8 resilienceLevel;        // 韧性等级 (1-5)
        uint8 transitScore;           // 各维度评分快照
        uint8 oilPriceScore;
        uint8 cyberScore;
        uint8 insuranceScore;
        uint8 geopoliticalScore;
        bytes32 evidenceHash;
        uint256 validUntil;
        uint256 issuedAt;
        address issuer;
        bool revoked;
        string routeURI;              // 航线详情 URI
    }

    // ========== 状态变量 ==========
    mapping(uint256 => RouteRiskScoreRecord[]) internal _routeRiskScores;
    mapping(uint256 => ResilienceCertificate[]) internal _routeCertificates;

    uint256 public scoreValidityPeriod = 1 days;  // 评分有效期：24小时
    uint256 public certValidityPeriod = 7 days;   // 证书有效期：7天

    // ========== 核心函数 ==========

    /**
     * @notice 记录航线战争风险评分
     * @param routeId 供应链航线 ID
     * @param score 综合评分 (0-100, 0=最安全, 100=最高风险)
     * @param validUntil 评分有效期截止时间
     * @param evidenceHash 原始数据哈希（含 AIS、油价、网攻、保险数据）
     * @param scorerURI 评分引擎信息 URI
     *
     * 要求: 调用者须持有 SCORER_ROLE
     */
    function recordRouteRiskScore(
        uint256 routeId,
        uint8 score,
        uint256 validUntil,
        bytes32 evidenceHash,
        string calldata scorerURI
    ) external onlyRole(SCORER_ROLE) {
        require(score <= 100, "WarRiskPassport: score out of range");
        require(validUntil > block.timestamp, "WarRiskPassport: invalid validity");
        require(
            validUntil <= block.timestamp + 3 days,
            "WarRiskPassport: validity exceeds max 3 days"
        );

        // 调用父类方法记录评分
        this.recordRiskScore(routeId, score, validUntil, evidenceHash, scorerURI);

        emit RouteRiskScoreRecorded(routeId, score, validUntil, evidenceHash);
    }

    /**
     * @notice 签发韧性证书
     * @param routeId 供应链航线 ID
     * @param resilienceLevel 韧性等级 (1-5)
     * @param evidenceHash 完整证据包哈希
     * @param validUntil 证书有效期截止时间
     *
     * 要求: 调用者须持有 SCORER_ROLE
     * 逻辑: 基于当前最新风险评分自动确定综合评分
     */
    function issueResilienceCertificate(
        uint256 routeId,
        uint8 resilienceLevel,
        bytes32 evidenceHash,
        uint256 validUntil
    ) external onlyRole(SCORER_ROLE) returns (uint256 certId) {
        require(resilenceLevel >= 1 && resilienceLevel <= 5,
            "WarRiskPassport: level must be 1-5");
        require(validUntil > block.timestamp,
            "WarRiskPassport: invalid validity");

        // 获取当前综合评分
        (uint8 compositeScore,) = this.getCompositeRiskScore(routeId);
        require(compositeScore <= 100, "WarRiskPassport: no valid score");

        // 验证评分与等级一致性
        uint8 expectedLevel = _mapScoreToLevel(compositeScore);
        require(resilienceLevel == expectedLevel,
            "WarRiskPassport: level inconsistent with score");

        // 调用父类方法签发证书
        certId = this.issueCertificate(
            routeId, resilienceLevel, evidenceHash, validUntil
        );

        emit ResilienceCertificateIssued(
            certId, routeId, compositeScore, resilienceLevel, validUntil
        );
    }

    /**
     * @notice 验证韧性证明（供第三方 DApp 调用）
     * @param routeId 航线 ID
     * @param minResilienceLevel 最低可接受韧性等级
     * @return valid 是否满足最低韧性要求
     * @return currentLevel 当前韧性等级
     * @return currentScore 当前综合风险评分
     */
    function verifyResilience(
        uint256 routeId,
        uint8 minResilienceLevel
    ) external view returns (bool valid, uint8 currentLevel, uint8 currentScore) {
        (currentScore,) = this.getCompositeRiskScore(routeId);
        currentLevel = _mapScoreToLevel(currentScore);
        valid = currentLevel >= minResilienceLevel;
    }

    /**
     * @notice 批量验证多条航线韧性（用于投资组合级风控）
     * @param routeIds 航线 ID 数组
     * @param minResilienceLevel 最低可接受韧性等级
     * @return results 验证结果数组
     */
    function batchVerifyResilience(
        uint256[] calldata routeIds,
        uint8 minResilienceLevel
    ) external view returns (bool[] memory results) {
        results = new bool[](routeIds.length);
        for (uint256 i = 0; i < routeIds.length; i++) {
            (uint8 score,) = this.getCompositeRiskScore(routeIds[i]);
            uint8 level = _mapScoreToLevel(score);
            results[i] = level >= minResilienceLevel;
        }
    }

    // ========== 事件 ==========
    event RouteRiskScoreRecorded(
        uint256 indexed routeId, uint8 score,
        uint256 validUntil, bytes32 evidenceHash
    );
    event ResilienceCertificateIssued(
        uint256 indexed certId, uint256 indexed routeId,
        uint8 compositeScore, uint8 resilienceLevel, uint256 validUntil
    );

    // ========== 内部函数 ==========
    function _mapScoreToLevel(uint8 score) internal pure returns (uint8) {
        if (score <= 15) return 5;
        if (score <= 35) return 4;
        if (score <= 55) return 3;
        if (score <= 75) return 2;
        return 1;
    }
}
```

### 3.2 接口设计说明

**与 CompliancePassport 的继承关系：**

- `recordRouteRiskScore` 内部调用父类 `recordRiskScore`，复用完整的评分存储和事件发射逻辑
- `issueResilienceCertificate` 内部调用父类 `issueCertificate`，复用证书 ID 生成和状态管理
- 新增 `verifyResilience` 和 `batchVerifyResilience` 为供应链场景特有的批量验证接口
- `_mapScoreToLevel` 替换父类 `_calculateComplianceLevel` 的评分→等级映射，采用供应链战争风险语义
- **关键约束**：评分有效期硬上限 3 天，证书有效期建议 7 天，防止过时数据被当作现行依据

---

## 4. 数据源与预言机

### 4.1 数据源矩阵

| 数据维度 | 主要数据源 | 备用数据源 | API 类型 | 更新频率 | 数据格式 |
|----------|-----------|-----------|----------|----------|----------|
| 海峡通航量 | MarineTraffic API | VesselFinder, HiFleet, Lloyd's List Intelligence | REST/GraphQL | 15–60 min | AIS NMEA |
| 油价 | EIA API (Brent/WTI) | Oilprice.com, ICE Futures | REST | 实时/15min | JSON |
| 网络攻击频率 | AlienVault OTX | IBM X-Force Exchange, Censys, STIX/TAXII feeds | REST/WebSocket | 实时 | STIX 2.1 |
| 保险费率 | Lloyd's Market | Marsh, Willis Towers Watson | 结构化录入/API | 日级 | JSON |
| 地缘政治指数 | ACLED 冲突数据 | CFR Preventive Priority Survey, IMF GeoRisk | REST | 日级 | JSON/CSV |

数据来源：[(MarineTraffic, 2026)](https://www.marinetraffic.com/) [(VesselFinder, 2026)](https://www.vesselfinder.com/) [(AlienVault OTX)](https://otx.alienvault.com/) [(IBM X-Force)](https://exchange.xforce.ibmcloud.com/) [(Censys, 2026-06-24)](https://www.presseportal.co.uk/censys-enrichment-api-direkte-integration-von-internet-intelligence-in-soc-workflows.html) [(Microsoft Sentinel STIX/TAXII)](https://learn.microsoft.com/id-id/azure/sentinel/connect-threat-intelligence-taxii)

### 4.2 预言机节点设计

**节点架构：3/5 共识 + 数据指纹**

```
预言机节点集群 (5 nodes)
├── Node A: 独立获取 5 维度数据 → 计算评分 → 签名提交
├── Node B: 独立获取 5 维度数据 → 计算评分 → 签名提交
├── Node C: 独立获取 5 维度数据 → 计算评分 → 签名提交
├── Node D: 独立获取 5 维度数据 → 计算评分 → 签名提交
└── Node E: 独立获取 5 维度数据 → 计算评分 → 签名提交

共识逻辑:
  → 各节点评分差异 < 10 分 → 取中位数上链
  → 任一节点评分偏差 > 10 分 → 触发争议解决（人工审核 + 数据源回溯）
  → 3/5 节点可用即继续运行（容许 2 节点离线）
```

**防操纵机制：**

1. **数据源多样性**：每个维度至少 2 个独立数据源，任一源数据偏差 >20% 自动降权
2. **时间戳强制**：所有原始数据必须附带可信时间戳，拒绝超过 1 小时的陈旧数据
3. **evidenceHash 可审计**：原始数据 + 评分参数 + 时间戳一并哈希后存链上，任何人可验证评分过程
4. **紧急暂停**：当 `DEFAULT_ADMIN_ROLE` 检测到系统性数据异常时，可调用 `freezeMandate` 冻结所有证书
5. **AIS 关闭率标志**：当某航线 AIS 应答器关闭率超过 10%，该维度的数据可靠性标记为 `DEGRADED`，评分自动附加不确定性区间

---

## 5. 商业模式

### 5.1 收入模型

| 收入流 | 定价 | 目标客户 | 年收入潜力（Year 3） |
|--------|------|----------|---------------------|
| **SaaS 订阅** | $5K–$50K/月（按航线数和企业规模分层） | 航运公司、贸易商 | $12M |
| **韧性证书认证费** | $500–$2K/证书（按航线/企业） | 航运公司、港口运营商 | $8M |
| **API 调用费** | $0.01–$0.10/查询（批量折扣） | 保险公司、主权基金、对冲基金 | $6M |
| **数据授权** | 定制化企业协议 | Lloyd's、Marsh、再保险公司 | $4M |

**Year 3 总收入预期：$30M**

### 5.2 定价策略

**分层定价（SaaS 订阅）：**

| 层级 | 月费 | 包含内容 | 目标客户 |
|------|------|----------|----------|
| Sentinel | $5,000 | 5 条航线监控 + 月度韧性报告 | 中型航运公司 |
| Vanguard | $15,000 | 20 条航线 + 实时评分 + API 调用 10K/月 | 大型贸易商 |
| Fortress | $50,000 | 无限航线 + 实时评分 + 无限 API + 批量验证 | 主权基金、保险公司 |

**韧性证书定价：**

- 单航线认证：$500/证书
- 企业级认证（覆盖所有关联航线）：$2,000/证书
- 批量认证（>50 条航线）：$300/证书

### 5.3 收入增长预测

[图2：收入增长预测图]

| 年份 | ARR | 客户数 | 关键里程碑 |
|------|-----|--------|-----------|
| Year 1 | $2M | 15–20 | MVP 上线，首批航运公司客户 |
| Year 2 | $10M | 60–80 | 保险公司采用，API 生态启动 |
| Year 3 | $30M | 150+ | 主权基金入场，韧性证书成为行业标准 |
| Year 5 | $120M | 500+ | 全球监管采纳，成为战争风险评级基础设施 |

---

## 6. MVP 路线图

### Phase 1：合约扩展 + 手动数据录入（2 周）

**目标：** 将 CompliancePassport 扩展为 WarRiskPassport，手动录入霍尔木兹海峡实时数据验证链路可行性。

| 任务 | 工期 | 交付物 |
|------|------|--------|
| WarRiskPassport 合约开发 | 3 天 | 合约代码 + 单元测试 |
| WarRiskCheck 枚举定义 | 1 天 | 7 项检查枚举 + 映射逻辑 |
| 手动评分录入脚本 | 2 天 | CLI 工具，从公开数据源手动录入 |
| 前端仪表盘 MVP | 4 天 | 航线风险评分可视化 |
| 测试网部署 | 2 天 | Sepolia 合约部署 + 演示 |

### Phase 2：预言机集成 + 自动化评分（4 周）

**目标：** 接入 AIS、油价、网攻、保险费率四大数据源，实现自动化评分。

| 任务 | 工期 | 交付物 |
|------|------|--------|
| MarineTraffic API 集成 | 5 天 | AIS 数据采集模块 |
| EIA 油价 API 集成 | 3 天 | 实时油价数据流 |
| AlienVault OTX + STIX 集成 | 5 天 | 网络攻击频率监控 |
| 保险费率数据录入工具 | 3 天 | 结构化录入 + 验证 |
| 评分引擎开发 | 5 天 | 5 维度加权评分算法 |
| 预言机节点集群部署 | 3 天 | 3/5 共机制 |

### Phase 3：SaaS 平台 + API 开放（8 周）

**目标：** 构建面向航运公司、保险公司、主权基金的 SaaS 平台。

| 任务 | 工期 | 交付物 |
|------|------|--------|
| SaaS 平台前端 | 15 天 | React + 韧性仪表盘 |
| API Gateway | 5 天 | RESTful API + 速率限制 + 认证 |
| 韧性证书管理模块 | 10 天 | 申请、签发、验证、撤销全流程 |
| 计费系统 | 5 天 | 分层订阅 + API 调用计费 |
| 主网部署 | 5 天 | Ethereum 主网合约部署 |

### Phase 4：生态合作（12 周）

**目标：** 与保险公司、航运公会、监管机构建立合作，推动韧性证书成为行业基础设施。

| 合作方 | 合作形式 | 预期成果 |
|--------|----------|----------|
| Lloyd's / Marsh | 数据共享 + 联合定价模型 | 保险费率维度数据标准化 |
| 国际航运公会 (ICS) | 韧性证书标准推广 | 行业认可 + 强制认证试点 |
| 主权财富基金 | 批量验证 API 采购 | 投资组合级战争风险监控 |
| 海事监管机构 | 合规标准共建 | 韧性证书纳入海事监管框架 |

---

## 7. 竞争优势与护城河

### 7.1 先发优势

**全球首个链上供应链战争风险评级系统。** 现有竞品（Resilinc、Interos、Everstream、Prewave）均为传统 SaaS 架构，不提供链上可验证凭证。在霍尔木兹危机持续、地缘风险常态化的背景下，先发优势意味着标准制定权。

### 7.2 技术护城河

CompliancePassport 合约已实现完整的「评分→证书→验证」链路，包括：

- **ERC-8126 兼容的 0-100 风险评分体系**（Finalized 标准）[(CoinDesk, 2026-06-12)](https://www.coindesk.cc/erc-8126-standardizes-ai-agent-verification-for-enhanced-privacy-61998.html)
- **ERC-8226 合规委托状态**（含财务上限、冻结机制）[(Ethereum Magicians, 2026-06-29)](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208/11)
- **EIP-712 链下签名 + 链上提交**（降低 Gas 成本，支持批量操作）
- **多评分者加权聚合**（`getCompositeRiskScore` 防止单点偏见）
- **证书撤销机制**（`revokeCertificate` 支持实时风险响应）

这些模块经过智能合约安全审计逻辑验证，扩展至供应链战争风险场景时无需重新构建核心架构。

### 7.3 网络效应

**数据飞轮：**

```
更多企业使用 → 更多航线评分数据 → 评分算法精度提升
      ↑                                    ↓
更多保险公司采用韧性证书 ← 更准确的费率定价参考
      ↑                                    ↓
更多航运公司申请认证 ← 证书成为保险/融资必要条件
```

当韧性证书成为保险公司承保的参考标准时，网络效应将形成正反馈循环。**每新增一个认证航线，整体验证精度提升；每新增一个保险公司采用，证书价值上升。**

### 7.4 数据护城河

- **实时 AIS + 保险费率交叉数据**：这是任何竞争对手无法从公开渠道获取的组合数据集
- **历史评分+证书链上记录**：不可篡改的时间序列数据，越积累越有价值
- **评分→费率关联模型**：随着数据积累，可建立评分与实际保险费率的统计关联，成为独家定价依据

---

## 8. 风险与挑战

### 8.1 数据源可靠性

**风险：** 预言机操纵是链上评分系统的最大威胁。如果攻击者控制了 AIS 数据源或油价 API，可以人为压低或抬高风险评分。

**缓解措施：**
- 3/5 多节点共识，任一节点评分偏差 >10 分触发争议解决
- 每维度至少 2 个独立数据源，交叉验证
- evidenceHash 强制链上存证，事后可审计
- 紧急暂停机制（`freezeMandate`），管理员可在检测到系统性异常时冻结所有证书

### 8.2 AIS 数据质量下降

**风险：** 霍尔木兹海峡越来越多的船舶关闭 AIS 应答器，导致通航量数据不可靠 [(National Security Journal, 2026-07-11)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/)。

**缓解措施：**
- 引入卫星图像分析（LSEG、Kpler 已采用此方法）作为 AIS 补充
- 当 AIS 关闭率超过 10% 时，通航量维度自动标记为 `DEGRADED`
- 评分算法在数据质量下降时自动扩大不确定性区间，并在证书中明确标注

### 8.3 监管合规

**风险：** 韧性证书可能被认定为金融产品（如信用评级），需要遵守各国金融产品信息披露法规。

**缓解措施：**
- 韧性证书定位为「信息参考」而非「投资建议」，明确免责声明
- 评分算法完全透明（evidenceHash 可审计），满足算法透明度要求
- 逐步与海事监管机构（IMO、各国海事局）建立标准共建关系
- 在金融监管严格的市场（美国、欧盟），先行获得合规顾问意见

### 8.4 市场教育

**风险：** 传统航运和保险行业对区块链技术的接受度有限，可能需要数年教育周期。

**缓解措施：**
- Phase 1 采用手动数据录入，降低技术门槛，让客户先感受价值
- 以保险公司为突破口——保险公司天然需要客观、可验证的风险评级
- 提供「非链上」读取接口（REST API 查询链上数据），客户无需直接接触区块链
- 与 Lloyd's、Marsh 等已有品牌合作，借力其行业信用

### 8.5 战争状态极端场景

**风险：** 在全面战争状态下，数据源可能完全中断（API 不可用、AIS 全面关闭、保险公司撤离），系统无法产出有效评分。

**缓解措施：**
- 评分有效期硬上限 3 天，数据中断时现有评分自动过期
- 证书包含 `validUntil` 时间戳，过期后自动失效
- 设置「数据中断」标志位，触发人工审核流程
- 维护离线评分预案（基于最近一次有效数据 + 风险恶化假设）

---

## 9. 结论

**供应链战争风险评级不是"锦上添花"，而是"不可或缺"。** 霍尔木兹海峡危机已经用数据证明了这一点：当通航量暴跌 98%、保险费率飙升 40 倍、一艘油轮的单次保费从 $25 万涨到 $600 万 [(新华网, 2026-07-11)](http://www.xinhuanet.com/fortune/20260711/e5a0070252ee42faa74cea3b4f694b50/c.html) [(gCaptain/Bloomberg, 2026-07-09)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/)——而全球尚无任何系统能实时、可验证地评级这些风险。

CompliancePassport 合约提供的「评分→证书→验证」链路是经过验证的架构。将 `agentId` 映射为 `supplyChainRouteId`、将合规检查映射为战争风险检查、将合规等级映射为韧性等级——这不是概念类比，而是架构复用。ERC-8126 的 0-100 风险评分、ERC-8226 的委托与冻结机制、EIP-712 的链下签名——每一个模块都在供应链战争风险场景中找到了精确对应。

**地缘风险常态化已经改变了全球贸易的底层逻辑。** 斯德哥尔摩经济学院教授 Constantin Blome 的研究指出："供应链已经从全球化的背景设施变成了地缘战略的中心舞台" [(Stockholm School of Economics, 2026-06-12)](https://www.hhs.se/en/about-us/news/cfsr/2026/research-portrait-constantin-blome/)。在这个新现实中，可验证的韧性评级不是可选项——它是贸易基础设施的必要组件。

**下一步行动：**

1. 立即启动 Phase 1，将 WarRiskPassport 合约部署至测试网
2. 与 Lloyd's 或 Marsh 建立 Phase 4 预合作，获取保险费率数据
3. 在霍尔木兹危机窗口期，以实时数据验证评分算法的准确性和时效性
4. 6 个月内完成 Phase 2-3，在主网上线可用的 SaaS 平台

---

*本白皮书基于 CompliancePassport 合约源码和 2026 年 7 月公开市场数据撰写。所有市场数据均标注来源和日期。*
