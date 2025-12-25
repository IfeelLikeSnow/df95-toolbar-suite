"""
DF95 AIWorker – Material Conflict Helper
========================================

Dieses Tool hilft dir, *Konflikte* zwischen existierenden Metadaten in deiner
DF95-SampleDB und neuen Material-Vorschlägen aus einem AIWorker-Result zu finden.

Typische Fragen:
    - "Wo schlägt das Modell METAL vor, obwohl in der DB bereits WOOD steht?"
    - "Wo würde der AIWorker neue df95_material-Werte setzen, wo bisher nichts eingetragen ist?"
    - "Welche Files hat das Result überhaupt abgedeckt / nicht abgedeckt?"

Es arbeitet komplett *offline* auf JSON-Dateien, unabhängig von REAPER.

Eingaben:
    1) SampleDB JSON (z.B. DF95_SampleDB_Multi_UCS.json)
    2) AIWorker-Result JSON (z.B. DF95_AIWorker_UCSResult_*.json aus dem Material-Mode)
    3) optional: Mindest-Confidence (z.B. 0.5)

Ausgaben:
    - Text-Report auf stdout:
        * Anzahl gematchter Items
        * Anzahl Konflikte (alt != neu)
        * Häufigste Konflikt-Paare (z.B. WOOD -> METAL)
    - CSV-Datei mit detaillierten Konflikten:
        * <ResultPath>_material_conflicts.csv

Usage:
    python df95_aiworker_material_conflict_helper.py \
        D:/.../DF95_SampleDB_Multi_UCS.json \
        D:/.../DF95_AIWorker_UCSResult_20251201_120000.json \
        0.6

"""

import os
import json
import csv
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional


@dataclass
class Conflict:
    full_path: str
    old_material: str
    new_material: str
    old_instrument: str
    new_instrument: str
    ai_confidence: float
    ai_model: str


def _norm_path(p: str) -> str:
    p = os.path.abspath(p)
    p = p.replace("\\", "/").replace("\\", "/").replace("\\", "/")
    return p.lower()


def load_sampledb(path: str) -> Dict[str, dict]:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    mapping: Dict[str, dict] = {}
    if isinstance(data, dict) and "items" in data:
        items = data.get("items") or []
    elif isinstance(data, list):
        items = data
    else:
        items = []

    for it in items:
        # Versuche verschiedene Felder, die einen Pfad enthalten könnten
        cand = it.get("full_path") or it.get("path") or it.get("file") or ""
        if not cand:
            continue
        key = _norm_path(cand)
        mapping[key] = it
    return mapping


def load_result(path: str) -> List[dict]:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    results = data.get("results") if isinstance(data, dict) else None
    if not isinstance(results, list):
        raise RuntimeError("Result-JSON hat kein erwartetes Feld 'results' (Liste).")
    return results


def analyze_conflicts(sampledb_path: str, result_path: str, min_conf: float = 0.5,
                    from_filter: str = "", to_filter: str = ""):
    db_map = load_sampledb(sampledb_path)
    results = load_result(result_path)

    total_results = len(results)
    matched = 0
    unmatched = 0
    conflicts: List[Conflict] = []
    proposed_new: List[Conflict] = []
    conflict_pairs: Dict[Tuple[str, str], int] = {}

    from_filter_l = (from_filter or "").strip().upper()
    to_filter_l = (to_filter or "").strip().upper()


    for res in results:
        full = res.get("full_path") or ""
        if not full:
            continue
        key = _norm_path(full)
        item = db_map.get(key)
        if not item:
            unmatched += 1
            continue

        matched += 1

        old_mat = (item.get("df95_material") or "").strip().upper()
        old_ins = (item.get("df95_instrument") or "").strip().upper()
        new_mat = (res.get("df95_material") or "").strip().upper()
        new_ins = (res.get("df95_instrument") or "").strip().upper()
        ai_conf = float(res.get("ai_confidence") or 0.0)
        ai_model = str(res.get("ai_model") or "")

        # Nur sinnvolle neuen Material-Vorschläge berücksichtigen
        if not new_mat and not new_ins:
            continue
        if ai_conf < min_conf:
            continue

        if not old_mat and not old_ins:
            # Bisher keine Material/Instrument-Infos -> "proposed new"
            proposed_new.append(Conflict(
                full_path=full,
                old_material=old_mat,
                new_material=new_mat,
                old_instrument=old_ins,
                new_instrument=new_ins,
                ai_confidence=ai_conf,
                ai_model=ai_model,
            ))
        else:
            # Potentieller Konflikt-Check
            mat_conflict = old_mat and new_mat and (old_mat != new_mat)
            ins_conflict = old_ins and new_ins and (old_ins != new_ins)

            if mat_conflict or ins_conflict:
                # Material-Filter anwenden (optional)
                if from_filter_l and (old_mat or "<EMPTY>") != from_filter_l:
                    continue
                if to_filter_l and (new_mat or "<EMPTY>") != to_filter_l:
                    continue

                conflicts.append(Conflict(
                    full_path=full,
                    old_material=old_mat,
                    new_material=new_mat,
                    old_instrument=old_ins,
                    new_instrument=new_ins,
                    ai_confidence=ai_conf,
                    ai_model=ai_model,
                ))
                key_pair = (old_mat or "<EMPTY>", new_mat or "<EMPTY>")
                conflict_pairs[key_pair] = conflict_pairs.get(key_pair, 0) + 1

    return {
        "total_results": total_results,
        "matched": matched,
        "unmatched": unmatched,
        "conflicts": conflicts,
        "proposed_new": proposed_new,
        "conflict_pairs": conflict_pairs,
    }


