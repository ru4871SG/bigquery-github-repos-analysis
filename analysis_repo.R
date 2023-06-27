#third analysis - repos, commits, licenses
library(bigrquery) 
library(tidyverse)
# library(DBI)

github_repos <- dbConnect(
  bigrquery::bigquery(),
  project = "bigquery-public-data",
  dataset = "github_repos",
  billing = "<your-project-id>"
)

my_billing_id <- "<your-project-id>"

#we use sample_repos table instead of full commits table, because we want to analyze popular repos that are publicly accessible
sql_5 <- "
      SELECT * 
      FROM `bigquery-public-data.github_repos.sample_repos` 
      ORDER BY watch_count DESC
      LIMIT 30
"

data_from_sql_5 <- bq_project_query(x = my_billing_id, query = sql_5)
top_30_sample_repos <- bq_table_download(data_from_sql_5)

#as for this one, we can use the commits table instead of sample_commits, since we want to know popular authors from the full list
sql_6 <- "
      SELECT author.name, COUNT(author.name) as author_count 
      FROM `bigquery-public-data.github_repos.commits`
      GROUP BY author.name
      ORDER BY author_count DESC
      LIMIT 30
"

data_from_sql_6 <- bq_project_query(x = my_billing_id, query = sql_6)
top_30_authors <- bq_table_download(data_from_sql_6)

#same as sql_6 but for committers
sql_7 <- "
      SELECT committer.name, COUNT(committer.name) as committer_count 
      FROM `bigquery-public-data.github_repos.commits`
      GROUP BY committer.name
      ORDER BY committer_count DESC
      LIMIT 30
"

data_from_sql_7 <- bq_project_query(x = my_billing_id, query = sql_7)
top_30_committers <- bq_table_download(data_from_sql_7)
#looks like the top committer is "Github", and by wide margin, which most likely means everybody who doesn't put their name grouped together
if (top_30_committers[1, "name"] == 'GitHub') {
  top_30_committers <- top_30_committers[-1, ]
} else {
  top_30_committers <- top_30_committers
}

sql_8 <- "
      SELECT license, COUNT(license) as license_count
      FROM `bigquery-public-data.github_repos.licenses` 
      GROUP BY license
      ORDER BY license_count DESC
"

data_from_sql_8 <- bq_project_query(x = my_billing_id, query = sql_8)
top_licenses <- bq_table_download(data_from_sql_8)

sql_9 <- "
        WITH only_python AS (
            SELECT DISTINCT repo_name
            FROM `bigquery-public-data.github_repos.sample_files`
            WHERE path LIKE '%.py')
        SELECT commits.repo_name, COUNT(commit) AS commits_count
        FROM `bigquery-public-data.github_repos.sample_commits` AS commits
        JOIN only_python AS repofiles
        ON commits.repo_name = repofiles.repo_name
        GROUP BY commits.repo_name
        ORDER BY commits_count DESC
"
data_from_sql_9 <- bq_project_query(x = my_billing_id, query = sql_9)
python_top_commits <- bq_table_download(data_from_sql_9)

sql_10 <- "
        WITH only_js AS (
            SELECT DISTINCT repo_name
            FROM `bigquery-public-data.github_repos.sample_files`
            WHERE path LIKE '%.js')
        SELECT commits.repo_name, COUNT(commit) AS commits_count
        FROM `bigquery-public-data.github_repos.sample_commits` AS commits
        JOIN only_js AS repofiles
        ON commits.repo_name = repofiles.repo_name
        GROUP BY commits.repo_name
        ORDER BY commits_count DESC
"
data_from_sql_10 <- bq_project_query(x = my_billing_id, query = sql_10)
js_top_commits <- bq_table_download(data_from_sql_10)

sql_11 <- "
        WITH only_html AS (
            SELECT DISTINCT repo_name
            FROM `bigquery-public-data.github_repos.sample_files`
            WHERE path LIKE '%.html')
        SELECT commits.repo_name, COUNT(commit) AS commits_count
        FROM `bigquery-public-data.github_repos.sample_commits` AS commits
        JOIN only_html AS repofiles
        ON commits.repo_name = repofiles.repo_name
        GROUP BY commits.repo_name
        ORDER BY commits_count DESC
"
data_from_sql_11 <- bq_project_query(x = my_billing_id, query = sql_11)
html_top_commits <- bq_table_download(data_from_sql_11)

#let's export to csv
write.csv(top_30_sample_repos, "flexdashboard/top_30_sample_repos.csv")
write.csv(top_30_authors, "flexdashboard/top_30_authors.csv")
write.csv(top_30_committers, "flexdashboard/top_30_committers.csv")
write.csv(top_licenses, "flexdashboard/top_licenses.csv")
write.csv(python_top_commits, "flexdashboard/python_top_commits.csv")
write.csv(js_top_commits, "flexdashboard/js_top_commits.csv")
write.csv(html_top_commits, "flexdashboard/html_top_commits.csv")
