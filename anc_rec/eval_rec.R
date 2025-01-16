
author_name <- 'chang_etal'

prediction <- read.csv(
    paste("anc_rec/", author_name, "/combined_anc_rec.csv", sep="")
    )

colnames(prediction)[1] <- "form"

reconstruction <- read.csv(
    "anc_rec/proto_gem_forms/proto_gem_forms.csv", encoding = "UTF-8", stringsAsFactors = F
    )

patterns <- reconstruction$simple_pattern_sing
names(patterns) <- reconstruction$form

argmax.pattern <- apply(prediction[, -1], 1, function(row) {
    colnames(prediction)[which.max(row) + 1]
})

names(argmax.pattern) <- prediction$form

# Align the vectors by their names
common_names <- intersect(names(argmax.pattern), names(patterns))

# Compare the values
matching_count <- sum(argmax.pattern[common_names] == patterns[common_names])

# Print the result
print(paste("Number of matching values:", matching_count))
print(paste("Proportion of matching values:", round(matching_count/nrow(prediction), 2)))
