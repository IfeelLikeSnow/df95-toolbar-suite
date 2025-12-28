"""
DF95 AIWorker Drum-Role Engine (Example)
---------------------------------------

Dieses Python-Skript zeigt, wie ein externer AIWorker-Job für Drum-Rollen
aussehen kann. Es erwartet ein JSON-Job-File nach DF95_AIWorker_UCS_V1-Format,
z.B. erzeugt durch:

  * DF95_Fieldrec_AIWorker_Bridge_FromProject.lua

mit:

  worker_mode = "material"
  requested_tasks enthält "classify_drum_role"

Das Skript:

  * lädt das Job-JSON
  * iteriert über alle files[]
  * führt pro Datei eine einfache Heuristik aus (hier: nur Dateiname / UCS),
    in deiner Umgebung ersetzt du das durch dein Modell (z.B. YAMNet/CLAP/onnx)
  * schreibt ein Result-JSON mit:

      {
        "results": [
          {
            "full_path": "...",
            "drum_role": "KICK" | "SNARE" | "HIHAT" | "TOM" | "PERC" | "FX" | "AMBIENCE",
            "drum_confidence": 0.0–1.0,
            ... (weitere Felder erlaubt)
          },
          ...
        ]
      }

Das Result-JSON wird von:

  * DF95_Fieldrec_AIWorker_ApplyToItems.lua

ausgewertet:
  - drum_role → direkt auf Items geschrieben (Notes, Farben, Take-Namen)
  - falls drum_role fehlt, wird lokal eine Heuristik genutzt.
"""

import json
import os
import sys
import math
from typing import Dict, Any, List


def load_job(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def guess_drum_role_from_name(name: str) -> str:
    """Sehr einfache Beispiel-Heuristik – bitte ersetzen durch dein Modell."""
    s = name.lower()
    if "kick" in s or " bd" in s or "bassdrum" in s:
        return "KICK"
    if "snare" in s or " sd" in s or "snr" in s:
        return "SNARE"
    if "hihat" in s or "hi-hat" in s or " hat" in s or " hh" in s:
        return "HIHAT"
    if "tom" in s or "tomh" in s or "tomm" in s or "toml" in s or "floor" in s:
        return "TOM"
    if "ride" in s:
        return "RIDE"
    if "crash" in s or "splash" in s or "china" in s:
        return "CRASH"
    if "amb" in s or "room" in s or "atmo" in s or "reverb" in s:
        return "AMBIENCE"
    if "fx" in s or "impact" in s or "hit" in s or "whoosh" in s or "rise" in s:
        return "FX"
    if "perc" in s or "clap" in s or "shaker" in s or "snap" in s:
        return "PERC"
    return ""


def process_job(job: Dict[str, Any]) -> Dict[str, Any]:
    files = job.get("files") or []
    audio_root = job.get("audio_root") or ""
    results: List[Dict[str, Any]] = []

    for entry in files:
        rel = entry.get("rel_path") or entry.get("path") or ""
        full = entry.get("full_path")
        if not full:
            full = os.path.join(audio_root, rel)
        base = os.path.basename(full)

        role = guess_drum_role_from_name(base)
        if role:
            conf = 0.75
        else:
            conf = 0.0

        results.append(
            {
                "full_path": full,
                "drum_role": role if role else None,
                "drum_confidence": conf,
            }
        )

    return {
        "version": "DF95_AIWorker_DrumRole_V1",
        "source_job": job.get("job_id") or job.get("created_utc"),
        "results": results,
    }


def main(argv: List[str]) -> None:
    if len(argv) < 3:
        print("usage: python df95_aiworker_drumrole_example.py <job.json> <result.json>")
        raise SystemExit(1)

    job_path = argv[1]
    out_path = argv[2]

    job = load_job(job_path)
    out = process_job(job)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)

    print(f"Wrote drum-role result to {out_path}")


if __name__ == "__main__":
    main(sys.argv)
