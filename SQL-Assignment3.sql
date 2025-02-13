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











