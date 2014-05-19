Clim <- function(var_exp, var_obs, memb = TRUE, kharin = FALSE, NDV = FALSE) {
  # This function computes per-pair climatologies from experimental and 
  # observational matrix output from load.
  #
  # Args:
  #   var_exp: Model data:
  #            c(nmod/nexp, nmemb/nparam, nsdates, nltime) up to
  #            c(nmod/nexp, nmemb/nparam, nsdates, nltime, nlevel, nlat, nlon)
  #   var_obs: Observational data: 
  #            c(nobs, nmemb, nsdates, nltime) up to
  #            c(nobs, nmemb, nsdates, nltime, nlevel, nlat, nlon)
  #   memb: TRUE/FALSE (1 climatology for each member). Default = TRUE.
  #   kharin: TRUE/FALSE (if Kharin method is applied or not). Default = FALSE.
  #   NDV: 
  #
  # Returns:
  #   $clim_exp: Matrix with same dimensions as var_exp
  #   $clim_obs: Matrix with same dimensions as var_obs
  #
  # History:
  #   1.0  #  2011-03  (V. Guemas, vguemas@ic3.cat)  #  Original code

  #
  #  Enlarge the number of dimensions of var_exp and var_obs to 7 if necessary
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #
  dimexp <- dim(var_exp)
  dimobs <- dim(var_obs)
  if (length(dimexp) < 4 | length(dimobs) < 4) {
    stop("At least 4 dim needed : c(nexp/nobs, nmemb, nsdates, nltime)") 
  }
  for (jn in 3:max(length(dimexp), length(dimobs))) { 
    if (dimexp[jn] != dimobs[jn]) {
      stop("Wrong input dimensions")
    }
  }
  var_exp <- Enlarge(var_exp, 7)
  var_obs <- Enlarge(var_obs, 7)
  
  #
  #  Find common points to compute climatologies 
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #
  tmp <- MeanListDim(var_obs, dims = 5:7, narm = TRUE)
  tmp2 <- MeanListDim(var_exp, dims = 5:7, narm = TRUE)
  nan <- MeanListDim(tmp, dims = 1:2, narm = FALSE) + Mean1Dim(Mean1Dim(tmp2, 2, 
                                                                    narm = TRUE), 
                                                           1, narm = FALSE)
  for (jdate in 1:dimexp[3]) {
    for (jtime in 1:dimexp[4]) {
      if (is.na(nan[jdate, jtime])) {
        var_exp[, , jdate, jtime, , , ] <- NA
        var_obs[, , jdate, jtime, , , ] <- NA
      }
    }
  }

  #
  #  Compute climatologies 
  # ~~~~~~~~~~~~~~~~~~~~~~~
  #
  out_clim_obs <- Mean1Dim(var_obs, posdim = 3, narm = TRUE)
  dim_clim_obs <- c(dimobs[1:2], dimobs[4:length(dimobs)])

  if (kharin == TRUE) {
    tmp_obs <- Trend(var_obs, posTR = 3)
    tmp_exp <- Trend(var_exp, posTR = 3)
    trend_obs <- array(dim = dim(var_exp))
    trend_exp <- array(dim = dim(var_exp))
    for (jdate in 1:dimexp[3]) {
      trend_exp[, , jdate, , , , ] <- tmp_exp$trend[, , 4, , , 
                                      , ] + jdate * tmp_exp$trend[, , 2, , , , ]
      trend_obs[, , jdate, , , , ] <- InsertDim(InsertDim(MeanListDim(
                                      tmp_obs$trend[, , 4, , , 
                                      , ] + jdate * tmp_obs$trend[, , 2, , , 
                                      , ], c(2, 1)), 1, dimexp[1]), 2,
                                      dimexp[2])
    }
    out_clim_exp <- trend_exp - trend_obs + InsertDim(InsertDim(InsertDim(
                    MeanListDim(out_clim_obs, c(2, 1)), 1, dimexp[1]), 2, 
                                                                dimexp[2]), 3, 
                                                      dimexp[3])
    dim_clim_exp <- dimexp
  } else if (NDV == TRUE) {
    iniobs <- InsertDim(SelIndices(var_obs, 4, c(1, 1)), 4, dimobs[4])
    iniexp <- InsertDim(SelIndices(var_exp, 4, c(1, 1)), 4, dimexp[4])
    tmp_obs <- Regression(var_obs, iniobs, posREG = 3)
    tmp_exp <- Regression(var_exp, iniexp, posREG = 3)
    reg_obs <- array(dim = dim(var_exp))
    reg_exp <- array(dim = dim(var_exp))
    for (jdate in 1:dimexp[3]) {
      reg_exp[, , jdate, , , , ] <- tmp_exp$regression[, , 4, , , 
                                    , ] + iniexp[, , jdate, , , 
                                    , ] * tmp_exp$regression[, , 2, , , , ]
      reg_obs[, , jdate, , , , ] <- InsertDim(InsertDim(MeanListDim(
                                    tmp_obs$regression[, , 4, , , 
                                    , ] + iniobs[, , jdate, , , 
                                    , ] * tmp_obs$regression[, , 2, , , , ], 
                                    c(2, 1)), 1, dimexp[1]), 2, dimexp[2])
    }
    out_clim_exp <- reg_exp - reg_obs + InsertDim(InsertDim(InsertDim(
                    MeanListDim(out_clim_obs, c(2, 1)), 1, dimexp[1]), 2, 
                    dimexp[2]), 3, dimexp[3])
    dim_clim_exp <- dimexp
  } else {
    out_clim_exp <- Mean1Dim(var_exp, posdim = 3, narm = TRUE)
    dim_clim_exp <- c(dimexp[1:2], dimexp[4:length(dimexp)])
  }

  if (memb != TRUE) {
    out_clim_obs <- Mean1Dim(out_clim_obs, posdim = 2, narm = TRUE) 
    out_clim_exp <- Mean1Dim(out_clim_exp, posdim = 2, narm = TRUE)
    dim_clim_exp <- dim_clim_exp[-2]
    dim_clim_obs <- dim_clim_obs[-2]
  }

  #
  #  Reduce the number of dimensions to the original one 
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # 

  clim_exp <- array(dim = dim_clim_exp)
  clim_exp[] <- out_clim_exp
  clim_obs <- array(dim = dim_clim_obs)
  clim_obs[] <- out_clim_obs

  #
  #  Outputs
  # ~~~~~~~~~
  #
  invisible(list(clim_exp = clim_exp, clim_obs = clim_obs))
}