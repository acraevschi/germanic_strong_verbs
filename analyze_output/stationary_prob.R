require(phytools)
require(rstan)
require(ggplot2)
require(ggpubr)
require(rethinking)
require(dplyr)
require(latex2exp)
require(reshape2)
require(HDInterval)
require(ggridges)

# Create Q matrix from vector of parameter values
make.Q.matrix <- function(vec) { 
  Q <- matrix(0, nrow = 5, ncol = 5)
  k <- 1
  for (i in 1:5) {
    for (j in 1:5) {
      if (i == j) next
      Q[i, j] <- vec[k]
      k <- k + 1 
    }
  }
  for (i in 1:5) {
    Q[i, i] <- -sum(Q[i, ])
  }
  rownames(Q) <- colnames(Q) <- c("AAA", "AAB", "ABA", "ABB", "ABC")
  return(Q)
}

# Compute stationary probabilities
get.stationary.probs <- function(Q) {
  svd.decomp <- svd(Q)
  return(svd.decomp$u[,5] / sum(svd.decomp$u[,5]))
}

compute_plots <- function(model_type, n_samples = 1000) {
  combined.fit <- readRDS(
    paste("../analysis_results/", model_type, "/combined_fit.rds", sep = "")
  )
  
  pars_name <- "mu"
  post <- extract(combined.fit, pars = pars_name)[[1]]
  set.seed(1997)
  sample.inds <- sample(1:nrow(post), n_samples)
  
  Q.no <- exp(post[sample.inds, 1:20])
  Q.yes <- exp(post[sample.inds, 21:40])
  
  list.no <- lapply(1:n_samples, function(i) make.Q.matrix(Q.no[i, ]))
  list.yes <- lapply(1:n_samples, function(i) make.Q.matrix(Q.yes[i, ]))
  
  list.no.svd <- lapply(list.no, get.stationary.probs)
  list.yes.svd <- lapply(list.yes, get.stationary.probs)
  
  states <- c("AAA", "AAB", "ABA", "ABB", "ABC")
  df_diff <- data.frame(matrix(ncol = length(states), nrow = n_samples))
  colnames(df_diff) <- paste0(states, ".diff")
  
  for (j in 1:length(states)) {
    for (i in 1:n_samples) {
      df_diff[i, j] <- list.yes.svd[[i]][j] - list.no.svd[[i]][j]
    }
  }
  
  plot_list <- lapply(states, function(state) {

    # Calculate the percentage of samples above and below zero
    pct_above <- round(mean(df_diff[[paste0(state, ".diff")]] > 0) * 100, 1)
    
    pct_below <- 100 - pct_above
    if (pct_above > pct_below) {
      label_text <- paste0("Prop. of samples\n above 0: ", pct_above, "%")
    } else {
      label_text <- paste0("Prop. of samples \nbelow 0: ", pct_below, "%")
    }
    
    if (state == "AAB"){
      x_axis_pos <- Inf
      hjust_value <- 2
    } else {
      x_axis_pos <- -Inf
      hjust_value <- -0.6
    }
    
    ggplot(df_diff) + 
      geom_density_ridges_gradient(aes_string(x = paste0(state, ".diff"), y = 0, fill = "stat(quantile)"), 
                                  alpha = 0.75, quantile_lines = TRUE, quantile_fun = hdi) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
      xlab(TeX(paste0("$\\Delta$Posterior stationary probability of ", state))) +
      ylab("") +
      scale_fill_manual(values = c("#0072B2", "#E69F00", "#0072B2"), guide = "none") +
      annotate("text", x = x_axis_pos, y = Inf, hjust = hjust_value, vjust = 1.35,
              label = label_text, 
              size = 4, color = "black") +
      theme_classic()
  })
  return(plot_list)
}

# Main Loop
for (model_type in c("simmap_verb_hierarchy", "simmap_no-hierarchy")) {
  plots <- compute_plots(model_type)
  
  # Interleave subplots by row
  plots <- annotate_figure(
    ggarrange(
      plotlist = plots, 
      ncol = 1, nrow = 5
    ), 
    left = text_grob("Density", rot = 90, size = 14)
  )
  output_name <- paste("../analysis_results/figures/", 
                      model_type, "/stationary_prob.pdf", sep = "")
  
  ggsave(filename = output_name, plot = plots, width = 7, height = 10)

}
