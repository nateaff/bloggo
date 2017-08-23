## ----global_options, echo = FALSE----------------------------------------
knitr::opts_chunk$set(
       knitr::opts_chunk$set(cache=TRUE),
       fig.align = 'center', 
       echo=TRUE, 
       warning=FALSE, 
       message=FALSE,   
       results = "hide",
       fig.width = 6.5, 
       fig.height = 6.5,
       dev = 'png')

## ----cauchy--------------------------------------------------------------
library(RandomFields)
library(dplyr)

set.seed(1)

# Convenience wrapper for Cauchy generator
cauchy2D <- function(alpha, beta){
  mod <- suppressWarnings(RandomFields::RMgencauchy(alpha, beta))
  function(n){
    y = x = seq(0, 1, length.out = n)
    # Returns R4 object
    xy = RandomFields::RFsimulate(mod, x = x, y = y, RFoptions(spConform = FALSE))
    xy@data
  } 
}

## ----2Dplot, fig.cap = "Cauchy process labeled by fractal dimension (D) and Hurst parameter (H)."----
# Dimension of field
n = 100
# Create a 3 X 3 grid of parameters  
params <- seq(.3, 1.6, length.out = 3)
# Transform function parameters to fractal dim. and Hurst parameters
to_hurst <- function(beta)  1- beta/2
to_fd <- function(alpha)  2 - alpha/2
coeffs <- expand.grid(to_fd(params), to_hurst(params)) %>%  
          apply(., 2, round, digits = 2) 

xs <- params %>%
      expand.grid(., .)  %>% 
      apply(., 1, function(x) cauchy2D(x[1], x[2])) %>% 
      lapply(., function(x) x(n)) %>% 
      lapply(., data.matrix) %>%
      lapply(. , matrix, ncol = n, byrow = TRUE) 
 
# Plotting convenience functions
add_text <- function(k){
  mtext(side = 1, cex = 0.9, line = 0.5,
        paste0("D: ", coeffs[k, 1], "    ","H: ", coeffs[k, 2]))
}

plot2D <- function(k){
  image(xs[[k]], col = viridis::viridis(256), axes = FALSE)    
  add_text(k)
}

par(mfrow = c(3,3), mar = c(2,1,1,1))
layout(matrix(c(1:9), nrow = 3, byrow = TRUE))
out <- lapply(1:9, plot2D) 


## ----transects, fig.cap = "Cross sections of 2D Cauchy process."---------
par(mfrow = c(3,3), mar = c(2,1,1,1))
plot_transects <- function(k){
  plot(
       xs[[k]][, 10], 
       col = viridis::viridis(10)[3], 
       type = 'l',
       lwd = 1.6,  
       axes = FALSE
       )
  add_text(k)
}

# plot transects
out <- lapply(1:9, function(k) plot_transects(k))


## ----correlation, fig.cap = "Autocorrelation function for lags h =  0-20"----

par(mfrow = c(3,3), mar = c(2,1,1,1))
out <- lapply(xs, function(x) acf(x[, 1], plot = FALSE)) %>% 
       lapply(., plot, yaxt = 'n') 

## ----grid-estimate, fig.width = 6.5, fig.height = 5, fig.caption = "Fractal dimension estimate and theoretical Hurst parameter for the nine transect time series."----

# Compute fractal dimension
fractal_dim <- function(x) {
  res <- fractaldim::fd.estimate(x, methods = "variogram") 
  res$fd  
}

transects <- lapply(1:9, function(k) xs[[k]][, 10])

plot(coeffs[, 2], lapply(transects, fractal_dim),  
            pch = 15,
            cex = 1.7,
            col = viridis::viridis(10)[3], 
            xlab = "Hurst Parameter", 
            ylab = "Fractal Dimension Estimate")

## ----arimasim, fig.cap = "Sample from each group ARMA simulations.", fig.width = 5, fig.height = 4, echo = TRUE----
set.seed(1)
reps = 50
t3 <- replicate(reps, arima.sim(n = 500, list(ar = c(0.5, -0.2), ma = c(-5, 0, 5))))
t2 <- replicate(reps, arima.sim(n = 500, list(ar = c(0.8, -0.2), ma = c(-5, 0, 5))))
t1 <- replicate(reps, arima.sim(n = 500, list(ar = c(1.1, -0.2), ma = c(-5, 0, 5))))  

ts_list <- list(t1, t2, t3)
pal = viridis::viridis(50)[c(2, 25, 45)] 

# Sample plot of each function
plot_ts <- function(k){
  plot(
        ts_list[[k]][1:250, 10], 
        type = 'l',
        lwd = 1.7, 
        cex = 1.6,
        bty = "n",
        yaxt = "n",
        xaxt = "n",
        xlab = paste0("Sim ", k),
        col = pal[k]
        )
}
par(mfrow = c(3,1), mar = c(4,1,1,1))
plot_ts(1); plot_ts(2); plot_ts(3)

## ----density, fig.width = 6.5, fig.height = 3.5, fig.cap = "Smoothed density of fractal dimension estimates for each simulation group."----
library(ggplot2)

# Compute features on each group
df1 <- apply(t1, 2, fractal_dim) %>% data.frame
df2 <- apply(t2, 2, fractal_dim) %>% data.frame
df3 <- apply(t3, 2, fractal_dim) %>% data.frame

fd_df <- rbind(df1, df2, df3)
fd_df$id <- as.factor(
                      c(rep("Sim 1", reps), 
                        rep("Sim 2", reps), 
                        rep("Sim 3", reps))
                        )

data_long <- reshape2::melt(fd_df, id.vars = c("id"))

ggplot(data_long, aes(x = value, fill = id)) +
       geom_density(
                alpha = 0.6, 
                aes(y = ..density..), 
                position = "identity",
                color = NA) +
       scale_fill_manual(values= pal) +
       xlab("Fractal Dimension") +
       ylab("") + 
       theme_minimal() + 
       theme(
             panel.grid = element_blank()
            ) 

