# Query Analysis: Picklist and Shipment Roles

This file compares SQL join strategies for retrieving shipment and picklist role information, analyzing performance with and without filters.

## Integrated Insights and Performance Analysis

### 1. Executive Summary: Filtered vs. Base Performance
The performance of this data document varies significantly depending on the presence of filters:
- **Filtered Queries (Cost ~74):** The MySQL optimizer is highly efficient when filters are present. It intelligently reorders joins to start with the most selective index (`PICKLIST_ROLE`), regardless of the `FROM` clause order.
- **Base Queries (Cost ~2.5k to 8.7M):** Without filters, the join direction becomes critical. Starting with the large `SHIPMENT` table leads to a **10-million-row join explosion**, while starting with the junction table `PICKLIST_SHIPMENT` keeps the query performant.

### 2. The Power of Selective Filtering
In the filtered queries, the optimizer ignores the logical `LEFT JOIN` sequence and effectively treats them as `INNER JOIN` operations due to null-rejecting conditions in the `WHERE` clause. This allows it to:
- Pick **`PICKLIST_ROLE`** as the driving table (smallest row count after filtering).
- Maintain an identical execution cost of **74.32** regardless of whether the query starts with `SHIPMENT` or `PICKLIST_SHIPMENT`.

### 3. Join Order Risk in Unfiltered Queries
When filters are removed (Base Queries), the choice of the driving table becomes the only lever for performance:
- **Starting with `SHIPMENT` (High Risk):** Leads to a full table scan and an exponential fan-out of rows. The cost (~8.7M) indicates that this approach will not scale as the database grows.
- **Starting with `PICKLIST_SHIPMENT` (Best Practice):** The junction table acts as a natural anchor, limiting the initial row set to mapping records and resulting in a significantly lower cost (~2.5k).

### 4. Critical Bottleneck: `SHIPMENT_STATUS`
Across all query variations, the join with `SHIPMENT_STATUS` remains the primary performance hotspot:
- **Observation:** It frequently defaults to an `ALL` (full scan) or `ref` access type with high row counts.
- **Impact:** In filtered queries, this single step accounts for **~91% of the total execution cost**.
- **Recommendation:** Implementing a composite index on `SHIPMENT_STATUS(SHIPMENT_ID, STATUS_ID)` is the most critical optimization to ensure long-term scalability.

### 5. Semantic Equivalence and Reordering
- **Null-Rejecting Filters:** Filters like `MBR3.ROLE_TYPE_ID = 'WAREHOUSE_PICKER'` ensure that any `NULL` results from a `LEFT JOIN` are discarded. This allows the optimizer to reorder the join chain freely to find the lowest-cost path.
- **Junction Table Efficiency:** The `PICKLIST_SHIPMENT` table is accessed efficiently using its primary key index. In the execution plans, this often appears as a covering index scan (`using_index: true`), which is extremely fast.

---

## Filtered Query 1: Starting with SHIPMENT

### SQL Query
```sql
EXPLAIN FORMAT=JSON
SELECT 
    PRIM.SHIPMENT_ID,
    PRIM.SHIPMENT_TYPE_ID,
    PRIM.STATUS_ID,
    MBR0.STATUS_ID,
    PRIM.ORIGIN_FACILITY_ID,
    PRIM.SHIPMENT_METHOD_TYPE_ID,
    MBR3.ROLE_TYPE_ID,
    MBR3.FROM_DATE,
    MBR3.THRU_DATE,
    MBR4.FIRST_NAME,
    MBR4.LAST_NAME,
    MBR3.PARTY_ID,
    MBR5.GROUP_NAME,
    MBR2.PICKLIST_DATE,
    PRIM.PRIMARY_ORDER_ID,
    MBR6.PRODUCT_STORE_ID
FROM SHIPMENT PRIM
LEFT OUTER JOIN SHIPMENT_STATUS MBR0
    ON PRIM.SHIPMENT_ID = MBR0.SHIPMENT_ID
LEFT OUTER JOIN PICKLIST_SHIPMENT MBR1
    ON PRIM.SHIPMENT_ID = MBR1.SHIPMENT_ID
LEFT OUTER JOIN PICKLIST MBR2
    ON MBR1.PICKLIST_ID = MBR2.PICKLIST_ID
LEFT OUTER JOIN PICKLIST_ROLE MBR3
    ON MBR2.PICKLIST_ID = MBR3.PICKLIST_ID
LEFT OUTER JOIN PERSON MBR4
    ON MBR3.PARTY_ID = MBR4.PARTY_ID
LEFT OUTER JOIN PARTY_GROUP MBR5
    ON MBR3.PARTY_ID = MBR5.PARTY_ID
LEFT OUTER JOIN ORDER_HEADER MBR6
    ON PRIM.PRIMARY_ORDER_ID = MBR6.ORDER_ID
WHERE (
    PRIM.SHIPMENT_TYPE_ID = 'SALES_SHIPMENT'
    AND MBR0.STATUS_ID = 'SHIPMENT_APPROVED'
    AND PRIM.ORIGIN_FACILITY_ID = 'ATLANTA'
    AND MBR3.ROLE_TYPE_ID = 'WAREHOUSE_PICKER'
    AND (
        PRIM.SHIPMENT_METHOD_TYPE_ID <> 'STOREPICKUP'
        OR PRIM.SHIPMENT_METHOD_TYPE_ID IS NULL
    )
    AND MBR3.PARTY_ID IS NOT NULL
    AND MBR3.PARTY_ID <> 'Y'
    AND MBR2.PICKLIST_DATE >= '2025-04-11'
);
```

