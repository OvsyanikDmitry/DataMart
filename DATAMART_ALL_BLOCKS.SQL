/*1.	Блок соц.-демо: */

SELECT DISTINCT
	cl.client_id,

	/*	Дата рождения;*/
	NVL(TO_CHAR(TO_DATE( cl.birth_dt,'DDMONYYYY:HH24:MI:SS')),'Нет данных') AS bith_dt,

	/*Возраст (целое число лет);*/
    NVL(
        FLOOR(MONTHS_BETWEEN
            (
                TO_DATE('01.12.2021','DD.MM.YYYY','nls_language=American'),
                TO_DATE( cl.birth_dt,'DDMONYYYY:HH24:MI:SS','nls_language=American')
            )
        /12),0)AS age,

	/*•	Код региона;*/
	NVL(cl.region_code,0) AS region_code,

	/*Адрес регистрации; */
	CASE
        WHEN reg.region='Москва'
        THEN
            'Москва'
        WHEN reg.region='Санкт-Петербург'
        THEN
            'Санкт-Петербург'
        ELSE
            (
            reg.region||' '||
            LOWER(reg.region_type)||
            NVL2(reg.district,(', '||reg.district),'')||
            NVL2(reg.district_type,(' '||LOWER(reg.district_type)),'')||', '||
            COALESCE(LOWER(reg.city_type),LOWER(reg.town_type))||' '||
            COALESCE(reg.city,reg.town)
            )
    END AS reg_addr,

	/*Адрес проживания;*/
    CASE
        WHEN fact.region='Москва'
        THEN
            'Москва'
        WHEN fact.region='Санкт-Петербург'
        THEN
            'Санкт-Петербург'
        ELSE
        (
        fact.region||' '||
        LOWER(fact.region_type)||
        NVL2(fact.district,(', '||fact.district),'')||
        NVL2(fact.district_type,(' '||LOWER(fact.district_type)),'')||', '||
        COALESCE(LOWER(fact.city_type),LOWER(fact.town_type))||' '||
        COALESCE(fact.city,fact.town)
        )
    END as fact_addr,
	/*	Пол (наименование);*/
    NVL(gen.gender_nm,'Нет данных') AS gender_nm,

	/*Уровень образования (наименование);*/
    NVL(el.level_nm,'Нет данных') AS education_level_nm,

	/*Семейное положение (наименование); */
    NVL(fs.status_nm,'Нет данных')AS family_status_nm,

	/*	Рабочий стаж (целое кол-во лет); */
    NVL(cl.fullseniority_year_cnt,0) AS fullseniority_year_cnt,

	/*	Доля жизни клиента, которую он работал;*/
    NVL(
        ROUND
			(
			cl.fullseniority_year_cnt/(MONTHS_BETWEEN
			(
			TO_DATE('01.12.2021','DD.MM.YYYY','nls_language=American'),
			TO_DATE( cl.birth_dt,'DDMONYYYY:HH24:MI:SS','nls_language=American')
			)
			/12),2),
        0) AS work_part_of_life_pct,

	/*	Является ли сотрудником Банка;    */
    CASE
        WHEN cl.staff_flg='1' THEN 'Да'
        WHEN cl.staff_flg='0' THEN 'Нет'
        ELSE 'Нет данных'
    END AS staff_flg,

	/*Кол-во лет с последнего изменения имени (если не заполнено, то оставить NULL);  */
    FLOOR(
        MONTHS_BETWEEN
            (
                TO_DATE(cl.name_change_year,'yyyy'),
                TO_DATE( cl.birth_dt,'DDMONYYYY:HH24:MI:SS')
            )/12
    )AS last_nm_change_year_cnt,

