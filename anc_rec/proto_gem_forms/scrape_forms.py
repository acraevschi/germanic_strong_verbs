import requests
from lxml import etree
import pandas as pd
import time


def scrape_inflection(url):

    response = requests.get(url)
    html_content = response.content
    tree = etree.HTML(html_content)
    xpath_3sg_past = "/html/body/div[3]/div[3]/div[5]/div[1]/div[7]/div[2]/table/tbody/tr[15]/td[1]/span/a"
    xpath_1pl_past = "/html/body/div[3]/div[3]/div[5]/div[1]/div[7]/div[2]/table/tbody/tr[18]/td[1]/span/a"
    xpath_ptcp = "/html/body/div[3]/div[3]/div[5]/div[1]/div[7]/div[2]/table/tbody/tr[23]/td[2]/span/a"
    try:
        sg3_past = tree.xpath(xpath_3sg_past)
        pl1_past = tree.xpath(xpath_1pl_past)
        ptcp = tree.xpath(xpath_ptcp)

        return sg3_past[0].text, pl1_past[0].text, ptcp[0].text
    except:
        time.sleep(2)
        try:
            sg3_past = tree.xpath(xpath_3sg_past)
            pl1_past = tree.xpath(xpath_1pl_past)
            ptcp = tree.xpath(xpath_ptcp)

            return sg3_past[0].text, pl1_past[0].text, ptcp[0].text
        except:
            return None, None, None


proto_gem = pd.read_csv("anc_rec/proto_gem_forms/proto_gem_forms.csv", encoding="utf-8")
proto_gem["PRET.SG"], proto_gem["PRET.PL"], proto_gem["PTCP"] = zip(
    *proto_gem["links"].map(scrape_inflection)
)

proto_gem["PRET.SG"] = proto_gem["PRET.SG"].apply(
    lambda x: x.replace("*", "") if x else x
)
proto_gem["PRET.PL"] = proto_gem["PRET.PL"].apply(
    lambda x: x.replace("*", "") if x else x
)
proto_gem["PTCP"] = proto_gem["PTCP"].apply(lambda x: x.replace("*", "") if x else x)

proto_gem_class = pd.read_csv("../../unimorph_wikt_patterns.csv", encoding="utf-8")

proto_gem = proto_gem.merge(
    proto_gem_class[["proto_gem_form", "class_n"]],
    how="left",
    left_on="form",
    right_on="proto_gem_form",
)
proto_gem.drop(columns=["proto_gem_form"], inplace=True)

proto_gem.drop(columns=["class_n_x"], inplace=True)
proto_gem.rename(columns={"class_n_y": "class_n"}, inplace=True)
proto_gem.drop_duplicates(inplace=True)

proto_gem.to_csv("proto_gem_forms.csv", index=False, encoding="utf-8")
