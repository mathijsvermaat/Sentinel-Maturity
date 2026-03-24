# Budget and Cost Planning

## Contents

- [Overview](#overview)
- [Cost Awareness Over Time](#cost-awareness-over-time)
- [Budget Models](#budget-models)
- [Microsoft Sentinel Cost Optimisation](#microsoft-sentinel-cost-optimisation)
- [Key Takeaway](#key-takeaway)

---

## Overview

As a SOC develops its data collection plan, it must consider how it will pay for the transport and storage of the data. Budget planning is not a one-time exercise — data volumes change over time, and the SOC needs to be involved in early planning when infrastructure changes occur.

## Cost Awareness Over Time

Data volumes are not static. As organisations evolve, so does the volume of security telemetry:

| Change | Impact on Log Volume |
|:-------|:---------------------|
| Enterprise applications moving to the cloud | Increased traffic through firewalls and perimeter controls → more NetFlow/firewall events |
| Adoption of new SaaS platforms | New data sources (e.g. OfficeActivity, CloudAppEvents) that generate audit logs |
| Expansion of server fleet | More endpoints generating Windows Security Events and Syslog data |
| Enabling advanced audit policies | More granular events per system (e.g. command-line logging, PowerShell script block logging) |
| Introduction of IoT/OT devices | New, potentially high-volume telemetry sources |

> [!IMPORTANT]
> When infrastructure changes are being considered, the SOC needs to be part of early planning to anticipate volume and cost impacts.

## Budget Models

### Dedicated SOC Budget (Recommended)

It is simplest for SOCs to maintain their **own budget** supporting comprehensive monitoring coverage and staffing. This approach:

- Ensures monitoring decisions are driven by **security requirements**, not cost-shifting politics
- Provides **predictable year-over-year** budget planning
- Avoids the perception of the SOC as a sunk cost — instead positioning it as a **source of value**

### Fee-for-Service / "Tax" Model (Not Recommended)

Moving to a fee-for-service model or "tax" on lines of business can become challenging:

- Many programs and projects will **not budget** for new monitoring capabilities
- Year-to-year planning becomes **overly complex** or subject to third parties the SOC cannot influence
- Lines of business may push back, undermining monitoring coverage

### Hybrid: Project-Funded Initial Deployment

An alternative approach:

1. **Large projects fund** the initial deployment of monitoring tools
2. **Recurring costs** (recap and staffing) are built into the long-term SOC budget for subsequent years

This balances the initial investment across the organisation while keeping ongoing costs under SOC control.

## Microsoft Sentinel Cost Optimisation

Microsoft Sentinel provides several mechanisms to control and optimise costs:

### Pricing Tiers

| Pricing Model | Best For | Description |
|:--------------|:---------|:------------|
| **Pay-As-You-Go** | Low/unpredictable volumes | Per-GB pricing with no commitment |
| **Commitment Tiers** | Predictable volumes ≥ 100 GB/day | Discounted per-GB rate in exchange for a daily commitment |

### Cost Reduction Strategies

| Strategy | Description | Sentinel Feature |
|:---------|:------------|:-----------------|
| **Free data sources** | Several connectors ingest at no cost (Azure Activity, Office 365, Entra ID audit/sign-in, etc.) | [Free data sources](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources) |
| **E5 security data grant** | M365 E5 / E5 Security customers get free ingestion of XDR tables into the Analytics tier | [M365 E5 Sentinel benefit](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer) |
| **Defender for Servers P2 benefit** | 500 MB/day/server free ingestion for security data types | [Data ingestion benefit](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit) |
| **Data Collection Rules (DCRs)** | Filter and transform data at ingestion time to reduce unnecessary volume | [DCR overview](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview) |
| **Sentinel Data Lake** | Route long-term retention to cheaper storage instead of keeping all data in Analytics tier | Analytics: 90d + Lake: 365d |
| **Summary Rules** | Aggregate high-volume data into compact summaries, retaining analytical value at lower cost | [Summary rules](https://learn.microsoft.com/en-us/azure/sentinel/summary-rules) |
| **Basic Logs** | Reduced-cost ingestion for high-volume, low-query tables | [Basic logs plan](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/basic-logs-configure) |

### Monitoring and Reporting

Use the **Workspace Usage Report** workbook (available in [Sentinel Content Hub](https://learn.microsoft.com/en-us/azure/sentinel/sentinel-content-hub)) to:

- Monitor ingestion volumes per table
- Identify cost optimisation opportunities
- Validate data connector health
- Track volume trends over time to inform budget planning

> [!TIP]
> Regularly review the Workspace Usage Report to catch unexpected volume spikes early. A single misconfigured diagnostic setting or verbose audit policy can significantly increase ingestion costs.

## Key Takeaway

> [!NOTE]
> The SOC budget should be treated as an investment in organisational resilience, not a tax on business units. Comprehensive monitoring coverage requires predictable, security-driven funding — not cost-shifting that undermines coverage.

---

### References

- [Plan costs and understand pricing and billing — Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers)
- [Microsoft Sentinel benefit for Microsoft 365 E5 customers](https://azure.microsoft.com/en-us/pricing/offers/sentinel-microsoft-365-offer)
- [Defender for Cloud data ingestion benefit](https://learn.microsoft.com/en-us/azure/defender-for-cloud/data-ingestion-benefit)
- [Free data sources in Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers#free-data-sources)

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
