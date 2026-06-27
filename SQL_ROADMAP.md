# SQL Roadmap — Intermediate → Advanced

Background: 1 YOE, solid MySQL/DBMS fundamentals, intermediate level. Goal: move to advanced/production-grade SQL skills.
Pace: ~1-1.5 hrs/day, 10-12 weeks total.

## Phase 1 (Weeks 1-2): Advanced Query Mastery
- [ ] Window functions: `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`/`LEAD`, `NTILE`
- [ ] Running totals and moving averages with window functions
- [ ] CTEs — replacing nested subqueries
- [ ] Recursive CTEs — hierarchical data (org charts, category trees)
- [ ] Advanced `GROUP BY`: `ROLLUP`, complex `HAVING` clauses
- [ ] Pivoting / unpivoting with `CASE`
- [ ] Set operations: `UNION`/`UNION ALL`/`INTERSECT`/`EXCEPT` — performance implications

## Phase 2 (Weeks 3-4): Query Performance & Execution
- [ ] Read `EXPLAIN` / `EXPLAIN ANALYZE` output confidently
- [ ] Identify full scans vs index usage in a plan
- [ ] Composite indexes — column order matters
- [ ] Covering indexes and index selectivity
- [ ] Cases where MySQL ignores an existing index
- [ ] Query rewrite patterns: avoid `SELECT *`, sargable predicates, avoid function-wrapped columns in `WHERE`
- [ ] Understand cost-based optimizer decisions and when to use index hints

## Phase 3 (Weeks 5-6): Transactions & Concurrency
- [ ] ACID properties in depth
- [ ] Isolation levels: Read Committed, Repeatable Read, Serializable — anomalies each prevents
- [ ] Row-level vs table-level locking, shared vs exclusive locks
- [ ] Deadlocks — detection and resolution
- [ ] MVCC — how InnoDB implements it
- [ ] `SELECT ... FOR UPDATE`, optimistic vs pessimistic locking

## Phase 4 (Weeks 7-8): Schema Design & Storage Internals
- [ ] BCNF and beyond 3NF
- [ ] Denormalization tradeoffs for read-heavy systems
- [ ] InnoDB internals: B+ tree structure
- [ ] Clustered vs secondary indexes, how primary key choice affects storage
- [ ] Partitioning strategies: range, hash, list
- [ ] Data type selection for storage/performance (VARCHAR sizing, ENUM, JSON columns)

## Phase 5 (Weeks 9-10): Scaling & Architecture
- [ ] Replication: master-replica setup, replication lag
- [ ] Read/write splitting
- [ ] Sharding concepts and strategies
- [ ] Connection pooling and app-layer interaction
- [ ] Caching layers (MySQL query cache deprecation, Redis/app-level caching)
- [ ] Zero-downtime schema changes, online DDL

## Phase 6 (Weeks 11-12): Real-World Application
- [ ] Write 5-10 production-style queries (multi-table reports, dashboard queries, dedup logic)
- [ ] Optimize queries against a 1M+ row dataset (Sakila/Employees sample DB), measure before/after with `EXPLAIN ANALYZE`
- [ ] Use slow query log and `performance_schema` to profile slow queries
- [ ] Learn 3-5 key MySQL vs PostgreSQL differences (window function nuances, `RETURNING`, JSONB vs JSON)

## Ongoing / Parallel
- [ ] Solve 3-5 SQL problems/week (LeetCode Database, StrataScratch) — focus on window functions, self-joins, gaps-and-islands
- [ ] Read `EXPLAIN` output for real queries at work, even unprompted

## Milestone Checkpoints
- [ ] After Phase 2: can explain why a query is slow from `EXPLAIN` output alone
- [ ] After Phase 4: can justify an index/schema decision using B+ tree access pattern reasoning
- [ ] After Phase 6: can optimize an unfamiliar slow query in under 15 minutes