### Execution Plan (JSON)
```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "74.32"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "MBR3",
          "access_type": "ALL",
          "possible_keys": [
            "PRIMARY",
            "PCKLST_RLE_PKLT"
          ],
          "rows_examined_per_scan": 31,
          "rows_produced_per_join": 2,
          "filtered": "8.10",
          "cost_info": {
            "read_cost": "3.10",
            "eval_cost": "0.25",
            "prefix_cost": "3.35",
            "data_read_per_join": "5K"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PARTY_ID",
            "ROLE_TYPE_ID",
            "FROM_DATE",
            "THRU_DATE"
          ],
          "attached_condition": "((`hotwax`.`mbr3`.`ROLE_TYPE_ID` = 'WAREHOUSE_PICKER') and (`hotwax`.`mbr3`.`PARTY_ID` is not null) and (`hotwax`.`mbr3`.`PARTY_ID` <> 'Y'))"
        }
      },
      {
        "table": {
          "table_name": "MBR2",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR3.PICKLIST_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "33.33",
          "cost_info": {
            "read_cost": "0.63",
            "eval_cost": "0.08",
            "prefix_cost": "4.23",
            "data_read_per_join": "2K"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PICKLIST_DATE"
          ],
          "attached_condition": "(`hotwax`.`mbr2`.`PICKLIST_DATE` >= TIMESTAMP'2025-04-11 00:00:00')"
        }
      },
      {
        "table": {
          "table_name": "MBR4",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PERSON_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR3.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "0.42",
            "eval_cost": "0.08",
            "prefix_cost": "4.73",
            "data_read_per_join": "8K"
          },
          "used_columns": [
            "PARTY_ID",
            "FIRST_NAME",
            "LAST_NAME"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR5",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PARTY_GRP_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR3.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "0.21",
            "eval_cost": "0.08",
            "prefix_cost": "5.02",
            "data_read_per_join": "15K"
          },
          "used_columns": [
            "PARTY_ID",
            "GROUP_NAME"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR1",
          "access_type": "index",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ],
          "key_length": "244",
          "rows_examined_per_scan": 11,
          "rows_produced_per_join": 0,
          "filtered": "10.00",
          "using_index": true,
          "using_join_buffer": "hash join",
          "cost_info": {
            "read_cost": "0.25",
            "eval_cost": "0.09",
            "prefix_cost": "6.20",
            "data_read_per_join": "243"
          },
          "used_columns": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ],
          "attached_condition": "((`hotwax`.`mbr1`.`PICKLIST_ID` = `hotwax`.`mbr3`.`PICKLIST_ID`) and (`hotwax`.`mbr1`.`SHIPMENT_ID` is not null))"
        }
      },
      {
        "table": {
          "table_name": "PRIM",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "SHIPMENT_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR1.SHIPMENT_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "5.00",
          "cost_info": {
            "read_cost": "0.09",
            "eval_cost": "0.00",
            "prefix_cost": "6.38",
            "data_read_per_join": "311"
          },
          "used_columns": [
            "SHIPMENT_ID",
            "SHIPMENT_TYPE_ID",
            "STATUS_ID",
            "PRIMARY_ORDER_ID",
            "ORIGIN_FACILITY_ID",
            "SHIPMENT_METHOD_TYPE_ID"
          ],
          "attached_condition": "((`hotwax`.`prim`.`ORIGIN_FACILITY_ID` = 'ATLANTA') and (`hotwax`.`prim`.`SHIPMENT_TYPE_ID` = 'SALES_SHIPMENT') and ((`hotwax`.`prim`.`SHIPMENT_METHOD_TYPE_ID` <> 'STOREPICKUP') or (`hotwax`.`prim`.`SHIPMENT_METHOD_TYPE_ID` is null)) and (`hotwax`.`prim`.`SHIPMENT_ID` = `hotwax`.`mbr1`.`SHIPMENT_ID`))"
        }
      },
      {
        "table": {
          "table_name": "MBR6",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "ORDER_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.PRIM.PRIMARY_ORDER_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "0.00",
            "eval_cost": "0.00",
            "prefix_cost": "6.39",
            "data_read_per_join": "201"
          },
          "used_columns": [
            "ORDER_ID",
            "PRODUCT_STORE_ID"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR0",
          "access_type": "ALL",
          "rows_examined_per_scan": 734,
          "rows_produced_per_join": 0,
          "filtered": "1.00",
          "using_join_buffer": "hash join",
          "cost_info": {
            "read_cost": "67.59",
            "eval_cost": "0.03",
            "prefix_cost": "74.32",
            "data_read_per_join": "435"
          },
          "used_columns": [
            "STATUS_ID",
            "SHIPMENT_ID"
          ],
          "attached_condition": "((`hotwax`.`mbr0`.`SHIPMENT_ID` = `hotwax`.`prim`.`SHIPMENT_ID`) and (`hotwax`.`mbr0`.`STATUS_ID` = 'SHIPMENT_APPROVED'))"
        }
      }
    ]
  }
}
```

