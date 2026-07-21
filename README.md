# S3 Data Lake Foundation — Terraform + CI/CD

Terraform implementation of the lab described in [`S3 Data Lake Foundation.md`](./S3%20Data%20Lake%20Foundation.md), deployed via a GitHub Actions CI/CD pipeline.

## What gets built

| Lab part | Resource(s) |
|---|---|
| Part 4 — Bucket | `aws_s3_bucket.data_lake` (`data-lake-prod-<ACCOUNT_ID>`), Block Public Access enabled, ACLs disabled |
| Part 5 — Security | SSE-S3 encryption + bucket key, bucket policy: deny non-HTTPS, deny unencrypted `PutObject`, allow only `DataEngineerRole` / `GlueServiceRole` / `RedshiftIAMRole` |
| Part 6 — Versioning | Enabled on the data lake bucket |
| Part 7 — Access logging | Dedicated `data-lake-prod-logs-<ACCOUNT_ID>` bucket, prefix `s3-access-logs/` |
| Part 8 — CloudTrail | `data-lake-audit-trail` (multi-region, log file validation, S3 object-level data events) writing to `data-lake-prod-cloudtrail-<ACCOUNT_ID>` |
| Part 9 — Folders | `raw/`, `processed/`, `curated/`, `temp/`, `archive/` placeholder keys |
| Part 10 — Lifecycle | Processed → Glacier (90d) → Deep Archive (180d); Temp → delete (1d); Archive → Deep Archive (30d) → delete (7y) |
| Part 11 — Tags | `Environment`, `Owner`, `Purpose`, `CostCenter` applied via provider `default_tags` |
| Part 12 — Test data | `test_customers.csv` uploaded to `raw/`, gated by `var.upload_test_data` |

The IAM roles and VPC from Labs 1.1/1.2 are treated as pre-existing prerequisites — Terraform looks them up with `aws_iam_role` data sources rather than creating them.

## Layout

```
terraform/
  versions.tf, providers.tf     # Terraform/provider config, S3 backend
  variables.tf, locals.tf, data.tf
  s3_data_lake_bucket.tf        # Part 4-7
  s3_bucket_policy.tf            # Part 5
  s3_logs_bucket.tf              # Part 7
  cloudtrail.tf                  # Part 8
  s3_folders.tf                  # Part 9
  s3_lifecycle.tf                # Part 10
  test_data.tf, test_customers.csv  # Part 12
  outputs.tf
.github/workflows/terraform.yml # CI/CD pipeline
```

## CI/CD pipeline (`.github/workflows/terraform.yml`)

1. **security-scan** — Checkov static analysis of the Terraform on every PR/push.
2. **plan** — `terraform fmt -check`, `init`, `validate`, `plan`. On pull requests the plan is posted as a PR comment; on pushes to `main` the plan is saved as an artifact.
3. **apply** — runs only on push to `main`, gated by the `production` GitHub Environment (configure required reviewers there for a manual approval gate), downloads the saved plan and applies it exactly (`terraform apply tfplan`) so what was reviewed is what ships.

Auth to AWS uses OIDC (`aws-actions/configure-aws-credentials`) — no long-lived access keys stored in GitHub.

### Required repository configuration

**Secrets** (Settings → Secrets and variables → Actions → Secrets):
- `AWS_ROLE_ARN` — IAM role GitHub Actions assumes via OIDC
- `TF_STATE_BUCKET` — S3 bucket holding Terraform state
- `TF_STATE_REGION` — region of that bucket
- `TF_LOCK_TABLE` — DynamoDB table for state locking

**Variables** (same page, "Variables" tab, optional):
- `AWS_REGION` — defaults to `us-east-1`
- `TF_STATE_KEY` — defaults to `S3-Data-Lake-Foundation/terraform.tfstate`

**Environment**: create a `production` environment (Settings → Environments) with required reviewers to approve applies before they run.

The AWS IAM role trust policy must allow the GitHub OIDC provider (`token.actions.githubusercontent.com`) to assume it, scoped to this repo.

## Local usage

```bash
cd terraform
cp backend.hcl.example backend.hcl   # fill in your state bucket details
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Part 15 — Teardown (delete test file only)

Set `upload_test_data = false` (e.g. in a `*.tfvars` file or `-var`) and re-apply:

```bash
terraform apply -var="upload_test_data=false"
```

This removes only `raw/test_customers.csv`, leaving the bucket, IAM roles, VPC, and logging bucket intact — matching the lab's teardown step exactly.
