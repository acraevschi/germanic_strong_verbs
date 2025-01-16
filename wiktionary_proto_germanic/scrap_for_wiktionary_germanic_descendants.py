from urllib.request import urlopen
from bs4 import BeautifulSoup
import re
import pandas as pd
from tqdm import tqdm
import json


with open("../support_files/gem_iso_list.txt", "r") as f:
    iso_list = f.read().split(",")

code_name = pd.read_csv("../support_files/LanguageCodes.tsv", sep="\t")
code_name_dict = {
    code: name
    for code, name, iso in zip(
        code_name["WiktionaryCode"], code_name["Canonical name"], code_name["iso-639-3"]
    )
    if iso in iso_list
}
code_name_dict["got-Latn"] = "Gothic"


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
for url in tqdm(lang_urls, desc="Extracting descendants"):
    page = urlopen(url)
    html = page.read()
    page.close()
    soup = BeautifulSoup(html, "lxml")
    # extract the Proto-Germanic form from title's page
    proto_gem_form = re.search(r"/([^/]+) -", soup.title.string).group(1)
    cognates[proto_gem_form] = []
    for s in soup.select("span.Latn, span.tr.Latn, span.Latnx"):
        if "lang" in s.attrs and s["lang"] in code_name_dict.keys():
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

file_path = "cognates_germanic.json"
with open(file_path, "w", encoding="UTF-8") as json_file:
    json.dump(cognates, json_file, indent=2)
