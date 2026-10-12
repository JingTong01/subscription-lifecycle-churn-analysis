# Subscription Lifecycle and Churn Analysis

End-to-end analysis of a paid music-streaming subscription service (KKBox, ~23M transactions, 2015–2017): SQL modelling of subscription lifecycles, survival analysis of when and why subscribers churn, and engagement signals that predict churn before it happens.

> **Status: in progress.** Data pipeline and subscription spells are complete; survival and engagement analysis are next. See [Progress](#progress).

## Business questions

1. **When** do subscribers churn? Which months of a subscription are the riskiest?
2. **Who** churns? How do auto-renewal, plan type, trials and discounts relate to churn?
3. Does **engagement drop before churn**, and how many weeks before expiry is it visible?
4. Which **lifecycle states** do subscribers move through, and where do they leak?
5. What should the business **do**, and how would we test it?

## Data

[KKBox Churn Prediction Challenge (WSDM 2018)](https://www.kaggle.com/competitions/kkbox-churn-prediction-challenge): real data from a Taiwanese music-streaming subscription service. Raw data is not included in this repo; see [How to reproduce](#how-to-reproduce).

| Table | Content | Size |
| --- | --- | --- |
| Transactions | Payments, renewals and cancellations, Jan 2015 – Mar 2017 | 22,978,755 rows, 2,426,143 users |
| Members | Demographics and registration channel | 6,769,473 users |
| User logs | Daily listening activity | ~400M rows (full) |
| Labels | Churn outcome for memberships expiring in March 2017 | 970,960 users, 9.0% churn |

## Progress

| Step | Description | Status |
| --- | --- | --- |
| 1 | Load raw data into DuckDB, convert to Parquet | ✅ Done |
| 2 | Profile the data | ✅ Done |
| 3 | Clean the data, with a documented cleaning log | ✅ Done |
| 4 | Build subscription spells | ✅ Done |
| 5 | Monthly KPIs and cohort retention | ⏳ Next |
| 6 | Survival analysis  | ⬜ Planned |
| 7 | Engagement and lifecycle analysis | ⬜ Planned |
| 8 | Churn prediction model  | ⬜ Planned |
| 9 | Dashboard | ⬜ Planned |
| 10 | Business recommendations | ⬜ Planned |

## Findings so far

**The business is driven by monthly renewals.** 87.8% of transactions are 30-day plans and 84.8% are auto-renewals, so every subscriber faces a renewal decision roughly every month.

**Demographics are weak; behaviour is what matters.** Age is invalid for 67% of members and gender missing for 65%. The analysis therefore focuses on subscription behaviour (plan, auto-renewal, trials, engagement) and keeps "Unknown" as its own category instead of dropping users.

**Cleaning removed under 0.05% of transactions.** 3,339 duplicates and 6,462 payments with impossible dates were dropped; trials, free periods, discounts and 0-day plans were kept and flagged. A profiling check disproved the initial hypothesis that 0-day plans are cancellations (98% are not). Full log: [`reports/cleaning_log.csv`](reports/cleaning_log.csv).

**Subscription spells.** Transactions were turned into 3,030,066 continuous subscription periods for 2.4M users (a spell ends when no renewal follows within 30 days of expiry). Median spell length is 128 days; 20% of spells are reactivations; 40% are still active at the data end and treated as censored in the survival analysis.

**Open issue.** A consistency check against KKBox's labels shows a mismatch for users who renewed early (25% labelled as churners where ~0% was expected). The cause is being investigated before the labels are used for modelling.


## Approach

```
Raw CSV ──► Parquet + DuckDB ──► Cleaning ──► Subscription spells ──► Cohorts & survival analysis
                                                    │
                          Daily logs ──► Engagement metrics ──► Lifecycle states & early-warning signals
                                                                                   │
                                                              Dashboard + business recommendations
```

**Tools:** SQL (DuckDB), Python (pandas, lifelines, scikit-learn), Jupyter.

## Repository structure

```
├── sql/          01_load.sql, 02_clean.sql, 03_spells.sql
├── notebooks/    01_eda, 02_clean, 03_spells
├── reports/      cleaning_log.csv, figures (coming)
├── dashboard/    (coming)
└── requirements.txt
```
