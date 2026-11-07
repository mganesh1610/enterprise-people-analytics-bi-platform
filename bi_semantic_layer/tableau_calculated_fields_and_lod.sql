-- ============================================================================
-- Enterprise People Analytics — Tableau FIXED LOD & Self-Service Governed Views
-- ============================================================================
-- Tableau Calculated Field Equivalents:
-- 1. [Job Level Median Monthly Income (LOD)]:
--    { FIXED [JobLevel] : MEDIAN([MonthlyIncome]) }
--
-- 2. [Employee Compa-Ratio (LOD)]:
--    [MonthlyIncome] / [Job Level Median Monthly Income (LOD)]
--
-- 3. [Department Baseline Attrition % (LOD)]:
--    { FIXED [Department] : AVG([attrition_flag]) }
--
-- 4. [k-Anonymity Safe Compensation Measure]:
--    IF COUNTD([emp_hash_id]) >= 5 THEN AVG([MonthlyIncome]) ELSE NULL END

SELECT
    Department,
    JobRole,
    JobLevel,
    headcount,
    separated_count,
    attrition_rate_pct,
    retention_rate_pct,
    overtime_share_pct,
    avg_experience_index,
    training_adoption_pct,
    avg_tenure_years,
    avg_years_since_promo,
    avg_compa_ratio,
    rls_masked_avg_monthly_income,
    attrition_vs_dept_diff_pp,
    exi_vs_dept_diff
FROM vw_pc_department_role_scorecard
ORDER BY Department, JobLevel, JobRole;
