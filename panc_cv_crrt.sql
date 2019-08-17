DROP MATERIALIZED VIEW IF EXISTS panc_cv_crrt CASCADE;
CREATE MATERIALIZED VIEW panc_cv_crrt AS

WITH panc_patient as  -- 找出急性胰腺炎的病人，以及诊断的顺序，一共497位
(
SELECT hadm_id, seq_num FROM diagnoses_icd
WHERE icd9_code = '5770'
GROUP BY hadm_id, seq_num
)
, panc_info as  --患者入住icu的信息
(
SELECT i.hadm_id, i.icustay_id, intime FROM icustays i
INNER JOIN panc_patient p
		ON i.hadm_id = p.hadm_id
		GROUP BY i.hadm_id, i.icustay_id, intime 
)
, panc_cv as  --患者行crrt的信息
(
SELECT r.hadm_id, r.icustay_id, r.itemid, charttime, value, valueuom, p.intime FROM chartevents r
INNER JOIN panc_info p
		ON r.icustay_id = p.icustay_id
WHERE itemid IN (152,149)
GROUP BY r.hadm_id, r.icustay_id, r.itemid, charttime, value, valueuom, p.intime
)
, panc_cv1 as  --整理行crrt患者的信息
(
SELECT hadm_id, icustay_id, min(charttime) as min_charttime, intime FROM panc_cv
WHERE icustay_id not in (246435, 281464)
GROUP BY hadm_id, icustay_id, intime
ORDER BY hadm_id
)
,panc_cv2 as --计算患者第一次开始CRRT的时间
(
SELECT hadm_id, icustay_id, min_charttime as min_starttime
,EXTRACT(epoch  FROM (min_charttime - intime)/60/60/24 ) as final_time
FROM panc_cv1
GROUP BY hadm_id, icustay_id, min_charttime, intime
)
-- 分组
SELECT hadm_id, icustay_id, final_time, min_starttime
					, case when final_time <= 2 then 1 else 0 end as early_crrt
					, case when final_time >= 0 then 1 else 0 end as group_cv
FROM panc_cv2
WHERE final_time <= 14
GROUP BY hadm_id, icustay_id, final_time, min_starttime
