### Semantics drives analogical change in Germanic strong verb paradigms: A phylogenetic study

This repository contains code and data to reproduce the analysis from the paper **Semantics drives analogical change in Germanic strong verb paradigms: A phylogenetic study**. 

For the details about methodology and/or data, please refer to the paper. 

## Data collection and annotation

Data collection pipeline is distributed in two folders: `unimorph_data` and `wiktionary_proto_germanic`. The scripts from these folders extract the data from [Unimorph](https://unimorph.github.io/) and [Wiktionary](https://www.wiktionary.org/), respectively. The script `scrap_for_wiktionary_germanic_descendants` finds strong verbs descending from Proto-Germanic strong verbs and extracts the descendants of these verbs using the web version of Wiktionary. This is done by using [BeautifulSoup](https://pypi.org/project/beautifulsoup4/). 

After extraction, the data from the two sources were interleaved. This gives us a list of Proto-Germanic verbs with forms in one of the 14 languages used in the study. For each Proto-Germanic verb, we calculate the percentage of missing verbs and only keep Proto-Germanic verbs with at least 80% of the languages having the form descending from the verb. After finalizing this process, we go through the data collected in this automatized way and check the entries manually. The manual check includes going to Wiktionary to check for comments, checking whether the inflected forms were extracted correctly, etc. For some languages, Wiktionary contained very few entries or entries from diverse varieties (e.g., Low German) and in certain cases, we used external resources. Whenever external resources were used, we provide a link of reference to the resource in the corresponding column. 

Concurrently, we code the vowel alternation pattern in the 4 principal parts. As described in the paper, we simplify the coding by reducing the alternation patterns to 3 principal parts. To do that, we create two additional columns, one where we account for alternations only in singular past tense form and another one with alternations only in plural past tense. In the study, we only use the principal parts from infinitive, singular past tense and past participle but the dataset contains the other options as well. 

Finally, where deemed necessary, we documented some of the decisions. For example, Old Saxon's verb *_blāsan_ is actually not attested but rather reconstructed. 

## Stan models and Simulation