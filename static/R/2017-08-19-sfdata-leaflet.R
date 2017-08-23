## ----global_options, echo=FALSE------------------------------------------
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

## ----data, eval = TRUE, echo = TRUE--------------------------------------

library(dplyr)
library(ggplot2)
# library(ggthemes)

# DataSF base URL for 311 data
apiURL <- "https://data.sfgov.org/resource/ktji-gk7t.json"
lim    <- "?$limit=10"
sel    <- paste("&$select=service_request_id",
                "service_details,service_name",
                "supervisor_district",
                "requested_datetime",
                "closed_date",
                "lat",
                "long", 
                sep = ",")
ord    <- "&$order=requested_datetime DESC"
where  <- paste0("&$where=requested_datetime > ", 
                 "'",Sys.Date() - 7, "T12:00:00'")
query  <- paste0(apiURL, lim, sel, ord)
#data   <- RSocrata::read.socrata(query)


## ----data2, eval=TRUE, echo = TRUE---------------------------------------
query <- soql::soql() %>% 
         soql::soql_add_endpoint(apiURL) %>%
         soql::soql_limit(50000) %>%
         soql::soql_select(paste(
                            "service_request_id", 
                            "service_details", 
                            "service_name", 
                            "supervisor_district", 
                            "requested_datetime", 
                            "closed_date", 
                            "lat", 
                            "long", 
                            sep = ","
                            )) %>%
         soql::soql_order("requested_datetime", desc=TRUE) %>%
         soql::soql_where(paste0("requested_datetime > ", 
                           "'",Sys.Date() - 7, "T12:00:00'"))
data <- RSocrata::read.socrata(query)

## ----barplot1, eval=TRUE-------------------------------------------------
# head(data)
# nrow(data)
# range(data$requested_datetime)

# Convert names in Homeless Concerns type
data$service_details[data$service_details == "aggressive_behavior"] <- "Aggressive Behavior"
data$service_details[data$service_details == "wellbeing_check"] <- "Wellbeing Check"
data$service_details[data$service_details == "homeless_other"] <- "Other"


pal5 <- c("#43897F","#b55609", "#7A496E","#618933", 
           "#436f89","#a38500","#992468", "#59497A")
pal <- colorRampPalette(pal5)(20)

svc_counts <- data %>% 
              dplyr::count(service_name) %>% 
              dplyr::arrange(n) %>% 
              dplyr::mutate(service_name = factor(service_name, service_name))

svc_counts %>% tail(20) %>%
  ggplot() +
  geom_bar(
    aes(
      x=service_name, 
      y=n, 
      fill = service_name), 
      stat='identity'
    ) +
  coord_flip() + 
  labs(
      x = 'Service Names', 
      y = 'Request Count', 
      title = '311 Homeless related request count for week of 2017-08-12') + 
  theme_minimal() + 
  scale_fill_manual(values = pal) +
  theme(
    legend.position = "none",
  )

## ----timeseries, eval = TRUE---------------------------------------------
top12 <- svc_counts$service_name %>% tail(12)

counts <- data %>% 
          filter(service_name %in% top12) %>% 
          dplyr::mutate(day = lubridate::wday(as.Date(requested_datetime), 
            label = TRUE), 
            hr = sprintf("%02d", lubridate::hour(requested_datetime))) 
counts <- counts %>%  dplyr::count(service_name, day, hr)
counts <- counts %>% 
          dplyr::mutate(day_hr = forcats::fct_inorder(paste0(day, "-",  hr)))
counts$service_details <- factor(counts$service_name)

count2 <- data %>% 
        filter(service_name %in% top12) %>% 
        dplyr::mutate(date = lubridate::round_date(requested_datetime, 
                       unit = 'hour') ) %>% 
        dplyr::count(service_name, date)



# Set label and x-axis breaks to every 12 hours
hrseq  <- seq(1, nrow(counts), by = 24)

len <- unique(counts$service_name) %>% length
pal <- colorRampPalette(pal5)(len)

gp <- count2 %>%  
      ggplot(aes(date, n, fill = service_name, color = service_name)) + 
      geom_area( alpha = 0.7) +
      geom_line(size = 0.8) + 
      labs(
        x = "Day and Hour of Service Request", 
        y = "Request Count", 
        caption = "source: datasf.org/opendata") +
        # subtitle = "311 'Homeless Concerns' Service Requests in San Francisco, 2016-2017") +
      ggtitle("311 'Homeless Concerns' Service Requests in San Francisco, 2016-2017")   
      
      # scale_colour_manual(values = pal) +
      # scale_fill_manual(values = pal) 
      # scale_x_date(date_breaks = 'day')
gp


gp <- gp + theme_minimal() +   
      theme(
        legend.position = "none",
        plot.background = element_rect(fill = "#fefefe"),
        # plot.margin = margin(.5, .5, .5, .5, "cm"),
        panel.grid.major = element_line(colour = "gray80"),
        title = element_text(
                  family = "Lato", 
                  size = 13, 
                  face = "bold", 
                  color = "gray5"
                  ),
        axis.title = element_text(
                      # family = "Lato", 
                      size = 11, 
                      color="gray15", 
                      ),
        plot.caption = element_text(
                        # family = "Lato", 
                        face = "italic", 
                        size = 10, 
                        color = "gray25"
                        )
        ) 
