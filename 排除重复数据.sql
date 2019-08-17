DROP MATERIALIZED VIEW IF EXISTS panc_3 CASCADE;
CREATE MATERIALIZED VIEW panc_3 AS 
with a as  --排除重复数据，选出第一次入icu的数据
(
SELECT *
,case when hadm_id > 0 then 1 end as countf 
FROM panc_2
ORDER BY hadm_id,intime, min_starttime
)
,b as
(
SELECT a.* 
  ,SUM (countf) OVER (partition by hadm_id ORDER BY hadm_id, intime, min_starttime) as countff
	FROM a
	)
	SELECT * FROM b
	where countff = 1
