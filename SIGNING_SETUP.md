# Android署名設定

## 1. キーストアファイルの作成

以下のコマンドでキーストアファイルを作成してください：

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## 2. key.propertiesファイルの設定

`android/key.properties`ファイルを以下のように設定してください：

```properties
storePassword=あなたのストアパスワード
keyPassword=あなたのキーパスワード
keyAlias=upload
storeFile=../app/upload-keystore.jks
```

## 3. セキュリティ注意事項

- **key.propertiesファイルは絶対にGitにコミットしないでください**
- `.gitignore`に`android/key.properties`と`android/app/upload-keystore.jks`を追加してください
- パスワードとキーストアファイルは安全な場所に保管してください

## 4. ビルド実行

設定完了後、以下のコマンドでリリースビルドを実行：

```bash
flutter build appbundle --release
```

## 5. トラブルシューティング

### 署名エラーが発生する場合
- キーストアファイルのパスが正しいか確認
- パスワードが正しいか確認
- キーエイリアスが正しいか確認

### ファイルが見つからない場合
- `android/key.properties`ファイルが存在するか確認
- `android/app/upload-keystore.jks`ファイルが存在するか確認

