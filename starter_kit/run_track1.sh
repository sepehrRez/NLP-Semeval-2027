#!/usr/bin/env bash
# Track 1 (English): fine-tune on the official train split and score every epoch
# on dev with the official scorer. Uses the Apple-Silicon GPU (MPS) automatically.
#
#   ./run_track1.sh                                # DeBERTa-v3-base, default hyper-parameters
#   ./run_track1.sh answerdotai/ModernBERT-large   # any Hugging Face model id or local path
#   EPOCHS=3 LR=3e-5 BS=32 ./run_track1.sh         # override hyper-parameters
#   SAVE=1 ./run_track1.sh                         # also keep the fine-tuned weights
#   TEST=path/to/test.csv ./run_track1.sh          # also write predictions for a test file
#   DEVICE=cpu ./run_track1.sh                     # force a device (auto|mps|cpu|cuda)
#
# Outputs go to results/track1/<model>/<timestamp>/: train.log, per-epoch dev
# prediction CSVs, and the official scorer's output next to each CSV.
set -euo pipefail
cd "$(dirname "$0")"

MODEL="${1:-microsoft/deberta-v3-base}"
DATA=../final_data
RUN_DIR="results/track1/${MODEL//\//__}/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RUN_DIR"

args=(
  --model_path "$MODEL" --tokenizer_path "$MODEL"
  --do_train --train_path "$DATA/train/dico_nli_train_track1_participant_labeled.csv"
  --do_dev --dev_path "$DATA/dev/dico_nli_dev_track1_participant_labeled.csv"
  --reference_path "$DATA/dev/dico_nli_dev_track1_reference.csv"
  --seed "${SEED:-42}" --max_length "${MAX_LEN:-128}" --device "${DEVICE:-auto}"
  --lr "${LR:-2e-5}" --batch_size "${BS:-16}" --num_epochs "${EPOCHS:-5}"
  --wd "${WD:-1e-2}" --warmup_pcrt "${WARMUP:-0.1}" --dropout "${DROPOUT:-0.1}"
  --no-is_optuna_trial --results_dir "$RUN_DIR"
)
if [[ -n "${TEST:-}" ]]; then args+=(--do_test --test_path "$TEST"); else args+=(--no-do_test); fi
if [[ -n "${SAVE:-}" ]]; then args+=(--save_path "$RUN_DIR/model"); fi

echo "Run directory: $RUN_DIR"
uv run --project .. python -u main.py "${args[@]}" 2>&1 | tee "$RUN_DIR/train.log"

echo
echo "Official dev scores per epoch ($RUN_DIR):"
grep -A3 "Official DiCo-NLI metrics on dev" "$RUN_DIR/train.log" | grep -E "Weighted F1|SoftCons|HardCons" | paste - - - | nl -w2 -s'  '
