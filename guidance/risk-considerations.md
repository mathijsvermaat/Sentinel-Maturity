# Risk Considerations

## Overview

There is no universally correct logging configuration. What is "sufficient" logging for one organisation may be inadequate or excessive for another. This document assumes a **risk-based approach**, where:

- Logging choices are **intentional**
- Gaps are **documented**
- Residual risk is **understood and accepted** by the business

## Risk Factors That Influence Logging Decisions

The following factors should drive what you log, how long you retain it, and where you store it:

| Factor | Description |
|:-------|:------------|
| **Business criticality of systems** | Crown-jewel assets require deeper logging and longer retention than commodity workloads |
| **Likelihood and impact of identity compromise** | Environments with high identity exposure (e.g. hybrid identity, external collaboration) need comprehensive authentication logging |
| **Exposure to targeted vs commodity threats** | Organisations facing APT-level threats need broader telemetry and longer retention to support extended investigations |
| **Ability to respond to and investigate incidents** | Logging has limited value if the SOC lacks capacity to act on it — balance collection with operational capability |
| **Dependence on third-party or legacy systems** | Systems that cannot forward native logs may require compensating controls or additional monitoring at network boundaries |

## Assessing Each Data Source

For each data source, your organisation should assess:

### Purpose and Use Case

> [!IMPORTANT]
> The authoring agencies discourage logging for the sake of logging.

Every data source should have a clear justification — whether it supports detection, investigation, compliance, or operational monitoring. If the purpose is unclear, the data source should be deprioritised or excluded.

### Prioritisation

Higher-priority data sources should be:

- Ingested into new SIEM deployments **first**
- Their health should be **regularly checked**

This document provides a suggested order of prioritisation by broad category of data source through the [Tier Model](../README.md#tier-model).

### Volume Considerations

The volume of logs a data source generates matters. For example:

- **Firewall or DNS logs** may generate enormous volumes that overshadow the importance of the information received
- High-volume sources should be evaluated against their **cost-to-value ratio** — consider whether routing them to cheaper storage tiers (Sentinel Data Lake) rather than Analytics logs is more appropriate

### Analytical Value

Even high-volume data sources can provide significant analytical value when:

- Queried for **anomalies in timing** (e.g. unusual login hours, off-pattern process execution)
- **Correlated against other data sources** (e.g. correlating high-volume firewall logs against threat intelligence-identified malicious IP addresses)
- Used for **baselining** normal behaviour to detect deviations

---

## Key Takeaway

> [!NOTE]
> Logging decisions should be based on the organisation's specific environment and risk profile. While the recommendations in the [Tier 1 Connectors](../README.md#tier-1-connectors-bare-minimum) provide a starting point, it is critical that organisations model their threats and risks and select data sources most relevant to their risk profile.

---

[← Back to Guidance](README.md) · [← Back to Sentinel Maturity Model](../README.md)