gp + facet_wrap(~service_name, nrow = 4)


## ----barplot2, eval=TRUE-------------------------------------------------
data_hl <- data %>% 
           filter(service_name %in% c("Homeless Concerns", 
                                      "Encampments"))
data_hl %>%
dplyr::count(service_details) %>% 
dplyr::arrange(n) %>% 
dplyr::mutate(service_details=factor(service_details, service_details))%>%
ggplot() +
  geom_bar(
    aes(
    x=service_details, 
    y=n, 
    fill = service_details), 
    stat = 'identity'
    ) +
  coord_flip() + 
  labs(
    x = 'Service Details', 
    y = 'Request Count', 
    title = '311 Homeless related request count for week of 2017-08-12') +
  theme_minimal() + 
  scale_fill_manual(values = pal) +
  theme(
    legend.position = "none",
 )

 

## ----timeseries2, eval = TRUE--------------------------------------------
# Group by day and hour and create day-hr column
counts <- data_hl %>% 
           dplyr::mutate(day = lubridate::wday(as.Date(requested_datetime), 
                    label = TRUE), 
                    hr = sprintf("%02d", lubridate::hour(requested_datetime))) 
counts <- counts %>%  dplyr::count(service_details, day, hr)
counts <- counts %>% dplyr::mutate(day_hr = forcats::fct_inorder(paste0(day,"-", hr)))
counts$service_details <- factor(counts$service_details)
# Set label and x-axis breaks to every 12 hours
hrseq  <- seq(1, nrow(counts), by = 24)

len <- unique(counts$service_details) %>% length
pal <- colorRampPalette(pal5)(len)

gp <- counts %>%  
      ggplot() + 
      geom_area( 
        aes(x=day_hr, y=n, group =1, fill=service_details), alpha = 0.7) +
      geom_line(
        aes(x=factor(day_hr), y=n, group=1, color=service_details), size=0.8) +
      labs(
        x = "Day and Hour of Service Request", 
        y = "Request Count", 
        caption = "source: datasf.org/opendata") +
        # subtitle = "311 'Homeless Concerns' Service Requests in San Francisco, 2016-2017") +
      ggtitle("311 'Homeless Concerns' Service Requests in San Francisco, 2016-2017") +
      scale_colour_manual(values = pal) +
      scale_fill_manual(values = pal) +
      scale_x_discrete(breaks = unique(counts$day_hr)[hrseq]) 
gp <- gp + theme_minimal() +   
      theme(
        legend.position = "none",
        plot.background = element_rect(fill = "#fefefe"),
        # plot.margin = margin(.5, .5, .5, .5, "cm"),
        panel.grid.major = element_line(colour = "gray80"),
        title = element_text(
                  family = "Lato", 
                  size = 13, 
                  face = "bold", 
                  color = "gray5"
                  ),
        axis.title = element_text(
                      # family = "Lato", 
                      size = 11, 
                      color="gray15", 
                      ),
        plot.caption = element_text(
                        # family = "Lato", 
                        face = "italic", 
                        size = 10, 
                        color = "gray25"
                        )
        ) 
gp + facet_wrap(~service_details, nrow = 7)


## ----map, eval = TRUE, echo = TRUE, fig.align='center', fig.show='hold'----

library(leaflet)
#Convert long, lat, to numeric
data$lat <- as.numeric(data$lat)
data$long <- as.numeric(data$long)
data$service_name <- as.factor(data$service_name)

# Find midpoint
midpoint <- function(a,b){
  abs(a - b)/2 + min(a,b)
}

bbox = c(-122.526441,37.692072,-122.36276,37.821818)

mlong <- midpoint(bbox[1], bbox[3])
mlat <- midpoint(bbox[2], bbox[4])

# Find poo 
x <- data %>% filter(service_details == "Human Waste") %>% 
          select(service_details, requested_datetime,)



# Filter    
x <- data %>% filter(service_name %in% c("Homeless Concerns", "Encampments"))
x <- data %>% filter(service_details %in% c("Human Waste", 
                    "Encampment Cleanup", "Cart Pickup"))

# Create pallette with number equal to number of service names/details
len <- x$service_details %>% unique %>% length
pal <- RColorBrewer::brewer.pal(len, "Set2") 
pal <- pal5[5:3]
# pal <- pal5(1:3) 
factpal <- colorFactor(pal, as.factor(x$service_details))
# Leaflet base
m <- leaflet(x, width = "100%") %>% setView(lng = mlong, 
                           lat = mlat ,
                           zoom = 13)

m <- m %>% addProviderTiles(providers$MtbMap) %>%
    addProviderTiles(providers$Stamen.TonerLines,
      options = providerTileOptions(opacity = 0.35)) %>%
    addProviderTiles(providers$Stamen.TonerLabels)

m %>% addCircleMarkers(
        lng = x$long, 
        lat = x$lat,
        label = x$service_details,
        labelOptions = labelOptions( style = list("boxshadow" = "1px 1px rgba(0,0,0,0)")),
        radius = 4, 
        color = ~factpal(x$service_details), 
        stroke = FALSE, 
        fillOpacity = 0.7)


## ----datatable, echo = TRUE, eval = TRUE---------------------------------
dim(x)
DT::datatable(x[, 3:7])


