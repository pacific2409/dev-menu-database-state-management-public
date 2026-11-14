> 本Repositoryは、ポートフォリオ公開用に作成したProject成果物のCopyです。Security、Environment固有情報、運用記録、作業履歴その他の一部内容は公開対象から除外しています。そのため、内部Repositoryの完全な構成および履歴とは一致しません。

# Database State Management

## Project Information

- **Project**: DevMenu
- **Domain**: Database
- **Module**: Database State Management
- **Documentation Repository**:
  - [Public Documentation](https://github.com/pacific2409/dev-menu-docs-public)

## Reference Specifications

The following files in the Documentation Repository are the primary specifications for this module.

- `persistent/details/database-definition.md`
- `persistent/details/table/technologies-table-spec.md`
- `persistent/details/table/shared-histories-table-spec.md`
- `persistent/details/table/proposal-items-table-spec.md`
- `persistent/function-design.md`
- `persistent/system-architecture.md`
- `persistent/infrastructure-architecture.md`

## Overview

This module manages the version-controlled SQL used to initialize the DevMenu Database state.

Its responsibilities are:

- Create the Environment-specific Schema.
- Create the Application and Migration Accounts from externally managed Credentials.
- Apply least-privilege Grants for each Account.
- Create the `technologies`, `shared_histories` and `proposal_items` Tables, including their Keys, Indexes and Constraints.

The module does not own RDS Infrastructure, Application persistence logic, Seed Data, Data Migration, Replication or an automated Migration Pipeline.

## Technology Stack

- MySQL 8.4 LTS
- SQLFluff
- AWS RDS for MySQL as the Runtime Database
- AWS Secrets Manager for externally managed Credentials
- AWS Systems Manager Port Forwarding for the approved management path

## Repository Structure

```text
.
├── database-schema/
│   ├── 001_create_schema.sql
│   └── 002_configure_users_and_grants.sql
├── ddl/
│   └── dev_menu/
│       ├── 003_create_technologies.sql
│       ├── 004_create_shared_histories.sql
│       └── 005_create_proposal_items.sql
├── .sqlfluff
└── requirements-dev.txt
```

SQL files use a module-wide three-digit sequence and are applied in numeric order. Once a file has been applied to an Environment, it is immutable. Corrections are added as a new numbered Roll-forward SQL file.

## Build and Execution

This module has no build artifact and no CI/CD Pipeline. Database changes are applied manually through the approved management path.

The runtime operator must:

1. Verify the AWS Account, Region, RDS target and authorized Caller.
2. Establish the approved SSM Port Forward to the target RDS Instance.
3. Use AWS CA Server Certificate verification for the MySQL connection.
4. Obtain the Master and purpose-specific Credentials without printing or persisting Secret values.
5. Set the runtime variables required by the SQL file headers.
6. Apply the SQL files in numeric order and read back the resulting Database state after each file.
7. Stop on the first error. Do not automatically retry, delete or repair partially applied state.

Exact Environment targets, Credentials, Commands and approval gates are intentionally excluded from this public copy.

## Configuration

### Runtime SQL Inputs

`001_create_schema.sql` requires:

- `@schema_name`

`002_configure_users_and_grants.sql` requires:

- `@schema_name`
- `@application_username`
- `@application_host`
- `@application_password`
- `@migration_username`
- `@migration_host`
- `@migration_password`

Environment-specific values must come from the approved handover and Secrets Manager resources. Passwords and connection strings must not be stored in this Repository, command-line arguments, shell history, logs, Evidence or handover documents.

Credential and client configuration files used during manual execution must be created only in a restricted ephemeral memory location, use mode `0600` and be removed on both success and failure.

### SQL Mode

The effective MySQL SQL Mode is an Environment-level runtime property. Application input validation is the initial control for rejecting values that exceed the defined Column limits. Database clients and operators must not assume that a non-strict Session rejects over-length `CHAR` or `VARCHAR` values; the current Environment contract and Integration Test results must be checked before operational use.

## Verification

Create the local validation environment:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
```

Run static SQL validation:

```bash
.venv/bin/sqlfluff lint database-schema ddl
git diff --check
```

Runtime verification must follow the module Test Specification and retain sanitized Evidence for Schema, Account, Grant, TLS, Metadata, Constraint, referential-integrity and cleanup results. Secret values, Tokens and connection strings must never be retained as Evidence.

## CI/CD

No CI/CD Pipeline is assigned to this module. Apply and Verification are controlled manual operations with explicit target checks, user approval and post-operation read-back.
