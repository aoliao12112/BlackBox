#!/bin/bash
# 采集 T01–T20 验收截图证据。
# 依赖：已构建的 blackbox.app（Debug，含 DebugSupport 启动参数路由），模拟器已启动。
set -u

UDID=6FC204BD-EFEF-49DC-AEBC-CFB6F94BB3FE
BUNDLE=none.blackbox
ROOT=/Users/admin/Desktop/blackbox
GT="$ROOT/Tests/GroundTruth"
OUT="$ROOT/Tests/AcceptanceEvidence"

APP=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
DOC="$APP/Documents"
mkdir -p "$DOC" "$OUT"
rm -f "$OUT"/*.png

shot() { sleep "$2"; xcrun simctl io "$UDID" screenshot "$OUT/$1" >/dev/null 2>&1; echo "  -> $1"; }
launch() { xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1; sleep 1; xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null 2>&1; }

echo "[0] 拷贝取证样张到 App Documents"
cp "$GT/gt_001.jpg" "$DOC/evidence_ocr.jpg"
cp "$GT/gt_017.jpg" "$DOC/evidence_bilingual.jpg"
cp "$GT/gt_025.jpg" "$DOC/evidence_multiphone.jpg"
cp "$GT/gt_022.jpg" "$DOC/evidence_tilted.jpg"
cp "$GT/gt_033.jpg" "$DOC/evidence_missing.jpg"

echo "[1] T01 首次启动空状态"
launch --reset-cards
shot 01_T01_home_empty.png 4

echo "[2] 注入演示名片（4 张）"
python3 "$ROOT/Scripts/seed_simulator_data.py" "$DOC/business_cards" | tail -1

echo "[3] T02 进入扫描页"
launch --route scanner
shot 02_T02_scanner.png 4

echo "[4] T06 边界检测（倾斜样张）"
launch --route boundary --sample-image evidence_tilted.jpg
shot 03_T06_boundary.png 6

echo "[5] T07 OCR 原始文本"
launch --route ocr --sample-image evidence_ocr.jpg
shot 04_T07_ocr.png 7

echo "[6] T08 结构化字段（中英双语）"
launch --route correction --sample-image evidence_bilingual.jpg
shot 05_T08_correction.png 8

echo "[7] T09 缺失字段（无 Website）"
launch --route correction --sample-image evidence_missing.jpg
shot 06_T09_missing_field.png 8

echo "[8] T10 多电话区分"
launch --route correction --sample-image evidence_multiphone.jpg
shot 07_T10_multi_phone.png 8

echo "[9] T12 保存后列表 / T17 删除前列表"
launch
shot 08_T12_home_list.png 4

echo "[10] T13 名片详情"
launch --route detail --card-id 88FE9508-1E01-54DA-846E-DABD61712B8D
shot 09_T13_detail.png 4

echo "[11] T14 编辑名片"
launch --route edit --card-id 88FE9508-1E01-54DA-846E-DABD61712B8D
shot 10_T14_edit.png 5

echo "[12] T15 搜索"
launch --route search --search-keyword 王
shot 11_T15_search.png 4

echo "[13] T16 标签管理 / 标签筛选"
launch --route tagManager
shot 12_T16_tag_manager.png 4
launch --route tagFilter --tag-name 课程演示
shot 13_T16_tag_filter.png 4

echo "[14] T19 导出"
launch --route export --card-id 38B0E427-BFC4-5AFE-9C09-2418BF146803
shot 14_T19_export.png 5

echo "[15] T18 持久化（重启前后对比）"
launch
shot 15_T18_before_relaunch.png 4
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
sleep 2
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null 2>&1
shot 16_T18_after_relaunch.png 4

echo "[16] T03/T20 相机权限拒绝路径"
xcrun simctl privacy "$UDID" revoke camera "$BUNDLE" >/dev/null 2>&1
launch --route scanner
shot 17_T03_camera_denied.png 5
xcrun simctl privacy "$UDID" grant camera "$BUNDLE" >/dev/null 2>&1

echo "DONE"
ls -1 "$OUT"
