#Second analysis - file sizes
library(bigrquery) 
library(tidyverse)
# library(DBI)

github_repos <- dbConnect(
  bigrquery::bigquery(),
  project = "bigquery-public-data",
  dataset = "github_repos",
  billing = "<your-project-id>"
)


dbListTables(github_repos)

repo_contents <- tbl(github_repos, "contents")
glimpse(repo_contents)

my_billing_id <- "<your-project-id>"

sql_2 <- "
  SELECT binary, COUNT(binary) as binary_count
  FROM `bigquery-public-data.github_repos.contents`
  GROUP BY binary
"

data_from_sql_2 <- bq_project_query(x = my_billing_id, query = sql_2)
binary_files_count <- bq_table_download(data_from_sql_2)

#we use 1,000,000 sample size because I use free account anyway
sql_3 <- "
    SELECT size
    FROM `bigquery-public-data.github_repos.contents`
    WHERE binary = true
    ORDER BY RAND()
    LIMIT 1000000
"

github_repo_sizes <- dbGetQuery(github_repos, sql_3)

BYTES_PER_MB = 2^20

df_repo_sizes_true <- data.frame(size = github_repo_sizes / BYTES_PER_MB)

sql_4 <- "
    SELECT size
    FROM `bigquery-public-data.github_repos.contents`
    WHERE binary = false
    ORDER BY RAND()
    LIMIT 1000000
"

github_repo_sizes_2 <- dbGetQuery(github_repos, sql_4)

df_repo_sizes_false <- data.frame(size = github_repo_sizes_2 / BYTES_PER_MB)

#let's check the equality of variances, I expect very large difference
result <- var.test(df_repo_sizes_true$size, df_repo_sizes_false$size)
print(result)

#let's do a Welch's t-test
result_test <- t.test(df_repo_sizes_true, df_repo_sizes_false, var.equal = FALSE)
print(result_test)
#the variance of the first group is approx. > 11x the variance of the second group

#let's export to csv
write.csv(binary_files_count, "flexdashboard/binary_files_count.csv")
write.csv(df_repo_sizes_true, "flexdashboard/df_repo_sizes_true.csv")
write.csv(df_repo_sizes_false, "flexdashboard/df_repo_sizes_false.csv")
