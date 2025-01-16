require(data.table)

patterns <- read.csv("../../unimorph_wikt_patterns.csv", encoding = "UTF-8", stringsAsFactors = F)

proto_gem_forms <- unique(patterns$proto_gem_form)

new.cols <- c("form", "PRET.SG", "PRET.PL", "PTCP", "links", 
    "class_n", "Pattern", "simmple_pattern_sing", "simple_pattern_pl")


proto_gem.df <- data.frame(matrix(ncol = length(new.cols), nrow = 107))
colnames(proto_gem.df) <- new.cols

new.links <- c()
forms <- c()
base.link <- "https://en.wiktionary.org/wiki/Reconstruction:Proto-Germanic/"
for (form in proto_gem_forms) {
    link <- paste(base.link, form, sep="")
    new.links <- c(new.links, link)
    forms <- c(forms, form)    
}

proto_gem.df$form <- forms
proto_gem.df$links <- new.links

write.csv(proto_gem.df, "anc_rec/proto_gem_forms/proto_gem_forms.csv", row.names = FALSE)
