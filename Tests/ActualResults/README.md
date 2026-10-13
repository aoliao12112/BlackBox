# Actual OCR results

在 Mac 或 iPhone 完成每张测试名片的扫描后，将结构化结果保存为 `gt_001.json` 至 `gt_035.json`。

最小格式：

```json
{
  "actual": {
    "name": "王小明",
    "company": "上海智联科技有限公司",
    "mobile": "+86 138-0000-0001",
    "email": "wangxm@zhilian.example.cn"
  }
}
```

运行 `python Scripts/evaluate_accuracy.py`。命令只有在结果齐全、必测字段 100% 正确且缺失字段零臆造时返回成功。
