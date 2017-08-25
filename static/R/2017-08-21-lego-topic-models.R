## ----global_options, echo = FALSE----------------------------------------
knitr::opts_chunk$set(
       knitr::opts_chunk$set(cache=TRUE),
       fig.align = 'center', 
       echo=FALSE, 
       warning=FALSE, 
       message=FALSE,  
       fig.width = 6.5, 
       fig.height = 6.5,
       dev = 'png', 
       eval = FALSE)

## ----themes, echo = FALSE, eval = TRUE-----------------------------------

library(ggplot2)
library(dplyr)
# Hide re-load
# import::from(dplyr, "%>%")
setwd("~/devel/R-proj/lego/data")
filenames <- dir() %>% sub(".csv", "", .)

options(warn = -1)
pg = RPostgreSQL::PostgreSQL()
con = DBI::dbConnect(pg, 
                user = "postgres", 
                password = keyringr::decrypt_gk_pw("db lego user postgres"), 
                host = "localhost", 
                port = 5432
                )

# Counts by theme
counts <- tbl(con, "themes") %>% 
          group_by(parent_id) %>% 
          count %>% 
          collect
sum(counts$n)

unique(counts$parent_id)

# Remove NA parents
parents <- counts %>% filter(!is.na(parent_id)) 
parent_set <- parents$parent_id


## ----set-query, echo = FALSE, eval = TRUE--------------------------------

# Get tables
themes <- tbl(con, "themes")
inventory_sets <- tbl(con, "inventory_sets")
inventories <- tbl(con, "inventories") 
inventory_parts <- tbl(con, "inventory_parts") 
colors <- tbl(con, "colors")
sets <- tbl(con, "sets") 

set_colors <- 
  themes %>% 
  # Filter out no-parent sets
  filter(parent_id %in% parent_set|| id %in% parent_set) %>% 
  mutate(theme = name, theme_id = id) %>% 
  select(theme, theme_id) %>%
  right_join(sets, by = 'theme_id') %>%
  select(set_num, name, year, theme_id, theme) %>% 
  right_join(inventories, by = 'set_num', copy = TRUE) %>% 
  right_join(inventory_parts, by = c('id' = 'inventory_id')) %>%
  filter(!is.na(year)) %>%
  left_join(colors, by = c('color_id' = 'id')) %>%
  mutate(name = name.x) %>% 
  select(set_num, name, theme, theme_id, rgb, year, is_trans, quantity) %>%
  collect 
        
DBI::dbDisconnect(con)

# Perform in-memory filtering and mutation
set_colors <- 
  set_colors %>% 
  mutate(name = stringr::str_sub(name, 1, 20)) %>%
  # Add alpha, transparent = 0.5 = '80', opaque = 'FF
  mutate(rgba = ifelse(is_trans == 't', 
                  paste0("#", rgb, '80'), 
                  paste0("#", rgb, 'FF'))) %>% 
  select(set_num, name, theme, theme_id,year, rgba, quantity) %>% 
  sample_n(10000) 

head(set_colors)

# Expand by quantity column and remove quantity
set_colors <- 
  set_colors[rep(seq(nrow(set_colors)), set_colors$quantity),] %>% 
  select(-quantity)

## ----tf-idf, echo = FALSE, eval = TRUE-----------------------------------
# Compute tf-idf
# idf(term) = ln( n-docs/n-docs with term)
# Compare Tidytext : http://tidytextmining.com/tfidf.html
set_words <- set_colors %>% 
             count(name, set_num, rgba, sort = TRUE) %>%
             ungroup()

total_words <- set_words %>%
              group_by(set_num) %>%
              summarize(total = sum(n))

set_words <- left_join(set_words, total_words, by = 'set_num')

# Term Frequency

# Create palette
pal <- unique(set_colors$rgba)
names(pal) <- unique(pal) 

set_words <- set_words %>%
  tidytext::bind_tf_idf(rgba, set_num, n)

tail <- set_words %>%   
       arrange(tf_idf) %>%
       mutate(rgba = factor(rgba, levels = unique(rgba))) %>%
       head(50) %>%
       arrange(desc(tf_idf))

tail <- tail[match(unique(tail$rgba), tail$rgba), ]
tail$rgba <- factor(tail$rgba, tail$rgba)
tail <- tail[1:12, ]

top <- set_words %>%   
       arrange(tf_idf) %>%
       mutate(rgba = factor(rgba, levels = unique(rgba))) %>%
       tail(30) %>% 
       arrange(desc(tf_idf))

