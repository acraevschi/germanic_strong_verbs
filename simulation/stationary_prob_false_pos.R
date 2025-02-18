require(phytools)
require(rstan)
require(ggplot2)
require(ggpubr)
require(rethinking)
require(dplyr)
require(latex2exp)
require(reshape2)
require(HDInterval)

n.states <- 5

# create a Q matrix out of vector of parameter values
make.Q.matrix <- function(vec){ 
  Q <- matrix(0, nrow = n.states, ncol=n.states)
  k = 1
  for (i in 1:n.states){
    for (j in 1:n.states){
      if (i==j) next
      Q[i,j] = vec[k]
      k <- k + 1 
    }
  }
  
  for (i in 1:n.states){
    Q[i,i] <- -sum(Q[i,])
  }
  
  rownames(Q) = colnames(Q) = c("AAA", "AAB", "ABA", "ABB", "ABC")
  return(Q)
}

get.stationary.probs <- function(Q){
  svd.decomp <- svd(Q)
  return(svd.decomp$u[,n.states]/sum(svd.decomp$u[,n.states]))
}

false_positive <- 0

for (tree.ind in 1:50) {
  
  fit <- readRDS(paste0("fits/tree_", tree.ind, ".rds"))
  
  pars_name <- "mu"
  post <- extract(fit, pars = pars_name)[[1]]

  set.seed(tree.ind)
  n_samples <- 1000
  sample.inds <- sample(1:nrow(post), n_samples)
  
  # Extract 'no' and 'yes' Q matrices
  Q.no <- exp(post[sample.inds, 1:20])  # indices for 'no' Q matrix
  Q.yes <- exp(post[sample.inds, 21:40]) # indices for 'yes' Q matrix
  
  # Create lists of Q matrices
  list.no <- lapply(1:n_samples, function(i) make.Q.matrix(Q.no[i, ]))
  list.yes <- lapply(1:n_samples, function(i) make.Q.matrix(Q.yes[i, ]))
  
  # Compute stationary probabilities for each sample
  list.no.svd <- lapply(list.no, get.stationary.probs)
  list.yes.svd <- lapply(list.yes, get.stationary.probs)
  
  # State names
  states <- c("AAA", "AAB", "ABA", "ABB", "ABC")
  
  # Create a data frame to store the differences in stationary probabilities
  df_diff <- data.frame(matrix(ncol = length(states), nrow = n_samples))
  colnames(df_diff) <- paste0(states, ".diff")
  
  # Fill the data frame with the differences between 'yes' and 'no' stationary probabilities
  for (j in 1:length(states)) {
    for (i in 1:n_samples) {
      df_diff[i, j] <- list.yes.svd[[i]][j] - list.no.svd[[i]][j]
    }
    ci_state <- hdi(df_diff[, j], credMass = 0.89) # change `credMass` to see false positives for different HDI levels
    if (ci_state[1] * ci_state[2] > 0) {
      print(paste0("False positive for tree ", tree.ind, " state ", states[j]))
      false_positive <- false_positive + 1
    }
  }
}


# False positives under 99% HDI

# [1] "False positive for tree 27 state ABB"

##################################################################

# False positives under 95% HDI

# [1] "False positive for tree 10 state AAA"
# [1] "False positive for tree 27 state ABB"


##################################################################

# False positives under 89% HDI

# [1] "False positive for tree 8 state ABC"
# [1] "False positive for tree 10 state AAA"
# [1] "False positive for tree 10 state AAB"
# [1] "False positive for tree 27 state ABB"
# [1] "False positive for tree 30 state ABA"
# [1] "False positive for tree 36 state ABC"
