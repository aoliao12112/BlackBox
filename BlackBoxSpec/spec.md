# BlackBox — 名片全能王功能切片 100% 黑盒复刻

> **Week 1 产出 · Specification v1.0**
> 黑盒观察 → 规格定义 → Architecture → Implementation → Test → Difference Analysis → Revision → Regression

---

## 0. 参考环境锁定

| 项目 | 值 |
|------|-----|
| 参考 App | CamCard（名片全能王） |
| 锁定版本 | *待教师确认* |
| iOS 版本 | *待教师确认* |
| 测试设备 | iPhone / Simulator（*待教师确认规格*） |
| App 语言 | 中文简体 |
| 登录状态 | 未登录（免费功能模式） |
| 测试名片集 | 教师统一提供 30~50 张 |

---

## 1. 页面清单（Page Inventory）

| ID | 页面 | 职责 | 导航入口 |
|----|------|------|----------|
| P1 | **名片夹首页** (HomeView) | 名片列表、空状态、扫描入口、搜索入口 | Tab Bar / 启动页 |
| P2 | **扫描页** (ScannerView) | 相机预览、拍摄、从相册导入 | 名片夹首页右上角按钮、空状态页按钮 |
| P3 | **名片检测页** (CardBoundaryView) | 自动检测名片边界、透视/方向校正、手动调整 | 拍摄 / 导入成功后自动进入 |
| P4 | **OCR 结果页** (OCRResultView) | 显示 OCR Raw Text + 识别到的名片图 | 校正完成后自动进入 |
| P5 | **字段校正页** (FieldCorrectionView) | 结构化字段展示 + 人工修改 + 置信标注 | OCR 结果页 "继续" 按钮 |
| P6 | **名片详情页** (CardDetailView) | 完整名片信息、查看原图、编辑、删除、导出 | 名片夹列表点击 |
| P7 | **名片编辑页** (CardEditView) | 修改名片字段 | 详情页 "编辑" 按钮 |
| P8 | **搜索页** (SearchView) | 按姓名/公司/职位/电话/Email 搜索 | 名片夹首页搜索入口 |
| P9 | **标签管理页** (TagManagerView) | 创建标签、给名片加标签、按标签筛选、删除标签 | 名片夹首页 Tab / 详情页 |
| P10 | **导出确认页** (ExportView) | 保存到系统联系人 / 导出 VCF | 详情页 "导出" 按钮 |

---

## 2. 状态转换清单（State Inventory）

### 2.1 应用生命周期状态

```
┌─────────────┐     首次启动      ┌──────────────────────┐
│  未初始化    │ ──────────────→  │  已初始化 (空名片夹)    │
└─────────────┘                   └──────────────────────┘
                                         │
                                    扫描/导入名片
                                         │
                                         ▼
                                    ┌──────────────────┐
                                    │  名片夹 (有数据)    │
                                    └──────────────────┘
                                         │
                                        删光
                                         │
                                         ▼
                                    ┌──────────────────┐
                                    │  已初始化 (空)      │
                                    └──────────────────┘
```

### 2.2 扫描流程状态机

```
┌──────────┐     进入扫描      ┌──────────────┐
│ 名片夹首页 │ ──────────────→ │ S1 相机预览中  │
└──────────┘                  └──────────────┘
                                 │           │
                          点击拍摄        相册导入
                                 │           │
                                 ▼           ▼
                          ┌────────────────────┐
                          │ S2 拍摄/导入成功     │
                          └────────────────────┘
                                     │
                                     ▼
                          ┌────────────────────┐
                          │ S3 名片边界检测中     │
                          └────────────────────┘
                                     │
                          ┌──────────┴──────────┐
                          ▼                     ▼
                   ┌────────────┐          ┌────────────┐
                   │ S4 边界    │          │ S4 边界    │
                   │ 已识别     │          │ 未识别     │
                   └────────────┘          └────────────┘
                          │                     │
                     确认/手动              手动调整/重拍
                          │                     │
                          ▼                     ▼
                   ┌────────────────────────────┐
                   │ S5 图像校正完成（裁剪+透视）  │
                   └────────────────────────────┘
                                     │
                                     ▼
                          ┌────────────────────┐
                          │ S6 OCR 识别中        │
                          └────────────────────┘
                                     │
                          ┌──────────┴──────────┐
                          ▼                     ▼
                   ┌────────────┐          ┌────────────┐
                   │ S7 OCR     │          │ S7 OCR     │
                   │ 成功       │          │ 失败       │
                   └────────────┘          └────────────┘
                          │                     │
                    进入字段解析             返回重拍/取消
                          │
                          ▼
                   ┌────────────────────┐
                   │ S8 字段解析完成      │
                   │ （可能有置信度标记）  │
                   └────────────────────┘
                          │
                     人工校正/确认
                          │
                          ▼
                   ┌────────────────────┐
                   │ S9 保存成功         │
                   └────────────────────┘
                          │
                          ▼
                   ┌────────────────────┐
                   │ 返回名片夹（已更新） │
                   └────────────────────┘
```

### 2.3 异常状态

