# 实现状态与差距

更新日期：2026-10-19

## 已落地

- P1~P10 页面与主导航流程。
- 后置摄像头、相册导入、Vision 矩形检测、四点手调、真实透视校正。
- Vision OCR、Raw Text 留存、规则字段抽取；缺失字段保持 `nil`。
- Mobile / Office / Fax 按标签分类；一个主邮箱和多个附加邮箱全链路保留。
- 人工修改标记 `.manual`，保存原图、处理图和元数据。
- 搜索、标签筛选、备注、编辑、确认删除和重启持久化实现。
- VCF 和系统通讯录导出，包括地址、网址、多邮箱；已声明通讯录权限。
- 35 张虚拟合成名片、35 份 Ground Truth、准确率评估脚本和 XCTest target。
- GitHub Actions 已在 Xcode 26.6 / iPhone 17 Pro Simulator 上完成编译并运行 XCTest（6 个套件、13 个用例），结果全部通过。

## 验收进度（2026-10-19 更新）

- 已在本地 Mac（Mac Studio 2023，Apple M2 Max / 32 GB，macOS Tahoe 26.0.1）与 **iPhone 17 Pro 真机**完成验收。
- **T01~T20 全部 20 项通过**：模拟器取证 9 项 + 真机人工执行 11 项，执行记录见 `acceptance_execution_record.md`，截图见 `Tests/AcceptanceEvidence`。
- 35 张 Ground Truth 已由 iOS Vision OCR **全量端到端扫描**，必测字段准确率 **139/148 = 93.92%**，缺失字段臆造 0，结果见 `Tests/ActualResults`。
- 边界检测、OCR、字段抽取、持久化、导出、搜索、标签、权限等项均有截图或 XCTest 证据。
- 最终演示录屏已生成（`BlackBox-演示录屏.mp4`，覆盖 10 个页面）。

## 仍需注意（不阻塞提交）

- 字段级准确率为 93.92%（非 100%）：剩余差异为 OCR 字符级误差（简繁字形误识、标点被识别为空格、漏字母）与标点/空格规范差异，原因与逐条归因见提交报告第 8 章「AI 能力边界分析」。
- 参考环境锁定仍待教师确认：仅 **CamCard 锁定版本**（目标 iOS / 设备已确认为 iOS 26 / iPhone 17 Pro，见 `observation_notes.md`）。
- 「UI 截图对比 / UI Golden Test」已完成**初步版本**：基于 App Store 官方公开截图（CamCard 8.65.0）与项目截图并排对照，见 `BlackBoxSpec/ui_comparison.md`、`UI截图对比报告.docx`、`Tests/ReferenceScreenshots/`。局限：官方截图是营销宣传图且非教师锁定版本；详情/OCR/校正/编辑页无官方素材，需真机补拍。
- 教师若提供统一 30~50 张图片，需替换或追加当前合成集后重跑评估。

> 说明：本文旧版中「不能在 Windows 上宣称完成的项目」的结论（尚未在 Mac/真机运行、35 张未全量扫描）已被本轮 Mac 与真机验收结果替代，相关内容已在上方更新。
