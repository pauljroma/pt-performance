//
//  AnalyticsEdgeFunctionModelsTests.swift
//  PTPerformanceTests
//
//  Unit tests for AnalyticsEdgeFunctionModels Codable responses.
//  Validates JSON decoding of snake_case edge function payloads into
//  camelCase Swift models using PTSupabaseClient.flexibleDecoder.
//

import XCTest
@testable import PTPerformance

@MainActor
final class AnalyticsEdgeFunctionModelsTests: XCTestCase {

    // MARK: - Shared Decoder

    private var decoder: JSONDecoder { PTSupabaseClient.flexibleDecoder }

    // MARK: - RevenueAnalyticsResponse

    func testRevenueAnalyticsResponse_fullDecode() throws {
        let json = """
        {
            "success": true,
            "generated_at": "2026-02-20T12:00:00Z",
            "period_days": 30,
            "sections_included": ["metrics", "cohorts"],
            "metrics": {
                "mrr": 4500.0,
                "arr": 54000.0,
                "mrr_breakdown": {
                    "app_store": 3000.0,
                    "pack_subscriptions": 1500.0
                },
                "active_subscribers": {
                    "total": 120,
                    "app_store": 80,
                    "pack_subscriptions": 30,
                    "trials": 10
                },
                "churn_rate": 4.2,
                "churn_details": {
                    "rate_percent": 4.2,
                    "churned_in_period": 5,
                    "active_at_period_start": 119
                },
                "expansion_revenue": 200.0,
                "revenue_by_tier": [
                    {
                        "tier": "pro",
                        "tier_name": "Pro",
                        "active_subscribers": 50,
                        "price_monthly": 29.99,
                        "monthly_revenue": 1499.50
                    }
                ],
                "subscribers_by_tier": [
                    {
                        "tier": "pro",
                        "tier_name": "Pro",
                        "active": 50,
                        "trial": 5,
                        "cancelled": 3
                    }
                ]
            },
            "cohort_analysis": [
                {
                    "cohort": "2026-01",
                    "total_users": 40,
                    "retained_users": 35,
                    "retention_rate_percent": 87.5,
                    "total_subscriptions": 30,
                    "active_subscriptions": 28,
                    "churned_subscriptions": 2,
                    "current_mrr_contribution": 840.0,
                    "avg_months_retained": 3.5,
                    "avg_revenue_per_user": 21.0
                }
            ],
            "ltv_estimates": [
                {
                    "tier": "pro",
                    "tier_name": "Pro",
                    "monthly_price": 29.99,
                    "total_subscriptions": 100,
                    "active_subscriptions": 80,
                    "churned_subscriptions": 20,
                    "avg_lifespan_months": 8.5,
                    "median_lifespan_months": 7.0,
                    "monthly_churn_rate_percent": 5.0,
                    "estimated_ltv": 254.92,
                    "estimated_ltv_churn_method": 599.80,
                    "conversion_rate_percent": 45.0
                }
            ],
            "forecasting": {
                "current_mrr": 4500.0,
                "current_arr": 54000.0,
                "monthly_churn_rate": 0.042,
                "avg_revenue_per_account": 37.50,
                "active_subscriber_count": 120,
                "trial_count": 10,
                "expansion_revenue_monthly": 200.0,
                "net_revenue_retention": 1.05,
                "projected_arr_12m": 68000.0,
                "projected_mrr_next_month": 4600.0,
                "runway_months_at_current_churn": 24.0
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RevenueAnalyticsResponse.self, from: json)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.generatedAt, "2026-02-20T12:00:00Z")
        XCTAssertEqual(response.periodDays, 30)
        XCTAssertEqual(response.sectionsIncluded, ["metrics", "cohorts"])

        // Metrics
        let metrics = try XCTUnwrap(response.metrics)
        XCTAssertEqual(metrics.mrr, 4500.0)
        XCTAssertEqual(metrics.arr, 54000.0)
        XCTAssertEqual(metrics.churnRate, 4.2)
        XCTAssertEqual(metrics.expansionRevenue, 200.0)
        XCTAssertEqual(metrics.mrrBreakdown?.appStore, 3000.0)
        XCTAssertEqual(metrics.mrrBreakdown?.packSubscriptions, 1500.0)
        XCTAssertEqual(metrics.activeSubscribers?.total, 120)
        XCTAssertEqual(metrics.activeSubscribers?.trials, 10)
        XCTAssertEqual(metrics.churnDetails?.ratePercent, 4.2)
        XCTAssertEqual(metrics.churnDetails?.churnedInPeriod, 5)
        XCTAssertEqual(metrics.revenueByTier?.count, 1)
        XCTAssertEqual(metrics.revenueByTier?.first?.tier, "pro")
        XCTAssertEqual(metrics.subscribersByTier?.first?.active, 50)

        // Cohort analysis
        XCTAssertEqual(response.cohortAnalysis?.count, 1)
        let cohort = try XCTUnwrap(response.cohortAnalysis?.first)
        XCTAssertEqual(cohort.cohort, "2026-01")
        XCTAssertEqual(cohort.totalUsers, 40)
        XCTAssertEqual(cohort.retentionRatePercent, 87.5)
        XCTAssertEqual(cohort.currentMrrContribution, 840.0)

        // LTV estimates
        XCTAssertEqual(response.ltvEstimates?.count, 1)
        let ltv = try XCTUnwrap(response.ltvEstimates?.first)
        XCTAssertEqual(ltv.tier, "pro")
        XCTAssertEqual(ltv.estimatedLtv, 254.92)
        XCTAssertEqual(ltv.conversionRatePercent, 45.0)

        // Forecasting
        let forecast = try XCTUnwrap(response.forecasting)
        XCTAssertEqual(forecast.currentMrr, 4500.0)
        XCTAssertEqual(forecast.projectedArr12m, 68000.0)
        XCTAssertEqual(forecast.runwayMonthsAtCurrentChurn, 24.0)
    }

    func testRevenueAnalyticsResponse_missingOptionalFields() throws {
        let json = """
        {
            "success": true
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RevenueAnalyticsResponse.self, from: json)

        XCTAssertEqual(response.success, true)
        XCTAssertNil(response.generatedAt)
        XCTAssertNil(response.periodDays)
        XCTAssertNil(response.sectionsIncluded)
        XCTAssertNil(response.metrics)
        XCTAssertNil(response.cohortAnalysis)
        XCTAssertNil(response.ltvEstimates)
        XCTAssertNil(response.forecasting)
    }

