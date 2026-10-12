


-- Convert raw CSVs to Parquet (compressed, much faster to query)
COPY (SELECT * FROM read_csv_auto('data/raw/members_v3.csv'))
  TO 'data/parquet/members.parquet' (FORMAT parquet);

COPY (SELECT * FROM read_csv_auto('data/raw/transactions.csv'))
  TO 'data/parquet/transactions.parquet' (FORMAT parquet);

COPY (SELECT * FROM read_csv_auto('data/raw/transactions_v2.csv'))
  TO 'data/parquet/transactions_v2.parquet' (FORMAT parquet);

COPY (SELECT * FROM read_csv_auto('data/raw/train_v2.csv'))
  TO 'data/parquet/labels.parquet' (FORMAT parquet);

COPY (SELECT * FROM read_csv_auto('data/raw/user_logs_v2.csv'))
  TO 'data/parquet/user_logs_v2.parquet' (FORMAT parquet);

-- Views: short names that read the Parquet files directly
CREATE OR REPLACE VIEW raw_members AS SELECT * FROM 'data/parquet/members.parquet';
CREATE OR REPLACE VIEW raw_tx      AS SELECT * FROM 'data/parquet/transactions*.parquet';
CREATE OR REPLACE VIEW labels      AS SELECT * FROM 'data/parquet/labels.parquet';
CREATE OR REPLACE VIEW raw_logs    AS SELECT * FROM 'data/parquet/user_logs*.parquet';