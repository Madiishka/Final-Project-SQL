#1
WITH monthly_activity AS (
    SELECT
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m')  AS month
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m')
),
continuous_clients AS (
    SELECT ID_client
    FROM monthly_activity
    GROUP BY ID_client
    HAVING COUNT(DISTINCT month) = 12
)
SELECT
    t.ID_client,
    ROUND(SUM(t.Sum_payment) / COUNT(t.Id_check), 2)        AS avg_check,
    ROUND(SUM(t.Sum_payment) / 12, 2)                       AS avg_monthly_amount,
    COUNT(t.Id_check)                                        AS total_operations
FROM transactions_info t
JOIN continuous_clients cc ON t.ID_client = cc.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY t.ID_client
ORDER BY total_operations DESC;

#2a
SELECT
    DATE_FORMAT(date_new, '%Y-%m')              AS month,
    ROUND(SUM(Sum_payment) / COUNT(Id_check), 2) AS avg_check
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;

#2b
SELECT
    DATE_FORMAT(date_new, '%Y-%m')   AS month,
    COUNT(Id_check)                  AS total_operations,
    ROUND(COUNT(Id_check) / 
          COUNT(DISTINCT ID_client), 2) AS avg_operations_per_client
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;

#2c
SELECT
    DATE_FORMAT(date_new, '%Y-%m')      AS month,
    COUNT(DISTINCT ID_client)           AS active_clients
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;

#2d
WITH yearly_totals AS (
    SELECT
        COUNT(Id_check)    AS total_ops_year,
        SUM(Sum_payment)   AS total_sum_year
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
)
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COUNT(t.Id_check) AS month_ops,
    SUM(t.Sum_payment) AS month_sum,
    ROUND(COUNT(t.Id_check) * 100.0 / yt.total_ops_year, 2) AS ops_pct,
    ROUND(SUM(t.Sum_payment) * 100.0 / yt.total_sum_year, 2) AS sum_pct
FROM transactions_info t
CROSS JOIN yearly_totals yt
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY DATE_FORMAT(t.date_new, '%Y-%m'), yt.total_ops_year, yt.total_sum_year
ORDER BY month;

#2e
WITH monthly_gender AS (
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m')        AS month,
        COALESCE(c.Gender, 'NA')                AS gender,
        COUNT(t.Id_check)                       AS ops_count,
        SUM(t.Sum_payment)                      AS total_sum
    FROM transactions_info t
    LEFT JOIN customer_info c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m'), COALESCE(c.Gender, 'NA')
),
monthly_totals AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m')          AS month,
        COUNT(Id_check)                         AS total_ops,
        SUM(Sum_payment)                        AS total_sum
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)
SELECT
    mg.month,
    mg.gender,
    mg.ops_count,
    ROUND(mg.ops_count * 100.0 / mt.total_ops, 2)  AS ops_pct,
    ROUND(mg.total_sum, 2)                          AS total_sum,
    ROUND(mg.total_sum * 100.0 / mt.total_sum, 2)  AS sum_pct
FROM monthly_gender mg
JOIN monthly_totals mt ON mg.month = mt.month
ORDER BY mg.month, mg.gender;

#3
WITH age_groups AS (
    SELECT
        t.ID_client,
        t.Id_check,
        t.Sum_payment,
        t.date_new,
        CASE
            WHEN c.Age IS NULL THEN 'No Data'
            WHEN c.Age < 20    THEN 'Under 20'
            WHEN c.Age < 30    THEN '20-29'
            WHEN c.Age < 40    THEN '30-39'
            WHEN c.Age < 50    THEN '40-49'
            WHEN c.Age < 60    THEN '50-59'
            WHEN c.Age < 70    THEN '60-69'
            ELSE '70+'
        END AS age_group
    FROM transactions_info t
    LEFT JOIN customer_info c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
)

SELECT
    age_group,
    COUNT(Id_check)             AS total_operations,
    ROUND(SUM(Sum_payment), 2)  AS total_sum
FROM age_groups
GROUP BY age_group
ORDER BY age_group;


WITH age_groups AS (
    SELECT
        t.ID_client,
        t.Id_check,
        t.Sum_payment,
        t.date_new,
        QUARTER(t.date_new)     AS quarter,
        YEAR(t.date_new)        AS year,
        CASE
            WHEN c.Age IS NULL THEN 'No Data'
            WHEN c.Age < 20    THEN 'Under 20'
            WHEN c.Age < 30    THEN '20-29'
            WHEN c.Age < 40    THEN '30-39'
            WHEN c.Age < 50    THEN '40-49'
            WHEN c.Age < 60    THEN '50-59'
            WHEN c.Age < 70    THEN '60-69'
            ELSE '70+'
        END AS age_group
    FROM transactions_info t
    LEFT JOIN customer_info c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
quarterly_totals AS (
    SELECT
        year,
        quarter,
        SUM(Sum_payment)   AS total_sum_q,
        COUNT(Id_check)    AS total_ops_q
    FROM age_groups
    GROUP BY year, quarter
)
SELECT
    ag.year,
    ag.quarter,
    ag.age_group,
    COUNT(ag.Id_check) AS ops_count,
    ROUND(SUM(ag.Sum_payment), 2) AS total_sum,
    ROUND(AVG(ag.Sum_payment), 2) AS avg_check,
    ROUND(COUNT(ag.Id_check) * 100.0 / qt.total_ops_q, 2) AS ops_pct,
    ROUND(SUM(ag.Sum_payment) * 100.0 / qt.total_sum_q, 2) AS sum_pct
FROM age_groups ag
JOIN quarterly_totals qt
    ON ag.year = qt.year AND ag.quarter = qt.quarter
GROUP BY ag.year, ag.quarter, ag.age_group, qt.total_ops_q, qt.total_sum_q
ORDER BY ag.year, ag.quarter, ag.age_group;