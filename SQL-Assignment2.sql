-- 5.1 Shipping Addresses for October 2023 Orders
-- Business Problem:
-- Customer Service might need to verify addresses for orders placed or completed in October 2023. This helps ensure shipments are delivered correctly and prevents address-related issues.
-- 
-- Fields to Retrieve:
-- 
-- ORDER_ID
-- PARTY_ID (Customer ID)
-- CUSTOMER_NAME (or FIRST_NAME / LAST_NAME)
-- STREET_ADDRESS
-- CITY
-- STATE_PROVINCE
-- POSTAL_CODE
-- COUNTRY_CODE
-- ORDER_STATUS
-- ORDER_DATE

select 
	oh.ORDER_ID , oh.ORDER_DATE , or2.PARTY_ID , concat(p.FIRST_NAME, ' ', p.LAST_NAME),
	pa.CITY , pa.STATE_PROVINCE_GEO_ID , pa.POSTAL_CODE , pa.COUNTRY_GEO_ID , os.ORDER_STATUS_ID
from 
order_header oh 
join order_status os on oh.ORDER_ID = os.ORDER_ID and (os.STATUS_ID = 'ORDER_CREATED' or
os.STATUS_ID = 'ORDER_COMPLETED')
and os.STATUS_DATETIME >= '2023-10-01' and os.STATUS_DATETIME <= '2023-10-30'
join order_role or2 on oh.ORDER_ID = or2.ORDER_ID and or2.ROLE_TYPE_ID = 'PLACING_CUSTOMER'
join person p on or2.PARTY_ID = p.PARTY_ID
join order_contact_mech ocm on oh.ORDER_ID = ocm.ORDER_ID
and ocm.CONTACT_MECH_PURPOSE_TYPE_ID = 'SHIPPING_LOCATION'
join postal_address pa on ocm.CONTACT_MECH_ID = pa.CONTACT_MECH_ID;

-- 5.2 Orders from New York
-- Business Problem:
-- Companies often want region-specific analysis to plan local marketing, staffing, or promotions in certain areas—here, specifically, New York.
-- 
-- Fields to Retrieve:
-- 
-- ORDER_ID
-- CUSTOMER_NAME
-- STREET_ADDRESS (or shipping address detail)
-- CITY
-- STATE_PROVINCE
-- POSTAL_CODE
-- TOTAL_AMOUNT
-- ORDER_DATE
-- ORDER_STATUS

select 
	oh.ORDER_ID , oh.ORDER_DATE , or2.PARTY_ID , concat(p.FIRST_NAME, ' ', p.LAST_NAME),
	pa.ADDRESS1,
	pa.CITY , g.GEO_NAME , pa.POSTAL_CODE , pa.COUNTRY_GEO_ID , os.ORDER_STATUS_ID
from 
order_header oh 
join order_status os on oh.ORDER_ID = os.ORDER_ID and (os.STATUS_ID = 'ORDER_CREATED' or
os.STATUS_ID = 'ORDER_COMPLETED')
join order_role or2 on oh.ORDER_ID = or2.ORDER_ID and or2.ROLE_TYPE_ID = 'PLACING_CUSTOMER'
join person p on or2.PARTY_ID = p.PARTY_ID
join order_contact_mech ocm on oh.ORDER_ID = ocm.ORDER_ID
and ocm.CONTACT_MECH_PURPOSE_TYPE_ID = 'SHIPPING_LOCATION'
join postal_address pa on ocm.CONTACT_MECH_ID = pa.CONTACT_MECH_ID
join geo g on pa.STATE_PROVINCE_GEO_ID = g.GEO_ID and g.GEO_NAME = 'New York';

-- 5.3 Top-Selling Product in New York
-- Business Problem:
-- Merchandising teams need to identify the best-selling product(s)
-- in a specific region (New York) for targeted restocking or promotions.
-- 
-- Fields to Retrieve:
-- 
-- PRODUCT_ID
-- INTERNAL_NAME
-- TOTAL_QUANTITY_SOLD
-- CITY / STATE (within New York region)
-- REVENUE (optionally, total sales amount)

with product_sales as (
    select 
        p.PRODUCT_ID,
        p.INTERNAL_NAME,
        sum(oi.QUANTITY) as TOTAL_QUANTITY_SOLD,
        pa.CITY,
        pa.STATE_PROVINCE_GEO_ID,
        sum(oi.UNIT_PRICE * oi.QUANTITY) as REVENUE,
        avg(SUM(oi.QUANTITY)) over () as AVG_QUANTITY_SOLD
    from order_header oh
    join order_contact_mech ocm 
        on oh.ORDER_TYPE_ID = 'SALES_ORDER' and oh.ORDER_ID = ocm.ORDER_ID 
        and ocm.CONTACT_MECH_PURPOSE_TYPE_ID = 'SHIPPING_LOCATION'
    join postal_address pa 
        on ocm.CONTACT_MECH_ID = pa.CONTACT_MECH_ID 
        and (pa.CITY_GEO_ID = 'NY' 
        or pa.STATE_PROVINCE_GEO_ID = 'NY')
    join order_item oi 
        on oh.ORDER_ID = oi.ORDER_ID 
    join product p 
        on oi.PRODUCT_ID = p.PRODUCT_ID
    group by 
        p.PRODUCT_ID, p.INTERNAL_NAME, pa.CITY, pa.STATE_PROVINCE_GEO_ID
)
select * 
from product_sales 
where TOTAL_QUANTITY_SOLD > AVG_QUANTITY_SOLD;

