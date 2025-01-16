#!/usr/bin/env Rscript

require(phytools)
require(rstan)
require(data.table)

#################################################################################

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the correct number of arguments is provided
if (length(args) != 1) {
  print_usage()
  stop("Error: Incorrect number of arguments.")
}

# Assign arguments to variables
t <- as.numeric(args[1])

#################################################################################

seed.num <- t 
n_verbs <- 100 # number of characters to simulate
n_samples <- 50 # num of trees used for sample 
matrix_size <- 6 # state space (5 states + death char)


### Prepare simmap summary tree ### 
file.dir <- paste("analysis_results/tam_simmap_summary/", 
                  "summ_simmap_t_", t, ".rds", sep="")

tree <- readRDS(file.dir)

tree$edge.length <- tree$edge.length/1000

###################################

char.states <- list() # store the character states
# Q.list <- list() # list of Q matrices used for verbs

hyper_mu <- 0.5
hyper_sigma <- 0.1

set.seed(1) # for generating the random distribution
hyper_log.normal <- exp(rnorm(1e4, mean = hyper_mu, sd = hyper_sigma))

death_rate <- 0.05 # arbitrary small rate

for (v in 1:n_verbs){
  Q <- matrix(0, nrow = matrix_size, ncol = matrix_size)
  for (i in 1:(matrix_size-1)){
    for (j in 1:(matrix_size)){
      if (i == j) next
      set.seed(i*j*v+seed.num)
      Q[i, j] <- sample(hyper_log.normal, 1)
    }
  }
  
  for (i in 1:(matrix_size-1)){
    Q[matrix_size, i] <- 1e-5
    Q[i, matrix_size] <- death_rate
  }
  
  diag(Q) <- -rowSums(Q)
  rownames(Q) = colnames(Q) <- c("AAA", "AAB", "ABA", "ABB", "ABC", "D")
  # Q.list[[v]] <- Q
  # print(Q)
  anc_states <- c(0, 0, 0, 0 , 1, 0) # states at the root, make it ABC as this is the most frequent state for Proto-Germanic
  names(anc_states) <- rownames(Q)
  set.seed(i*j*v+seed.num)
  sim.hist <- sim.history(tree, Q, nsim = 1, anc=anc_states, direction="row_to_column")
  char.states[[v]] <- sim.hist$states
}

char.states.int <- lapply(char.states, function(x) as.integer(factor(x)))
char.matrix <- lapply(char.states.int, function(x) to.matrix(x, seq=1:matrix_size))

###################################

parent <- tree$edge[,1]
child <- tree$edge[,2]
b.lens <- tree$edge.length  
b.lens[b.lens==0] <- .01
N <- length(unique(c(parent,child)))
T <- length(child[which(!child %in% parent)])
J <- matrix_size
B <- length(parent)
segment.states <- names(tree$edge.length)

states.bin <- lapply(char.matrix, function(x) rbind(x, matrix(1,nrow=N-T, ncol=J)))
S <- length(states.bin) # number of characters

model_path = "analysis/models_code/simmap_verb_hierarchy.stan"

data.list <- list(N=N,
                  T=T,
                  B=B,
                  J=J,
                  brlen=b.lens,
                  child=child,
                  parent=parent,
                  tiplik=states.bin,
                  segment_states=ifelse(segment.states=="no", 1, 2),
                  S=S)

fit <- stan(
  file = model_path,
  data = data.list,
  iter = 3000,
  chains = 4,
  cores = 24,
  pars=c("log_lik", "log_death_rate", "mu"),
  include=TRUE,
  seed=t
)

output_dir <- paste("simulation/", author_name, sep="")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

saveRDS(fit, paste(output_dir, "/tree_", t, ".rds", sep=""))
