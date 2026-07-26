# DAX Measures — HomeCredit Default Risk Analysis

Measures used to look at default rates and how risk shifts across different borrower segments, compared to the overall baseline.

---

### Total Applicants
```dax
Total Applicants = COUNTROWS('application_train')
```
Total number of applications in the dataset.

### Total Defaults
```dax
Total Defaults = SUM('application_train'[TARGET])
```
Sums the target flag (1 = defaulted) to get the total count of defaults.

### Default Rate
```dax
Default Rate = 
DIVIDE(
    [Total Defaults], 
    [Total Applicants], 
    0
)
```
Defaults as a share of total applicants; the core risk metric.

### Baseline Default Rate
```dax
Baseline Default Rate = 
CALCULATE(
    [Default Rate], 
    ALL('application_train')
)
```
The overall default rate with all filters removed, so it stays constant no matter what segment you're viewing. Used as the reference point for comparison.

### Relative Risk Increase
```dax
Relative Risk Increase = 
DIVIDE(
    [Default Rate] - [Baseline Default Rate], 
    [Baseline Default Rate], 
    0
)
```
How much higher (or lower) a segment's default rate is compared to the baseline, as a percentage. Makes it easy to say "this group is 40% riskier than average" instead of just comparing raw rates.

### Heavy Borrower Segment
```dax
Heavy Borrower Segment = 
IF(
    RELATED('Dim_Bureau_Summary'[Total_Past_Loans]) >= 5, 
    "5+ External Loans", 
    "< 5 External Loans"
)
```
Splits applicants into two groups based on how many external loans they've had, pulled from the bureau summary table.

### Late Payment Segment
```dax
Late Payment Segment = 
IF(
    RELATED('Dim_Installments_Summary'[PCT_Late_Payments]) > 25, 
    "Late Payer (>25%)", 
    "On-Time / Mild Late"
)
```
Flags applicants who've been late on more than a quarter of their past installments.

### WriteOff Segment
```dax
WriteOff Segment = 
IF(
    RELATED('Dim_Bureau_Summary'[Has_External_Writeoff]) = 1, 
    "External Write-Off (Status 5)", 
    "No Write-Off History"
)
```
Flags applicants who have a prior loan written off, based on the bureau's status code.
