"""
DF95 AIWorker – Material Evaluation Helper
==========================================

Dieses Script hilft dir, ein trainiertes Material-Modell zu evaluieren.

Ziele:
    - Lade einen Checkpoint, der mit df95_aiworker_material_train_template.py
      erzeugt wurde.
    - Evaluiere ihn auf einem CSV-Datenset (gleiche Struktur wie beim Training).
    - Berechne:
        * Overall Accuracy
        * Per-Class Accuracy
        * Konfusionsmatrix (als Text)
    - Drucke ein kompaktes Reporting, das dir sagt:
        "Wie gut erkennt das Modell WOOD, METAL, DRUM, ...?"

Wichtig:
    - Dieses Script ist bewusst als *Offline-Tool* gedacht.
    - Es hat keinerlei Einfluss auf den laufenden REAPER/AIWorker – du kannst
      es eigenständig im Python-Umfeld ausführen.

Usage (Beispiel):
    python df95_aiworker_material_eval_helper.py path/to/test.csv path/to/checkpoints/material_ckpt.pt

"""

import os
import csv
from dataclasses import dataclass
from typing import List, Dict, Any

try:
    import torch
    import torchaudio
except ImportError:
    torch = None
    torchaudio = None

# Wir nutzen die gleichen Helfer wie das Training:
from df95_aiworker_material_train_template import (
    TrainSample,
    load_dataset_from_csv,
    LabelEncoder,
    TrainConfig,
    load_waveform,
    waveform_to_features,
    SimpleConvNet,
)


@dataclass
class EvalResult:
    overall_accuracy: float
    per_class_accuracy: Dict[str, float]
    confusion: Dict[str, Dict[str, int]]
    num_samples: int


def evaluate_material_model(csv_path: str, ckpt_path: str) -> EvalResult:
    if torch is None or torchaudio is None:
        raise RuntimeError("PyTorch/torchaudio sind nicht installiert – Evaluation nicht möglich.")

    if not os.path.isfile(ckpt_path):
        raise RuntimeError(f"Checkpoint nicht gefunden: {ckpt_path}")

    samples = load_dataset_from_csv(csv_path)
    if not samples:
        raise RuntimeError(f"Keine Samples in CSV: {csv_path}")

    # Material-Labels sammeln & Encoder bauen (wie beim Training)
    material_labels = [s.material for s in samples if s.material]
    if not material_labels:
        raise RuntimeError("Keine 'material'-Labels in CSV gefunden.")

    enc = LabelEncoder()
    enc.fit(material_labels)

    # Checkpoint laden
    ckpt = torch.load(ckpt_path, map_location="cpu")
    classes = ckpt.get("material_classes") or []
    cfg = ckpt.get("config") or {}
    sample_rate = cfg.get("sample_rate", 44100)
    mono = bool(cfg.get("mono", True))

    # Modell rekonstruieren
    num_classes = len(classes)
    if num_classes == 0:
        raise RuntimeError("Checkpoint enthält keine material_classes.")

    model = SimpleConvNet(num_classes=num_classes)
    state = ckpt.get("model_state")
    if state is None:
        raise RuntimeError("Checkpoint enthält keinen model_state.")
    model.load_state_dict(state)
    model.eval()

    if torch.cuda.is_available():
        device = "cuda"
        model.to(device)
    else:
        device = "cpu"

    # Confusion-Setup
    confusion: Dict[str, Dict[str, int]] = {}
    for c in classes:
        confusion[c] = {c2: 0 for c2 in classes}

    total = 0
    correct = 0

    # Evaluation (simple: Sample für Sample)
    for s in samples:
        true_label = s.material
        if true_label not in classes:
            # Sample hat Label, das im Checkpoint nicht existiert – überspringen
            continue

        try:
            wav, sr = torchaudio.load(s.audio_path)
        except Exception as e:
            print(f"[WARN] Konnte Audio nicht laden: {s.audio_path} ({e})")
            continue

        if mono and wav.shape[0] > 1:
            wav = wav.mean(dim=0, keepdim=True)
        if sr != sample_rate:
            wav = torchaudio.functional.resample(wav, sr, sample_rate)

        mel = torchaudio.transforms.MelSpectrogram(
            sample_rate=sample_rate,
            n_fft=2048,
            hop_length=512,
            n_mels=64,
        )(wav)
        db = torchaudio.transforms.AmplitudeToDB()(mel)
        x = db.unsqueeze(0)  # [1,1,M,T]

        x = x.to(device)
        with torch.no_grad():
            logits = model(x)
            probs = torch.softmax(logits, dim=1)
            _, idx = torch.max(probs, dim=1)
            idx = int(idx.item())

        if idx < 0 or idx >= len(classes):
            continue

        pred_label = classes[idx]

        total += 1
        if pred_label == true_label:
            correct += 1

        confusion[true_label][pred_label] += 1

    if total == 0:
        raise RuntimeError("Keine gültigen Samples für Evaluation – bitte CSV und Pfade prüfen.")

    overall_acc = correct / total

    # Per-Class Accuracy
    per_class_acc: Dict[str, float] = {}
    for c_true in classes:
        row = confusion[c_true]
        c_total = sum(row.values())
        if c_total > 0:
            c_correct = row.get(c_true, 0)
            per_class_acc[c_true] = c_correct / c_total
        else:
            per_class_acc[c_true] = 0.0

    return EvalResult(
        overall_accuracy=overall_acc,
        per_class_accuracy=per_class_acc,
        confusion=confusion,
        num_samples=total,
    )


def print_eval_report(res: EvalResult) -> None:
    print("============================================================")
    print(" DF95 AIWorker Material – Evaluation Report")
    print("============================================================")
    print(f"Samples (gültig): {res.num_samples}")
    print(f"Overall-Accuracy: {res.overall_accuracy*100:.2f}%")
    print("")
    print("Per-Class Accuracy:")
    for cls, acc in sorted(res.per_class_accuracy.items(), key=lambda x: x[0]):
        print(f"  {cls:12s}: {acc*100:5.2f}%")
    print("")
    print("Confusion Matrix (Counts):")
    classes = sorted(res.confusion.keys())
    header = "true\pred".ljust(12) + " " + " ".join(c[:6].rjust(7) for c in classes)
    print(header)
    for t in classes:
        row = res.confusion[t]
        line = t[:12].ljust(12) + " "
        for p in classes:
            line += f"{row.get(p,0):7d}"
        print(line)
    print("============================================================")


def main():
    import sys
    if len(sys.argv) < 3:
        print("Usage: python df95_aiworker_material_eval_helper.py <test_csv> <checkpoint.pt>")
        sys.exit(1)

    csv_path = sys.argv[1]
    ckpt_path = sys.argv[2]

    res = evaluate_material_model(csv_path, ckpt_path)
    print_eval_report(res)


if __name__ == "__main__":
    main()
