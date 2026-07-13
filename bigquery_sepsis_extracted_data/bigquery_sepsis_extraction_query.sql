WITH sepsis_hadm AS (
  SELECT DISTINCT HADM_ID
  FROM physionet-data.mimiciii_clinical.diagnoses_icd
  WHERE ICD9_CODE IN (
    '0380','0381','03810','03811','03812','03819',
    '0382','0383','03840','03841','03842','03843','03844','03849',
    '0388','0389',
    '78552',   -- septic shock
    '99591',   -- sepsis
    '99592'    -- severe sepsis
  )
),

adult_sepsis_icu AS (
  SELECT
    icu.SUBJECT_ID,
    icu.HADM_ID,
    icu.ICUSTAY_ID,
    icu.INTIME,
    icu.OUTTIME,
    adm.ADMITTIME,
    adm.DISCHTIME,
    adm.DEATHTIME,
    adm.ADMISSION_TYPE,
    adm.ETHNICITY,
    adm.HOSPITAL_EXPIRE_FLAG,
    pat.GENDER,
    pat.DOB,
    CASE
      WHEN DATETIME_DIFF(adm.ADMITTIME, pat.DOB, YEAR) >= 300 THEN 90
      ELSE DATETIME_DIFF(adm.ADMITTIME, pat.DOB, YEAR)
    END AS AGE,
    ROW_NUMBER() OVER (
      PARTITION BY icu.HADM_ID
      ORDER BY icu.INTIME
    ) AS ICU_RANK
  FROM physionet-data.mimiciii_clinical.icustays icu
  INNER JOIN physionet-data.mimiciii_clinical.admissions adm
    ON icu.HADM_ID = adm.HADM_ID
  INNER JOIN physionet-data.mimiciii_clinical.patients pat
    ON icu.SUBJECT_ID = pat.SUBJECT_ID
  INNER JOIN sepsis_hadm s
    ON icu.HADM_ID = s.HADM_ID
),

cohort AS (
  SELECT
    SUBJECT_ID,
    HADM_ID,
    ICUSTAY_ID,
    INTIME,
    OUTTIME,
    ADMITTIME,
    DISCHTIME,
    DEATHTIME,
    ADMISSION_TYPE,
    ETHNICITY,
    HOSPITAL_EXPIRE_FLAG AS TARGET_MORTALITY,
    GENDER,
    AGE
  FROM adult_sepsis_icu
  WHERE ICU_RANK = 1
    AND AGE >= 18
),

vitals_long AS (
  SELECT
    c.SUBJECT_ID,
    c.HADM_ID,
    c.ICUSTAY_ID,
    CASE
      WHEN ce.ITEMID IN (211, 220045) THEN 'heartrate'
      WHEN ce.ITEMID IN (51, 442, 455, 6701, 220179, 220050) THEN 'sysbp'
      WHEN ce.ITEMID IN (8368, 8440, 8441, 8555, 220180, 220051) THEN 'diasbp'
      WHEN ce.ITEMID IN (456, 52, 6702, 443, 220052, 220181, 225312) THEN 'meanbp'
      WHEN ce.ITEMID IN (615, 618, 220210, 224690) THEN 'resprate'
      WHEN ce.ITEMID IN (223761, 678, 223762, 676) THEN 'temperature'
      WHEN ce.ITEMID IN (646, 220277) THEN 'spo2'
      ELSE NULL
    END AS FEATURE_NAME,
    CASE
      WHEN ce.ITEMID IN (223761, 678) THEN (ce.VALUENUM - 32) / 1.8
      ELSE ce.VALUENUM
    END AS FEATURE_VALUE
  FROM cohort c
  INNER JOIN physionet-data.mimiciii_clinical.chartevents ce
    ON c.ICUSTAY_ID = ce.ICUSTAY_ID
  WHERE ce.CHARTTIME >= c.INTIME
    AND ce.CHARTTIME <= DATETIME_ADD(c.INTIME, INTERVAL 24 HOUR)
    AND ce.VALUENUM IS NOT NULL
    AND (ce.ERROR IS NULL OR ce.ERROR = 0)
    AND ce.ITEMID IN (
      211, 220045,
      51, 442, 455, 6701, 220179, 220050,
      8368, 8440, 8441, 8555, 220180, 220051,
      456, 52, 6702, 443, 220052, 220181, 225312,
      615, 618, 220210, 224690,
      223761, 678, 223762, 676,
      646, 220277
    )
),

