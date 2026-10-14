"""Seed an installed iOS Simulator app container with deterministic demo cards."""

from __future__ import annotations

import json
import shutil
import sys
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GROUND_TRUTH = ROOT / "Tests" / "GroundTruth"
FIXED_NAMESPACE = uuid.UUID("ad2d207c-3afe-4f0f-8f0e-97939cfa40b8")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: seed_simulator_data.py <business_cards_directory>")
    destination = Path(sys.argv[1])
    destination.mkdir(parents=True, exist_ok=True)

    entries = []
    timestamp = "2026-10-14T08:00:00Z"
    tag_id = str(uuid.uuid5(FIXED_NAMESPACE, "课程演示")).upper()
    selected = ["gt_001", "gt_009", "gt_017", "gt_025"]
    for order, card_id in enumerate(selected):
        source = json.loads((GROUND_TRUTH / f"{card_id}.json").read_text(encoding="utf-8"))
        truth = source["ground_truth"]
        identifier = str(uuid.uuid5(FIXED_NAMESPACE, card_id)).upper()
        card_dir = destination / identifier
        card_dir.mkdir(parents=True, exist_ok=True)

        meta = {
            "id": identifier,
            **truth,
            "tags": [{"id": tag_id, "name": "课程演示", "colorHex": "3478F6"}],
            "notes": f"CI 模拟器测试数据 · {source['category']}",
            "createdAt": f"2026-10-14T08:0{order}:00Z",
            "updatedAt": timestamp,
            "ocrRawText": "\n".join(str(value) for value in truth.values() if value),
            "fieldConfidence": [],
        }
        (card_dir / "meta.json").write_text(
            json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        image = GROUND_TRUTH / source["image_file"]
        shutil.copy2(image, card_dir / "original.jpg")
        shutil.copy2(image, card_dir / "processed.jpg")
        entries.append({"id": identifier, "updatedAt": timestamp})

    (destination / "index.json").write_text(
        json.dumps({"entries": entries}, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Seeded {len(entries)} cards into {destination}")
    print(f"DETAIL_CARD_ID={entries[0]['id']}")


if __name__ == "__main__":
    main()
