#!/usr/bin/env python3
"""Unit and boundary test suite for the Enterprise People Analytics & BI Governance Platform."""

from __future__ import annotations

import csv
import json
import sqlite3
import unittest
from pathlib import Path

from pipeline.run_people_analytics_pipeline import (
    IBM_HR_SHA256,
    OUTPUT_DIR,
    UCI_ADULT_SHA256,
    pseudonymize_employee_id,
    run_pipeline,
)


class TestPeopleAnalyticsPlatform(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.summary = run_pipeline()

    def test_01_dataset_scale_and_provenance(self) -> None:
        self.assertEqual(self.summary["combined_records_processed"], 34031)
        self.assertEqual(self.summary["ibm_hr_employees"], 1470)
        self.assertEqual(self.summary["ibm_hr_columns"], 35)
        self.assertEqual(self.summary["uci_workforce_benchmark_rows"], 32561)
        self.assertEqual(self.summary["uci_workforce_clean_rows"], 30162)
        self.assertEqual(self.summary["uci_workforce_quarantined_rows"], 2399)

    def test_02_all_16_data_quality_gates_pass(self) -> None:
        self.assertEqual(self.summary["data_quality_gates_passed"], 16)
        self.assertEqual(self.summary["data_quality_gates_total"], 16)
        audit_csv = OUTPUT_DIR / "pc_data_quality_16_gates_audit.csv"
        self.assertTrue(audit_csv.exists())
        with audit_csv.open(encoding="utf-8") as f:
            rows = list(csv.DictReader(f))
        self.assertEqual(len(rows), 16)
        self.assertTrue(all(r["status"] == "PASS" for r in rows))

    def test_03_privacy_pseudonymization_and_k_anonymity(self) -> None:
        masked = pseudonymize_employee_id(1001)
        self.assertTrue(masked.startswith("EMP-"))
        self.assertEqual(len(masked), 16)
        self.assertEqual(self.summary["small_cells_suppressed_k_anonymity"], 6)

        db_path = OUTPUT_DIR / "people_analytics_warehouse.sqlite"
        conn = sqlite3.connect(str(db_path))
        cur = conn.cursor()
        # Verify non-HR self-service view strips MonthlyIncome and EmployeeNumber
        cur.execute("PRAGMA table_info(vw_self_service_leader_safe);")
        cols = {row[1] for row in cur.fetchall()}
        self.assertNotIn("MonthlyIncome", cols)
        self.assertNotIn("EmployeeNumber", cols)
        self.assertIn("emp_hash_id", cols)

        # Verify k-anonymity suppression in executive scorecard when headcount < 5
        cur.execute(
            "SELECT COUNT(*) FROM vw_pc_department_role_scorecard WHERE headcount < 5 AND rls_masked_avg_monthly_income IS NOT NULL;"
        )
        leaked_cells = cur.fetchone()[0]
        self.assertEqual(leaked_cells, 0)
        conn.close()

    def test_04_statistical_hypothesis_metrics(self) -> None:
        self.assertAlmostEqual(self.summary["overall_attrition_rate_pct"], 16.12, places=2)
        self.assertAlmostEqual(self.summary["overtime_attrition_rate_pct"], 30.53, places=2)
        self.assertAlmostEqual(self.summary["non_overtime_attrition_rate_pct"], 10.44, places=2)
        self.assertGreater(self.summary["overtime_odds_ratio"], 3.5)
        self.assertGreater(self.summary["retained_avg_exi"], self.summary["separated_avg_exi"])

    def test_05_predictive_retention_and_segmentation_bounds(self) -> None:
        self.assertGreaterEqual(self.summary["holdout_roc_auc_logistic"], 0.84)
        self.assertLessEqual(self.summary["holdout_brier_score"], 0.09)
        self.assertGreaterEqual(self.summary["holdout_top20_lift"], 3.4)
        self.assertGreaterEqual(self.summary["holdout_top20_capture_pct"], 70.0)

        seg_csv = OUTPUT_DIR / "workforce_retention_segments.csv"
        self.assertTrue(seg_csv.exists())
        with seg_csv.open(encoding="utf-8") as f:
            segs = list(csv.DictReader(f))
        self.assertEqual(len(segs), 4)
        self.assertEqual(sum(int(s["employees"]) for s in segs), 1470)


if __name__ == "__main__":
    unittest.main()
