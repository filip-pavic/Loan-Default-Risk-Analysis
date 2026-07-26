# Home Credit Default Risk Analytics
> **Identifying Triggers for Credit Default Risk**

---

## Table of Contents
- [Project Background \& Business Problem](#project-background--business-problem)
- [Data Architecture \& Quality Verification](#data-architecture--quality-verification)
- [The Analytical Framework (SQL Skills)](#-the-analytical-framework-sql-skills)
- [Key Insights \& Findings](#key-insights-and-findings)
  - [Visual Dashboards](#interactive-power-bi-dashboards)
- [Data-Driven Strategic Recommendations](#data-driven-strategic-recommendations)
- [Dataset Source and Data Scope](#dataset-source-and-data-scope)

---

## Project Background & Business Problem

Home Credit faces compressed gross margins due to loan defaults, creating a critical business need to optimize risk assessment for incoming credit applications.
The primary business objective of this project is to minimize default rates by identifying exactly which customer behaviors, internal payment disciplines, and external credit bureau histories correlate with financial distress. 

### Key Questions Approaching the Analysis With:
1. **Baseline Risk:** What is our current baseline exposure across the total portfolio?
2. **Volume vs. Behavior:** Do clients that have a high volume of external loans indicate higher risk, or should we focus on internal payment tracking which will provide a more accurate warning sign?
3. **Severe Bureau Alerts:** How heavily does a history of external debt write offs impact an applicant's default probability at our institution?
4. **Data Anomaly Impact:** Does the system's massive 1,000-year employment data anomaly hide a high risk or low risk customer segment?

---

## Data Quality Check

Before calculating risk metrics, I checked data quality using SQL across transactional ledger (`installments_payments`) and external records (`bureau_balance`) to ensure metric integrity.

### Data Completeness
* **Completeness:** Checked date alignments (`DAYS_INSTALMENT`, `DAYS_ENTRY_PAYMENT`) and financial amounts (`AMT_PAYMENT`) making sure there is zero distortion in late payment calculations.
* **Structural Volume:** Profiled a large dataset consisting of **307,511 total applicants** and successfully handled and analysed their installment payments across millions of rows (10,000,000+)

### Anomaly Isolation
* A data quality check on the `DAYS_EMPLOYED` variable showed an extreme outlier placeholder value of `365243` (representing exactly 1,000 years in the past).
* **Discovery Step:** By mapping this anomaly against demographic traits, I verified that 100% of these records belong to the **Pensioner** income type who have no listed corporate occupation.
* **Handling Strategy:** Instead of dropping these "bad values," I isolated them into a standalone customer segment to evaluate their specific default risk independently.

---

## The Analytical Framework (SQL Skills)

To build this analysis, I aggregated millions of raw transactional rows down to the unique applicant level:
* **Exploratory Data Profiling:** `TOP 10`, `COUNT`, `MIN`, `MAX` boundary auditing
* **Transactional Aggregations:** Dynamic calculation of customer-level payment delinquency percentages (`AVG(CASE WHEN...)`) across multi-million-row ledgers
* **Complex Relational Joins:** Intersecting core applicant tracking files with aggregated subqueries via `LEFT JOIN` and `INNER JOIN` to prevent row duplication
* **Risk Logic Modeling:** Implementation of programmatic bit flags (`MAX(CASE WHEN...)`) to isolate external credit write off statuses

---

## Key Insights and Findings

### 1. Portfolio Baseline Exposure
Across the entire baseline population, the portfolio default rate sits at **exactly 8.07%**. This serves as the benchmark for evaluating all sub segments.

### 2. Behavioral Delinquency vs. Credit Volume
Analysis of internal payment tracking versus external loan capacity shows contrast to the traditional risk assumptions:

| Risk Segment | Criteria | Default Rate | Risk vs. Baseline |
| :--- | :--- | :---: | :---: |
| **Baseline Portfolio** | All Approved Applicants | **8.07%** | *Benchmark* |
| **Heavy Borrowers** | 5+ External Loans at Other Banks | **7.63%** | **Lower Risk (-0.44%)** |
| **Late Payers** | Internal Installments Paid Late >25% of Time | **8.17%** | **Higher Risk (+0.10%)** |

> **Conclusion:** Internal behavioral data is a stronger warning sign of potential default than an applicant's amount of external credits. Having multiple active lines of credit does not drive up the chance that the client is going to default, infact, might be a sign of security.

### 3. High-Impact Severe Risk Triggers
Evaluating month-by-month external credit bureau histories (`STATUS = 5`) exposed our most aggressive risk trigger:
* **External Write-Off Default Rate:** **11.02%**
* **Relative Risk Increase Formula:**
$$\text{Relative Risk Jump} = \frac{11.02\%}{8.07\%} - 1 = +36.55\%$$

> **Insight:** Applicants with a history of severe bad debt at a completely separate bank suffer a **36.55% relative jump** in default probability when entering our portfolio.

---

### Interactive Power BI Dashboards

Access DAX used here: [`/dax/dax_measures.dax`](./dax/dax_measures.dax)

#### Page 1: Executive Portfolio Risk Overview
You can access the interractive dashboard here:
https://app.powerbi.com/view?r=eyJrIjoiYTYwNGJkNjYtMjZjNi00OWFiLThmYTQtNzUyYjAwNGEzOTVjIiwidCI6ImQ5NzRiNGRmLWVlYzItNDMzZS1hOTE4LTNmZTE4NDEyNzM1ZiIsImMiOjh9

<img width="1371" height="764" alt="image" src="https://github.com/user-attachments/assets/0cf3dc85-fa1c-4e72-b61b-065fe761f04d" />


*Figure 1: Executive Risk Overview highlighting baseline portfolio metrics, payment delinquency behaviors, and severe external credit write off triggers.*

---

### 4. Risk Profile of the 1,000-Year Data Anomaly
Evaluating the "Pensioner" anomaly isolated in Phase 1 showed a highly stable safe segment:
* **Standard Employed Applicants:** **8.64%** default rate.
* **Pensioner Anomaly Segment (`365243` days):** **5.41%** default rate.

> **Insight:** Despite their technical "unemployed" system status, pensioners are significantly less likely to default than standard working class individuals. This is most likely due to stable, pension income.

#### Page 2: Demographic Risk & Anomaly Deep-Dive
You can access full interractive dashboard here:
https://app.powerbi.com/view?r=eyJrIjoiYTYwNGJkNjYtMjZjNi00OWFiLThmYTQtNzUyYjAwNGEzOTVjIiwidCI6ImQ5NzRiNGRmLWVlYzItNDMzZS1hOTE4LTNmZTE4NDEyNzM1ZiIsImMiOjh9

<img width="1371" height="765" alt="image" src="https://github.com/user-attachments/assets/04b87b3c-f088-4921-afe2-a6ba3b7c871c" />


*Figure 2: Demographic Deep-Dive displaying the safe Pensioner segment (5.41% default rate), borrower age trajectories, and applicant volume distributions.*

---

## Data-Driven Strategic Recommendations

1. **Implement an Automated Rejection Gate for External Write-Offs:** Configure the automated underwriting system to trigger immediate declines or mandatory credit committee escalation for any applicant with an external credit bureau history matching `STATUS = 5`. Eliminating this segment protects the bank from an exposure block carrying a **36.55% relative risk spike**.
2. **Deprioritize Total External Loan Volume Penalties:** Revise credit scoring models to stop penalizing applicants solely for maintaining 5 or more external accounts. The data proves these heavy borrowers perform **0.44% better** than the baseline portfolio average.
3. **Enforce Tiered Adjustments on Internal Repayment Delinquency:** Utilize internal behavioral tracking to automatically reduce credit limits or apply interest rate premiums on active accounts as soon as their internal installment late payment frequency crosses the 25% threshold.
4. **Capitalize on the Pensioner Segment:** Adjust marketing and acquisition parameters to actively attract pensioner applicants. While the core system flags them as unemployed, their exceptionally low default rate (**5.41% vs. 8.64% for working class**) makes them an incredibly safe, high margin asset class.

---

## Dataset Source and Data Scope

The dataset used in this analysis originates from the [Home Credit Default Risk competition hosted on Kaggle](https://www.kaggle.com/c/home-credit-default-risk). Due to GitHub's file size limitations, the raw `.csv` files are not stored in this repository.

The data used in this project consists in total of 10 tables, of which I used five, extracted from the Kaggle Home Credit Default Risk dataset, centered around current loan applicants identified by their unique ID (SK_ID_CURR). The backbone of the dataset comprises application_train.csv (307,511 rows × 122 columns) and application_test.csv (48,744 rows × 121 columns), which store static applicant profiles, financial demographics, and the binary classification target. To capture historical credit behavior, current applicant profiles are linked to bureau.csv (1,716,428 rows × 17 columns), containing records of the clients' prior loans from other financial institutions. This external credit history is further explained by bureau_balance.csv (~27.3 million rows × 3 columns), which provides a granular monthly tracking of payment statuses for those external bureau accounts via a secondary identifier (SK_ID_BUREAU). Finally, installments_payments.csv (13,605,401 rows × 8 columns) captures the payment behavior on previous internal Home Credit loans, recording the precise amounts and dates of scheduled versus actual repayments.
I chose only these 5 tables because I wanted to focus on the depth of the data insights that can be found, in regards to the respective tables.

You can access and download the complete relational database directly from Kaggle.