| 状态 | 触发条件 | 系统行为 |
|------|----------|----------|
| E1 相机权限拒绝 | 用户在系统弹窗选了"不允许" | 显示权限引导页 + 跳转设置 |
| E2 相册权限拒绝 | 用户拒绝相册访问 | 显示权限引导页 |
| E3 无法检测到名片边界 | 背景复杂/名片太小 | 提示"请将名片置于清晰背景" + 允许手动调整 |
| E4 OCR 完全失败 | 图像模糊/光线极暗 | 提示"未能识别文字，请重拍" |
| E5 字段全空 | OCR 无结果 | 进入空的校正页，允许手动输入 |
| E6 取消保存 | 在校正/详情页取消 | 返回上一页，不保存 |
| E7 数据持久化失败 | 磁盘满等 | 提示保存失败 + 保留在编辑态 |

---

## 3. 端到端业务流程

```
名片夹 / Home                           # P1
    │
    ├─ [扫描名片按钮] ──→ ScannerView       # P2
    │                          │
    │                    点击拍摄 / 导入
    │                          │
    │                          ▼
    │                    CardBoundaryView   # P3 边界检测 + 校正
    │                          │
    │                     确认/手动调整
    │                          │
    │                          ▼
    │                    OCRResultView       # P4 原始 OCR 结果
    │                          │
    │                     继续 → 字段解析
    │                          │
    │                          ▼
    │                    FieldCorrectionView # P5 人工校正
    │                          │
    │                          ▼
    │                     保存到本地
    │                          │
    │                          ▼
    │                    返回 HomeView（列表已更新）
    │
    ├─ [点击名片] ──→ CardDetailView        # P6 详情
    │                      │
    │                 编辑 → CardEditView     # P7
    │                 删除 → 确认弹窗 → 从列表移除
    │                 导出 → ExportView      # P10
    │
    ├─ [搜索入口] ──→ SearchView            # P8
    │
    └─ [标签入口] ──→ TagManagerView        # P9
```

---

## 4. BusinessCard Schema

### 4.1 数据模型定义（Swift）

```swift
// 名片数据模型
struct BusinessCard: Identifiable, Codable, Hashable {
    var id: UUID                    // 唯一标识
    var originalImageData: Data?    // 原始拍摄图片（压缩存储）
    var processedImageData: Data?   // 经边界检测+校正后的图片
    
    // 结构化联系字段
    var name: String?               // 姓名
    var company: String?            // 公司
    var jobTitle: String?           // 职位
    var department: String?         // 部门（可选）
    var mobile: String?             // 手机号码
    var officePhone: String?        // 办公电话
    var fax: String?                // 传真（可选）
    var email: String?              // 电子邮箱
    var website: String?            // 网址
    var address: String?            // 地址
    var postalCode: String?         // 邮编（可选）
    
    // 管理字段
    var tags: [Tag]                 // 标签列表
    var notes: String?              // 备注
    var createdAt: Date             // 创建时间
    var updatedAt: Date?            // 最后更新时间
    
    // AI/OCR 溯源（用于分析）
    var ocrRawText: String?         // OCR 原始文本
    var fieldConfidence: [FieldConfidence]?  // 各字段置信度
}

// 标签
struct Tag: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String?
}

// 字段置信度（用于 AI 输出概率性分析）
struct FieldConfidence: Codable {
    let fieldName: String           // 如 "name", "company"
    let rawValue: String            // AI 解析原始值
    let confidence: Double          // 0.0 ~ 1.0
    let source: String              // "OCR" / "LLM" / "Manual"
}
```

### 4.2 Schema 约束

| 约束 | 规则 |
|------|------|
| 字段允许 nil | 所有联系字段（name/company/phone 等）均可为 nil。**AI 不允许补全原图不存在的信息** |
| ID 唯一性 | UUID 全局唯一 |
| 图片压缩 | 存储前压缩至 JPEG 最大 1024px，quality = 0.7 |
| tags 关联 | 可多张名片共享同一个 Tag（同 id），删除 Tag 时从所有名片中移除 |
| 搜索范围 | 搜索匹配 name / company / jobTitle / mobile / email |

### 4.3 持久化层

```
存储位置：Documents/business_cards/
├── index.json                    # 名片列表索引（ID + 更新时间）
├── <card_id>/
│   ├── meta.json                 # BusinessCard JSON
│   ├── original.jpg              # 原图
│   └── processed.jpg             # 校正后图
```

---

## 5. 技术架构（MVVM + Protocol-oriented）

```
┌─────────────────────────────────────────────────────┐
│                       Views                         │
│  HomeView / ScannerView / FieldCorrectionView ...   │
└──────────────────────┬──────────────────────────────┘
                       ├── ViewModels
                       │   HomeViewModel
                       │   ScannerViewModel
                       │   FieldCorrectionViewModel
                       │   CardDetailViewModel
                       │
                       ├── Services (Protocols)
                       │   OCRService              ← Week 3 实现
                       │   CardBoundaryService      ← Week 3 实现
                       │   FieldExtractorService    ← Week 4 实现
                       │   ImagePreprocessor        ← Week 3 实现
                       │
                       ├── Repositories
                       │   BusinessCardRepository   ← Week 2 实现
                       │   TagRepository            ← Week 5 实现
                       │
                       └── Models
                           BusinessCard / Tag / ...
```

---

## 6. Week 1 交付清单

- [x] spec.md（本文件）
- [x] BusinessCard Schema 定义
- [x] 页面清单（P1~P10）
- [x] 状态转换图（扫描流程 + 异常状态）
- [ ] Reference Test Suite（→ reference_test_suite.md）
- [ ] Ground Truth 测试数据集（→ Tests/GroundTruth/*.json，30 张）
- [ ] 项目骨架代码（Models/Services 占位 Protocol）

---

*Document Version: 1.0 · Week 1 · 2026-10-13*
