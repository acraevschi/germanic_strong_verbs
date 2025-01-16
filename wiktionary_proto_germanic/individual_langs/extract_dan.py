from bs4 import BeautifulSoup
import requests
import pandas as pd
from tqdm import tqdm

gem_unimorph_df = pd.read_csv(
    "wiktionary_proto_germanic/gem_unimorph_df.csv", encoding="UTF-8"
)
dan = gem_unimorph_df[gem_unimorph_df.lang == "dan"]


def split_multiword(string):
    if len(string.split()) == 3:
        return string.split()[0]
    elif len(string.split()) == 2:
        return string.split()[1]
    else:
        return string


gem_unimorph_df[gem_unimorph_df.lang == "deu"]
for link in tqdm(dan["links"]):
    try:
        html_code = requests.get(link).text
        soup = BeautifulSoup(html_code, "html.parser")
        participle = soup.find_all(
            "span", class_="Latn form-of lang-da past|part-form-of"
        )
        past = soup.find_all("span", class_="Latn form-of lang-da past-form-of")
        gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.SG"] = split_multiword(
            past[0].text
        )
        gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.PL"] = split_multiword(
            past[0].text
        )
        gem_unimorph_df.loc[gem_unimorph_df.links == link, "PTCP"] = split_multiword(
            participle[0].text
        )
    except:
        html_code = requests.get(link).text
        soup = BeautifulSoup(html_code, "html.parser")
        participle = soup.find_all(
            "b", class_="Latn form-of lang-da past|part-form-of", attrs={"lang": "da"}
        )
        past = soup.find_all(
            "b", class_="Latn form-of lang-da past-form-of", attrs={"lang": "da"}
        )
        gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.SG"] = split_multiword(
            past[0].text
        )
        gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.PL"] = split_multiword(
            past[0].text
        )
        gem_unimorph_df.loc[gem_unimorph_df.links == link, "PTCP"] = split_multiword(
            participle[0].text
        )
    finally:
        continue

dan = gem_unimorph_df[gem_unimorph_df.lang == "dan"]

gem_unimorph_df.to_csv(
    "wiktionary_proto_germanic/gem_unimorph_df.csv", index=False, encoding="UTF-8"
)
