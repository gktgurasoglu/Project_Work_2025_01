WITH payment_aggregates AS (
    SELECT
        user_id,
        game_name,
        DATE_TRUNC('month', payment_date)::DATE AS payment_month,
        COALESCE(SUM(revenue_amount_usd), 0) AS total_payment
    FROM project.games_payments
    GROUP BY user_id, game_name, DATE_TRUNC('month', payment_date)
),
payment_bounds AS (
    SELECT
        user_id,
        game_name,
        MIN(DATE_TRUNC('month', payment_date)) AS first_month
    FROM project.games_payments
    GROUP BY user_id, game_name
),
max_month AS (
    SELECT MAX(DATE_TRUNC('month', payment_date)) AS last_month
    FROM project.games_payments
),
all_months AS (
    SELECT
        u.user_id,
        u.game_name,
        u.language,
        u.has_older_device_model,
        u.age,
        gs.payment_month
    FROM project.games_paid_users AS u
    JOIN payment_bounds pb
        ON u.user_id = pb.user_id AND u.game_name = pb.game_name
    CROSS JOIN max_month
    JOIN LATERAL (
        SELECT generate_series(
            pb.first_month,
            max_month.last_month,
            INTERVAL '1 month'
        )::DATE AS payment_month
    ) gs ON TRUE
),
payment_status AS (
    SELECT
        am.user_id,
        am.game_name,
        am.language,
        am.has_older_device_model,
        am.age,
        am.payment_month,
        COALESCE(pa.total_payment, 0) AS total_payment,       
        COALESCE(LAG(pa.total_payment, 1) OVER (
            PARTITION BY am.user_id, am.game_name
            ORDER BY am.payment_month
        ), 0) AS total_payment_previous,
        COALESCE(SUM(pa.total_payment) OVER (
            PARTITION BY am.user_id, am.game_name
            ORDER BY am.payment_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ), 0) AS previous_total_payments
    FROM all_months AS am
    LEFT JOIN payment_aggregates AS pa
        ON am.user_id = pa.user_id
        AND am.game_name = pa.game_name
        AND am.payment_month = pa.payment_month
),
final_status AS (
    SELECT
        user_id,
        game_name,
        language,
        has_older_device_model,
        age,
        payment_month,
        total_payment,
        total_payment_previous,
        CASE
            WHEN total_payment > 0 THEN
                CASE
                    WHEN total_payment_previous = 0 THEN
                        CASE
                            WHEN previous_total_payments = 0 THEN 'new'
                            ELSE 'back'
                        END
                    ELSE 'active'
                END
            ELSE
                CASE
                    WHEN total_payment_previous > 0 THEN 'churn'
                    ELSE 'deactive'
                END
        END AS status
    FROM payment_status
)
SELECT
    user_id,
    game_name,
    language,
    has_older_device_model,
    age,
    payment_month,
    status,
    total_payment,
    total_payment_previous
FROM final_status
ORDER BY payment_month, user_id, game_name;
