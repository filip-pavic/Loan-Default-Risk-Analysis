/*=====================================================================================
PHASE 1: EXPLORATORY ANALYSIS / QUALITY CHECKS
=====================================================================================*/

SELECT TOP 10 * FROM application_test;
SELECT TOP 10 * FROM application_train;
SELECT TOP 10 * FROM bureau;
SELECT TOP 10 * FROM bureau_balance;
SELECT TOP 10 * FROM installments_payments;

SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN DAYS_INSTALMENT IS NULL THEN 1 ELSE 0 END) AS missing_installment_dates,
    SUM(CASE WHEN DAYS_ENTRY_PAYMENT IS NULL THEN 1 ELSE 0 END) AS missing_actual_payment_dates,
    SUM(CASE WHEN AMT_PAYMENT IS NULL THEN 1 ELSE 0 END) AS missing_payment_amounts
FROM installments_payments;
-- Checking payment dates before calculating late payment metrics

SELECT 
    MIN(DAYS_EMPLOYED) AS max_employment_history_days, -- Deepest in the past
    MAX(DAYS_EMPLOYED) AS min_employment_history_days, -- Closest to today
    COUNT(CASE WHEN DAYS_EMPLOYED = 365243 THEN 1 END) AS anomaly_count,
    COUNT(*) AS total_rows
FROM application_train;
-- Checking for abnormal boundaries or bad values in demographics data


/*=====================================================================================
PHASE 2: RISK SEGMENTATION / INSIGHT GENERATION
=====================================================================================*/

SELECT 
    COUNT(*) AS total_applicants,
    SUM(CAST(TARGET AS INT)) AS total_defaults,    (SUM(CAST(TARGET AS FLOAT)) / COUNT(*)) * 100 AS baseline_default_rate_percentage
FROM application_train;
-- This query shows me what percentage of people are currently failing to pay back their loans, which gives me a baseline default rate
-- This query will serve me as comparison with further queries
-- 8.07% OF PEOPLE HOME CREDIT LEND MONEY TO, FAILS TO PAY IT BACK, gross margin not looking good 

SELECT TOP 10 
    OCCUPATION_TYPE, 
    NAME_INCOME_TYPE, 
    DAYS_BIRTH / -365 AS age, 
    DAYS_EMPLOYED
FROM application_train
WHERE DAYS_EMPLOYED = 365243;
-- This query shows me that people with the 365243 value have income types like PENSIONER AND NO LISTED OCCUPATION. It represents UNEMPLOYED.
-- erifying if the anomaly maps perfectly to the Pensioner income type:
SELECT 
    NAME_INCOME_TYPE,
    COUNT(*) AS total_people,
    SUM(CASE WHEN DAYS_EMPLOYED = 365243 THEN 1 ELSE 0 END) AS people_with_anomaly
FROM application_train
GROUP BY NAME_INCOME_TYPE;
-- 100% of Pensioner income types have 365243 anomaly, meaning it is a system placeholder for UNEMPLOYED**************IMPORTANT***************

-- What is the default risk for this exact segment?:
SELECT 
    CASE WHEN DAYS_EMPLOYED = 365243 THEN 'Unemployed / Pensioner' ELSE 'Employed' END AS employment_status,
    COUNT(*) AS total_applicants,
    SUM(CAST(TARGET AS INT)) AS total_defaults,
    (SUM(CAST(TARGET AS FLOAT)) / COUNT(*)) * 100 AS default_rate_percentage
FROM application_train
GROUP BY CASE WHEN DAYS_EMPLOYED = 365243 THEN 'Unemployed / Pensioner' ELSE 'Employed' END;
-- This query checks if the employment anomaly we found impacts risk
-- Result: Employed default rate is 8.64%, Unemployed/Pensioner is 5.41%
-- Insight: Pensioners default less than the baseline (8.07%), likely due to stable, guaranteed retirement income streams.

SELECT 
    SK_ID_CURR, 
    COUNT(SK_ID_BUREAU) AS total_past_loans
FROM bureau
GROUP BY SK_ID_CURR;
-- this shows me how many loans people have

SELECT
    SK_ID_CURR,
    AVG(CASE WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT THEN 1.0 ELSE 0.0 END) * 100 AS PCT_late_payments
FROM installments_payments
GROUP BY SK_ID_CURR;
-- this query shows what percentage of their monthly bills people paid past the due date

SELECT 
    AVG(CASE WHEN b.total_past_loans >= 5 THEN CAST(app.TARGET AS FLOAT) ELSE NULL END) * 100 AS segment_heavy_borrowers_default_rate,
    AVG(CASE WHEN i.PCT_late_payments > 25 THEN CAST(app.TARGET AS FLOAT) ELSE NULL END) * 100 AS segment_late_payers_default_rate
FROM application_train AS app
LEFT JOIN (
    SELECT SK_ID_CURR, COUNT(SK_ID_BUREAU) AS total_past_loans
    FROM bureau
    GROUP BY SK_ID_CURR) AS b ON app.SK_ID_CURR = b.SK_ID_CURR
LEFT JOIN (
    SELECT SK_ID_CURR, AVG(CASE WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT THEN 1.0 ELSE 0.0 END) * 100 AS PCT_late_payments
    FROM dbo.installments_payments
    GROUP BY SK_ID_CURR) AS i ON app.SK_ID_CURR = i.SK_ID_CURR;
/*This query shows the following:
segment_heavy_borrowers_deafult_rate: 7.63%
segment_late_payers_default_rate: 8.17%
This means that 7.63% of all Home Credit loaners have other loans with other banks
AND
8.17% of all Home Credit loaners are late payers of their bills
COMPARING THIS TO OUR BASELINE of 8.07% PEOPLE WHO DEFAULT WE GAIN FOLLOWING INSIGHT:
1. PEOPLE WHO HAVE 5 OR MORE LOANS WITH OTHER BANKS DEFAULT LESS THAN THE AVERAGE PERSON (7.68% vs 8.07%)
2. PEOPLE WHO PAY THEIR BILLS LATE MORE THAN 25% OF THE TIME DEFAULT MORE THAN THE AVERAGE PERSON (8.17% vs 8.07%)
CONCLUSION: INTERNAL BEHAVIORAL DATA IS STRONGER WARNING SIGN TO POTENTIAL DEFAULT RATHER THAN PEOPLE HAVING MULTIPLE EXTERNAL LOANS*/

SELECT 
    AVG(CASE WHEN b.has_external_writeoff = 1 THEN CAST(app.TARGET AS FLOAT) ELSE NULL END) * 100 AS external_writeoff_default_rate
FROM application_train AS app
    INNER JOIN (
    SELECT 
        bu.SK_ID_CURR,
        MAX(CASE WHEN bb.STATUS = '5' THEN 1 ELSE 0 END) AS has_external_writeoff
    FROM bureau AS bu
    INNER JOIN dbo.bureau_balance AS bb ON bu.SK_ID_BUREAU = bb.SK_ID_BUREAU
    GROUP BY bu.SK_ID_CURR) AS b ON app.SK_ID_CURR = b.SK_ID_CURR;
--THIS QUERY SHOWS THAT IF A CUSTOMER HAS A HISTORY OF A BAD DEBT (STATUS = 5) AT A COMPLETELY DIFFERENT BANK, THEY ARE CLOSE TO 37% MORE LIKELY TO DEFAULT ON HOME CREDIT.
-- 37% WAS FOUND BY: (11.02% - 8.07%)/8.07% = 0.3655 * 100 = 36.5%
