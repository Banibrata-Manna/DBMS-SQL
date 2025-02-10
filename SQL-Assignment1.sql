-- The marketing team ran a campaign in June 2023 and 
-- wants to see how many new customers signed up during that period.

select
p.FIRST_NAME,p.LAST_NAME,
(select cm.INFO_STRING from contact_mech cm 
join party_contact_mech pcm on p.PARTY_ID = pcm.PARTY_ID and cm.CONTACT_MECH_TYPE_ID = 'EMAIL_ADDRESS' limit 1),
(select tn.CONTACT_NUMBER  from contact_mech cm 
join party_contact_mech pcm on p.PARTY_ID = pcm.PARTY_ID and cm.CONTACT_MECH_TYPE_ID = 'TELECOM_NUMBER'
join telecom_number tn on tn.CONTACT_MECH_ID = pcm.CONTACT_MECH_ID limit 1)
from 
person p
join party_role pr on pr.PARTY_ID = p.PARTY_ID and
p.CREATED_STAMP >= '2023-06-01' and p.CREATED_STAMP <='2023-06-30' and pr.ROLE_TYPE_ID = "CUSTOMER";

--Finding Physical Products FOR merchandising teams

--fields TO SELECT 
--	productId
--	product TYPE id
--	Internal name

-- Finding Physical Products FOR merchandising teams

-- fields TO SELECT 
--	productId
--	product TYPE id
--	Internal name


select p.PRODUCT_ID, p.PRODUCT_TYPE_ID, p.INTERNAL_NAME from product p
where p.IS_VARIANT = 'Y' and p.PRODUCT_TYPE_ID = 'FINISHED_GOOD';

select p.PRODUCT_ID, p.PRODUCT_TYPE_ID, p.INTERNAL_NAME from product p
join 
product_type pt on p.PRODUCT_TYPE_ID = pt.PRODUCT_TYPE_ID and pt.IS_PHYSICAL = 'Y';


-- 3 Products Missing NetSuite ID
-- Business Problem:
-- A product cannot sync to NetSuite unless it has a valid NetSuite ID.
-- The OMS needs a list of all products that still need to be created or updated in NetSuite.
-- 
-- Fields to Retrieve:
-- 
-- PRODUCT_ID
-- INTERNAL_NAME
-- PRODUCT_TYPE_ID
-- NETSUITE_ID (or similar field indicating the NetSuite ID; may be NULL or empty if missing)

select p.PRODUCT_ID, p.INTERNAL_NAME , p.PRODUCT_TYPE_ID , gi.ID_VALUE  from product p
join good_identification gi on p.PRODUCT_ID = gi.PRODUCT_ID 
and gi.GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID' and gi.ID_VALUE  is null;


-- 5 Completed Orders in August 2023
-- Business Problem:
-- After running similar reports for a previous month,
-- you now need all completed orders in August 2023 for analysis.
-- 
-- Fields to Retrieve:
-- 
-- PRODUCT_ID
-- PRODUCT_TYPE_ID
-- PRODUCT_STORE_ID
-- TOTAL_QUANTITY
-- INTERNAL_NAME
-- FACILITY_ID
-- EXTERNAL_ID
-- FACILITY_TYPE_ID
-- ORDER_HISTORY_ID
-- ORDER_ID
-- ORDER_ITEM_SEQ_ID
-- SHIP_GROUP_SEQ_ID



select oi.PRODUCT_ID , p.PRODUCT_TYPE_ID , psc.PRODUCT_STORE_ID, oi.QUANTITY, oi.EXTERNAL_ID ,
oi.ORDER_ID , oi.ORDER_ITEM_SEQ_ID , oisg.FACILITY_ID, oi.EXTERNAL_ID ,
oh.ORDER_HISTORY_ID , oisg.SHIP_GROUP_SEQ_ID  from
order_item oi 
join
order_status os on os.ORDER_ID = oi.ORDER_ID
and os.STATUS_ID = 'ORDER_COMPLETED' and os.STATUS_DATETIME >= '2023-08-01'
and os.STATUS_DATETIME <= '2023-08-31'
join order_item_ship_group oisg on oi.ORDER_ID = oisg.ORDER_ID and oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID-- joining items and ship group by orderId
join product_store_facility psf on oisg.FACILITY_ID = psf.FACILITY_ID and psf.THRU_DATE is null -- joining the stores which use the facility mentioned in ship group 
join product_store_catalog psc on oi.PROD_CATALOG_ID = psc.PROD_CATALOG_ID and psc.THRU_DATE is null
and psc.PRODUCT_STORE_ID = psf.PRODUCT_STORE_ID -- joining the stores that have the similar catalog of product item
join product p on p.PRODUCT_ID = oi.PRODUCT_ID
join
order_history oh on oi.ORDER_ID = oh.ORDER_ID and oi.ORDER_ITEM_SEQ_ID = oh.ORDER_ITEM_SEQ_ID and oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID;