---

## Filtered Query 2: Starting with PICKLIST_SHIPMENT

### SQL Query
```sql
EXPLAIN FORMAT=JSON
SELECT 
    MBR0.SHIPMENT_ID,
    MBR0.SHIPMENT_TYPE_ID,
    MBR0.STATUS_ID,
    MBR1.STATUS_ID,
    MBR0.ORIGIN_FACILITY_ID,
    MBR0.SHIPMENT_METHOD_TYPE_ID,
    MBR0.PRIMARY_ORDER_ID,
    MBR2.PRODUCT_STORE_ID,
    MBR4.ROLE_TYPE_ID,
    MBR4.FROM_DATE,
    MBR4.THRU_DATE,
    MBR5.FIRST_NAME,
    MBR5.LAST_NAME,
    MBR4.PARTY_ID,
    MBR6.GROUP_NAME,
    MBR3.PICKLIST_DATE
FROM PICKLIST_SHIPMENT PRIM
LEFT OUTER JOIN SHIPMENT MBR0
    ON PRIM.SHIPMENT_ID = MBR0.SHIPMENT_ID
LEFT OUTER JOIN SHIPMENT_STATUS MBR1
    ON MBR0.SHIPMENT_ID = MBR1.SHIPMENT_ID
LEFT OUTER JOIN ORDER_HEADER MBR2
    ON MBR0.PRIMARY_ORDER_ID = MBR2.ORDER_ID
LEFT OUTER JOIN PICKLIST MBR3
    ON PRIM.PICKLIST_ID = MBR3.PICKLIST_ID
LEFT OUTER JOIN PICKLIST_ROLE MBR4
    ON MBR3.PICKLIST_ID = MBR4.PICKLIST_ID
LEFT OUTER JOIN PERSON MBR5
    ON MBR4.PARTY_ID = MBR5.PARTY_ID
LEFT OUTER JOIN PARTY_GROUP MBR6
    ON MBR4.PARTY_ID = MBR6.PARTY_ID
WHERE (
    MBR0.SHIPMENT_TYPE_ID = 'SALES_SHIPMENT'
    AND MBR1.STATUS_ID = 'SHIPMENT_APPROVED'
    AND MBR0.ORIGIN_FACILITY_ID = 'ATLANTA'
    AND MBR4.ROLE_TYPE_ID = 'WAREHOUSE_PICKER'
    AND (
        MBR0.SHIPMENT_METHOD_TYPE_ID <> 'STOREPICKUP'
        OR MBR0.SHIPMENT_METHOD_TYPE_ID IS NULL
    )
    AND MBR4.PARTY_ID IS NOT NULL
    AND MBR4.PARTY_ID <> 'Y'
    AND MBR3.PICKLIST_DATE >= '2025-04-11'
);
```