    func testRevenueAnalyticsResponse_emptyArrays() throws {
        let json = """
        {
            "success": true,
            "sections_included": [],
            "cohort_analysis": [],
            "ltv_estimates": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RevenueAnalyticsResponse.self, from: json)

        XCTAssertEqual(response.sectionsIncluded, [])
        XCTAssertEqual(response.cohortAnalysis?.count, 0)
        XCTAssertEqual(response.ltvEstimates?.count, 0)
    }

    func testRevenueAnalyticsResponse_snakeCaseKeyMapping() throws {
        let json = """
        {
            "generated_at": "2026-01-01",
            "period_days": 7,
            "sections_included": ["metrics"]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RevenueAnalyticsResponse.self, from: json)

        XCTAssertEqual(response.generatedAt, "2026-01-01")
        XCTAssertEqual(response.periodDays, 7)
        XCTAssertEqual(response.sectionsIncluded, ["metrics"])
    }

    func testRevenueMetrics_emptyTierArrays() throws {
        let json = """
        {
            "mrr": 100.0,
            "revenue_by_tier": [],
            "subscribers_by_tier": []
        }
        """.data(using: .utf8)!

        let metrics = try decoder.decode(RevenueMetrics.self, from: json)

        XCTAssertEqual(metrics.mrr, 100.0)
        XCTAssertEqual(metrics.revenueByTier?.count, 0)
        XCTAssertEqual(metrics.subscribersByTier?.count, 0)
    }

    // MARK: - RetentionAnalyticsResponse

    func testRetentionAnalyticsResponse_fullDecode() throws {
        let json = """
        {
            "analysis_id": "ret-001",
            "generated_at": "2026-02-20T08:00:00Z",
            "months_analyzed": 6,
            "cohorts": [
                {
                    "cohort_month": "2026-01",
                    "cohort_size": 50,
                    "d1_retention_pct": 80.0,
                    "d1_retained": 40,
                    "d7_retention_pct": 60.0,
                    "d7_retained": 30,
                    "d30_retention_pct": 45.0,
                    "d30_retained": 22,
                    "d90_retention_pct": 30.0,
                    "d90_retained": 15
                }
            ],
            "drivers": [
                {
                    "feature": "workout_logging",
                    "total_users": 200,
                    "users_with_feature": 120,
                    "users_without_feature": 80,
                    "retained_with_feature": 100,
                    "retained_without_feature": 30,
                    "retention_rate_with_pct": 83.3,
                    "retention_rate_without_pct": 37.5,
                    "lift_pct": 45.8
                }
            ],
            "resurrected_users": [
                {
                    "patient_id": "aaaaaaaa-bbbb-cccc-dddd-000000000001",
                    "resurrected_at": "2026-02-15T10:00:00Z",
                    "last_active_at": "2026-01-01T08:00:00Z",
                    "inactive_days": 45,
                    "return_session_type": "workout",
                    "signup_date": "2025-06-01",
                    "days_since_signup": 260
                }
            ],
            "churn_prediction_inputs": {
                "total_users_analyzed": 500,
                "overall_d30_retention_pct": 52.0,
                "highest_impact_feature": "workout_logging",
                "highest_impact_lift_pct": 45.8,
                "avg_inactive_days_before_resurrection": 38.5,
                "resurrection_count": 12,
                "cohort_trend": "improving"
            },
            "summary": {
                "total_cohort_users": 300,
                "latest_cohort_d1_pct": 80.0,
                "latest_cohort_d7_pct": 60.0,
                "best_retention_month": "2026-01",
                "top_retention_driver": "workout_logging",
                "total_resurrections": 12
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RetentionAnalyticsResponse.self, from: json)

        XCTAssertEqual(response.analysisId, "ret-001")
        XCTAssertEqual(response.monthsAnalyzed, 6)

        // Cohorts
        let cohort = try XCTUnwrap(response.cohorts?.first)
        XCTAssertEqual(cohort.cohortMonth, "2026-01")
        XCTAssertEqual(cohort.cohortSize, 50)
        XCTAssertEqual(cohort.d1RetentionPct, 80.0)
        XCTAssertEqual(cohort.d1Retained, 40)
        XCTAssertEqual(cohort.d7RetentionPct, 60.0)
        XCTAssertEqual(cohort.d30RetentionPct, 45.0)
        XCTAssertEqual(cohort.d90Retained, 15)

        // Drivers
        let driver = try XCTUnwrap(response.drivers?.first)
        XCTAssertEqual(driver.feature, "workout_logging")
        XCTAssertEqual(driver.totalUsers, 200)
        XCTAssertEqual(driver.retentionRateWithPct, 83.3)
        XCTAssertEqual(driver.liftPct, 45.8)

        // Resurrected users
        let resurrected = try XCTUnwrap(response.resurrectedUsers?.first)
        XCTAssertEqual(resurrected.patientId, "aaaaaaaa-bbbb-cccc-dddd-000000000001")
        XCTAssertEqual(resurrected.inactiveDays, 45)
        XCTAssertEqual(resurrected.returnSessionType, "workout")
        XCTAssertEqual(resurrected.daysSinceSignup, 260)

        // Churn prediction inputs
        let churn = try XCTUnwrap(response.churnPredictionInputs)
        XCTAssertEqual(churn.totalUsersAnalyzed, 500)
        XCTAssertEqual(churn.overallD30RetentionPct, 52.0)
        XCTAssertEqual(churn.highestImpactFeature, "workout_logging")
        XCTAssertEqual(churn.cohortTrend, "improving")

        // Summary
        let summary = try XCTUnwrap(response.summary)
        XCTAssertEqual(summary.totalCohortUsers, 300)
        XCTAssertEqual(summary.latestCohortD1Pct, 80.0)
        XCTAssertEqual(summary.bestRetentionMonth, "2026-01")
        XCTAssertEqual(summary.totalResurrections, 12)
    }

    func testRetentionAnalyticsResponse_missingOptionalFields() throws {
        let json = """
        {
            "analysis_id": "ret-002"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RetentionAnalyticsResponse.self, from: json)

        XCTAssertEqual(response.analysisId, "ret-002")
        XCTAssertNil(response.generatedAt)
        XCTAssertNil(response.monthsAnalyzed)
        XCTAssertNil(response.cohorts)
        XCTAssertNil(response.drivers)
        XCTAssertNil(response.resurrectedUsers)
        XCTAssertNil(response.churnPredictionInputs)
        XCTAssertNil(response.summary)
    }