-- 7.3 Store-Specific (Facility-Wise) Revenue
-- Business Problem:
-- Different physical or online stores (facilities) may have varying levels of performance. The business wants to compare revenue across facilities for sales planning and budgeting.
-- 
-- Fields to Retrieve:
-- 
-- FACILITY_ID
-- FACILITY_NAME
-- TOTAL_ORDERS
-- TOTAL_REVENUE
-- DATE_RANGE

select 
    f.facility_id as facility_id,
    f.facility_name as facility_name,
    count(distinct oh.order_id) as total_orders,
    sum(oh.grand_total) as total_revenue,
    concat(min(oh.entry_date), ' to ', max(oh.entry_date)) as date_range
from order_header oh
join order_item_ship_group oisg 
    on oh.order_id = oisg.order_id and oh.ENTRY_DATE >= '2020-01-01 00:00:00' and
oh.ENTRY_DATE <= '2020-01-31 00:00:00' and oh.status_id = 'ORDER_COMPLETED'
join facility f 
    on oisg.facility_id = f.facility_id 
group by f.facility_id, f.facility_name;


-- 8.1 Lost and Damaged Inventory
-- Business Problem:
-- Warehouse managers need to track “shrinkage” 
--such as lost or damaged inventory to reconcile physical vs. system counts.
-- 
-- Fields to Retrieve:
-- 
-- INVENTORY_ITEM_ID
-- PRODUCT_ID
-- FACILITY_ID
-- QUANTITY_LOST_OR_DAMAGED
-- REASON_CODE (Lost, Damaged, Expired, etc.)
-- TRANSACTION_DATE

select 
	ii.INVENTORY_ITEM_ID ,
	ii.PRODUCT_ID ,
	ii.FACILITY_ID ,
	(iiv.AVAILABLE_TO_PROMISE_VAR*-1) ATP_Variation,
	(iiv.QUANTITY_ON_HAND_VAR*-1) QOH_Variation,
	iiv.VARIANCE_REASON_ID ,
	iiv.CREATED_TX_STAMP as Transaction_Date 
from
inventory_item ii
join inventory_item_variance iiv on ii.INVENTORY_ITEM_ID = iiv.INVENTORY_ITEM_ID
and (iiv.VARIANCE_REASON_ID = 'VAR_DAMAGED' OR iiv.VARIANCE_REASON_ID = 'VAR_LOST');

-- 8.3 Retrieve the Current Facility (Physical or Virtual) of Open Orders
-- Business Problem:
-- The business wants to know where open orders are currently assigned,
-- whether in a physical store or a virtual facility 
-- (e.g., a distribution center or online fulfillment location).
-- 
-- Fields to Retrieve:
-- 
-- ORDER_ID
-- ORDER_STATUS
-- FACILITY_ID
-- FACILITY_NAME
-- FACILITY_TYPE_ID

select oh.ORDER_ID ,
	oh.STATUS_ID ,
	oisg.FACILITY_ID ,
	f.FACILITY_NAME,
	f.FACILITY_TYPE_ID
from 
order_header oh 
join order_item_ship_group oisg on oh.ORDER_ID = oisg.ORDER_ID and oh.STATUS_ID = 'ORDER_CREATED'
join facility f on f.FACILITY_ID = oisg.FACILITY_ID ;

-- 8.4 Items Where QOH and ATP Differ
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

select 
	ii.PRODUCT_ID ,
	ii.FACILITY_ID ,
	ii.AVAILABLE_TO_PROMISE_TOTAL ,
	ii.QUANTITY_ON_HAND_TOTAL ,
	(ii.QUANTITY_ON_HAND_TOTAL - ii.AVAILABLE_TO_PROMISE_TOTAL) as difference_ATP_QOH
from
inventory_item ii;

select 
	ii.PRODUCT_ID ,
	ii.FACILITY_ID ,
	ii.AVAILABLE_TO_PROMISE_TOTAL ,
	ii.QUANTITY_ON_HAND_TOTAL ,
	(ii.QUANTITY_ON_HAND_TOTAL - ii.AVAILABLE_TO_PROMISE_TOTAL) as difference_ATP_QOH
from
inventory_item ii where ii.QUANTITY_ON_HAND_TOTAL - ii.AVAILABLE_TO_PROMISE_TOTAL != 0;

-- 8.6 Total Orders by Sales Channel
-- Business Problem:
-- Marketing and sales teams want to see how many orders come from each channel (e.g., web, mobile app, in-store POS, marketplace) to allocate resources effectively.
-- 
-- Fields to Retrieve:
-- 
-- SALES_CHANNEL
-- TOTAL_ORDERS
-- TOTAL_REVENUE
-- REPORTING_PERIOD

select 
    count(oh.order_id) as total_orders,
    sum(oh.grand_total) as total_revenue,
    min(oh.entry_date) as min_order_entry_date,
    max(oh.entry_date) as max_order_entry_date
from order_header oh
where oh.entry_date between '2020-01-01' and '2020-12-01'
group by oh.SALES_CHANNEL_ENUM_ID;

with channel_group_report as (
    select 
        count(oh.order_id) as total_orders, 
        sum(oh.grand_total) as total_revenue,
        oh.sales_channel_enum_id as sales_channel,
        oh.entry_date as order_entry_date
    from order_header oh
    group by oh.sales_channel_enum_id, oh.entry_date
)
select 
    sales_channel,
    sum(total_orders) as total_orders, 
    sum(total_revenue) as total_revenue, 
    concat(min(order_entry_date), ' to ', max(order_entry_date)) as reporting_period
from channel_group_report
where order_entry_date between '2020-01-01' and '2020-12-01'
group by sales_channel;


