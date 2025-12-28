"""
DF95 AIWorker – Material / Instrument Training Template
=======================================================

Dieses Script ist ein *Template*, um ein eigenes Material-/Instrument-Modell
für den DF95-AIWorker zu trainieren.

Ziel:
    - Du kannst ein Modell trainieren (z.B. mit PyTorch + torchaudio),
      das WAV-Dateien auf Material/Instrumente usw. klassifiziert.
    - Die Vorhersagen werden später in df95_aiworker_material_model.predict_for_file()
      verwendet.

Wichtige Punkte:
    - Dieses Template ist bewusst "low-level" gehalten und enthält keine
      fertige ML-Architektur, aber alle Hooks, um eine zu integrieren.
    - Du entscheidest, welches Backend du nutzt (PyTorch, TensorFlow, JAX, Sklearn...).

Empfohlene Datenstruktur
------------------------

Wir empfehlen für Trainingsdaten eine CSV mit folgenden Spalten:

    audio_path,material,instrument,ucs_category,ucs_subcategory,extra_tags

Beispiel:

    D:/Audio/Train/wood_hit_001.wav,WOOD,,FOLEY,WOOD,"impact;hit"
    D:/Audio/Train/snare_rim_01.wav,DRUM,SNARE,DRUM,SNARE,"rimshot;tight"

oder alternativ ein Ordner-basiertes Layout:

    dataset_root/
        material/
            WOOD/
                file1.wav
                file2.wav
            METAL/
                ...
        instruments/
            SNARE/
            KICK/
            ...

Dieses Template nutzt im Default eine CSV-Datei.

Integration in den AIWorker
---------------------------

Nach dem Training soll dein Modell in

    Support/DF95_AIWorker/df95_aiworker_material_model.py

verwendet werden, indem dort in `predict_for_file()` das
trainierte Modell geladen und auf die gegebene Datei angewandt wird.

D.h.:

    - Trainiertes Modell speichern (z.B. als .pt/.pth Checkpoint)
    - In df95_aiworker_material_model.py:
        - globales Model laden
        - Audio laden + preprocessen
        - Vorhersage
        - Mapping von Klassen -> df95_material, df95_instrument, ucs_category, ...

Dieses Template kümmert sich nur um das *Trainieren* und *Speichern*,
nicht um das Live-Laden im Worker.

"""

import os
import csv
from dataclasses import dataclass
from typing import List, Optional, Dict, Any

# Optional: wenn du PyTorch, torchaudio, librosa o.ä. nutzen möchtest,
# kannst du die Imports aktivieren und in `FEATURE_BACKEND` festlegen.
try:
    import torch
    import torchaudio
except ImportError:
    torch = None
    torchaudio = None


# --------------------------------------------------------------------
# Konfiguration
# --------------------------------------------------------------------

@dataclass
class TrainConfig:
    csv_path: str          # Pfad zur Trainings-CSV
    checkpoint_out: str    # Pfad zur Model-Checkpoint-Datei
    sample_rate: int = 44100
    mono: bool = True
    num_epochs: int = 10
    batch_size: int = 16
    learning_rate: float = 1e-3
    device: str = "cuda" if torch and torch.cuda.is_available() else "cpu"


# Wähle hier, welchen Backend-Typ du später implementieren möchtest:
FEATURE_BACKEND = "torchaudio"  # oder "librosa", "numpy", etc.


# --------------------------------------------------------------------
# Datenstruktur für ein Trainingssample
# --------------------------------------------------------------------

@dataclass
class TrainSample:
    audio_path: str
    material: str
    instrument: str
    ucs_category: str
    ucs_subcategory: str
    extra_tags: List[str]


