import pandas as pd
import json
from tqdm import tqdm

with open("../support_files/gem_iso_list.txt", "r") as f:
    iso_list = f.read().split(",")

code_iso_name = pd.read_csv("../support_files/LanguageCodes.tsv", sep="\t")
code_iso_dict = {
    code: iso
    for code, iso in zip(code_iso_name["WiktionaryCode"], code_iso_name["iso-639-3"])
    if iso in iso_list
}
code_iso_dict["got-Latn"] = "got"

wikt_path = "cognates_germanic.json"
with open(wikt_path, "r", encoding="UTF-8") as json_file:
    cognates = json.load(json_file)

unimorph_data = pd.read_csv(
    "../unimorph_data/rearranged_verbs.tsv", sep="\t", encoding="UTF-8"
)
unimorph_data.columns = ["lang", "form", "PRET.SG", "PRET.PL", "PTCP"]

# make proto-germanic form the first column and the rest of the columns will be the germanic languages with corresponding forms
proto_gem_forms = list(cognates.keys())
all_langs = []

for form in proto_gem_forms:
    langs = [code_iso_dict[cognate[0]] for cognate in cognates[form]]
    all_langs += langs

set_langs = set(all_langs)
gem_df = pd.DataFrame(index=proto_gem_forms, columns=list(set_langs))

# fill the dataframe with the cognates
for gem_form in tqdm(cognates, desc="Filling the dataframe"):
    for cognate in cognates[gem_form]:
        lang = code_iso_dict[cognate[0]]
        form = cognate[1].replace(
            "*", ""
        )  # remove the asterisk from reconstructed forms
        gem_df.loc[gem_form][lang] = form

# only keep the rows from the dataframe that have at least certain % coverage
threshold = 0.8
gem_df = gem_df.dropna(thresh=threshold * len(gem_df.columns))

# transform gem_df from wide to long format
gem_df = gem_df.reset_index()
gem_df = gem_df.rename(columns={"index": "proto_gem_form"})
gem_df = pd.melt(
    gem_df,
    id_vars="proto_gem_form",
    var_name="lang",
    value_name="form",
    ignore_index=True,
)

# gem_df.to_csv("wiktionary_proto_germanic/gem_long.csv", index=False, encoding="UTF-8")
unimorph_goh = list(set(unimorph_data[unimorph_data["lang"] == "goh"]["form"]))
wikt_goh = set(gem_df[gem_df["lang"] == "goh"]["form"])

for form in wikt_goh:
    if form in unimorph_goh:
        unimorph_goh.remove(form)

### It misses a lot of forms
# link unimorph data to gem_df
gem_unimorph_df = pd.merge(
    unimorph_data,
    gem_df,
    left_on=["lang", "form"],
    right_on=["lang", "form"],
    how="right",
)
gem_unimorph_df.dropna(subset=["PRET.SG"]).value_counts("lang")

# add links to wiktionary for manual extraction of conjugated forms
gem_unimorph_df["links"] = None
for cognate_set in cognates.keys():
    if cognate_set not in gem_unimorph_df["proto_gem_form"].values:
        continue
    for cognate in cognates[cognate_set]:
        lang, form, link = code_iso_dict[cognate[0]], cognate[1], cognate[2]
        gem_unimorph_df.loc[
            (gem_unimorph_df["lang"] == lang) & (gem_unimorph_df["form"] == form),
            "links",
        ] = (
            "https://en.wiktionary.org/" + link
        )

gem_unimorph_df.to_csv("gem_unimorph_df.csv", index=False, encoding="UTF-8")
