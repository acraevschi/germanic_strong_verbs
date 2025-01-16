require(phytools)
require(ape)
require(Dict)

trees <- read.nexus('gem_trees_cleaned.trees')

mapping_lang_iso <- Dict$new(
  Gothic="got", Icelandic="isl", Faroese="fao", Norwegian="nob",
  Danish="dan", Swedish="swe", OldSaxon="osx", Old_High_German="goh",
  German="deu", Dutch="nld", Frisian="fry", LowGerman="nds",
  Old_English="ang", English="eng"
)

add_langs <- function(a.tree){
  possible_values <- c(1, 2)
  # Generate a random integer with a uniform distribution
  high.german.mrca <- getMRCA(a.tree, c("Old_High_German", "German"))
  b.len.mrca <- a.tree$edge.length[which(a.tree$edge[,2]==high.german.mrca)]
  b.len.german <- a.tree$edge.length[which(a.tree$edge[,2]==which(a.tree$tip.label=='German'))]
  branch.pos <- runif(1, 0.01, b.len.mrca)
  branch.len <- b.len.german + branch.pos
  new_tree <- bind.tip(a.tree, "LowGerman", edge.length=branch.len, where=high.german.mrca, position=branch.pos)
  # make Old Saxon branch length roughly equal to Old High German:
  b.len.saxon <- abs(a.tree$edge.length[which(a.tree$edge[,2]==which(a.tree$tip.label=="Old_High_German"))] + rnorm(1, 0, 0.1))
  branch.pos <- runif(1, branch.len-b.len.mrca, branch.len)
  lowgerm.id <- which(new_tree$tip.label=="LowGerman")
  new_tree <- bind.tip(new_tree, "OldSaxon", edge.length=b.len.saxon, where=lowgerm.id, position=branch.pos)
  
  # just in case there are accidental zeros in the branch lengths
  new_tree$edge.length[which(new_tree$edge.length == 0)] <- 0.01
  
  new_tree$tip.label <- sapply(new_tree$tip.label, function(x) mapping_lang_iso[x])
  
  return(new_tree)
}

new_trees <- lapply(trees, add_langs)

write.nexus(new_trees, file='gem_trees_final.trees')
