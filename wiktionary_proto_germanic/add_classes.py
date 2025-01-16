import pandas as pd

classes = pd.read_csv("proto_classes.csv", encoding="UTF-8")
forms = pd.read_csv("gem_unimorph_df.csv", encoding="UTF-8")

forms["class_n"] = forms["proto_gem_form"].map(
    classes.set_index("proto_gem_form")["class_n"]
)

forms.to_csv("gem_unimorph_df.csv", encoding="UTF-8", index=False)
