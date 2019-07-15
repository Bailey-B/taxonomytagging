# Taxonomy Tagging
This R script can be used to match article DOIs to relevant tag codes. It scrapes the full text, title, and keywords of the articles you need to tag. Then it matches this against a list of collection names. It produces an output in the format required by Atypon's File Upload Handler.

## To Start
Download the latest version of R. The IDE, RStudio, is also recommended. 
https://cran.r-project.org/
https://www.rstudio.com/products/rstudio/download/

### Package Installation
Open taxonomy.R. Follow the examples in lines 1-11 to set up your working directory and install the necessary packages, if you haven't already done so.

## Inputs
This script requires two file inputs: 
* An export from SOCR that includes Atypon URLs and has been converted to a .csv.
* A list of tag names and tagcodes. Mine was in a .txt format.

Please see socr-dummy.csv and tags-dummy.txt for formatting examples. I don't recommend running the script with these dummy inputs.

## Web Scraping with rvest
This is the section that takes the longest to run. In RStudio, look for the red stop sign at the top right of your console. Nothing new will appear in in the console or the Global Environment until the web scraping loop has finished, but of the stop sign is still there, the loop is still working.

I was able to successfully scrape 2,300 articles with R 3.6.0, on Mac OS 10.14.5, with 16 G of RAM, but it took several minutes. I plan to update this script so the web scraping step is done in parallel.

Change article.max if you want to test the script on a smaller number of urls than is in your version of socr.csv.

## Matching with stringr::str_extract_all()
This script will match a whole tag name against words and phrases in the article, its title, and any keywords. One limitation of this method is if your tag name is something like "Hospitality and Tourism" the script will not find a match if the article only uses the words "hospitality" and/or "tourism" separately. However, it also won't find a false match if your tag name is "Hospital Administration" and the article only has the word "administration" because it is about school administration. 

Be sure to spot check your taggings before uploading them to Atypon.

If you notice tag names aren't getting matched with as many articles as you'd expect, consider updating your tags.txt file so, for example, "hospitality" and "tourism" are listed as separate tag names with the same tag code. 

Another idea is to try something more complex than string matching in a future version of this project. Adam Day has recommended an autoML https://cloud.google.com/natural-language/automl/entity-analysis/docs/.

## Formatting for the File Upload Handler
This script will write a file for Atypon's File Upload Handler. Make sure you include this file and the manifest in a zip file that has been named appropriately for the taxonomy you are updating. 

Be sure to do an incremental upload so you don't overwrite any existing taggings.




