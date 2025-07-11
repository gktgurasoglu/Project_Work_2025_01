SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'project' 
    AND table_name = 'games_payments'; -- we examine the column names and data types of the files.

SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'project' 
    AND table_name = 'games_paid_users'; -- column names and data types of the files.
-- There is no data type we need to convert

SELECT 
    COUNT(*) AS total_rows,
    COUNT(user_id) AS id_non_null_row,
    COUNT(game_name) AS game_non_null_row,
    COUNT(payment_date) AS date_non_null_row,
    COUNT(revenue_amount_usd) AS amount_non_null_row
FROM 
    project.games_payments;  -- 3026 rows, no null values.
    
SELECT 
    COUNT(*) AS total_rows,
    COUNT(user_id) AS id_non_null_row,
    COUNT(game_name) AS game_non_null_row,
    COUNT(language) AS language_non_null_row,
    COUNT(has_older_device_model) AS device_non_null_row,
    COUNT(age) AS age_non_null_row
FROM 
    project.games_paid_users;  -- 383 satır var, hiç null değer yok.
-- There are no cells that we have to delete or fill in in certain ways.
    
SELECT 
    MIN(revenue_amount_usd) AS min_value,
    MAX(revenue_amount_usd) AS max_value,
    AVG(revenue_amount_usd) AS avg_value,
    STDDEV(revenue_amount_usd) AS std_dev
FROM 
    project.games_payments; -- we get an idea about income data. The mean(avg) is 21 dollars and sd.dev shows that the density of the distribution almost covers the min amount.

SELECT 
    MIN(age) AS min_value,
    MAX(age) AS max_value,
    AVG(age) AS avg_value,
    STDDEV(age) AS std_dev
FROM 
    project.games_paid_users; -- we get an idea of the age distribution. Sd.dev is a bit high, so the age distribution is concentrated between 16-30.

SELECT 
    MIN(payment_date) AS first_date,
    MAX(payment_date) AS last_date
FROM 
    project.games_payments; -- All transactions took place in 2022, starting in March and closing at the end of December.
-- We don't need to think in detail for the age calculation check (in terms of the quality of the accuracy of the data)

SELECT 
    count(distinct user_id) as benzersiz_kullanıcı
FROM 
    project.games_payments; -- We detect the number of unique users and compare it to the paid_users file; we find the same number: 383. We also understand that each user uses only 1 game.
-- We understand that the user ids of the two files are the same and there is no difference.
    
select  game_name,
        DATE_TRUNC('month', payment_date)::DATE AS payment_month,
        SUM(revenue_amount_usd) AS total_payment
    FROM project.games_payments
    GROUP BY game_name, DATE_TRUNC('month', payment_date)
    order by game_name, DATE_TRUNC('month', payment_date) -- monthly revenues of games. We find that Game1 is 3 months old (very recent) and Game2 is 6 months old (no data for the 11th month!).
-- Each user has played only 1 game and game1 is a very new game (3 months old) - in this context, game1/game/2 can be advertised in game3, and the first 3/6 months of game3 data can be requested for comparison.
-- It may cause us to reconsider the idea of removing game1 and game2 from the application and make different proposals.
    
SELECT
        user_id,
        game_name,
        language,
        has_older_device_model,
        age,
        generate_series(
            (SELECT MIN(DATE_TRUNC('month', payment_date)) FROM project.games_payments),
            (SELECT MAX(DATE_TRUNC('month', payment_date)) FROM project.games_payments),
            INTERVAL '1 month')::DATE AS payment_month
FROM project.games_paid_users -- For each user, we add 10 months to the rows, month by month. (So the previous months will appear for the user who is a member for the 12th month.) 383 users*10 months 3830 rows of data.
-- Each added month will be assigned a value opposite; New user, Empty/Passive, Active, Churn, ChurntoBack. It will be very helpful in our calculations.   

SELECT 
    sum(revenue_amount_usd) AS sum_value,
    DATE_TRUNC('month', payment_date)::DATE AS payment_month
FROM 
    project.games_payments
group by payment_month; -- MRR










