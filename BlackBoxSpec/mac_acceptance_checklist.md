# Mac / iPhone 验收清单

## 1. 编译与单元测试

1. 用 Xcode 打开 `blackbox.xcodeproj`，确认 deployment target 为 iOS 17.0。
2. 选择可用 iPhone Simulator，执行 `Product > Test`。
3. 保存测试报告截图；任何编译警告或测试失败都先修复，不允许跳过。

## 2. T01~T20

按 `reference_test_suite.md` 顺序逐条执行，并在下表填入日期、设备、结果和证据文件名。

| 测试 | 结果 | 证据/备注 |
|---|---|---|
| T01~T05 启动、导航、权限、拍摄/导入 | 待执行 | |
| T06 边界与透视校正 | 待执行 | 同时保留原图和校正图 |
| T07 OCR Raw Text | 待执行 | 检查保存后仍存在 |
| T08~T10 字段准确性、零补全、号码分类 | 待执行 | 导出 35 个 ActualResults JSON |
| T11~T14 校正、保存、详情、编辑 | 待执行 | |
| T15~T17 搜索、标签、删除 | 待执行 | |
| T18 Kill/Relaunch 持久化 | 待执行 | 必须真机或完整模拟器重启 |
| T19 VCF/系统联系人 | 待执行 | 检查地址、网址、多邮箱 |
| T20 全异常路径 | 待执行 | 每条异常均要截图/录屏 |

## 3. 准确率门禁

把 App 输出放到 `Tests/ActualResults/gt_001.json` 至 `gt_035.json`，运行：

```bash
python3 Scripts/evaluate_accuracy.py
```

只有“必测字段 100%、缺失结果 0、缺失字段臆造 0”才通过。否则修改实现并从失败样本开始回归，再跑全量。

## 4. 黑盒观察证据

在指定版本 CamCard 上填写 `observation_notes.md`；不要拿姊妹产品推测当成观察事实。锁定版本、iOS、设备后再记录差异和修订。
