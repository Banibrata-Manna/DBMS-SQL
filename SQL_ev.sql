-- 1. BOPIS Orders Revenue (Last Year)
-- Business Problem:
-- BOPIS (Buy Online, Pickup In Store) is a key retail strategy. Finance wants to know the revenue from BOPIS orders for the previous year.
-- 
-- Fields to Retrieve:
-- 
-- TOTAL ORDERS
-- TOTAL REVENUE

-- Cost - 7504

-- Reason - Simply counted 

select count(*), sum(oh.GRAND_TOTAL) from order_header oh 
join shipment s on oh.ORDER_ID = s.PRIMARY_ORDER_ID and s.SHIPMENT_METHOD_TYPE_ID = 'STOREPICKUP'
and oh.SALES_CHANNEL_ENUM_ID = 'WEB_SALES_CHANNEL' 
and oh.STATUS_ID != 'ORDER_CANCELLED'
and oh.ORDER_DATE >= '2023-01-01 00:00:00' and oh.ORDER_DATE <= '2023-12-31 00:00:00';

-- 2. Orders Completed Hourly
-- Business Problem:
-- Operations teams may want to see how orders complete across the day to schedule staffing.
--
-- Fields to Retrieve:
--
-- TOTAL ORDERS
-- HOUR

-- Cost 14719

-- Reason - 

SELECT 
    hour(os.STATUS_DATETIME) as hour, 
    count(*) as total_orders
from order_status os
where os.STATUS_ID = 'ORDER_COMPLETED'
and os.STATUS_DATETIME >= '2021-08-18 00:00:00' and os.STATUS_DATETIME < '2021-08-19 00:00:00'
group by hour;

-- 3. Items Where QOH and ATP Differ
-- Business Problem:
-- Sometimes the Quantity on Hand (QOH) doesn’t match the Available to Promise (ATP) 
-- due to pending orders, reservations, or data discrepancies. 
-- This needs review for accurate fulfillment planning.
-- 
-- Fields to Retrieve:
-- 
-- PRODUCT_ID
-- FACILITY_ID
-- QOH (Quantity on Hand)
-- ATP (Available to Promise)
-- DIFFERENCE (QOH - ATP)

-- cost - 217177

-- Reason - found the difference between total QOH and for ATP all inventory items of a product at a facility by grouping the records by inventory item by product id and facility id. 

select 
	ii.PRODUCT_ID ,
	ii.FACILITY_ID ,
	sum(ii.QUANTITY_ON_HAND_TOTAL),
	sum(ii.AVAILABLE_TO_PROMISE_TOTAL),
	(sum(ii.QUANTITY_ON_HAND_TOTAL) - sum(ii.AVAILABLE_TO_PROMISE_TOTAL)) as difference_ATP_QOH
from
inventory_item ii
group by ii.PRODUCT_ID, ii.FACILITY_ID having difference_ATP_QOH != 0;


-- 4. Store with Most One-Day Shipped Orders (Last Month)
-- Business Problem:
-- Identify which facility (store) handled the highest volume of “one-day shipping” orders in the previous month, useful for operational benchmarking.
-- 
-- Fields to Retrieve:
-- FACLITY_NAME
-- FACILITY_ID
-- TOTAL_ONE_DAY_SHIP_ORDERS
-- REPORTING_PERIOD

-- cost - 4203.99

-- Reason - grouped orders shipped by a facility by shipment records having 'SHIPMENT_SHIPPED' status having method 'NEXT_DAY' 

select s.origin_facility_id as facility_id, f.FACILITY_NAME as name,
       count(distinct s.primary_order_id) as total_one_day_ship_orders,
       concat(date_format(now() - interval 2 month, '%Y-%m-01'), ' to ',
       	last_day(now() - interval 2 month))
       as reporting_period
from shipment s
join shipment_method_type smt 
    on s.shipment_method_type_id = smt.shipment_method_type_id
    and s.status_id = 'SHIPMENT_SHIPPED'
join facility f on f.FACILITY_ID = s.ORIGIN_FACILITY_ID 
where (smt.parent_type_id = 'NEXT_DAY' or s.SHIPMENT_METHOD_TYPE_ID = 'NEXT_DAY')
and s.created_date >= date_format(now() - interval 2 month, '%Y-%m-01')
and s.created_date <= last_day(now() - interval 2 month)
group by s.origin_facility_id, f.FACILITY_NAME
order by total_one_day_ship_orders desc
limit 1;

-- 5. Product IDs Across Systems
-- Business Problem:
-- To sync an order or product across multiple systems 
-- (e.g., Shopify, HotWax, ERP/NetSuite),
-- the OMS needs to know each system’s unique identifier for that product.
-- This query retrieves the Shopify ID, HotWax ID, and ERP ID (NetSuite ID) for all products.
-- 
-- Fields to Retrieve:
-- 
-- PRODUCT_ID (internal OMS ID)
-- SHOPIFY_ID
-- HOTWAX_ID
-- ERP_ID or NETSUITE_ID

-- Cost - 222982

-- Reason - Joined Product table with two good_identification aliases to get both erp and shopify product id 
-- for a product in a single tuple. 

SELECT 
    p.PRODUCT_ID as Hotwax_ID,
    gi_erp.ID_VALUE AS ERP_ID,
    gi_prod.ID_VALUE AS SHOPIFY_PROD_ID
FROM product p
JOIN good_identification gi_erp 
    ON gi_erp.PRODUCT_ID = p.PRODUCT_ID 
    AND gi_erp.GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID'
JOIN good_identification gi_prod 
    ON gi_prod.PRODUCT_ID = p.PRODUCT_ID 
    AND gi_prod.GOOD_IDENTIFICATION_TYPE_ID = 'SHOPIFY_PROD_ID';