select oi.PRODUCT_ID , p.PRODUCT_TYPE_ID , product_stores.ps, oi.QUANTITY, oi.EXTERNAL_ID ,
oi.ORDER_ID , oi.ORDER_ITEM_SEQ_ID , oisg.FACILITY_ID, oi.EXTERNAL_ID ,
oh.ORDER_HISTORY_ID , oisg.SHIP_GROUP_SEQ_ID from
order_item oi 
join
order_status os on os.ORDER_ID = oi.ORDER_ID
and os.STATUS_ID = 'ORDER_COMPLETED' and os.STATUS_DATETIME >= '2023-08-01'
and os.STATUS_DATETIME <= '2023-08-31' 
join order_item_ship_group oisg on oi.ORDER_ID = oisg.ORDER_ID and oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID -- joining items and ship group by orderId
join (select ps.PRODUCT_STORE_ID as ps, psc.PROD_CATALOG_ID as pci, psf.FACILITY_ID as fi from product_store ps 
join product_store_catalog psc using(PRODUCT_STORE_ID)
join product_store_facility psf using(PRODUCT_STORE_ID)
where psf.THRU_DATE is null and psc.THRU_DATE is null) as product_stores on product_stores.pci = oi.PROD_CATALOG_ID and product_stores.fi = oisg.FACILITY_ID 
join product p on p.PRODUCT_ID = oi.PRODUCT_ID
join order_history oh on oi.ORDER_ID = oh.ORDER_ID and oi.ORDER_ITEM_SEQ_ID = oh.ORDER_ITEM_SEQ_ID and oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID;


select oi.PRODUCT_ID , p.PRODUCT_TYPE_ID , f.PRODUCT_STORE_ID , oi.QUANTITY, oi.EXTERNAL_ID ,
oi.ORDER_ID , oi.ORDER_ITEM_SEQ_ID , oisg.FACILITY_ID, oi.EXTERNAL_ID ,
oh.ORDER_HISTORY_ID , oisg.SHIP_GROUP_SEQ_ID from
order_item oi
join
order_status os on os.ORDER_ID = oi.ORDER_ID
and os.STATUS_ID = 'ORDER_COMPLETED' and os.STATUS_DATETIME >= '2023-08-01' and os.STATUS_DATETIME <= '2023-08-31'
join
order_item_ship_group oisg on oi.ORDER_ID = oisg.ORDER_ID and oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID
join 
facility f on oisg.FACILITY_ID = f.FACILITY_ID 
join 
order_history oh on oi.ORDER_ID = oh.ORDER_ID and oi.ORDER_ITEM_SEQ_ID = oh.ORDER_ITEM_SEQ_ID and oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID 
join
product p on p.PRODUCT_ID = oi.PRODUCT_ID;

select oi.PRODUCT_ID , p.PRODUCT_TYPE_ID , oh.PRODUCT_STORE_ID , oi.QUANTITY, oi.EXTERNAL_ID ,
oi.ORDER_ID , oi.ORDER_ITEM_SEQ_ID , oisg.FACILITY_ID, oi.EXTERNAL_ID ,
ohs.ORDER_HISTORY_ID , oisg.SHIP_GROUP_SEQ_ID from
order_header oh 
join
order_status os on os.ORDER_ID = oh.ORDER_ID
join
order_item oi on oh.ORDER_ID = oi.ORDER_ID 
and os.STATUS_ID = 'ORDER_COMPLETED' and os.STATUS_DATETIME >= '2023-08-01' and os.STATUS_DATETIME <= '2023-08-31'
join
order_item_ship_group oisg on oi.ORDER_ID = oisg.ORDER_ID and oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID
join 
order_history ohs on oi.ORDER_ID = ohs.ORDER_ID and oi.ORDER_ITEM_SEQ_ID = ohs.ORDER_ITEM_SEQ_ID and ohs.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID 
join
product p on p.PRODUCT_ID = oi.PRODUCT_ID;


-- 6 Newly Created Sales Orders and Payment Methods
-- Business Problem:
-- Finance teams need to see new orders and their payment methods for reconciliation and fraud checks.
-- 
-- Fields to Retrieve:
-- 
-- ORDER_ID
-- TOTAL_AMOUNT
-- PAYMENT_METHOD
-- Shopify Order ID (if applicable)

select oh.ORDER_ID , oh.GRAND_TOTAL , opp.PAYMENT_METHOD_ID , oh.ORDER_NAME from
order_header oh
join
order_payment_preference opp on oh.ORDER_ID = opp.ORDER_ID;

-- 7 Payment Captured but Not Shipped
-- Business Problem:
-- Finance teams want to ensure revenue is recognized properly. If payment is captured but no shipment has occurred, it warrants further review.
-- 
-- Fields to Retrieve:
-- 
-- ORDER_ID
-- ORDER_STATUS
-- PAYMENT_STATUS
-- SHIPMENT_STATUS

select oh.ORDER_ID , oh.STATUS_ID , opp.STATUS_ID , s.STATUS_ID  from
order_header oh 
join order_payment_preference opp on oh.ORDER_ID = opp.ORDER_ID and opp.STATUS_ID = 'PAYMENT_RECIEVED'
join shipment s on s.PRIMARY_ORDER_ID = oh.ORDER_ID and s.STATUS_ID != 'SHIPMENT_SHIPPED';




