require(phytools)
require(rstan)
require(ggplot2)
require(ggpubr)
require(rethinking)
require(dplyr)
require(latex2exp)
library(reshape2)

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
model_type <- "simmap_verb_hierarchy_root"

combined.fit <- readRDS(
  paste(
    "../analysis_results/", model_type, "/mcc_tree_root.rds", 
    sep=""
    )
  )

# parameters of interest have different names in the two models
pars_name <- "mu"

post <- extract(combined.fit, pars=pars_name)
post <- post[[1]]
# rm(combined_fit)

n_samples <- 1000
sample.inds <- sample(1:nrow(post), n_samples)


Q.no <- exp(post[sample.inds,1:20]) # indices for "no" Q matrix
Q.yes <- exp(post[sample.inds,21:40]) # indices for "yes" Q matrix

list.no <- list() # list of Q.no matrices
list.yes <- list() # list of Q.yes matrices

for (i in 1:n_samples){
  list.no[[i]] <- make.Q.matrix(Q.no[i,])
  list.yes[[i]] <- make.Q.matrix(Q.yes[i,])
}

list.no.svd <- lapply(list.no, get.stationary.probs)
list.yes.svd <- lapply(list.yes, get.stationary.probs)

AAA.no <- c()
AAB.no <- c()
ABA.no <- c()
ABB.no <- c()
ABC.no <- c()

AAA.yes <- c()
AAB.yes <- c()
ABA.yes <- c()
ABB.yes <- c()
ABC.yes <- c()

for (i in 1:n_samples){
  # For 'no' samples
  AAA.no <- c(AAA.no, list.no.svd[[i]][1])
  AAB.no <- c(AAB.no, list.no.svd[[i]][2])
  ABA.no <- c(ABA.no, list.no.svd[[i]][3])
  ABB.no <- c(ABB.no, list.no.svd[[i]][4])
  ABC.no <- c(ABC.no, list.no.svd[[i]][5])
  
  # For 'yes' samples
  AAA.yes <- c(AAA.yes, list.yes.svd[[i]][1])
  AAB.yes <- c(AAB.yes, list.yes.svd[[i]][2])
  ABA.yes <- c(ABA.yes, list.yes.svd[[i]][3])
  ABB.yes <- c(ABB.yes, list.yes.svd[[i]][4])
  ABC.yes <- c(ABC.yes, list.yes.svd[[i]][5])
}

plot1 <- ggplot() + 
  geom_density(aes(x=AAA.yes - AAA.no, fill="yes", alpha=0.5)) +
  xlab(TeX("$\\Delta$Posterior stationary probability of AAA")) +
  ylab("") +
  guides(alpha="none", fill="none") +
  theme_minimal() 

plot2 <- ggplot() + 
  geom_density(aes(x=AAB.yes - AAB.no, fill="yes", alpha=0.5)) +
  xlab(TeX("$\\Delta$Posterior stationary probability of AAB")) +
  ylab("") +
  guides(alpha="none", fill="none") +
  theme_minimal()

plot3 <- ggplot() + 
  geom_density(aes(x=ABA.yes - ABA.no, fill="yes", alpha=0.5)) +
  xlab(TeX("$\\Delta$Posterior stationary probability of ABA")) +
  ylab("") +
  guides(alpha="none", fill="none") +
  theme_minimal()

plot4 <- ggplot() + 
  geom_density(aes(x=ABB.yes - ABB.no, fill="yes", alpha=0.5)) +
  xlab(TeX("$\\Delta$Posterior stationary probability of ABB")) +
  ylab("") +
  guides(alpha="none", fill="none") +
  theme_minimal()

plot5 <- ggplot() + 
  geom_density(aes(x=ABC.yes - ABC.no, fill="yes", alpha=0.5)) +
  xlab(TeX("$\\Delta$Posterior stationary probability of ABC")) +
  ylab("") +
  guides(alpha="none", fill="none") +
  theme_minimal()


all_plots <- ggarrange(plot1, plot2, plot3, plot4, plot5,
                    ncol = 2, nrow = 3)
                    
all_plots <- annotate_figure(
  all_plots, 
  left = text_grob("Density", rot=90)
  )

output_name <- paste("../analysis_results/figures/", 
                      model_type,".jpeg", 
                      sep="")

ggsave(filename = output_name, plot = all_plots, 
        width = 2500, height = 1500, units = "px")
