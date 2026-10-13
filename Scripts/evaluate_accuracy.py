"""Compare Mac/iPhone OCR exports with the repository Ground Truth files."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXPECTED = ROOT / "Tests" / "GroundTruth"
DEFAULT_ACTUAL = ROOT / "Tests" / "ActualResults"


def normalize(field: str, value):
    if value is None:
        return None
    if isinstance(value, list):
        return sorted(normalize(field, item) for item in value)
    text = str(value).strip().lower()
    if field in {"mobile", "officePhone", "fax"}:
        return re.sub(r"[^0-9+]", "", text)
    return re.sub(r"\s+", " ", text)


def evaluate(expected_dir: Path, actual_dir: Path) -> int:
    total = correct = hallucinations = missing_results = 0
    for expected_path in sorted(expected_dir.glob("gt_*.json")):
        expected_doc = json.loads(expected_path.read_text(encoding="utf-8"))
        actual_path = actual_dir / expected_path.name
        if not actual_path.exists():
            print(f"MISSING RESULT  {expected_path.stem}")
            missing_results += 1
            continue
        actual_doc = json.loads(actual_path.read_text(encoding="utf-8"))
        expected = expected_doc["ground_truth"]
        actual = actual_doc.get("actual", actual_doc.get("ground_truth", actual_doc))
        for field in expected_doc["required_accuracy_fields"]:
            total += 1
            wanted = normalize(field, expected.get(field))
            got = normalize(field, actual.get(field))
            if wanted == got:
                correct += 1
            else:
                print(f"MISMATCH        {expected_path.stem}.{field}: expected={wanted!r}, actual={got!r}")
        for field, wanted in expected.items():
            if wanted is None and normalize(field, actual.get(field)) not in (None, "", []):
                hallucinations += 1
                print(f"HALLUCINATION   {expected_path.stem}.{field}: {actual.get(field)!r}")

    accuracy = (correct / total * 100) if total else 0.0
    print(f"\nRequired fields: {correct}/{total} = {accuracy:.2f}%")
    print(f"Missing result files: {missing_results}")
    print(f"Hallucinated absent fields: {hallucinations}")
    return 0 if total and correct == total and hallucinations == 0 and missing_results == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected", type=Path, default=DEFAULT_EXPECTED)
    parser.add_argument("--actual", type=Path, default=DEFAULT_ACTUAL)
    args = parser.parse_args()
    return evaluate(args.expected, args.actual)


if __name__ == "__main__":
    raise SystemExit(main())
