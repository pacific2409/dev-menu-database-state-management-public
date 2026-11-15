> 本Repositoryは、ポートフォリオ公開用に作成したProject成果物のCopyです。Security、Environment固有情報、運用記録、作業履歴その他の一部内容は公開対象から除外しています。そのため、内部Repositoryの完全な構成および履歴とは一致しません。

# Database State Management

## プロジェクト情報

- **プロジェクト**: DevMenu
- **ドメイン**: Database
- **モジュール**: Database State Management
- **Documentation Repository**:
  - [公開Documentation](https://github.com/pacific2409/dev-menu-docs-public)

## 参照仕様

Documentation Repositoryにある以下のファイルを、本Moduleの正本となる仕様とする。

- `persistent/details/database-definition.md`
- `persistent/details/table/technologies-table-spec.md`
- `persistent/details/table/shared-histories-table-spec.md`
- `persistent/details/table/proposal-items-table-spec.md`
- `persistent/function-design.md`
- `persistent/system-architecture.md`
- `persistent/infrastructure-architecture.md`

## 概要

本Moduleは、DevMenu Databaseの状態を初期構成するために使用するSQLをVersion管理する。

本Moduleの責務は以下のとおり。

- Environment固有のSchemaを作成する。
- 外部で管理されるCredentialを使用して、Application AccountおよびMigration Accountを作成する。
- 各Accountへ最小権限のGrantを適用する。
- Key、IndexおよびConstraintを含む、`technologies`、`shared_histories`、`proposal_items` Tableを作成する。

RDS Infrastructure、Applicationの永続化Logic、Seed Data、Data Migration、Replicationおよび自動Migration Pipelineは、本Moduleの責務に含まれない。

## 技術スタック

- MySQL 8.4 LTS
- SQLFluff
- Runtime DatabaseとしてのAWS RDS for MySQL
- 外部管理CredentialのためのAWS Secrets Manager
- 承認された管理経路としてのAWS Systems Manager Port Forwarding

## Repository構成

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

SQLファイルにはModule全体で一意となる3桁の連番を付け、番号順に適用する。一度Environmentへ適用したファイルは変更しない。修正は、新しい番号を付けたRoll-forward SQLファイルとして追加する。

## 構築と実行

本ModuleにはBuild ArtifactおよびCI/CD Pipelineがない。Database変更は、承認された管理経路を通じて手動で適用する。

実行担当者は、以下を実施する。

1. AWS Account、Region、対象RDSおよび承認されたCallerを確認する。
2. 対象RDS Instanceへの承認されたSSM Port Forwardを確立する。
3. MySQL接続でAWS CA Server Certificateの検証を使用する。
4. Secret値を出力または永続化せずに、Master Credentialおよび用途別Credentialを取得する。
5. SQLファイルのHeaderで要求されるRuntime変数を設定する。
6. SQLファイルを番号順に適用し、各ファイルの適用後にDatabaseの状態をRead-backする。
7. 最初のErrorで停止する。部分的に適用された状態に対して、自動的なRetry、削除または修復を行わない。

正確なEnvironmentの対象、Credential、Commandおよび承認Gateは、この公開用Copyから意図的に除外している。

## 設定

### Runtime SQL入力

`001_create_schema.sql`には、以下が必要となる。

- `@schema_name`

`002_configure_users_and_grants.sql`には、以下が必要となる。

- `@schema_name`
- `@application_username`
- `@application_host`
- `@application_password`
- `@migration_username`
- `@migration_host`
- `@migration_password`

Environment固有の値は、承認されたHandoverおよびSecrets Manager Resourceから取得する。PasswordおよびConnection Stringを、本Repository、Command Line Argument、Shell History、Log、EvidenceまたはHandover文書へ保存してはならない。

手動実行で使用するCredentialおよびClient設定ファイルは、Accessが制限された一時Memory領域にのみ作成し、Mode `0600`を使用する。また、成功時と失敗時のどちらでも削除する。

### SQL Mode

有効なMySQL SQL Modeは、Environment LevelのRuntime Propertyである。定義されたColumn上限を超える値を拒否する初期Controlは、Applicationの入力Validationとする。Database Clientおよび実行担当者は、非Strict Sessionが上限を超える`CHAR`または`VARCHAR`値を拒否すると仮定してはならない。運用で使用する前に、現在のEnvironment ContractおよびIntegration Test結果を確認する。

## 検証

Local検証Environmentを作成する。

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
```

SQLのStatic Validationを実行する。

```bash
.venv/bin/sqlfluff lint database-schema ddl
git diff --check
```

Runtime Verificationは、ModuleのTest Specificationに従って実施し、Schema、Account、Grant、TLS、Metadata、Constraint、参照整合性およびCleanup結果についてSanitize済みのEvidenceを保持する。Secret値、TokenおよびConnection StringをEvidenceとして保持してはならない。

## CI/CD

本ModuleにはCI/CD Pipelineを割り当てていない。ApplyおよびVerificationは、明示的な対象確認、ユーザー承認および操作後のRead-backを伴う、統制された手動操作として実施する。
