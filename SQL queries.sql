- > Top 5 Cities with highest credit card spends and their percentage contribution to total credit card spends.

WITH CTE AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY CITY
                             ORDER BY TRANSACTION_DATE) AS rn
   FROM credit_card_transcations)
SELECT TOP 1 city,
           DATEDIFF(DAY, min(transaction_date), max(transaction_date)) AS Duration
FROM CTE
WHERE rn = 1
  OR rn = 500
GROUP BY CITY
HAVING COUNT(1) = 2
ORDER BY Duration ;

-> Highest spend month and the amount spent in that month for each Card type.
  
WITH cte AS
  (SELECT card_type,
          SUM(amount) AS total_spend,
          DATEPART(YEAR, TRANSACTION_DATE) AS YR,
          DATEPART(MONTH, TRANSACTION_DATE) AS MNTH
   FROM credit_card_transcations
   GROUP BY card_type,
            DATEPART(YEAR, TRANSACTION_DATE),
            DATEPART(MONTH, TRANSACTION_DATE)),
     cte1 AS
  (SELECT *,
          DENSE_RANK() OVER(PARTITION BY card_type
                            ORDER BY total_spend DESC) AS rank_mnth
   FROM cte)
SELECT *
FROM CTE1
WHERE rank_mnth =1;

-> Transaction details (all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends.
  
WITH CTE AS
  (SELECT *,
          SUM(amount) over(PARTITION BY CARD_TYPE
                           ORDER BY transaction_date, transaction_id) AS cumm_amount
   FROM credit_card_transcations)
SELECT *
FROM
  (SELECT *,
          ROW_NUMBER() OVER(PARTITION BY CARD_TYPE
                            ORDER BY cumm_amount) AS rn
   FROM CTE
   WHERE cumm_amount >= 1000000) A
WHERE rn = 1;

-> City with the lowest percentage spend for the Gold Card type.
  
WITH CTE AS
  (SELECT city,
          SUM(amount) AS total_spend
   FROM credit_card_transcations
   WHERE card_type = 'Gold'
   GROUP BY city),
     CTE1 AS
  (SELECT SUM(CAST (Amount AS bigint)) AS total_amount
   FROM credit_card_transcations)
SELECT TOP 1*,
            total_spend*1.0/total_amount*100 AS diff
FROM cte
JOIN cte1 ON 1=1
ORDER BY diff ;

-> Print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

WITH CTE AS
  (SELECT city,
          exp_type,
          SUM(amount) AS total_amount
   FROM credit_card_transcations
   GROUP BY city,
            exp_type),
CTE1 AS
  (SELECT *,
          RANK() OVER(PARTITION BY CITY
                      ORDER BY total_amount DESC) AS highest_amount,
          RANK() OVER(PARTITION BY CITY
                      ORDER BY total_amount) AS least_amount
   FROM CTE)
SELECT City,
       MAX(CASE
               WHEN highest_amount = 1 THEN exp_type
           END) AS high ,
       MIN(CASE
               WHEN least_amount = 1 THEN exp_type
           END) AS low
FROM CTE1
GROUP BY city;

-> To find percentage contribution of spends by females for each expense type

WITH CTE AS
  (SELECT exp_type,
          SUM(amount) AS total_spend,
          gender
   FROM credit_card_transcations
   GROUP BY exp_type,
            gender),
     CTE1 AS
  (SELECT *,
          SUM(amount) over(PARTITION BY exp_type)AS total_amount
   FROM credit_card_transcations),
     cte2 AS
  (SELECT CTE.exp_type,
          cte.gender,
          total_spend,
          total_amount,
          (1.0*total_spend/total_amount*100) AS percen_amount,
          ROW_NUMBER() OVER(PARTITION BY cte.exp_type
                            ORDER BY cte.exp_type) AS rn
   FROM CTE1
   JOIN CTE ON 1=1
   WHERE CTE.GENDER = 'F')
SELECT *
FROM cte2
WHERE rn=1;


SELECT exp_type,
       sum(CASE
               WHEN gender='F' THEN amount
           END)*1.0 /sum(amount)AS total_amount
FROM credit_card_transcations
GROUP BY exp_type;

-> Which card and expense type combination saw highest month over month growth in Jan-2014

WITH CTE AS
  (SELECT card_type,
          exp_type,
          SUM(amount) AS total_amount,
          FORMAT(transaction_date, 'yyyyMM') AS date
   FROM credit_card_transcations
   GROUP BY card_type,
            exp_type,
            FORMAT(transaction_date, 'yyyyMM')),
     CTE1 AS
  (SELECT *,
          LAG(total_amount) OVER(PARTITION BY card_type, exp_type
                                 ORDER BY date) AS last_value
   FROM CTE)
SELECT TOP 1*,
            (total_amount-last_value) AS mom
FROM CTE1
WHERE date = '201401'
ORDER BY mom DESC ;

-> During Weekends which city has highest total spend to total no of transcations ratio 

SELECT TOP 1 City,
           1.0*SUM(amount)/COUNT(1) AS ratio
FROM credit_card_transcations 
--WHERE DATENAME(WEEKDAY,transaction_date)  IN ('Saturday','Sunday')
WHERE DATEPART(WEEKDAY, transaction_date) IN (7,1) 
//Integers IS faster THAN Strings
GROUP BY city
ORDER BY ratio DESC;

-> Which city took least number of days to reach its 500th transaction after the first transaction in that city
  
WITH CTE AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY CITY
                             ORDER BY TRANSACTION_DATE) AS rn
   FROM credit_card_transcations)
SELECT TOP 1 city,
           DATEDIFF(DAY, min(transaction_date), max(transaction_date)) AS Duration
FROM CTE
WHERE rn = 1
  OR rn = 500
GROUP BY CITY
HAVING COUNT(1) = 2
ORDER BY Duration ;
