## ----global_options, echo=FALSE------------------------------------------
knitr::opts_chunk$set(
       knitr::opts_chunk$set(cache=TRUE),
       fig.align = 'center', 
       echo=TRUE, 
       warning=FALSE, 
       message=FALSE, 
       fig.width = 6.5, 
       fig.height = 6.5,
       dev = 'png', 
       eval = FALSE)

## ----connect, eval=TRUE--------------------------------------------------
library(RPostgreSQL)
library(dplyr)

# Suppress warnings for this session
options(warn=-1)

# Set driver and get connection to database
pg = RPostgreSQL::PostgreSQL()
# Replace user and password with your value
con = DBI::dbConnect(pg, 
                user = "postgres", 
                password = keyringr::decrypt_gk_pw("db lego user postgres"), 
                host = "localhost", 
                port = 5432
                )

## ----glance--------------------------------------------------------------
# Check data
DBI::dbListTables(con)
DBI::dbListFields(con, 'sets')

## ----glance2-------------------------------------------------------------
# Example without using the pipe operator
# Get the 'sets' table
res <- tbl(con, 'sets') 
head(res, 5)

# Using pipes 
con %>% tbl('sets') %>% head(10)
# Head with default arguments
con %>% tbl('inventories') %>% head
con %>% tbl('colors') %>% head

## ----select1, results='markup'-------------------------------------------
res <- tbl(con, sql("select name, year from sets"))
res
dim(res)

## ----filter, eval=TRUE---------------------------------------------------
# Collect data
res <- tbl(con, sql("select name, year from sets")) %>% collect
res
dim(res)

## ----show, eval=TRUE-----------------------------------------------------
res <- tbl(con, sql("select name, rgb from colors"))
show_query(res)
res <- con %>% tbl('colors') %>% select(name, rgb) 
show_query(res)

## ----set-count, eval=TRUE------------------------------------------------
years <- tbl(con, sql("select year from sets")) %>% collect
hist(years$year, 
      col = "gray30", 
      lwd = 2, 
      cex = 0.9,
      border = "white", 
      xlab = "Year",
      main="Lego sets per year, 1950-2017")

## ----set-count2, eval = TRUE---------------------------------------------
library(ggplot2)
gp <-  years %>%  ggplot( ) + geom_bar(aes(x = year )) + 
          labs(
            x = "", 
            y = "Set count", 
            caption = "rebrickable.com/api/",
            title ="Lego sets per year, 1950-2017"
            ) +
          scale_fill_manual(values = "gray10")+ 
          theme_light( ) + 
          theme(
            panel.background = element_rect(fill = "#fdfdfd"),
            plot.background = element_rect(fill = "#fdfdfd"),
            legend.position = "none", 
            text = element_text(
                     color = "gray10", 
                     face = "bold",
                     family="Lato", 
                     size = 13),
            axis.title = element_text(size=rel(0.9)),
            plot.title = element_text(face = "bold", size = rel(1.1)),
            plot.caption = element_text(
                             face = "italic",
                             color = "gray30",
                             size = rel(0.6)),
            panel.grid = element_blank()
            )
gp


## ----theme, eval=TRUE----------------------------------------------------
theme_light2 <- function(){
  theme_light( ) + 
    theme(
          panel.background = element_rect(fill = "#fdfdfd"),
          plot.background = element_rect(fill = "#fdfdfd"),
          legend.position = "none",
          text = element_text(
                   color = "gray10", 
                   face = "bold",
                   family="Lato", 
                   size = 13),
          plot.title = element_text(size = rel(1)),
          axis.title = element_text(size=rel(0.9)),
          plot.caption = element_text(
                           face = "italic",
                           color = "gray30",
                           size = rel(0.7)),
          panel.grid = element_blank()
          )
 }

## ----one-set, eval=TRUE, output='markup'---------------------------------
# Get table 
inventories     <- tbl(con, "inventories")
inventory_parts <- tbl(con, "inventory_parts")
colors          <- tbl(con, "colors")
sets            <- tbl(con, "sets")

# Get inventory parts for one set
sets %>% head
one_set <- sets %>% filter(set_num == "0012-1") %>% 
           right_join(inventories, by = 'set_num', copy = TRUE) %>%
           right_join(inventory_parts, by = c('id' = 'inventory_id')) %>%
           filter(!is.na(year)) %>% collect  
one_set$part_num

## ----all-sets, eval=TRUE-------------------------------------------------
set_colors <- sets %>%   
              select(set_num, name, year) %>% 
              right_join(inventories, by = 'set_num', copy = TRUE) %>%
              right_join(inventory_parts, by = c('id' = 'inventory_id')) %>%
              filter(!is.na(year)) %>%
              left_join(colors, by = c('color_id'  = 'id')) %>%
              mutate(name = name.x) %>% 
              select(set_num, name, year, color_id, rgb, is_trans) %>% 
              collect

## ------------------------------------------------------------------------
DBI::dbDisconnect(con)

## ----plot3, eval=TRUE----------------------------------------------------
# Make hex values readable by R
breaks <- seq(1950, 2017, by = 10)

# Create color pallete and add names. 
set_colors <- set_colors %>% mutate(rgb = paste0("#", rgb))
pal <- unique(set_colors$rgb)
names(pal) <- unique(pal) 

gp <-  set_colors %>%   ggplot() + 
          geom_bar(aes(x = year, fill = rgb)) + 
          labs(
            x =   "", 
            y = "Brick Color Frequency", 
            title = "Lego brick colors, 1950-2017", 
            caption = "source: rebrickable.com/api/"
            ) +          
          scale_fill_manual(values = pal) + 
          scale_x_discrete(limits = breaks) +          
          theme_light2() 

gp

## ----plot4, eval=TRUE----------------------------------------------------
# Get number of occurences and frequency of color
freq_tbl <- set_colors %>% select(year, rgb, color_id) %>% 
              group_by(year, rgb) %>%
              summarise(n = n()) %>% 
              mutate(percent = n/sum(n))
# Plot color occurences only
gp <-  freq_tbl %>%   ggplot() + 
          geom_bar(aes(x = year, fill = rgb)) + 
          labs(
            x = "", 
            y = "Unique Brick Colors", 
            title = "Lego brick colors, 1950-2017",
            caption = "source: rebrickable.com/api/"           
            )  +          
          scale_fill_manual(values = pal)+ 
          scale_x_discrete(limits = breaks) +          
          theme_light2()

gp

## ----plot-relative, eval=TRUE--------------------------------------------
gp <-  freq_tbl %>% ggplot() + 
        geom_bar(
          aes(x = year, y = percent, fill = rgb), 
          stat  = "identity", 
          width = 1
          ) +
        labs(x = "", 
          y = "Relative Color Frequency", 
          title = "Lego brick colors, 1950-2017",
          caption = "source: rebrickable.com/api") +
        scale_fill_manual(values = pal) + 
        scale_x_discrete(limits = breaks) +          
        theme_light2()

gp

