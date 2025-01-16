from urllib.request import urlopen
from bs4 import BeautifulSoup
import requests
import re
import pandas as pd
from tqdm import tqdm

### Old Dutch wasn't extracted originally, so I'm adding it here in a separate script and concatenating it to the already partially manually modified Germanic dataset

gem_manual_df = pd.read_csv(
    "wiktionary_proto_germanic/unimorph_wikt_manual.csv", encoding="UTF-8"
)


def get_urls(page):
    lang_urls = []
    while True:
        html = page.read()
        page.close()
        soup = BeautifulSoup(html, "lxml")
        for s in soup.find_all("a"):
            if "href" in s.attrs and s["href"].startswith("/wiki/Reconstruction:"):
                href = s["href"]
                lang_urls.append("https://en.wiktionary.org/" + href)
        if len([s for s in soup.find_all("a") if s.text == "next page"]) == 0:
            break
        else:
            href = [s for s in soup.find_all("a") if s.text == "next page"][0]["href"]
            page = urlopen("https://en.wiktionary.org" + href)
    return lang_urls


lang_urls = []
for i in range(1, 8):
    page = urlopen(
        f"https://en.wiktionary.org/wiki/Category:Proto-Germanic_class_{i}_strong_verbs"
    )
    lang_urls.extend(get_urls(page))
    if i in (5, 6, 7):
        page = urlopen(
            f"https://en.wiktionary.org/wiki/Category:Proto-Germanic_class_{i}_strong_j-present_verbs"
        )
        lang_urls.extend(get_urls(page))
    if i == 7:
        for letter in "abcde":
            page = urlopen(
                f"https://en.wiktionary.org/wiki/Category:Proto-Germanic_class_7{letter}_strong_verbs"
            )
            lang_urls.extend(get_urls(page))

cognates = dict()
for url in tqdm(lang_urls, desc="Extracting Old Dutch descendants"):
    page = urlopen(url)
    html = page.read()
    page.close()
    soup = BeautifulSoup(html, "lxml")
    # extract the Proto-Germanic form from title's page
    proto_gem_form = re.search(r"/([^/]+) -", soup.title.string).group(1)
    cognates[proto_gem_form] = []
    for s in soup.select("span.Latn, span.tr.Latn, span.Latnx"):
        if "lang" in s.attrs and s["lang"] == "odt":
            if s.find("a") != None:  # and "href" in s.find("a").attrs
                # print(s['lang'],s.text,s.find('a')['href'])
                # cognates.append([s["lang"], s.text, s.find("a")["href"]])
                try:
                    cognate_lst = (s["lang"], s.text, s.find("a")["href"])
                except:
                    cognate_lst = (s["lang"], s.text, None)
                cognates[proto_gem_form].append(cognate_lst)
            else:
                continue
                # print(s['lang'],s.text)
                # cognates.append([s["lang"], s.text, ""])

long_odt = {col_name: [] for col_name in gem_manual_df.columns}

for key, value_lst in cognates.items():
    if key not in gem_manual_df["proto_gem_form"].values:
        continue
    try:
        values = value_lst[0]
        long_odt["proto_gem_form"].append(key)
        long_odt["lang"].append("odt")
    except:
        long_odt["proto_gem_form"].append(key)
        long_odt["lang"].append("odt")
    try:
        if "*" in values[1]:
            long_odt["form"].append(values[1].replace("*", ""))
            long_odt["Note"].append("Reconstructed")
        else:
            long_odt["form"].append(values[1])
            long_odt["Note"].append(None)
    except:
        long_odt["form"].append(None)
    try:
        long_odt["links"].append("https://en.wiktionary.org" + values[-1])
    except:
        long_odt["links"].append(None)

long_odt["PRET.SG"] = [None] * len(long_odt["proto_gem_form"])
long_odt["PRET.PL"] = [None] * len(long_odt["proto_gem_form"])
long_odt["PTCP"] = [None] * len(long_odt["proto_gem_form"])

odt_df = pd.DataFrame.from_dict(long_odt)


def find_conjugation(soup, conjugation_id="Inflection", i=0):
    if i != 0:
        conjugation_id = conjugation_id + "_" + str(i)
    if i == 5:
        return None
    conjugation_span = soup.find("span", {"id": conjugation_id})
    conjugation_section = (
        conjugation_span.find_next("div", class_="NavFrame")
        if conjugation_span
        else None
    )
    if conjugation_section is None:
        return find_conjugation(soup, i=i + 1)
    table = conjugation_section.find("table", class_="inflection-table")
    if 'lang="odt"' not in table.find("td").prettify() or table is None:
        return find_conjugation(soup, i=i + 1)
    else:
        return table


def get_table_odt(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, "html.parser")
    table = find_conjugation(soup)
    return table


table = get_table_odt("https://en.wiktionary.org/wiki/Reconstruction:Old_Dutch/bitan")

for link in tqdm(odt_df["links"]):
    # Initialize variables to store the extracted forms
    third_person_singular_past = None
    first_person_plural_past = None
    past_participle = None
    try:
        table = get_table_odt(link)
        # Find the rows in the table
        rows = table.find_all("tr")
    except:
        continue
    # Loop through the rows to extract the desired forms
    for i, row in enumerate(rows):
        if i == len(rows) - 1:
            past_participle = rows[i].find_all("td")[-1].text.strip()
            break
        current_row_val = rows[i].find_all("th")[-1].text.strip().replace("\xa0", " ")
        if (
            current_row_val == "3rd person singular"
            and third_person_singular_past is None
        ):
            third_person_singular_past = rows[i].find_all("td")[-1].text.strip()
        elif (
            current_row_val == "1st person plural" and first_person_plural_past is None
        ):
            first_person_plural_past = rows[i].find_all("td")[-1].text.strip()

    odt_df.loc[odt_df.links == link, "PRET.SG"] = third_person_singular_past.replace(
        "*", ""
    )
    odt_df.loc[odt_df.links == link, "PRET.PL"] = first_person_plural_past.replace(
        "*", ""
    )
    odt_df.loc[odt_df.links == link, "PTCP"] = past_participle.replace("*", "")

combined_df = pd.concat([gem_manual_df, odt_df], ignore_index=True)

combined_df.to_csv(
    "wiktionary_proto_germanic/unimorph_wikt_manual.csv", index=False, encoding="UTF-8"
)
