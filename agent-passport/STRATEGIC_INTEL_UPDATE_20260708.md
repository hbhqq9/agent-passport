# Agent Passport 战略情报速递（2026-07-08 09:45 更新）

## 🚨 今日新发现（3项重大情报）

### 1. Linux Foundation ANS（Agent Name Service）—— 7月8日发布
- **DNS-inspired agent identity standard**，Linux Foundation主导
- 给Agent一个类似域名系统的可验证身份
- 直接对标Agent Passport的L1身份层
- 来源：[Vuink Report](https://vuink.com/post/bcrafbheprjngpu-d-dorruvvi-d-dpbz/p/agent-name-service-the-universal-ai-agents-identity-system)

### 2. CrowdStrike "Continuous Identity for AI Agents" —— 6月15日发布
- 基于SPIFFE标准 + SSF（Shared Signals Framework）
- 每次Agent动作实时授权，无永久权限
- 人机双身份令牌（Human_ID + Agent_ID）
- 来源：[Massive News](https://massive.news/crowdstrike-announces-continuous-identity-for-ai-agents/)

### 3. 派拉软件 AIM —— 7月5日发布（中国）
- 面向中国企业的AI Agent身份安全认证管理
- SPIFFE/SPIRE体系 + SCIM + NHI治理 + CIBA异步审批
- 人机融合身份路由：Human→Agent→MCP→业务应用
- OBO动态Token交换（同时内嵌Human_ID与Agent_ID）
- 来源：[CSDN](https://blog.csdn.net/LUCKYLILIWA/article/details/159757937)

## 📊 竞争格局关键更新

| 竞争者 | 最新动态 | 对Agent Passport的影响 |
|--------|---------|---------------------|
| **NewCore** | $66M融资，$300M估值，"Digital Passport for AI Agents" | 🔴 直接竞品概念，但聚焦企业内网，不做Web2桥接 |
| **BNB Agent Studio** | 7月1日上线，ERC-8004+AWS AgentCore，15分钟部署Agent | 🟡 互补——BNB做Agent创建/托管，我们做身份/访问 |
| **ScrambleID** | JWT client assertions (RFC 7523) + DPoP agent auth框架 | 🟢 技术互补——他们的auth模式可集成到AccessGateway |
| **EU Digital Omnibus** | Art.50透明度义务8月2日如期生效，水印延期至12月2日 | 🔴 合规压力窗口确认——AGL的Art.50方案有市场 |

## 💡 突破策略启示

1. **"Proof-of-Agent Passport"概念**：Agent Passport不是要替代NewCore/CrowdStrike的企业IAM，而是做"Agent的国际护照"——企业IAM是员工工卡，我们是跨国通行证
2. **Linux Foundation ANS整合**：ANS走DNS路线，我们走链上路线。两者可以桥接——Agent在ANS注册域名式身份，在Agent Passport获取链上护照
3. **Art.50合规倒逼**：8月2日起所有EU AI系统必须明示AI身份，这意味着所有部署在EU的Agent都需要某种"身份证明"——Agent Passport可以成为这个证明的提供者

---
*更新时间：2026-07-08 09:45 CST*
