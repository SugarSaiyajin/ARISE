# 圖片與 APK 交付檢查（2026-10-20）

目前已完成並可重新交付的版本是 0.14.0；開發中的 0.20 不包含在本次交付包。

## 檢查結果

- 先前訊息提供 `/workspace/ARISE/...` 工作區路徑，沒有可驗證的公開下載網址。工作區存在檔案不代表手機可下載，這是交付流程缺口。
- 原始專案、docs、build/android 目錄為 0700，APK 與截圖為 0600。不同使用者的讀取服務可能因此無法存取；尚無用戶端紀錄可證明這就是唯一原因。
- 兩張 1280×720 PNG 均通過完整解碼驗證。
- 0.14.0 APK 為 82,178,195 bytes，與原始驗證報告 SHA-256 一致：`be68ae3be81f8275f7d6db209f149bcdab596906c9cfcb501e32b96ae913a29f`。
- 重新執行 APK ZIP 完整性、v2 簽章、16 KB ZIP／ELF 對齊、套件名稱、啟動入口、唯一 provider 與零權限檢查，全數通過。
- Android API 24+、ARM64；尚未在實體手機安裝驗證。這些檢查不能排除特定手機的執行問題。
- GitHub API 與 release 列表連線均回傳 Forbidden；重新取得執行權限後仍相同。沒有成功發布，也沒有成功由外部網址重新下載驗證。此錯誤不是使用者批准遭自動審查拒絕。

## 已採取的修正

執行 `python3 tools/package_delivery.py`，先驗證已完成 APK，再複製原檔產生 `build/delivery/arise-0.14.0/` 與 `build/delivery/arise-0.14.0.zip`，包含 APK、兩張 PNG、MP4、安裝說明、validation.json 及 SHA256SUMS.txt。ZIP 已通過完整性檢查；交付檔案為 0644、交付目錄及必要父目錄為 0755，不開放金鑰或工具鏈。圖片透過對話圖片輸出直接顯示。

目前只能提供工作區檔案下載連結，不能保證聊天介面支援該下載方式。尚需可用的附件傳輸或專案發布通道，才能確認用戶手機下載流程恢復。不要將檔案存在、權限修正或產生 ZIP 當成已完成公開發布。

## 後續修復：已建立並驗證 HTTPS 下載

用戶回報附件仍無法下載後，發現 GitHub API 雖然 Forbidden，Git 與網頁存取正常。已將 0.14.0 完整交付檔案發布至獨立分支 `delivery/android-0.14.0`，未修改 main。

- APK：https://github.com/SugarSaiyajin/ARISE/raw/refs/heads/delivery/android-0.14.0/arise-0.14.0.apk
- 下載頁：https://github.com/SugarSaiyajin/ARISE/tree/delivery/android-0.14.0
- 圖片：https://raw.githubusercontent.com/SugarSaiyajin/ARISE/refs/heads/delivery/android-0.14.0/character.png

已透過標準 HTTPS、不附加 GitHub 權杖，從上述 APK 連結完整重新下載 82,178,195 bytes，HTTP 200，SHA-256 與已驗證原檔一致。圖片與下載頁也回傳 HTTP 200，圖片校驗碼吻合。詳見 delivery-http-verification-0.14.json。這取代上一節尚無公開下載通道的狀態；用戶手機端實際下載與安裝仍待驗證。