### Execution Plan (JSON)
```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "74.32"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "MBR4",
          "access_type": "ALL",
          "possible_keys": [
            "PRIMARY",
            "PCKLST_RLE_PKLT"
          ],
          "rows_examined_per_scan": 31,
          "rows_produced_per_join": 2,
          "filtered": "8.10",
          "cost_info": {
            "read_cost": "3.10",
            "eval_cost": "0.25",
            "prefix_cost": "3.35",
            "data_read_per_join": "5K"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PARTY_ID",
            "ROLE_TYPE_ID",
            "FROM_DATE",
            "THRU_DATE"
          ],
          "attached_condition": "((`hotwax`.`mbr4`.`ROLE_TYPE_ID` = 'WAREHOUSE_PICKER') and (`hotwax`.`mbr4`.`PARTY_ID` is not null) and (`hotwax`.`mbr4`.`PARTY_ID` <> 'Y'))"
        }
      },
      {
        "table": {
          "table_name": "MBR3",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR4.PICKLIST_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "33.33",
          "cost_info": {
            "read_cost": "0.63",
            "eval_cost": "0.08",
            "prefix_cost": "4.23",
            "data_read_per_join": "2K"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PICKLIST_DATE"
          ],
          "attached_condition": "(`hotwax`.`mbr3`.`PICKLIST_DATE` >= TIMESTAMP'2025-04-11 00:00:00')"
        }
      },
      {
        "table": {
          "table_name": "MBR5",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PERSON_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR4.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "0.42",
            "eval_cost": "0.08",
            "prefix_cost": "4.73",
            "data_read_per_join": "8K"
          },
          "used_columns": [
            "PARTY_ID",
            "FIRST_NAME",
            "LAST_NAME"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR6",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PARTY_GRP_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR4.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "0.21",
            "eval_cost": "0.08",
            "prefix_cost": "5.02",
            "data_read_per_join": "15K"
          },
          "used_columns": [
            "PARTY_ID",
            "GROUP_NAME"
          ]
        }
      },
      {
        "table": {
          "table_name": "PRIM",
          "access_type": "index",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ],
          "key_length": "244",
          "rows_examined_per_scan": 11,
          "rows_produced_per_join": 0,
          "filtered": "10.00",
          "using_index": true,
          "using_join_buffer": "hash join",
          "cost_info": {
            "read_cost": "0.25",
            "eval_cost": "0.09",
            "prefix_cost": "6.20",
            "data_read_per_join": "243"
          },
          "used_columns": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ],
          "attached_condition": "(`hotwax`.`prim`.`PICKLIST_ID` = `hotwax`.`mbr4`.`PICKLIST_ID`)"
        }
      },
      {
        "table": {
          "table_name": "MBR0",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "SHIPMENT_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.PRIM.SHIPMENT_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "5.00",
          "cost_info": {
            "read_cost": "0.09",
            "eval_cost": "0.00",
            "prefix_cost": "6.38",
            "data_read_per_join": "311"
          },
          "used_columns": [
            "SHIPMENT_ID",
            "SHIPMENT_TYPE_ID",
            "STATUS_ID",
            "PRIMARY_ORDER_ID",
            "ORIGIN_FACILITY_ID",
            "SHIPMENT_METHOD_TYPE_ID"
          ],
          "attached_condition": "((`hotwax`.`mbr0`.`ORIGIN_FACILITY_ID` = 'ATLANTA') and (`hotwax`.`mbr0`.`SHIPMENT_TYPE_ID` = 'SALES_SHIPMENT') and ((`hotwax`.`mbr0`.`SHIPMENT_METHOD_TYPE_ID` <> 'STOREPICKUP') or (`hotwax`.`mbr0`.`SHIPMENT_METHOD_TYPE_ID` is null)) and (`hotwax`.`prim`.`SHIPMENT_ID` = `hotwax`.`mbr0`.`SHIPMENT_ID`))"
        }
      },
      {
        "table": {
          "table_name": "MBR2",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "ORDER_ID"
          ],
          "key_length": "82",
          "ref": [
            "hotwax.MBR0.PRIMARY_ORDER_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 0,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "0.00",
            "eval_cost": "0.00",
            "prefix_cost": "6.39",
            "data_read_per_join": "201"
          },
          "used_columns": [
            "ORDER_ID",
            "PRODUCT_STORE_ID"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR1",
          "access_type": "ALL",
          "rows_examined_per_scan": 734,
          "rows_produced_per_join": 0,
          "filtered": "1.00",
          "using_join_buffer": "hash join",
          "cost_info": {
            "read_cost": "67.59",
            "eval_cost": "0.03",
            "prefix_cost": "74.32",
            "data_read_per_join": "435"
          },
          "used_columns": [
            "STATUS_ID",
            "SHIPMENT_ID"
          ],
          "attached_condition": "((`hotwax`.`mbr1`.`SHIPMENT_ID` = `hotwax`.`mbr0`.`SHIPMENT_ID`) and (`hotwax`.`mbr1`.`STATUS_ID` = 'SHIPMENT_APPROVED'))"
        }
      }
    ]
  }
}
```

