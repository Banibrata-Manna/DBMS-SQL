-- Non Return Refunds
-- 
-- Get a list of all refund payments made on orders due to cancelations. No return refunds should be included.
-- 
-- The expected fields in the result are:
-- 
-- Order Id
-- Payment internal Id
-- Payment manual reference
-- Payment parent reference
-- Refund amount from payment pref

SELECT opp.ORDER_ID, opp.ORDER_PAYMENT_PREFERENCE_ID,
opp.MANUAL_REF_NUM, opp.MAX_AMOUNT FROM 
order_payment_preference opp 
left join return_item_response rir on opp.ORDER_PAYMENT_PREFERENCE_ID = rir.ORDER_PAYMENT_PREFERENCE_ID
where rir.RETURN_ITEM_RESPONSE_ID is null and opp.STATUS_ID = 'PAYMENT_REFUNDED';

-- Kit Product Iventory Updates in returns

SELECT rh.RETURN_ID, ri.RETURN_ITEM_SEQ_ID, s.SHIPMENT_ID, ri.PRODUCT_ID, iid.AVAILABLE_TO_PROMISE_DIFF, iid.QUANTITY_ON_HAND_DIFF FROM return_header rh
JOIN return_item ri ON rh.RETURN_ID = ri.RETURN_ID
AND rh.RETURN_HEADER_TYPE_ID = 'CUSTOMER_RETURN' AND rh.STATUS_ID = 'RETURN_COMPLETED'
JOIN product p ON ri.PRODUCT_ID = p.PRODUCT_ID AND p.PRODUCT_TYPE_ID = 'MARKETING_PKG_PICK' 
JOIN return_item_shipment ris ON ris.RETURN_ID = ri.RETURN_ID AND ris.RETURN_ITEM_SEQ_ID = ri.RETURN_ITEM_SEQ_ID
JOIN shipment s ON s.SHIPMENT_ID = ris.SHIPMENT_ID
JOIN product_facility pf ON pf.PRODUCT_ID = ri.PRODUCT_ID AND s.DESTINATION_FACILITY_ID = pf.FACILITY_ID
JOIN inventory_item_detail iid ON iid.INVENTORY_ITEM_ID = pf.INVENTORY_ITEM_ID AND iid.RETURN_ID = ri.RETURN_ID
ORDER BY rh.ENTRY_DATE DESC;

-- Net transfer Orders between two facilities

WITH TRAN_SHIP AS (
  SELECT s.ORIGIN_FACILITY_ID AS ofac, s.DESTINATION_FACILITY_ID AS dfac, si.PRODUCT_ID AS p_id, si.QUANTITY AS quantity FROM shipment s
  JOIN shipment_item si ON si.SHIPMENT_ID = s.SHIPMENT_ID 
  AND s.SHIPMENT_TYPE_ID = 'OUT_TRANSFER' AND s.STATUS_ID = 'SHIPMENT_SHIPPED'
)
SELECT ts1.ofac, ts1.dfac, p.INTERNAL_NAME, SUM(ts1.quantity - ts2.quantity) AS Net_Quantity FROM TRAN_SHIP ts1 JOIN TRAN_SHIP ts2 ON ts1.ofac = ts2.dfac AND ts1.dfac = ts2.ofac AND ts1.p_id = ts2.p_id
JOIN product p ON p.PRODUCT_ID = ts1.p_id
GROUP BY ts1.p_id, ts1.ofac, ts2.ofac, ts1.dfac, ts2.dfac;
