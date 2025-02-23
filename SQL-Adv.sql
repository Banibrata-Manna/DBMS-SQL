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