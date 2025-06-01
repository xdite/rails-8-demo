# Zeabur 部署指南

這個 Rails 8 Books CRUD 應用已經配置好可以部署到 Zeabur 平台，包含 Active Storage 附件功能。

## 📋 前置需求

1. Zeabur 帳號
2. 已設置好的 PostgreSQL 服務
3. （推薦）Zeabur Volumes 用於持久化檔案儲存
4. （可選）雲端儲存服務（如 AWS S3、Google Cloud Storage）用於大規模生產環境

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

### 3. 配置 Zeabur Volumes（重要！）

為了確保上傳的檔案在容器重啟後不會遺失，**強烈建議**配置 Zeabur Volumes：

1. 在服務頁面點選「硬碟」分頁
2. 點選「Mount Volumes」按鈕
3. 配置如下：
   - **Volume ID**: `storage`（或任何你喜歡的名稱）
   - **Mount Directory**: `/rails/storage`
4. 點選確認並重新啟動服務

⚠️ **重要注意事項**：
- 根據 [Zeabur 文件](https://zeabur.com/docs/zh-TW/data-management/volumes)，啟用 Volumes 後服務將**無法支援零停機重新啟動**
- 每次重新啟動時會有短暫的服務中斷
- 掛載後該目錄的資料會全部清空，請在掛載前備份重要資料

### 4. 設置環境變數

確保以下環境變數已設置：

```bash
RAILS_ENV=production
RAILS_MASTER_KEY=<your_master_key>

# Active Storage 服務選擇（可選）
ACTIVE_STORAGE_SERVICE=local  # 使用本地儲存（配合 Volumes）
# 或
ACTIVE_STORAGE_SERVICE=amazon  # 使用 AWS S3

# AWS S3 配置（如果選擇雲端儲存）
AWS_ACCESS_KEY_ID=<your_aws_access_key>
AWS_SECRET_ACCESS_KEY=<your_aws_secret_key>
AWS_REGION=<your_aws_region>
AWS_BUCKET=<your_s3_bucket_name>

# Google Cloud Storage 配置（如果選擇 GCS）
GCS_PROJECT=<your_gcs_project>
GCS_BUCKET=<your_gcs_bucket>
GOOGLE_APPLICATION_CREDENTIALS=<path_to_service_account_json>
```

你可以在 `config/master.key` 文件中找到 master key。

### 5. 數據庫和 Rails 8 組件設置（關鍵步驟！）

部署完成後，**必須**運行以下命令來設置數據庫和 Rails 8 組件：

```bash
# 在 Zeabur 控制台的終端中運行
RAILS_ENV=production rails zeabur:setup_production_db
```

這個命令會自動安裝：
- **Solid Queue**：Rails 8 的默認背景任務處理器
- **Solid Cache**：Rails 8 的緩存系統
- **Solid Cable**：Rails 8 的 WebSocket 連接處理器
- **Active Storage**：檔案上傳和處理系統

或者你也可以分別運行：

```bash
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails solid_queue:install
RAILS_ENV=production rails solid_cache:install
RAILS_ENV=production rails solid_cable:install
RAILS_ENV=production rails active_storage:install
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails assets:precompile
```

## 🔧 配置說明

### 數據庫配置

應用已配置為在 production 環境中使用 PostgreSQL：

- 主要使用 `POSTGRES_CONNECTION_STRING` 或 `POSTGRES_URI`
- 如果連接字符串不可用，會回退到個別環境變數
- 包含 cache、queue 和 cable 的多數據庫配置

### Rails 8 組件

這個應用使用 Rails 8 的新特性：

- **Solid Queue**：處理背景任務（如圖片分析、檔案處理）
- **Solid Cache**：提供高效的緩存機制
- **Solid Cable**：處理 WebSocket 連接
- **Active Storage**：檔案上傳和管理

### Active Storage 配置

應用包含完整的 Active Storage 功能：

- **Zeabur Volumes 儲存**：使用 Zeabur 的持久儲存空間（推薦）
- **雲端儲存**：可配置 AWS S3 或 Google Cloud Storage（適合大規模應用）
- **圖片處理**：支援圖片縮放、裁剪等功能
- **檔案驗證**：自動驗證檔案類型和大小

#### 支援的檔案類型

- **封面圖片**：PNG, JPG, JPEG, GIF（最大 5MB）
- **其他附件**：圖片、PDF、文字檔案（最大 10MB）

### Gem 配置

- `sqlite3` gem 僅用於開發和測試環境
- `pg` gem 僅用於 production 環境
- `image_processing` gem 用於圖片處理功能

## 🛠️ 實用命令

### 檢查環境變數和組件

```bash
rails zeabur:check_postgres_env        # 檢查 PostgreSQL 配置
rails zeabur:check_active_storage      # 檢查 Active Storage 配置
rails zeabur:check_volumes             # 檢查 Zeabur Volumes 配置
rails zeabur:check_rails8_components   # 檢查 Rails 8 組件安裝狀態
rails zeabur:check_all                 # 運行所有檢查
```

### 完整的生產環境設置

```bash
RAILS_ENV=production rails zeabur:setup_production_db
```

### Active Storage 相關命令

```bash
# 安裝 Active Storage
RAILS_ENV=production rails active_storage:install

# 清理未使用的附件（可選）
RAILS_ENV=production rails active_storage:purge_unattached

# 查看儲存統計
RAILS_ENV=production rails zeabur:storage_stats
```

## 📁 檔案儲存配置

### Zeabur Volumes 儲存（推薦）

使用 Zeabur 的持久儲存空間來保存上傳的檔案：

**優點**：
- 檔案在容器重啟後不會遺失
- 成本相對較低
- 配置簡單
- 適合中小型應用

**配置步驟**：
1. 在 Zeabur 控制台配置 Volume
2. 掛載目錄：`/rails/storage`
3. 設置環境變數：`ACTIVE_STORAGE_SERVICE=local`

**注意事項**：
- 啟用 Volumes 後無法零停機重啟
- 需要定期備份重要檔案
- 檔案僅存在於單一伺服器

### 雲端儲存（大規模應用）

對於大規模生產環境，建議使用雲端儲存服務：

#### AWS S3 配置

```bash
# 環境變數
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_BUCKET=your-bucket-name
ACTIVE_STORAGE_SERVICE=amazon
```

#### Google Cloud Storage 配置

```bash
# 環境變數
GCS_PROJECT=your_project
GCS_BUCKET=your_bucket
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
ACTIVE_STORAGE_SERVICE=google
```

## 📝 注意事項

1. 確保 `config/master.key` 文件存在且包含正確的密鑰
2. 如果使用自定義域名，請在 Zeabur 控制台中配置
3. 建議在部署前先在本地測試 production 配置
4. **重要**：配置 Zeabur Volumes 來避免檔案在容器重啟時遺失
5. **關鍵**：必須安裝 Rails 8 組件（Solid Queue 等）才能正常使用檔案上傳功能
6. 啟用 Volumes 後，服務重啟會有短暫中斷
7. 定期備份上傳的檔案
8. 監控儲存空間使用量

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

### Rails 8 組件問題

如果遇到 `solid_queue_jobs` 表不存在的錯誤：

1. **檢查組件安裝狀態**：
   ```bash
   RAILS_ENV=production rails zeabur:check_rails8_components
   ```

2. **重新安裝組件**：
   ```bash
   RAILS_ENV=production rails zeabur:setup_production_db
   ```

3. **手動安裝缺失的組件**：
   ```bash
   RAILS_ENV=production rails solid_queue:install
   RAILS_ENV=production rails solid_cache:install
   RAILS_ENV=production rails solid_cable:install
   RAILS_ENV=production rails db:migrate
   ```

### Active Storage 問題

1. **檔案上傳失敗**：檢查檔案大小和格式限制
2. **圖片無法顯示**：確認 `image_processing` gem 已安裝
3. **檔案遺失**：確認已正確配置 Zeabur Volumes
4. **權限問題**：確保 `/rails/storage` 目錄有正確的讀寫權限
5. **儲存空間不足**：檢查 Zeabur Volumes 使用量或考慮雲端儲存
6. **背景任務失敗**：確認 Solid Queue 已正確安裝

### Zeabur Volumes 相關問題

1. **Volume 掛載失敗**：檢查 Volume ID 和掛載路徑是否正確
2. **檔案權限錯誤**：確認容器內的使用者有讀寫權限
3. **服務無法啟動**：檢查 Volume 配置是否與 Dockerfile 中的路徑一致

## 💰 成本考量

### Zeabur Volumes 計費

根據 [Zeabur 價目表](https://zeabur.com/docs/zh-TW/data-management/volumes)：
- Volumes 按使用量計費
- 適合中小型應用的檔案儲存需求
- 比雲端儲存服務更經濟實惠

### 雲端儲存計費

- AWS S3、Google Cloud Storage 等按流量和儲存量計費
- 適合大規模應用或需要 CDN 加速的場景

## 📚 功能特性

這個應用包含：

- ✅ 完整的 Books CRUD 功能
- ✅ **Rails 8 新特性**
  - 🚀 Solid Queue 背景任務處理
  - 💾 Solid Cache 緩存系統
  - 🔌 Solid Cable WebSocket 支援
- ✅ **Active Storage 附件功能**
  - 📸 書籍封面圖片上傳
  - 📎 多檔案附件支援
  - 🖼️ 圖片預覽和縮放
  - 📥 檔案下載功能
  - ✅ 檔案類型和大小驗證
- ✅ **Zeabur Volumes 持久化儲存**
- ✅ 現代化的 Tailwind CSS UI
- ✅ 響應式設計
- ✅ 表單驗證和錯誤處理
- ✅ PostgreSQL 生產環境支持
- ✅ 多數據庫配置（主庫、緩存、隊列、Cable）
- ✅ 圖片處理功能（縮放、裁剪）

## 🎯 訪問應用

部署完成後，你可以：

1. 訪問根路徑 `/` 查看書籍列表
2. 添加新書籍並上傳封面圖片
3. 上傳多個附件檔案
4. 查看、編輯和刪除書籍
5. 下載附件檔案
6. 享受現代化的用戶界面

## 🔒 安全性考量

1. 檔案類型驗證：只允許安全的檔案格式
2. 檔案大小限制：防止過大檔案上傳
3. 使用者權限：確保適當的存取控制
4. 雲端儲存：使用 HTTPS 傳輸加密
5. Volumes 權限：確保容器內檔案權限正確設置

## 📋 部署檢查清單

- [ ] PostgreSQL 服務已創建並運行
- [ ] GitHub 倉庫已連接到 Zeabur
- [ ] 環境變數已正確設置（`RAILS_MASTER_KEY` 等）
- [ ] **Zeabur Volumes 已配置**（Volume ID: `storage`, Mount Directory: `/rails/storage`）
- [ ] **Rails 8 組件已安裝**（運行 `rails zeabur:setup_production_db`）
- [ ] 資料庫遷移已完成
- [ ] Active Storage 已安裝
- [ ] Solid Queue、Solid Cache、Solid Cable 已安裝
- [ ] 應用可以正常訪問
- [ ] 檔案上傳功能正常運作
- [ ] 檔案在重啟後仍然存在
- [ ] 背景任務正常處理

祝你部署順利！🚀 