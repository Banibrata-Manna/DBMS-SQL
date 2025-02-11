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



