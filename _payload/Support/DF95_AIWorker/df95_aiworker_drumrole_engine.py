"""
DF95 AIWorker Drum-Role Engine (Full Model Mode Skeleton)
--------------------------------------------------------

Dies ist die "vollwertige" Drum-Role Engine für DF95:

- Lädt einen DF95_AIWorker_UCS_V1 Job (von der Fieldrec-Bridge in REAPER erzeugt)
- Lädt eine optionale Konfigurationsdatei:
    df95_aiworker_drumrole_config.json
- Wählt einen Backend-Modus:
    * "heuristic"  -> eingebaut, leichtgewichtig, pure Python (default)
    * "yamnet"     -> YAMNet-Backend (Audio-Embedding + Klassifikation)
    * "clap"       -> CLAP/AudioCLAP-Embedding + Klassifikation
    * "custom"     -> eigene Python-Logik (z.B. Torch/ONNX)

Ziel:
    Für jede Datei im Job ein Ergebnisobjekt zurückgeben mit mindestens:

        {
          "full_path": "...",
          "drum_role": "KICK" | "SNARE" | "HIHAT" | "TOM" | "PERC" | "FX" | "AMBIENCE" | "",
          "drum_confidence": 0.0–1.0
        }

Die DF95 Lua-Seite (ApplyToItems, BeatEngine) nutzt:
    - drum_role        -> direkte Nutzung als Rolle
    - drum_confidence  -> Gewichtung im Weighted Selector

WICHTIG:
    Dieses Skript enthält **nur das Gerüst** für YAMNet/CLAP – es bringt selbst
    KEINE großen Modelle mit. Du kannst aber sehr einfach:

    - die Funktionen `predict_role_yamnet()` / `predict_role_clap()` erweitern
    - dein eigenes Modell im "custom"-Backend einhängen.

"""

import json
import os
import sys
import math
from dataclasses import dataclass
from typing import Dict, Any, List, Optional, Tuple


# ------------------------------------------------------------
# Datentypen
# ------------------------------------------------------------

@dataclass
class DrumRoleResult:
    full_path: str
    drum_role: str
    drum_confidence: float


# ------------------------------------------------------------
# Config laden
# ------------------------------------------------------------

DEFAULT_CONFIG = {
    "backend": "heuristic",  # "heuristic" | "yamnet" | "clap" | "custom"
    "min_confidence": 0.25,
    "yamnet": {
        "label_map": {
            "Bass drum": "KICK",
            "Bass drum, musical": "KICK",
            "Snare drum": "SNARE",
            "Side stick": "SNARE",
            "Hi-hat": "HIHAT",
            "Ride cymbal": "RIDE",
            "Crash cymbal": "CRASH",
            "Tom-tom": "TOM",
            "Floor tom": "TOM",
            "Cymbal": "CRASH",
            "Gong": "CRASH",
            "Drum kit": "PERC",
        }
    },
    "clap": {
        "prompt_map": {
            "kick drum": "KICK",
            "snare drum": "SNARE",
            "hi-hat": "HIHAT",
            "tom drum": "TOM",
            "ride cymbal": "RIDE",
            "crash cymbal": "CRASH",
            "percussion": "PERC",
            "drum ambience": "AMBIENCE",
            "impact fx": "FX",
        }
    },
    "custom": {
        "module": "",
        "function": "",
    },
}


def load_config(config_path: str) -> Dict[str, Any]:
    if not os.path.isfile(config_path):
        return DEFAULT_CONFIG.copy()
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        return DEFAULT_CONFIG.copy()

    cfg = DEFAULT_CONFIG.copy()
    for k, v in data.items():
        if isinstance(v, dict) and isinstance(cfg.get(k), dict):
            cfg[k].update(v)
        else:
            cfg[k] = v
    return cfg


# ------------------------------------------------------------
# Job laden / schreiben
# ------------------------------------------------------------

