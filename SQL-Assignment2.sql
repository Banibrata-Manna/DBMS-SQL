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
        avg(sum(oi.QUANTITY)) over () as AVG_QUANTITY_SOLD
    from order_header oh
    join order_contact_mech ocm 
        on oh.ORDER_ID = ocm.ORDER_ID 
        and ocm.CONTACT_MECH_PURPOSE_TYPE_ID = 'SHIPPING_LOCATION'
    join postal_address pa 
        on ocm.CONTACT_MECH_ID = pa.CONTACT_MECH_ID 
        and pa.CITY = 'New York' 
        and pa.STATE_PROVINCE_GEO_ID = 'NY'
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



