# BlackBox

基于 SDD 的 CamCard 名片数字化功能切片复刻项目。

## 当前能力

- 后置摄像头拍摄、相册导入、矩形边界检测与 Core Image 透视校正
- Vision 中英文 OCR、保守的规则字段抽取、人工校正与字段来源记录
- 原图/校正图/OCR Raw Text/结构化字段的本地持久化
- 名片详情、搜索、标签、备注、删除、VCF 与系统通讯录导出
- 35 张虚拟合成名片 + Ground Truth + 自动准确率判定脚本
- XCTest：字段抽取、VCF 映射、持久化往返
- 验收证据与端到端演示录屏（`Tests/AcceptanceEvidence`、`BlackBox-演示录屏.mp4`）

## 开发环境

- Xcode 26（本项目在 Xcode 26.6 上验证）
- iOS 17.0 或更高版本（deployment target）
- 已在 iPhone 17 Pro（iOS 26）真机完成相机、权限、系统通讯录和 Kill/Relaunch 验收

在 Mac 上打开 `blackbox.xcodeproj`，选择 `blackbox` scheme 后运行。单元测试使用 `Product > Test`，或：

```bash
xcodebuild test -project blackbox.xcodeproj -scheme blackbox \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

生成/校验测试数据：

```bash
python3 Scripts/generate_test_cards.py
python3 Scripts/evaluate_accuracy.py
```

完整交付状态与验收记录见 `BlackBoxSpec/implementation_status.md`、`BlackBoxSpec/mac_acceptance_checklist.md` 与 `BlackBoxSpec/acceptance_execution_record.md`。