vitals_24h AS (
  SELECT
    SUBJECT_ID,
    HADM_ID,
    ICUSTAY_ID,

    MIN(IF(FEATURE_NAME = 'heartrate', FEATURE_VALUE, NULL)) AS heartrate_min,
    MAX(IF(FEATURE_NAME = 'heartrate', FEATURE_VALUE, NULL)) AS heartrate_max,
    AVG(IF(FEATURE_NAME = 'heartrate', FEATURE_VALUE, NULL)) AS heartrate_mean,

    MIN(IF(FEATURE_NAME = 'sysbp', FEATURE_VALUE, NULL)) AS sysbp_min,
    MAX(IF(FEATURE_NAME = 'sysbp', FEATURE_VALUE, NULL)) AS sysbp_max,
    AVG(IF(FEATURE_NAME = 'sysbp', FEATURE_VALUE, NULL)) AS sysbp_mean,

    MIN(IF(FEATURE_NAME = 'diasbp', FEATURE_VALUE, NULL)) AS diasbp_min,
    MAX(IF(FEATURE_NAME = 'diasbp', FEATURE_VALUE, NULL)) AS diasbp_max,
    AVG(IF(FEATURE_NAME = 'diasbp', FEATURE_VALUE, NULL)) AS diasbp_mean,

    MIN(IF(FEATURE_NAME = 'meanbp', FEATURE_VALUE, NULL)) AS meanbp_min,
    MAX(IF(FEATURE_NAME = 'meanbp', FEATURE_VALUE, NULL)) AS meanbp_max,
    AVG(IF(FEATURE_NAME = 'meanbp', FEATURE_VALUE, NULL)) AS meanbp_mean,

    MIN(IF(FEATURE_NAME = 'resprate', FEATURE_VALUE, NULL)) AS resprate_min,
    MAX(IF(FEATURE_NAME = 'resprate', FEATURE_VALUE, NULL)) AS resprate_max,
    AVG(IF(FEATURE_NAME = 'resprate', FEATURE_VALUE, NULL)) AS resprate_mean,

    MIN(IF(FEATURE_NAME = 'temperature', FEATURE_VALUE, NULL)) AS temperature_min,
    MAX(IF(FEATURE_NAME = 'temperature', FEATURE_VALUE, NULL)) AS temperature_max,
    AVG(IF(FEATURE_NAME = 'temperature', FEATURE_VALUE, NULL)) AS temperature_mean,

    MIN(IF(FEATURE_NAME = 'spo2', FEATURE_VALUE, NULL)) AS spo2_min,
    MAX(IF(FEATURE_NAME = 'spo2', FEATURE_VALUE, NULL)) AS spo2_max,
    AVG(IF(FEATURE_NAME = 'spo2', FEATURE_VALUE, NULL)) AS spo2_mean

  FROM vitals_long
  WHERE FEATURE_NAME IS NOT NULL
  GROUP BY SUBJECT_ID, HADM_ID, ICUSTAY_ID
),