    func testRetentionAnalyticsResponse_emptyArrays() throws {
        let json = """
        {
            "cohorts": [],
            "drivers": [],
            "resurrected_users": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RetentionAnalyticsResponse.self, from: json)

        XCTAssertEqual(response.cohorts?.count, 0)
        XCTAssertEqual(response.drivers?.count, 0)
        XCTAssertEqual(response.resurrectedUsers?.count, 0)
    }

    func testRetentionCohortRow_identifiable() throws {
        let json = """
        {
            "cohort_month": "2026-01",
            "cohort_size": 10
        }
        """.data(using: .utf8)!

        let row = try decoder.decode(RetentionCohortRow.self, from: json)

        XCTAssertEqual(row.id, "2026-01")
        XCTAssertEqual(row.cohortMonth, "2026-01")
    }

    func testRetentionDriver_identifiable() throws {
        let json = """
        {
            "feature": "streaks",
            "lift_pct": 12.5
        }
        """.data(using: .utf8)!

        let driver = try decoder.decode(RetentionDriver.self, from: json)

        XCTAssertEqual(driver.id, "streaks")
        XCTAssertEqual(driver.liftPct, 12.5)
    }

    func testResurrectedUser_identifiable() throws {
        let json = """
        {
            "patient_id": "abc-123",
            "inactive_days": 30
        }
        """.data(using: .utf8)!

        let user = try decoder.decode(ResurrectedUser.self, from: json)

        XCTAssertEqual(user.id, "abc-123")
        XCTAssertEqual(user.inactiveDays, 30)
    }

    // MARK: - EngagementScoresResponse

    func testEngagementScoresResponse_fullDecode() throws {
        let json = """
        {
            "success": true,
            "summary": {
                "total_patients": 100,
                "highly_engaged": 25,
                "engaged": 30,
                "moderate": 20,
                "at_risk": 15,
                "high_risk": 10,
                "avg_score": 62.5
            },
            "data": [
                {
                    "patient_id": "aaaaaaaa-bbbb-cccc-dddd-000000000002",
                    "score": 78.5,
                    "risk_level": "engaged",
                    "components": {
                        "workout_frequency": {
                            "raw_value": 0.85,
                            "weight": 0.35,
                            "weighted_value": 0.30,
                            "sessions_completed": 4,
                            "expected_sessions": 5
                        },
                        "streak_consistency": {
                            "raw_value": 0.90,
                            "weight": 0.25,
                            "weighted_value": 0.23,
                            "current_streak": 12
                        },
                        "feature_breadth": {
                            "raw_value": 0.60,
                            "weight": 0.20,
                            "weighted_value": 0.12,
                            "features_used": 3,
                            "features_total": 5
                        },
                        "recency": {
                            "raw_value": 0.95,
                            "weight": 0.20,
                            "weighted_value": 0.19,
                            "days_since_last_activity": 1
                        }
                    },
                    "calculated_at": "2026-02-20T09:00:00Z"
                }
            ],
            "execution_time_ms": 245
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(EngagementScoresResponse.self, from: json)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.executionTimeMs, 245)

        // Summary
        let summary = try XCTUnwrap(response.summary)
        XCTAssertEqual(summary.totalPatients, 100)
        XCTAssertEqual(summary.highlyEngaged, 25)
        XCTAssertEqual(summary.engaged, 30)
        XCTAssertEqual(summary.moderate, 20)
        XCTAssertEqual(summary.atRisk, 15)
        XCTAssertEqual(summary.highRisk, 10)
        XCTAssertEqual(summary.avgScore, 62.5)

        // Data rows
        let row = try XCTUnwrap(response.data?.first)
        XCTAssertEqual(row.patientId, "aaaaaaaa-bbbb-cccc-dddd-000000000002")
        XCTAssertEqual(row.score, 78.5)
        XCTAssertEqual(row.riskLevel, "engaged")
        XCTAssertEqual(row.calculatedAt, "2026-02-20T09:00:00Z")

        // Components
        let components = try XCTUnwrap(row.components)
        XCTAssertEqual(components.workoutFrequency?.rawValue, 0.85)
        XCTAssertEqual(components.workoutFrequency?.weight, 0.35)
        XCTAssertEqual(components.workoutFrequency?.sessionsCompleted, 4)
        XCTAssertEqual(components.workoutFrequency?.expectedSessions, 5)
        XCTAssertEqual(components.streakConsistency?.currentStreak, 12)
        XCTAssertEqual(components.featureBreadth?.featuresUsed, 3)
        XCTAssertEqual(components.featureBreadth?.featuresTotal, 5)
        XCTAssertEqual(components.recency?.daysSinceLastActivity, 1)
    }

