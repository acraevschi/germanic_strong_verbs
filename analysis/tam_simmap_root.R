#!/usr/bin/env Rscript

require(phytools)
require(rstan)
require(data.table)


trees <- read.nexus(paste0("../trees/gem_trees_final.trees"))
tree <- phangorn::mcc(trees)
rm(trees)

# rescale the tree to make 1 unit of branch length = 1 millennia
tree$edge.length <- tree$edge.length/1000

tree$root.edge <- 1/1000 # add one year to the root
tree <- rootedge.to.singleton(tree)
tree <- reorder.phylo(tree, 'pruningwise')

root.ind <- length(tree$tip.label) + 1 # root index is the first after the tips in "pruningwise" order
tree <- bind.tip(tree, "Proto-Germanic", edge.length = 0.5/1000, 
    where = root.ind, position = 0)

############ SIMMAP #####################



data <- read.csv("../tam_char.csv", encoding = "UTF-8")
data <- rbind(data, list(lang="Proto-Germanic", Perfect_narr_past="no"))
data <- data.table(data)

data <- data[!lang %in% c("gsw", "odt", "gml", "gmh")]

n_states <- length(unique(data$Perfect_narr_past))

data$Perfect_narr_past <- factor(data$Perfect_narr_past)
perfect_char <- setNames(data$Perfect_narr_past, data$lang)

n_samples <- 100 # for simmap

simmap_lst <- list()
tree <- reorder.phylo(tree,'pruningwise')

simmap_lst <- make.simmap(tree, perfect_char, model='ARD', nsim = n_samples,
                                pi=c(1, 0)) # set the root to have "no"

multi.simmap <- densityMap(simmap_lst, res = 100, plot = FALSE)
multi.simmap <- multi.simmap$tree
singleton.simmap <- map.to.singleton(multi.simmap)

singleton.simmap <- reorder.phylo(singleton.simmap, order = "pruningwise")
curr.states <- as.integer(names(singleton.simmap$edge.length))

state.names <- ifelse(curr.states > max(curr.states)/2, "yes", "no")
names(singleton.simmap$edge.length) <- state.names

nodes.to.keep <- c()
for (i in 1:(nrow(singleton.simmap$edge) - 2)) { # the last two edges are edges of the root, which has no parent
    state1 <- names(singleton.simmap$edge.length)[i]
    where.diff <- which(singleton.simmap$edge[,2]==singleton.simmap$edge[i,1])
    state2 <- names(singleton.simmap$edge.length)[where.diff]
    if (state1 != state2) {
    nodes.to.keep <- c(nodes.to.keep,singleton.simmap$edge[i,1])
    }
}

dummy.br.len <- .001
# before binding, edge.length still contains states
for (n in nodes.to.keep) {
    singleton.simmap <- bind.tip(singleton.simmap,
                                paste('dummy_tip_', n, sep=''),
                                edge.length=dummy.br.len,where=n
    )
}

singleton.simmap <- collapse.singles(singleton.simmap)

dummy.tips <- which(grepl('dummy_',singleton.simmap$tip.label))

transition.nodes <- singleton.simmap$edge[which(singleton.simmap$edge[,2] %in% dummy.tips),1]

singleton.simmap <- drop.tip(singleton.simmap,singleton.simmap$tip.label[dummy.tips],collapse.singles=F)

num.tips <- length(singleton.simmap$tip.label)
num.total.nodes <- num.tips + singleton.simmap$Nnode

all.states <- rep(NA, length(singleton.simmap$edge.length))

original.states <- c()

for (i in 1:num.tips){
    lang.name <- singleton.simmap$tip.label[i]
    state.val <- ifelse(as.integer(perfect_char[lang.name]) == 1, "no", "yes")
    original.states <- c(original.states, state.val)
}

singleton.simmap <- reorder.phylo(singleton.simmap, "pruningwise")

child <- singleton.simmap$edge[,2]
parent <- singleton.simmap$edge[,1]

### continue here
for (i in 1:num.tips){
    edge.ind <- which(child == i)
    all.states[edge.ind] <- original.states[i]
}

# go in reverse order and check the state of child of parent=i, 
# and assign parent the state of the child if n.descends per parent is equal to 2 or 
# the other state if n.descends is 1 

for (i in length(singleton.simmap$edge.length):num.tips+2){ # +2 to avoid touching the tips and the root
    edge.ind <- which(child == i)
    children.of.parent <- which(parent == i)
    children.states <- all.states[children.of.parent]
    if (any(is.na(children.states))) print("There were NA values")
    if (length(children.states) == 1){
    all.states[edge.ind] <- ifelse(children.states == "yes", "no", "yes")
    next
    }
    if (length(children.states) == 2){
    all.states[edge.ind] <- children.states[1]
    next
    }
}

names(singleton.simmap$edge.length) <- all.states
singleton.simmap <- reorder.phylo(singleton.simmap, "pruningwise")

output_dir <- paste("../analysis_results/tam_simmap_root", sep="")
if (!dir.exists(output_dir)) dir.create(output_dir)


saveRDS(
    singleton.simmap, 
    paste(output_dir,
        "/summ_simmap_mcc", ".rds", sep="")
    )