labs_long AS (
  SELECT
    c.SUBJECT_ID,
    c.HADM_ID,
    c.ICUSTAY_ID,
    CASE
      WHEN le.ITEMID = 50813 THEN 'lactate'
      WHEN le.ITEMID IN (51300, 51301) THEN 'wbc'
      WHEN le.ITEMID = 50912 THEN 'creatinine'
      WHEN le.ITEMID = 50885 THEN 'bilirubin'
      WHEN le.ITEMID = 51265 THEN 'platelet'
      WHEN le.ITEMID = 51006 THEN 'bun'
      WHEN le.ITEMID IN (50824, 50983) THEN 'sodium'
      WHEN le.ITEMID IN (50822, 50971) THEN 'potassium'
      WHEN le.ITEMID = 50882 THEN 'bicarbonate'
      WHEN le.ITEMID = 50820 THEN 'ph'
      WHEN le.ITEMID = 50821 THEN 'pao2'
      WHEN le.ITEMID = 50818 THEN 'paco2'
      WHEN le.ITEMID IN (50809, 50931) THEN 'glucose'
      WHEN le.ITEMID IN (50811, 51222) THEN 'hemoglobin'
      ELSE NULL
    END AS FEATURE_NAME,
    le.VALUENUM AS FEATURE_VALUE
  FROM cohort c
  INNER JOIN physionet-data.mimiciii_clinical.labevents le
    ON c.SUBJECT_ID = le.SUBJECT_ID
   AND c.HADM_ID = le.HADM_ID
  WHERE le.CHARTTIME >= c.INTIME
    AND le.CHARTTIME <= DATETIME_ADD(c.INTIME, INTERVAL 24 HOUR)
    AND le.VALUENUM IS NOT NULL
    AND le.ITEMID IN (
      50813,
      51300, 51301,
      50912,
      50885,
      51265,
      51006,
      50824, 50983,
      50822, 50971,
      50882,
      50820,
      50821,
      50818,
      50809, 50931,
      50811, 51222
    )
),

labs_24h AS (
  SELECT
    SUBJECT_ID,
    HADM_ID,
    ICUSTAY_ID,

    MIN(IF(FEATURE_NAME = 'lactate', FEATURE_VALUE, NULL)) AS lactate_min,
    MAX(IF(FEATURE_NAME = 'lactate', FEATURE_VALUE, NULL)) AS lactate_max,
    AVG(IF(FEATURE_NAME = 'lactate', FEATURE_VALUE, NULL)) AS lactate_mean,

    MIN(IF(FEATURE_NAME = 'wbc', FEATURE_VALUE, NULL)) AS wbc_min,
    MAX(IF(FEATURE_NAME = 'wbc', FEATURE_VALUE, NULL)) AS wbc_max,
    AVG(IF(FEATURE_NAME = 'wbc', FEATURE_VALUE, NULL)) AS wbc_mean,

    MIN(IF(FEATURE_NAME = 'creatinine', FEATURE_VALUE, NULL)) AS creatinine_min,
    MAX(IF(FEATURE_NAME = 'creatinine', FEATURE_VALUE, NULL)) AS creatinine_max,
    AVG(IF(FEATURE_NAME = 'creatinine', FEATURE_VALUE, NULL)) AS creatinine_mean,

    MIN(IF(FEATURE_NAME = 'bilirubin', FEATURE_VALUE, NULL)) AS bilirubin_min,
    MAX(IF(FEATURE_NAME = 'bilirubin', FEATURE_VALUE, NULL)) AS bilirubin_max,
    AVG(IF(FEATURE_NAME = 'bilirubin', FEATURE_VALUE, NULL)) AS bilirubin_mean,

    MIN(IF(FEATURE_NAME = 'platelet', FEATURE_VALUE, NULL)) AS platelet_min,
    MAX(IF(FEATURE_NAME = 'platelet', FEATURE_VALUE, NULL)) AS platelet_max,
    AVG(IF(FEATURE_NAME = 'platelet', FEATURE_VALUE, NULL)) AS platelet_mean,

    MIN(IF(FEATURE_NAME = 'bun', FEATURE_VALUE, NULL)) AS bun_min,
    MAX(IF(FEATURE_NAME = 'bun', FEATURE_VALUE, NULL)) AS bun_max,
    AVG(IF(FEATURE_NAME = 'bun', FEATURE_VALUE, NULL)) AS bun_mean,

    MIN(IF(FEATURE_NAME = 'sodium', FEATURE_VALUE, NULL)) AS sodium_min,
    MAX(IF(FEATURE_NAME = 'sodium', FEATURE_VALUE, NULL)) AS sodium_max,
    AVG(IF(FEATURE_NAME = 'sodium', FEATURE_VALUE, NULL)) AS sodium_mean,

    MIN(IF(FEATURE_NAME = 'potassium', FEATURE_VALUE, NULL)) AS potassium_min,
    MAX(IF(FEATURE_NAME = 'potassium', FEATURE_VALUE, NULL)) AS potassium_max,
    AVG(IF(FEATURE_NAME = 'potassium', FEATURE_VALUE, NULL)) AS potassium_mean,

    MIN(IF(FEATURE_NAME = 'bicarbonate', FEATURE_VALUE, NULL)) AS bicarbonate_min,
    MAX(IF(FEATURE_NAME = 'bicarbonate', FEATURE_VALUE, NULL)) AS bicarbonate_max,
    AVG(IF(FEATURE_NAME = 'bicarbonate', FEATURE_VALUE, NULL)) AS bicarbonate_mean,

    MIN(IF(FEATURE_NAME = 'ph', FEATURE_VALUE, NULL)) AS ph_min,
    MAX(IF(FEATURE_NAME = 'ph', FEATURE_VALUE, NULL)) AS ph_max,
    AVG(IF(FEATURE_NAME = 'ph', FEATURE_VALUE, NULL)) AS ph_mean,

    MIN(IF(FEATURE_NAME = 'pao2', FEATURE_VALUE, NULL)) AS pao2_min,
    MAX(IF(FEATURE_NAME = 'pao2', FEATURE_VALUE, NULL)) AS pao2_max,
    AVG(IF(FEATURE_NAME = 'pao2', FEATURE_VALUE, NULL)) AS pao2_mean,

    MIN(IF(FEATURE_NAME = 'paco2', FEATURE_VALUE, NULL)) AS paco2_min,
    MAX(IF(FEATURE_NAME = 'paco2', FEATURE_VALUE, NULL)) AS paco2_max,
    AVG(IF(FEATURE_NAME = 'paco2', FEATURE_VALUE, NULL)) AS paco2_mean,

    MIN(IF(FEATURE_NAME = 'glucose', FEATURE_VALUE, NULL)) AS glucose_min,
    MAX(IF(FEATURE_NAME = 'glucose', FEATURE_VALUE, NULL)) AS glucose_max,
    AVG(IF(FEATURE_NAME = 'glucose', FEATURE_VALUE, NULL)) AS glucose_mean,

    MIN(IF(FEATURE_NAME = 'hemoglobin', FEATURE_VALUE, NULL)) AS hemoglobin_min,
    MAX(IF(FEATURE_NAME = 'hemoglobin', FEATURE_VALUE, NULL)) AS hemoglobin_max,
    AVG(IF(FEATURE_NAME = 'hemoglobin', FEATURE_VALUE, NULL)) AS hemoglobin_mean

  FROM labs_long
  WHERE FEATURE_NAME IS NOT NULL
  GROUP BY SUBJECT_ID, HADM_ID, ICUSTAY_ID
),

