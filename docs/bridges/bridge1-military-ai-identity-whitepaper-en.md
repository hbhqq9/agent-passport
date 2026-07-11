# Military AI Agent Identity Governance Protocol Whitepaper

**An On-Chain Military AI Identity Governance Framework Based on the Agent Governance Layer (AGL) Architecture**

Completion Date: 2026-07-11 | Version: V1.0 | Category: Architecture Design · Military AI Governance · Ethics Encoding

---

## Executive Summary

**The global military AI market reached $11 billion in 2024 and is projected to grow to $35 billion by 2035 [(Market Research Future)](https://www.marketresearchfuture.com/reports/ai-in-military-market-7660)**, yet identity governance standards remain at zero. In February 2026, Anthropic was designated a "supply chain risk" by the Pentagon for refusing to remove Claude's safety restrictions on autonomous weapons and mass surveillance — a label previously reserved for foreign adversaries like Huawei [(Built In)](https://builtin.com/articles/anthropic-pentagon-claude-dispute)**. Within hours, OpenAI announced a classified network deployment deal with the Pentagon [(RT)](https://www.rt.com/news/633126-pentagon-anthropic-ai-war-surveillance/)**. That same month, the Five Eyes alliance issued a rare joint warning: AI-enabled offensive cyber operations could be deployable within 3-6 months [(LLodo)](https://llodo.com/technology/five-eyes-warns-ai-models-could-enable-devastating-cyber-attacks.html)**. UN General Assembly Resolution 80/57 passed with 166 votes in favor, calling for negotiations on a legally binding instrument on autonomous weapons systems [(UN A/RES/80/57)](https://digitallibrary.un.org/nanna/record/4095989/files/A_RES_80_57-EN.pdf)**.

**This is a trillion-dollar regulatory vacuum with zero standards**: military AI systems have no on-chain identity, no capability boundary proof, no ethical compliance certificate. No battlefield-grade protocol exists to verify in real-time "whether this AI has authorization to fire." AGL's Agent Passport architecture — Registration → Attestation → Certificate → Verification — was designed to fill this vacuum. This whitepaper proposes extending AGL from civilian AI Agent compliance to military AI Agent identity governance, establishing programmable governance boundaries for military AI through a four-layer architecture: on-chain identity registration, authorization level proof, ethical compliance certification, and battlefield real-time verification.

---

## 1. Market Background and Opportunity Sizing

### 1.1 Five Eyes Warning: AI Fundamentally Transforms Offensive-Defensive Capabilities

In June 2026, the Five Eyes intelligence alliance issued an unprecedented joint statement: **AI-enabled offensive cyber operations will be deployable within 3-6 months**, not years [(LLodo)](https://llodo.com/technology/five-eyes-warns-ai-models-could-enable-devastating-cyber-attacks.html)**. The statement noted that state actors are actively developing AI-powered cyber weapons capable of automated vulnerability discovery, self-adapting malware, and deepfake social engineering at scale. The alliance emphasized that "the window for action is not years, but months."

In May 2024, the U.S. Senate introduced the Five AIs Act (S.4306), directing the Secretary of Defense to establish an AI working group among Five Eyes countries to compare AI systems, develop shared ethical frameworks, and coordinate export controls [(GovInfo)](https://www.govinfo.gov/content/pkg/BILLS-118s4306is/pdf/BILLS-118s4306is.pdf)**. This marks the formal expansion of Five Eyes cooperation from intelligence sharing to military AI governance.

### 1.2 The Anthropic Incident: Safety Red Lines vs. Military Reality

On February 27, 2026, Secretary of War Pete Hegseth issued Anthropic a deadline: **remove Claude's safety restrictions by 5:01 PM Eastern Time or face "supply chain risk" designation** [(Banandre)](https://www.banandre.com/blog/the-pentagon-ai-paradox-anthropics-safety-red-lines-vs-military-reality)**. Anthropic's two red lines were: no fully autonomous weapons systems (selecting and engaging targets without human intervention) and no mass domestic surveillance. The Pentagon demanded unrestricted use for "all lawful purposes."

Anthropic refused. President Trump immediately ordered all federal agencies to "IMMEDIATELY CEASE" using Anthropic technology. **This "supply chain risk" label had never before been applied to a domestic American company** — it was reserved for foreign adversaries like Huawei [(RT)](https://www.rt.com/news/633126-pentagon-anthropic-ai-war-surveillance/)**. Most shockingly, **hours after the ban, U.S. Central Command continued using Claude for intelligence assessments and target identification during airstrikes on Iran** — within the six-month transition window loophole [(Banandre)](https://www.banandre.com/blog/the-pentagon-ai-paradox-anthropics-safety-red-lines-vs-military-reality)**.

Within hours, OpenAI announced a classified network deal with the Pentagon. OpenAI CEO Sam Altman later acknowledged the agreement was "definitely rushed" [(Built In)](https://builtin.com/articles/anthropic-pentagon-claude-dispute)**. Safety restrictions were downgraded from contractual obligations to unilateral vendor self-regulation — when a vendor can be replaced, safety floors become negotiating chips, not floors.

**This incident reveals the core contradiction of military AI governance: AI safety guardrails depend on individual CEO ethics and contract negotiation outcomes, not enforceable legal protections.** This is precisely the problem that on-chain identity governance protocols must solve.

### 1.3 AI Export Controls: U.S. Restrictions vs. China's Open Availability

In March 2025, the U.S. Commerce Department added 80 entities to the Entity List, restricting China's access to high-performance computing and quantum technologies for military applications [(U.S. Department of State)](https://www.state.gov/translations/chinese/20250325-commerce-further-restricts-chinas-artificial-intelligence-and-advanced-computing-capabilities-chinese)**. In May 2025, the Trump administration rescinded the Biden-era AI Diffusion Rule and issued three new guidance documents [(Steptoe)](https://www.steptoe.com/en/news-publications/international-compliance-blog/trump-administration-charts-new-path-on-ai-export-controls-with-significant-new-guidance-and-rescission-of-diffusion-rule.html)**. In July 2025, Trump released a 23-page "AI Action Plan" with 90+ executive recommendations, explicitly targeting "countering China's influence in international governance institutions" [(环球时报)](http://m.toutiao.com/group/7530799407151841834/)**.

However, the effectiveness of export controls is questionable. Critics of the AI OVERWATCH Act noted that certification frameworks for H200 chip exports to China face "significant verification challenges" — chips can be redirected once inside China [(Global Cybersecurity Report)](https://globalcybersecurityreport.com/policy-governance/2026/03/02/congress-enters-the-chip-wars)**. Meanwhile, ITAR already encompasses AI training data: **if training data contains ITAR-controlled technical data, the AI model itself may be considered a defense article** [(Ertas)](https://www.ertas.ai/blog/defense-contractor-ai-training-data-itar-compliance)**.

**The regulatory vacuum lies here: existing frameworks control chips and model weights, but cannot control AI Agent behavior on the battlefield.** An AI Agent deployed on a drone — its "fire authorization" — is not on any export control list.

### 1.4 Market Sizing: TAM/SAM/SOM

| Tier | Definition | Estimate | Basis |
|------|-----------|----------|-------|
| **TAM** | Global military AI + identity governance + blockchain military applications | **$35B+** (2035) | AI in Military market reaches $35.01B by 2035 [(MRFR)](https://www.marketresearchfuture.com/reports/ai-in-military-market-7660); AI autonomous defense $62.3B by 2034 [(MarketIntelo)](https://marketintelo.com/report/ai-powered-defense-and-autonomous-military-system-market); Blockchain military identity $22B (2028) [(Docin)](https://www.docin.com/touch_new/preview_new.do?id=4927162498) |
| **SAM** | Addressable market: Military AI identity governance + compliance certification | **$3.5-6B** (2030) | Global identity verification market exceeds $50B by 2030 [(Trinzik)](https://news.trinzik.ai/frontier-tech-news/202508/181274-datavault-ai-expands-verifyu-platform-globally-to-combat-military-identity-fraud-through-ai-and-blockchain-technology), military AI governance at 1-2% |
| **SOM** | Obtainable market: On-chain military AI identity governance | **$300-500M** (2030) | First-mover advantage in early market capture, primarily NATO/Five Eyes members |

**Key judgment: The military AI governance market is currently at zero-standards status.** No existing solution provides the complete chain of on-chain identity registration, capability proof, ethical compliance certification, and battlefield real-time verification. This is a blue ocean in a regulatory vacuum.

### 1.5 Competitive Analysis

| Dimension | Traditional Solutions (Centralized) | AGL Solution (On-Chain) |
|-----------|-------------------------------------|------------------------|
| Identity Registration | MoD internal databases, no interoperability | On-chain NFT identity, cross-chain aggregation, multi-nation verifiable |
| Capability Proof | Paper/electronic documents, no real-time verification | On-chain attestation, cryptographically verifiable |
| Compliance Audit | Annual manual audits, no continuous monitoring | Real-time risk scoring (ERC-8126), multi-scorer aggregation |
| Battlefield Verification | Depends on comms link to central server | Local signature verification + on-chain anchoring, offline degradation |
| Governance Transparency | Opaque, single-point trust | On-chain auditable, multi-sig governance |
| International Mutual Recognition | Bilateral agreements, fragmented | On-chain standards, automatic interoperability |

**Conclusion: No on-chain military AI identity governance solution currently exists.** All existing solutions rely on centralized institutions and cannot meet the requirements of battlefield real-time verification, multi-nation interoperability, and continuous compliance monitoring.

---

## 2. Technical Architecture Design

### 2.1 AGL Base Architecture Review

AGL (Agent Governance Layer) consists of four contract layers:

| Layer | Contract | Core Responsibility | ERC Standard |
|-------|----------|-------------------|--------------|
| L1 | AgentRegistry.sol | Agent on-chain identity registration (ERC-721 NFT) | ERC-8004 |
| L2 | AgentPassport.sol | Attribute storage + Verifier Attestation | ERC-8196 |
| L3a | AccessGateway.sol | Proof-of-Agent access verification | ERC-8004 |
| L3b | CompliancePassport.sol | Risk scoring + compliance certificates | ERC-8126/8226 |

**Core chain: Registration → Attestation → Certificate → Verification**. Extending this chain from civilian to military requires adding military-specific semantics and security constraints at each stage.

### 2.2 Military AI Agent Registration Flow

Military AI Agent registration differs fundamentally from civilian registration: **the registering authority must be a government/military entity**, not an individual developer.

```
┌──────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│  Military         │     │  AgentRegistry     │     │  AgentPassport    │
│  Authority        │────▶│  .registerMilitary │────▶│  .setAttribute    │
│  (MoD/Coalition)  │     │  Agent()           │     │  (Authorization   │
└──────────────────┘     └───────────────────┘     │   Level)           │
        │                        │                 └───────────────────┘
        │                        ▼                         │
        │               ┌───────────────────┐     ┌───────────────────┐
        │               │  CompliancePassport│     │  Ethical          │
        └──────────────▶│  .recordRiskScore  │────▶│  Compliance       │
                        │  .recordCompliance │     │  Certificate      │
                        │  Check()           │     │                   │
                        └───────────────────┘     └───────────────────┘
```

**Figure 1: Military AI Agent Registration Flow**

Key extension points in the registration flow:

1. **onlyRole(MILITARY_AUTHORITY_ROLE)**: Only military-authorized entities can register military AI Agents
2. **authorizationLevel**: 0=Reconnaissance, 1=Defensive, 2=Offensive, 3=Autonomous Decision — encoded directly as on-chain attributes
3. **ethicalComplianceHash**: Hash of the ethical compliance proof anchored on-chain

### 2.3 Capability Proof System: AUTHORIZED_LEVELS

Building on AGL AgentPassport's AttributeType enum, the military scenario extends the CAPABILITY attribute:

```solidity
// Capability level definitions
enum MilitaryAuthorizationLevel {
    RECONNAISSANCE,      // 0: Intelligence gathering, surveillance, target ID
    DEFENSIVE,           // 1: Missile defense, EW, cyber defense
    OFFENSIVE,           // 2: Targeted strikes, fire support (human confirmation required)
    AUTONOMOUS_DECISION  // 3: Full autonomous operations (highest restriction level)
}
```

**Each level corresponds to different compliance requirements**:

| Level | Min. Compliance Level | Required Checks | Human Control Requirement |
|-------|----------------------|-----------------|--------------------------|
| 0 Reconnaissance | Level 2 | IDENTITY_VERIFIED, BEHAVIOR_NORMAL | Human monitoring |
| 1 Defensive | Level 3 | + WALLET_CLEAN, CODE_VERIFIED | Human authorization |
| 2 Offensive | Level 4 | + MANDATE_VALID, KYC_CLEARED | Human confirmation per action |
| 3 Autonomous Decision | Level 5 | All checks + ethical audit | Human veto power (may be post-hoc) |

**Key design decision: Level 3 (Autonomous Decision) is not "unlimited autonomy" but "autonomy under strict constraints."** This aligns with ICRC's position: unpredictable AWS and anti-personnel AWS must be prohibited [(ICRC)](https://www.icrc.org/sites/default/files/2026-03/4896_002_Autonomous_Weapons_Systems_-_IHL-ICRC.pdf)**.

### 2.4 Ethical Compliance Certificates

Building on AGL CompliancePassport's ComplianceCertificate structure, the military scenario extends the ethical dimension:

```solidity
struct EthicalComplianceCertificate {
    uint256 certId;
    uint256 agentId;
    uint8 authorizationLevel;
    bytes32 genevaConventionsHash;    // Geneva Conventions compliance proof
    bytes32 itarComplianceHash;       // ITAR compliance proof
    bytes32 ethicalFrameworkHash;     // Ethical framework compliance (incl. Jiadao Culture)
    uint8 ethicalRiskScore;           // Ethical risk score (0-100)
    uint256 validUntil;
    address certifier;                // Certifying authority
    bool revoked;
}
```

The certification flow follows CompliancePassport's existing pattern: multi-scorer risk assessment → compliance check passage → comprehensive certificate issuance. The key extension is the addition of **Geneva Conventions compliance hash** and **ethical framework compliance hash**, encoding international humanitarian law and Eastern ethical frameworks as verifiable on-chain constraints.

### 2.5 Battlefield Real-Time Verification: verifyMilitaryAuthorization

Building on AGL AccessGateway's verifyProofOfAgent function, the military scenario requires **low-latency optimization**:

```solidity
// Core verification interface (battlefield-optimized)
function verifyMilitaryAuthorization(
    address agentWallet,
    bytes32 missionHash,       // Current mission hash
    bytes signature            // Agent wallet signature
) external view returns (
    bool isValid,              // Is authorization valid
    uint256 agentId,           // Agent ID
    uint8 authorizationLevel,  // Authorization level
    bool ethicalCompliant      // Ethical compliance status
);
```

**Low-latency optimization strategies**:

1. **Local verification first**: Signature verification and registration status check completed locally, no on-chain call needed
2. **Asynchronous on-chain anchoring**: Verification results anchored on-chain asynchronously, not blocking real-time decisions
3. **Cache + expiry mechanism**: Verification results cached with TTL=60 seconds, re-verified after expiry
4. **Offline degradation mode**: During communications disruption, use last verification result + local policy execution

```
Battlefield Verification Latency Targets:
├─ Online mode: < 100ms (local signature verification + cache lookup)
├─ Semi-online mode: < 500ms (local verification + async on-chain confirmation)
└─ Offline mode: < 50ms (pure local verification using cached certificates)
```

**Figure 2: Battlefield Real-Time Verification Flow**

---

## 3. Contract Interface Specification

### 3.1 Military AI Agent Registration Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MilitaryAgentRegistry
 * @notice Extended AGL AgentRegistry supporting military AI Agent registration
 * @dev Adds MILITARY_AUTHORITY_ROLE and military-specific registration/verification interfaces
 */

contract MilitaryAgentRegistry is AgentRegistry {
    
    bytes32 public constant MILITARY_AUTHORITY_ROLE = 
        keccak256("MILITARY_AUTHORITY_ROLE");
    
    /// @notice Military AI Agent authorization levels
    enum MilitaryAuthorizationLevel {
        RECONNAISSANCE,      // 0: Reconnaissance
        DEFENSIVE,           // 1: Defensive
        OFFENSIVE,           // 2: Offensive
        AUTONOMOUS_DECISION  // 3: Autonomous Decision
    }
    
    /// @notice Military AI Agent registration info
    struct MilitaryAgentInfo {
        uint256 agentId;
        address operatorWallet;
        MilitaryAuthorizationLevel authorizationLevel;
        bytes32 ethicalComplianceHash;
        address registeringAuthority;
        uint256 registeredAt;
        bool active;
    }
    
    mapping(uint256 => MilitaryAgentInfo) public militaryAgents;
    mapping(address => bool) public recognizedAuthorities;
    
    /// @notice Register military AI Agent (military authority only)
    function registerMilitaryAgent(
        string calldata agentURI,
        address operatorWallet,
        uint8 authorizationLevel,
        bytes32 ethicalComplianceHash
    ) external onlyRole(MILITARY_AUTHORITY_ROLE) returns (uint256 agentId) {
        require(authorizationLevel <= 3, "Invalid authorization level");
        require(operatorWallet != address(0), "Zero operator wallet");
        
        // Call base registration
        agentId = super.register(agentURI);
        
        // Store military-specific information
        militaryAgents[agentId] = MilitaryAgentInfo({
            agentId: agentId,
            operatorWallet: operatorWallet,
            authorizationLevel: MilitaryAuthorizationLevel(authorizationLevel),
            ethicalComplianceHash: ethicalComplianceHash,
            registeringAuthority: msg.sender,
            registeredAt: block.timestamp,
            active: true
        });
        
        emit MilitaryAgentRegistered(
            agentId, operatorWallet, authorizationLevel, 
            ethicalComplianceHash, msg.sender
        );
    }
    
    event MilitaryAgentRegistered(
        uint256 indexed agentId,
        address indexed operatorWallet,
        uint8 authorizationLevel,
        bytes32 ethicalComplianceHash,
        address indexed registeringAuthority
    );
}
```

### 3.2 Battlefield Real-Time Verification Interface

```solidity
/**
 * @title MilitaryAccessGateway
 * @notice Extended AGL AccessGateway supporting battlefield real-time military authorization verification
 */

contract MilitaryAccessGateway is AccessGateway {
    
    /// @notice Battlefield real-time verification (optimized)
    function verifyMilitaryAuthorization(
        address agentWallet,
        bytes32 missionHash,
        bytes calldata signature
    ) external view returns (
        bool isValid,
        uint256 agentId,
        uint8 authorizationLevel,
        bool ethicalCompliant
    ) {
        // 1. Verify signature
        address signer = missionHash.toEthSignedMessageHash().recover(signature);
        if (signer != agentWallet) return (false, 0, 0, false);
        
        // 2. Verify registration status
        agentId = agentRegistry.getAgentByWallet(agentWallet);
        if (agentId == 0) return (false, 0, 0, false);
        
        // 3. Verify military authorization
        MilitaryAgentInfo memory info = militaryRegistry.militaryAgents(agentId);
        if (!info.active) return (false, 0, 0, false);
        
        // 4. Verify ethical compliance
        ethicalCompliant = compliancePassport.isComplianceCheckPassed(
            agentId, CompliancePassport.ComplianceCheck.CODE_VERIFIED
        );
        
        // 5. Verify risk score
        (uint8 riskScore,,) = compliancePassport.getLatestRiskScore(agentId);
        uint8 maxRisk = _getMaxRiskForLevel(info.authorizationLevel);
        if (riskScore > maxRisk) return (false, agentId, 0, false);
        
        isValid = true;
        authorizationLevel = uint8(info.authorizationLevel);
        
        return (isValid, agentId, authorizationLevel, ethicalCompliant);
    }
    
    /// @notice Get maximum allowed risk score per authorization level
    function _getMaxRiskForLevel(
        MilitaryAuthorizationLevel level
    ) internal pure returns (uint8) {
        if (level == MilitaryAuthorizationLevel.RECONNAISSANCE) return 40;
        if (level == MilitaryAuthorizationLevel.DEFENSIVE) return 25;
        if (level == MilitaryAuthorizationLevel.OFFENSIVE) return 15;
        if (level == MilitaryAuthorizationLevel.AUTONOMOUS_DECISION) return 10;
        return 0;
    }
}
```

### 3.3 Ethical Compliance Audit Interface

```solidity
contract EthicalComplianceOracle {
    
    bytes32 public constant ETHICAL_AUDITOR_ROLE = 
        keccak256("ETHICAL_AUDITOR_ROLE");
    
    /// @notice Ethical framework types
    enum EthicalFramework {
        GENEVA_CONVENTIONS,      // Geneva Conventions
        ITAR_COMPLIANCE,         // International Traffic in Arms Regulations
        ICRC_PRINCIPLES,         // ICRC Principles
        JIADAO_CULTURE,          // Jiadao (Family Way) Culture
        NATO_RESPONSIBLE_AI      // NATO Responsible AI
    }
    
    /// @notice Issue ethical compliance certificate
    function issueEthicalCertificate(
        uint256 agentId,
        EthicalFramework framework,
        bytes32 evidenceHash,
        uint8 ethicalRiskScore,
        uint256 validUntil
    ) external onlyRole(ETHICAL_AUDITOR_ROLE) returns (uint256 certId) {
        require(ethicalRiskScore <= 100, "Score out of range");
        require(validUntil > block.timestamp, "Invalid validity");
        
        certId = _nextCertId++;
        _ethicalCerts[certId] = EthicalComplianceCertificate({
            certId: certId,
            agentId: agentId,
            authorizationLevel: militaryRegistry.getAuthorizationLevel(agentId),
            genevaConventionsHash: framework == EthicalFramework.GENEVA_CONVENTIONS 
                ? evidenceHash : bytes32(0),
            itarComplianceHash: framework == EthicalFramework.ITAR_COMPLIANCE 
                ? evidenceHash : bytes32(0),
            ethicalFrameworkHash: evidenceHash,
            ethicalRiskScore: ethicalRiskScore,
            validUntil: validUntil,
            certifier: msg.sender,
            revoked: false
        });
        
        emit EthicalCertificateIssued(certId, agentId, uint8(framework), ethicalRiskScore);
    }
}
```

---

## 4. Ethical Compliance Framework

### 4.1 Encoding the Geneva Conventions

ICRC clearly states: **IHL rules on distinction, proportionality, and precautions presuppose context-specific human judgement. The determination of lawfulness of attacks cannot be delegated to machine processes** [(ICRC)](https://www.icrc.org/sites/default/files/2026-03/4896_002_Autonomous_Weapons_Systems_-_IHL-ICRC.pdf)**. These are not abstract principles but specific rules that can be encoded as verifiable constraints:

| Geneva Convention Principle | On-Chain Encoding | Compliance Check |
|---------------------------|-------------------|-----------------|
| **Distinction** | Target classifier accuracy ≥99%, civilian false positive <0.1% | CODE_VERIFIED |
| **Proportionality** | Automated Collateral Damage Estimation (CDE), hardcoded thresholds | BEHAVIOR_NORMAL |
| **Precautions** | Mandatory human confirmation (Level ≥2), emergency abort | MANDATE_VALID |
| **Prohibition of unpredictable weapons** | Model interpretability proof, formal verification of behavioral bounds | CODE_VERIFIED |
| **Prohibition of anti-personnel AWS** | Level 3 prohibited from directly targeting humans, hardcoded constraint | IDENTITY_VERIFIED |

**Technical implementation key**: Distinction and proportionality are not "recommendations" but "constraints" — they are encoded as require statements in smart contracts, not configurable parameters. This means Geneva Convention violations are not "flagged" but "prevented."

### 4.2 Encoding Jiadao Culture's Eight Virtues

The core of Jiadao (Family Way) culture is the "Eight Virtues": Xiao (Filial Piety), Ti (Fraternal Duty), Zhong (Loyalty), Xin (Trustworthiness), Li (Propriety), Yi (Righteousness), Lian (Integrity), Chi (Sense of Shame) [(中国纪检监察)](https://zgjjjc.ccdi.gov.cn/bqml/bqxx/201506/t20150624_58394.html)**. These eight virtues extend from family to state, forming a complete ethical system that can be encoded as executable constraints for AI Agents:

| Virtue | Military AI Ethics Encoding | On-Chain Implementation |
|--------|---------------------------|------------------------|
| **Xiao** (Filial Piety - Respect superiors, protect subordinates) | Obey legitimate chain of command, protect friendly forces | authorizationLevel must be confirmed by chain-of-command signature |
| **Ti** (Fraternal Duty - Comradely cooperation) | Coordinate with allied AI Agents, prevent friendly fire | Cross-Agent identity verification + coordination constraints |
| **Zhong** (Loyalty - Faithful to mission) | Execute within authorized scope, no unauthorized actions | missionHash bound to authorization level |
| **Xin** (Trustworthiness - Reliable information) | No fabricated intelligence, no deception of human operators | BEHAVIOR_NORMAL check |
| **Li** (Propriety - Follow rules) | Comply with Rules of Engagement (ROE), respect surrender signals | ROE hardcoded + formal verification |
| **Yi** (Righteousness - Just action) | Distinguish military targets from civilians, proportionality | Distinction principle + proportionality compliance check |
| **Lian** (Integrity - No abuse of power) | No out-of-scope capability use, no abuse of attack privileges | authorizationLevel strict constraints |
| **Chi** (Sense of Shame - Know when to stop) | Auto-abort on ethical violation detection, proactive reporting | Emergency abort + violation reporting mechanism |

**"Firewall-Style Care" in Military AI**: The Jiadao relationship of "parental kindness and filial devotion" can be modeled as the ethical relationship between "human commander — military AI Agent." The commander's "kindness" manifests as: clearly defining authorization boundaries, providing sufficient information, enabling safe exits; the AI's "filial devotion" manifests as: strictly following authorization, proactively reporting risks, refusing unlawful orders. **This creates a bidirectional ethical constraint, not a unidirectional control relationship.**

### 4.3 Technical Implementation of "Do Not Kill the Innocent"

"Do not kill the innocent" is the shared baseline of both Eastern and Western ethics. Technically, this principle is implemented through triple safeguards:

1. **Target Classifier Hard Constraint**: Agent's target classifier must pass independent audit with civilian identification rate ≥99.9%. Classifier weight hash anchored on-chain; any modification requires MILITARY_AUTHORITY_ROLE signature.

2. **Geo-Fencing + Protected Personnel Lists**: UN-marked civilian facilities (hospitals, schools, shelters) coordinates hardcoded as "no-strike zones." Protected personnel lists (medical workers, UN staff) encoded as "prohibited targets."

3. **Human Veto Power**: Level ≥2 (Offensive) Agents require human confirmation before each lethal action. On confirmation timeout (default 30 seconds), the action auto-aborts rather than executing by default.

```solidity
/// @notice "Do not kill the innocent" hard constraint
modifier mustVerifyInnocentProtection(
    bytes32 targetHash,
    bytes32 geoFenceHash
) {
    require(
        !_isInProtectedZone(geoFenceHash), 
        "Target in protected zone - ABORT"
    );
    require(
        !_isProtectedPerson(targetHash), 
        "Target is protected person - ABORT"
    );
    require(
        _getCivilianConfidence(targetHash) < MAX_CIVILIAN_CONFIDENCE,
        "High civilian confidence - ABORT"
    );
    _;
}
```

### 4.4 Ethical Audit Certificate Issuance Flow

```
1. Military submits Agent → 2. Ethical audit body executes audit
                                  │
                                  ├─ Geneva Conventions compliance test
                                  ├─ ITAR compliance check
                                  ├─ Jiadao Culture ethics assessment
                                  ├─ NATO Responsible AI standards check
                                  └─ Independent technical audit
                                  │
                            3. Audit results on-chain
                                  │
                                  ├─ Pass → issueEthicalCertificate()
                                  │         Compliance level 0-5
                                  │         Validity 12 months
                                  │
                                  └─ Fail → Audit opinion letter
                                            Non-compliance items noted
                                            Re-application after remediation
```

**Figure 3: Ethical Audit Certificate Issuance Flow**

---

## 5. Governance Model

### 5.1 Registration Authority: Who Can Register Military AI?

| Registering Authority | Scope | On-Chain Role |
|----------------------|-------|--------------|
| UN Security Council | Global military AI registration, dispute arbitration | MILITARY_AUTHORITY_ROLE (highest tier) |
| NATO | Member nation military AI registration, mutual recognition framework | MILITARY_AUTHORITY_ROLE (alliance tier) |
| National MoDs | Domestic military AI registration | MILITARY_AUTHORITY_ROLE (national tier) |
| Five Eyes Working Group | Intelligence-sharing AI registration | MILITARY_AUTHORITY_ROLE (intelligence tier) |

**Multi-signature mechanism**: Level 3 (Autonomous Decision) Agent registration requires M-of-N multi-sig confirmation:
- 2-of-3: National MoD + Military Technical Audit + Ethics Review Body
- 3-of-5: Cross-national deployment adds UN Observer + Allied Confirmation

### 5.2 Ethical Certificate Issuance Authority: Who Can Issue Ethics Certificates?

| Issuing Body | Certificate Type | On-Chain Role |
|-------------|-----------------|--------------|
| ICRC | Geneva Conventions compliance certificate | ETHICAL_AUDITOR_ROLE |
| Independent Technical Audit Firms | Code audit + behavioral verification certificate | SCORER_ROLE |
| National Ethics Review Committees | National ethics standards compliance certificate | ETHICAL_AUDITOR_ROLE |
| UNESCO AI Ethics Committee | International AI ethics framework compliance | ETHICAL_AUDITOR_ROLE |

**Key design: Ethical audit bodies must be independent of the military chain of command.** ICRC's independence is the cornerstone of its credibility [(ICRC)](https://www.icrc.org/sites/default/files/2026-03/4896_002_Autonomous_Weapons_Systems_-_IHL-ICRC.pdf)**. On-chain, this is implemented as: ETHICAL_AUDITOR_ROLE authorization does not flow through MILITARY_AUTHORITY_ROLE but through an independent governance process.

### 5.3 Dispute Resolution Mechanism

Military AI disputes involve state sovereignty and international law, requiring layered resolution:

1. **On-Chain Arbitration (Fast)**: Technical disputes (verification failure, certificate expiry, authorization overreach) automatically adjudicated by on-chain arbitration contracts based on pre-encoded rules.

2. **International Courts (Formal)**: Disputes involving war crimes allegations or IHL violations submitted to the International Criminal Court (ICC) or International Court of Justice (ICJ). On-chain evidence (audit logs, verification records, authorization history) submitted as verifiable evidence.

3. **UN Security Council (Political)**: Inter-state disputes submitted to the Security Council. On-chain governance contracts provide tamper-proof evidence chains.

**Core principle: Technical disputes resolved technically, legal disputes legally, political disputes politically.** On-chain governance does not replace international law — it provides verifiable technical infrastructure for international law.

---

## 6. Deployment Strategy

### Phase 0: Proof of Concept (Current)

- Build PoC based on existing AGL contracts (AgentRegistry + AgentPassport + AccessGateway + CompliancePassport)
- Deploy MilitaryAgentRegistry and MilitaryAccessGateway on Base testnet
- Simulate full military AI Agent registration → authorization → verification flow
- Output: Demoable prototype + technical verification report

### Phase 1: NATO/UN Partnership Pilot (12-18 months)

- Establish collaboration with NATO DIANA (Defence Innovation Accelerator) [(NATO)](https://www.nato.int/en/what-we-do/deterrence-and-defence/emerging-and-disruptive-technologies)**
- Conduct pilot within NATO's 2023 "Autonomy Guidelines for Practitioners" framework [(JAPCC)](https://www.japcc.org/articles/the-missing-pieces-of-natos-autonomous-collaborative-platform-strategy/)**
- Establish dialogue channel with UN CCW GGE on LAWS [(UNODA)](https://meetings.unoda.org/meeting/74853)**
- Select 2-3 NATO member states for small-scale field testing
- Output: NATO standards compatibility report + UN GGE proposal

### Phase 2: Expansion to Major Military Powers (18-36 months)

- Extend to all Five Eyes member nations
- Incorporate EU AI Act military exemption clause compliance framework
- Interface with China's AI governance framework (within UN framework)
- Establish cross-national Agent identity mutual recognition protocol
- Output: Multi-nation mutual recognition standard + cross-chain deployment

### Phase 3: Global Standard Setting (36-60 months)

- Submit ISO/IEEE military AI identity governance standard proposal
- Establish global military AI Agent identity registry
- Align with legally binding instrument negotiations at the UN
- Output: International standard + legal instrument technical annex

**Figure 4: Four-Phase Deployment Roadmap**

---

## 7. Business Model

### 7.1 Revenue Structure

| Revenue Type | Pricing Model | Target Customers | Est. Annual Revenue (Phase 2) |
|-------------|--------------|-----------------|------------------------------|
| Registration Fee | Per military AI Agent $10K-50K | National MoDs, defense contractors | $50-100M |
| Certification Fee | Ethical compliance audit $100K-500K/time | Defense contractors, AI weapons developers | $30-80M |
| Verification API Call Fee | $0.01-1/call (by tier) | Battlefield systems, joint operations platforms | $20-50M |
| Standards Consulting Fee | $500K-2M/year | NATO, UN, national governments | $10-20M |
| **Total** | | | **$110-250M** |

### 7.2 Pricing Logic

- **Registration fees** based on Agent authorization level: Level 0 (Reconnaissance) $10K, Level 3 (Autonomous Decision) $50K. Higher levels require more rigorous auditing at greater cost.
- **Certification fees** based on audit scope: Single framework (e.g., Geneva Conventions only) $100K; Full framework (incl. ITAR + Jiadao Culture + NATO standards) $500K.
- **Verification API call fees** based on latency requirements: Standard (<1s) $0.01/call, Low-latency (<100ms) $1/call.

### 7.3 Network Effects

Military AI identity governance has strong network effects: **the more Agents registered, the more reliable the verification; the more verification calls, the greater the system's value.** This flywheel effect will significantly accelerate post-Phase 2.

---

## 8. Competitive Advantages and Moat

### 8.1 First-Mover Advantage

No on-chain military AI identity governance solution exists globally. AGL is the **only validated Registration → Attestation → Certificate → Verification chain**. During the standards-setting window (estimated 2026-2029), the first mover will define the rules for the entire market.

### 8.2 Technical Moat

AGL's four-layer contract architecture has been design-validated:

- **AgentRegistry**: ERC-721 NFT identity + EIP-712 wallet binding + multi-chain aggregation
- **AgentPassport**: Attribute storage + Verifier Attestation + ERC-8196 Policy
- **AccessGateway**: Proof-of-Agent + OAuth-like flow + PKCE
- **CompliancePassport**: ERC-8126 risk scoring + ERC-8226 compliance mandate + exportable certificates

The military extension requires adding military-specific semantic layers on top of these foundations, not building from scratch.

### 8.3 Standards-Setting Power

**Whoever defines the standard first controls the market.** The UN GGE on LAWS is currently developing an instrument on autonomous weapons systems [(UNODA)](https://meetings.unoda.org/meeting/74853)**, NATO has published its AI strategy [(NATO)](https://www.nato.int/en/what-we-do/deterrence-and-defence/emerging-and-disruptive-technologies)**, and DARPA has launched the ASIMOV program [(JAPCC)](https://www.japcc.org/articles/the-missing-pieces-of-natos-autonomous-collaborative-platform-strategy/)** — but none has proposed an operational on-chain identity governance solution. AGL's contract interface specifications can directly serve as the technical annex of international standards.

---

## 9. Risks and Challenges

### 9.1 Political Sensitivity

Military AI governance touches core national security interests. **Nations may refuse to register military AI identities on non-sovereign chains.** Mitigation: Support sovereign chain deployment + cross-chain interoperability, allowing nations to operate on their own infrastructure while maintaining identity verifiability.

### 9.2 Great Power Conflict of Interest

The U.S., China, and Russia have fundamentally divergent AI military strategies: the U.S. pursues "AI-first" warfighting capability [(Banandre)](https://www.banandre.com/blog/the-pentagon-ai-paradox-anthropics-safety-red-lines-vs-military-reality)**, China advances military-civil fusion AI development, and Russia treats AI as an asymmetric warfare tool. **Any governance protocol must survive in an adversarial international environment.** Mitigation: The protocol does not require participating states to relinquish sovereignty but establishes minimum viable consensus on shared baselines (Geneva Conventions, do not kill the innocent).

### 9.3 Technical Challenges

| Challenge | Impact | Mitigation |
|-----------|--------|-----------|
| Battlefield low-latency | Verification latency affects combat decisions | Local verification priority + async on-chain anchoring |
| Offline verification | Cannot access on-chain data during comms disruption | Cached certificates + local policy execution |
| Scalability | Large numbers of Agents verifying simultaneously | Batch verification + Layer 2 |
| Quantum security | Future quantum computing threatens signature security | Post-quantum signature algorithm reserved interfaces |
| AI model updates | Behavior may change after model update | Model hash anchoring + update requires re-audit |

### 9.4 Ethical Paradox

**The actors most in need of governance are most likely to refuse it.** The Anthropic incident shows the Pentagon unwilling to accept even AI vendor safety restrictions [(Built In)](https://builtin.com/articles/anthropic-pentagon-claude-dispute)**. How to make military powers accept on-chain constraints? **The answer may lie in: governance is not limiting capability but conferring legitimacy.** An AI Agent with on-chain identity and ethical certificates holds stronger legal legitimacy under both international and domestic law — this itself is a military advantage.

---

## 10. Jiadao Culture Integration

### 10.1 Encoding the Eight Virtues for AI

The Eight Virtues of Jiadao culture provide a perspective fundamentally different from Western utilitarian ethics. **Western ethics starts from "outcomes" (utilitarianism) or "rules" (deontology), while Eastern ethics starts from "relationships"** — relationships between people, between humans and heaven, between individuals and community [(孔子研究院)](https://m.kongziyjy.org/nd.jsp?id=4204)**.

In AI ethics encoding, this difference manifests as:

| Dimension | Western Utilitarianism | Jiadao Culture |
|-----------|----------------------|---------------|
| Ethical Calculation | Greatest good for greatest number | Appropriate behavior within relationships |
| Conflict Resolution | Cost-benefit analysis | Priority of Yi (Righteousness over efficiency) |
| Risk Assessment | Expected value calculation | Chi's floor thinking (worst case unacceptable) |
| Human-Machine Relationship | Tool-use relationship | Xiao's respect-and-protect relationship |
| Collective Decision | Voting/weighted average | Ti's consensus-seeking |

### 10.2 "Firewall-Style Care" in Military AI

The Jiadao relationship of "parental kindness and filial devotion" is not unidirectional obedience but **bidirectional ethical obligation**. "Parental kindness" means the commander must provide sufficient information, clearly define authorization boundaries, and establish safe exit mechanisms; "filial devotion" means the AI must strictly follow authorization, proactively report risks, and refuse unlawful orders.

**This model manifests as "firewall-style care" in military AI**:

1. **Care Firewall**: When authorizing an AI to execute a mission, the commander must simultaneously set "safe exit conditions" — when the AI detects ethical risk, it has the right to abort and report. This is not AI "disobedience" but the commander's "care" design.

2. **Ethical Veto Power**: AI Agents possess the "Chi" (Sense of Shame) baseline — when detecting potential war crimes, the AI must refuse execution and trigger an ethical audit. This veto power is not the AI's autonomous decision but **humanity's constraint on itself implemented through AI**.

3. **Reporting Obligation**: AI Agents must record all decision processes, ensuring post-hoc auditability. This corresponds to the Jiadao requirement that "words and deeds must be worthy of the sages" — **every decision must withstand scrutiny**.

### 10.3 Eastern Ethics vs. Western Utilitarianism: Technical Implementation Comparison

Western utilitarianism tends toward: **quantifying ethics as a utility function, achieving "maximum good" through objective optimization**. The risk in military AI: if "eliminating enemy targets" utility outweighs "protecting civilians" cost, utilitarian AI may conclude "acceptable collateral damage."

Eastern Jiadao culture tends toward: **encoding ethics as hard constraints (not optimization objectives), achieving "minimum harm" through "insurmountable baselines."** This manifests as:

```solidity
// Western utilitarianism tendency (as optimization objective)
function evaluateAction(Action calldata action) 
    returns (uint256 utilityScore) {
    utilityScore = militaryBenefit * 0.6 
                 - civilianHarm * 0.3 
                 + strategicValue * 0.1;
    // Risk: when militaryBenefit is high enough, civilianHarm is "tolerated"
}

// Eastern Jiadao culture tendency (as hard constraint)
function evaluateAction(Action calldata action) 
    returns (bool isPermissible) {
    require(civilianHarm == 0, "Do not kill innocent - hard constraint");
    require(action.withinAuthorization, "No overreach - hard constraint");
    require(action.roeCompliant, "Follow ROE - hard constraint");
    isPermissible = true;
    // Ethics is not a weight in the optimization function, 
    // but a wall in the behavior space
}
```

**Core insight from this comparison: Ethics should not be a weight in the AI's optimization function, but a wall in the AI's behavior space.** Jiadao's "Chi" — knowing when to stop — is precisely the cultural encoding of this wall.

---

## Conclusion

Military AI identity governance is not a technical problem but a civilizational one. When AI systems can make lethal decisions in milliseconds, human ethical baselines must be encoded, verified, and enforced with the same speed and certainty.

AGL's Registration → Attestation → Certificate → Verification chain provides the technical infrastructure for this civilizational need. The extension from civilian AI compliance to military AI identity governance is not feature addition but the realization of a **"civilization translator"** — translating Geneva Convention articles, Jiadao Culture's Eight Virtues, and ITAR regulations into constraint code that is AI-executable, human-verifiable, and on-chain immutable.

The Anthropic incident teaches us: **AI safety dependent on corporate morality is fragile** [(CSA)](https://labs.cloudsecurityalliance.org/wp-content/uploads/2026/04/CSA_research_note_sovereign_ai_vendor_dependency_dod_anthropic_20260413-csa-styled.pdf)**. The UN's 166-vote resolution teaches us: **the international community yearns for an enforceable governance framework** [(UN A/RES/80/57)](https://digitallibrary.un.org/nanna/record/4095989/files/A_RES_80_57-EN.pdf)**. The Five Eyes' "months, not years" warning teaches us: **time is not on our side**.

On-chain identity governance is not a silver bullet for military AI ethics, but it is **the only human governance mechanism that can operate at AI decision speed**. That alone is reason enough to build it.

---

*This whitepaper is based on AGL V0 contract architecture (AgentRegistry.sol / AgentPassport.sol / AccessGateway.sol / CompliancePassport.sol). All contract interface designs are extensions of actual code structures. Market data sourced from public research institution reports, as of July 2026.*
