# 異鄉田園 0.28「旅章與共生」

[下載Android APK（約104 MB）](https://github.com/SugarSaiyajin/ARISE/raw/refs/heads/delivery/android-0.28.0/arise-0.28.0.apk)

Android7以上、ARM64、OpenGL ES3。檔案104,307,407 bytes，低於GitHub單檔100MiB上限。與0.27同套件與簽章、版本代碼升至28；請直接覆蓋安裝，勿先解除安裝，以免刪除存檔。

本輪完成計劃1–5的遊戲功能、6的秋季提案，以及7的驗證與交付：

- 九名居民的新生活事件，各有情境敘述、兩個選擇及後續對話。
- 八種養殖生物的個性時段互動、照料日數與三階段里程碑。
- 四聚落三步探索旅章，連結原料與實際工藝品交付。
- 八件家具的移動、平面旋轉及通道預覽，確認後才套用。
- 每週三份合作訂單與四項長期養成目標。
- 秋季作物、場景、節慶與道具獨立待審，未加入遊戲。

入口：手札→經營總覽→長期發展。事件需走近本人、好感5；家具只能在農舍確認；訂單需走近莊園出貨箱。日常照料會自動累計，里程碑謝禮與週訂單不重複領取。

[完整操作、數值與限制](docs/CHAPTER_028.md) · [8,546項檢查](docs/validation-0.28-tests.json) · [APK驗證](validation.json) · [更新相容性](docs/update-compatibility-0.28.json)

![居民事件](docs/chapter-0.28-story.png)
![家具旋轉預覽](docs/chapter-0.28-rotation.png)
![成長里程碑](docs/chapter-0.28-growth.png)
![每週交付確認](docs/chapter-0.28-order.png)

[15.7秒實際Godot渲染影片](https://github.com/SugarSaiyajin/ARISE/raw/refs/heads/delivery/android-0.28.0/docs/chapter-0.28-gameplay.mp4)。使用獨立示範存檔與桌面觸控介面，不能代表實體手機效能；沒有贈送示範物資給新玩家。

[秋季提案05：待審閱](docs/design-review-05/README.md)。通過後才會製作正式圖集並整合，0.28仍維持春夏循環。

![秋季概念稿，未加入APK](docs/design-review-05/autumn.png)

手機手感修正與上架準備維持暫緩，未連接手機或模擬器。

APK SHA256：`8b818f0b7f0bb4fd3b5abf3cad029d7a440f406c394688d3666084a3a7c3ade2`

[原始碼提交](https://github.com/SugarSaiyajin/ARISE/commit/6d420cf)
