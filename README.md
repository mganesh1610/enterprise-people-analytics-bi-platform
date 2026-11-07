# Enterprise People Analytics, Workforce Planning & Multi-BI Governance Platform

End-to-end **People & Culture (P&C) Business Intelligence, Workforce Planning, Retention Analytics, and Data Quality/Privacy Governance** platform built in **Python 3, SQL (`SQL Joins & CTEs`), Microsoft Power BI (`DAX`, `Power Query`, Row-Level Security), Tableau (`FIXED LOD`), and Qlik Sense (`Set Analysis` & `Section Access`)**.

## 1. Architecture & Business Capabilities

Partners across **Talent Acquisition, People Growth, Inclusion, Total Rewards, People Operations, Payroll, and PES Capability Owners** to deliver trusted recurring scorecards, self-service BI semantic models, and predictive retention insights:

1. **Automated P&C Data Preparation & 16-Gate Quality/Privacy Validation (`pipeline/run_people_analytics_pipeline.py`)**:
   - Ingests and SHA-256 verifies **34,031 public workforce and employee lifecycle records** across two primary datasets:
     - **IBM HR Analytics Employee Attrition, Compensation & Experience Dataset** (`1,470` employee records $\times$ `35` attributes; SHA-256 `a5c31e38bd7fafc9bc333884eb181b06b41b8e5e488e8f7ccb27199fb3be7659`).
     - **UCI Census Workforce & Compensation Benchmark Dataset** (`32,561` workforce records $\times$ `15` attributes; SHA-256 `5b00264637dbfec36bdeaab5676b0b309ff9eb788d63554ca0a249491c86603d`).
   - Enforces **16 programmatic data-quality and privacy controls (`16/16` passed, `100%`)**:
     - Deterministic SHA-256 PII pseudonymization (`EmployeeNumber` $\rightarrow$ `EMP-...`).
     - Self-service **k-anonymity cell suppression ($n < 5$)** across `6` small Department $\times$ JobLevel $\times$ Gender cells.
     - Quarantine of `3` zero-variance HRIS fields (`EmployeeCount`, `Over18`, `StandardHours`) and `2,399` external benchmark rows with unknown (`?`) occupation/workclass tokens (`30,162` clean benchmark rows retained).
     - Escalation of `94` out-of-band Compa-Ratio exceptions (`< 0.65` or `> 1.65`) to Total Rewards & Payroll owners.
2. **Multi-BI Semantic Layer (`bi_semantic_layer/` & `sql/`)**:
   - **Microsoft Power BI**: `bi_semantic_layer/powerbi_dax_measures_and_rls.dax` (DAX KPI measures, k-anonymity `IF([Total Headcount] < 5, BLANK(), ...)` wrappers, and `USERPRINCIPALNAME()` Row-Level Security).
   - **Qlik Sense**: `bi_semantic_layer/qlik_sense_load_and_set_analysis.qvs` (`Section Access` department security and `Set Analysis` expressions).
   - **Tableau & Governed SQL Views**: `bi_semantic_layer/tableau_calculated_fields_and_lod.sql` and `sql/pc_governed_scorecard_views.sql` (`vw_pc_department_role_scorecard`, `vw_self_service_leader_safe`, `vw_external_workforce_benchmark`).
3. **Statistical Reasoning & Predictive Retention Analytics**:
   - **Overtime Attrition Impact**: `30.53%` voluntary attrition among Overtime staff vs. `10.44%` among Non-Overtime staff ($\text{Odds Ratio} = 3.77\text{x}$, $\chi^2 = 89.04$, $p < 10^{-16}$).
   - **Employee Experience Index ($\text{EXI} \in [1, 4]$)**: Retained employees average `2.766` EXI vs. `2.547` among separated employees (Welch $t = 5.87$, $p = 4.37 \times 10^{-9}$).
   - **Total Rewards Compa-Ratio Equity**: Retained employees average `1.028` Compa-Ratio vs. `0.989` among separated employees ($t = 2.07$, $p = 0.0387$).
   - **Predictive Flight-Risk Model & K-Means ($K=4$) Segmentation**: Stratified 80/20 L2-regularized Logistic Regression achieves **`0.8466` holdout ROC-AUC**, **`0.7117` PR-AUC**, **`0.0836` Brier calibration score**, and **`3.50x` top-quintile lift** (capturing **`70.21%`** of voluntary separations in the top 20% risk tier).

## 2. Quickstart & Verification

```bash
python3 pipeline/run_people_analytics_pipeline.py
python3 -m unittest discover -s tests -v
```