top <- top[match(unique(top$rgba), top$rgba),] %>%
arrange(tf_idf)
top$rgba <- factor(top$rgba, top$rgba)
top <- top[1:12, ]

# Highest td-idf
top %>%
ggplot() +
  geom_bar(aes(x = rgba, y = tf_idf, fill = rgba), 
    stat = 'identity', 
    show.legend = FALSE) +
  scale_fill_manual(values = pal) + 
  labs(x = NULL, y = "tf-idf") +
  coord_flip() + 
  theme_minimal()  

# Lowest td-idf
tail  %>%
ggplot(aes(x = rgba, y = tf_idf)) +
  geom_bar(aes(fill = rgba),
    stat = 'identity', 
    show.legend = FALSE) +
  scale_fill_manual(values = pal) + 
  labs(x = NULL, y = "tf-idf") +
  coord_flip() + 
  theme_minimal() 
 

## ----lda1, eval = FALSE--------------------------------------------------
## library(topicmodels)
## n_topics <- c(5, 10, 25, 35, 50, 65, 80, 100)
## 
## # Fit models - This is compute intensive and takes a few minutes
## set_lda_compare <- n_topics %>%
## purrr::map(LDA, x = set_dtm, control = list(seed = 1109))
## 

 
#----------------------------------------------------------
# 5-cv
#----------------------------------------------------------
library(topicmodels)
library(tidytext)
# Make document term matrix
set_words %>% 
select(name, rgba, n) %>% 
crossv_kfold(5) -> folds


folds %>% 
mutate(dtm = cast_dtm(train, name, rgba, n))

map(folds$train, ~ cast_dtm(., name, rgba, n))

cast_dtm(folds$train[[1]])

dtm <- function(x){
  cast_dtm(x, name, rgba, n)
}

folds %>% mutate(dtm = map(train, dtm))



n_topics <- c(30, 35, 30, 40, 45, 50)

set_dtm %>%
crossv_kfold(k = 5) -> folds 
mutate(model = map(train, 
  ~LDA(n_topics, x = set_dtm., control = list(seed = 1))))-> models
  



## ----load-lda, eval = TRUE, echo = FALSE---------------------------------
n_topics <- c(5, 10, 25, 35, 50, 65, 80, 100)
# saveRDS(set_lda_compare, "~/devel/R-proj/lego/cache/set_lda_compare.RDS")
set_lda_compare <- readRDS("~/devel/R-proj/lego/cache/set_lda_compare.RDS")
library(topicmodels)
library(dplyr)

data_frame(k = n_topics,
           perplex = purrr::map_dbl(set_lda_compare, perplexity)) %>%
  ggplot(aes(k, perplex)) +
  geom_point() +
  geom_line() +
  labs(title = "Evaluating LDA topic models",
       subtitle = "Optimal number of topics (smaller is better)",
       x = "Number of topics",
       y = "Perplexity") + 
  theme_minimal()

# Take two best models to compare
ind35 <- which(n_topics == 35)
ind50 <- which(n_topics == 50)

set_lda35 <- set_lda_compare[[ind35]]
set_lda50 <- set_lda_compare[[ind50]]

## ----top-terms, echo = FALSE, eval = TRUE--------------------------------
# Plot the top ''
set_topics <- tidytext::tidy(set_lda35, matrix = 'beta')

top_terms <- set_topics %>%
  group_by(topic) %>%
  top_n(3, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = term)) +
  labs(x ='') +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free_y", nrow =10) +
  scale_fill_manual(values = pal) + 
  coord_flip() + 
  theme_minimal() +
  theme(axis.text.y=element_blank())

set_topics <- broom::tidy(set_lda50, matrix = 'beta')

top_terms <- set_topics %>%
  group_by(topic) %>%
  top_n(3, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = term)) +
  labs(x ='') +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free_y", nrow =10) +
  scale_fill_manual(values = pal) + 
  coord_flip() + 
  theme_minimal() +
  theme(axis.text.y=element_blank())


## ----top-docs, echo = FALSE, eval = TRUE---------------------------------
# Tidy Gamma matrix
set_docs <- tidytext::tidy(set_lda35, matrix = "gamma")

# Find the "purest" topics and see what sets they are 
# associated with 
top_docs <- set_docs %>% arrange(desc(gamma)) %>% head(50)

topic <- set_docs %>%
         filter(topic == 3) %>% 
         arrange(desc(gamma)) %>%
         head(20) 
topic$document


topic <- set_docs %>%
         filter(topic == 21) %>% 
         arrange(desc(gamma)) %>%
         head(20) 
topic$document


## ----set-inclusion-------------------------------------------------------



