# Ground Truth 测试数据集

> **Week 1 · 模板** · 学生应替换为教师提供的 30~50 张统一测试名片

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
    "website": "www.abc-tech.com",
    "address": "123 Tech Street, Silicon Valley, CA 94000"
  },
  "required_accuracy_fields": ["name", "company", "mobile", "email"]
}
```

- `ground_truth` 中字段值为 `null` 表示原图不存在该字段（用于验证 AI 不补全规则）
- 用 `required_accuracy_fields` 标记哪些字段必须 100% 正确，哪些允许模糊匹配
