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











