# Track 1 project instructions

CSCI 5832 course project on SemEval-2027 Task 2 (DiCo-NLI), Track 1 (English).

> **About this file:** Claude Opus 5.5 (Anthropic), an AI assistant used through Claude Code, wrote these notes on 26 November 2026 as planning guidance for this project. They are kept in the repository to be transparent about AI use. The paper's Acknowledgments section also discloses it.

## What's provided vs. what you do

The organizers give everyone working code: a baseline training script (the "starter kit") and the official scorer. It has been run once so far, with one model and one setting. The project isn't just tuning hyperparameters. Tuning covers roughly the 5 "experiment validity" points. The 40 points for experiments and analysis expect your own comparisons and error analysis, and the 30 code points expect code that reproduces every number in your paper. Treat the starter kit as the baseline you build on and compare against.

## The task in plain words

You get two short phrases and predict how their meanings relate:

| Label | Meaning | Example from the training data |
|---|---|---|
| `FORWARD_ENTAILMENT` | phrase 1 implies phrase 2 | "against Greenpeace activists" → "against Greenpeace" |
| `BACKWARD_ENTAILMENT` | phrase 2 implies phrase 1 | "against Greenpeace" → "against Greenpeace activists" |
| `EQUIVALENCE` | same meaning | "flying" → "in flight" |
| `NEGATIVE_OTHER` | none of these | "a dog" → "the skateboarder" |

It's about meaning, not shared words: "Five dead" → "Four dead" is forward entailment, because if five died, then four died.

**The twist:** every pair with a relation appears twice, once in each order, and the two correct answers are linked. If (A, B) is forward, then (B, A) must be backward, and equivalence stays equivalence. The task checks whether models respect that. There are three official scores:

- **Weighted F1:** how well you label individual items.
- **SoftCons:** for each pair, whether your two answers are compatible with each other, even if both are wrong.
- **HardCons:** for each pair, whether both answers are right.

## The files that matter

| Path | What it is | You… |
|---|---|---|
| [README.md](README.md) | Official task description and rules | read it |
| [final_data/](final_data/) `…track1_participant_labeled.csv` | Train (3,042 rows) and dev (660 rows), with columns `text1`, `text2`, `label`, `pair_id` | use, don't edit |
| `…track1_reference.csv` (same folders) | The scorer's answer key | use, don't edit |
| [evaluation_functions/](evaluation_functions/) | Official scorer | use, don't edit |
| [starter_kit/](starter_kit/) | Baseline training code | build on it |
| [latex/task_proposal_v2/](latex/task_proposal_v2/) | Pilot paper PDF, ACL style files, a `.bib` of related work | reuse for your paper |
| [trial_data/](trial_data/) | Old sample data | **don't train on it**: 64 of its pairs are also in dev |
| [starter_kit/paper/](starter_kit/paper/) | Your paper: [acl_latex.tex](starter_kit/paper/acl_latex.tex) and [custom.bib](starter_kit/paper/custom.bib) | write it |

## What the starter kit does, and doesn't do

[run_track1.sh](starter_kit/run_track1.sh) calls [main.py](starter_kit/main.py), which does three things:

1. Reads the CSVs and turns the labels into numbers ([data_reader.py](starter_kit/src/trainer/helpers/data_reader.py)).
2. Downloads a pretrained model and adds a 4-way classifier on top. Both phrases go into the model together as one input ([model.py](starter_kit/src/trainer/helpers/model.py)).
3. Trains for N epochs. After each epoch it predicts dev, writes a predictions CSV, and runs the official scorer ([trainer.py](starter_kit/src/trainer/trainer.py)).

It doesn't create a validation split, do anything special for consistency, analyze errors, or use LLMs. That's where your work goes.

The one run so far (DeBERTa-v3-base, final epoch, dev) scored F1 0.83, SoftCons 0.88 and HardCons 0.83. Its errors already suggest angles for the analysis:

- Only 4 of its 113 errors get the direction backwards.
- About two-thirds of the errors involve `NEGATIVE_OTHER`, its worst label (F1 0.66). Most of the rest confuse equivalence with entailment.
- A one-line rule, "the longer phrase entails the shorter one", is already right on 61% of the dev items that have a relation. Whether models learn more than that shortcut is exactly what this task asks.

## Roles and status

- **Done:** the environment, one baseline run, and the paper's Related Work section, which cites 7 papers (see [custom.bib](starter_kit/paper/custom.bib)).

## The experiment plan, mapped to the rubric

About a day in total, most of it the laptop training unattended. Keep it plugged in: it's a fanless MacBook Air, so long runs slow down as it heats up.

**1. Fair setup (validity, 5 pts): ~1 h**

- **Split:** set aside about 15% of train as a validation set, grouped by `pair_id` so both directions of a pair stay together. Tune on it, and use the official dev set only for the final numbers. The official test set isn't released until 10 January 2027, probably after the class ends.
- **Tuning:** pick the number of epochs for each model on the validation set. Add a small learning-rate search for the main model only.
- **Seeds:** run each final setting with 3 seeds and report the mean ± standard deviation.
- **Rules:** no PhrasIS, no `trial_data/`, and don't use the fact that `NEGATIVE_OTHER` items are the only ones without a reversed copy.
- **Output:** the split files, plus a runner script that trains, picks epochs and collects the official scores into one table.

**2. Models and baselines (sufficiency, 20 pts): ~2–3 h of unattended GPU time**

