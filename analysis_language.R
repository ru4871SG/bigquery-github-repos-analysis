#First analysis - github repo languages 
library(bigrquery) 
library(tidyverse)
library(DBI)

github_repos <- dbConnect(
  bigrquery::bigquery(),
  project = "bigquery-public-data",
  dataset = "github_repos",
  billing = "<your-project-id>"
)


dbListTables(github_repos)

repo_languages <- tbl(github_repos, "languages")
glimpse(repo_languages)

my_billing_id <- "<your-project-id>"

#we can either work directly with SQL syntax or collect it first before we analyze in R
#let's start with sql syntax first.
sql <- "
SELECT language.name, COUNT(language.name) as language_count
FROM `bigquery-public-data.github_repos.languages`, UNNEST(language) as language
GROUP BY language.name
ORDER BY language_count DESC
"

data_from_sql <- bq_project_query(x = my_billing_id, query = sql)
table_from_sql <- bq_table_download(data_from_sql)
#table_from_sql is the result


#Alternative to table_from_sql, we can analyze it straight in R after we collect it.
# df_languages <- repo_languages %>%
#         collect()

#normnally, you would put the filter before you collect, but we need to unnest it, so I decided to collect it before I unnest and do the filter
# df_languages_unnested <- df_languages %>%
#             unnest(language) %>% #you can only unnest it once you collect() and save it first. You cannot do unnest directly from repo_languages before collect()
#             group_by(name) %>%
#             summarise(language_count = n(), .groups = "drop") %>%
#             arrange(desc(language_count))
#df_languages_unnested is the result

#we can compare the result of both table_from_sql and df_languages_unnested, they are the same
# head(table_from_sql)
# head(df_languages_unnested)

#let's just use one of them
language_ranking <- table_from_sql

#let's export to csv every time we run this script, so we can re-use it offline
write.csv(language_ranking, "flexdashboard/language_ranking.csv")