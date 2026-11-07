# Enterprise People Analytics — Metric Definitions, Data Limitations & Escalation Procedures

## 1. Standard People & Culture (P&C) KPI Dictionary

| Metric Name | Formula / Technical Definition | Business Owner | Self-Service Privacy Rule |
| :--- | :--- | :--- | :--- |
| **Active & Historical Headcount** | $\text{COUNT}(\text{DISTINCT } \texttt{emp\_hash\_id})$ | People Operations | Unrestricted at aggregate level; suppress slices with $n < 5$. |
| **Voluntary Attrition Rate (%)** | $\frac{\sum \mathbb{I}(\texttt{Attrition} = \text{'Yes'})}{\text{Total Headcount}} \times 100$ | Talent Acquisition & People Growth | Suppress demographic/role slices where $\text{Headcount} < 5$. |
| **Workforce Retention Rate (%)** | $100\% - \text{Voluntary Attrition Rate (\%)}$ | People Operations | Suppress demographic/role slices where $\text{Headcount} < 5$. |
| **Compa-Ratio** | $\frac{\texttt{MonthlyIncome}_i}{\text{Median}(\texttt{MonthlyIncome}_{\text{JobLevel}})}$ | Total Rewards & Payroll | Individual values restricted to HR/Total Rewards; masked in `vw_self_service_leader_safe`. |
| **Employee Experience Index (EXI)** | $\frac{1}{4}(\texttt{JobSat} + \texttt{EnvSat} + \texttt{WorkLifeBalance} + \texttt{RelSat}) \in [1.0, 4.0]$ | PES Capability Owner | Aggregated only; individual survey responses never exposed to line managers. |
| **Training & Solution Adoption (%)** | $\frac{\sum \mathbb{I}(\texttt{TrainingTimesLastYear} \ge 2)}{\text{Total Headcount}} \times 100$ | People Growth & PES | Unrestricted for self-service operational tracking. |
| **Promotion Stagnation Ratio** | $\frac{\texttt{YearsSinceLastPromotion}}{\max(\texttt{YearsAtCompany}, 1)}$ | People Growth | Aggregated by Job Role and Tenure Band for workforce planning. |

---

## 2. Analytical Storytelling Framework: Observed Results vs. Interpretation vs. Recommendations

| Analytical Pillar | Observed Result (Verified Data Fact) | Statistical Interpretation (Inference & Drivers) | Practical P&C Recommendation |
| :--- | :--- | :--- | :--- |
| **Overtime & Workload Sustainability** | Employees working overtime (`OverTime = Yes`) exhibit a **30.53%** attrition rate compared to **10.44%** for standard-schedule staff. | Overtime increases voluntary separation odds by **3.77x** ($\chi^2 = 89.04, p < 10^{-16}$), making workload intensity the #1 operational predictor of turnover. | Partner with People Operations and business leaders to cap consecutive overtime quarters and reallocate headcount requisitions to high-overtime Job Roles (`Sales Executive`, `Laboratory Technician`). |
| **Employee Experience (PES) & Environment** | Retained employees average **2.766 EXI** vs. **2.547 EXI** among separated employees across the 4-pillar survey. | Welch two-sample test confirms a highly significant experience gap ($t = 5.87, p = 4.37 \times 10^{-9}$), concentrated in `EnvironmentSatisfaction` and `WorkLifeBalance`. | Trigger automated HRBP check-ins when department quarterly EXI drops below `2.60` and pair manager enablement with flexible scheduling pilots. |
| **Total Rewards & Pay Equity (Compa-Ratio)** | Separated employees hold a lower mean Compa-Ratio (**0.989**) than retained peers (**1.028**), with **94** records falling outside `[0.65, 1.65]`. | Sub-median band positioning significantly accelerates early-career turnover ($t = 2.07, p = 0.0387$), particularly when combined with promotion waits $>3$ years. | Escalate the 94 out-of-band Compa-Ratio exceptions to Total Rewards for mid-year equity adjustment review. |
| **Predictive Retention & Flight-Risk Triage** | L2-regularized Logistic Regression achieves **0.8466 holdout ROC-AUC** (`0.0836` Brier score) and **3.50x top-quintile lift**, capturing **70.21%** of separations in the top 20% risk tier. | Combining overtime status, EXI, Compa-Ratio, and tenure band isolates flight-risk cohorts before resignation occurs. | Deploy governed department-level flight-risk heatmaps in Power BI, Tableau, and Qlik Sense while masking individual risk scores from non-HR line managers. |

---

## 3. Data Limitations & Escalation Procedures

1. **Cross-Sectional vs. Longitudinal Snapshot Limitation:** The primary HR dataset (`1,470` employees) represents a cross-sectional snapshot without exact termination timestamps (`YYYY-MM-DD`); therefore, tenure survival curves reflect completed years (`YearsAtCompany`) rather than calendar-month hazard rates.
2. **External Benchmark Missing-Token Quarantine:** In the `32,561`-row UCI Census Workforce Benchmark, `2,399` rows contain unknown (`?`) occupation, workclass, or country codes. These rows are quarantined via `missing_field_flag = 1` and excluded from occupation rate denominators (`30,162` clean rows retained) to prevent denominator distortion.
3. **Escalation Routing:**
   - **HRIS Schema & Primary-Key Discrepancies (`DQ-03`, `DQ-04`, `DQ-08`, `DQ-09`):** Escalate to **People Information & Systems**.
   - **Compensation Band & Payroll Outliers (`DQ-10` — 94 Compa-Ratio exceptions):** Escalate to **Total Rewards & Payroll Governance**.
   - **Small-Cell Privacy & RBAC Exceptions (`DQ-06`, `DQ-07`, `DQ-16` — 6 suppressed cells with $n < 5$):** Escalate to **P&C Data Privacy Officer**.
