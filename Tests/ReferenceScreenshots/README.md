# 参考版截图素材（CamCard）

本目录存放用于 UI 截图对比的 CamCard 参考版素材。

| 项 | 内容 |
|----|------|
| App | 名片全能王（CamCard），开发者 INTSIG Information Co., Ltd |
| 版本 | 8.65.0（App Store 当前在线版，2026-10-19 发布） |
| 来源 | Apple App Store 官方商店页公开截图 |
| 商店链接 | https://apps.apple.com/cn/app/id349447615 |
| 获取方式 | iTunes Search API 公开接口 |

## 文件说明

| 文件 | 对应页面 | 是否在复刻范围 |
|------|----------|----------------|
| camcard_01.jpg | 人脉搜索 | 否 |
| camcard_02.jpg | 名片识别 | 是 |
| camcard_03.jpg | 名片管理 | 是 |
| camcard_04.jpg | 名片更新 / 数据统计 | 否 |
| camcard_05.jpg | 名片访客 | 否 |
| camcard_06.jpg | 数字名片 | 否 |
| camcard_07.jpg | 企业查询 | 否 |

### 补充素材（2026-10-28 采集）

| 文件 | 来源 | 对应页面 | 用途 |
|------|------|----------|------|
| camcard_site_scan.png | 官网 camcard.com/zh-cn 产品页 | 拍摄页（单拍/连拍/多拍 + 边界框） | 对比一、校正对比 |
| camcard_store_boundary.png | App Store 美区公开截图 | 拍摄页（两张名片同时框选） | 校正 / 边界检测对比 |
| camcard_site_cardlist.png | 官网产品页 | 名片夹列表（手机 + PC 双端） | 对比二 |
| camcard_store_card_search.png | App Store 美区公开截图 | 名片夹 + 搜索 + 标签 + 备注 | 搜索 / 标签对比 |
| camcard_store_search.png | App Store 中国区公开截图 | 人脉搜索（搜索结果列表） | 搜索对比 |
| camcard_site_detail.png | 官网产品页 | 名片详情（字段 + 编辑名片/更换样式） | 详情页对比 |
| camcard_store_edit.png | App Store 美区公开截图 | 名片样式编辑（配色 / 社交链接） | 编辑页对比 |

补充素材说明：

- 官网素材来自 `https://www.camcard.com/zh-cn` 产品页（`static-cdn.camcard.com`），是官方对外展示的 App 界面图，同样带营销排版。
- 商店素材来自 iTunes Search API（`itunes.apple.com/cn|us/lookup?id=349447615`），仍是**营销宣传图**而非原始截屏。
- 以上均为公开素材，**不是教师锁定版本**；用于「同页面能对比即可」的初步对照。

## 注意事项

1. 这些是 App Store 的**营销宣传图**（含设备外框与文案），不是应用内原始截屏；对比时已按此前提说明。
2. 版本为商店当前在线版，**并非教师锁定的参考版本**；锁定版本确认后应重新采集。
3. 素材版权归 INTSIG / Apple 商店页所有，仅用于课程作业的界面比对，不作再分发用途。
4. 对比结论见 `BlackBoxSpec/ui_comparison.md` 与 `UI截图对比报告.docx`。
