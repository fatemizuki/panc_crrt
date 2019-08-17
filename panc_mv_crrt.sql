DROP MATERIALIZED VIEW IF EXISTS panc_mv_crrt CASCADE;
CREATE MATERIALIZED VIEW panc_mv_crrt AS

WITH panc_patient as  -- 找出急性胰腺炎的病人，以及诊断的顺序，一共497位
(
SELECT hadm_id, seq_num FROM diagnoses_icd
WHERE icd9_code = '5770'
GROUP BY hadm_Id, seq_num
)
, panc_info as  --患者入住icu的信息
(
SELECT i.hadm_id, i.icustay_id, intime FROM icustays i
INNER JOIN panc_patient p
		ON i.hadm_id = p.hadm_id
		GROUP BY i.hadm_id, i.icustay_id, intime
)
, panc_crrt_mv as  --取出使用mv监测的病人的crrt数据
(
SELECT r.hadm_id, r.icustay_id, r.itemid, starttime, endtime, value, valueuom, p.intime FROM procedureevents_mv r
INNER JOIN panc_info p
		ON r.icustay_id = p.icustay_id
WHERE itemid IN (225802, 225803, 225809)
GROUP BY r.hadm_id, r.icustay_id, r.itemid, starttime, endtime, value, valueuom, p.intime
)
, panc_mv as -- 整理mv患者crrt数据
(
SELECT hadm_id, icustay_id, min(starttime) as min_starttime, intime FROM panc_crrt_mv
GROUP BY hadm_id, icustay_id, intime
ORDER BY hadm_id
)
, panc_mv1 as -- 计算开始CRRT时间
(
SELECT hadm_id, icustay_id,min_starttime
,EXTRACT(epoch  FROM (min_starttime - intime)/60/60/24 ) as final_time
FROM panc_mv
GROUP BY hadm_id, icustay_id, min_starttime, intime
)
-- 分组
SELECT hadm_id, icustay_id, final_time, min_starttime
					, case when final_time <= 2 then 1 else 0 end as early_crrt
					, case when final_time >= 0 then 2 else 0 end as group_cv
FROM panc_mv1
WHERE final_time <= 14
GROUP by hadm_id, icustay_id, final_time, min_starttime
