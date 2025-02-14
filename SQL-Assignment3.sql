-- 1 Completed Sales Orders (Physical Items)
-- Business Problem:
-- Merchants need to track only physical items (requiring shipping and fulfillment) for logistics and shipping-cost analysis.
-- 
-- Fields to Retrieve:
-- 
-- ORDER_ID
-- ORDER_ITEM_SEQ_ID
-- PRODUCT_ID
-- PRODUCT_TYPE_ID
-- SALES_CHANNEL_ENUM_ID
-- ORDER_DATE
-- ENTRY_DATE
-- STATUS_ID
-- STATUS_DATETIME
-- ORDER_TYPE_ID
-- PRODUCT_STORE_ID

select
	oh.ORDER_ID ,
	oi.ORDER_ITEM_SEQ_ID ,
	p.PRODUCT_ID ,
	p.PRODUCT_TYPE_ID ,
	oh.SALES_CHANNEL_ENUM_ID ,
	oh.ORDER_DATE ,
	oh.ENTRY_DATE ,
	os.STATUS_ID ,
	os.STATUS_DATETIME ,
	oh.ORDER_TYPE_ID ,
	oh.PRODUCT_STORE_ID 
from
order_header oh
join
order_item oi on oh.ORDER_ID = oi.ORDER_ID 
join 
order_status os on oi.ORDER_ID = os.ORDER_ID and oi.ORDER_ITEM_SEQ_ID = os.ORDER_ITEM_SEQ_ID 
join
product p on oi.PRODUCT_ID = p.PRODUCT_ID
join 
product_type pt on p.PRODUCT_TYPE_ID = pt.PRODUCT_TYPE_ID;


-- 2 Completed Return Items
-- Business Problem:
-- Customer service and finance often need insights into
-- returned items to manage refunds, replacements, and inventory restocking.
-- 
-- Fields to Retrieve:
-- 
-- RETURN_ID
-- ORDER_ID
-- PRODUCT_STORE_ID
-- STATUS_DATETIME
-- ORDER_NAME
-- FROM_PARTY_ID
-- RETURN_DATE
-- ENTRY_DATE
-- RETURN_CHANNEL_ENUM_ID

select
	rh.RETURN_ID ,
	ri.ORDER_ID ,
	oh.PRODUCT_STORE_ID ,
	rs.STATUS_ID ,
	rs.STATUS_DATETIME ,
	oh.ORDER_NAME ,
	rh.FROM_PARTY_ID ,
	rh.RETURN_DATE ,
	rh.ENTRY_DATE ,
	rh.RETURN_CHANNEL_ENUM_ID 
from 
return_header rh 
join 
return_item ri on rh.RETURN_ID = ri.RETURN_ID 
join 
return_status rs on rh.RETURN_ID = rs.RETURN_ID 
and ri.RETURN_ITEM_SEQ_ID = rs.RETURN_ITEM_SEQ_ID 
join 
order_header oh on ri.ORDER_ID = oh.ORDER_ID;


-- 3 Single-Return Orders (Last Month)
-- Business Problem:
-- The mechandising team needs a list of orders that only have one return.
-- 
-- Fields to Retrieve:
-- 
-- PARTY_ID
-- FIRST_NAME


select ri.ORDER_ID, sum(ri.RETURN_QUANTITY) as items_returned from
return_header rh 
join return_item ri on rh.RETURN_ID = ri.RETURN_ID and ri.STATUS_ID = 'RETURN_COMPLETED'
group by ri.ORDER_ID
having items_returned = 1;


select 
	sum(ri.RETURN_QUANTITY) as total_returns,
	sum(ri.RETURN_PRICE) as return_total
	from 
	return_header rh join
	return_item ri on rh.RETURN_ID = ri.RETURN_ID and ri.STATUS_ID = 'RETURN_COMPLETED';


select 
    count(ra.RETURN_ADJUSTMENT_ID) as appeasement_count, 
    sum(ra.AMOUNT) as total_appeasement_amount 
    from
    return_adjustment ra where ra.RETURN_ADJUSTMENT_TYPE_ID = 'APPEASEMENT';


with returns_against_appeasements AS (
    select 
        sum(ri.RETURN_QUANTITY) AS total_returns,
        sum(ri.RETURN_PRICE) AS return_total
    from 
        return_header rh
    join 
        return_item ri ON rh.RETURN_ID = ri.RETURN_ID
    where 
        ri.STATUS_ID = 'RETURN_COMPLETED'
)
select 
    raa.total_returns, 
    raa.return_total, 
    count(ra.RETURN_ADJUSTMENT_ID) as appeasement_count, 
    sum(ra.AMOUNT) as total_appeasement_amount