def load_dataset_from_csv(csv_path: str) -> List[TrainSample]:
    samples: List[TrainSample] = []
    with open(csv_path, "r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            path = row.get("audio_path") or ""
            if not path:
                continue
            material = (row.get("material") or "").strip().upper()
            instrument = (row.get("instrument") or "").strip().upper()
            ucs_category = (row.get("ucs_category") or "").strip().upper()
            ucs_subcategory = (row.get("ucs_subcategory") or "").strip().upper()
            extra = (row.get("extra_tags") or "").strip()
            tags = [t.strip() for t in extra.split(";") if t.strip()]
            samples.append(TrainSample(
                audio_path=path,
                material=material,
                instrument=instrument,
                ucs_category=ucs_category,
                ucs_subcategory=ucs_subcategory,
                extra_tags=tags,
            ))
    return samples


# --------------------------------------------------------------------
# Encoding der Label (Material / Instrument / UCS)
# --------------------------------------------------------------------

class LabelEncoder:
    def __init__(self):
        self.classes: List[str] = []
        self.index: Dict[str, int] = {}

    def fit(self, labels: List[str]) -> None:
        uniq = sorted(set(l for l in labels if l))
        self.classes = uniq
        self.index = {c: i for i, c in enumerate(self.classes)}

    def encode(self, label: str) -> int:
        return self.index.get(label, -1)

    def decode(self, idx: int) -> str:
        if 0 <= idx < len(self.classes):
            return self.classes[idx]
        return ""


# --------------------------------------------------------------------
# Feature-Extraktion (Audio -> Tensor)
# --------------------------------------------------------------------

def load_waveform(path: str, cfg: TrainConfig):
    if torchaudio is None:
        raise RuntimeError("torchaudio ist nicht installiert – bitte installieren oder eigenes Backend implementieren.")
    wav, sr = torchaudio.load(path)
    if cfg.mono and wav.shape[0] > 1:
        wav = wav.mean(dim=0, keepdim=True)
    if sr != cfg.sample_rate:
        wav = torchaudio.functional.resample(wav, sr, cfg.sample_rate)
    return wav  # Tensor [1, T]


def waveform_to_features(wav):
    """
    Placeholder: wandelt ein Waveform-Tensor in Feature-Tensor um.
    Du kannst hier z.B. eine Mel-Spectrogram-Transformation machen:
        - torchaudio.transforms.MelSpectrogram
        - torchaudio.transforms.AmplitudeToDB
    """
    if torchaudio is None:
        raise RuntimeError("torchaudio ist nicht installiert – Feature-Backend muss angepasst werden.")
    mel = torchaudio.transforms.MelSpectrogram(
        sample_rate=44100,
        n_fft=2048,
        hop_length=512,
        n_mels=64,
    )(wav)
    db = torchaudio.transforms.AmplitudeToDB()(mel)
    return db  # Tensor [1, n_mels, time]


# --------------------------------------------------------------------
# Einfaches Model-Template (CNN)
# --------------------------------------------------------------------

class SimpleConvNet(torch.nn.Module):
    """
    Sehr einfaches Convolutional Network als Platzhalter für Material/Instrument-Klassifikation.

    Input:  [B, 1, n_mels, T]
    Output: Logits für N Klassen (z.B. Material-Klassen)
    """

    def __init__(self, num_classes: int):
        super().__init__()
        self.conv = torch.nn.Sequential(
            torch.nn.Conv2d(1, 16, kernel_size=3, padding=1),
            torch.nn.BatchNorm2d(16),
            torch.nn.ReLU(),
            torch.nn.MaxPool2d(2),
            torch.nn.Conv2d(16, 32, kernel_size=3, padding=1),
            torch.nn.BatchNorm2d(32),
            torch.nn.ReLU(),
            torch.nn.MaxPool2d(2),
        )
        self.head = torch.nn.Sequential(
            torch.nn.Linear(32 * 16 * 16, 128),
            torch.nn.ReLU(),
            torch.nn.Linear(128, num_classes),
        )

    def forward(self, x):
        # x: [B, 1, M, T]
        h = self.conv(x)
        h = h.view(h.size(0), -1)
        out = self.head(h)
        return out


# --------------------------------------------------------------------
# Training-Loop (Material-Klassifikation)
# --------------------------------------------------------------------

def train_material_model(cfg: TrainConfig) -> Dict[str, Any]:
    if torch is None or torchaudio is None:
        raise RuntimeError("PyTorch/torchaudio sind nicht installiert. Bitte installieren oder Backend anpassen.")

    samples = load_dataset_from_csv(cfg.csv_path)
    if not samples:
        raise RuntimeError(f"Keine Samples in CSV: {cfg.csv_path}")

    # Material-Labels sammeln
    material_labels = [s.material for s in samples if s.material]
    if not material_labels:
        raise RuntimeError("Keine 'material'-Labels in CSV gefunden.")

    mat_encoder = LabelEncoder()
    mat_encoder.fit(material_labels)

    # Dataset als einfache Liste (für Template)
    features = []
    targets = []
    for s in samples:
        try:
            wav = load_waveform(s.audio_path, cfg)
            feat = waveform_to_features(wav)  # [1, M, T]
            features.append(feat)
            targets.append(mat_encoder.encode(s.material))
        except Exception as e:
            print(f"[WARN] Konnte Sample nicht laden/verarbeiten: {s.audio_path} ({e})")

    if not features:
        raise RuntimeError("Keine Features extrahiert – bitte Pfade/Audio prüfen.")

    # Stapeln
    X = torch.stack(features, dim=0)  # [N, 1, M, T]
    y = torch.tensor(targets, dtype=torch.long)

    num_classes = len(mat_encoder.classes)
    model = SimpleConvNet(num_classes=num_classes).to(cfg.device)
    X = X.to(cfg.device)
    y = y.to(cfg.device)

    criterion = torch.nn.CrossEntropyLoss()
    optim = torch.optim.Adam(model.parameters(), lr=cfg.learning_rate)

    model.train()
    for epoch in range(cfg.num_epochs):
        optim.zero_grad()
        logits = model(X)
        loss = criterion(logits, y)
        loss.backward()
        optim.step()
        print(f"[Epoch {epoch+1}/{cfg.num_epochs}] Loss: {loss.item():.4f}")

    # Checkpoint speichern
    ckpt = {
        "model_state": model.state_dict(),
        "material_classes": mat_encoder.classes,
        "config": {
            "sample_rate": cfg.sample_rate,
            "mono": cfg.mono,
        },
    }
    os.makedirs(os.path.dirname(cfg.checkpoint_out), exist_ok=True)
    torch.save(ckpt, cfg.checkpoint_out)
    print(f"[DF95 AIWorker Material] Checkpoint gespeichert unter: {cfg.checkpoint_out}")

    return ckpt


# --------------------------------------------------------------------
# CLI-Entrypoint (optional)
# --------------------------------------------------------------------

def main():
    """
    Beispiel-CLI:

        python df95_aiworker_material_train_template.py path/to/train.csv path/to/checkpoints/material_ckpt.pt
    """
    import sys
    if len(sys.argv) < 3:
        print("Usage: python df95_aiworker_material_train_template.py <train_csv> <checkpoint_out>")
        sys.exit(1)
    csv_path = sys.argv[1]
    ckpt_out = sys.argv[2]
    cfg = TrainConfig(csv_path=csv_path, checkpoint_out=ckpt_out)
    train_material_model(cfg)


if __name__ == "__main__":
    main()
