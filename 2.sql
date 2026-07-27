SELECT product_code, month_start, SUM(monthly_earned_premium) AS earned_premium
FROM policy_month_profitability
GROUP BY product_code, month_start
ORDER BY product_code, month_start;

SELECT risk_category, SUM(monthly_paid_claims + monthly_reserve) AS incurred_claims
FROM policy_month_profitability
GROUP BY risk_category;

SELECT underwriter_id,
    SUM(earned_premium) AS earned_premium,
    SUM(incurred_claims) AS incurred_claims,
    SUM(total_expense) AS total_expense,
    ROUND(SUM(incurred_claims) / NULLIF(SUM(earned_premium),0), 4) AS loss_ratio,
    ROUND(SUM(total_expense) / NULLIF(SUM(earned_premium),0), 4) AS expense_ratio,
    ROUND(SUM(incurred_claims) / NULLIF(SUM(earned_premium),0)
        + SUM(total_expense) / NULLIF(SUM(earned_premium),0), 4) AS combined_ratio
FROM vw_underwriting_profitability
GROUP BY underwriter_id;

SELECT branch_code,
    SUM(earned_premium) AS earned_premium,
    SUM(incurred_claims) AS incurred_claims,
    SUM(total_expense) AS total_expense,
    SUM(underwriting_profit) AS underwriting_profit,
    ROUND(SUM(underwriting_profit) / NULLIF(SUM(earned_premium),0), 4) AS underwriting_margin
FROM vw_underwriting_profitability
GROUP BY branch_code;

SELECT v.policy_id, v.underwriter_id, v.underwriting_profit,
    ROUND(v.underwriting_profit / NULLIF(v.earned_premium,0), 4) AS underwriting_margin
FROM vw_underwriting_profitability v
JOIN underwriting u ON v.policy_id = u.policy_id
WHERE u.manual_override_flag = 'Y'
  AND v.underwriting_profit < 0;
  
-- High discount: >15% | High loss ratio: >100% (loss_ratio > 1)
SELECT v.policy_id, u.discount_percentage, v.loss_ratio
FROM vw_underwriting_profitability v
JOIN underwriting u ON v.policy_id = u.policy_id
WHERE u.discount_percentage > 15
  AND v.loss_ratio > 1;
  
WITH yearly AS (
    SELECT line_of_business, YEAR(month_start) AS yr,
        SUM(monthly_earned_premium) AS earned_premium,
        ROUND((SUM(monthly_paid_claims + monthly_reserve) + SUM(monthly_expense))
              / NULLIF(SUM(monthly_earned_premium),0), 4) AS combined_ratio
    FROM policy_month_profitability
    GROUP BY line_of_business, YEAR(month_start)
)
SELECT line_of_business, yr, combined_ratio,
    LAG(combined_ratio) OVER (PARTITION BY line_of_business ORDER BY yr) AS prev_yr_combined_ratio,
    CASE WHEN combined_ratio > LAG(combined_ratio) OVER (PARTITION BY line_of_business ORDER BY yr)
         THEN 'Deteriorating' ELSE 'Stable/Improving' END AS trend_flag
FROM yearly
ORDER BY line_of_business, yr;

