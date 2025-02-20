# Semantics drives analogical change in Germanic strong verb paradigms: A phylogenetic study

This repository contains code and data to reproduce the analysis from the paper **Semantics drives analogical change in Germanic strong verb paradigms: A phylogenetic study**. 

For the details about methodology and/or data, please refer to the paper (link comming). All the results are saved as RDS files (most of them within `analysis_results`' subfolders) and can be read with R to avoid the necessity to re-run everything, as it requires significant compute time.

## Data collection and annotation

Data collection pipeline is distributed in two folders: `unimorph_data` and `wiktionary_proto_germanic`. The scripts from these folders extract the data from [Unimorph](https://unimorph.github.io/) and [Wiktionary](https://www.wiktionary.org/), respectively. The script `scrap_for_wiktionary_germanic_descendants` finds strong verbs descending from Proto-Germanic strong verbs and extracts the descendants of these verbs using the web version of Wiktionary. This is done by using [BeautifulSoup](https://pypi.org/project/beautifulsoup4/). 

After extraction, the data from the two sources were interleaved. This gives us a list of Proto-Germanic verbs with forms in one of the 14 languages used in the study. For each Proto-Germanic verb, we calculate the percentage of missing verbs and only keep Proto-Germanic verbs with at least 80% of the languages having the form descending from the verb. After finalizing this process, we go through the data collected in this automatized way and check the entries manually. The manual check includes going to Wiktionary to check for comments, checking whether the inflected forms were extracted correctly, etc. For some languages, Wiktionary contained very few entries or entries from diverse varieties (e.g., Low German) and in certain cases, we used external resources. Whenever external resources were used, we provide a link of reference to the resource in the corresponding column. 

Concurrently, we code the vowel alternation pattern in the 4 principal parts. As described in the paper, we simplify the coding by reducing the alternation patterns to 3 principal parts. To do that, we create two additional columns, one where we account for alternations only in singular past tense form and another one with alternations only in plural past tense. In the study, we only use the principal parts from infinitive, singular past tense and past participle but the dataset contains the other options as well. 

Finally, where deemed necessary, we documented some of the decisions. For example, Old Saxon's verb *_blāsan_ is actually not attested but rather reconstructed. 

## Stan models and Simulation

### Hierarchical Model

The hierarchical model used in the study is implemented in the Stan script simmap_verb_hierarchy.stan, which specifies transition rates between verb states. Each verb can be in one of five states: AAA, AAB, ABA, ABB, or ABC. The transition rates between these states are modeled as lognormal-distributed variables, allowing variation across verbs and across two linguistic regimes: extended and non-extended. The global death rate of verbs is also included as a parameter.

Likelihood computations rely on a pruning algorithm, implemented as a Stan function in Stan files (in folder `analysis/models_code`), which efficiently calculates the probability of observed data given the model. This algorithm follows a dynamic programming approach to traverse the phylogenetic tree and compute likelihoods for each node. The posterior distributions of transition rates are estimated using RStan.

Posterior rate matrices are constructed from the sampled transition rates and used to derive posterior stationary distributions (in `stationary_prob.R`). Entry and exit rates for different states are computed to analyze changes in verbal paradigms under different regimes (`entry_rates.R` and `exit_rates.R` files). All the files can be found in the folder `analyze_output`.

### Non-Hierarchical Model

An alternative non-hierarchical model, implemented in `simmap_no-hierarchy.stan`. It assumes invariant transition rates across all verbs. This provides a baseline for comparison with the hierarchical model, allowing an assessment of whether verb-specific variation in transition rates is necessary to explain the observed data. Inference follows the same steps as in the hierarchical case.

### Model Comparison

To evaluate model performance, we compare the hierarchical and non-hierarchical models using Pareto-smoothed importance sampling leave-one-out cross-validation (PSIS-LOO-CV) (`compare_models.R` in `model_comparison`, the comparison results are saved as RDS files in the same folder). The hierarchical model outperforms the non-hierarchical model, as indicated by the expected log predictive density (ELPD) scores.

### Ancestral State Reconstruction

The hierarchical model's fitted parameters are used to reconstruct the most probable ancestral state distributions for each verb at the root of the phylogenetic tree (`anc_rec.R`). The reconstructed states are compared with expert reconstructions, showing an accuracy of 89% (`eval_rec.R`).

### Ancestry-Constrained Model

To validate the robustness of the ancestral state reconstruction, an ancestry-constrained version of the hierarchical model is run, enforcing the root state to match expert reconstructions (`tam_simmap_root.R`). This produces results consistent with the unconstrained model.

### Simulation Study

A simulation study is conducted to assess the false positive rate of the hierarchical model-fitting procedure. Synthetic datasets are generated under the non-hierarchical model (`sim_history.R`), ensuring no inherent differences across regimes. The hierarchical model is then fitted to this dataset to test whether it will erroneously detect regime-based difference. This validation confirms that the hierarchical model does not produce spurious results, reinforcing the reliability of the main study findings.

A brief description of the analysis of the results of the models in presented in `results_analysis_summ.Rmd`. 