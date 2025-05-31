# Zeabur 部署指南

這個 Rails 8 Books CRUD 應用已經配置好可以部署到 Zeabur 平台。

## 📋 前置需求

1. Zeabur 帳號
2. 已設置好的 PostgreSQL 服務

## 🚀 部署步驟

### 1. 在 Zeabur 上創建 PostgreSQL 服務

1. 登入 Zeabur 控制台
2. 創建新項目
3. 添加 PostgreSQL 服務
4. Zeabur 會自動提供以下環境變數：
   - `POSTGRES_CONNECTION_STRING`
   - `POSTGRES_DATABASE`
   - `POSTGRES_HOST`
   - `POSTGRES_PASSWORD`
   - `POSTGRES_PORT`
   - `POSTGRES_URI`
   - `POSTGRES_USERNAME`
   - `POSTGRESQL_HOST`

### 2. 部署 Rails 應用

1. 將代碼推送到 GitHub
2. 在 Zeabur 項目中添加 Git 服務
3. 連接你的 GitHub 倉庫
4. Zeabur 會自動檢測這是一個 Rails 應用並開始構建

### 3. 設置環境變數

確保以下環境變數已設置：

```bash
RAILS_ENV=production
RAILS_MASTER_KEY=<your_master_key>
```

你可以在 `config/master.key` 文件中找到 master key。

### 4. 數據庫設置

部署完成後，運行以下命令來設置數據庫：

```bash
# 在 Zeabur 控制台的終端中運行
RAILS_ENV=production rails zeabur:setup_production_db
```

或者分別運行：

```bash
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails assets:precompile
```

## 🔧 配置說明

### 數據庫配置

應用已配置為在 production 環境中使用 PostgreSQL：

- 主要使用 `POSTGRES_CONNECTION_STRING` 或 `POSTGRES_URI`
- 如果連接字符串不可用，會回退到個別環境變數
- 包含 cache、queue 和 cable 的多數據庫配置

### Gem 配置

- `sqlite3` gem 僅用於開發和測試環境
- `pg` gem 僅用於 production 環境

## 🛠️ 實用命令

### 檢查環境變數

```bash
rails zeabur:check_postgres_env
```

### 完整的生產環境設置

```bash
RAILS_ENV=production rails zeabur:setup_production_db
```

## 📝 注意事項

1. 確保 `config/master.key` 文件存在且包含正確的密鑰
2. 如果使用自定義域名，請在 Zeabur 控制台中配置
3. 建議在部署前先在本地測試 production 配置

## 🔍 故障排除

### 數據庫連接問題

1. 檢查環境變數是否正確設置
2. 確認 PostgreSQL 服務正在運行
3. 檢查網絡連接和防火牆設置

### 資產編譯問題

確保在部署時運行了資產預編譯：

```bash
RAILS_ENV=production rails assets:precompile
```

## 📚 功能特性

這個應用包含：

- ✅ 完整的 Books CRUD 功能
- ✅ 現代化的 Tailwind CSS UI
- ✅ 響應式設計
- ✅ 表單驗證和錯誤處理
- ✅ PostgreSQL 生產環境支持
- ✅ 多數據庫配置（主庫、緩存、隊列、Cable）

## 🎯 訪問應用

部署完成後，你可以：

1. 訪問根路徑 `/` 查看書籍列表
2. 添加新書籍
3. 查看、編輯和刪除書籍
4. 享受現代化的用戶界面

祝你部署順利！🚀 