- **Baselines:** majority class, and the rule "the longer phrase entails the shorter one". These take seconds.
- **Fine-tuned encoders:** BERT, RoBERTa, DeBERTa-v3 and ModernBERT.
- **Output:** the main results table.

**3. Your idea, a consistency loss: ~1 h of coding, ~2 h of runs**

This adapts Li et al. (2019)'s symmetry loss to DiCo-NLI's directional rule.

- **How it works:** for each training pair (A, B), the model also sees the swapped pair (B, A), created on the fly. A penalty grows when the two predictions disagree, after swapping the forward and backward probabilities of the second. Total loss = cross-entropy + λ × penalty.
- **Why it's interesting:** the swapped pairs need no labels, so the loss also covers `NEGATIVE_OTHER` items, which appear in one direction only. Li et al. applied the idea to contradiction, which reads the same both ways. Here, the label must *change* when the pair is swapped (forward ↔ backward).
- **Watch out:** predicting `EQUIVALENCE` for everything is perfectly consistent, so a large λ can push the model that way. Tune λ on the validation set (e.g. 0.1 vs 1) and watch F1.
- **Expectations:** the training data already has both directions with correct labels, so the gains may be small. A small or zero gain is still a valid result if you analyze it honestly. The baseline does leave room: 32 of 277 dev pairs were inconsistent.
- **Scope:** the main model only (likely DeBERTa-v3), with 3 seeds.
- **Output:** the ablation table, with three rows: the baseline, the baseline plus the consistency loss, and swap-and-average as a cheap extra. Swap-and-average runs the model on the swapped pair at prediction time, swaps its forward and backward probabilities, and averages with the original prediction, without any retraining. Comparing consistency enforced at training time with consistency enforced at prediction time gives the paper a good discussion point.

**4. Analysis (20 pts): ~1 h**

- Per-label scores and the confusion matrix.
- A three-way consistency breakdown: both directions right, consistent but wrong, and inconsistent. SoftCons tests the reversal rule; HardCons tests that both directions are right.
- How each model compares with the longer-phrase shortcut.
- The spread across seeds.
- An errors CSV for a manual read of about 50 errors, which Sepehr can categorize.
- **Output:** tables and figures ready for the paper.

**5. Hand-off to Sepehr**

- The tables and figures from steps 2–4.
- The errors CSV.
- A short "what we ran" note covering models, settings, seeds, hardware and library versions, for the System Overview and Experimental Setup sections.
- One sentence for the last Related Work TODO: how the consistency loss relates to Li et al.

**6. Code (30 pts)**

Submit the starter kit with your additions: the split script, the runner, the consistency loss, swap-and-average, and the analysis script.

- Add a README that maps each table to the command that produces it, and say which parts the organizers wrote.
- Keep final predictions and scores in a folder that git tracks, because `starter_kit/results/` is ignored.
- Keep the AI-use statement in the paper's Acknowledgments up to date as Claude helps with the code.

**Optional, only if time allows:** a DeBERTa already trained on general NLI data, or an LLM prompted without fine-tuning (run locally with MLX).

## Paper format

**Class requirements:** LaTeX with the ACL template, 5–8 pages, submitted as a PDF, and meeting the requirements of a real SemEval submission.

**SemEval system-paper rules** (from the [requirements](https://semeval.github.io/paper-requirements.html) and the [section outline](https://semeval.github.io/system-paper-template.html)):

- **Title:** "*Team name* at SemEval-2027 Task 2: *descriptive title*".
- **Not anonymous:** put your names and affiliations on the paper. Use `\usepackage[final]{acl}` (or `preprint`, which adds page numbers). Never use `review`, which hides the author names.
- **Sections, in order:**
  - Abstract.
  - Introduction: the task, your approach, your main results, and the URL of your code.
  - Background: the task, the data, and related work.
  - System Overview: your method, in enough detail to reimplement it. This is usually the longest section.
  - Experimental Setup: data splits, preprocessing, hyperparameter tuning, tool versions, and metrics.
  - Results: official scores, ablations, and error analysis.
  - Conclusion.
  - Optional: a Limitations section (standard in ACL papers) and an appendix for hyperparameters and extra results.
- **Results:** report several runs, ablations and comparisons with baselines, and give enough detail to reproduce your system.
- **Citations:** cite the task description paper. It isn't published yet, so use a placeholder citation for now.
- **Length:** SemEval's own limit is 5 pages, plus references and appendices. The class asks for 5–8, so follow the class. If you later submit to SemEval itself, move the extra material to the appendix.

**About the example in `latex/task_proposal_v2/`:** it uses the right template (the official ACL style files) and is 6 pages long, but it's the wrong kind of paper. It's the organizers' *task proposal*, so its title and sections (data, tracks, schedule, organizers) don't fit a system paper. Reuse its LaTeX setup (style files, bibliography), not its structure. The pilot paper is an LREC paper, so use it for content, not format.

**Your skeleton:** [starter_kit/paper/acl_latex.tex](starter_kit/paper/acl_latex.tex) follows this structure. Red `[TODO: …]` markers show what you still need to write, and a checklist at the top of the file lists the submission requirements.

**Writing tool:** upload these four files to a new Overleaf project: `acl_latex.tex`, `custom.bib`, `acl.sty` and `acl_natbib.bst`. Leave out `acl_lualatex.tex`, which is an alternative template for a different compiler and won't build with Overleaf's default. To build locally instead, run `tectonic acl_latex.tex` in that folder.

## Still to decide

- The report deadline, which decides how much of steps 2–4 fits.