---

## Base Queries (Without WHERE Conditions)

These queries remove all filters to analyze the default join behavior and baseline performance.

### Base Query 1: Starting with SHIPMENT
```sql
EXPLAIN FORMAT=JSON
SELECT 
    PRIM.SHIPMENT_ID,
    PRIM.SHIPMENT_TYPE_ID,
    PRIM.STATUS_ID,
    MBR0.STATUS_ID,
    PRIM.ORIGIN_FACILITY_ID,
    PRIM.SHIPMENT_METHOD_TYPE_ID,
    MBR3.ROLE_TYPE_ID,
    MBR3.FROM_DATE,
    MBR3.THRU_DATE,
    MBR4.FIRST_NAME,
    MBR4.LAST_NAME,
    MBR3.PARTY_ID,
    MBR5.GROUP_NAME,
    MBR2.PICKLIST_DATE,
    PRIM.PRIMARY_ORDER_ID,
    MBR6.PRODUCT_STORE_ID
FROM SHIPMENT PRIM
LEFT OUTER JOIN SHIPMENT_STATUS MBR0
    ON PRIM.SHIPMENT_ID = MBR0.SHIPMENT_ID
LEFT OUTER JOIN PICKLIST_SHIPMENT MBR1
    ON PRIM.SHIPMENT_ID = MBR1.SHIPMENT_ID
LEFT OUTER JOIN PICKLIST MBR2
    ON MBR1.PICKLIST_ID = MBR2.PICKLIST_ID
LEFT OUTER JOIN PICKLIST_ROLE MBR3
    ON MBR2.PICKLIST_ID = MBR3.PICKLIST_ID
LEFT OUTER JOIN PERSON MBR4
    ON MBR3.PARTY_ID = MBR4.PARTY_ID
LEFT OUTER JOIN PARTY_GROUP MBR5
    ON MBR3.PARTY_ID = MBR5.PARTY_ID
LEFT OUTER JOIN ORDER_HEADER MBR6
    ON PRIM.PRIMARY_ORDER_ID = MBR6.ORDER_ID;
```

