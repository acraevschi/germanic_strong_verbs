#!/usr/bin/env Rscript

require(phytools)
require(rstan)
require(data.table)

if (!dir.exists(output_dir)) {
 dir.create(output_dir, recursive = TRUE)
}

### Prepare simmap summary tree ### 
file.dir <- paste("summ_simmap_mcc.rds", sep="")

tree <- readRDS(file.dir)

# rescale the tree to make 1 unit of branch length = 1 millennia
tree$edge.length <- tree$edge.length/1000
###################################

patterns <- read.csv("../unimorph_wikt_patterns.csv", encoding = "UTF-8", stringsAsFactors = F)
patterns <- data.table(patterns)

patterns <- patterns[!lang %in% c("gsw", "odt", "gml", "gmh")]

patterns$simple_pattern_sing[patterns$simple_pattern_sing=="" & patterns$form == ""] <- "M"
patterns$simple_pattern_sing[patterns$simple_pattern_sing==""] <- "M1" 
patterns$simple_pattern_sing_int <- as.integer(factor(patterns$simple_pattern_sing))
n_states <- length(unique(patterns$simple_pattern_sing_int))

wide_data <- dcast(patterns, lang ~ proto_gem_form, 
                   value.var = "simple_pattern_sing_int", fun.aggregate = function(x) x[1L])

wide_data <- wide_data[match(tree$tip.label, wide_data$lang), ]
wide_data <- wide_data[,-1]

rownames(wide_data) <- tree$tip.label

to.matrix_mod <- function(x){ # treats missing data properly
  data_matrix <- to.matrix(x, seq=c(1:n_states))
  
  for (i in 1:nrow(data_matrix)) {
    if (data_matrix[i, n_states-1] == 1) {
      data_matrix[i, ] <- rep(1, ncol(data_matrix))
    }
  }
  
  data_matrix <- data_matrix[, 1:(n_states-2)] # remove extra states that stand for missing states
  print(data_matrix)
  # that will leave the row that had initial state M1 with row full of zeros
  ### these are the rows that have form in wiktionary but no conjugation, hence they can be in whatever state but not (D)ead
  for (i in 1:nrow(data_matrix)) {
    if (all(data_matrix[i, ] == 0)) {
      data_matrix[i, ] <- c(rep(1, ncol(data_matrix) - 1), 0)
    }}

  colnames(data_matrix) <- c("AAA", "AAB", "ABA", "ABB", "ABC", "D")
  return(data_matrix) 
  
}
  
tree <- reorder.phylo(tree,'pruningwise')

lst_chars <- lapply(wide_data, function(x) to.matrix_mod(x))
parent <- tree$edge[,1]
child <- tree$edge[,2]
b.lens <- tree$edge.length  
b.lens[b.lens==0] <- .01
N <- length(unique(c(parent,child)))
T <- length(child[which(!child %in% parent)])
J <- length(unique(patterns$simple_pattern_sing_int)) - 2 # remove extra dummy characters
B <- length(parent)
segment.states <- names(tree$edge.length)

states.bin <- lapply(lst_chars, function(x) rbind(x, matrix(1,nrow=N-T, ncol=J)))
S <- length(states.bin) # number of characters

# If the data is missing, the row would be full of zeros. If the line is full of zeros, make it likelihood of 1 (check Chundra's tutorial)
#model_path = "analysis/models_code/simmap_no-hierarchy.stan"

fit_dir <- paste("../analysis_results/", model_type, "/combined_fit.rds", sep="")
fit <- readRDS(fit_dir)

mu <- extract(fit)$mu
log_death_rate <- extract(fit)$log_death_rate

Z = array(0,dim=c(S,J))

n.samples <- 10000

inds <- sample(1:nrow(mu), n.samples)

for (i in inds) {
  data.list <- list(N=N,
                    T=T,
                    B=B,
                    J=J,
                    brlen=b.lens,
                    child=child,
                    parent=parent,
                    tiplik=states.bin,
                    S=S,
                    segment_states=ifelse(segment.states=="no", 1, 2),
                    mu=mu[i,],
                    log_death_rate=log_death_rate[i]
  )
  fit.rec <- stan(
    file = "anc_rec/anc_rec.stan", 
    data=data.list, 
    algorithm = "Fixed_param",
    iter=1,chains=1
    )
  z <- extract(fit.rec)$z[1,]
  z <- to.matrix(z,seq=as.numeric(c(1:J)))
  Z <- Z + z
}

colnames(Z) <- c("AAA", "AAB", "ABA", "ABB", "ABC", "D")
rownames(Z) <- names(lst_chars)
Z.norm <- Z/n.samples

max_colnames <- apply(Z.norm, 1, function(row) colnames(Z.norm)[which.max(row)])
# print(max_colnames)

write.csv(Z.norm, paste("anc_rec/combined_anc_rec.csv", sep=""), row.names = TRUE)

