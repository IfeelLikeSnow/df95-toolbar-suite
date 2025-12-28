"""
DF95 AIWorker UCS V1 – Python Example Worker

Dies ist ein Beispiel-Script, das das von REAPER/DF95 generierte Job-JSON
einliest und ein Result-JSON mit UCS-/DF95-Feldern schreibt.

Es implementiert KEINE echte Audio-Analyse – hier bist du frei, deine
eigenen Modelle (z.B. YAMNet, CLAP, PANNs, OpenL3, etc.) einzuhängen.

Aufruf:
    python df95_aiworker_ucsv1_example.py path/zum/job.json

Das Script erzeugt:
    Support/DF95_AIWorker/Results/DF95_AIWorker_UCSResult_<timestamp>.json

Job-Format (vereinfacht):
{
  "version": "DF95_AIWorker_UCS_V1",
  "audio_root": "/pfad/zum/ordner",
  "sampledb_hint": "/pfad/zur/DF95_SampleDB_Multi_UCS.json",
  "requested_tasks": [...],
  "files": [
    { "rel_path": "file1.wav", "full_path": "/absolut/file1.wav" },
    ...
  ]
}

Result-Format:
{
  "version": "DF95_AIWorker_UCS_V1",
  "job_source": "path/zum/job.json",
  "results": [
    {
      "full_path": "/absolut/file1.wav",
      "ucs_category": "FX",
      "ucs_subcategory": "Impacts",
      "ucs_descriptor": "Metal Heavy Slam",
      "ucs_perspective": "ST",
      "ucs_rec_medium": "MS",
      "ucs_channel_config": "ST",
      "df95_catid": "FX_IMPACT_METAL_HEAVY",
      "df95_drone_flag": "",
      "ai_tags": ["impact", "metal", "heavy"],
      "ai_model": "your_model_name_v1"
    },
    ...
  ]
}
"""

import json
import os
import sys
import datetime
from df95_aiworker_material_model import predict_for_file



def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(obj, path):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)


def main(job_path):
    job = load_json(job_path)
    audio_root = job.get("audio_root", "")
    files = job.get("files", [])
    worker_mode = (job.get("worker_mode") or "generic").lower()
    if worker_mode not in ("generic", "drone", "material"):
        worker_mode = "generic"

    results = []
    for entry in files:
        full = entry.get("full_path") or ""
        rel = entry.get("rel_path") or os.path.basename(full)

        if worker_mode == "drone":
            res = {
                "full_path": full,
                "ucs_category": "DRONE",
                "ucs_subcategory": "TEXTURE",
                "ucs_descriptor": "TBD",
                "ucs_perspective": "",
                "ucs_rec_medium": "",
                "ucs_channel_config": "",
                "df95_catid": "",
                "df95_drone_flag": "Y",
                "df95_drone_centerfreq": "MID",
                "df95_drone_density": "MED",
                "df95_drone_form": "PAD",
                "df95_drone_motion": "STATIC",
                "df95_motion_strength": "LOW",
                "df95_tension": "MED",
                "df95_material": "",
                "df95_instrument": "",
                "ai_tags": ["drone", "todo_ai"],
                "ai_model": "DF95_AIWorker_DroneDummy_v1",
            }
        elif worker_mode == "material":
            # Material-/Instrument-Mode: delegiere an df95_aiworker_material_model.predict_for_file
            predicted = predict_for_file(full)
            res = {
                "full_path": full,
                "ucs_category": predicted.get("ucs_category", "") or "",
                "ucs_subcategory": predicted.get("ucs_subcategory", "") or "",
                "ucs_descriptor": predicted.get("ucs_descriptor", "") or "",
                "ucs_perspective": predicted.get("ucs_perspective", "") or "",
                "ucs_rec_medium": predicted.get("ucs_rec_medium", "") or "",
                "ucs_channel_config": predicted.get("ucs_channel_config", "") or "",
                "df95_catid": predicted.get("df95_catid", "") or "",
                "df95_drone_flag": "",
                "df95_drone_centerfreq": "",
                "df95_drone_density": "",
                "df95_drone_form": "",
                "df95_drone_motion": "",
                "df95_motion_strength": "",
                "df95_tension": "",
                "df95_material": predicted.get("df95_material", "") or "",
                "df95_instrument": predicted.get("df95_instrument", "") or "",
                "ai_tags": predicted.get("ai_tags", []) or [],
                "ai_model": predicted.get("ai_model", "DF95_AIWorker_MaterialModel_v1") or "DF95_AIWorker_MaterialModel_v1",
                "ai_confidence": predicted.get("ai_confidence", 0.0),
            }
        else:
            res = {
                "full_path": full,
                "ucs_category": "FIELDREC",
                "ucs_subcategory": "ZOOMF6",
                "ucs_descriptor": "TBD",
                "ucs_perspective": "",
                "ucs_rec_medium": "",
                "ucs_channel_config": "",
                "df95_catid": "",
                "df95_drone_flag": "",
                "df95_drone_centerfreq": "",
                "df95_drone_density": "",
                "df95_drone_form": "",
                "df95_drone_motion": "",
                "df95_motion_strength": "",
                "df95_tension": "",
                "df95_material": "",
                "df95_instrument": "",
                "ai_tags": ["todo_ai"],
                "ai_model": "DF95_AIWorker_UCS_Dummy_v1",
            }

        results.append(res)

    root = os.path.join(os.path.dirname(os.path.dirname(job_path)), "Results")
    os.makedirs(root, exist_ok=True)
    ts = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    out_name = f"DF95_AIWorker_UCSResult_{ts}.json"
    out_path = os.path.join(root, out_name)

    out = {
        "version": "DF95_AIWorker_UCS_V1",
        "job_source": job_path,
        "created_utc": datetime.datetime.utcnow().isoformat() + "Z",
        "results": results,
    }

    save_json(out, out_path)
    print(f"[DF95 AIWorker UCS] Wrote result: {out_path}")



if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python df95_aiworker_ucsv1_example.py path/to/job.json")
        sys.exit(1)
    main(sys.argv[1])
