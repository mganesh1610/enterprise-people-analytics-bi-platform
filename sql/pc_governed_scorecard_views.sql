-- Governed Self-Service Executive P&C Scorecard View (k-Anonymity & RBAC Safe)
    CREATE VIEW vw_pc_department_role_scorecard AS
    WITH dept_benchmarks AS (
        SELECT
            Department,
            AVG(MonthlyIncome) AS dept_avg_income,
            AVG(attrition_flag) * 100.0 AS dept_attrition_rate_pct,
            AVG(employee_experience_index) AS dept_avg_exi
        FROM stg_ibm_hr_employees
        GROUP BY Department
    ),
    role_aggregates AS (
        SELECT
            e.Department,
            e.JobRole,
            CAST(e.JobLevel AS INTEGER) AS JobLevel,
            COUNT(*) AS headcount,
            CAST(SUM(e.attrition_flag) AS INTEGER) AS separated_count,
            ROUND(AVG(e.attrition_flag) * 100.0, 2) AS attrition_rate_pct,
            ROUND((1.0 - AVG(e.attrition_flag)) * 100.0, 2) AS retention_rate_pct,
            ROUND(AVG(e.overtime_flag) * 100.0, 2) AS overtime_share_pct,
            ROUND(AVG(e.employee_experience_index), 3) AS avg_experience_index,
            ROUND(AVG(e.solution_training_adopted) * 100.0, 2) AS training_adoption_pct,
            ROUND(AVG(e.YearsAtCompany), 2) AS avg_tenure_years,
            ROUND(AVG(e.YearsSinceLastPromotion), 2) AS avg_years_since_promo,
            ROUND(AVG(e.compa_ratio), 3) AS avg_compa_ratio,
            CASE WHEN COUNT(*) < 5 THEN NULL ELSE ROUND(AVG(e.MonthlyIncome), 2) END AS rls_masked_avg_monthly_income
        FROM stg_ibm_hr_employees e
        GROUP BY e.Department, e.JobRole, e.JobLevel
    )
    SELECT
        r.*,
        ROUND(r.attrition_rate_pct - d.dept_attrition_rate_pct, 2) AS attrition_vs_dept_diff_pp,
        ROUND(r.avg_experience_index - d.dept_avg_exi, 3) AS exi_vs_dept_diff
    FROM role_aggregates r
    JOIN dept_benchmarks d ON r.Department = d.Department
    ORDER BY r.Department, r.JobLevel, r.JobRole;

    -- Self-Service Non-HR Leader View (Strictly Masks Individual Compensation & Sensitive PII)
    CREATE VIEW vw_self_service_leader_safe AS
    SELECT
        emp_hash_id,
        Department,
        JobRole,
        CAST(JobLevel AS INTEGER) AS JobLevel,
        tenure_band,
        OverTime,
        CAST(TrainingTimesLastYear AS INTEGER) AS TrainingTimesLastYear,
        CAST(solution_training_adopted AS INTEGER) AS solution_training_adopted,
        ROUND(employee_experience_index, 2) AS employee_experience_index,
        CAST(YearsAtCompany AS INTEGER) AS YearsAtCompany,
        CAST(YearsInCurrentRole AS INTEGER) AS YearsInCurrentRole,
        CAST(YearsSinceLastPromotion AS INTEGER) AS YearsSinceLastPromotion,
        Attrition
    FROM stg_ibm_hr_employees;

    -- External Workforce Labor-Market Benchmark View (Quarantining '?' Unknown Tokens)
    CREATE VIEW vw_external_workforce_benchmark AS
    WITH clean_market AS (
        SELECT
            occupation,
            education,
            sex,
            hours_per_week,
            high_comp_flag,
            overtime_schedule_flag
        FROM stg_uci_workforce_benchmark
        WHERE missing_field_flag = 0
    )
    SELECT
        occupation,
        COUNT(*) AS benchmark_workers,
        ROUND(AVG(hours_per_week), 2) AS avg_weekly_hours,
        ROUND(AVG(overtime_schedule_flag) * 100.0, 2) AS overtime_schedule_pct,
        ROUND(AVG(high_comp_flag) * 100.0, 2) AS upper_comp_band_pct
    FROM clean_market
    GROUP BY occupation
    ORDER BY benchmark_workers DESC;
