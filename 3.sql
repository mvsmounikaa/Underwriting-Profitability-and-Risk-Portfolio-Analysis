-- Generate a month-spine (Jan 2023 - Dec 2024) once, reused across queries
CREATE TABLE calendar_month AS
SELECT DATE_ADD('2023-01-01', INTERVAL (a.n) MONTH) AS month_start
FROM (
    SELECT a.N + b.N * 10 AS n
    FROM (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
          UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a
    CROSS JOIN (SELECT 0 N UNION SELECT 1 UNION SELECT 2) b
) a
WHERE DATE_ADD('2023-01-01', INTERVAL (a.n) MONTH) <= '2024-12-01';

CREATE TABLE policy_month_profitability AS
SELECT
    p.policy_id,
    p.product_code,
    p.line_of_business,
    p.branch_code,
    u.underwriter_id,
    u.risk_category,
    cm.month_start,

    -- Earned Premium: annual GWP / 12, allocated only to months within the policy term.
    -- Cancelled policies stop earning from the cancellation-implied end date (policy_end_date used as proxy).
    ROUND(p.gross_written_premium / 12, 2) AS monthly_earned_premium,

    -- Incurred claims attributed to this policy-month (claim_date falls within this month)
    COALESCE(c.paid_amount, 0) AS monthly_paid_claims,
    COALESCE(c.reserve_amount, 0) AS monthly_reserve,

    -- Expenses attributed to this policy-month (expense_date falls within this month)
    COALESCE(e.expense_amount, 0) AS monthly_expense

FROM policy p
JOIN underwriting u ON p.policy_id = u.policy_id
JOIN calendar_month cm
    ON cm.month_start BETWEEN DATE_FORMAT(p.policy_start_date, '%Y-%m-01')
                           AND DATE_FORMAT(p.policy_end_date, '%Y-%m-01')
LEFT JOIN (
    SELECT policy_id, DATE_FORMAT(claim_date, '%Y-%m-01') AS month_start,
           SUM(paid_amount) AS paid_amount, SUM(reserve_amount) AS reserve_amount
    FROM claims GROUP BY policy_id, DATE_FORMAT(claim_date, '%Y-%m-01')
) c ON c.policy_id = p.policy_id AND c.month_start = cm.month_start
LEFT JOIN (
    SELECT policy_id, DATE_FORMAT(expense_date, '%Y-%m-01') AS month_start,
           SUM(expense_amount) AS expense_amount
    FROM expense GROUP BY policy_id, DATE_FORMAT(expense_date, '%Y-%m-01')
) e ON e.policy_id = p.policy_id AND e.month_start = cm.month_start;

CREATE VIEW vw_underwriting_profitability AS
SELECT
    policy_id, product_code, line_of_business, branch_code,
    underwriter_id, risk_category,
    SUM(monthly_earned_premium) AS earned_premium,
    SUM(monthly_paid_claims + monthly_reserve) AS incurred_claims,
    SUM(monthly_expense) AS total_expense,
    ROUND(SUM(monthly_paid_claims + monthly_reserve) / NULLIF(SUM(monthly_earned_premium),0), 4) AS loss_ratio,
    ROUND(SUM(monthly_expense) / NULLIF(SUM(monthly_earned_premium),0), 4) AS expense_ratio,
    ROUND((SUM(monthly_earned_premium) - SUM(monthly_paid_claims + monthly_reserve) - SUM(monthly_expense)), 2) AS underwriting_profit
FROM policy_month_profitability
GROUP BY policy_id, product_code, line_of_business, branch_code, underwriter_id, risk_category;