    func testEngagementScoresResponse_missingOptionalFields() throws {
        let json = """
        {
            "success": true
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(EngagementScoresResponse.self, from: json)

        XCTAssertEqual(response.success, true)
        XCTAssertNil(response.summary)
        XCTAssertNil(response.data)
        XCTAssertNil(response.executionTimeMs)
    }

    func testEngagementScoresResponse_emptyDataArray() throws {
        let json = """
        {
            "success": true,
            "data": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(EngagementScoresResponse.self, from: json)

        XCTAssertEqual(response.data?.count, 0)
    }

    func testEngagementScoreRow_identifiable() throws {
        let json = """
        {
            "patient_id": "patient-xyz",
            "score": 55.0
        }
        """.data(using: .utf8)!

        let row = try decoder.decode(EngagementScoreRow.self, from: json)

        XCTAssertEqual(row.id, "patient-xyz")
    }

    func testEngagementComponents_partialComponents() throws {
        let json = """
        {
            "workout_frequency": {
                "raw_value": 0.5,
                "weight": 0.35,
                "weighted_value": 0.175
            }
        }
        """.data(using: .utf8)!

        let components = try decoder.decode(EngagementComponents.self, from: json)

        XCTAssertNotNil(components.workoutFrequency)
        XCTAssertNil(components.streakConsistency)
        XCTAssertNil(components.featureBreadth)
        XCTAssertNil(components.recency)
    }

    func testEngagementComponent_snakeCaseMapping() throws {
        let json = """
        {
            "raw_value": 0.75,
            "weight": 0.20,
            "weighted_value": 0.15,
            "sessions_completed": 3,
            "expected_sessions": 4,
            "current_streak": 7,
            "features_used": 2,
            "features_total": 5,
            "days_since_last_activity": 2
        }
        """.data(using: .utf8)!

        let component = try decoder.decode(EngagementComponent.self, from: json)

        XCTAssertEqual(component.rawValue, 0.75)
        XCTAssertEqual(component.weight, 0.20)
        XCTAssertEqual(component.weightedValue, 0.15)
        XCTAssertEqual(component.sessionsCompleted, 3)
        XCTAssertEqual(component.expectedSessions, 4)
        XCTAssertEqual(component.currentStreak, 7)
        XCTAssertEqual(component.featuresUsed, 2)
        XCTAssertEqual(component.featuresTotal, 5)
        XCTAssertEqual(component.daysSinceLastActivity, 2)
    }

    // MARK: - TrainingOutcomesResponse

    func testTrainingOutcomesResponse_fullDecode() throws {
        let json = """
        {
            "success": true,
            "type": "individual",
            "summary": {
                "total_exercises_tracked": 8,
                "exercises_with_gains": 6,
                "avg_strength_gain_pct": 12.5,
                "best_strength_gain": {
                    "exercise_name": "Back Squat",
                    "start_load": 100.0,
                    "current_load": 125.0,
                    "pct_change": 25.0,
                    "data_points": 12
                },
                "volume_trend": "increasing",
                "pain_trend": "decreasing",
                "overall_adherence_pct": 88.0,
                "weeks_of_data": 8
            },
            "data": {
                "volume_progression": [
                    {
                        "week_start": "2026-02-10",
                        "total_volume": 15000.0,
                        "log_count": 4
                    }
                ],
                "strength_gains": [
                    {
                        "exercise_name": "Back Squat",
                        "start_load": 100.0,
                        "current_load": 125.0,
                        "pct_change": 25.0,
                        "data_points": 12
                    }
                ],
                "pain_trend": [
                    {
                        "week_start": "2026-02-10",
                        "avg_pain": 2.5,
                        "sample_count": 3
                    }
                ],
                "adherence": [
                    {
                        "week_start": "2026-02-10",
                        "sessions_completed": 4,
                        "sessions_scheduled": 5,
                        "adherence_pct": 80.0
                    }
                ]
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainingOutcomesResponse.self, from: json)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.type, "individual")

        // Summary
        let summary = try XCTUnwrap(response.summary)
        XCTAssertEqual(summary.totalExercisesTracked, 8)
        XCTAssertEqual(summary.exercisesWithGains, 6)
        XCTAssertEqual(summary.avgStrengthGainPct, 12.5)
        XCTAssertEqual(summary.volumeTrend, "increasing")
        XCTAssertEqual(summary.painTrend, "decreasing")
        XCTAssertEqual(summary.overallAdherencePct, 88.0)
        XCTAssertEqual(summary.weeksOfData, 8)

        // Best strength gain (nested)
        let bestGain = try XCTUnwrap(summary.bestStrengthGain)
        XCTAssertEqual(bestGain.exerciseName, "Back Squat")
        XCTAssertEqual(bestGain.startLoad, 100.0)
        XCTAssertEqual(bestGain.currentLoad, 125.0)
        XCTAssertEqual(bestGain.pctChange, 25.0)
        XCTAssertEqual(bestGain.dataPoints, 12)

        // Data arrays
        let data = try XCTUnwrap(response.data)

        let volume = try XCTUnwrap(data.volumeProgression?.first)
        XCTAssertEqual(volume.weekStart, "2026-02-10")
        XCTAssertEqual(volume.totalVolume, 15000.0)
        XCTAssertEqual(volume.logCount, 4)

        let gain = try XCTUnwrap(data.strengthGains?.first)
        XCTAssertEqual(gain.exerciseName, "Back Squat")
        XCTAssertEqual(gain.pctChange, 25.0)

        let pain = try XCTUnwrap(data.painTrend?.first)
        XCTAssertEqual(pain.avgPain, 2.5)
        XCTAssertEqual(pain.sampleCount, 3)

        let adherence = try XCTUnwrap(data.adherence?.first)
        XCTAssertEqual(adherence.sessionsCompleted, 4)
        XCTAssertEqual(adherence.sessionsScheduled, 5)
        XCTAssertEqual(adherence.adherencePct, 80.0)
    }

    func testTrainingOutcomesResponse_missingOptionalFields() throws {
        let json = """
        {
            "success": true
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainingOutcomesResponse.self, from: json)

        XCTAssertEqual(response.success, true)
        XCTAssertNil(response.type)
        XCTAssertNil(response.summary)
        XCTAssertNil(response.data)
    }

    func testTrainingOutcomeData_emptyArrays() throws {
        let json = """
        {
            "volume_progression": [],
            "strength_gains": [],
            "pain_trend": [],
            "adherence": []
        }
        """.data(using: .utf8)!

        let data = try decoder.decode(TrainingOutcomeData.self, from: json)

        XCTAssertEqual(data.volumeProgression?.count, 0)
        XCTAssertEqual(data.strengthGains?.count, 0)
        XCTAssertEqual(data.painTrend?.count, 0)
        XCTAssertEqual(data.adherence?.count, 0)
    }

    func testStrengthGain_identifiable() throws {
        let json = """
        {
            "exercise_name": "Bench Press",
            "start_load": 60.0,
            "current_load": 75.0,
            "pct_change": 25.0,
            "data_points": 8
        }
        """.data(using: .utf8)!

        let gain = try decoder.decode(StrengthGain.self, from: json)

        XCTAssertEqual(gain.id, "Bench Press")
        XCTAssertEqual(gain.startLoad, 60.0)
        XCTAssertEqual(gain.currentLoad, 75.0)
    }

    func testWeeklyVolume_identifiable() throws {
        let json = """
        {
            "week_start": "2026-02-03",
            "total_volume": 12000.0,
            "log_count": 3
        }
        """.data(using: .utf8)!

        let volume = try decoder.decode(WeeklyVolume.self, from: json)

        XCTAssertEqual(volume.id, "2026-02-03")
    }

    func testWeeklyPain_identifiable() throws {
        let json = """
        {
            "week_start": "2026-02-03",
            "avg_pain": 3.0,
            "sample_count": 5
        }
        """.data(using: .utf8)!

        let pain = try decoder.decode(WeeklyPain.self, from: json)

        XCTAssertEqual(pain.id, "2026-02-03")
        XCTAssertEqual(pain.avgPain, 3.0)
    }

    func testEFWeeklyAdherence_identifiable() throws {
        let json = """
        {
            "week_start": "2026-02-03",
            "sessions_completed": 3,
            "sessions_scheduled": 4,
            "adherence_pct": 75.0
        }
        """.data(using: .utf8)!

        let adherence = try decoder.decode(EFWeeklyAdherence.self, from: json)

        XCTAssertEqual(adherence.id, "2026-02-03")
        XCTAssertEqual(adherence.adherencePct, 75.0)
    }

    // MARK: - ExecutiveDashboardResponse

    func testExecutiveDashboardResponse_fullDecode() throws {
        let json = """
        {
            "generated_at": "2026-02-20T14:00:00Z",
            "overview": {
                "total_users": 500,
                "dau": 120,
                "wau": 300,
                "mau": 450,
                "dau_mau_ratio": 0.267
            },
            "revenue": {
                "subscriber_count": 200,
                "trial_count": 25,
                "mrr_estimate": 5980.0,
                "total_active": 225,
                "churn_count": 8
            },
            "engagement": {
                "avg_sessions_per_user_per_week": 3.2,
                "total_sessions_this_week": 960,
                "active_users_with_sessions": 280,
                "avg_streak_length": 5.4
            },
            "satisfaction": {
                "avg_rating": 4.3,
                "feedback_count": 150,
                "feedback_last_30d": 22,
                "avg_rating_last_30d": 4.5,
                "rating_distribution": {
                    "1_star": 3,
                    "2_star": 5,
                    "3_star": 15,
                    "4_star": 55,
                    "5_star": 72
                }
            },
            "safety": {
                "open_incidents": {
                    "critical": 0,
                    "high": 1,
                    "medium": 3,
                    "low": 5
                },
                "total_open": 9,
                "resolved_this_week": 4,
                "total_this_month": 15
            },
            "trends": {
                "dau": {
                    "current": 120,
                    "previous": 110,
                    "change_pct": 9.1
                },
                "sessions": {
                    "current": 960,
                    "previous": 880,
                    "change_pct": 9.1
                },
                "new_signups": {
                    "current": 35,
                    "previous": 28,
                    "change_pct": 25.0
                }
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ExecutiveDashboardResponse.self, from: json)

        XCTAssertEqual(response.generatedAt, "2026-02-20T14:00:00Z")

        // Overview
        let overview = try XCTUnwrap(response.overview)
        XCTAssertEqual(overview.totalUsers, 500)
        XCTAssertEqual(overview.dau, 120)
        XCTAssertEqual(overview.wau, 300)
        XCTAssertEqual(overview.mau, 450)
        XCTAssertEqual(overview.dauMauRatio, 0.267)

        // Revenue
        let revenue = try XCTUnwrap(response.revenue)
        XCTAssertEqual(revenue.subscriberCount, 200)
        XCTAssertEqual(revenue.trialCount, 25)
        XCTAssertEqual(revenue.mrrEstimate, 5980.0)
        XCTAssertEqual(revenue.totalActive, 225)
        XCTAssertEqual(revenue.churnCount, 8)

        // Engagement
        let engagement = try XCTUnwrap(response.engagement)
        XCTAssertEqual(engagement.avgSessionsPerUserPerWeek, 3.2)
        XCTAssertEqual(engagement.totalSessionsThisWeek, 960)
        XCTAssertEqual(engagement.activeUsersWithSessions, 280)
        XCTAssertEqual(engagement.avgStreakLength, 5.4)

        // Satisfaction
        let satisfaction = try XCTUnwrap(response.satisfaction)
        XCTAssertEqual(satisfaction.avgRating, 4.3)
        XCTAssertEqual(satisfaction.feedbackCount, 150)
        XCTAssertEqual(satisfaction.feedbackLast30d, 22)
        XCTAssertEqual(satisfaction.avgRatingLast30d, 4.5)

        // Rating distribution
        let dist = try XCTUnwrap(satisfaction.ratingDistribution)
        XCTAssertEqual(dist.oneStar, 3)
        XCTAssertEqual(dist.twoStar, 5)
        XCTAssertEqual(dist.threeStar, 15)
        XCTAssertEqual(dist.fourStar, 55)
        XCTAssertEqual(dist.fiveStar, 72)

        // Safety
        let safety = try XCTUnwrap(response.safety)
        XCTAssertEqual(safety.totalOpen, 9)
        XCTAssertEqual(safety.resolvedThisWeek, 4)
        XCTAssertEqual(safety.totalThisMonth, 15)
        XCTAssertEqual(safety.openIncidents?.critical, 0)
        XCTAssertEqual(safety.openIncidents?.high, 1)

        // Trends
        let trends = try XCTUnwrap(response.trends)
        XCTAssertEqual(trends.dau?.current, 120)
        XCTAssertEqual(trends.dau?.previous, 110)
        XCTAssertEqual(trends.dau?.changePct, 9.1)
        XCTAssertEqual(trends.sessions?.current, 960)
        XCTAssertEqual(trends.newSignups?.current, 35)
        XCTAssertEqual(trends.newSignups?.changePct, 25.0)
    }

    func testExecutiveDashboardResponse_missingOptionalFields() throws {
        let json = """
        {
            "generated_at": "2026-02-20T14:00:00Z"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ExecutiveDashboardResponse.self, from: json)

        XCTAssertEqual(response.generatedAt, "2026-02-20T14:00:00Z")
        XCTAssertNil(response.overview)
        XCTAssertNil(response.revenue)
        XCTAssertNil(response.engagement)
        XCTAssertNil(response.satisfaction)
        XCTAssertNil(response.safety)
        XCTAssertNil(response.trends)
    }

    func testExecutiveDashboardResponse_snakeCaseKeyMapping() throws {
        let json = """
        {
            "generated_at": "2026-02-20",
            "overview": {
                "total_users": 10,
                "dau_mau_ratio": 0.5
            },
            "revenue": {
                "subscriber_count": 5,
                "trial_count": 2,
                "mrr_estimate": 100.0,
                "total_active": 7,
                "churn_count": 0
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ExecutiveDashboardResponse.self, from: json)

        XCTAssertEqual(response.generatedAt, "2026-02-20")
        XCTAssertEqual(response.overview?.totalUsers, 10)
        XCTAssertEqual(response.overview?.dauMauRatio, 0.5)
        XCTAssertEqual(response.revenue?.subscriberCount, 5)
        XCTAssertEqual(response.revenue?.mrrEstimate, 100.0)
    }

    func testRatingDistribution_numericPrefixKeys() throws {
        let json = """
        {
            "1_star": 10,
            "2_star": 20,
            "3_star": 30,
            "4_star": 40,
            "5_star": 50
        }
        """.data(using: .utf8)!

        let dist = try decoder.decode(RatingDistribution.self, from: json)

        XCTAssertEqual(dist.oneStar, 10)
        XCTAssertEqual(dist.twoStar, 20)
        XCTAssertEqual(dist.threeStar, 30)
        XCTAssertEqual(dist.fourStar, 40)
        XCTAssertEqual(dist.fiveStar, 50)
    }

    func testEFTrendMetric_decode() throws {
        let json = """
        {
            "current": 150,
            "previous": 100,
            "change_pct": 50.0
        }
        """.data(using: .utf8)!

        let metric = try decoder.decode(EFTrendMetric.self, from: json)

        XCTAssertEqual(metric.current, 150)
        XCTAssertEqual(metric.previous, 100)
        XCTAssertEqual(metric.changePct, 50.0)
    }

    func testExecSafety_incidentCounts() throws {
        let json = """
        {
            "open_incidents": {
                "critical": 2,
                "high": 3,
                "medium": 5,
                "low": 10
            },
            "total_open": 20,
            "resolved_this_week": 7,
            "total_this_month": 30
        }
        """.data(using: .utf8)!

        let safety = try decoder.decode(ExecSafety.self, from: json)

        XCTAssertEqual(safety.openIncidents?.critical, 2)
        XCTAssertEqual(safety.openIncidents?.high, 3)
        XCTAssertEqual(safety.openIncidents?.medium, 5)
        XCTAssertEqual(safety.openIncidents?.low, 10)
        XCTAssertEqual(safety.totalOpen, 20)
        XCTAssertEqual(safety.resolvedThisWeek, 7)
        XCTAssertEqual(safety.totalThisMonth, 30)
    }

    // MARK: - ProductHealthResponse

    func testProductHealthResponse_fullDecode() throws {
        let json = """
        {
            "period_start": "2026-01-21",
            "period_end": "2026-02-20",
            "period_days": 30,
            "engagement": {
                "dau": 110,
                "wau": 280,
                "mau": 420,
                "total_patients": 500,
                "dau_trend": 5.2,
                "wau_trend": 3.1,
                "mau_trend": 1.8,
                "dau_wau_ratio": 0.393,
                "wau_mau_ratio": 0.667
            },
            "feature_adoption": {
                "workout_logging": {
                    "users": 350,
                    "adoption_pct": 70.0
                },
                "streaks": {
                    "users": 200,
                    "adoption_pct": 40.0
                }
            },
            "satisfaction": {
                "avg_rating": 4.4,
                "total_reviews": 180,
                "rating_distribution": {
                    "1_star": 2,
                    "2_star": 4,
                    "3_star": 12,
                    "4_star": 60,
                    "5_star": 102
                },
                "nps_proxy": 72.0,
                "recent_low_ratings": [
                    {
                        "rating": 2,
                        "feedback": "App crashed during workout",
                        "timestamp": "2026-02-18T15:30:00Z",
                        "app_version": "2.1.0"
                    }
                ]
            },
            "safety": {
                "open_incidents": {
                    "critical": 0,
                    "high": 2,
                    "medium": 4,
                    "low": 6
                },
                "total_open": 12,
                "incidents_in_period": 8,
                "resolved_in_period": 5,
                "avg_resolution_hours": 18.5
            },
            "subscription_health": {
                "new_trials": 30,
                "active_subscriptions": 200,
                "conversions": 15,
                "cancellations": 8,
                "expired": 3,
                "trial_conversion_rate": 50.0,
                "churn_rate": 4.0
            },
            "generated_at": "2026-02-20T16:00:00Z"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ProductHealthResponse.self, from: json)

        XCTAssertEqual(response.periodStart, "2026-01-21")
        XCTAssertEqual(response.periodEnd, "2026-02-20")
        XCTAssertEqual(response.periodDays, 30)
        XCTAssertEqual(response.generatedAt, "2026-02-20T16:00:00Z")

        // Engagement
        let engagement = try XCTUnwrap(response.engagement)
        XCTAssertEqual(engagement.dau, 110)
        XCTAssertEqual(engagement.wau, 280)
        XCTAssertEqual(engagement.mau, 420)
        XCTAssertEqual(engagement.totalPatients, 500)
        XCTAssertEqual(engagement.dauTrend, 5.2)
        XCTAssertEqual(engagement.wauTrend, 3.1)
        XCTAssertEqual(engagement.mauTrend, 1.8)
        XCTAssertEqual(engagement.dauWauRatio, 0.393)
        XCTAssertEqual(engagement.wauMauRatio, 0.667)

        // Feature adoption (dictionary)
        let adoption = try XCTUnwrap(response.featureAdoption)
        XCTAssertEqual(adoption.count, 2)
        XCTAssertEqual(adoption["workout_logging"]?.users, 350)
        XCTAssertEqual(adoption["workout_logging"]?.adoptionPct, 70.0)
        XCTAssertEqual(adoption["streaks"]?.users, 200)
        XCTAssertEqual(adoption["streaks"]?.adoptionPct, 40.0)

        // Satisfaction
        let satisfaction = try XCTUnwrap(response.satisfaction)
        XCTAssertEqual(satisfaction.avgRating, 4.4)
        XCTAssertEqual(satisfaction.totalReviews, 180)
        XCTAssertEqual(satisfaction.npsProxy, 72.0)
        XCTAssertEqual(satisfaction.ratingDistribution?.fiveStar, 102)

        // Low ratings
        let lowRating = try XCTUnwrap(satisfaction.recentLowRatings?.first)
        XCTAssertEqual(lowRating.rating, 2)
        XCTAssertEqual(lowRating.feedback, "App crashed during workout")
        XCTAssertEqual(lowRating.appVersion, "2.1.0")

        // Safety
        let safety = try XCTUnwrap(response.safety)
        XCTAssertEqual(safety.totalOpen, 12)
        XCTAssertEqual(safety.incidentsInPeriod, 8)
        XCTAssertEqual(safety.resolvedInPeriod, 5)
        XCTAssertEqual(safety.avgResolutionHours, 18.5)
        XCTAssertEqual(safety.openIncidents?.critical, 0)

        // Subscription health
        let subs = try XCTUnwrap(response.subscriptionHealth)
        XCTAssertEqual(subs.newTrials, 30)
        XCTAssertEqual(subs.activeSubscriptions, 200)
        XCTAssertEqual(subs.conversions, 15)
        XCTAssertEqual(subs.cancellations, 8)
        XCTAssertEqual(subs.expired, 3)
        XCTAssertEqual(subs.trialConversionRate, 50.0)
        XCTAssertEqual(subs.churnRate, 4.0)
    }

    func testProductHealthResponse_missingOptionalFields() throws {
        let json = """
        {
            "period_days": 7
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ProductHealthResponse.self, from: json)

        XCTAssertEqual(response.periodDays, 7)
        XCTAssertNil(response.periodStart)
        XCTAssertNil(response.periodEnd)
        XCTAssertNil(response.engagement)
        XCTAssertNil(response.featureAdoption)
        XCTAssertNil(response.satisfaction)
        XCTAssertNil(response.safety)
        XCTAssertNil(response.subscriptionHealth)
        XCTAssertNil(response.generatedAt)
    }

    func testProductHealthResponse_emptyFeatureAdoption() throws {
        let json = """
        {
            "feature_adoption": {}
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ProductHealthResponse.self, from: json)

        XCTAssertEqual(response.featureAdoption?.count, 0)
    }

    func testProductHealthResponse_emptyLowRatings() throws {
        let json = """
        {
            "satisfaction": {
                "avg_rating": 4.8,
                "total_reviews": 50,
                "recent_low_ratings": []
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ProductHealthResponse.self, from: json)

        let satisfaction = try XCTUnwrap(response.satisfaction)
        XCTAssertEqual(satisfaction.recentLowRatings?.count, 0)
        XCTAssertEqual(satisfaction.avgRating, 4.8)
    }

    func testProductHealthResponse_snakeCaseKeyMapping() throws {
        let json = """
        {
            "period_start": "2026-01-01",
            "period_end": "2026-01-31",
            "period_days": 30,
            "generated_at": "2026-02-01T00:00:00Z",
            "subscription_health": {
                "new_trials": 10,
                "active_subscriptions": 50,
                "trial_conversion_rate": 60.0,
                "churn_rate": 2.0
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(ProductHealthResponse.self, from: json)

        XCTAssertEqual(response.periodStart, "2026-01-01")
        XCTAssertEqual(response.periodEnd, "2026-01-31")
        XCTAssertEqual(response.periodDays, 30)
        XCTAssertEqual(response.generatedAt, "2026-02-01T00:00:00Z")
        XCTAssertEqual(response.subscriptionHealth?.newTrials, 10)
        XCTAssertEqual(response.subscriptionHealth?.activeSubscriptions, 50)
        XCTAssertEqual(response.subscriptionHealth?.trialConversionRate, 60.0)
        XCTAssertEqual(response.subscriptionHealth?.churnRate, 2.0)
    }

    func testLowRatingEntry_identifiable() throws {
        let json = """
        {
            "rating": 1,
            "feedback": "Terrible experience",
            "timestamp": "2026-02-19T10:00:00Z",
            "app_version": "2.0.5"
        }
        """.data(using: .utf8)!

        let entry = try decoder.decode(LowRatingEntry.self, from: json)

        XCTAssertEqual(entry.id, "2026-02-19T10:00:00Z")
        XCTAssertEqual(entry.rating, 1)
        XCTAssertEqual(entry.feedback, "Terrible experience")
        XCTAssertEqual(entry.appVersion, "2.0.5")
    }

    func testFeatureAdoptionMetric_decode() throws {
        let json = """
        {
            "users": 250,
            "adoption_pct": 55.5
        }
        """.data(using: .utf8)!

        let metric = try decoder.decode(FeatureAdoptionMetric.self, from: json)

        XCTAssertEqual(metric.users, 250)
        XCTAssertEqual(metric.adoptionPct, 55.5)
    }

    func testProductSubscriptionHealth_decode() throws {
        let json = """
        {
            "new_trials": 20,
            "active_subscriptions": 100,
            "conversions": 10,
            "cancellations": 5,
            "expired": 2,
            "trial_conversion_rate": 50.0,
            "churn_rate": 5.0
        }
        """.data(using: .utf8)!

        let health = try decoder.decode(ProductSubscriptionHealth.self, from: json)

        XCTAssertEqual(health.newTrials, 20)
        XCTAssertEqual(health.activeSubscriptions, 100)
        XCTAssertEqual(health.conversions, 10)
        XCTAssertEqual(health.cancellations, 5)
        XCTAssertEqual(health.expired, 2)
        XCTAssertEqual(health.trialConversionRate, 50.0)
        XCTAssertEqual(health.churnRate, 5.0)
    }

    // MARK: - EFAnyCodable

    func testEFAnyCodable_decodesInt() throws {
        let json = """
        42
        """.data(using: .utf8)!

        let value = try decoder.decode(EFAnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Int, 42)
    }

    func testEFAnyCodable_decodesString() throws {
        let json = """
        "hello"
        """.data(using: .utf8)!

        let value = try decoder.decode(EFAnyCodable.self, from: json)

        XCTAssertEqual(value.value as? String, "hello")
    }

    func testEFAnyCodable_decodesDouble() throws {
        let json = """
        3.14
        """.data(using: .utf8)!

        let value = try decoder.decode(EFAnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Double, 3.14)
    }

    func testEFAnyCodable_decodesBool() throws {
        let json = """
        true
        """.data(using: .utf8)!

        let value = try decoder.decode(EFAnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Bool, true)
    }

    // MARK: - Minimal / Empty JSON Object

    func testAllResponseTypes_decodeFromEmptyObject() throws {
        let emptyJson = "{}".data(using: .utf8)!

        let revenue = try decoder.decode(RevenueAnalyticsResponse.self, from: emptyJson)
        XCTAssertNil(revenue.success)
        XCTAssertNil(revenue.metrics)

        let retention = try decoder.decode(RetentionAnalyticsResponse.self, from: emptyJson)
        XCTAssertNil(retention.analysisId)
        XCTAssertNil(retention.cohorts)

        let engagement = try decoder.decode(EngagementScoresResponse.self, from: emptyJson)
        XCTAssertNil(engagement.success)
        XCTAssertNil(engagement.data)

        let training = try decoder.decode(TrainingOutcomesResponse.self, from: emptyJson)
        XCTAssertNil(training.success)
        XCTAssertNil(training.data)

        let executive = try decoder.decode(ExecutiveDashboardResponse.self, from: emptyJson)
        XCTAssertNil(executive.generatedAt)
        XCTAssertNil(executive.overview)

        let productHealth = try decoder.decode(ProductHealthResponse.self, from: emptyJson)
        XCTAssertNil(productHealth.periodDays)
        XCTAssertNil(productHealth.engagement)
    }
}
