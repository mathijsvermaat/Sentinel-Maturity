# Amazon Web Services (AWS)

**Tier:** 2 (Extended Visibility) · **Connector type:** Multi-cloud · **Free ingestion:** No · **Conditional:** Only applicable with AWS workloads

---

## Contents

- [Amazon Web Services (AWS)](#amazon-web-services-aws)
  - [Contents](#contents)
  - [Overview](#overview)
    - [Licensing Benefits](#licensing-benefits)
  - [Tables and Rationale](#tables-and-rationale)
  - [Example Detections](#example-detections)
    - [IAM and Access](#iam-and-access)
    - [Resource Security](#resource-security)
    - [Threat Detection](#threat-detection)
  - [MITRE Detection Strategies](#mitre-detection-strategies)
  - [MCSB Control Mapping](#mcsb-control-mapping)
  - [Important Considerations](#important-considerations)
    - [Connector Architecture](#connector-architecture)
    - [Management Events vs. Data Events](#management-events-vs-data-events)
    - [Federated Access (Entra ID → AWS)](#federated-access-entra-id--aws)
  - [Notes](#notes)
  - [Tools](#tools)
  - [References](#references)

---

## Overview

For customers with workloads in Amazon Web Services, CloudTrail logs are the **equivalent of Azure Activity Logs** — they capture the control plane audit trail for all AWS API calls. Without these logs in Sentinel, your SOC has a blind spot covering everything that happens in the other cloud.

The ACSC logging guidance treats cloud logging as a **generic requirement** — the same logging priorities apply to every cloud provider. If Azure Activity Logs are Tier 1 for Azure, AWS CloudTrail should be Tier 2 for organisations running multi-cloud.

### Licensing Benefits

| License | What it unlocks |
|:--------|:----------------|
| **AWS CloudTrail (free tier)** | 90 days of management event history — free, but not forwarded to Sentinel |
| **AWS CloudTrail (trail)** | Management events forwarded to S3 → Sentinel. Data events (S3 object access, Lambda invocations) available at additional AWS cost |
| **Amazon GuardDuty** | AWS-native threat detection alerts — can be forwarded to Sentinel as correlated alerts |

> [!NOTE]
> AWS CloudTrail logs are **not** a free data source in Sentinel. Ingestion cost is borne by the Sentinel workspace. Additionally, AWS charges for S3 storage of CloudTrail logs and SQS message delivery.

---

## Tables and Rationale

| Table | Description | Retention Recommendation | Rationale | Forensic Value | Example Detection |
|:------|:------------|:------------------------|:----------|:---------------|:------------------|
| **AWSCloudTrail** | All AWS API calls — IAM actions, resource CRUD, console logins, security group changes, S3 operations | Analytics: 90d / Lake: 365d | **Core AWS control plane audit trail.** Equivalent of AzureActivity for AWS. Detects unauthorized resource deployment, IAM privilege escalation, security group modifications, and S3 exfiltration. | Proves exactly which AWS API calls were made, by which principal, from which IP, and when. The authoritative evidence for AWS infrastructure investigations. | IAM user created with admin policy, security group opened to 0.0.0.0/0, S3 bucket made public |
| **AWSGuardDuty** | Amazon GuardDuty findings — anomalous API activity, cryptocurrency mining, credential compromise | Analytics: 90d / Lake: 365d | AWS-native threat detection — complements behavioural detections in Sentinel. Equivalent of Defender for Cloud SecurityAlert for AWS. | Correlated AWS threat findings — proves that AWS-native detection identified suspicious activity, providing additional confidence alongside Sentinel analytics | GuardDuty finding for cryptocurrency mining instance |
| **AWSVPCFlow** | VPC Flow Logs — network traffic metadata for AWS VPCs (source/dest IP, port, protocol, action) | Analytics: 90d / Lake: 365d | AWS network visibility — equivalent of NSG Flow Logs. Detects lateral movement within AWS VPCs. | Network flow evidence for AWS workloads — proves which EC2 instances communicated with each other and with external IPs | Lateral movement between EC2 instances, outbound C2 from compromised instance |

---

## Example Detections

### IAM and Access

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| IAM user created with admin policy | AWSCloudTrail | [T1136](https://attack.mitre.org/techniques/T1136/) | [DET0583](https://attack.mitre.org/detectionstrategies/DET0583/) — Create Account | CreateUser + AttachUserPolicy with AdministratorAccess — privilege escalation |
| Console login without MFA | AWSCloudTrail | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Valid Account Abuse | ConsoleLogin event without MFA — potential compromised credentials |
| Access key used from unusual IP | AWSCloudTrail | [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) — Valid Account Abuse | API calls from an IP not seen in baseline access patterns for this key |
| AssumeRole from unexpected source | AWSCloudTrail | [T1550](https://attack.mitre.org/techniques/T1550/) | [DET0338](https://attack.mitre.org/detectionstrategies/DET0338/) — Alternate Authentication Material | Cross-account role assumption from an account not in the trusted relationship |
| Root account usage | AWSCloudTrail | [T1078.004](https://attack.mitre.org/techniques/T1078/004/) | [DET0546](https://attack.mitre.org/detectionstrategies/DET0546/) — Compromised Cloud Accounts | Any API call from the AWS root account — should be extremely rare |

### Resource Security

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| S3 bucket made public | AWSCloudTrail | [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) — Cloud Storage Exfiltration | PutBucketPolicy or PutBucketAcl granting public access |
| Security group opened to 0.0.0.0/0 | AWSCloudTrail | [T1562.007](https://attack.mitre.org/techniques/T1562/007/) *(revoked &rarr; [T1686.001](https://attack.mitre.org/techniques/T1686/001/))* | [DET0424](https://attack.mitre.org/detectionstrategies/DET0424/) — Disable or Modify Cloud Firewall | AuthorizeSecurityGroupIngress with 0.0.0.0/0 — opens compute to internet |
| CloudTrail logging disabled | AWSCloudTrail | [T1562.008](https://attack.mitre.org/techniques/T1562/008/) *(revoked &rarr; [T1685.002](https://attack.mitre.org/techniques/T1685/002/))* | [DET0289](https://attack.mitre.org/detectionstrategies/DET0289/) — Disable or Modify Cloud Log | StopLogging or DeleteTrail — attacker disabling audit trail |
| KMS key policy modified | AWSCloudTrail | [T1098](https://attack.mitre.org/techniques/T1098/) | [DET0096](https://attack.mitre.org/detectionstrategies/DET0096/) — Account Manipulation | Changes to KMS key policies — potential data access escalation |

### Threat Detection

| Detection | Table(s) | MITRE ATT&CK | Detection Strategy | Description |
|:----------|:---------|:-------------|:-------------------|:------------|
| GuardDuty cryptocurrency finding | AWSGuardDuty | [T1496](https://attack.mitre.org/techniques/T1496/) | [DET0267](https://attack.mitre.org/detectionstrategies/DET0267/) — Resource Hijacking | EC2 instance flagged for cryptocurrency mining activity |
| GuardDuty credential exfiltration | AWSGuardDuty | [T1552](https://attack.mitre.org/techniques/T1552/) | [DET0412](https://attack.mitre.org/detectionstrategies/DET0412/) — Unsecured Credentials | Credential extracted from EC2 instance metadata service |
| Unusual VPC traffic pattern | AWSVPCFlow | [T1046](https://attack.mitre.org/techniques/T1046/) | [DET0376](https://attack.mitre.org/detectionstrategies/DET0376/) — Network Service Discovery | Internal scanning or lateral movement within AWS VPCs |

---

## MITRE Detection Strategies

Curated list of MITRE [Detection Strategies](https://attack.mitre.org/detectionstrategies/) relevant to the techniques referenced on this page. The **Connector Evidence (IaaS)** column translates MITRE's published cloud-analytic intent into the analogous AWS evidence available in this connector.

| Technique | Detection Strategy | Connector Evidence (IaaS) |
|:----------|:-------------------|:-----------|
| [T1136](https://attack.mitre.org/techniques/T1136/) | [DET0583](https://attack.mitre.org/detectionstrategies/DET0583/) &mdash; Detection Strategy for T1136 - Create Account across platforms | `AWSCloudTrail`: `CreateUser`, `AttachUserPolicy`, and related IAM account-creation activity |
| [T1078](https://attack.mitre.org/techniques/T1078/) | [DET0560](https://attack.mitre.org/detectionstrategies/DET0560/) &mdash; Detection of Valid Account Abuse Across Platforms | *MITRE has not published an IaaS analytic for this strategy* |
| [T1550](https://attack.mitre.org/techniques/T1550/) | [DET0338](https://attack.mitre.org/detectionstrategies/DET0338/) &mdash; Behavioral Detection Strategy for Use Alternate Authentication Material (T1550) | `AWSCloudTrail`: `AssumeRole`, `GetCallerIdentity`, and other alternate-authentication API activity |
| [T1078.004](https://attack.mitre.org/techniques/T1078/004/) | [DET0546](https://attack.mitre.org/detectionstrategies/DET0546/) &mdash; Detection of Abused or Compromised Cloud Accounts for Access and Persistence | `AWSCloudTrail`: `ConsoleLogin`, `AssumeRole`, `ListAccessKeys`, `CreateUser`, and other compromised-cloud-account behaviours |
| [T1530](https://attack.mitre.org/techniques/T1530/) | [DET0484](https://attack.mitre.org/detectionstrategies/DET0484/) &mdash; Multi-Platform Cloud Storage Exfiltration Behavior Chain | `AWSCloudTrail`: `GetObject`, `CopyObject`, bucket-access changes; `AWSVPCFlow`: unusual outbound transfer from S3 endpoints |
| [T1562.007](https://attack.mitre.org/techniques/T1562/007/) *(revoked &rarr; [T1686.001](https://attack.mitre.org/techniques/T1686/001/))* | [DET0424](https://attack.mitre.org/detectionstrategies/DET0424/) &mdash; Detection Strategy for Disable or Modify Cloud Firewall | `AWSCloudTrail`: security-group ingress / egress rule changes and related network-control modification activity |
| [T1562.008](https://attack.mitre.org/techniques/T1562/008/) *(revoked &rarr; [T1685.002](https://attack.mitre.org/techniques/T1685/002/))* | [DET0289](https://attack.mitre.org/detectionstrategies/DET0289/) &mdash; Detection Strategy for Disable or Modify Cloud Log | `AWSCloudTrail`: `StopLogging`, trail updates / deletion, or other logging-impairment operations |
| [T1098](https://attack.mitre.org/techniques/T1098/) | [DET0096](https://attack.mitre.org/detectionstrategies/DET0096/) &mdash; Account Manipulation Behavior Chain Detection | *MITRE has not published an IaaS analytic for this strategy* |
| [T1496](https://attack.mitre.org/techniques/T1496/) | [DET0267](https://attack.mitre.org/detectionstrategies/DET0267/) &mdash; Resource Hijacking Detection Strategy | `AWSCloudTrail`: `RunInstances` and related compute deployment activity; `AWSGuardDuty`: cryptocurrency-mining findings; `AWSVPCFlow`: mining-pool egress |
| [T1552](https://attack.mitre.org/techniques/T1552/) | [DET0412](https://attack.mitre.org/detectionstrategies/DET0412/) &mdash; Detect Access or Search for Unsecured Credentials Across Platforms | *MITRE has not published an IaaS analytic for this strategy* |
| [T1046](https://attack.mitre.org/techniques/T1046/) | [DET0376](https://attack.mitre.org/detectionstrategies/DET0376/) &mdash; Behavioral Detection Strategy for Network Service Discovery Across Platforms | *MITRE has not published an IaaS analytic for this strategy* |
| [T1021](https://attack.mitre.org/techniques/T1021/) | [DET0269](https://attack.mitre.org/detectionstrategies/DET0269/) &mdash; Behavioral Detection Strategy for Remote Service Logins and Post-Access Activity | `AWSCloudTrail`: `ConsoleLogin`, `StartSession`; `AWSVPCFlow`: connections to administrative ports such as 22 and 3389 |
| [T1071](https://attack.mitre.org/techniques/T1071/) | [DET0444](https://attack.mitre.org/detectionstrategies/DET0444/) &mdash; Detection of Command and Control Over Application Layer Protocols | *MITRE has not published an IaaS analytic for this strategy* |

> [!NOTE]
> **Connector-native evidence mapping.** MITRE's published Detection Strategies for the IaaS platform family sometimes mix source names across cloud vendors. To keep this page AWS-native and readable, the third column translates MITRE's analytic intent into the analogous evidence available in `AWSCloudTrail`, `AWSVPCFlow`, and `AWSGuardDuty`.

> [!NOTE]
> **MITRE legacy technique IDs.** Some technique IDs cited on this page are *legacy* IDs that MITRE has revoked and remapped: T1562.007 &rarr; T1686.001; T1562.008 &rarr; T1685.002. Published Detection Strategies are attached to the current technique IDs only; the table above follows the `revoked-by` chain so each strategy still applies to the legacy ID cited above.

> [!TIP]
> Detection Strategies are MITRE-published *pseudo-code analytics*, not vendor rules — they tell you **what** to correlate across data sources. Use them to validate that your Sentinel analytic rules and KQL hunting queries cover the published correlation logic.

---

## MCSB Control Mapping

| MCSB Control | Relevance |
|:-------------|:----------|
| **LT-3** Enable logging for security investigation | CloudTrail provides the control plane audit trail for AWS |
| **LT-4** Enable network logging for security investigation | VPC Flow Logs provide network traffic metadata for AWS |
| **LT-1** Enable threat detection | GuardDuty findings provide AWS-native threat detection |
| **IM-1** Centralise identity management | IAM activity logging supports cross-cloud identity visibility |
| **PA-7** Follow just enough administration | IAM policy changes tracked for least-privilege enforcement |

> [!NOTE]
> **Other framework alignment:** This data supports NIST SP 800-53 AU-2 (audit events) and AC-2 (account management), CIS Controls v8 8.2 (collect audit logs), and ASD ACSC cloud logging priorities #3–#7 (cloud user accounts, administrative changes, security principals, authentication, and cloud service logs).

---

## Important Considerations

### Connector Architecture

The AWS Sentinel connector uses an S3 → SQS → Sentinel pipeline:

```
[CloudTrail] → [S3 Bucket] → [SQS Queue] → [Sentinel Connector] → [AWSCloudTrail table]
```

- An IAM role with cross-account trust allows Sentinel to poll the SQS queue
- CloudTrail must be configured to deliver logs to the S3 bucket
- SQS notifications must be configured on the S3 bucket
- For multi-account setups, use **AWS Organizations CloudTrail** (organisation trail) to aggregate all accounts into a single S3 bucket

### Management Events vs. Data Events

| Event Type | What It Captures | Cost | Recommendation |
|:-----------|:-----------------|:-----|:---------------|
| **Management events** | IAM changes, resource CRUD, console logins | Included in CloudTrail free tier (history only) | **Always enable** — low volume, high value |
| **Data events** | S3 object access, Lambda invocations, DynamoDB reads | Additional AWS cost + high Sentinel ingestion | Enable selectively for critical S3 buckets and Lambda functions |

Start with management events only; add data events for crown-jewel resources.

### Federated Access (Entra ID → AWS)

If users authenticate to AWS via Entra ID federation (SSO), the authentication appears in Entra ID SigninLogs (Tier 1) and the subsequent AWS actions appear in CloudTrail. Cross-reference both for complete visibility into federated user activity.

---

## Notes

- If your organisation has no AWS workloads, skip this connector entirely
- CloudTrail management events are relatively low volume — typically a few GB/day even for large AWS environments
- VPC Flow Logs can be high-volume — consider enabling only for security-critical VPCs initially and using the **Data Lake** tier
- For **Defender for Cloud multi-cloud CSPM**, AWS security alerts already flow through `SecurityAlert` — see [Defender for Cloud](microsoft-defender-for-cloud.md)
- The [Microsoft Sentinel AWS connector](https://learn.microsoft.com/en-us/azure/sentinel/connect-aws) documentation provides step-by-step setup instructions

---

## Tools

| Tool | Type | Purpose | Source | Guide |
|:-----|:-----|:--------|:-------|:------|
| **Workspace Usage Report** | Workbook | Monitor AWS table ingestion volumes | Sentinel Content Hub | [Walkthrough](../procedures/workspace-usage-report.md) |
| **Amazon Web Services** | Solution | Provides the AWS CloudTrail and S3 connectors plus detection content for multi-cloud visibility | Sentinel Content Hub | — |

---

## References

### Official Documentation

| Title | Description | Link |
|:------|:------------|:-----|
| Connect AWS CloudTrail to Microsoft Sentinel | Connector setup guide — SQS-based CloudTrail log ingestion | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/amazon-web-services) |
| Connect AWS S3 to Microsoft Sentinel | S3-based connector for GuardDuty, VPC Flow Logs, and CloudTrail | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/amazon-web-services-s3) |

### Community & Third-Party Resources

| Title | Author | Description | Link |
|:------|:-------|:------------|:-----|
| Sentinel Ninja — AWS connector | Ofer Shezaf (Microsoft) | Auto-generated reference: tables ingested, related solutions, and content items | [github.com](https://github.com/oshezaf/sentinelninja/blob/main/Solutions%20Docs/connectors/aws.md) |
| Best practices for event logging and threat detection | ASD ACSC | International joint guidance — cloud logging priorities apply equally to all cloud providers including AWS | [cyber.gov.au](https://www.cyber.gov.au/business-government/detecting-responding-to-threats/event-logging/best-practices-for-event-logging-and-threat-detection) |
| Manage Cloud Logs for Effective Threat Hunting | NSA | NSA guidance on cloud log management including AWS CloudTrail best practices | [defense.gov (PDF)](https://media.defense.gov/2024/Mar/07/2003407864/-1/-1/0/CSI_CloudTop10-Logs-for-Effective-Threat-Hunting.PDF) |

[← Back to Connectors](README.md) · [← Back to Sentinel Maturity Model](../README.md)
