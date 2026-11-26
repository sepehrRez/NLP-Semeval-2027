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

## The plan, mapped to the rubric

**1. Fair setup (validity, 5 pts)**

- Set aside about 15% of train as a validation set, keeping both directions of a pair together by grouping on `pair_id`. Tune on that set, and use dev only as your final test set. The official test set isn't released until 10 January 2027, probably after the class ends.
- Run each final setting with at least 3 random seeds and report the mean ± standard deviation.
- Follow the shared-task rules: no PhrasIS, no `trial_data/`, and don't use the fact that `NEGATIVE_OTHER` items are the only ones without a reversed copy.

**2. Models and baselines (sufficiency, 20 pts)**

- Simple baselines: majority class, and the longer-phrase rule.
- Fine-tuned encoders: BERT, RoBERTa, DeBERTa-v3 and ModernBERT. Add a DeBERTa already trained on general NLI data, which needs a small code change. Each run takes about 5–10 minutes on the Mac.
- One LLM prompted without fine-tuning, run locally with MLX (e.g. Qwen 4B or 8B).
- A small learning-rate × epochs search for your main model.

**3. One idea of your own**

The simplest strong option: at prediction time, also run the model on the swapped pair (B, A). Swap the forward and backward probabilities in that prediction, then average it with the (A, B) prediction. Both directions then agree by construction (SoftCons = 1.0), and you measure whether accuracy improves too. Because you create the swapped input yourself, this doesn't rely on the leak. Cheap extras:

- Add reversed copies of the `NEGATIVE_OTHER` training items.
- Stretch goal: a training loss that penalizes the two directions disagreeing.

**4. Analysis (20 pts)**

- Per-label scores and confusion matrices for each model.
- Which pairs break consistency.
- Error categories: one phrase contains the other, numbers, names, plurals, paraphrases.
- How each model compares with the longer-phrase shortcut.
- A manual read of about 50 errors.
- Spread across seeds.

**5. Paper (10 + 10 pts)**

See [Paper format](#paper-format) below. For related work, start from the organizers' [dico_nli_biblio.bib](latex/task_proposal_v2/dico_nli_biblio.bib). It already lists 12 relevant papers, including the Reversal Curse, PhrasIS, annotation artifacts in NLI, and consistency benchmarks. Then read the 14-page [pilot paper](latex/task_proposal_v2/item3.Baseline_System_Results__LREC_2026_DiCo_NLI_Pilot.pdf).

**6. Code (30 pts)**

You submit the starter kit together with your additions: the split script, the swapped-pair prediction, the LLM prompting code and the analysis notebook. Add a README that says which command produces which table, and state clearly which parts the organizers wrote. Keep your final predictions and scores in a folder that git tracks, because `starter_kit/results/` is ignored.

**Recommended scope:** a moderate model comparison, the consistency idea and a focused error analysis, rather than dozens of models.

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
