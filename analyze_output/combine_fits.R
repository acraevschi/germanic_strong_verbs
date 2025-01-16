require(rstan)

# may use a lot of RAM!
for (model_type in c("simmap_verb_hierarchy", "simmap_no-hierarchy")){
  fits.lst <- list()
  all.fits.dirs <- list.files(
    paste("../analysis_results/", model_type, sep=""),
    full.names = TRUE
  )
  for (fit.path in all.fits.dirs){
    fit <- readRDS(fit.path)

    fits.lst <- append(fits.lst, fit)
  }

  combined.fit <- sflist2stanfit(fits.lst)
  saveRDS(combined.fit,
          paste(
            "../analysis_results/", model_type, "/combined_fit.rds", 
            sep="")
          )
}


