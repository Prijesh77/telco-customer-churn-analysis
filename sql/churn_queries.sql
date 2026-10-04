-- Telco Customer Churn: SQL analysis
-- Dialect: SQLite (the notebook loads the CSV into a table named `customers`).
-- Author: Prijesh Shrestha

-- 1. Overall churn rate and monthly revenue lost
SELECT
    COUNT(*)                                                    AS customers,
    SUM(churn_flag)                                             AS churned,
    ROUND(100.0 * AVG(churn_flag), 1)                           AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn_flag = 1 THEN MonthlyCharges END), 0) AS monthly_revenue_lost,
    ROUND(100.0 * SUM(CASE WHEN churn_flag = 1 THEN MonthlyCharges END)
          / SUM(MonthlyCharges), 1)                             AS pct_of_monthly_revenue
FROM customers;

-- 2. Churn by contract type
SELECT
    Contract,
    COUNT(*)                          AS customers,
    ROUND(100.0 * AVG(churn_flag), 1) AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2)     AS avg_monthly_charge
FROM customers
GROUP BY Contract
ORDER BY churn_rate_pct DESC;

-- 3. Churn by tenure band (how long the customer has stayed)
SELECT
    CASE
        WHEN tenure <= 6  THEN '01: 0-6 months'
        WHEN tenure <= 12 THEN '02: 7-12 months'
        WHEN tenure <= 24 THEN '03: 13-24 months'
        WHEN tenure <= 48 THEN '04: 25-48 months'
        ELSE                   '05: 49-72 months'
    END                               AS tenure_band,
    COUNT(*)                          AS customers,
    ROUND(100.0 * AVG(churn_flag), 1) AS churn_rate_pct
FROM customers
GROUP BY tenure_band
ORDER BY tenure_band;

-- 4. Churn by payment method
SELECT
    PaymentMethod,
    COUNT(*)                          AS customers,
    ROUND(100.0 * AVG(churn_flag), 1) AS churn_rate_pct
FROM customers
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;

-- 5. Internet service x tech support: does support reduce churn for fibre customers?
SELECT
    InternetService,
    TechSupport,
    COUNT(*)                          AS customers,
    ROUND(100.0 * AVG(churn_flag), 1) AS churn_rate_pct
FROM customers
WHERE InternetService <> 'No'
GROUP BY InternetService, TechSupport
ORDER BY InternetService, TechSupport;

-- 6. Highest-risk segment: new, month-to-month, fibre, electronic check
SELECT
    COUNT(*)                                           AS customers,
    ROUND(100.0 * AVG(churn_flag), 1)                  AS churn_rate_pct,
    ROUND(SUM(MonthlyCharges), 0)                      AS monthly_revenue
FROM customers
WHERE Contract = 'Month-to-month'
  AND InternetService = 'Fiber optic'
  AND PaymentMethod = 'Electronic check'
  AND tenure <= 12;