--2. Кредитные заявки:
	--Кол-во кредитных заявок по клиенту за всю историю;
	COALESCE(credit1.APP_HIST_CNT,0) AS APP_HIST_CNT,

	--Кол-во кредитных заявок по клиенту за последние 6 месяцев;
	COALESCE(credit2.APP_6M_CNT,0) AS APP_6M_CNT,

	--Кол-во кредитных заявок по клиенту за последние 3 месяца;
	COALESCE(credit3.APP_3M_CNT,0) AS APP_3M_CNT,

	--Сумма по кредитным заявкам по клиенту за всю историю;
	COALESCE(credit4.APP_HIST_AMT,0) AS APP_HIST_AMT,

	--Сумма по кредитным заявкам по клиенту за последние 6 месяцев;
	COALESCE(credit5.APP_6M_AMT,0) AS APP_6M_AMT,

	--Сумма по кредитным заявкам по клиенту за последние 3 месяца;
    COALESCE(credit6.APP_3M_AMT,0) AS APP_3M_AMT,

	--Флаг наличия заявки на ипотеку за последние 6 месяцев;
	credit7.MORTGAGE_6M_FLG,

	--Целое кол-во месяцев с даты подачи последней заявки;
	credit8.LAST_APP_MONTH_CNT,


--3.Данные БКИ:
	--•	Максимальный бакет просрочки на отчетную дату (факт просрочки рассматривается на месяц, предшествующий отчетной дате)
	--Возможные бакеты просрочки:  0,  [1-30), [30-60), [60-90), [90-120), 120+;
	COALESCE(bki1.MAX_CUR_DELQ_BUCKET,'Нет данных') AS MAX_CUR_DELQ_BUCKET,

	--Флаг наличия просрочки [1-30) за последние 3 месяца
	COALESCE(bki1.DELQ_1_30_3M_FLG,'Нет данных') AS DELQ_1_30_3M_FLG,

	--Флаг наличия просрочки [1-30) за последние 6 месяцев
	COALESCE(bki1.DELQ_1_30_6M_FLG,'Нет данных') AS DELQ_1_30_6M_FLG,

	--Флаг наличия просрочки 90+ за последние 12 месяцев
	COALESCE(bki1.DELQ_90_12M_FLG,'Нет данных') AS DELQ_90_12M_FLG,

	--Флаг наличия у клиента договора возрастом менее 6-ти месяцев
	COALESCE(bki1.LAST_AGR_LESS6M_FLG,'Нет данных') AS LAST_AGR_LESS6M_FLG,

	--Количество месяцев с даты открытия первого кредита
	COALESCE(bki2.LAST_OPEN_AGR_MONTH_CNT,0) AS LAST_OPEN_AGR_MONTH_CNT,

	--Количество месяцев с даты открытия последнего кредита
	COALESCE(bki3.FIRST_OPEN_AGR_MONTH_CNT,0) AS FIRST_OPEN_AGR_MONTH_CNT,

	--Количество месяцев до предполагаемого закрытия открытого договора (для договора с самой поздней датой закрытия)
	COALESCE(bki4.MAX_CLOSE_AGR_NOW_MONTH_CNT,0) AS MAX_CLOSE_AGR_NOW_MONTH_CNT,

	--Сумма оставшейся непогашенной задолженности по текущим открытым договорам
	COALESCE(bki5.CURRENT_CREDIT_LIMIT_AMT,0) AS CURRENT_CREDIT_LIMIT_AMT,

	--Сумма кредитного лимита по текущим открытым договорам
	COALESCE(bki6.CURRENT_CURR_BALANCE_AMT,0) AS CURRENT_CURR_BALANCE_AMT,


