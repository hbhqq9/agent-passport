# Supply Chain War Risk Real-Time Rating System Whitepaper

**An On-Chain Resilience Certificate Framework Built on the CompliancePassport Contract Architecture**

> Version 1.0 | 2026-07-11

---

## Executive Summary

**The Strait of Hormuz is experiencing the most severe transit disruption since the 1980s.** Pre-conflict daily transits averaged 125–140 vessels; by July 2026, throughput fell below 2% of normal, with only 2 vessels recorded in a 48-hour window [(National Security Journal)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/) [(Discovery Alert)](https://discoveryalert.com.au/strait-hormuz-tanker-traffic-standstill-oil-supply-crisis/). The VLCC MEG-China TD3C benchmark surged to **$296,175/day**, more than double pre-crisis levels [(Lloyd's List)](https://www.lloydslist.com/LL1157747/VLCCs-and-suezmaxes-riding-high-as-peace-deal-hikes-Hormuz-flows); hull war risk insurance premiums exploded from 0.25% of vessel value to a peak of 10%, currently hovering at 2%–6% [(Xinhua)](http://www.xinhuanet.com/fortune/20260711/e5a0070252ee42faa74cea3b4f694b50/c.html) [(gCaptain/Bloomberg)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/). Yet no on-chain solution exists to convert geopolitical risk data into verifiable supply chain resilience credentials in real time. The Geopolitical Risk Analytics Platform market was valued at **$4.02 billion** in 2025 and is projected to reach **$15.26 billion** by 2035 (CAGR 14.30%) [(SNS Insider)](https://www.snsinsider.com/press-release/global-geopolitical-risk-analytics-platform-market), but existing participants (Resilinc, Interos, Everstream) are all traditional SaaS architectures with no on-chain verification layer.

**This whitepaper proposes extending the CompliancePassport contract's "Score → Certificate → Verify" pipeline to the supply chain war risk rating domain.** The core mapping: `agentId` → `supplyChainRouteId` / `companyId`; risk score inputs shift from AI agent behavioral data to real-time geopolitical risk data streams (AIS vessel tracking, oil price APIs, cybersecurity threat feeds, insurance premiums); outputs shift from compliance levels to "Resilience Certificates" (Level 1–5). This is the world's first on-chain verifiable credential system that anchors war risk ratings to blockchain — when a missile strikes an LNG carrier in the strait, the rating updates within minutes and the resilience certificate is re-issued or revoked accordingly.

---

## 1. Market Background and Opportunity Sizing

### 1.1 The Hormuz Crisis: Real-Time Data Confirms Systemic Rupture

The Strait of Hormuz carries approximately one-fifth of the world's seaborne oil trade and around 25% of global LNG trade [(Discovery Alert)](https://discoveryalert.com.au/strait-hormuz-tanker-traffic-standstill-oil-supply-crisis/). After the US-Israeli joint strikes on Iran on February 28, 2026, this 33-kilometer-wide chokepoint transformed from a global trade artery into a war zone within days.

| Metric | Pre-Conflict Baseline | Current Status | Change |
|--------|----------------------|----------------|--------|
| Daily transits | 125–140 vessels/day | <2% of normal throughput (2 vessels/48h on Jul 9) | **↓ >98%** |
| Recovery period average | — | ~40 vessels/day (post-June MOU) | Still <1/3 normal |
| Japanese merchant fleet in Gulf | ~45 vessels | 4 vessels | **↓ 91%** |
| VLCC TCE (MEG-China) | ~$90K–100K/day | $296,175/day | **↑ 3×** |
| War risk premium | 0.25% hull value/7 days | 2%–6% (peak 10%) | **↑ 8–40×** |
| Single transit insurance for $100M tanker | $250K | $2M–$6M | **↑ 8–24×** |

Sources: [(National Security Journal, 2026-07-11)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/) [(Lloyd's List, 2026-07-06)](https://www.lloydslist.com/LL1157747/VLCCs-and-suezmaxes-riding-high-as-peace-deal-hikes-Hormuz-flows) [(Xinhua, 2026-07-11)](http://www.xinhuanet.com/fortune/20260711/e5a0070252ee42faa74cea3b4f694b50/c.html) [(gCaptain/Bloomberg, 2026-07-09)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/) [(Real Tribune, 2026-07-10)](https://english.realtribune.ru/insurance-in-the-strait-of-hormuz-six-minutes-to-protect-a-vessel-and-6-million-for-a-single-passage)

Critically, an increasing number of vessels are switching off AIS transponders when transiting the strait — Kpler and LSEG now rely on satellite imagery and maritime intelligence as supplements, but tracking accuracy has significantly degraded [(National Security Journal, 2026-07-11)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/). **When the data source itself becomes unreliable, the need for multi-source cross-verification shifts from nice-to-have to existential.**

### 1.2 The Premium Transmission Chain: Everything Rerates from Insurance to Trade

War risk premiums have become the most sensitive market indicator for Hormuz security conditions. Marcus Baker, Global Head of Marine at Marsh, stated clearly: "Rates are unlikely to fall until the market truly believes the risk environment has changed" [(gCaptain/Bloomberg, 2026-07-09)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/). On June 19, Lloyd's and Chubb jointly launched a new marine war consortium providing up to **$200 million** in coverage separately for hull and liability, plus an additional $200 million for cargo [(Real Tribune, 2026-07-10)](https://english.realtribune.ru/insurance-in-the-strait-of-hormuz-six-minutes-to-protect-a-vessel-and-6-million-for-a-single-passage).

The premium transmission path is clear: war risk premiums → voyage costs → freight rates → crude CIF prices → end-consumer prices. **At any point in this chain, the absence of transparent, verifiable risk ratings leads to pricing errors and resource misallocation.** Currently, such ratings depend entirely on closed-door underwriting discussions at Lloyd's Market — outsiders cannot verify, audit, or access them in real time.

### 1.3 Market Sizing: TAM / SAM / SOM

| Layer | Definition | Size | Source |
|-------|-----------|------|--------|
| **TAM** | Global supply chain risk management + geopolitical risk analytics | $152.6B (2035E) | SNS Insider + GlobeNewsWire combined estimates [(SNS Insider, 2026-07-08)](https://www.snsinsider.com/press-release/global-geopolitical-risk-analytics-platform-market) [(GlobeNewsWire, 2026-07-06)](https://www.globenewswire.com/news-release/2026/07/06/3322173/0/en/Vendor-Risk-Management-Market-Size-to-Surpass-USD-47-95-Billion-by-2035-SNS-Insider.html) |
| **SAM** | Geopolitical risk analytics + maritime war risk rating SaaS | $8–12B (2035E) | Maritime/war risk subset of the $15.26B geopolitical risk analytics market |
| **SOM** | On-chain resilience certificates + API services (3-year addressable) | $200–500M | Shipping companies + insurers + sovereign funds, assuming 1–3% penetration |

### 1.4 Competitive Landscape: Zero On-Chain, All SaaS

| Competitor | Architecture | On-Chain Verification | War Risk Specialization | Real-Time Rating |
|-----------|-------------|----------------------|------------------------|-----------------|
| Resilinc | Traditional SaaS | ❌ | Partial (supply chain risk) | Event-driven alerts |
| Interos | Traditional SaaS | ❌ | Partial (geopolitical dimension) | AI scoring (i-Score) |
| Everstream | Traditional SaaS | ❌ | Partial | Monitoring alerts |
| Prewave | Traditional SaaS | ❌ | Partial (social media prediction) | AI prediction |
| **This Proposal** | **On-chain contract + Oracles** | **✅** | **✅ Core** | **✅ Minute-level** |

Sources: [(ToolRadar, 2026-06-16)](https://toolradar.com/compare/interos-vs-resilinc) [(SaaSworthy, 2026-07-04)](https://www.saasworthy.com/product-alternative/37122/resilinc)

**Competitive vacuum: no existing platform provides blockchain-based, verifiable war risk resilience certificates.** This is a structural gap, not an iterative feature difference.

---

## 2. Technical Architecture Design

### 2.1 CompliancePassport Architecture Mapping

The CompliancePassport contract's core pipeline is **Score → Certificate → Verify**, three layers in sequence:

```
CompliancePassport Original          Supply Chain War Risk Extension
─────────────────────────          ──────────────────────
agentId                     →     supplyChainRouteId / companyId
RiskScoreRecord (0-100)     →     RouteRiskScore (0-100, multi-dimension weighted)
ComplianceCheck enum        →     WarRiskCheck enum (strait transit/oil/cyber/insurance)
ComplianceCertificate       →     ResilienceCertificate (resilience level 1-5)
SCORER_ROLE                 →     SCORER_ROLE (scoring oracle)
COMPLIANCE_ORACLE_ROLE      →     WAR_RISK_ORACLE_ROLE
ERC-8126 risk score interface→     Oracle-aggregated risk score interface
ERC-8226 compliance mandate  →     War risk mandate/exposure limit mechanism
```

**Core design principle: do not modify CompliancePassport's interface semantics; only extend enum types and data source mappings.** This ensures full compatibility with ERC-8126 / ERC-8226 standards while shifting the application domain from AI agent compliance to supply chain war risk.

### 2.2 Data Oracle Architecture

[Figure 1: Oracle Data Flow Architecture Diagram]

```
┌─────────────────────────────────────────────────────────────────┐
│                    Off-Chain Data Source Layer                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────┐   │
│  │ AIS Vessel│  │ Oil Price│  │ Cyber    │  │ Insurance     │   │
│  │ Tracking  │  │ Brent/WTI│  │STIX/TAXII│  │ Lloyd's/Marsh │   │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └───────┬───────┘   │
│        │             │             │               │            │
│        ▼             ▼             ▼               ▼            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           Scoring Engine                                 │    │
│  │   Multi-dimension weighted scoring → 0-100 score        │    │
│  │   → Mapped to resilience level 1-5                      │    │
│  └─────────────────────┬───────────────────────────────────┘    │
│                        │ EIP-712 Signature                      │
│                        ▼                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           Oracle Node                                    │    │
│  │   SCORER_ROLE holder · Multi-node consensus · Data hash  │    │
│  └─────────────────────┬───────────────────────────────────┘    │
└────────────────────────┼─────────────────────────────────────────┘
                         │ On-Chain Transaction
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    On-Chain Contract Layer                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  WarRiskPassport (extends CompliancePassport)            │    │
│  │  recordRouteRiskScore() → RiskScoreRecord[]             │    │
│  │  issueResilienceCertificate() → ResilienceCertificate   │    │
│  │  verifyResilienceProof() → bool                         │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

**Oracle Security Design Principles:**

1. **Multi-source cross-verification**: Each dimension uses at least 2 independent data sources (e.g., AIS data from both MarineTraffic and VesselFinder); loss of any single source does not stall scoring
2. **Data hash anchoring**: Every score submission must include `evidenceHash` (keccak256(abi.encode(rawData, timestamp, sourceId))); raw data stored on IPFS; scoring logic is auditable
3. **Multi-node consensus**: At least 3 of 5 oracle nodes must agree on a score before on-chain submission, preventing single-point manipulation
4. **Time decay**: Scores automatically include `validUntil` (default 24 hours); expired scores automatically invalidate, ensuring timeliness
5. **AIS shutdown detection**: When the AIS transponder shutdown rate for a route abnormally increases, the transit dimension is automatically downgraded and a warning flag is triggered

### 2.3 Scoring Algorithm: Multi-Dimension Weighted Model

**Total Score Formula:**

```
RouteRiskScore = Σ(Wi × Si)  where i ∈ {transit, oil, cyber, insurance, geopolitical}

Si = normalize(raw_value_i, min_i, max_i) → [0, 100]
Wi = dimension weight, ΣWi = 1.0
```

| Dimension | Weight (Wi) | Raw Data | Normalization Method | Data Source |
|-----------|-------------|----------|---------------------|-------------|
| Strait transit volume | 0.30 | Daily transit vessel count | 0 = 0 vessels, 100 = ≥140 vessels (inverse linear: fewer transits = higher score) | MarineTraffic API, VesselFinder |
| Oil price volatility | 0.25 | Brent/WTI 30-day volatility | 0 = volatility <5%, 100 = volatility >50% | EIA API, Oilprice.com |
| Cyber attack frequency | 0.15 | Maritime infrastructure attack events in 24h | 0 = 0 events, 100 = ≥20 events | AlienVault OTX, IBM X-Force, STIX/TAXII feeds |
| Insurance premium level | 0.20 | Current war risk premium as % of hull value | 0 = ≤0.25%, 100 = ≥10% | Lloyd's, Marsh broker data |
| Geopolitical index | 0.10 | Military conflict level (1-5) + diplomatic status | 0 = full ceasefire, 100 = full-scale war | ACLED data, Council on Foreign Relations |

**Note:** The transit volume dimension uses inverse normalization — fewer transits yield a higher risk score. This reflects the reality that "markets vote with their feet": when shipowners collectively avoid a route, transit volume itself is the most authentic risk indicator.

**Resilience Level Mapping:**

| Resilience Level | Composite Score Range | Meaning | Typical Scenario |
|-----------------|----------------------|---------|-----------------|
| Level 5 | 0–15 | Minimal risk, full resilience | Normal operations, multiple alternative routes, baseline insurance |
| Level 4 | 16–35 | Low risk, good resilience | Localized tension without transit impact, alternative routes available |
| Level 3 | 36–55 | Moderate risk, partial resilience | Transit volume down 30–50%, insurance premiums rising but manageable |
| Level 2 | 56–75 | High risk, insufficient resilience | Transit volume down 50–80%, insurance premiums surging, alternative routes congested |
| Level 1 | 76–100 | Extreme risk, resilience collapsed | Near-standstill transit, insurance denied or premiums >5%, active military conflict |

### 2.4 WarRiskCheck Enum Extension

```solidity
enum WarRiskCheck {
    STRAIT_TRANSIT_NORMAL,      // Strait transit volume normal
    OIL_PRICE_STABLE,           // Oil price volatility within acceptable range
    CYBER_THREAT_LOW,           // Maritime cyber attack frequency low
    INSURANCE_COVERAGE_ACTIVE,  // War risk insurance available at reasonable rates
    GEOPOLITICAL_STABLE,        // Geopolitical conditions stable
    ALTERNATIVE_ROUTE_AVAILABLE,// Alternative shipping routes/pipelines available
    AIS_DATA_RELIABLE           // AIS tracking data reliable (shutdown rate <10%)
}
```

This maps to CompliancePassport's `ComplianceCheck` enum: the original 6 checks (identity verified, wallet clean, behavior normal, code audited, mandate valid, KYC cleared) map to 7 war risk checks. The `_calculateComplianceLevel` function's scoring logic is fully reused with only check-item name substitutions.

---

## 3. Contract Interface Specification

### 3.1 Core Function Signatures

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title WarRiskPassport
 * @notice Supply Chain War Risk Real-Time Rating — Based on CompliancePassport Extension
 * @dev Architecture Layer: L3 — War Risk Compliance Layer
 * Standard Dependencies: ERC-8126 (Risk Score), ERC-8226 (Regulated Mandate), ERC-8004 (Identity)
 */

import "./CompliancePassport.sol";

contract WarRiskPassport is CompliancePassport {

    // ========== New Roles ==========
    bytes32 public constant WAR_RISK_ORACLE_ROLE = keccak256("WAR_RISK_ORACLE_ROLE");

    // ========== New Data Structures ==========

    /// @notice Route risk score record (extended from RiskScoreRecord)
    struct RouteRiskScoreRecord {
        uint256 routeId;              // Supply chain route ID
        uint8 transitScore;           // Transit volume dimension score (0-100)
        uint8 oilPriceScore;          // Oil price volatility dimension score (0-100)
        uint8 cyberScore;             // Cyber attack dimension score (0-100)
        uint8 insuranceScore;         // Insurance premium dimension score (0-100)
        uint8 geopoliticalScore;      // Geopolitical dimension score (0-100)
        uint8 compositeScore;         // Weighted composite score (0-100)
        uint256 scoredAt;
        uint256 validUntil;           // Default 24h validity
        bytes32 evidenceHash;         // Raw data hash (IPFS CID)
        string scorerURI;             // Scoring engine URI
        bool revoked;
    }

    /// @notice Resilience Certificate (extended from ComplianceCertificate)
    struct ResilienceCertificate {
        uint256 certId;
        uint256 routeId;              // Route or company ID
        uint8 compositeRiskScore;     // Composite war risk score
        uint8 resilienceLevel;        // Resilience level (1-5)
        uint8 transitScore;           // Dimension score snapshots
        uint8 oilPriceScore;
        uint8 cyberScore;
        uint8 insuranceScore;
        uint8 geopoliticalScore;
        bytes32 evidenceHash;
        uint256 validUntil;
        uint256 issuedAt;
        address issuer;
        bool revoked;
        string routeURI;              // Route details URI
    }

    // ========== State Variables ==========
    mapping(uint256 => RouteRiskScoreRecord[]) internal _routeRiskScores;
    mapping(uint256 => ResilienceCertificate[]) internal _routeCertificates;

    uint256 public scoreValidityPeriod = 1 days;  // Score validity: 24 hours
    uint256 public certValidityPeriod = 7 days;   // Certificate validity: 7 days

    // ========== Core Functions ==========

    /**
     * @notice Record route war risk score
     * @param routeId Supply chain route ID
     * @param score Composite score (0-100, 0=safest, 100=highest risk)
     * @param validUntil Score validity expiration timestamp
     * @param evidenceHash Raw data hash (including AIS, oil price, cyber, insurance data)
     * @param scorerURI Scoring engine information URI
     *
     * Requires: caller must hold SCORER_ROLE
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

        // Call parent method to record score
        this.recordRiskScore(routeId, score, validUntil, evidenceHash, scorerURI);

        emit RouteRiskScoreRecorded(routeId, score, validUntil, evidenceHash);
    }

    /**
     * @notice Issue resilience certificate
     * @param routeId Supply chain route ID
     * @param resilienceLevel Resilience level (1-5)
     * @param evidenceHash Complete evidence package hash
     * @param validUntil Certificate validity expiration timestamp
     *
     * Requires: caller must hold SCORER_ROLE
     * Logic: composite score automatically determined from latest risk score
     */
    function issueResilienceCertificate(
        uint256 routeId,
        uint8 resilienceLevel,
        bytes32 evidenceHash,
        uint256 validUntil
    ) external onlyRole(SCORER_ROLE) returns (uint256 certId) {
        require(resilienceLevel >= 1 && resilienceLevel <= 5,
            "WarRiskPassport: level must be 1-5");
        require(validUntil > block.timestamp,
            "WarRiskPassport: invalid validity");

        // Get current composite score
        (uint8 compositeScore,) = this.getCompositeRiskScore(routeId);
        require(compositeScore <= 100, "WarRiskPassport: no valid score");

        // Verify score-level consistency
        uint8 expectedLevel = _mapScoreToLevel(compositeScore);
        require(resilienceLevel == expectedLevel,
            "WarRiskPassport: level inconsistent with score");

        // Call parent method to issue certificate
        certId = this.issueCertificate(
            routeId, resilienceLevel, evidenceHash, validUntil
        );

        emit ResilienceCertificateIssued(
            certId, routeId, compositeScore, resilienceLevel, validUntil
        );
    }

    /**
     * @notice Verify resilience proof (for third-party DApp calls)
     * @param routeId Route ID
     * @param minResilienceLevel Minimum acceptable resilience level
     * @return valid Whether minimum resilience requirement is met
     * @return currentLevel Current resilience level
     * @return currentScore Current composite risk score
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
     * @notice Batch verify resilience for multiple routes (portfolio-level risk control)
     * @param routeIds Array of route IDs
     * @param minResilienceLevel Minimum acceptable resilience level
     * @return results Array of verification results
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

    // ========== Events ==========
    event RouteRiskScoreRecorded(
        uint256 indexed routeId, uint8 score,
        uint256 validUntil, bytes32 evidenceHash
    );
    event ResilienceCertificateIssued(
        uint256 indexed certId, uint256 indexed routeId,
        uint8 compositeScore, uint8 resilienceLevel, uint256 validUntil
    );

    // ========== Internal Functions ==========
    function _mapScoreToLevel(uint8 score) internal pure returns (uint8) {
        if (score <= 15) return 5;
        if (score <= 35) return 4;
        if (score <= 55) return 3;
        if (score <= 75) return 2;
        return 1;
    }
}
```

### 3.2 Interface Design Notes

**Inheritance Relationship with CompliancePassport:**

- `recordRouteRiskScore` internally calls parent `recordRiskScore`, reusing the complete score storage and event emission logic
- `issueResilienceCertificate` internally calls parent `issueCertificate`, reusing certificate ID generation and state management
- New `verifyResilience` and `batchVerifyResilience` provide supply-chain-specific batch verification interfaces
- `_mapScoreToLevel` replaces the parent's `_calculateComplianceLevel` score-to-level mapping, using supply chain war risk semantics
- **Key constraint**: Score validity hard cap of 3 days; certificate validity recommended at 7 days, preventing stale data from being treated as current

---

## 4. Data Sources and Oracles

### 4.1 Data Source Matrix

| Data Dimension | Primary Source | Backup Source | API Type | Update Frequency | Data Format |
|---------------|---------------|--------------|----------|-----------------|-------------|
| Strait transit volume | MarineTraffic API | VesselFinder, HiFleet, Lloyd's List Intelligence | REST/GraphQL | 15–60 min | AIS NMEA |
| Oil prices | EIA API (Brent/WTI) | Oilprice.com, ICE Futures | REST | Real-time/15min | JSON |
| Cyber attack frequency | AlienVault OTX | IBM X-Force Exchange, Censys, STIX/TAXII feeds | REST/WebSocket | Real-time | STIX 2.1 |
| Insurance premiums | Lloyd's Market | Marsh, Willis Towers Watson | Structured entry/API | Daily | JSON |
| Geopolitical index | ACLED conflict data | CFR Preventive Priority Survey, IMF GeoRisk | REST | Daily | JSON/CSV |

Sources: [(MarineTraffic, 2026)](https://www.marinetraffic.com/) [(VesselFinder, 2026)](https://www.vesselfinder.com/) [(AlienVault OTX)](https://otx.alienvault.com/) [(IBM X-Force)](https://exchange.xforce.ibmcloud.com/) [(Censys, 2026-06-24)](https://www.presseportal.co.uk/censys-enrichment-api-direkte-integration-von-internet-intelligence-in-soc-workflows.html) [(Microsoft Sentinel STIX/TAXII)](https://learn.microsoft.com/id-id/azure/sentinel/connect-threat-intelligence-taxii)

### 4.2 Oracle Node Design

**Node Architecture: 3/5 Consensus + Data Fingerprinting**

```
Oracle Node Cluster (5 nodes)
├── Node A: Independently fetch 5-dimension data → Calculate score → Sign and submit
├── Node B: Independently fetch 5-dimension data → Calculate score → Sign and submit
├── Node C: Independently fetch 5-dimension data → Calculate score → Sign and submit
├── Node D: Independently fetch 5-dimension data → Calculate score → Sign and submit
└── Node E: Independently fetch 5-dimension data → Calculate score → Sign and submit

Consensus Logic:
  → Score variance across nodes < 10 points → Median submitted on-chain
  → Any node's score deviates > 10 points → Dispute resolution triggered (manual review + data source traceback)
  → 3/5 nodes available → System continues (tolerates 2 node outages)
```

**Anti-Manipulation Mechanisms:**

1. **Data source diversity**: Each dimension uses at least 2 independent data sources; any source with >20% data deviation is automatically downweighted
2. **Mandatory timestamps**: All raw data must include trusted timestamps; data older than 1 hour is rejected
3. **Auditable evidenceHash**: Raw data + scoring parameters + timestamps are hashed and stored on-chain; anyone can verify the scoring process
4. **Emergency pause**: When `DEFAULT_ADMIN_ROLE` detects systemic data anomalies, `freezeMandate` can freeze all certificates
5. **AIS shutdown rate flag**: When the AIS transponder shutdown rate for a route exceeds 10%, the transit dimension's data reliability is marked as `DEGRADED`, and the score automatically includes an uncertainty interval

---

## 5. Business Model

### 5.1 Revenue Model

| Revenue Stream | Pricing | Target Customers | Year 3 Revenue Potential |
|---------------|---------|-----------------|-------------------------|
| **SaaS Subscription** | $5K–$50K/month (tiered by route count and company size) | Shipping companies, traders | $12M |
| **Resilience Certificate Fee** | $500–$2K/certificate (per route/company) | Shipping companies, port operators | $8M |
| **API Call Fee** | $0.01–$0.10/query (volume discounts) | Insurance companies, sovereign funds, hedge funds | $6M |
| **Data Licensing** | Custom enterprise agreements | Lloyd's, Marsh, reinsurers | $4M |

**Year 3 Total Revenue Projection: $30M**

### 5.2 Pricing Strategy

**Tiered Pricing (SaaS Subscription):**

| Tier | Monthly Fee | Included Features | Target Customer |
|------|------------|-------------------|----------------|
| Sentinel | $5,000 | 5 routes monitored + monthly resilience report | Mid-size shipping companies |
| Vanguard | $15,000 | 20 routes + real-time scoring + 10K API calls/month | Large traders |
| Fortress | $50,000 | Unlimited routes + real-time scoring + unlimited API + batch verification | Sovereign funds, insurers |

**Resilience Certificate Pricing:**

- Single route certification: $500/certificate
- Enterprise certification (covering all associated routes): $2,000/certificate
- Batch certification (>50 routes): $300/certificate

### 5.3 Revenue Growth Forecast

[Figure 2: Revenue Growth Forecast]

| Year | ARR | Customer Count | Key Milestones |
|------|-----|---------------|----------------|
| Year 1 | $2M | 15–20 | MVP launch, first shipping company customers |
| Year 2 | $10M | 60–80 | Insurer adoption, API ecosystem launch |
| Year 3 | $30M | 150+ | Sovereign fund entry, resilience certificate becomes industry standard |
| Year 5 | $120M | 500+ | Global regulatory adoption, becomes war risk rating infrastructure |

---

## 6. MVP Roadmap

### Phase 1: Contract Extension + Manual Data Entry (2 Weeks)

**Goal:** Extend CompliancePassport to WarRiskPassport; manually enter real-time Hormuz data to validate on-chain pipeline feasibility.

| Task | Duration | Deliverable |
|------|----------|-------------|
| WarRiskPassport contract development | 3 days | Contract code + unit tests |
| WarRiskCheck enum definition | 1 day | 7-check enum + mapping logic |
| Manual score entry script | 2 days | CLI tool for manual entry from public data sources |
| Frontend dashboard MVP | 4 days | Route risk score visualization |
| Testnet deployment | 2 days | Sepolia contract deployment + demo |

### Phase 2: Oracle Integration + Automated Scoring (4 Weeks)

**Goal:** Integrate AIS, oil price, cyber attack, and insurance premium data sources; achieve automated scoring.

| Task | Duration | Deliverable |
|------|----------|-------------|
| MarineTraffic API integration | 5 days | AIS data collection module |
| EIA oil price API integration | 3 days | Real-time oil price data stream |
| AlienVault OTX + STIX integration | 5 days | Cyber attack frequency monitoring |
| Insurance premium data entry tool | 3 days | Structured entry + validation |
| Scoring engine development | 5 days | 5-dimension weighted scoring algorithm |
| Oracle node cluster deployment | 3 days | 3/5 consensus mechanism |

### Phase 3: SaaS Platform + API Launch (8 Weeks)

**Goal:** Build SaaS platform for shipping companies, insurers, and sovereign funds.

| Task | Duration | Deliverable |
|------|----------|-------------|
| SaaS platform frontend | 15 days | React + resilience dashboard |
| API Gateway | 5 days | RESTful API + rate limiting + authentication |
| Resilience certificate management module | 10 days | Apply, issue, verify, revoke full lifecycle |
| Billing system | 5 days | Tiered subscription + API call billing |
| Mainnet deployment | 5 days | Ethereum mainnet contract deployment |

### Phase 4: Ecosystem Partnerships (12 Weeks)

**Goal:** Establish partnerships with insurers, shipping associations, and regulators to drive resilience certificate adoption as industry infrastructure.

| Partner | Partnership Model | Expected Outcome |
|---------|------------------|-----------------|
| Lloyd's / Marsh | Data sharing + joint pricing model | Insurance premium data standardization |
| International Chamber of Shipping (ICS) | Resilience certificate standard promotion | Industry recognition + mandatory certification pilot |
| Sovereign wealth funds | Batch verification API procurement | Portfolio-level war risk monitoring |
| Maritime regulatory agencies | Compliance standard co-creation | Resilience certificate integrated into maritime regulatory framework |

---

## 7. Competitive Advantages and Moats

### 7.1 First-Mover Advantage

**The world's first on-chain supply chain war risk rating system.** Existing competitors (Resilinc, Interos, Everstream, Prewave) are all traditional SaaS architectures with no on-chain verifiable credentials. With the Hormuz crisis ongoing and geopolitical risk becoming the new normal, first-mover advantage means standard-setting power.

### 7.2 Technical Moat

The CompliancePassport contract already implements a complete "Score → Certificate → Verify" pipeline, including:

- **ERC-8126-compatible 0-100 risk scoring system** (Finalized standard) [(CoinDesk, 2026-06-12)](https://www.coindesk.cc/erc-8126-standardizes-ai-agent-verification-for-enhanced-privacy-61998.html)
- **ERC-8226 compliance mandate status** (with financial caps, freeze mechanism) [(Ethereum Magicians, 2026-06-29)](https://ethereum-magicians.org/t/erc-8226-regulated-agent-mandate/28208/11)
- **EIP-712 off-chain signing + on-chain submission** (reducing gas costs, supporting batch operations)
- **Multi-scorer weighted aggregation** (`getCompositeRiskScore` prevents single-point bias)
- **Certificate revocation mechanism** (`revokeCertificate` supports real-time risk response)

These modules have been validated through smart contract security audit logic; extension to the supply chain war risk scenario requires no core architecture rebuild.

### 7.3 Network Effects

**The Data Flywheel:**

```
More enterprises adopt → More route scoring data → Scoring algorithm accuracy improves
      ↑                                         ↓
More insurers adopt resilience certificates ← More accurate premium pricing reference
      ↑                                         ↓
More shipping companies seek certification ← Certificate becomes prerequisite for insurance/financing
```

When resilience certificates become a reference standard for insurance underwriting, network effects will form a positive feedback loop. **Each newly certified route improves overall verification accuracy; each new insurer adoption increases certificate value.**

### 7.4 Data Moat

- **Real-time AIS + insurance premium cross-referenced data**: A combined dataset no competitor can obtain from public sources
- **Historical scoring + certificate on-chain records**: Immutable time-series data that grows more valuable over time
- **Score-to-premium correlation model**: As data accumulates, statistical correlations between scores and actual insurance premiums can be established, becoming a proprietary pricing basis

---

## 8. Risks and Challenges

### 8.1 Data Source Reliability

**Risk:** Oracle manipulation is the greatest threat to on-chain scoring systems. If an attacker controls AIS data sources or oil price APIs, they could artificially depress or inflate risk scores.

**Mitigation:**
- 3/5 multi-node consensus; any node's score deviation >10 points triggers dispute resolution
- At least 2 independent data sources per dimension for cross-verification
- Mandatory evidenceHash on-chain storage enables post-hoc auditing
- Emergency pause mechanism (`freezeMandate`) allows administrators to freeze all certificates when systemic anomalies are detected

### 8.2 AIS Data Quality Degradation

**Risk:** Increasing numbers of vessels in the Strait of Hormuz are switching off AIS transponders, making transit volume data unreliable [(National Security Journal, 2026-07-11)](https://nationalsecurityjournal.org/japan-just-pulled-almost-its-entire-merchant-fleet-out-of-the-gulf-a-quiet-exodus-that-says-everything-about-hormuz/).

**Mitigation:**
- Introduce satellite imagery analysis (already adopted by LSEG, Kpler) as AIS supplement
- When AIS shutdown rate exceeds 10%, the transit dimension is automatically marked as `DEGRADED`
- Scoring algorithm automatically expands uncertainty intervals when data quality degrades, with explicit notation on certificates

### 8.3 Regulatory Compliance

**Risk:** Resilience certificates may be classified as financial products (e.g., credit ratings), requiring compliance with financial product disclosure regulations in various jurisdictions.

**Mitigation:**
- Position resilience certificates as "information reference" rather than "investment advice" with explicit disclaimers
- Fully transparent scoring algorithm (evidenceHash is auditable), meeting algorithm transparency requirements
- Gradually establish standard co-creation relationships with maritime regulators (IMO, national maritime authorities)
- In strictly regulated financial markets (US, EU), obtain compliance advisor opinions in advance

### 8.4 Market Education

**Risk:** Traditional shipping and insurance industries have limited blockchain acceptance, potentially requiring years of education.

**Mitigation:**
- Phase 1 uses manual data entry, lowering technical barriers and letting customers experience value first
- Target insurers as the breakthrough — insurers naturally require objective, verifiable risk ratings
- Provide "off-chain" read interfaces (REST API querying on-chain data); customers need not interact with blockchain directly
- Partner with established brands like Lloyd's and Marsh, leveraging their industry credibility

### 8.5 Extreme War State Scenarios

**Risk:** Under full-scale war conditions, data sources may be completely disrupted (APIs unavailable, AIS fully shut down, insurers evacuated), making it impossible for the system to produce valid scores.

**Mitigation:**
- Score validity hard cap of 3 days; when data is interrupted, existing scores automatically expire
- Certificates include `validUntil` timestamps; expired certificates automatically invalidate
- Set a "data interruption" flag triggering manual review processes
- Maintain offline scoring contingency plans (based on last valid data + risk deterioration assumptions)

---

## 9. Conclusion

**Supply chain war risk rating is not a "nice-to-have" — it is "cannot-operate-without."** The Strait of Hormuz crisis has proven this with data: when transit volume plunges 98%, insurance premiums surge 40×, and a single tanker's transit insurance jumps from $250K to $6M [(Xinhua, 2026-07-11)](http://www.xinhuanet.com/fortune/20260711/e5a0070252ee42faa74cea3b4f694b50/c.html) [(gCaptain/Bloomberg, 2026-07-09)](https://gcaptain.com/hormuz-war-risk-cover-climbs-as-shipowners-pull-back/) — yet no system worldwide can rate these risks in real time with verifiable credentials.

The CompliancePassport contract's "Score → Certificate → Verify" pipeline is a proven architecture. Mapping `agentId` to `supplyChainRouteId`, compliance checks to war risk checks, compliance levels to resilience levels — this is not conceptual analogy but architectural reuse. ERC-8126's 0-100 risk scoring, ERC-8226's mandate and freeze mechanism, EIP-712's off-chain signing — every module finds a precise counterpart in the supply chain war risk scenario.

**Geopolitical risk normalization has already changed the foundational logic of global trade.** Professor Constantin Blome of the Stockholm School of Economics notes: "Supply chains have moved from the background of globalization to the center of geopolitical strategy" [(Stockholm School of Economics, 2026-06-12)](https://www.hhs.se/en/about-us/news/cfsr/2026/research-portrait-constantin-blome/). In this new reality, verifiable resilience ratings are not optional — they are a necessary component of trade infrastructure.

**Next Steps:**

1. Immediately launch Phase 1, deploying WarRiskPassport contract to testnet
2. Establish Phase 4 pre-partnership with Lloyd's or Marsh for insurance premium data access
3. Leverage the ongoing Hormuz crisis window to validate scoring algorithm accuracy and timeliness with real-time data
4. Complete Phases 2–3 within 6 months, launching a production-ready SaaS platform on mainnet

---

*This whitepaper is based on the CompliancePassport contract source code and publicly available market data as of July 2026. All market data includes source citations and dates.*
