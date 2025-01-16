require(loo)

# Load combined posterior fit
fit.hierarchical <- readRDS("../analysis_results/simmap_verb_hierarchy/combined_fit.rds")

fit.flat <- readRDS("../analysis_results/simmap_no-hierarchy/combined_fit.rds")

log_lik.hierarhical <- extract_log_lik(
    fit.hierarchical, 
    merge_chains = FALSE
)
r_eff <- relative_eff(exp(log_lik.hierarhical), cores = 8) 
loo_hierarhical <- loo(log_lik.hierarhical, r_eff = r_eff, cores = 8)

log_lik.flat <- extract_log_lik(
    fit.flat, 
    merge_chains = FALSE
)
r_eff <- relative_eff(exp(log_lik.flat), cores = 8) 
loo_flat <- loo(log_lik.flat, r_eff = r_eff, cores = 8)

comparison <- loo_compare(loo_hierarhical, loo_flat)

saveRDS(comparison, "comparison.rds")
saveRDS(loo_hierarhical, "loo_hierarhical.rds")
saveRDS(loo_flat, "loo_flat.rds")