--4.Карточные транзакции:
	--Общая сумма исходящих транзакций за 30 дней до отчетной даты
	COALESCE(trback30D.TRANS_OUT_30D_AMT, 0)  TRANS_OUT_30D_AMT,

	--Общая сумма исходящих транзакций за 90 дней до отчетной даты
    COALESCE(trback90D.TRANS_OUT_90D_AMT, 0) TRANS_OUT_90D_AMT,

	--Общая сумма исходящих транзакций за 180 дней до отчетной даты
    COALESCE(trback180D.TRANS_OUT_180D_AMT, 0) TRANS_OUT_180D_AMT,

	--Общая сумма исходящих транзакций за 365 дней до отчетной даты
    COALESCE(trback365D.TRANS_OUT_365D_AMT, 0) TRANS_OUT_365D_AMT,

	--Общая сумма входящих транзакций за 30 дней до отчетной даты
    COALESCE(trinc30D.TRANS_IN_30D_AMT, 0) TRANS_IN_30D_AMT,

	--Общая сумма входящих транзакций за 90 дней до отчетной даты
    COALESCE(trinc90D.TRANS_IN_90D_AMT, 0) TRANS_IN_90D_AMT,

	--Общая сумма входящих транзакций за 180 дней до отчетной даты
    COALESCE(trinc180D.TRANS_IN_180D_AMT, 0) TRANS_IN_180D_AMT,

	--Общая сумма входящих транзакций за 365 дней до отчетной даты
    COALESCE(trinc365D.TRANS_IN_365D_AMT, 0) TRANS_IN_365D_AMT,

	--Общая сумма транзакций за 30 дней до отчетной даты
    COALESCE(trall30D.TRANS_ALL_30D_AMT, 0) TRANS_ALL_30D_AMT,

	--Общая сумма транзакций за 90 дней до отчетной даты
    COALESCE(trall90D.TRANS_ALL_90D_AMT, 0) TRANS_ALL_90D_AMT,

	--Общая сумма транзакций за 180 дней до отчетной даты
    COALESCE(trall180D.TRANS_ALL_180D_AMT, 0) TRANS_ALL_180D_AMT,

	--Общая сумма транзакций за 365 дней до отчетной даты
    COALESCE(trall365D.TRANS_ALL_365D_AMT, 0) TRANS_ALL_365D_AMT,

	--Отношение суммы транзакций за последний месяц к среднемесячной сумме транзакций за последние 3 месяца
    round(amount.nov/avg.months3, 2) LAST_MONTH_TO_AVG3M_SUM_PCT,

	--Отношение суммы транзакций за последний месяц к среднемесячной сумме транзакций за последние 6 месяцев
    round(amount.nov/avg6.months6, 2) LAST_MONTH_TO_AVG6M_SUM_PCT,

	--Отношение суммы транзакций за последний месяц к среднемесячной сумме транзакций за последние 12 месяцев
    round(amount.nov/avg12.months12, 2) LAST_MONTH_TO_AVG12M_SUM_PCT,

	--Отношение среднемесячной суммы транзакций за последние 3 месяца к среднемесячной сумме транзакций за последние 6 месяцев
    round(avg.months3/avg6.months6, 2) AVG3M_TO_AVG6M_SUM_PCT,

	--Отношение кол-ва транзакций за последний месяц к среднемесячному кол-ву транзакций за последние 3 месяца
    round(count1.Cmonths1/count3.Cmonths3, 2) LAST_MONTH_TO_AVG3M_CNT_PCT,

	--Отношение кол-ва транзакций за последний месяц к среднемесячному кол-ву транзакций за последние 6 месяцев
    round(count1.Cmonths1/count6.Cmonths6, 2) LAST_MONTH_TO_AVG6M_CNT_PCT,

	--Отношение кол-ва транзакций за последний месяц к среднемесячному кол-ву транзакций за последние 12 месяцев
    round(count1.Cmonths1/count12.Cmonths12, 2) LAST_MONTH_TO_AVG12M_CNT_PCT,

	--Отношение среднемесячного кол-ва транзакций за последние 3 месяца к среднемесячному кол-ву транзакций за последние 6 месяцев
    round(count3.Cmonths3/count6.Cmonths6, 2) AVG3M_TO_AVG6M_CNT_PCT,

	--Сумма транзакций за первый месяц до отчетной даты
	COALESCE(SALARY_2M_AMT,0) AS SALARY_2M_AMT,

	--Сумма транзакций за второй месяц до отчетной даты
    COALESCE(SALARY_1M_AMT,0) AS SALARY_1M_AMT,

	--Сумма транзакций за третий месяц до отчетной даты
    COALESCE(SALARY_3M_AMT,0) AS SALARY_3M_AMT,

	--Сумма транзакций за четвертый месяц до отчетной даты
    COALESCE(SALARY_4M_AMT,0) AS SALARY_4M_AMT,

	--Сумма транзакций за пятый месяц до отчетной даты
    COALESCE(SALARY_5M_AMT,0) AS SALARY_5M_AMT,

	--Сумма транзакций за шестой месяц до отчетной даты
    COALESCE(SALARY_6M_AMT,0) AS SALARY_6M_AMT,

	--Кол-во транзакций за первый месяц до отчетной даты
    COALESCE(SALARY_1M_CNT,0) AS SALARY_1M_CNT,

	--Кол-во транзакций за второй месяц до отчетной даты
    COALESCE(SALARY_2M_CNT,0) AS SALARY_2M_CNT,

	--Кол-во транзакций за третий месяц до отчетной даты
    COALESCE(SALARY_3M_CNT,0) AS SALARY_3M_CNT,

	--Кол-во транзакций за четвертый месяц до отчетной даты
    COALESCE(SALARY_4M_CNT,0) AS SALARY_4M_CNT,

	--Кол-во транзакций за пятый месяц до отчетной даты
    COALESCE(SALARY_5M_CNT,0) AS SALARY_5M_CNT,

	--Кол-во транзакций за шестой месяц до отчетной даты
    COALESCE(SALARY_6M_CNT,0) AS SALARY_6M_CNT,

	--Отношение суммы зарплатных транзакций за последний месяц к сумме за 3 последних месяца
    COALESCE(SALARY_DURING_6M_CNT,0) AS SALARY_DURING_6M_CNT,

	--Отношение суммы зарплатных транзакций за последний месяц к сумме за 6 последних месяцев
    COALESCE(round(SALARY_2M_AMT/SALARY_3M_SUMAMT, 2),0) AS SALARY_1M_TO_3M_AMT_PCT,

	--Отношение кол-ва зарплатных транзакций за последний месяц к кол-ву за 3 последних месяца
    COALESCE(round(SALARY_1M_CNT/СOUNT_3M_CNT, 2),0) AS SALARY_1M_TO_3M_CNT_PCT,

	--Отношение кол-ва зарплатных за последний месяц к кол-ву за 6 последних месяцев
    COALESCE(round(SALARY_2M_AMT/SALARY_6M_SUMAMT, 2),0) AS SALARY_1M_TO_6M_AMT_PCT,

	--Кол-во месяцев, в которые были зарплатные начисления, из последних 6 месяцев
    COALESCE(round(SALARY_1M_CNT/СOUNT_6M_CNT, 2),0) AS SALARY_1M_TO_6M_CNT_PCT,

	--Кол-во месяцев назад, когда была начислена последняя зарплатная транзакция
	COALESCE(LAST_SAL_TRANS_MONTH_CNT,0) AS LAST_SAL_TRANS_MONTH_CNT,

	--Кол-во месяцев назад, когда была начислена первая зарплатная транзакция
	COALESCE(FIRST_SAL_TRANS_MONTH_CNT,0) AS FIRST_SAL_TRANS_MONTH_CNT