from 
    returns_against_appeasements raa
join 
    return_adjustment ra on ra.RETURN_ADJUSTMENT_TYPE_ID = 'APPEASEMENT'
group by 
    raa.total_returns, raa.return_total;


-- 4 Returns and Appeasements
-- Business Problem:
-- The retailer needs the total amount of items, were returned as well as how many appeasements were issued.
-- 
-- Fields to Retrieve:
-- 
-- TOTAL RETURNS
-- RETURN $ TOTAL
-- TOTAL APPEASEMENTS
-- APPEASEMENTS $ TOTAL

select 
    r.total_returns,
    r.return_total,
    a.appeasement_count,
    a.total_appeasement_amount
from 
(select 
    sum(ri.return_quantity) as total_returns,
    sum(ri.return_price) as return_total
 from return_header rh
 join return_item ri on rh.return_id = ri.return_id
 where ri.status_id = 'RETURN_COMPLETED'
) r
cross join 
(select 
    count(ra.return_adjustment_id) as appeasement_count, 
    sum(ra.amount) as total_appeasement_amount 
 from return_adjustment ra 
 where ra.return_adjustment_type_id = 'APPEASEMENT'
) a;

-- 5 Detailed Return Information
-- Business Problem:
-- Certain teams need granular return data (reason, date, refund amount)
-- for analyzing return rates, identifying recurring issues, or updating policies.
-- 
-- Fields to Retrieve:
-- 
-- RETURN_ID
-- ENTRY_DATE
-- RETURN_ADJUSTMENT_TYPE_ID (refund type, store credit, etc.)
-- AMOUNT
-- COMMENTS
-- ORDER_ID
-- ORDER_DATE
-- RETURN_DATE
-- PRODUCT_STORE_ID

select rh.RETURN_ID, 
	rh.ENTRY_DATE ,
	ra.RETURN_ADJUSTMENT_ID ,
	ra.AMOUNT ,
	ra.COMMENTS ,
	ra.ORDER_ID ,
	rh.RETURN_DATE ,
	oh.PRODUCT_STORE_ID 
from 
return_header rh 
join 
return_adjustment ra on rh.RETURN_ID = ra.RETURN_ID 
join 
order_header oh on ra.ORDER_ID = oh.ORDER_ID;

-- 6 Orders with Multiple Returns
-- Business Problem:
-- Analyzing orders with multiple returns can identify potential fraud, chronic issues with certain items, or inconsistent shipping processes.
-- 
-- Fields to Retrieve:
-- 
-- ORDER_ID
-- RETURN_ID
-- RETURN_DATE
-- RETURN_REASON
-- RETURN_QUANTITY

select ri.ORDER_ID, sum(ri.RETURN_QUANTITY) from 
return_header rh 
join 
return_item ri on rh.RETURN_ID = ri.RETURN_ID and ri.STATUS_ID = 'RETURN_COMPLETED'
group by ri.ORDER_ID
having sum(ri.RETURN_QUANTITY) > 1;

-- 7 Store with Most One-Day Shipped Orders (Last Month)
-- Business Problem:
-- Identify which facility (store) handled the highest volume of “one-day shipping” orders in the previous month, useful for operational benchmarking.
-- 
-- Fields to Retrieve:
-- FACLITY_NAME
-- FACILITY_ID
-- TOTAL_ONE_DAY_SHIP_ORDERS
-- REPORTING_PERIOD


select s.origin_facility_id as facility_id, f.FACILITY_NAME as name,
       count(distinct s.primary_order_id) as total_one_day_ship_orders,
       concat(date_format(now() - interval 1 month, '%Y-%m-01'), ' to ',
       	last_day(now() - interval 1 month))
       as reporting_period
from shipment s
join shipment_method_type smt 
    on s.shipment_method_type_id = smt.shipment_method_type_id
    and s.status_id = 'SHIPMENT_SHIPPED'
join facility f on f.FACILITY_ID = s.ORIGIN_FACILITY_ID 
where (smt.parent_type_id = 'NEXT_DAY' or s.SHIPMENT_METHOD_TYPE_ID = 'NEXT_DAY')
and s.last_modified_date >= date_format(now() - interval 1 month, '%Y-%m-01')
and s.last_modified_date <= last_day(now() - interval 1 month)
group by s.origin_facility_id, f.FACILITY_NAME
order by total_one_day_ship_orders desc
limit 1;







