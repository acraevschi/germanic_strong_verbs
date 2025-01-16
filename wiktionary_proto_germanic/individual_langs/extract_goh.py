import requests
import pandas as pd
from bs4 import BeautifulSoup
from tqdm import tqdm

gem_unimorph_df = pd.read_csv("wiktionary_proto_germanic/gem_unimorph_df.csv", encoding="UTF-8")
goh = gem_unimorph_df[gem_unimorph_df.lang == "goh"]
goh_incomplete = goh[goh["PRET.SG"].isnull()]
goh_incomplete.dropna(subset=["links"], inplace=True)

def pick_one_variant(string):
    lst_strings = string.split(",")
    return lst_strings[0].strip()

def find_conjugation(soup, conjugation_id="Conjugation", i=0):
    if i != 0:
        conjugation_id = conjugation_id + "_" + str(i)
    if i == 5:
        return None
    conjugation_span = soup.find('span', {'id': conjugation_id})
    conjugation_section = conjugation_span.find_next('div', class_='NavFrame') if conjugation_span else None
    if conjugation_section is None:
        return find_conjugation(soup, i=i+1)
    table = conjugation_section.find('table', class_='inflection-table')
    if 'lang="goh"' not in table.find('td').prettify() or table is None:
        return find_conjugation(soup, i=i+1)
    else:
        return table
    

def get_table_goh(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')
    table = find_conjugation(soup)
    return table


for link in tqdm(goh_incomplete["links"]):
    # Initialize variables to store the extracted forms
    third_person_singular_past = None
    first_person_plural_past = None
    past_participle = None
    try:
        table = get_table_goh(link)
        # Find the rows in the table
        rows = table.find_all('tr')
    except:
        continue
    # Loop through the rows to extract the desired forms
    for i, row in enumerate(rows):
        if i == len(rows) - 1:
            past_participle = rows[i].find_all('td')[-1].text.strip()
            break
        current_row_val = rows[i].find_all("th")[-1].text.strip().replace(u"\xa0", u" ")
        if current_row_val == '3rd person singular' and third_person_singular_past is None:
            third_person_singular_past = rows[i].find_all('td')[-1].text.strip()
        elif current_row_val == '1st person plural' and first_person_plural_past is None:
            first_person_plural_past = rows[i].find_all('td')[-1].text.strip()
    

    gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.SG"] = pick_one_variant(third_person_singular_past)
    gem_unimorph_df.loc[gem_unimorph_df.links == link, "PRET.PL"] = pick_one_variant(first_person_plural_past)
    gem_unimorph_df.loc[gem_unimorph_df.links == link, "PTCP"] = pick_one_variant(past_participle)

gem_unimorph_df.to_csv("wiktionary_proto_germanic/gem_unimorph_df.csv", index=False, encoding="UTF-8")