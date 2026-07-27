CREATE DATABASE underwriting_profitability;
USE underwriting_profitability;

CREATE TABLE underwriter (
    underwriter_id     VARCHAR(10) PRIMARY KEY,
    underwriter_name   VARCHAR(50),
    team                VARCHAR(30),
    experience_band     VARCHAR(20),
    region               VARCHAR(20)
);

CREATE TABLE policy (
    policy_id               VARCHAR(10) PRIMARY KEY,
    policy_number            VARCHAR(20),
    customer_id               VARCHAR(10),
    product_code               VARCHAR(20),
    line_of_business            VARCHAR(20),
    policy_start_date            DATE,
    policy_end_date                DATE,
    policy_status                    VARCHAR(20),
    gross_written_premium              DECIMAL(12,2),
    net_written_premium                  DECIMAL(12,2),
    sum_insured                            DECIMAL(14,2),
    branch_code                              VARCHAR(10)
);

CREATE TABLE underwriting (
    uw_id                       VARCHAR(10) PRIMARY KEY,
    policy_id                     VARCHAR(10),
    underwriter_id                  VARCHAR(10),
    risk_score                        INT,
    risk_category                       VARCHAR(10),
    uw_decision                           VARCHAR(20),
    uw_date                                 DATE,
    premium_loading_percentage               DECIMAL(5,2),
    discount_percentage                        DECIMAL(5,2),
    manual_override_flag                         CHAR(1),
    FOREIGN KEY (policy_id) REFERENCES policy(policy_id),
    FOREIGN KEY (underwriter_id) REFERENCES underwriter(underwriter_id)
);

CREATE TABLE claims (
    claim_id           VARCHAR(10) PRIMARY KEY,
    policy_id             VARCHAR(10),
    claim_date              DATE,
    claim_status               VARCHAR(20),
    paid_amount                   DECIMAL(12,2),
    reserve_amount                  DECIMAL(12,2),
    claim_type                        VARCHAR(40),
    FOREIGN KEY (policy_id) REFERENCES policy(policy_id)
);

CREATE TABLE expense (
    expense_id       VARCHAR(10) PRIMARY KEY,
    policy_id            VARCHAR(10),
    expense_type            VARCHAR(30),
    expense_amount             DECIMAL(12,2),
    expense_date                  DATE,
    FOREIGN KEY (policy_id) REFERENCES policy(policy_id)
);

SELECT COUNT(*) FROM policy;        -- expect 220
SELECT COUNT(*) FROM underwriting;  -- expect 220
SELECT COUNT(*) FROM claims;        -- expect 87
SELECT COUNT(*) FROM expense;       -- expect 552
SELECT COUNT(*) FROM underwriter;   -- expect 12