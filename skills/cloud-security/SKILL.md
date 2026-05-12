---
name: cloud-security
description: >-
  AWS cloud security posture: GuardDuty, Security Hub, AWS Config, CloudTrail,
  IAM Access Analyzer, SCPs, WAF, landing zone basics. Detecting and fixing
  common cloud misconfigurations. Triggers: AWS security, GuardDuty, Security
  Hub, CloudTrail, AWS Config, SCP, IAM Access Analyzer, cloud posture,
  misconfiguration, public S3, exposed port, cloud security.
---

# cloud-security

Cloud misconfigurations are the most common cause of cloud-based security incidents. The good news: AWS ships tools that detect most of them automatically. The work is enabling them, understanding what they report, and responding correctly.

---

## The core toolset

| Service | What it does |
|---------|-------------|
| **CloudTrail** | Logs every API call in your account — who did what, when, from where |
| **GuardDuty** | Threat detection — analyzes CloudTrail, VPC flow logs, DNS logs for suspicious patterns |
| **Security Hub** | Aggregates findings from GuardDuty, Inspector, Config, Macie — one dashboard |
| **AWS Config** | Tracks resource configuration over time; rules detect drift from your standards |
| **IAM Access Analyzer** | Finds IAM policies that grant access to external accounts or public access |
| **Macie** | Scans S3 for PII and sensitive data |
| **Inspector** | Scans EC2 and containers for CVEs and network reachability |

Enable all of these. They're cheap relative to the cost of not knowing about a misconfiguration.

---

## CloudTrail

CloudTrail is foundational. Without it, you have no record of what happened.

```bash
# Check if CloudTrail is enabled in your account
aws cloudtrail describe-trails

# Verify logging is active
aws cloudtrail get-trail-status --name your-trail-name
```

