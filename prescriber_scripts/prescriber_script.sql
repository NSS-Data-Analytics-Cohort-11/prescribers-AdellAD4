-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. 

SELECT prescription.npi, SUM(prescription.total_claim_count) AS total_claims 
FROM prescription
GROUP BY prescription.npi
ORDER BY total_claims DESC
LIMIT 5;
 --ANSWER: 1881634483	99707
 
-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT prescription.npi, SUM(prescription.total_claim_count) AS total_claims, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description 
FROM prescription
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
GROUP BY prescription.npi, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
ORDER BY total_claims DESC
LIMIT 5;

--ANSWER: 1881634483	99707	"BRUCE"	"PENDLEY"	"Family Practice"

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT prescription.npi, SUM(prescription.total_claim_count) AS total_claims, prescriber.specialty_description 
FROM prescription
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
GROUP BY prescription.npi, prescriber.specialty_description
ORDER BY total_claims DESC
LIMIT 5;

--ANSWER: Family Practice

-- b. Which specialty had the most total number of claims for opioids?

SELECT SUM(prescription.total_claim_count) AS total_claims, prescriber.specialty_description, drug.opioid_drug_flag 
FROM prescription
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
INNER JOIN drug
ON drug.drug_name = prescription.drug_name
WHERE drug.opioid_drug_flag = 'Y' 
GROUP BY prescriber.specialty_description, drug.opioid_drug_flag 
ORDER BY total_claims DESC
LIMIT 5;

--ANSWER: Nurse Practitioner

-- c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT prescriber.specialty_description, SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi=prescription.npi
GROUP BY prescriber.specialty_description
HAVING SUM(prescription.total_claim_count) IS NULL
ORDER BY prescriber.specialty_description;

--ANSWER "Marriage & Family Therapist",
-- "Contractor",
-- "Physical Therapist in Private Practice",
-- "Developmental Therapist", "Chiropractic",
-- "Occupational Therapist in Private Practice",
-- "Licensed Practical Nurse",
-- "Midwife", "Medical Genetics",
-- "Physical Therapy Assistant",
-- "Ambulatory Surgical Center", and
-- "Undefined Physician type"

-- d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH claims AS
	(SELECT
		prescriber.specialty_description,
		SUM(prescription.total_claim_count) AS total_claims
	FROM prescriber 
	INNER JOIN prescription 
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	GROUP BY prescriber.specialty_description),
-- second CTE for total opioid claims
opioid AS
	(SELECT
		prescriber.specialty_description,
		SUM(prescription.total_claim_count) AS total_opioid
	FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE drug.opioid_drug_flag ='Y'
	GROUP BY prescriber.specialty_description)
--main query
SELECT
	claims.specialty_description,
	COALESCE(ROUND((opioid.total_opioid / claims.total_claims * 100),2),0) AS pct_opioid
FROM claims
LEFT JOIN opioid
USING(specialty_description)
ORDER BY pct_opioid;

--ANSWER: Best to run the query
			 
			 
-- Dibran's Query
--SELECT
-- 	specialty_description,
-- 	SUM(
-- 		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
-- 		ELSE 0
-- 	END
-- 	) as opioid_claims,
	
-- 	SUM(total_claim_count) AS total_claims,
	
