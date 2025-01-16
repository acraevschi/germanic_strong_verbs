require(rstan)

# may use a lot of RAM!

fits.lst <- list()
all.fits.dirs <- list.files(
  "simulation/fits",
  full.names = TRUE
)

for (fit.path in all.fits.dirs){
  fit <- readRDS(fit.path)
  
  fits.lst <- append(fits.lst, fit)
}

combined.fit <- sflist2stanfit(fits.lst)

saveRDS(combined.fit, "simulation/fits/combined_fit.rds")