Best practices:
- Enable CloudTrail in all regions, not just the ones you use actively
- Log to an S3 bucket in a separate logging account (so a compromised account can't delete the logs)
- Enable CloudTrail log file validation (detects tampering)
- Enable S3 data events if you need to track object-level access

```bash
# Create a multi-region trail with log validation
aws cloudtrail create-trail \
  --name org-wide-trail \
  --s3-bucket-name your-log-bucket \
  --include-global-service-events \
  --is-multi-region-trail \
  --enable-log-file-validation
```

---

## GuardDuty

GuardDuty analyzes CloudTrail, VPC flow logs, and DNS logs automatically. Enable it and let it run.

```bash
# Enable GuardDuty
aws guardduty create-detector --enable

# List findings (severity 7+ is High)
aws guardduty list-findings \
  --detector-id $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text) \
  --finding-criteria '{"Criterion":{"severity":{"Gte":7}}}'
```

### High-signal finding types to act on immediately

| Finding | What it means |
|---------|--------------|
| `UnauthorizedAccess:IAMUser/MaliciousIPCaller` | API calls from a known malicious IP |
| `Recon:IAMUser/MaliciousIPCaller` | Reconnaissance from a known bad actor |
| `CredentialAccess:IAMUser/AnomalousBehavior` | Unusual credential usage patterns |
| `Persistence:IAMUser/UserPermissions` | IAM changes that could persist access |
| `CryptoCurrency:EC2/BitcoinTool.B` | Instance running crypto mining software |
| `Trojan:EC2/DNSDataExfiltration` | DNS-based data exfiltration pattern |

For any High severity finding, treat it as a real incident until proven otherwise.

---

## AWS Config

Config rules detect when resources drift from your standards. Key rules to enable:

```bash
# Enable Config (if not already via AWS Organizations)
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT:role/ConfigRole

# Enable the AWS managed rules you care about most
aws configservice put-config-rule --config-rule '{
  "ConfigRuleName": "s3-bucket-public-read-prohibited",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}'
```

### Most important managed rules

| Rule | Catches |
|------|---------|
| `s3-bucket-public-read-prohibited` | Public S3 buckets |
| `restricted-ssh` | Security groups allowing SSH from 0.0.0.0/0 |
| `restricted-common-ports` | Security groups with open RDP, MySQL, etc. |
| `iam-root-access-key-check` | Root account with active access keys |
| `mfa-enabled-for-iam-console-access` | IAM users without MFA |
| `access-keys-rotated` | Access keys older than 90 days |
| `cloudtrail-enabled` | CloudTrail not enabled |
| `encrypted-volumes` | Unencrypted EBS volumes |

Use AWS Security Hub's `AWS Foundational Security Best Practices` standard — it bundles ~200 controls and runs them automatically.

---

## IAM Access Analyzer

Finds policies that grant access outside your account — public access, cross-account access, or access from external principals.

```bash
# Create an analyzer for your account
aws accessanalyzer create-analyzer \
  --analyzer-name account-analyzer \
  --type ACCOUNT

# List active findings
aws accessanalyzer list-findings \
  --analyzer-arn arn:aws:access-analyzer:us-east-1:ACCOUNT:analyzer/account-analyzer \
  --filter '{"status":{"eq":["ACTIVE"]}}'
```

Any finding with `isPublic: true` needs immediate investigation. Public S3 buckets, public ECR repositories, and public Lambda functions should be intentional and documented.

---

## Service Control Policies (SCPs)

SCPs are guardrails applied at the AWS Organizations level. They limit what accounts can do — even if an IAM admin in that account tries to override them.

Common preventive SCPs:

```json
// Prevent disabling CloudTrail
{
  "Sid": "DenyCloudTrailDisable",
  "Effect": "Deny",
  "Action": [
    "cloudtrail:DeleteTrail",
    "cloudtrail:StopLogging",
    "cloudtrail:UpdateTrail"
  ],
  "Resource": "*"
}
```

```json
// Restrict to approved regions only
{
  "Sid": "DenyNonApprovedRegions",
  "Effect": "Deny",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "StringNotEquals": {
      "aws:RequestedRegion": ["us-east-1", "us-west-2"]
    }
  }
}
```

```json
// Prevent public S3 bucket ACLs
{
  "Sid": "DenyPublicS3",
  "Effect": "Deny",
  "Action": "s3:PutBucketAcl",
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "s3:x-amz-acl": ["public-read", "public-read-write", "authenticated-read"]
    }
  }
}
```

SCPs apply to every principal in the account including root — they're the strongest preventive control available.

---

## Common misconfigurations and fixes

| Misconfiguration | Detection | Fix |
|-----------------|-----------|-----|
| Public S3 bucket | Config rule, Access Analyzer | Enable S3 Block Public Access at account level |
| Security group open to 0.0.0.0/0 on SSH/RDP | Config rule | Restrict to specific IP ranges or use SSM Session Manager instead |
| Root account used for daily operations | CloudTrail + Config | Create IAM users/roles; disable root access keys |
| No MFA on console users | Config rule | Enforce with IAM policy requiring MFA |
| Long-lived access keys | Config rule | Replace with IAM roles and instance profiles |
| Unencrypted S3 / EBS | Config rule | Enable default encryption at the account level |
| No VPC flow logs | Manual check | Enable flow logs to S3 or CloudWatch Logs |
| Overly permissive IAM policies (`*:*`) | Access Analyzer + manual | Scope down to specific actions and resources |

### Enable S3 Block Public Access at account level (do this first)

```bash
aws s3control put-public-access-block \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

---

## Responding to a cloud security finding

1. **Don't panic, don't delete** — preserve evidence before making changes
2. **Scope the blast radius** — what resources did the affected credential/role have access to?
3. **Revoke the credential** — disable the access key or role immediately
4. **Check CloudTrail** — what was done with the credential? Time window?
5. **Rotate secrets** — any secrets the compromised identity could have accessed
6. **Fix the root cause** — how did they get in? Patch the gap
7. **Document** — what happened, what was accessed, what you did

```bash
# Quickly see what an access key did recently
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=AKIAIOSFODNN7EXAMPLE \
  --start-time 2024-01-01T00:00:00Z \
  --max-results 50
```

---

## Related

- IAM patterns and least privilege design: [`identity-authz`](../identity-authz/SKILL.md)
- Zero trust and service identity: [`zero-trust-design`](../zero-trust-design/SKILL.md)
- Full CVE and vulnerability lifecycle: [`cve-lifecycle`](../cve-lifecycle/SKILL.md)
- Security metrics and posture reporting: [`appsec-metrics`](../appsec-metrics/SKILL.md)
