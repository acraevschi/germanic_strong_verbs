require(ape)
require(Dict)
require(phangorn)
require(phytools)
require(data.table)
require(ggplot2)
require(ggtree)
require(ggpubr)
require(treeio)
require(dplyr)
require(latex2exp)


patterns <- read.csv("../unimorph_wikt_patterns.csv", encoding = "UTF-8", stringsAsFactors=FALSE)
patterns <- data.table(patterns)

patterns <- patterns[!lang %in% c("gsw", "odt", "gml", "gmh")]

patterns$simple_pattern_sing[patterns$simple_pattern_sing==""] <- "?"

### Class_n distribution for 107 verbs

proto_gem_verbs <- patterns %>% 
  distinct(proto_gem_form, .keep_all = TRUE)

class_count <- proto_gem_verbs[, .N, by = class_n]

ggplot(class_count) +
  geom_bar(aes(x=factor(class_n), y=N), stat="identity") +
  labs(x = "Class", y = "") +
  theme_classic()

ggsave(filename="../analysis_results/figures/class_distribution.pdf")

### Distribution of missing verbs per class
missing_paterns <- patterns[Pattern == ""]
lang_missing <- missing_paterns[, .N, by = lang]
lang_missing <- rbind(lang_missing, list("eng", 0))

language_codes <- fread("../support_files/LanguageCodes.tsv")

merged_data <- merge(lang_missing, language_codes[, .(`iso-639-3`, `Canonical name`)],
                     by.x = "lang", by.y = "iso-639-3", all.x = TRUE)

merged_data <- merged_data[order(-N)]

merged_data$prop_miss <- merged_data$N / 107
merged_data$prop_miss <- round(merged_data$prop_miss, 2)


ggplot(merged_data, aes(x = reorder(`Canonical name`, -N), y = N)) + 
  geom_bar(stat = "identity") + 
  # geom_text(aes(label = prop_miss), vjust = -0.3, size=4) +
  labs(x = "", y = "Missing verbs") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(filename="../analysis_results/figures/missing_per_lang.pdf", width = 12, height = 10.1)


### Tree with mapped character states
language_codes <- read.delim("../support_files/LanguageCodes.tsv", stringsAsFactors = FALSE)
iso_to_name <- setNames(language_codes$Canonical.name, language_codes$iso.639.3)

# For visualization purposes, some names are slightly modified
iso_to_name["nob"] <- "Norwegian" 
iso_to_name["nds"] <- "Low\nGerman"
iso_to_name["fry"] <- "West\nFrisian"

trees <- read.nexus("../trees/gem_trees_final.trees")
mcc <- maxCladeCred(trees,rooted=TRUE)

patterns$label <- iso_to_name[patterns$lang]

mcc$tip.label <- iso_to_name[mcc$tip.label]

labels <- c("?", "AAA", "AAB", "ABA", "ABB", "ABC", "Died out")
values <- c("#AA4499", "#332288", "#44AA99", "#88CCEE", "#DDCC77", "#117733", "#CC6677")

set.seed(10)
verbs_show <- sample(patterns$proto_gem_form, 5)
select.patterns <- patterns[proto_gem_form %in% verbs_show]

wide_patterns <- dcast(select.patterns, label ~ proto_gem_form, value.var = "simple_pattern_sing")
wide_patterns_matrix <- as.matrix(wide_patterns[, -1, with = FALSE])
rownames(wide_patterns_matrix) <- wide_patterns$label
colnames(wide_patterns_matrix) <- paste0("*", colnames(wide_patterns_matrix))

p <- ggtree(mcc) + 
  geom_tiplab(size=3.5) 

p <- gheatmap(p, wide_patterns_matrix, offset=5, font.size=4,
  hjust=0.5, colnames_position = "top",
  legend_title = TeX("\\textbf{Pattern}")) +
  scale_fill_manual(values = values, labels = labels, name = "Pattern") +
  theme(legend.position = "inside", legend.position.inside = c(0.05, 0.8),
  legend.key.size = unit(1, "cm"))

ggsave(filename="../analysis_results/figures/tree_char.pdf", plot=p, width = 15, height = 10)

############ Pattern count by language
pattern_count_by_lang <- patterns[, .N, by = .(lang, simple_pattern_sing)]

data_norm <- pattern_count_by_lang %>%
  group_by(lang) %>%
  mutate(proportion = N / sum(N) * 107)


iso_to_name["goh"] <- "Old High\nGerman"

data_norm$lang <- iso_to_name[data_norm$lang]



# Create stacked bar plot
ggplot(data_norm, aes(x = proportion, y = lang, fill = simple_pattern_sing)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = values, labels = labels) +
  labs(
    title = "",
    x = "",
    y = "",
    fill = "Pattern"
  ) +
  theme_classic()
  

ggsave(filename="../analysis_results/figures/pattern_count_by_lang.pdf", width = 14, height = 10)
