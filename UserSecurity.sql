select * from
user_login_security_group ulsg 
join
security_group_permission sgp
on ulsg.GROUP_ID = sgp.GROUP_ID 
and ulsg.USER_LOGIN_ID = ''
and sgp.PERMISSION_ID = ''
and ulsg.THRU_DATE is null;

select ulsg.USER_LOGIN_ID , sgp.PERMISSION_ID  from
user_login_security_group ulsg 
join
security_group_permission sgp
on ulsg.GROUP_ID = sgp.GROUP_ID 
and ulsg.USER_LOGIN_ID = 'bigal'
and ulsg.THRU_DATE is null;

select sgp.GROUP_ID , sgp.PERMISSION_ID , sp.DESCRIPTION  from
security_group_permission sgp 
join
security_permission sp
on sgp.PERMISSION_ID = sp.PERMISSION_ID 
and sgp.THRU_DATE is null
and sgp.GROUP_ID = 'ACCTG_FUNCTNL_ADMIN';


--SELECT * FROM good_identification;