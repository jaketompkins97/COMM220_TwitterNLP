# COMM 220: Research Methods in Communication Science 
# Jake Tompkins (UID# 005331938)

# You'll need to have these libraries installed (uncomment and run lines 5-15)...
# instal.packageslibrary("rtweet")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("tidytext")
# install.packages("tidyverse")
# install.packages("reactable")
# install.packages("glue")
# install.packages("stringr")
# install.packages("httpuv")
# install.packages("dplyr")
# install.packages("purrr")


# Run these libraries (you may see warning messages about the libraries masking each other because they have similar functions...that's ok!)
library(rtweet)
library(dplyr)
library(tidyr)
library(tidytext)
library(tidyverse)
library(reactable)
library(glue)
library(stringr)
library(httpuv)
library(dplyr)
library(purrr)

# Collect 2000 tweets that contain the word covid
covid_tweet_df <- search_tweets("covid", n = 5000, include_rts = FALSE, lang = "en", geocode = lookup_coords("usa"))

# Collect 2000 generic tweets
control_tweet_df <- search_tweets("-covid", n = 5000, include_rts = FALSE, lang = "en", geocode = lookup_coords("usa"))

# Pulls out variables we are curious about (user ID, status ID, date/time, username, tweet content, likes, and URL)
covid_tweets <- covid_tweet_df %>%
  select(user_id, status_id, created_at, screen_name, text, favorite_count, urls_expanded_url)
control_tweets <- control_tweet_df %>%
  select(user_id, status_id, created_at, screen_name, text, favorite_count, urls_expanded_url)

# Attaches link to live tweet in data frame
covid_table_data <- select(covid_tweets, -user_id, -status_id)
control_table_data <- select(control_tweets, -user_id, -status_id)

covid_tweets <- covid_tweets %>%
  mutate(
    TweetURL = glue::glue("https://twitter.com/{screen_name}/status/{status_id}"),
    TweetLink = glue::glue(" <a href='{TweetURL}'>>> </a>"),
    Tweet = paste(text, TweetLink)
  )
control_tweets <- control_tweets %>%
  mutate(
    TweetURL = glue::glue("https://twitter.com/{screen_name}/status/{status_id}"),
    TweetLink = glue::glue(" <a href='{TweetURL}'>>> </a>"),
    Tweet = paste(text, TweetLink)
  )

covid_table_data <- covid_tweet_df %>%
  select(user_id, status_id, created_at, screen_name, text, favorite_count, retweet_count, urls_expanded_url) %>%
  mutate(
    Tweet = glue::glue("{text} <a href='https://twitter.com/{screen_name}/status/{status_id}'>>> </a>")
  )%>%
  select(DateTime = created_at, User = screen_name, Tweet, Likes = favorite_count, RTs = retweet_count, URLs = urls_expanded_url)
control_table_data <- control_tweet_df %>%
  select(user_id, status_id, created_at, screen_name, text, favorite_count, retweet_count, urls_expanded_url) %>%
  mutate(
    Tweet = glue::glue("{text} <a href='https://twitter.com/{screen_name}/status/{status_id}'>>> </a>")
  )%>%
  select(DateTime = created_at, User = screen_name, Tweet, Likes = favorite_count, RTs = retweet_count, URLs = urls_expanded_url)

# Produces a filterable HTML table to view the data (stop and show the class)
reactable::reactable(covid_table_data)

reactable(covid_table_data,
          filterable = TRUE, searchable = TRUE, bordered = TRUE, striped = TRUE, highlight = TRUE, showSortable = TRUE, defaultSortOrder = "desc", defaultPageSize = 25, showPageSizeOptions = TRUE, pageSizeOptions = c(25, 50, 75, 100, 200),
          columns = list(
            DateTime = colDef(defaultSortOrder = "asc"),
            User = colDef(defaultSortOrder = "asc"),
            Tweet = colDef(html = TRUE, minWidth = 10000, resizable = TRUE),
            Likes = colDef(filterable = FALSE, format = colFormat(separators = TRUE)),
            RTs = colDef(filterable = FALSE, format = colFormat(separators = TRUE)),
            URLs = colDef(html = TRUE)
          )
)

reactable::reactable(control_table_data)

reactable(control_table_data,
          filterable = TRUE, searchable = TRUE, bordered = TRUE, striped = TRUE, highlight = TRUE, showSortable = TRUE, defaultSortOrder = "desc", defaultPageSize = 25, showPageSizeOptions = TRUE, pageSizeOptions = c(25, 50, 75, 100, 200),
          columns = list(
            DateTime = colDef(defaultSortOrder = "asc"),
            User = colDef(defaultSortOrder = "asc"),
            Tweet = colDef(html = TRUE, minWidth = 10000, resizable = TRUE),
            Likes = colDef(filterable = FALSE, format = colFormat(separators = TRUE)),
            RTs = colDef(filterable = FALSE, format = colFormat(separators = TRUE)),
            URLs = colDef(html = TRUE)
          )
)

# Selects only the content of the tweets
tweets.Covid = covid_tweet_df %>% select(text)
tweets.Control = control_tweet_df %>% select(text)


# Remove http elements manually
tweets.Covid$stripped_text1 <- gsub("http\\S+","",tweets.Covid$text)
tweets.Control$stripped_text2 <- gsub("http\\s+","",tweets.Control$text)

# Use the unnest_tokens() function to convert to lowercase,
# remove punctuation, and add id for each tweet
tweets.Covid_stem <- tweets.Covid %>%
  select(stripped_text1) %>%
  unnest_tokens(word, stripped_text1)
tweets.Control_stem <- tweets.Control %>%
  select(stripped_text2) %>%
  unnest_tokens(word, stripped_text2)

