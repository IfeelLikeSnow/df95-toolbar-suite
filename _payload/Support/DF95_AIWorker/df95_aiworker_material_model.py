"""
DF95 AIWorker – Material / Instrument Model Helper

Dieses Modul kapselt die eigentliche "Intelligenz" für den Material-Mode.
Hier kannst du später ein echtes ML-Modell (CLAP, PANNs, YAMNet, etc.)
einbauen, ohne das Worker-Script noch einmal anfassen zu müssen.

Die zentrale Funktion ist:

    predict_for_file(path: str) -> dict

Sie liefert ein Dictionary mit allen Feldern, die der DF95-AIWorker
bei worker_mode == "material" erwartet (oder optional versteht).
"""

from __future__ import annotations
import os
from typing import Dict, List, Optional

# Optional: echtes Modell-Backend (PyTorch + torchaudio)
try:
    import torch
    import torchaudio
except ImportError:
    torch = None
    torchaudio = None

# Standard-Pfad für den Material-Checkpoint (kannst du anpassen)
_DEFAULT_CKPT_PATH = os.path.join(os.path.dirname(__file__), "checkpoints", "material_ckpt.pt")

_MATERIAL_MODEL = None
_MATERIAL_CLASSES = None
_MODEL_CFG = {
    "sample_rate": 44100,
    "mono": True,
}




def _load_material_model():
    """Lädt (falls vorhanden) ein trainiertes Material-Modell.

    Erwartet einen Checkpoint, der mit df95_aiworker_material_train_template.py
    erzeugt wurde und folgende Keys enthält:

        - "model_state"
        - "material_classes"
        - "config" mit "sample_rate", "mono"

    Wenn nichts geladen werden kann (kein torch/torchaudio oder kein Checkpoint),
    bleibt _MATERIAL_MODEL = None und das System fällt auf Heuristiken zurück.
    """
    global _MATERIAL_MODEL, _MATERIAL_CLASSES, _MODEL_CFG

    if _MATERIAL_MODEL is not None:
        return

    if torch is None or torchaudio is None:
        # Kein ML-Backend verfügbar
        return

    ckpt_path = _DEFAULT_CKPT_PATH
    if not os.path.isfile(ckpt_path):
        # Kein Checkpoint vorhanden
        return

    try:
        ckpt = torch.load(ckpt_path, map_location="cpu")
    except Exception as e:
        print(f"[DF95 AIWorker Material] Konnte Checkpoint nicht laden: {e}")
        return

    material_classes = ckpt.get("material_classes") or []
    cfg = ckpt.get("config") or {}
    _MODEL_CFG.update(cfg)

    # Import der SimpleConvNet-Architektur aus dem Training-Template
    try:
        from df95_aiworker_material_train_template import SimpleConvNet
    except ImportError as e:
        print(f"[DF95 AIWorker Material] Konnte SimpleConvNet nicht importieren: {e}")
        return

    num_classes = len(material_classes)
    if num_classes == 0:
        print("[DF95 AIWorker Material] Checkpoint hat keine Klassen – Abbruch.")
        return

    model = SimpleConvNet(num_classes=num_classes)
    state_dict = ckpt.get("model_state")
    if state_dict is None:
        print("[DF95 AIWorker Material] Checkpoint ohne model_state – Abbruch.")
        return

    try:
        model.load_state_dict(state_dict)
        model.eval()
    except Exception as e:
        print(f"[DF95 AIWorker Material] Konnte model_state nicht laden: {e}")
        return

    _MATERIAL_MODEL = model
    _MATERIAL_CLASSES = material_classes
    print(f"[DF95 AIWorker Material] Modell geladen mit {len(material_classes)} Klassen aus {ckpt_path}.")


def _infer_material_with_model(path: str):
    """Versucht, das trainierte Modell auf eine Datei anzuwenden.

    Gibt (material_label, confidence) zurück oder (None, 0.0), wenn
    kein Modell verfügbar ist oder etwas schiefgeht.
    """
    if torch is None or torchaudio is None:
        return None, 0.0

    _load_material_model()
    if _MATERIAL_MODEL is None or _MATERIAL_CLASSES is None:
        return None, 0.0

    # Audio laden
    try:
        wav, sr = torchaudio.load(path)
    except Exception as e:
        print(f"[DF95 AIWorker Material] Konnte Audio nicht laden: {path} ({e})")
        return None, 0.0

    sr_target = _MODEL_CFG.get("sample_rate", 44100)
    mono = bool(_MODEL_CFG.get("mono", True))

    if mono and wav.shape[0] > 1:
        wav = wav.mean(dim=0, keepdim=True)
    if sr != sr_target:
        wav = torchaudio.functional.resample(wav, sr, sr_target)

    # Feature-Extraktion (Mel-Spec + dB) – analog zum Training-Template
    mel = torchaudio.transforms.MelSpectrogram(
        sample_rate=sr_target,
        n_fft=2048,
        hop_length=512,
        n_mels=64,
    )(wav)
    db = torchaudio.transforms.AmplitudeToDB()(mel)  # [1, M, T]

    x = db.unsqueeze(0)  # [1, 1, M, T]
    with torch.no_grad():
        logits = _MATERIAL_MODEL(x)
        probs = torch.softmax(logits, dim=1)
        conf, idx = torch.max(probs, dim=1)
        idx = int(idx.item())
        conf = float(conf.item())

    if idx < 0 or idx >= len(_MATERIAL_CLASSES):
        return None, 0.0

    label = _MATERIAL_CLASSES[idx]
    return label, conf