urine_24h AS (
  SELECT
    c.SUBJECT_ID,
    c.HADM_ID,
    c.ICUSTAY_ID,
    SUM(oe.VALUE) AS urineoutput_24h
  FROM cohort c
  LEFT JOIN physionet-data.mimiciii_clinical.outputevents oe
    ON c.ICUSTAY_ID = oe.ICUSTAY_ID
   AND oe.CHARTTIME >= c.INTIME
   AND oe.CHARTTIME <= DATETIME_ADD(c.INTIME, INTERVAL 24 HOUR)
   AND oe.VALUE IS NOT NULL
  GROUP BY c.SUBJECT_ID, c.HADM_ID, c.ICUSTAY_ID
),

vasopressor_mv AS (
  SELECT DISTINCT
    c.SUBJECT_ID,
    c.HADM_ID,
    c.ICUSTAY_ID
  FROM cohort c
  INNER JOIN physionet-data.mimiciii_clinical.inputevents_mv mv
    ON c.ICUSTAY_ID = mv.ICUSTAY_ID
  WHERE mv.STARTTIME < DATETIME_ADD(c.INTIME, INTERVAL 24 HOUR)
    AND mv.ENDTIME > c.INTIME
    AND mv.ITEMID IN (
      221906,  -- norepinephrine
      221289,  -- epinephrine
      221749,  -- phenylephrine
      222315,  -- vasopressin
      221662,  -- dopamine
      221653,  -- dobutamine
      221986   -- milrinone
    )
),

