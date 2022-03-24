select
bki.CLIENT_ID,
COALESCE(max(MAX_CUR_DELQ_BUCKET),'Нет данных') as MAX_CUR_DELQ_BUCKET,
COALESCE(max(DELQ_1_30_3M_FLG),'Нет данных') as DELQ_1_30_3M_FLG,
COALESCE(max(DELQ_1_30_6M_FLG),'Нет данных') as DELQ_1_30_6M_FLG,
COALESCE(max(DELQ_90_12M_FLG),'Нет данных') as DELQ_90_12M_FLG,
NVL(TO_CHAR(LAST_AGR_LESS6M_FLG),'Нет данных') as LAST_AGR_LESS6M_FLG,
NVL(TO_CHAR(LAST_OPEN_AGR_MONTH_CNT),'Нет данных') as LAST_OPEN_AGR_MONTH_CNT,
NVL(TO_CHAR(FIRST_OPEN_AGR_MONTH_CNT),'Нет данных') as FIRST_OPEN_AGR_MONTH_CNT,
NVL(TO_CHAR(MAX_CLOSE_AGR_NOW_MONTH_CNT),'Нет данных') as MAX_CLOSE_AGR_NOW_MONTH_CNT,
NVL(TO_CHAR(CURRENT_CURR_BALANCE_AMT),'Нет данных') as CURRENT_CURR_BALANCE_AMT,
NVL(TO_CHAR(CURRENT_CREDIT_LIMIT_AMT),'Нет данных') as CURRENT_CREDIT_LIMIT_AMT
from de_common.group_rep_bki_info bki
left join(
select
bki.client_id CLIENT_ID,
case
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='5' then '120+'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='4' then '[90-120)'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='3' then '[60-90)'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='2' then '[30-60)'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='1' then '0'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='0' then 'Новый'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='9' then 'Взыскание'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='E' then '[1-30)'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='F' then '[1-30)'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='A' then '[1-30)'
when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='X' then 'Нет данных'
else 'Нет данных'
end MAX_CUR_DELQ_BUCKET,
case when regexp_substr( PMT_STRING_84M, '\w{1,3}',2) like '%A%' then 'Y'
when regexp_substr( PMT_STRING_84M, '\w{1,3}',2) like '%E%' then 'Y'
when regexp_substr( PMT_STRING_84M, '\w{1,3}',2) like '%F%' then 'Y'
else 'N'
end DELQ_1_30_3M_FLG,
case when regexp_substr( PMT_STRING_84M, '\w{1,6}',2) like '%A%' then 'Y'
when regexp_substr( PMT_STRING_84M, '\w{1,6}',2) like '%E%' then 'Y'
when regexp_substr( PMT_STRING_84M, '\w{1,6}',2) like '%F%' then 'Y'
else 'N'
end DELQ_1_30_6M_FLG,
case when regexp_substr( PMT_STRING_84M, '\w{1,12}',2) like '%4%' then 'Y'
when regexp_substr( PMT_STRING_84M, '\w{1,12}',2) like '%5%' then 'Y'
else 'N'
end DELQ_90_12M_FLG,
case when round(months_between(cast('2021-12-01'as date),
to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY')))>6 then 'N'
else 'Y'
end LAST_AGR_LESS6M_FLG

from de_common.group_rep_bki_info bki
where  bki.FACT_CLOSE_DT is NULL
and bki.CURR_BALANCE_AMT!=0
) MAX_CUR_DELQ_BUCKET
on bki.client_id=MAX_CUR_DELQ_BUCKET.client_id

left join
(
select
client_id,
max(month_cnt) as FIRST_OPEN_AGR_MONTH_CNT,
min(month_cnt) as LAST_OPEN_AGR_MONTH_CNT,
max(MONTHS_CNT2) as MAX_CLOSE_AGR_NOW_MONTH_CNT,
sum(CURR_BALANCE_AMT) as CURRENT_CURR_BALANCE_AMT,
sum(CREDIT_LIMIT_AMT) as CURRENT_CREDIT_LIMIT_AMT
from
(
select
bki.client_id,
bki.report_dt,
CREDIT_LIMIT_AMT,
CURR_BALANCE_AMT,
to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY') as OPEN_DT,
to_date(substr(bki.PLAN_CLOSE_DT,1,9),'DD-MM-YY') PLAN_CLOSE_DT,
round(months_between(cast('2021-12-01'as date),
to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY'))) as  MONTH_CNT,
round(months_between(cast(to_date(substr(bki.PLAN_CLOSE_DT,1,9),'DD-MM-YY')as date),
cast('2021-12-01'as date))) as MONTHS_CNT2
from de_common.group_rep_bki_info bki
where bki.fact_close_dt is null)
group by client_id
) F_L_MC_OPEN_AGR_MONTH_CNT
on bki.client_id=F_L_MC_OPEN_AGR_MONTH_CNT.client_id

where bki.fact_close_dt is null
group by bki.CLIENT_ID, LAST_AGR_LESS6M_FLG, LAST_OPEN_AGR_MONTH_CNT,
FIRST_OPEN_AGR_MONTH_CNT, MAX_CLOSE_AGR_NOW_MONTH_CNT,
CURRENT_CURR_BALANCE_AMT, CURRENT_CREDIT_LIMIT_AMT
order by 1
;
