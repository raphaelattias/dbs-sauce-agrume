/* QUESTION 1
SELECT age_group, COUNT(CASE WHEN AT_FAULT = 1 THEN 1 END)/COUNT(*) * 100 AS atfault_ratio
FROM (
select 
  case
   when P.PARTY_AGE <19 then 'Underage'
   when P.PARTY_AGE between 19 and 21 then 'young_1'
   when P.PARTY_AGE between 22 and 24 then 'young_2'
   when P.PARTY_AGE between 25 and 60 then 'adult'
   when P.PARTY_AGE between 61 and 64 then 'elder_1'
   when P.PARTY_AGE >64 then 'elder_2'
  END as age_group, AT_FAULT
 from PARTY P
 Where PARTY_AGE IS NOT NULL
) t
group by age_group
ORDER BY (
    CASE age_group
    WHEN 'Underage'THEN 1
    WHEN 'young_1' THEN 2
    WHEN 'young_2' THEN 3
    WHEN 'adult'   THEN 4
    WHEN 'elder_1' THEN 5
    WHEN 'elder_2' THEN 6
    END
) ASC
*/

/* QUESTION 2
SELECT P.STATEWIDE_VEHICLE_TYPE AS VEHICLE_TYPE , COUNT(*) as ACCIDENT_WITH_HOLES
FROM COLLISION C, PARTY P
WHERE C.CASE_ID= P.CASE_ID AND STATEWIDE_VEHICLE_TYPE IS NOT NULL AND (C.ROAD_CONDITION_1 = 'holes' OR C.ROAD_CONDITION_2 = 'holes')  
GROUP BY STATEWIDE_VEHICLE_TYPE
ORDER BY ACCIDENT_WITH_HOLES DESC
FETCH FIRST 5 ROWS ONLY;
*/

/* QUESTION 3
SELECT P.VEHICLE_MAKE AS VEHICLE_BRAND , COUNT(*) as Nbr_VICTIMS
FROM VICTIM C, PARTY P
WHERE C.CASE_ID= P.CASE_ID AND P.VEHICLE_MAKE IS NOT NULL AND P.VEHICLE_MAKE != 'NOT STATED' AND (C.Victim_degree_of_injury = 'killed' OR C.Victim_degree_of_injury = 'severe injury')   
GROUP BY VEHICLE_MAKE
ORDER BY Nbr_VICTIMS DESC
FETCH FIRST 10 ROWS ONLY;
*/

/* QUESTION 4
SELECT V1.VICTIM_SEATING_POSITION, ROUND(V1.COUNT_PER_POSITION/V2.TOT_PER_POSITION,3) AS SAFETY_INDEX
FROM (SELECT V.VICTIM_SEATING_POSITION, COUNT(V.VICTIM_SEATING_POSITION) AS COUNT_PER_POSITION
FROM VICTIM V 
WHERE V.VICTIM_DEGREE_OF_INJURY = 'no injury' 
GROUP BY V.VICTIM_SEATING_POSITION) V1,
(SELECT V.VICTIM_SEATING_POSITION, COUNT(V.VICTIM_SEATING_POSITION) AS TOT_PER_POSITION
FROM VICTIM V 
GROUP BY V.VICTIM_SEATING_POSITION) V2
WHERE V1.VICTIM_SEATING_POSITION = V2.VICTIM_SEATING_POSITION
ORDER BY SAFETY_INDEX DESC
*/

/* QUESTION 5
SELECT COUNT(*) FROM (
SELECT P1.STATEWIDE_VEHICLE_TYPE, COUNT(DISTINCT P1.COUNTY_CITY_LOCATION) AS TOT_CITY, COUNT( P1.COUNTY_CITY_LOCATION) AS TOT_COL
FROM
(SELECT P.CASE_ID, P.STATEWIDE_VEHICLE_TYPE, C.COUNTY_CITY_LOCATION FROM PARTY P
JOIN 
(SELECT C.CASE_ID, C.COUNTY_CITY_LOCATION FROM COLLISION C) C
ON C.CASE_ID = P.CASE_ID
) P1
GROUP BY P1.STATEWIDE_VEHICLE_TYPE) P2
WHERE (P2.TOT_COL) > 10 AND (P2.TOT_CITY) > (SELECT COUNT(DISTINCT C1.COUNTY_CITY_LOCATION)/2 FROM COLLISION2 C1)
*/