# Remove stop words from list of words
cleaned_tweets.Covid <- tweets.Covid_stem %>%
  anti_join(stop_words)
cleaned_tweets.Control <- tweets.Control_stem %>%
  anti_join(stop_words)


## Begin sentiment analysis with nrc lexicon (code from Rick) for "sadness"

sents = get_sentiments("nrc")

sentiment = sents[which(sents[,2]=='sadness'),1]$word

cleaned_tweets.Covid$sentiment = 0
for (i in 1:nrow(cleaned_tweets.Covid)) {
  print(i)
  twtWords = tolower(unlist(strsplit(cleaned_tweets.Covid$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  cleaned_tweets.Covid$sentiment[i] = m_sentiment
}


ixes = sample(1:nrow(cleaned_tweets.Covid),10000)
sub_CovidDF = cleaned_tweets.Covid[ixes,]
sub_CovidDF$sentiment = 0
for (i in 1:nrow(sub_CovidDF)) {
  print(i)
  twtWords = tolower(unlist(strsplit(sub_CovidDF$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  sub_CovidDF$sentiment[i] = m_sentiment
}


covid_sentiment_twt = sub_CovidDF[sub_CovidDF$sentiment>0,]
covid_nonsentiment_twt = sub_CovidDF[sub_CovidDF$sentiment==0,]


cleaned_tweets.Control$sentiment = 0
for (i in 1:nrow(cleaned_tweets.Control)) {
  print(i)
  twtWords = tolower(unlist(strsplit(cleaned_tweets.Control$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  cleaned_tweets.Control$sentiment[i] = m_sentiment
}

ixes = sample(1:nrow(cleaned_tweets.Control),10000)
sub_ControlDF = cleaned_tweets.Control[ixes,]
sub_ControlDF$sentiment = 0
for (i in 1:nrow(sub_ControlDF)) {
  print(i)
  twtWords = tolower(unlist(strsplit(sub_ControlDF$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  sub_ControlDF$sentiment[i] = m_sentiment
}


control_sentiment_twt = sub_ControlDF[sub_ControlDF$sentiment>0,]
control_nonsentiment_twt = sub_ControlDF[sub_ControlDF$sentiment==0,]


# Quick histograms to see how many words with that sentiment were in each group of tweets 
hist(sub_CovidDF$sentiment, 
     main="Histogram for Covid Tweets", 
     xlab="Sadness Score", 
     border="black", 
     col="green",
     xlim=c(0.0,1.0),
     las=1, 
     breaks=6)
hist(sub_ControlDF$sentiment, 
     main="Histogram for Generic Tweets", 
     xlab="Sadness Score", 
     border="black", 
     col="grey",
     xlim=c(0.0,1.0),
     las=1, 
     breaks=6)



# Perform t-test for each group (I usually expect these results to be statistically significant)
t.test(sub_CovidDF$sentiment,sub_ControlDF$sentiment)


## Begin sentiment analysis with nrc lexicon (code from Rick) for "anticipation"

sents = get_sentiments("nrc")

sentiment = sents[which(sents[,2]=='anticipation'),1]$word

cleaned_tweets.Covid$sentiment = 0
for (i in 1:nrow(cleaned_tweets.Covid)) {
  print(i)
  twtWords = tolower(unlist(strsplit(cleaned_tweets.Covid$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  cleaned_tweets.Covid$sentiment[i] = m_sentiment
}


ixes = sample(1:nrow(cleaned_tweets.Covid),10000)
sub_CovidDF = cleaned_tweets.Covid[ixes,]
sub_CovidDF$sentiment = 0
for (i in 1:nrow(sub_CovidDF)) {
  print(i)
  twtWords = tolower(unlist(strsplit(sub_CovidDF$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  sub_CovidDF$sentiment[i] = m_sentiment
}


covid_sentiment_twt = sub_CovidDF[sub_CovidDF$sentiment>0,]
covid_nonsentiment_twt = sub_CovidDF[sub_CovidDF$sentiment==0,]


cleaned_tweets.Control$sentiment = 0
for (i in 1:nrow(cleaned_tweets.Control)) {
  print(i)
  twtWords = tolower(unlist(strsplit(cleaned_tweets.Control$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  cleaned_tweets.Control$sentiment[i] = m_sentiment
}

ixes = sample(1:nrow(cleaned_tweets.Control),10000)
sub_ControlDF = cleaned_tweets.Control[ixes,]
sub_ControlDF$sentiment = 0
for (i in 1:nrow(sub_ControlDF)) {
  print(i)
  twtWords = tolower(unlist(strsplit(sub_ControlDF$word[i]," ")))
  m_sentiment = mean(twtWords %in% sentiment)
  sub_ControlDF$sentiment[i] = m_sentiment
}


control_sentiment_twt = sub_ControlDF[sub_ControlDF$sentiment>0,]
control_nonsentiment_twt = sub_ControlDF[sub_ControlDF$sentiment==0,]


# Quick histograms to see how many words with that sentiment were in each group of tweets 
hist(sub_CovidDF$sentiment, 
     main="Histogram for Covid Tweets", 
     xlab="Anticipation Score", 
     border="black", 
     col="green",
     xlim=c(0.0,1.0),
     las=1, 
     breaks=6)
hist(sub_ControlDF$sentiment, 
     main="Histogram for Generic Tweets", 
     xlab="Anticipation Score", 
     border="black", 
     col="grey",
     xlim=c(0.0,1.0),
     las=1, 
     breaks=6)

# Perform t-test for each group (I usually expect these results not to be statistically significant)
t.test(sub_CovidDF$sentiment,sub_ControlDF$sentiment)
