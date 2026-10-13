# Ground Truth 测试数据集

> 当前仓库提供 35 张可复现的虚拟合成名片及逐张 Ground Truth。若教师另发统一数据集，最终验收必须再使用教师数据重跑。

## 数据集构成建议（30~50 张）

| 类型 | 数量 | 说明 |
|------|------|------|
| 中文名片 | 8~10 | 标准中文姓名、公司、职位 |
| 英文名片 | 8~10 | 标准英文姓名、Company、Title |
| 中英双语 | 5~8 | 正反两面中英混排 |
| 竖版/特殊布局 | 3~5 | 非标准布局，检测难度高 |
| 多电话/多 Email | 3~5 | Mobile + Office + Fax 三条线 |
| 字段缺失 | 3~5 | 故意不含 Website / Address 等 |
| 拍摄质量较差 | 3~5 | 轻微模糊 / 低光 / 有阴影 |
| 复杂 Logo / 背景 | 2~4 | 背景干扰 OCR |

**重要**：所有名片必须使用虚拟合成数据，避免真实手机号、真实姓名等敏感信息。

## Ground Truth JSON Schema

```json
{
  "card_id": "gt_001",
  "description": "中英双语，标准正平面片",
  "image_file": "gt_001.jpg",
  "ground_truth": {
    "name": "David Chen",
    "company": "ABC Technologies",
    "jobTitle": "Technical Director",
    "mobile": "+1-555-123-4567",
    "email": "david.chen@example.com",
    "additionalEmails": ["sales@example.com"],
    "website": "www.abc-tech.com",
    "address": "123 Tech Street, Silicon Valley, CA 94000"
  },
  "required_accuracy_fields": ["name", "company", "mobile", "email"]
}
```

- `ground_truth` 中字段值为 `null` 表示原图不存在该字段（用于验证 AI 不补全规则）
- `additionalEmails` 为数组；不存在其他邮箱时可省略或使用空数组
- 用 `required_accuracy_fields` 标记哪些字段必须 100% 正确，哪些允许模糊匹配

## 目录约定

- `Tests/GroundTruth/gt_XXX.json`：标准答案与图片文件名。
- `Tests/GroundTruth/gt_XXX.jpg`：由 `Scripts/generate_test_cards.py` 可重复生成的测试图片。
- `Tests/ActualResults/gt_XXX.json`：在 Mac/iPhone 上跑完 OCR 后导出的实际结构化结果。
- `python Scripts/evaluate_accuracy.py`：比对实际结果，输出逐字段准确率和“缺失字段被补全”次数。