def load_job(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def write_result(path: str, payload: Dict[str, Any]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


# ------------------------------------------------------------
# Backend: Heuristische Rolle (fallback, leichtgewichtig)
# ------------------------------------------------------------

def guess_drum_role_from_name(name: str) -> Tuple[str, float]:
    """Sehr einfache Fallback-Heuristik auf Basis des Dateinamens."""
    s = name.lower()
    # Kick
    if "kick" in s or " bd" in s or "bassdrum" in s or "_bd_" in s:
        return "KICK", 0.75
    # Snare
    if "snare" in s or " sd" in s or "snr" in s:
        return "SNARE", 0.75
    # HiHat
    if "hihat" in s or "hi-hat" in s or " hat" in s or " hh" in s:
        return "HIHAT", 0.7
    # Tom
    if "tom" in s or "tomh" in s or "tomm" in s or "toml" in s or "floor" in s:
        return "TOM", 0.7
    # Ride
    if "ride" in s:
        return "RIDE", 0.65
    # Crash
    if "crash" in s or "splash" in s or "china" in s:
        return "CRASH", 0.65
    # Ambience
    if "amb" in s or "room" in s or "atmo" in s or "reverb" in s:
        return "AMBIENCE", 0.6
    # FX
    if "fx" in s or "impact" in s or "hit" in s or "whoosh" in s or "rise" in s:
        return "FX", 0.6
    # Perc
    if "perc" in s or "clap" in s or "shaker" in s or "snap" in s:
        return "PERC", 0.6
    return "", 0.0


def classify_heuristic(full_path: str) -> DrumRoleResult:
    base = os.path.basename(full_path)
    role, conf = guess_drum_role_from_name(base)
    return DrumRoleResult(full_path=full_path, drum_role=role, drum_confidence=conf)


# ------------------------------------------------------------
# Backend: YAMNet (Skeleton)
# ------------------------------------------------------------

def predict_role_yamnet(full_path: str, cfg: Dict[str, Any]) -> DrumRoleResult:
    """
    Skeleton für YAMNet-Backend.

    Hier könntest du z.B.:
      - Audio laden (z.B. mit librosa)
      - YAMNet-Embedding benutzen (TensorFlow, tfhub)
      - wichtigste Labels extrahieren
      - über cfg["yamnet"]["label_map"] nach drum_role mappen.

    Da dieses Skript ohne externe Abhängigkeiten ausgeliefert wird,
    ist die folgende Implementierung nur ein Platzhalter, der auf
    die heuristische Variante zurückfällt.
    """
    # TODO: YAMNet-Modell einbinden (lokal in deinem Env)
    # Für jetzt: fallback auf heuristische Logik
    return classify_heuristic(full_path)


# ------------------------------------------------------------
# Backend: CLAP / AudioCLAP (Skeleton)
# ------------------------------------------------------------

def predict_role_clap(full_path: str, cfg: Dict[str, Any]) -> DrumRoleResult:
    """
    Skeleton für CLAP/AudioCLAP-Backend.

    Idee:
      - Audio einbetten (CLAP-Embedding)
      - Gegen eine Liste von Textprompts matchen (cfg["clap"]["prompt_map"])
      - bestes Matching als drum_role interpretieren.

    Hier ist nur ein Fallback eingebaut; ersetze diese Funktion
    mit deiner echten CLAP-Integration.
    """
    # TODO: CLAP-Modell integrieren
    return classify_heuristic(full_path)


# ------------------------------------------------------------
# Backend: Custom (dynamisch ladbar)
# ------------------------------------------------------------

def predict_role_custom(full_path: str, cfg: Dict[str, Any]) -> DrumRoleResult:
    """
    Lädt optional ein benutzerdefiniertes Python-Modul/Funktion, z.B.:

      custom: {
        "module": "my_drum_model",
        "function": "predict_role"
      }

    Erwarteter Funktions-Prototyp:

      def predict_role(path: str) -> Tuple[str, float]:
          ...

    Muss (role, confidence) zurückgeben.
    """
    module_name = (cfg.get("custom") or {}).get("module") or ""
    func_name = (cfg.get("custom") or {}).get("function") or ""

    if not module_name or not func_name:
        # Fallback
        return classify_heuristic(full_path)

    try:
        mod = __import__(module_name, fromlist=[func_name])
        fn = getattr(mod, func_name)
    except Exception:
        return classify_heuristic(full_path)

    try:
        role, conf = fn(full_path)
    except Exception:
        role, conf = "", 0.0

    if not isinstance(role, str):
        role = ""
    if not isinstance(conf, (int, float)):
        conf = 0.0

    return DrumRoleResult(full_path=full_path, drum_role=role, drum_confidence=float(conf))


# ------------------------------------------------------------
# Drum-Role Engine (Backend-Auswahl)
# ------------------------------------------------------------

def classify_file(full_path: str, backend: str, cfg: Dict[str, Any]) -> DrumRoleResult:
    backend = (backend or "heuristic").lower()
    if backend == "yamnet":
        return predict_role_yamnet(full_path, cfg)
    if backend == "clap":
        return predict_role_clap(full_path, cfg)
    if backend == "custom":
        return predict_role_custom(full_path, cfg)
    # Default
    return classify_heuristic(full_path)


def process_job(job: Dict[str, Any], cfg: Dict[str, Any]) -> Dict[str, Any]:
    files = job.get("files") or []
    audio_root = job.get("audio_root") or ""
    backend = cfg.get("backend", "heuristic")
    min_conf = float(cfg.get("min_confidence", 0.25))

    results: List[Dict[str, Any]] = []

    for entry in files:
        rel = entry.get("rel_path") or entry.get("path") or ""
        full = entry.get("full_path")
        if not full:
            full = os.path.join(audio_root, rel)
        full = os.path.abspath(full)

        res = classify_file(full, backend, cfg)

        # Min-Confidence-Filter (optional)
        if res.drum_confidence < min_conf:
            # Leere Role signalisieren „kein klares Drum“
            results.append(
                {
                    "full_path": full,
                    "drum_role": "",
                    "drum_confidence": float(res.drum_confidence),
                }
            )
        else:
            results.append(
                {
                    "full_path": full,
                    "drum_role": res.drum_role,
                    "drum_confidence": float(res.drum_confidence),
                }
            )

    return {
        "version": "DF95_AIWorker_DrumRole_V2",
        "backend": backend,
        "source_job": job.get("job_id") or job.get("created_utc"),
        "results": results,
    }


def main(argv: List[str]) -> None:
    if len(argv) < 3:
        print("usage: python df95_aiworker_drumrole_engine.py <job.json> <result.json> [config.json]")
        raise SystemExit(1)

    job_path = argv[1]
    out_path = argv[2]
    if len(argv) >= 4:
        cfg_path = argv[3]
    else:
        cfg_path = os.path.join(os.path.dirname(job_path), "df95_aiworker_drumrole_config.json")

    job = load_job(job_path)
    cfg = load_config(cfg_path)

    out = process_job(job, cfg)
    write_result(out_path, out)

    print(f"[DF95 DrumRoleEngine] backend={cfg.get('backend','heuristic')}  wrote: {out_path}")


if __name__ == "__main__":
    main(sys.argv)
