from bs4 import BeautifulSoup
import requests
from tqdm import tqdm
import pandas as pd

gem_unimorph_df = pd.read_csv(
    "wiktionary_proto_germanic/gem_unimorph_df.csv", encoding="UTF-8"
)
nld = gem_unimorph_df[gem_unimorph_df.lang == "nld"]
nld_incomplete = nld[nld["PRET.SG"].isnull()]
nld_incomplete.dropna(subset=["links"], inplace=True)
nld_incomplete = nld_incomplete[
    nld_incomplete["form"] != "bijden"
]  # spotted an error in link

for link in tqdm(nld_incomplete["links"]):
    html_code = requests.get(link).text

    # Parse the HTML code with BeautifulSoup
    soup = BeautifulSoup(html_code, "html.parser")

    # Find the rows based on the title attribute of the <th> tag
    all_th_tags = soup.find_all("th")

    ind = 0
    found = False
    for th_tag in all_th_tags:
        try:
            if 'lang="nl"' in th_tag.prettify():
                found = True
                break
        except:
            continue
        ind += 1

    if not found:  # otherwise the last <th> tag will serve as index
        continue

    past_ind = ind + 2
    past_participle_ind = ind + 3

    past_singular_th = all_th_tags[past_ind]
    past_participle_th = all_th_tags[past_participle_ind]

    # Extract the corresponding <td> tags
    past_singular_td = past_singular_th.find_next("td") if past_singular_th else None
    past_participle_td = (
        past_participle_th.find_next("td") if past_participle_th else None
    )

    # Extract the text content from the found <td> tags
    past_singular = past_singular_td.text.strip() if past_singular_td else None
    past_participle = past_participle_td.text.strip() if past_participle_td else None

    # Print the results
    gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.SG"] = past_singular
    # the vowel of plural in dutch is the same as singular, so this is reasonable to do
    gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.PL"] = past_singular
    gem_unimorph_df.loc[gem_unimorph_df.links == link, "PTCP"] = past_participle

gem_unimorph_df.to_csv(
    "wiktionary_proto_germanic/gem_unimorph_df.csv", index=False, encoding="UTF-8"
)