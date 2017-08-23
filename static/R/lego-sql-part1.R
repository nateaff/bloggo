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
       dev = 'png', 
       eval = FALSE)

## ----libraries-----------------------------------------------------------
# install.packages("dplyr")
# install.packages("RPostgreSQL")
# install.packags("readr")
# install.packages("import") 
# Make pipe available -- added to "imports" environment
import::from(dplyr, "%>%")

## ----setup---------------------------------------------------------------
setwd("~/path/to/my/lego-project")
# Supress warnings for this session
options(warn=-1)

## ----download------------------------------------------------------------
URL <- "https://s3-us-west-1.amazonaws.com/kaggle-lego/lego-database.zip"
tmp <- tempfile()
download.file(URL, tmp)
dir.create("data")
# Unzip files in the data directory
setwd("data")
files <- unzip(tmp)

## ----check-files---------------------------------------------------------
# Check files names
files 
# Remove db schema '.png' file
files <- files[-2]
# Remove file prefix and suffix 
filenames <- files %>% sub("./", "", .) %>% sub(".csv", "", .) 

## ----glance1-------------------------------------------------------------
# Glance at head of color
readr::read_csv(files[1], n_max = 5)
# Look at heads of all files
lapply(files, readr::read_csv, n_max = 5)

## ----setup-con-----------------------------------------------------------
# Access Postgres driver 
pg = RPostgreSQL::PostgreSQL()
# Note fake user/password
con = DBI::dbConnect(pg, 
                     user = "my-username", 
                     password = "#my-password", 
                     host = "localhost", 
                     port = 5432
                     )


## ----create-db-----------------------------------------------------------

DBI::dbSendStatement(con, "create database legos")
# Test writing one file to the database
colors <- readr::read_csv(files[1])
DBI::dbWriteTable(con, "colors", colors , row.names=FALSE)
# Check that it works
dtab <- DBI::dbReadTable(con, "colors")
summary(dtab)
# Write all files to the database
for(k in seq_along(files[1:8])){
  cat("Writing ", filenames[k], "/n")
  tmp <- readr::read_csv(files[k])
  DBI::dbWriteTable(con, filenames[k], tmp, row.names=FALSE)  
  rm(tmp)
}
dtab <- DBI::dbReadTable(con, "sets")
summary(dtab)
# Close connection
DBI::dbDisconnect(con)

## ----reconnect-----------------------------------------------------------
# If restarting, re-set the directory to data
setwd("~/path/to/my/lego-project")
# Get filenames again
filenames <- dir() %>% sub(".csv", "", .)
install.packages("keyringr")

# Replace plaintext password with keyringr call
pg = RPostgreSQL::PostgreSQL()
con = DBI::dbConnect(pg, 
                user = "postgres", 
                password = keyringr::decrypt_gk_pw("db lego user myusername"), 
                host = "localhost", 
                port = 5432
                )

## ----echo=FALSE, eval = TRUE, results='hide',message=FALSE---------------
# Hide re-load
import::from(dplyr, "%>%")
setwd("~/devel/R-proj/lego/data")
filenames <- dir() %>% sub(".csv", "", .)

pg = RPostgreSQL::PostgreSQL()
con = DBI::dbConnect(pg, 
                user = "postgres", 
                password = keyringr::decrypt_gk_pw("db lego user postgres"), 
                host = "localhost", 
                port = 5432
                )

## ----check-schema, eval = TRUE-------------------------------------------
# Function to check table schema
get_schema_query <- function(tab){
  paste0("select column_name, data_type, character_maximum_length", 
  " from INFORMATION_SCHEMA.COLUMNS where table_name = '",tab,"';")
}
# Check an example
res <- DBI::dbSendQuery(con, get_schema_query("sets"))
DBI::dbFetch(res)
DBI::dbClearResult(res)
# Create function from previous example
check_schemas <- function(tab){
  res <- DBI::dbSendQuery(con, get_schema_query(tab))
  out <- DBI::dbFetch(res)
  DBI::dbClearResult(res)
  out
}
# Check all tables
schemas <- lapply(filenames, check_schemas)
names(schemas) <- filenames  

## ----plot-colors , eval = TRUE,  fig.cap="Lego colors, 1950-2017"--------
# Select rgb and is_trans columns 
rgb_df <- DBI::dbGetQuery(con, "select rgb, is_trans from colors")

# Check data
dim(rgb_df)
head(rgb_df)

## ----transform , eval = TRUE---------------------------------------------
rgb_df$rgb <- paste0("#", rgb_df$rgb) 
head(rgb_df)
# Count number of transparent colors
rgb_df %>% dplyr::filter(is_trans == "t") %>% dplyr::count()
# And rgb + alpha column
rgb_df <- rgb_df %>% dplyr::mutate(rgbt = ifelse  (is_trans ==  "f", rgb,adjustcolor(rgb, 0.5)))

## ----eval = TRUE---------------------------------------------------------
par(bg = "gray10", mar = c(2,1,2,1))
barplot(
        height = rep(0.5, nrow(rgb_df)), 
        col = sort(rgb_df$rgb), 
        yaxt ="n", 
        border = par("bg"),
        space = 0
        )

## ----squares, eval = TRUE------------------------------------------------
# Draw a single square
draw_lego <- function(col){
  plot(5,5, type = "n", axes = FALSE)
  rect(
        0, 0, 10, 10, 
        type = "n", 
        xlab = "", 
        ylab = "",
        lwd = 4,
        col = col, 
        add = TRUE 
      )
  points(x = 5, y = 5, col ="gray20", cex = 3, lwd = 1.7)
  }

op <- par(bg = "gray12")
plot.new()

par(mfrow = c(9, 15), mar = c(0.7, 0.7, 1, 0.7))
cols <- sort(rgb_df$rgbt)
for(k in 1:length(cols))  draw_lego(cols[k])

## ------------------------------------------------------------------------
DBI::dbDisconnect(con)
# Unsupress warnings
options(warn= 0)