#### Execution Plan (JSON)
```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "8712979.26"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "PRIM",
          "access_type": "ALL",
          "rows_examined_per_scan": 7268,
          "rows_produced_per_join": 7268,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "40.25",
            "eval_cost": "726.80",
            "prefix_cost": "767.05",
            "data_read_per_join": "35M"
          },
          "used_columns": [
            "SHIPMENT_ID",
            "SHIPMENT_TYPE_ID",
            "STATUS_ID",
            "PRIMARY_ORDER_ID",
            "ORIGIN_FACILITY_ID",
            "SHIPMENT_METHOD_TYPE_ID"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR0",
          "access_type": "ref",
          "possible_keys": [
            "SHPMNT_STTS_SHMT"
          ],
          "key": "SHPMNT_STTS_SHMT",
          "used_key_parts": [
            "SHIPMENT_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.PRIM.SHIPMENT_ID"
          ],
          "rows_examined_per_scan": 2,
          "rows_produced_per_join": 14929,
          "filtered": "100.00",
          "using_index": true,
          "cost_info": {
            "read_cost": "3170.26",
            "eval_cost": "1492.95",
            "prefix_cost": "5430.26",
            "data_read_per_join": "13M"
          },
          "used_columns": [
            "STATUS_ID",
            "SHIPMENT_ID"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR1",
          "access_type": "index",
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ],
          "key_length": "244",
          "rows_examined_per_scan": 676,
          "rows_produced_per_join": 10092330,
          "filtered": "100.00",
          "using_index": true,
          "using_join_buffer": "hash join",
          "cost_info": {
            "read_cost": "29.13",
            "eval_cost": "1009233.07",
            "prefix_cost": "1014692.46",
            "data_read_per_join": "2G"
          },
          "used_columns": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ],
          "attached_condition": "(is_not_null_compl(MBR1), (`gorjanauat`.`prim`.`SHIPMENT_ID` = `gorjanauat`.`mbr1`.`SHIPMENT_ID`), true)"
        }
      },
      {
        "table": {
          "table_name": "MBR2",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR1.PICKLIST_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 10092330,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "169.00",
            "eval_cost": "1009233.07",
            "prefix_cost": "2024094.53",
            "data_read_per_join": "26G"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PICKLIST_DATE"
          ],
          "attached_condition": "(is_not_null_compl(MBR2), (`gorjanauat`.`mbr1`.`PICKLIST_ID` = `gorjanauat`.`mbr2`.`PICKLIST_ID`), true)"
        }
      },
      {
        "table": {
          "table_name": "MBR3",
          "access_type": "ref",
          "possible_keys": [
            "PRIMARY",
            "PCKLST_RLE_PKLT"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR2.PICKLIST_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 10409091,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "2523082.67",
            "eval_cost": "1040909.12",
            "prefix_cost": "5588086.31",
            "data_read_per_join": "16G"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PARTY_ID",
            "ROLE_TYPE_ID",
            "FROM_DATE",
            "THRU_DATE"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR4",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PERSON_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR3.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 10409091,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "174.30",
            "eval_cost": "1040909.12",
            "prefix_cost": "6629169.73",
            "data_read_per_join": "72G"
          },
          "used_columns": [
            "PARTY_ID",
            "FIRST_NAME",
            "LAST_NAME"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR5",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PARTY_GRP_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR3.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 10409091,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "174.30",
            "eval_cost": "1040909.12",
            "prefix_cost": "7670253.15",
            "data_read_per_join": "140G"
          },
          "used_columns": [
            "PARTY_ID",
            "GROUP_NAME"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR6",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "ORDER_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.PRIM.PRIMARY_ORDER_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 10409091,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "1817.00",
            "eval_cost": "1040909.12",
            "prefix_cost": "8712979.27",
            "data_read_per_join": "28G"
          },
          "used_columns": [
            "ORDER_ID",
            "PRODUCT_STORE_ID"
          ]
        }
      }
    ]
  }
}
```

---

### Base Query 2: Starting with PICKLIST_SHIPMENT
```sql
EXPLAIN FORMAT=JSON
SELECT 
    MBR0.SHIPMENT_ID,
    MBR0.SHIPMENT_TYPE_ID,
    MBR0.STATUS_ID,
    MBR1.STATUS_ID,
    MBR0.ORIGIN_FACILITY_ID,
    MBR0.SHIPMENT_METHOD_TYPE_ID,
    MBR0.PRIMARY_ORDER_ID,
    MBR2.PRODUCT_STORE_ID,
    MBR4.ROLE_TYPE_ID,
    MBR4.FROM_DATE,
    MBR4.THRU_DATE,
    MBR5.FIRST_NAME,
    MBR5.LAST_NAME,
    MBR4.PARTY_ID,
    MBR6.GROUP_NAME,
    MBR3.PICKLIST_DATE
FROM PICKLIST_SHIPMENT PRIM
LEFT OUTER JOIN SHIPMENT MBR0
    ON PRIM.SHIPMENT_ID = MBR0.SHIPMENT_ID
LEFT OUTER JOIN SHIPMENT_STATUS MBR1
    ON MBR0.SHIPMENT_ID = MBR1.SHIPMENT_ID
LEFT OUTER JOIN ORDER_HEADER MBR2
    ON MBR0.PRIMARY_ORDER_ID = MBR2.ORDER_ID
LEFT OUTER JOIN PICKLIST MBR3
    ON PRIM.PICKLIST_ID = MBR3.PICKLIST_ID
LEFT OUTER JOIN PICKLIST_ROLE MBR4
    ON MBR3.PICKLIST_ID = MBR4.PICKLIST_ID
LEFT OUTER JOIN PERSON MBR5
    ON MBR4.PARTY_ID = MBR5.PARTY_ID
LEFT OUTER JOIN PARTY_GROUP MBR6
    ON MBR4.PARTY_ID = MBR6.PARTY_ID;
```