FROM de_common.group_dim_client cl

    LEFT JOIN (SELECT*FROM DE_COMMON.group_dim_client_address WHERE addr_type=1) reg
		ON cl.client_id=reg.client_id

	LEFT JOIN (SELECT*FROM DE_COMMON.group_dim_client_address WHERE addr_type=2) fact
		ON cl.client_id=fact.client_id

    LEFT JOIN de_common.group_dict_gender gen
        ON gen.gender_code=cl.gender_code

    LEFT JOIN de_common.group_dict_education_level el
        ON el.level_code=cl.education_level_code

    LEFT JOIN de_common.group_dict_family_status fs
        ON fs.status_code=cl.family_status_code

	LEFT JOIN
		(
		SELECT client_id, COUNT(*) AS APP_HIST_CNT
		FROM de_common.group_fct_credit_applications
		GROUP BY client_id
		) credit1
		ON cl.client_id=credit1.client_id

	LEFT JOIN
		(
		SELECT client_id, COUNT(*) AS APP_6M_CNT
		FROM de_common.group_fct_credit_applications
		WHERE application_date BETWEEN TO_DATE('2021-06-01', 'YYYY-MM-DD')
			AND TO_DATE('2021-11-30 23:59:59', 'YYYY-MM-DD hh24:mi:ss')
		GROUP BY client_id
		) credit2
		ON cl.client_id=credit2.client_id

	LEFT JOIN
		(
		SELECT client_id, COUNT(*) AS APP_3M_CNT
		FROM de_common.group_fct_credit_applications
		WHERE application_date BETWEEN TO_DATE('2021-09-01', 'YYYY-MM-DD')
			AND TO_DATE('2021-11-30 23:59:59', 'YYYY-MM-DD hh24:mi:ss')
		GROUP BY client_id) credit3
		ON cl.client_id=credit3.client_id

	LEFT JOIN
		(
		SELECT client_id, SUM(application_sum_amt) AS APP_HIST_AMT
		FROM de_common.group_fct_credit_applications
		GROUP BY client_id
		) credit4
		ON cl.client_id = credit4.client_id

	LEFT JOIN
		(
		SELECT client_id, SUM(application_sum_amt) AS APP_6M_AMT
		FROM de_common.group_fct_credit_applications
		WHERE application_date BETWEEN TO_DATE('2021-06-01', 'YYYY-MM-DD')
			AND TO_DATE('2021-11-30 23:59:59', 'YYYY-MM-DD hh24:mi:ss')
		GROUP BY client_id
		) credit5
		ON cl.client_id = credit5.client_id

	LEFT JOIN
		(
		SELECT client_id, SUM(application_sum_amt) AS APP_3M_AMT
		FROM de_common.group_fct_credit_applications
		WHERE application_date BETWEEN TO_DATE('2021-09-01', 'YYYY-MM-DD')
			AND TO_DATE('2021-11-30 23:59:59', 'YYYY-MM-DD hh24:mi:ss')
		GROUP BY client_id
		) credit6
		ON cl.client_id = credit6.client_id

	LEFT JOIN
		(
		SELECT client_id,
		CASE
			WHEN credit_product_type = 6 THEN 'YES'
			ELSE 'NO'
		END AS MORTGAGE_6M_FLG
		FROM de_common.group_fct_credit_applications
		) credit7
		ON cl.client_id = credit7.client_id

	LEFT JOIN
		(
		SELECT
			client_id,
			FLOOR
				(
				MONTHS_BETWEEN
					(
					TO_DATE('2021-11-30','YYYY-MM-DD'),
					TO_DATE('2020-06-01','YYYY-MM-DD')
					)
				) AS LAST_APP_MONTH_CNT
		FROM de_common.group_fct_credit_applications
		) credit8
		ON cl.client_id = credit8.client_id

	LEFT JOIN
		(
		SELECT DISTINCT
			bki.client_id CLIENT_ID,
			case
				when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='4' then '[90-120)'
				when regexp_substr( PMT_STRING_84M, '\w', 1, 2)='5' then '120+'
				else 'N'
			end MAX_CUR_DELQ_BUCKET,

			case
				when regexp_substr( PMT_STRING_84M, '\w{1,3}',2) like '%A%' then 'Y'
				when regexp_substr( PMT_STRING_84M, '\w{1,3}',2) like '%E%' then 'Y'
				when regexp_substr( PMT_STRING_84M, '\w{1,3}',2) like '%F%' then 'Y'
				else 'N'
			end DELQ_1_30_3M_FLG,

			case
				when regexp_substr( PMT_STRING_84M, '\w{1,6}',2) like '%A%' then 'Y'
				when regexp_substr( PMT_STRING_84M, '\w{1,6}',2) like '%E%' then 'Y'
				when regexp_substr( PMT_STRING_84M, '\w{1,6}',2) like '%F%' then 'Y'
				else 'N'
			end DELQ_1_30_6M_FLG,

			case
				when regexp_substr( PMT_STRING_84M, '\w{1,12}',2) like '%4%' then 'Y'
				when regexp_substr( PMT_STRING_84M, '\w{1,12}',2) like '%5%' then 'Y'
				else 'N'
			end DELQ_90_12M_FLG,

			case
				when round(months_between(cast('2021-12-01'as date),
					to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY')))>6 then 'N'
				else 'Y'
			end LAST_AGR_LESS6M_FLG

		FROM de_common.group_rep_bki_info bki
		WHERE  bki.FACT_CLOSE_DT IS NULL
		ORDER BY MAX_CUR_DELQ_BUCKET DESC
		) bki1
		ON 	cl.client_id=bki1.client_id

	LEFT JOIN
		(
		select distinct
			client_id,
			min(month_cnt) as LAST_OPEN_AGR_MONTH_CNT
		from
			(
			select
			bki.client_id,
			bki.report_dt,
			to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY') as OPEN_DT,
			round(months_between(cast('2021-12-01'as date),
			to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY'))) as  MONTH_CNT
			from de_common.group_rep_bki_info bki
			where bki.fact_close_dt is null
			)
		group by client_id
		) bki2
		ON cl.client_id=bki2.client_id

	LEFT JOIN
		(
		select distinct
			client_id,
			max(month_cnt) as FIRST_OPEN_AGR_MONTH_CNT
		from
			(
			select
			bki.client_id,
			bki.report_dt,
			to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY') as OPEN_DT,
			round(months_between(cast('2021-12-01'as date),
			to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY'))) as  MONTH_CNT
			from de_common.group_rep_bki_info bki
			where bki.fact_close_dt is null
			)
		group by client_id
		) bki3
		ON cl.client_id=bki3.client_id

	LEFT JOIN
		(
		select
			client_id,
			max(MONTHS_CNT) as MAX_CLOSE_AGR_NOW_MONTH_CNT
		from
			(
			select
			bki.client_id,
			bki.report_dt,
			to_date(substr(bki.PLAN_CLOSE_DT,1,9),'DD-MM-YY') PLAN_CLOSE_DT,
			to_date(substr(bki.OPEN_DT,1,9),'DDMONYYYY') as OPEN_DT,
			round(months_between(cast(to_date(substr(bki.PLAN_CLOSE_DT,1,9),'DD-MM-YY')as date), cast('2021-12-01'as date))) as MONTHS_CNT
			from de_common.group_rep_bki_info bki
			where bki.fact_close_dt is null
			)
		group by client_id
		) bki4
		ON cl.client_id=bki4.client_id

	LEFT JOIN
		(
		select
			CLIENT_ID,
			CURRENT_CREDIT_LIMIT_AMT
		from
			(
			select
			bki.client_id,
			sum(CREDIT_LIMIT_AMT) as CURRENT_CREDIT_LIMIT_AMT
			from de_common.group_rep_bki_info bki
			where bki.FACT_CLOSE_DT is null
			group by bki.client_id)
		) bki5
		ON cl.client_id=bki5.client_id

	LEFT JOIN
		(
		select
			CLIENT_ID,
			CURRENT_CURR_BALANCE_AMT
		from
			(
			select
				bki.client_id,
				sum(curr_balance_amt) as CURRENT_CURR_BALANCE_AMT
			from de_common.group_rep_bki_info bki
			where bki.FACT_CLOSE_DT is null
			group by bki.client_id
			)
		) bki6
		ON cl.client_id=bki6.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_OUT_30D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-30
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
			AND IN_OUT_TYPE='OUT'
		GROUP BY CLIENT_ID
		) trback30D
		ON cl.client_id=trback30D.client_id

	LEFT JOIN
		(
        SELECT
           CLIENT_ID,
           SUM(TRANS_AMT) as TRANS_OUT_90D_AMT
        FROM de_common.group_fct_transactions
        WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-90
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
			AND IN_OUT_TYPE='OUT'
        GROUP BY CLIENT_ID
        ) trback90D
		ON cl.client_id=trback90D.client_id

	LEFT JOIN
		(
		 SELECT
			 CLIENT_ID,
			 SUM(TRANS_AMT) as TRANS_OUT_180D_AMT
		 FROM de_common.group_fct_transactions
		 WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-180
			 AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			 AND OPER_RESULT='SUCCESS'
			 AND IN_OUT_TYPE='OUT'
		 GROUP BY CLIENT_ID
		 ) trback180D
		ON cl.client_id=trback180D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_OUT_365D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-365
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS' AND IN_OUT_TYPE='OUT'
		GROUP BY CLIENT_ID
		) trback365D
		ON cl.client_id=trback365D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_IN_30D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-30
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS' AND IN_OUT_TYPE='IN'
		GROUP BY CLIENT_ID
		) trinc30D
		ON cl.client_id=trinc30D.client_id

	LEFT JOIN
		(
		SELECT
		   CLIENT_ID,
		   SUM(TRANS_AMT) as TRANS_IN_90D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-90
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
			AND IN_OUT_TYPE='IN'
		GROUP BY CLIENT_ID
		) trinc90D
		ON cl.client_id=trinc90D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_IN_180D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-180
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
			AND IN_OUT_TYPE='IN'
		GROUP BY CLIENT_ID
		) trinc180D
		ON cl.client_id=trinc180D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_IN_365D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-365
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
			AND IN_OUT_TYPE='IN'
		GROUP BY CLIENT_ID
		) trinc365D
		ON cl.client_id=trinc365D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_ALL_30D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-30
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
		GROUP BY CLIENT_ID
		) trall30D
		ON cl.client_id=trall30D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_ALL_90D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-90
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
		GROUP BY CLIENT_ID
		) trall90D
		ON cl.client_id=trall90D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_ALL_180D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-180
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
		GROUP BY CLIENT_ID
		) trall180D
		ON cl.client_id=trall180D.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT) as TRANS_ALL_365D_AMT
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= TO_DATE ('2021.12.01')-365
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
		GROUP BY CLIENT_ID
		) trall365D
		ON cl.client_id=trall365D.client_id

	LEFT JOIN
		(
		 SELECT
			 CLIENT_ID,
			 SUM(TRANS_AMT) nov
		 FROM de_common.group_fct_transactions
		 WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -1)
			 AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			 AND OPER_RESULT='SUCCESS'
		 GROUP BY CLIENT_ID
		 ) amount
		ON cl.client_id=amount.client_id

	LEFT JOIN
		(
		  SELECT
			  CLIENT_ID,
			  SUM(TRANS_AMT)/COUNT(DISTINCT(extract(MONTH FROM TRANSACTION_DT))) months3
		  FROM de_common.group_fct_transactions
		  WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -3)
		  AND TRANSACTION_DT < TO_DATE ('2021.12.01')
		  AND OPER_RESULT='SUCCESS'
		  GROUP BY CLIENT_ID
		  ) avg
		ON cl.client_id=avg.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT)/COUNT(DISTINCT(extract(MONTH FROM TRANSACTION_DT))) months6
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -6)
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
		GROUP BY CLIENT_ID
		) avg6
		ON cl.client_id=avg6.client_id

	LEFT JOIN
		(
		SELECT
			CLIENT_ID,
			SUM(TRANS_AMT)/COUNT(DISTINCT(extract(MONTH FROM TRANSACTION_DT))) months12
		FROM de_common.group_fct_transactions
		WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -12)
			AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			AND OPER_RESULT='SUCCESS'
		GROUP BY CLIENT_ID
		) avg12
		ON cl.client_id=avg12.client_id

	LEFT JOIN
		(
		 SELECT
			 CLIENT_ID,
			 COUNT(TRANSACTION_ID) Cmonths1
		 FROM de_common.group_fct_transactions
		 WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -1)
			 AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			 AND OPER_RESULT='SUCCESS' GROUP BY CLIENT_ID
		 ) count1
		ON cl.client_id=count1.client_id

	LEFT JOIN
		(
		  SELECT
			  tr2.CLIENT_ID,
			  COUNT(tr2.TRANSACTION_ID)/COUNT(DISTINCT(extract(MONTH FROM TRANSACTION_DT))) Cmonths3
		  FROM de_common.group_fct_transactions tr2
		  WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -3)
			  AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			  AND OPER_RESULT='SUCCESS'
		  GROUP BY tr2.CLIENT_ID
		  ) count3
		ON cl.client_id=count3.client_id

	LEFT JOIN
		(
		   SELECT
			   tr2.CLIENT_ID,
			   COUNT(tr2.TRANSACTION_ID)/COUNT(DISTINCT(extract(MONTH FROM TRANSACTION_DT))) Cmonths6
		   FROM de_common.group_fct_transactions tr2
		   WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -6)
			   AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			   AND OPER_RESULT='SUCCESS'
		   GROUP BY tr2.CLIENT_ID
		) count6
		ON cl.client_id=count6.client_id

	LEFT JOIN
		(
		   SELECT
			   tr2.CLIENT_ID,
			   COUNT(tr2.TRANSACTION_ID)/COUNT(DISTINCT(extract(MONTH FROM TRANSACTION_DT))) Cmonths12
		   FROM de_common.group_fct_transactions tr2
		   WHERE TRANSACTION_DT >= ADD_MONTHS('2021.12.01', -12)
			   AND TRANSACTION_DT < TO_DATE ('2021.12.01')
			   AND OPER_RESULT='SUCCESS'
		   GROUP BY tr2.CLIENT_ID
		) count12
		ON cl.client_id=count12.client_id

	LEFT JOIN
		(
		select
			client_id,
			sum(income_sum_amt) as SALARY_2M_AMT,
			COUNT(income_month) as SALARY_1M_CNT
		from DE_COMMON.group_fct_income_transactions
		where income_type = 1 and income_month = '2021-11'
		group by client_id
		) SALARY1M
		ON cl.client_id=SALARY1M.client_id

	LEFT JOIN
		(
		select client_id,
			sum(income_sum_amt) as SALARY_1M_AMT,
			COUNT(income_month) as SALARY_2M_CNT
		from DE_COMMON.group_fct_income_transactions a
		where income_type = 1 and income_month = '2021-10'
		group by client_id
		) SALARY2M
		ON cl.client_id=SALARY2M.client_id

	LEFT JOIN
		(
		select client_id,
			sum(income_sum_amt) as SALARY_3M_AMT,
			COUNT(income_month) as SALARY_3M_CNT
		from DE_COMMON.group_fct_income_transactions a
		where income_type = 1 and income_month = '2021-09'
		group by client_id
		)SALARY3M
		ON cl.client_id=SALARY3M.client_id

	LEFT JOIN
		(
		select client_id,
			sum(income_sum_amt) as SALARY_4M_AMT,
			COUNT(income_month) as SALARY_4M_CNT
		from DE_COMMON.group_fct_income_transactions a
		where income_type = 1 and income_month = '2021-08'
		group by client_id
		)SALARY4M
		ON cl.client_id=SALARY4M.client_id

	LEFT JOIN
		(
		select client_id,
			sum(income_sum_amt) as SALARY_5M_AMT,
			COUNT(income_month) as SALARY_5M_CNT
		from DE_COMMON.group_fct_income_transactions a where income_type = 1 and income_month = '2021-07'
		group by client_id
		) SALARY5M
		ON cl.client_id=SALARY5M.client_id

	LEFT JOIN
		(
		select client_id,
			sum(income_sum_amt) as SALARY_6M_AMT,
			COUNT(income_month) as SALARY_6M_CNT
		from DE_COMMON.group_fct_income_transactions a where income_type = 1 and income_month = '2021-06'
		group by client_id
		) SALARY6M
		ON cl.client_id=SALARY6M.client_id

	LEFT JOIN
		(
		select client_id,
		sum(income_sum_amt) as SALARY_3M_SUMAMT,
		COUNT(income_month) as СOUNT_3M_CNT
		from DE_COMMON.group_fct_income_transactions where income_type = 1 and
		income_month in('2021-11', '2021-10', '2021-09') group by client_id
		) total3M
		ON cl.client_id=total3M.client_id

	LEFT JOIN
		(
		select client_id,
			sum(income_sum_amt) as SALARY_6M_SUMAMT,
			COUNT(income_month) as СOUNT_6M_CNT
		from DE_COMMON.group_fct_income_transactions where income_type = 1 and
		income_month in('2021-11', '2021-10', '2021-09', '2021-08', '2021-07', '2021-06')
		group by client_id
		) total6M
		ON cl.client_id=total6M.client_id

	LEFT JOIN
		(
		select client_id,
			months_between
				(
				to_date(RPAD('2021-12', 10, '-01')),
				to_date(RPAD('2021-06', 10, '-01'))
				) as SALARY_DURING_6M_CNT
			from DE_COMMON.group_fct_income_transactions where income_type = 1
		and income_sum_amt > 0
		group by client_id
		order by client_id
		) totalMN
		ON cl.client_id=totalMN.client_id

	LEFT JOIN
		(
		select
			client_id,
			months_between
				(
				to_date('2021-12-01','yyyy-mm-dd'),
				max(to_date(income_month,'yyyy-mm'))
				) as LAST_SAL_TRANS_MONTH_CNT,
			months_between
				(
				to_date('2021-12-01','yyyy-mm-dd'),
				min(to_date(income_month,'yyyy-mm'))
				) as FIRST_SAL_TRANS_MONTH_CNT
		from DE_COMMON.group_fct_income_transactions
		where income_type = 1
		group by client_id
		) LFSALARY
		ON cl.client_id=LFSALARY.client_id

ORDER BY cl.client_id;
