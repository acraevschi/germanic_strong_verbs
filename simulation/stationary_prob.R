require(phytools)
require(rstan)
require(ggplot2)
require(ggpubr)
require(rethinking)
require(dplyr)
require(latex2exp)
library(reshape2)

# create a Q matrix out of vector of parameter values
make.Q.matrix <- function(vec){ 
  Q <- matrix(0, nrow = 5, ncol=5)
  k = 1
  for (i in 1:5){
    for (j in 1:5){
      if (i==j) next
      Q[i,j] = vec[k]
      k <- k + 1 
    }
  }
  
  for (i in 1:5){
    Q[i,i] <- -sum(Q[i,])
  }
  
  rownames(Q) = colnames(Q) = c("AAA", "AAB", "ABA", "ABB", "ABC")
  return(Q)
}

get.stationary.probs <- function(Q){
  svd.decomp <- svd(Q)
  return(svd.decomp$u[,5]/sum(svd.decomp$u[,5]))
}

# Function to create density plots
create_density_plot <- function(df_diff, state) {
  ggplot(df_diff) + 
    geom_density(aes(x = !!sym(paste0(state, ".diff")), fill="yes", alpha=0.5)) +
    xlab(TeX(paste0("$\\Delta$Posterior stationary probability of ", state))) +
    ylab("") +
    guides(alpha="none", fill="none") +
    theme_minimal()
}

for (author_name in c("chang_etal", "heggarty_etal")) {
  combined.fit <- readRDS(paste0("simulation/", author_name, "/combined_fit.rds"))
  
  pars_name <- "mu"
  post <- extract(combined.fit, pars = pars_name)[[1]]
  
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
  for (i in 1:n_samples) {
    for (j in 1:length(states)) {
      df_diff[i, j] <- list.yes.svd[[i]][j] - list.no.svd[[i]][j]
    }
  }
  
  # Generate density plots for all states
  plot_list <- lapply(states, function(state) create_density_plot(df_diff, state))
  
  # Arrange the plots in a grid
  all_plots <- ggarrange(plotlist = plot_list, ncol = 2, nrow = 3)
  
  # Add annotation to the combined plot
  all_plots <- annotate_figure(
    all_plots, 
    left = text_grob("Density", rot = 90)
  )
  
  # Save the output
  output_name <- paste0("simulation/figures/", author_name, ".jpeg")
  ggsave(filename = output_name, plot = all_plots, width = 2500, height = 1500, units = "px")
}
