library(phytools)
library(rstan)
library(ggplot2)
library(ggpubr)
library(dplyr)
library(latex2exp)
library(HDInterval)
library(ggridges)

# Function to create a Q matrix from a vector of rates
make.Q.matrix <- function(vec) {
  stopifnot(length(vec) == 20)
  
  Q <- matrix(0, nrow = n.states, ncol = n.states)
  k <- 1
  for (i in 1:n.states) {
    for (j in 1:n.states) {
      if (i != j) {
        Q[i, j] <- vec[k]
        k <- k + 1
      }
    }
    Q[i, i] <- -sum(Q[i, ])
  }
  
  rownames(Q) <- colnames(Q) <- c("AAA", "AAB", "ABA", "ABB", "ABC")
  return(Q)
}

# Function to calculate entry rates based on a Q matrix
get.entry.rates <- function(Q) {
  states <- colnames(Q)
  svd.decomp <- svd(Q)
  stationary.probs <- svd.decomp$u[, n.states] / sum(svd.decomp$u[, n.states])
  names(stationary.probs) <- states
  
  entry.rates <- numeric(length(states))
  names(entry.rates) <- states
  
  for (i in seq_along(states)) {
    state.i <- states[i]
    stat.probs.state <- stationary.probs[names(stationary.probs) != state.i]
    entry.rates[state.i] <- sum(Q[rownames(Q) != state.i, state.i] * stat.probs.state) / sum(stat.probs.state)
  }
  
  return(entry.rates)
}

compute.rate.differences <- function(entry_rates, exit_rates) {
  diff_rates <- lapply(names(entry_rates$no), function(state) {
    diff.entry <- entry_rates$yes[[state]] - entry_rates$no[[state]]
    diff.exit <- exit_rates$yes[[state]] - exit_rates$no[[state]]
    
    # Calculate percentages
    calculate_annotation <- function(data) {
      pct_above <- round(mean(data > 0) * 100, 1)
      pct_below <- 100 - pct_above
      if (pct_above > pct_below) {
        list(
          label = paste0("Prop. above 0: \n", pct_above, "%"),
          x_pos = max(data) - max(data)/3.5 # Near the right tail
        )
      } else {
        list(
          label = paste0("Prop. below 0:\n", pct_below, "%"),
          x_pos = min(data) + max(data)/4.5  # Near the left tail
        )
      }
    }
    
    entry_annot <- calculate_annotation(diff.entry)
    exit_annot <- calculate_annotation(diff.exit)
    
    list(
      entry = ggplot() + 
        geom_density_ridges_gradient(aes(x = diff.entry, y = 0, fill = stat(quantile)), 
                                     alpha = 0.75, quantile_lines = TRUE, quantile_fun = hdi) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
        xlab(TeX(paste0("$\\Delta$Posterior entry rates to ", state))) + 
        ylab("") +
        scale_fill_manual(values = c("#0072B2", "#E69F00", "#0072B2"), guide = "none") +
        annotate("text", x = entry_annot$x_pos, y = max(density(diff.entry)$y) * 0.8, 
                 label = entry_annot$label, 
                 size = 4, color = "black") +
        theme_classic(),
      
      exit = ggplot() + 
        geom_density_ridges_gradient(aes(x = diff.exit, y = 0, fill = stat(quantile)), 
                                     alpha = 0.75, quantile_lines = TRUE, quantile_fun = hdi) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
        xlab(TeX(paste0("$\\Delta$Posterior exit rates from ", state))) + 
        ylab("") +
        scale_fill_manual(values = c("#0072B2", "#E69F00", "#0072B2"), guide = "none") +
        annotate("text", x = exit_annot$x_pos, y = max(density(diff.exit)$y) * 0.8, 
                 label = exit_annot$label, 
                 size = 4, color = "black") +
        theme_classic()
    )
  })
  names(diff_rates) <- names(entry_rates$no)
  return(diff_rates)
}

# Main analysis loop
analyze_and_plot <- function(model_type) {
  # Load combined fit
  combined.fit <- readRDS(
      paste0("../analysis_results/", model_type, "/combined_fit.rds")
    )
  
  # Extract and process posterior samples
  post <- extract(combined.fit, pars = "mu")[[1]]
  n_samples <- min(1000, nrow(post))
  set.seed(1997)
  sample.inds <- sample(1:nrow(post), n_samples)
  Q.no <- exp(post[sample.inds, 1:20])
  Q.yes <- exp(post[sample.inds, 21:40])
  
  # Initialize rate containers
  entry_rates <- list(no = list(), yes = list())
  exit_rates <- list(no = list(), yes = list())
  states <- c("AAA", "AAB", "ABA", "ABB", "ABC")
  
  for (state in states) {
    entry_rates$no[[state]] <- c()
    entry_rates$yes[[state]] <- c()
    exit_rates$no[[state]] <- c()
    exit_rates$yes[[state]] <- c()
  }
  
  # Calculate entry and exit rates
  for (i in 1:n_samples) {
    matrix.no <- make.Q.matrix(Q.no[i, ])
    matrix.yes <- make.Q.matrix(Q.yes[i, ])
    
    rates.no <- get.entry.rates(matrix.no)
    rates.yes <- get.entry.rates(matrix.yes)
    
    for (state in states) {
      entry_rates$no[[state]] <- c(entry_rates$no[[state]], rates.no[state])
      entry_rates$yes[[state]] <- c(entry_rates$yes[[state]], rates.yes[state])
      exit_rates$no[[state]] <- c(exit_rates$no[[state]], abs(matrix.no[state, state]))
      exit_rates$yes[[state]] <- c(exit_rates$yes[[state]], abs(matrix.yes[state, state]))
    }
  }
  
  # Compute rate differences and create plots
  diff_rates <- compute.rate.differences(entry_rates, exit_rates)
  
  entry_plots <- lapply(diff_rates, `[[`, "entry")
  exit_plots <- lapply(diff_rates, `[[`, "exit")

  all_entry_plots <- annotate_figure(
    ggarrange(plotlist = entry_plots, ncol = 1, nrow = n.states),
    left = text_grob("Density", rot = 90)
  )
  
  all_exit_plots <- annotate_figure(
    ggarrange(plotlist = exit_plots, ncol = 1, nrow = n.states),
    left = text_grob("Density", rot = 90)
  )
  
  # Save plots
  ggsave(paste0("../analysis_results/figures/", model_type, "/entry_rate_diff.pdf"), plot = all_entry_plots, width=7, height=10)
  ggsave(paste0("../analysis_results/figures/", model_type, "/exit_rate_diff.pdf"), plot = all_exit_plots,  width=7, height=10)
}

# Execute for all models
models <- c("simmap_verb_hierarchy", "simmap_no-hierarchy")

for (model in models) {
  analyze_and_plot(model)
}
