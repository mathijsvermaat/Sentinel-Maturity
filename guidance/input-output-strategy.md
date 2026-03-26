# Input/Output Strategy

## Contents

- [Overview](#overview)
- [The Strategy](#the-strategy)
- [Applying This to Microsoft Sentinel](#applying-this-to-microsoft-sentinel)
- [Key Takeaway](#key-takeaway)
- [References](#references)

---

## Overview

Gartner's SIEM input/output strategy focuses on moving beyond basic log collection to a more strategic, cost-effective approach. The core principle is **tiering telemetry**: sending only high-value data to the SIEM for real-time analysis and routing everything else to cheaper storage.

## The Strategy

Traditional SIEM deployments often follow a "collect everything" approach, which leads to:

- **Escalating costs** as data volumes grow
- **Alert fatigue** from low-value telemetry
- **Slow query performance** when hunting through massive datasets

The input/output model reframes SIEM usage around **what you need out** rather than **what you put in**.

### Inputs — What Goes Into the SIEM

Not all data needs to flow into the SIEM's real-time analytics tier. Data should be tiered based on its operational value:

| Tier | Data Characteristics | Sentinel Mapping |
|:-----|:---------------------|:-----------------|
| **High-value** | Security events, authentication logs, alerts, identity changes | Analytics logs (90-day interactive retention) |
| **Medium-value** | Audit trails, compliance logs, infrastructure events | Analytics logs with Lake extension (365-day long-term retention) |
| **Low-value / high-volume** | NetFlow, raw DNS, verbose firewall logs | Sentinel Data Lake (cost-optimised storage) or external storage |

### Outputs — What the SIEM Delivers

Key outputs that a well-designed SIEM deployment should produce:

| Output | Description |
|:-------|:------------|
| **Enriched alerts** | Correlated, context-rich alerts that reduce analyst triage time |
| **Incident response data** | Pre-correlated evidence packages that accelerate investigation |
| **Forensic evidence** | Preserved, tamper-resistant log data for post-incident analysis |
| **Compliance reporting** | Automated reports demonstrating adherence to regulatory frameworks |
| **Threat hunting insights** | Historical data enabling proactive hypothesis-driven investigations |

## Applying This to Microsoft Sentinel

Microsoft Sentinel's architecture maps well to this tiered approach:

| Sentinel Feature | I/O Role | Cost Profile |
|:-----------------|:---------|:-------------|
| **Analytics logs** | High-value real-time analysis | Standard per-GB ingestion pricing |
| **Sentinel Data Lake** | Long-term retention and historical search | Reduced-cost storage with on-demand query |
| **Data Collection Rules (DCRs)** | Filter and transform data before ingestion | Reduce costs by dropping unnecessary fields or events |
| **Summary Rules** | Aggregate high-volume data into compact summaries | Retain analytical value at a fraction of the storage cost |

> [!TIP]
> Use **Data Collection Rules** to filter high-volume sources at ingestion time. For example, you can filter Windows Security Events to only collect specific Event IDs rather than the full event stream, significantly reducing cost while maintaining detection capability.

## Key Takeaway

> [!NOTE]
> As SIEMs evolve into Security Analytics Platforms integrated with XDR, the focus shifts from "how much data can we collect" to "how effectively can we detect, investigate, and respond." Capabilities like data pipelines, AI-driven analytics, and automation enable advanced outcomes — enriched alerts, incident response, forensics, and compliance — while controlling costs.

---

## References

- [Plan costs and understand pricing and billing — Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/billing?tabs=simplified%2Ccommitment-tiers)
- [Data Collection Rules in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview)

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
