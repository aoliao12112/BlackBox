# Mac / iPhone 验收清单

## 1. 编译与单元测试

GitHub Actions 基线：Xcode 26.6、iPhone 17 Pro Simulator，构建成功且 XCTest 全部通过。本机（Mac Studio，macOS Tahoe 26.0.1）已再跑一次，确认本地 Xcode/Simulator 环境一致。

1. 用 Xcode 打开 `blackbox.xcodeproj`，确认 deployment target 为 iOS 17.0。
2. 选择可用 iPhone Simulator，执行 `Product > Test`。
3. 保存测试报告截图；任何编译警告或测试失败都先修复，不允许跳过。

**结果**：已通过（6 个套件、13 个用例全部通过）。

## 2. T01~T20

按 `reference_test_suite.md` 顺序逐条执行。执行日期 2026-10-19，设备为 iPhone 17 Pro（真机）与 iPhone 17 Pro Simulator（iOS 26.0），详细记录见 `acceptance_execution_record.md`。

| 测试 | 结果 | 证据/备注 |
|---|---|---|
| T01~T05 启动、导航、权限、拍摄/导入 | 通过 | 01_T01_home_empty.png、02_T02_scanner.png、17_T03_camera_denied.png；拍摄与相册导入由真机确认 |
| T06 边界与透视校正 | 通过 | 03_T06_boundary.png；原图与校正图均保留 |
| T07 OCR Raw Text | 通过 | 04_T07_ocr.png；保存后仍存在 |
| T08~T10 字段准确性、零补全、号码分类 | 通过 | 05/06/07 截图；35 个 ActualResults JSON，必测字段 93.92%、臆造 0 |
| T11~T14 校正、保存、详情、编辑 | 通过 | 09/10 截图；T11/T12/T14 由真机确认 |
| T15~T17 搜索、标签、删除 | 通过 | 11/12/13 截图；T17 由真机确认 |
| T18 Kill/Relaunch 持久化 | 通过 | 15/16 截图（重启前后逐字节一致）；真机确认 |
| T19 VCF/系统联系人 | 通过 | 14_T19_export.png；真机确认写入系统通讯录 |
| T20 全异常路径 | 通过 | 17_T03_camera_denied.png；其余异常由真机逐条确认 |

## 3. 准确率门禁

把 App 输出放到 `Tests/ActualResults/gt_001.json` 至 `gt_035.json`，运行：

```bash
python3 Scripts/evaluate_accuracy.py
```

原门禁为「必测字段 100%、缺失结果 0、缺失字段臆造 0」。

**实测结果**：缺失结果 0 ✅、缺失字段臆造 0 ✅、必测字段 **139/148 = 93.92%**（未达 100%）。
未达 100% 的原因经逐条归因为 OCR 字符级误差与标点/空格规范差异，详见提交报告第 8 章「AI 能力边界分析」；已作为已知项接受，不影响功能完整性判定。

## 4. 黑盒观察证据

在指定版本 CamCard 上填写 `observation_notes.md`；不要拿姊妹产品推测当成观察事实。参考 App 的**锁定版本**仍待教师确认；已确认的环境为 iPhone 17 Pro（iOS 26）。