def write_conflicts_csv(result_path: str, conflicts: List[Conflict], proposed_new: List[Conflict]) -> str:
    base = os.path.splitext(result_path)[0]
    out_path = f"{base}_material_conflicts.csv"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([
            "type", "full_path",
            "old_material", "new_material",
            "old_instrument", "new_instrument",
            "ai_confidence", "ai_model",
        ])
        for c in conflicts:
            w.writerow([
                "conflict", c.full_path,
                c.old_material, c.new_material,
                c.old_instrument, c.new_instrument,
                f"{c.ai_confidence:.3f}", c.ai_model,
            ])
        for c in proposed_new:
            w.writerow([
                "proposed_new", c.full_path,
                c.old_material, c.new_material,
                c.old_instrument, c.new_instrument,
                f"{c.ai_confidence:.3f}", c.ai_model,
            ])

    return out_path



def write_summary_json(result_path: str, stats: dict, min_conf: float, from_filter: str = "", to_filter: str = "") -> str:
    """Schreibt eine kompakte JSON-Zusammenfassung der Konfliktanalyse.

    Enthält:
      - overall: total_results, matched, unmatched, num_conflicts, num_proposed_new, min_conf
      - filters: from_filter, to_filter
      - pairs: Liste von { "old": ..., "new": ..., "count": N }
    """
    base = os.path.splitext(result_path)[0]
    out_path = f"{base}_material_conflicts_summary.json"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    pairs = stats.get("conflict_pairs", {}) or {}
    pair_list = []
    for (old_mat, new_mat), count in pairs.items():
        pair_list.append({
            "old": old_mat,
            "new": new_mat,
            "count": int(count),
        })
    pair_list.sort(key=lambda x: x["count"], reverse=True)

    payload = {
        "overall": {
            "total_results": int(stats.get("total_results", 0)),
            "matched": int(stats.get("matched", 0)),
            "unmatched": int(stats.get("unmatched", 0)),
            "num_conflicts": len(stats.get("conflicts", []) or []),
            "num_proposed_new": len(stats.get("proposed_new", []) or []),
            "min_conf": float(min_conf),
        },
        "filters": {
            "from_material": from_filter or "",
            "to_material": to_filter or "",
        },
        "pairs": pair_list,
    }

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)

    return out_path


def print_report(sampledb_path: str, result_path: str, min_conf: float, stats: dict) -> None:
    print("============================================================")
    print(" DF95 AIWorker Material – Conflict Report")
    print("============================================================")
    print(f"SampleDB : {sampledb_path}")
    print(f"Result   : {result_path}")
    print(f"Min Conf : {min_conf:.2f}")
    print("")
    print(f"Total Results : {stats['total_results']}")
    print(f"Matched Items : {stats['matched']}")
    print(f"Unmatched     : {stats['unmatched']}")
    print("")
    print(f"Conflicts (Material/Instruments): {len(stats['conflicts'])}")
    print(f"Proposed new Material/Instr.    : {len(stats['proposed_new'])}")
    print("")
    if stats["conflict_pairs"]:
        print("Konflikt-Paare (old -> new):")
        pairs_sorted = sorted(stats["conflict_pairs"].items(), key=lambda kv: kv[1], reverse=True)
        for (old_mat, new_mat), count in pairs_sorted[:20]:
            print(f"  {old_mat:10s} -> {new_mat:10s} : {count}")
    else:
        print("Keine Material-Konflikte mit Min-Confidence-Filter gefunden.")
    print("============================================================")


def main():
    import sys
    if len(sys.argv) < 3:
        print("Usage: python df95_aiworker_material_conflict_helper.py <sampledb_json> <result_json> [min_confidence] [from_material] [to_material]")
        sys.exit(1)

    sampledb_path = sys.argv[1]
    result_path = sys.argv[2]
    if len(sys.argv) >= 4:
        try:
            min_conf = float(sys.argv[3])
        except ValueError:
            min_conf = 0.5
    else:
        min_conf = 0.5

    from_filter = sys.argv[4] if len(sys.argv) >= 5 else ""
    to_filter = sys.argv[5] if len(sys.argv) >= 6 else ""

    stats = analyze_conflicts(sampledb_path, result_path, min_conf=min_conf, from_filter=from_filter, to_filter=to_filter)
    csv_path = write_conflicts_csv(result_path, stats["conflicts"], stats["proposed_new"])
    summary_path = write_summary_json(result_path, stats, min_conf, from_filter, to_filter)
    print_report(sampledb_path, result_path, min_conf, stats)
    print(f"Details als CSV: {csv_path}")
    print(f"Summary  als JSON: {summary_path}")


if __name__ == "__main__":
    main()