/* QUESTION 6
SELECT COUNTY_CITY_LOCATION, POPULATION, CASE_ID, MEAN_AGE FROM (
select N.*, ROW_NUMBER() OVER (PARTITION BY COUNTY_CITY_LOCATION order by MEAN_AGE ASC) r FROM
(SELECT V2.COUNTY_CITY_LOCATION, V2.POPULATION, V3.CASE_ID, V3.MEAN_AGE FROM (SELECT * FROM (SELECT * FROM IN_LOCATION L WHERE L.POPULATION IS NOT NULL ORDER BY L.POPULATION DESC) WHERE ROWNUM <= 3) V2
LEFT JOIN
(SELECT V1.CASE_ID, V1.MEAN_AGE, C.COUNTY_CITY_LOCATION
FROM (SELECT V.CASE_ID, AVG(V.VICTIM_AGE) AS MEAN_AGE
FROM VICTIM V
GROUP BY V.CASE_ID) V1
JOIN 
(COLLISION2 C)
ON V1.CASE_ID = C.CASE_ID) V3
ON v2.county_city_location = v3.county_city_location) N
) M where r <= 10
*/

/* QUESTION 7
SELECT P2.CASE_ID, AGE_MAX FROM (
SELECT P1.CASE_ID, MAX(P1.VICTIM_AGE) AS AGE_MAX, MIN(P1.VICTIM_AGE) AS AGE_MIN FROM
(SELECT C.CASE_ID, C.TYPE_OF_COLLISION, V.VICTIM_AGE FROM COLLISION C
INNER JOIN (SELECT V.VICTIM_AGE, V.CASE_ID FROM VICTIM V) V 
ON C.CASE_ID = V.CASE_ID) P1 WHERE P1.TYPE_OF_COLLISION = 'pedestrian'
GROUP BY P1.CASE_ID) P2
WHERE AGE_MIN >= 100
*/

/* QUESTION 8
SELECT P1.VEHICLE_MAKE, P1.VEHICLE_YEAR, NUMBER_OF_COLLISION FROM 
(SELECT P.VEHICLE_MAKE, P.VEHICLE_YEAR, COUNT(*) AS NUMBER_OF_COLLISION FROM PARTY P 
GROUP BY P.VEHICLE_MAKE, P.VEHICLE_YEAR) P1
WHERE NUMBER_OF_COLLISION >= 10 AND VEHICLE_MAKE != '(null)' AND VEHICLE_MAKE != '(null)'
ORDER BY NUMBER_OF_COLLISION DESC
*/

/* QUESTION 9
SELECT * FROM (SELECT * FROM 
(SELECT C.COUNTY_CITY_LOCATION, COUNT(*) AS NUMBER_OF_COLLISION FROM COLLISION2 C 
GROUP BY C.COUNTY_CITY_LOCATION) P
ORDER BY NUMBER_OF_COLLISION DESC) A
WHERE ROWNUM <= 10
*/

/* QUESTION 10
SELECT time_zone, COUNT(*) as nbr_accident
FROM(
SELECT 
  case 
    when ((EXTRACT(MONTH FROM COLLISION_DATE) > 8) OR (EXTRACT(MONTH FROM COLLISION_DATE) <4)) then case 
                                                                                                      when (C.Lighting IS NULL OR C.Lighting = 'dusk or dawn') then case 
                                                                                                                                                                when SUBSTR(COLLISION_TIME, 1, 2)>17 AND SUBSTR(COLLISION_TIME, 1, 2)<20 then 'Dusk' 
                                                                                                                                                                when SUBSTR(COLLISION_TIME, 1, 2)>5 AND SUBSTR(COLLISION_TIME, 1, 2)<8 then 'Dawn'                              
                                                                                                                                                                when SUBSTR(COLLISION_TIME, 1, 2)>7 AND SUBSTR(COLLISION_TIME, 1, 2)<19 then 'Day sep-march'
                                                                                                                                                                else 'Night sep-march'
                                                                                                                                                              END 
                                                                                                      when C.Lighting = 'dark with no street lights' then 'Night sep-march'
                                                                                                      when C.Lighting = 'dark with street lights not functioning' then 'Night sep-march'
                                                                                                      when C.Lighting = 'daylight' then 'Day sep-march'
                                                                                                      when C.Lighting = 'dark with street lights' then 'Night sep-march'
                                                                                                     END 
    else case 
          when (C.Lighting IS NULL OR C.Lighting = 'dusk or dawn') then case 
                                                                          when SUBSTR(COLLISION_TIME, 1, 2)>19 AND SUBSTR(COLLISION_TIME, 1, 2)<22 then 'Dusk' 
                                                                          when SUBSTR(COLLISION_TIME, 1, 2)>3 AND SUBSTR(COLLISION_TIME, 1, 2)<7 then 'Dawn'                              
                                                                          when SUBSTR(COLLISION_TIME, 1, 2)>5 AND SUBSTR(COLLISION_TIME, 1, 2)<21 then 'Day apr-aug'
                                                                          else 'Night apr-aug'
                                                                        END 
          when C.Lighting = 'dark with no street lights' then 'Night apr-aug'
          when C.Lighting = 'dark with street lights not functioning' then 'Night apr-aug'
          when C.Lighting = 'daylight' then 'Day apr-aug'
          when C.Lighting = 'dark with street lights' then 'Night apr-aug' 
        END
      END as time_zone 
FROM Collision C)
GROUP BY time_zone
*/