def _guess_material_from_filename(name: str) -> Optional[str]:
    n = name.lower()
    if any(k in n for k in ["wood", "holz", "branch", "stick"]):
        return "WOOD"
    if any(k in n for k in ["metal", "metall", "iron", "steel", "clang"]):
        return "METAL"
    if any(k in n for k in ["glass", "glas", "bottle", "shard"]):
        return "GLASS"
    if any(k in n for k in ["water", "rain", "river", "wave"]):
        return "WATER"
    if any(k in n for k in ["stone", "rock", "gravel"]):
        return "STONE"
    if any(k in n for k in ["drum", "snare", "kick", "tom", "hihat", "hi-hat", "cymbal", "ride", "crash"]):
        return "DRUM"
    return None


def _guess_instrument_from_filename(name: str) -> Optional[str]:
    n = name.lower()
    if "snare" in n:
        return "SNARE"
    if "kick" in n or "bd_" in n or "bassdrum" in n:
        return "KICK"
    if "tom" in n:
        return "TOM"
    if "hihat" in n or "hi-hat" in n or "hat_" in n:
        return "HIHAT"
    if "cymbal" in n or "ride" in n or "crash" in n:
        return "CYMBAL"
    if "bell" in n:
        return "BELL"
    return None


def predict_for_file(path: str) -> Dict:
    """
    Haupteinstieg für den DF95-AIWorker im Material-Mode.

    Ablauf:
      1) Versuche, ein trainiertes Material-Modell zu verwenden
         (Checkpoint unter _DEFAULT_CKPT_PATH).
      2) Wenn kein Modell verfügbar oder Inferenz fehlschlägt,
         nutze Heuristiken auf Basis des Dateinamens.

    :param path: voller Dateipfad zur Audiodatei
    :return: Dict mit Feldern wie:
        - ucs_category
        - ucs_subcategory
        - ucs_descriptor
        - df95_material
        - df95_instrument
        - ai_tags (Liste)
        - ai_model (Name des verwendeten Modells)
        - ai_confidence (optional: 0.0–1.0)
    """

    base = os.path.basename(path)
    name, _ = os.path.splitext(base)

    # 1) Versuche ML-Modell
    material_ml = None
    ml_conf = 0.0
    if torch is not None and torchaudio is not None:
        try:
            material_ml, ml_conf = _infer_material_with_model(path)
        except Exception as e:
            print(f"[DF95 AIWorker Material] Modell-Inferenz fehlgeschlagen, fallback auf Heuristik: {e}")
            material_ml, ml_conf = None, 0.0

    # 2) Heuristik
    material_heur = _guess_material_from_filename(name)
    instrument = _guess_instrument_from_filename(name)

    # Material-Auswahl: Modell hat Vorrang, wenn es etwas Sinnvolles liefert
    material = material_ml or material_heur

    # UCS-Kategorie vorschlagen
    if instrument or material == "DRUM":
        ucs_category = "DRUM"
        ucs_subcategory = instrument or "DRUM"
    elif material in ("WOOD", "METAL", "GLASS", "STONE", "WATER"):
        ucs_category = "FOLEY"
        ucs_subcategory = material
    else:
        ucs_category = "FX"
        ucs_subcategory = "MISC"

    # Descriptor grob aus Material/Instrument ableiten
    if instrument:
        descriptor = instrument
    elif material:
        descriptor = material
    else:
        descriptor = "TBD"

    tags: List[str] = []
    if material:
        tags.append(material.lower())
    if instrument:
        tags.append(instrument.lower())
    if not tags:
        tags.append("todo_ai")

    # Modellname / Confidence
    if material_ml:
        ai_model = "DF95_AIWorker_MaterialModel_v1"
        ai_conf = ml_conf
    else:
        ai_model = "DF95_AIWorker_MaterialHeuristic_v1"
        ai_conf = 0.4 if material_heur or instrument else 0.1

    result = {
        "ucs_category": ucs_category,
        "ucs_subcategory": ucs_subcategory,
        "ucs_descriptor": descriptor,
        "ucs_perspective": "",
        "ucs_rec_medium": "",
        "ucs_channel_config": "",
        "df95_catid": "",
        "df95_material": material or "",
        "df95_instrument": instrument or "",
        "ai_tags": tags,
        "ai_model": ai_model,
        "ai_confidence": ai_conf,
    }

    return result
