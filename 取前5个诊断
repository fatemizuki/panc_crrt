DROP MATERIALIZED VIEW IF EXISTS panc_4 CASCADE;
CREATE MATERIALIZED VIEW panc_4 AS

WITH a as
(
SELECT p.*,seq_num,icd9_code,subject_id FROM panc_3 p
INNER JOIN diagnoses_icd d
		ON d.hadm_id = p.hadm_id
WHERE icd9_code = '5770'
)
SELECT * FROM a
WHERE seq_num in ('1','2','3','4','5')
