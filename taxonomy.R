# Match Article DOIs to Relevant Tag Codes.

# Set your working directory (examples below). Use getwd() to check your current working directory.
# setwd("/Users/baileybaumann/Documents/R/taxonomy") # Mac.
# setwd("C:/Users/bbaumann/OneDrive - SAGE Publishing/Desktop/Reporting Projects/R/taxonomy") # Windows.

# You only need to install these packages once.
# install.packages("tidyverse")
# instal.packages("rvest")
# install.packages("stringr")
# install.packages("curl")

# Load these packages with every new instance of R.
library(tidyverse) 
library(rvest) 
library(stringr)
library(curl)

# Pt 1: Web Scraping.

urls.table <- read.csv("socr.csv") 
urls.table <- urls.table[urls.table$estimate != "estimate",] # In case the SOCR data has extra headers.

article.min <- 1
article.max <- nrow(urls.table) 

# Trim any white spaces from urls.
urls.vector <- trimws(urls.table$atyponUrl) 
# Extract dois from urls.
dois.vector <- str_sub(urls.vector, 38, 80) 
# Create new df with only urls & dois. We need this for Pt 2.
urls.dois <- as.data.frame(cbind(urls.vector, dois.vector)) 

# This is the web scraping loop. It takes a while with a lot of articles.
# TODO: https://github.com/yusuzech/r-web-scraping-cheat-sheet/blob/master/README.md#rvest7.11.
for (i in article.min:article.max) {
  if (i %% 1000 == 0) { # Adds 1 second delay every 1,000 articles so as not to overload server.
    Sys.sleep(1)
  }
  # Specify a different useragent if appropriate. Important step if you are scraping a lot of pages.
  article <- read_html(curl(paste0(urls.vector[i])), handle = new_handle("useragent" = "Mozilla/5.0"))
  articletext <- article %>%
    html_nodes(".hlFld-KeywordText , p , h1") %>% # Or different HTML classes.
    html_text() %>%
    as.vector()
  output <- paste0("articletext", i)
  assign(output, value = articletext)
}

# Pt 2: Organize Web Scraping Results into One Data Frame.

# Each article gets one character string.
for (n in article.min:article.max) {
  articletext.n <- str_c("articletext", n) # Creates variable names to cycle through.
  articletext.n <- get(articletext.n) # Assigns values to varaible names.
  articletext <- str_c(articletext.n, collapse = "") # Collapses each article into its own string.
  articletext <- str_sub(articletext, 2097, 100000) # Removes extra characters from start of article. 
  output <- paste0("articletext", n) # Creates names for outputs. 
  assign(output, value = articletext) # Assigns values to outputs.
}

# Put the character strings created above into a vector.
articles.vector <- vector()
for (n in article.min:article.max) {
  articletext.n <- str_c("articletext", n)  # Creates variable names to cycle through.
  articletext.n <- get(articletext.n) # Assigns values to varaible names.
  articles.vector <- append(articles.vector, articletext.n) # Add each character string as a new row. 
}

# Change class of articles from list to character. 
articles.vector <- unlist(articles.vector) 
# Subset urls.dois (from Pt 1) if needed.
urls.dois <- urls.dois[article.min:article.max,] 
# Create df with a column each for articles, urls, and dois.
articles.df <- cbind(urls.dois, articles.vector) 

#Pt 3: Search for Matching Tag Names.

tags <- read.table("tags.txt", header = FALSE, sep = "\n") 
# My tags had a "-" between their names and codes.
tags <- separate(tags, col = V1, into = c("tagcode", "tagname"), sep = "-") 
# My tags also had extra white spaces.
tags$tagname <- trimws(tags$tagname, which = "left")

# Collapse list of tag names into a single string.
tagnames.str <- str_c(tags$tagname, collapse = "|")

# Add a column called "matches" to articles.df
# Fill this column with the tag names that occur in the article in that row.
# TODO: Consider using autoML instead https://cloud.google.com/natural-language/automl/entity-analysis/docs/.
articles.df <- articles.df %>%
  mutate(
    matches = str_extract_all(articles.vector, tagnames.str))

# Pt 4: Make Table for File Upload Handler.

# Remove extra columns.
urls.tagnames <- select(articles.df, -c(urls.vector, articles.vector)) 
# Matches column is currently a nested list. We need each match in a separate row.
matches.unnested <- unnest(urls.tagnames, matches, .drop = TRUE, .preserve = dois.vector)
# Remove duplicated rows.
matches.unnested <- unique(matches.unnested)
# Use a join to add tag codes to corresponding tag names.
urls.tagnames.tagcodes <- inner_join(matches.unnested, tags, by = c("matches" = "tagname"))
# Drop the matches column. We don't want it for the File Uploads Handler.
urls.tagcodes <- select(urls.tagnames.tagcodes, -matches)
# Add an "a" so the File Uploads Handler knows we are adding these tags.
urls.tagcodes$a <- "a"
# Reorder columns for File Uploads Handler.
urls.tagcodes <- urls.tagcodes[c("dois.vector", "a", "tagcode")]

# Write to .txt file. Exclude headers and quotation marks.
# Make sure the file is named correctly for the taxonomy you are updating.
write.table(urls.tagcodes, file = "fileuploadhandler.txt", sep = "\t", 
           row.names = FALSE, col.names = FALSE, quote = FALSE)