-- 	SUM(
-- 		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
-- 		ELSE 0
-- 	END
-- 	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
-- FROM prescriber
-- INNER JOIN prescription
-- USING(npi)
-- INNER JOIN drug
-- USING(drug_name)
-- GROUP BY specialty_description
-- --order by specialty_description;
-- order by opioid_percentage desc			

--3. a. Which drug (generic_name) had the highest total drug cost?

SELECT drug.generic_name, SUM(prescription.total_drug_cost)
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY SUM(prescription.total_drug_cost) DESC;

--ANSWER "INSULIN GLARGINE,HUM.REC.ANLOG"

-- b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT drug.generic_name, ROUND(SUM(prescription.total_drug_cost)/SUM(prescription.total_day_supply),2) AS high_generic_total_per_day
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY high_generic_total_per_day DESC;

--ANSWER: "C1 ESTERASE INHIBITOR"	3495.22

--4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT drug_name,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag ='Y' THEN 'antibiotic'
ELSE 'neither' END AS drug_type
FROM drug;

--ANSWER: Best to run the query

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag ='Y' THEN 'antibiotic'
ELSE 'neither' END AS drug_type,
SUM(MONEY(prescription.total_drug_cost))
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY SUM(MONEY(prescription.total_drug_cost));

--ANSWER Opioids

--5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT (*)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN'

--ANSWER 42

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsa.cbsaname, SUM(population.population)
FROM cbsa
INNER JOIN population
ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname
ORDER BY SUM(population.population) DESC;

--ANSWER Largest is "Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410. Smallest is "Morristown, TN" 116352

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT population.population, fips_county.county
FROM population
LEFT JOIN cbsa
ON cbsa.fipscounty = population.fipscounty
LEFT JOIN fips_county
ON population.fipscounty = fips_county.fipscounty
WHERE cbsa IS NULL
ORDER BY population DESC;

--ANSWER Sevier County, population 95523



--6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= '3000' 
ORDER BY total_claim_count DESC;

--ANSWER: "OXYCODONE HCL"	4538
--        "LISINOPRIL"	3655
--        "GABAPENTIN"	3531
--        "HYDROCODONE-ACETAMINOPHEN"	3376
--        "LEVOTHYROXINE SODIUM"	3138
--        "LEVOTHYROXINE SODIUM"	3101
--        "MIRTAZAPINE"	3085
--        "FUROSEMIDE"	3083
--        "LEVOTHYROXINE SODIUM"	3023

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag
FROM prescription
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE total_claim_count >= '3000' 
ORDER BY total_claim_count DESC;

--ANSWER "OXYCODONE HCL" and "HYDROCODONE-ACETAMINOPHEN" are opioids

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag, prescriber.nppes_provider_last_org_name, prescriber.nppes_provider_first_name 
FROM prescription
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE total_claim_count >= '3000' 
ORDER BY total_claim_count DESC;

--ANSWER Would be best to run the query

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT drug.drug_name, prescriber.npi
FROM prescriber
CROSS JOIN drug
WHERE specialty_description iLIKE 'Pain Management'
	AND nppes_provider_city iLIKE 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- SELECT prescriber.npi, drug.drug_name, 
-- (SELECT SUM(prescription.total_claim_count) FROM prescription
-- WHERE prescriber.npi = prescription.npi
-- AND prescription.drug_name = drug.drug_name) AS sum_total_claims
-- FROM prescriber
-- CROSS JOIN drug
-- LEFT JOIN prescription
-- ON prescriber.npi = prescription.npi
-- WHERE prescriber.specialty_description iLIKE 'Pain Management'
-- 	AND prescriber.nppes_provider_city iLIKE 'NASHVILLE'
-- 	AND drug.opioid_drug_flag = 'Y'
-- GROUP BY prescriber.npi, drug.drug_name
-- ORDER BY prescriber.npi; 

-- SELECT
-- 	prescriber.npi,
-- 	drug.drug_name,
-- 	(SELECT
-- 	 	SUM(prescription.total_claim_count)
-- 	 FROM prescription
-- 	 WHERE prescriber.npi = prescription.npi
-- 	 AND prescription.drug_name = drug.drug_name) as total_claims
-- FROM prescriber
-- CROSS JOIN drug 
-- INNER JOIN prescription
-- using (npi)
-- WHERE 
-- 	prescriber.specialty_description = 'Pain Management' AND
-- 	prescriber.nppes_provider_city = 'NASHVILLE' AND
-- 	drug.opioid_drug_flag = 'Y'
-- GROUP BY prescriber.npi, drug.drug_name
-- ORDER BY prescriber.npi DESC;

--I originally had the following query, but thought I needed to sum the total claim count and rewrote the query with a subquery which my computer could not handle. It ran the query for over 16 minutes and I canceled it. Then Matt sent me the query he did with subquery just to see if my computer could handle it and it could not. So I compared the results with what I originally had and went with that one.

SELECT prescriber.npi, drug.drug_name, prescription.total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE prescriber.specialty_description = 'Pain Management' AND
	prescriber.nppes_provider_city = 'NASHVILLE' AND
	drug.opioid_drug_flag = 'Y';
    
--ANSWER Once again, best to run the query

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi, drug.drug_name,
 COALESCE(prescription.total_claim_count,0)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE prescriber.specialty_description = 'Pain Management' AND
	prescriber.nppes_provider_city = 'NASHVILLE' AND
	drug.opioid_drug_flag = 'Y';
    
