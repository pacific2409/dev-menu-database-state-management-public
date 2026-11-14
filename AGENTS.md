# AGENTS.md

## Pull Request Review Policy
- 必ず日本語でレビューおよびコメントをしてください。

## Architecture and Responsibility
- Database Object間の依存関係、所有境界および変更の影響範囲が明確であることを確認する。
- Schema変更が既存の利用側との互換性を不必要に損なわず、安全な移行順序を維持していることを確認する。
- 一つの変更へ無関係な責務を混在させず、変更目的と対象範囲を明確に保つ。

## Implementation Quality
- SQLは意図、適用順序および依存関係を読み取れる、簡潔で一貫した構造にする。
- Data Type、NULL許容、Default値、KeyおよびConstraintを暗黙的な挙動へ依存させず、必要な内容を明示する。
- Naming、Formattingおよび記述方法をRepository内で一貫させる。
- 未確定の要件やDatabase固有の挙動を推測で補完しない。
- Database変更はVersion管理し、変更内容と適用結果を追跡できる状態にする。

## Testing and Verification
- SQLの構文、依存関係および想定する適用順序を検証する。
- 適用後のDatabase Object、Column、Index、KeyおよびConstraintをMetadataからRead-backし、期待した状態と一致することを確認する。
- 正常系だけでなく、NULL、境界値、重複、参照整合性違反その他の制約違反を検証する。
- 変更失敗時に中途半端な状態を残さないこと、および必要な復旧方法が明確であることを確認する。
- 検証Evidenceは再確認可能な形で記録し、機密情報を含めない。

## Security
- Credential、Secretその他の機密値をSource、SQL、Command Line、Shell History、LogまたはEvidenceへ含めない。
- Database UserおよびGrantは最小権限とし、利用目的の異なるCredentialを共用しない。
- Database接続では通信の暗号化と証明書検証を維持する。
- 利用者入力をSQL文字列として直接組み立てることを前提としたDatabase構造または運用を導入しない。
- 機密情報をDefault値、Comment、Object名その他のDatabase Metadataへ格納しない。

## Performance
- Indexは想定するQuery、Join、Sortおよび一意性制約に基づいて設計する。
- Write負荷、Storage使用量およびMaintenance Costを考慮せずにIndexを追加しない。
- Query Planや実測値を確認できる場合は、それらを根拠としてPerformance上の判断を行う。
- 将来の規模を推測した過剰な最適化より、現在確認できるAccess Patternと制約を優先する。

## Module-specific Considerations
- 一時的な作業状況、特定のRelease対象または個別仕様の要約を、本品質基準へ固定的に持ち込まない。
- Database変更では互換性、適用順序、可逆性およびRoll-forward可能性を確認する。
- 破壊的変更は必要性、利用側への影響および安全な移行条件が明確でない限り導入しない。
- Environmentごとの差異をSQLへ無秩序に埋め込まず、変更内容を比較・追跡できる状態を維持する。
