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