vasopressor_cv AS (
  SELECT DISTINCT
    c.SUBJECT_ID,
    c.HADM_ID,
    c.ICUSTAY_ID
  FROM cohort c
  INNER JOIN physionet-data.mimiciii_clinical.inputevents_cv cv
    ON c.ICUSTAY_ID = cv.ICUSTAY_ID
  WHERE cv.CHARTTIME >= c.INTIME
    AND cv.CHARTTIME <= DATETIME_ADD(c.INTIME, INTERVAL 24 HOUR)
    AND cv.ITEMID IN (
      30047, 30120,
      30044, 30119, 30309,
      30127, 30128,
      30051, 42273, 42802,
      30043, 30307,
      30042, 30306,
      30125
    )
),

vasopressor_24h AS (
  SELECT
    c.SUBJECT_ID,
    c.HADM_ID,
    c.ICUSTAY_ID,
    CASE
      WHEN mv.ICUSTAY_ID IS NOT NULL OR cv.ICUSTAY_ID IS NOT NULL THEN 1
      ELSE 0
    END AS vasopressor_24h
  FROM cohort c
  LEFT JOIN vasopressor_mv mv
    ON c.ICUSTAY_ID = mv.ICUSTAY_ID
  LEFT JOIN vasopressor_cv cv
    ON c.ICUSTAY_ID = cv.ICUSTAY_ID
),

sofa_scores AS (
  SELECT
    s.icustay_id,
    s.sofa AS sofa_score
  FROM `physionet-data.mimiciii_derived.sofa` s
  INNER JOIN cohort c
    ON s.icustay_id = c.ICUSTAY_ID
)

SELECT 
  c.SUBJECT_ID,
  c.HADM_ID, 
  c.ICUSTAY_ID,

  c.TARGET_MORTALITY,

  c.AGE,
  c.GENDER, 
  c.ETHNICITY,
  c.ADMISSION_TYPE,

  v.heartrate_min,
  v.heartrate_max,
  v.heartrate_mean,
  v.sysbp_min, 
  v.sysbp_max,
  v.sysbp_mean,
  v.diasbp_min,
  v.diasbp_max,
  v.diasbp_mean,
  v.meanbp_min,
  v.meanbp_max,
  v.meanbp_mean,
  v.resprate_min,
  v.resprate_max,
  v.resprate_mean,
  v.temperature_min, 
  v.temperature_max, 
  v.temperature_mean, 
  v.spo2_min,
  v.spo2_max,
  v.spo2_mean,

  l.lactate_min, 
  l.lactate_max,
  l.lactate_mean,

  l.wbc_min,
  l.wbc_max,
  l.wbc_mean,

  l.creatinine_min,
  l.creatinine_max,
  l.creatinine_mean,

  l.bilirubin_min, 
  l.bilirubin_max,
  l.bilirubin_mean,

  l.platelet_min,
  l.platelet_max,
  l.platelet_mean,
  
  l.bun_min,
  l.bun_max,
  l.bun_mean,

  l.sodium_min,
  l.sodium_max,
  l.sodium_mean,

  l.potassium_min,
  l.potassium_max,
  l.potassium_mean,

  l.bicarbonate_min,
  l.bicarbonate_max,
  l.bicarbonate_mean,

  l.ph_min,
  l.ph_max,
  l.ph_mean,

  l.pao2_min, 
  l.pao2_max, 
  l.pao2_mean, 

  l.paco2_min,
  l.paco2_max,
  l.paco2_mean,

  l.glucose_min,
  l.glucose_max,
  l.glucose_mean,
  
  l.hemoglobin_min,
  l.hemoglobin_max,
  l.hemoglobin_mean,

  u.urineoutput_24h,
  vp.vasopressor_24h,

  sf.sofa_score

  FROM cohort c
  LEFT JOIN vitals_24h v
    ON c.ICUSTAY_ID = V.ICUSTAY_ID
  LEFT JOIN labs_24h l
    ON c.ICUSTAY_ID = l.ICUSTAY_ID
  LEFT JOIN urine_24h u
    ON c.ICUSTAY_ID = u.ICUSTAY_ID
  LEFT JOIN vasopressor_24h vp
    ON c.ICUSTAY_ID = vp.ICUSTAY_ID
  LEFT JOIN sofa_scores sf
    ON c.ICUSTAY_ID = sf.icustay_id
;
