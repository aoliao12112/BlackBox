#!/bin/bash
# 录制《BlackBox 端到端演示》视频：用 simctl 录屏 + App 的 --demo 自动演示模式。
# 前置：App 已构建并安装；App Documents 内已放好 evidence_*.jpg 样张；名片夹已有演示数据。
set -u

UDID=${UDID:-6FC204BD-EFEF-49DC-AEBC-CFB6F94BB3FE}
BUNDLE=${BUNDLE:-none.blackbox}
ROOT=/Users/admin/Desktop/blackbox
OUT="$ROOT/BlackBox-演示录屏.mp4"

xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
sleep 1
rm -f "$OUT"

echo "[1] 开始录屏"
xcrun simctl io "$UDID" recordVideo --codec h264 "$OUT" &
REC=$!
sleep 3

echo "[2] 启动 App（--demo 自动演示）"
xcrun simctl launch "$UDID" "$BUNDLE" --demo >/dev/null 2>&1

echo "[3] 录制中（约 62s）"
sleep 62

echo "[4] 停止录屏并封盘"
kill -INT "$REC" 2>/dev/null
wait "$REC" 2>/dev/null
sleep 2

if [ -f "$OUT" ]; then
  echo "DONE $(du -h "$OUT" | cut -f1)  $OUT"
else
  echo "FAILED: 未生成视频"
  exit 1
fi
