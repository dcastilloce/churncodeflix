-- Familiarizing with the data
SELECT *
FROM subscriptions
LIMIT 100;

SELECT DISTINCT(segment)
FROM subscriptions;


-- Range of months to calculate churn rate
 
SELECT MIN(subscription_start) as min_subs_start, MAX(subscription_start) as max_subs_start
FROM subscriptions;

-- Analyzing trend
-- CTE months
WITH months AS (
  SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
  FROM subscriptions
  UNION
  SELECT
  '2017-02-01' as first_day,
  '2017-02-28' as last_day
  FROM subscriptions
  UNION
  SELECT
  '2017-03-01' as first_day,
  '2017-03-31' as last_day
  FROM subscriptions
), 
cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
), -- Joining subscriptions
status AS (
  SELECT id, first_day AS month,
  CASE
   WHEN (subscription_start < first_day AND ((subscription_end > first_day) OR(subscription_end IS NULL))) AND (segment = 87) THEN 1
   ELSE 0
  END AS is_active_87,
  CASE
   WHEN ((subscription_end BETWEEN first_day AND last_day) AND segment = 87) THEN 1
   ELSE 0
   END AS is_canceled_87,
  CASE
   WHEN (subscription_start < first_day AND ((subscription_end > first_day) OR(subscription_end IS NULL))) AND (segment = 30) THEN 1
   ELSE 0
  END AS is_active_30,
  CASE
   WHEN ((subscription_end BETWEEN first_day AND last_day) AND segment = 30) THEN 1
   ELSE 0
   END AS is_canceled_30
  FROM cross_join
), --Users active or canceled by segment
status_aggregate AS (
  SELECT month, SUM(is_active_87) AS sum_active_87, 
  SUM(is_canceled_87) AS sum_canceled_87,
  SUM(is_active_30) AS sum_active_30, SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY month
),
-- How much users did subscribed and canceled by month ans segment
churn_rate AS (
  SELECT month, ROUND(1.0 * sum_canceled_87 /sum_active_87, 3) AS churn_rate_87,
  ROUND(1.0 * sum_canceled_30 /sum_active_30, 3) AS churn_rate_30
FROM status_aggregate
), -- Churn rate
change AS(
  SELECT month, churn_rate_87,
churn_rate_87 - LAG(churn_rate_87, 1, 0) OVER (
  ORDER BY month) AS change_87, churn_rate_30, churn_rate_30 - LAG(churn_rate_30, 1, 0) OVER (
  ORDER BY month) AS change_30 
FROM churn_rate
),
perc_change AS (
  SELECT month, churn_rate_87,
  ROUND((change_87*100) / LAG(churn_rate_87,1,0) OVER(
   ORDER BY month
  ), 2) AS'%change_87',
  churn_rate_30,
  ROUND((change_30*100) / LAG(churn_rate_30,1,0) OVER(
   ORDER BY month
  ), 2) AS'%change_30'
  FROM change
) SELECT *
FROM perc_change -- %Change by segment between months






