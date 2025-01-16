import requests
import re

with open("../support_files/gem_iso_list.txt", "r") as f:
    unimorph_iso_list = f.read().split(",")

file = open("unimorph_germanic.tsv", "w", encoding="utf8")
file.write("unimorph_iso\tlemma\tinflected_form\tfeatures\n")  # write headers

for iso_code in unimorph_iso_list:
    url = (
        "https://raw.githubusercontent.com/unimorph/" + iso_code + "/master/" + iso_code
    )
    dataset = requests.get(url).text
    dataset = dataset.split("\n")
    for line in dataset:
        # When I use the regex from elif, I still get SBJV for some languages, so the following line intends to prevent this behaviour
        if iso_code == "dan" and re.search(r"(V;ACT;IND;PST)|(V.PTCP;PASS;PST)", line):
            file.write(iso_code + "\t" + line + "\n")
        elif "SBJV" in line or "PASS" in line:
            continue
        elif re.search(
            r"((V)+\S*PST)|(V.PTCP;PST)|(V.CVB)", line
        ):  # to get only indicative verbs in PST and past participles (CVB for Icelandic)
            file.write(iso_code + "\t" + line + "\n")

file.close()
