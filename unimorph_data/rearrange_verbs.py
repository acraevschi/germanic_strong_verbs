import pandas as pd
from tqdm import tqdm

unimorph = pd.read_csv("unimorph_germanic.tsv", sep="\t", encoding="utf8")
unimorph = unimorph.dropna()  # drop empty lines
unimorph = unimorph[~unimorph.features.str.contains("LGSPEC")]

languages = list(set(unimorph["unimorph_iso"]))


def find_relevant(paradigm, lang):
    """
    Returns two values in a list, first is PST form and second is PTCP
    """
    past_sg, past, participle = "-", "-", "-"

    if len(paradigm) == 1:  # for Swiss German
        # Past                                # Participle
        return [
            paradigm.iloc[0]["inflected_form"],
            paradigm.iloc[0]["inflected_form"],
            paradigm.iloc[0]["inflected_form"],
        ]
    for i in range(len(paradigm)):
        if "PTCP" in paradigm.iloc[i, -1] or "CVB" in paradigm.iloc[i, -1]:
            participle = paradigm.iloc[i]["inflected_form"]
        elif (
            "3;" in paradigm.iloc[i]["features"]
            and "SG" in paradigm.iloc[i]["features"]
        ):
            past_sg = paradigm.iloc[i]["inflected_form"]
        elif lang in ("dan", "swe", "nob", "eng"):
            if lang == "swe" and "SG" in paradigm.iloc[i]["features"]:
                past_sg = paradigm.iloc[i]["inflected_form"]
            elif lang == "swe" and "PL" in paradigm.iloc[i]["features"]:
                past = paradigm.iloc[i]["inflected_form"]
            else:
                past_sg = paradigm.iloc[i]["inflected_form"]
                past = paradigm.iloc[i]["inflected_form"]
        elif (
            "PL" in paradigm.iloc[i]["features"]
            and "PST" in paradigm.iloc[i]["features"]
            and "1;" in paradigm.iloc[i]["features"]
        ):
            past = paradigm.iloc[i]["inflected_form"]
        elif (
            "PL" in paradigm.iloc[i]["features"]
            and "PST" in paradigm.iloc[i]["features"]
        ):
            past = paradigm.iloc[i]["inflected_form"]
        elif paradigm.iloc[0].unimorph_iso == "fao":
            past = paradigm.loc[paradigm.features == "V;IND;PST;3"][
                "inflected_form"
            ].values[0]

    return [past_sg, past, participle]


file = open("rearranged_verbs.tsv", "w", encoding="utf8")
file.write("unimorph_iso\tINF\tPST.SG\tPST.PL\tPTCP\n")  # write headers

for lang in tqdm(languages, desc=f"Extracting principal parts"):
    unimorph_lang = unimorph.loc[unimorph["unimorph_iso"] == lang]
    unique_verbs = list(set(unimorph_lang["lemma"]))
    for verb in tqdm(unique_verbs):
        paradigm = unimorph_lang[unimorph_lang.lemma == verb]
        past_sg, past, participle = find_relevant(paradigm, lang)
        print("\t".join([lang, verb, past_sg, past, participle]), file=file)

file.close()