#### Execution Plan (JSON)
```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "2480.06"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "PRIM",
          "access_type": "index",
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ],
          "key_length": "244",
          "rows_examined_per_scan": 676,
          "rows_produced_per_join": 676,
          "filtered": "100.00",
          "using_index": true,
          "cost_info": {
            "read_cost": "1.00",
            "eval_cost": "67.60",
            "prefix_cost": "68.60",
            "data_read_per_join": "174K"
          },
          "used_columns": [
            "PICKLIST_ID",
            "SHIPMENT_ID"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR0",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "SHIPMENT_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.PRIM.SHIPMENT_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 676,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "169.00",
            "eval_cost": "67.60",
            "prefix_cost": "305.20",
            "data_read_per_join": "3M"
          },
          "used_columns": [
            "SHIPMENT_ID",
            "SHIPMENT_TYPE_ID",
            "STATUS_ID",
            "PRIMARY_ORDER_ID",
            "ORIGIN_FACILITY_ID",
            "SHIPMENT_METHOD_TYPE_ID"
          ],
          "attached_condition": "(is_not_null_compl(MBR0), (`gorjanauat`.`prim`.`SHIPMENT_ID` = `gorjanauat`.`mbr0`.`SHIPMENT_ID`), true)"
        }
      },
      {
        "table": {
          "table_name": "MBR1",
          "access_type": "ref",
          "possible_keys": [
            "SHPMNT_STTS_SHMT"
          ],
          "key": "SHPMNT_STTS_SHMT",
          "used_key_parts": [
            "SHIPMENT_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR0.SHIPMENT_ID"
          ],
          "rows_examined_per_scan": 2,
          "rows_produced_per_join": 1388,
          "filtered": "100.00",
          "using_index": true,
          "cost_info": {
            "read_cost": "294.87",
            "eval_cost": "138.86",
            "prefix_cost": "738.93",
            "data_read_per_join": "1M"
          },
          "used_columns": [
            "STATUS_ID",
            "SHIPMENT_ID"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR2",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "ORDER_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR0.PRIMARY_ORDER_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 1388,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "169.00",
            "eval_cost": "138.86",
            "prefix_cost": "1046.79",
            "data_read_per_join": "3M"
          },
          "used_columns": [
            "ORDER_ID",
            "PRODUCT_STORE_ID"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR3",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.PRIM.PICKLIST_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 1388,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "169.00",
            "eval_cost": "138.86",
            "prefix_cost": "1354.65",
            "data_read_per_join": "3M"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PICKLIST_DATE"
          ],
          "attached_condition": "(is_not_null_compl(MBR3), (`gorjanauat`.`prim`.`PICKLIST_ID` = `gorjanauat`.`mbr3`.`PICKLIST_ID`), true)"
        }
      },
      {
        "table": {
          "table_name": "MBR4",
          "access_type": "ref",
          "possible_keys": [
            "PRIMARY",
            "PCKLST_RLE_PKLT"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PICKLIST_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR3.PICKLIST_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 1432,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "347.15",
            "eval_cost": "143.22",
            "prefix_cost": "1845.01",
            "data_read_per_join": "2M"
          },
          "used_columns": [
            "PICKLIST_ID",
            "PARTY_ID",
            "ROLE_TYPE_ID",
            "FROM_DATE",
            "THRU_DATE"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR5",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PERSON_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR4.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 1432,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "174.30",
            "eval_cost": "143.22",
            "prefix_cost": "2162.54",
            "data_read_per_join": "10M"
          },
          "used_columns": [
            "PARTY_ID",
            "FIRST_NAME",
            "LAST_NAME"
          ]
        }
      },
      {
        "table": {
          "table_name": "MBR6",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY",
            "PARTY_GRP_PARTY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "PARTY_ID"
          ],
          "key_length": "62",
          "ref": [
            "gorjanauat.MBR4.PARTY_ID"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 1432,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "174.30",
            "eval_cost": "143.22",
            "prefix_cost": "2480.06",
            "data_read_per_join": "19M"
          },
          "used_columns": [
            "PARTY_ID",
            "GROUP_NAME"
          ]
        }
      }
    ]
  }
}
```
