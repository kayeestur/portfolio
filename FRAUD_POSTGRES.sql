/* IMPORTING DATASET FRAUD IN SQL */

CREATE TABLE fraud (
	step SMALLINT,
	type VARCHAR(50) NOT NULL,
	amount NUMERIC,
	nameOrig VARCHAR(100),
	oldbalanceOrg NUMERIC,
	newbalanceOrig NUMERIC,
	nameDest VARCHAR(100),
	oldbalanceDest NUMERIC,
	newbalanceDest NUMERIC,
	isFraud SMALLINT NOT NULL,
	isFlaggedFraud SMALLINT NOT NULL)
	
/* EXPLORATORY DATA ANALYSIS */

/* How many transactions are inside the dataset? */
SELECT COUNT(type) AS NumOfObs
FROM fraud
	
/* What are the different transaction types inside the dataset?
How many transactions were done for each transaction type?*/
SELECT DISTINCT type, COUNT(type) AS Total_Transactions
FROM fraud
GROUP BY type
ORDER BY COUNT(type) DESC

/* What is the max, min, average, transaction amount */
SELECT MAX(amount), MIN(amount), ROUND(AVG(amount),2) AS Ave
FROM fraud

/* Top 10 customers have above average transactions */
SELECT nameOrig, amount, isFraud, isFlaggedFraud
FROM fraud
WHERE amount > (SELECT AVG(amount) FROM fraud)
ORDER BY amount DESC
LIMIT 10

/* Do any of these transactions have been confirmed fraud? */
SELECT nameOrig, amount, isFraud
FROM fraud
WHERE amount > (SELECT AVG(amount) FROM fraud) AND isFraud <> 0
ORDER BY amount DESC

/* Which customers had multiple transactions? */

SELECT nameorig, COUNT(nameorig)
FROM fraud
GROUP BY nameorig
HAVING COUNT(nameorig) > 1
ORDER BY COUNT(nameorig) DESC

/* What are the transactions that were flagged as fraud? 
Were these transactions actually fraud?*/
SELECT *
FROM fraud
WHERE isflaggedfraud <> 0
ORDER BY amount DESC

/* How many transactions were actually fraud? */
SELECT type, COUNT(type) AS NumOfFraudTrans
FROM fraud
WHERE isfraud <> 0
GROUP BY type

/* How many transactions were actually fraud but where not flagged as fraud? */
SELECT type, COUNT(type) AS NumOfFraudTrans
FROM fraud
WHERE isfraud <> 0 AND isflaggedfraud = 0
GROUP BY type

/* Total Amount of Fraudulent Transactions per Transaction Type */
SELECT type, SUM (amount) AS TotalAmount
FROM fraud
WHERE isfraud <> 0
GROUP BY type
ORDER BY SUM(amount) DESC

--Created view to see only fraudulent transactions for further analysis
CREATE VIEW fraud_trans AS
SELECT *
FROM fraud
WHERE isfraud <> 0

-- transactions where customer balances were zeroed out should be flagged
SELECT type, amount, nameorig, oldbalanceorg, newbalanceorig,
CASE
	WHEN amount = oldbalanceorg AND newbalanceorig = 0 THEN 'Zeroed Out'
	ELSE 'Other'
END AS Transaction_Activity
INTO fraudactivity
FROM fraud_trans

--Summary table of fraudulent transactions where customer balances were zeroed out
SELECT transaction_activity,COUNT(transaction_activity) AS NumOfTrans, SUM(amount) AS TotalAmount
FROM fraudactivity
GROUP BY transaction_activity
ORDER BY COUNT(transaction_activity) DESC

--Potential Controls for CASH_OUT transaction types
SELECT *,
CASE
	WHEN amount > oldbalanceorg THEN 'Insufficient Old Balance'
	WHEN amount <> (oldbalanceorg - newbalanceorig) THEN 'Incorrect New Balance'
	ELSE 'To further investigate'
END AS Controls
FROM fraudactivity
WHERE transaction_activity = 'Other' AND type ='CASH_OUT'

--Potential controls for TRANSFER transaction types
SELECT *,
CASE 
	WHEN amount > oldbalanceorg THEN 'Insufficient Old Balance'
	WHEN amount <> (oldbalanceorg-newbalanceorig) THEN 'Incorrect New Balance'
	ELSE 'To further investigate'
END AS Controls
FROM fraudactivity
WHERE transaction_activity = 'Other' AND type ='TRANSFER'

-- Same amount transactions repeated multiple times need to be investigated
SELECT DISTINCT amount,COUNT(type) AS NumOfTrans
FROM fraudactivity
GROUP BY DISTINCT amount
HAVING COUNT(type)>10
ORDER BY COUNT(type) DESC

-- Another type of control for destination 
SELECT type,amount,nameorig,oldbalanceorg,newbalanceorig,namedest,oldbalancedest,newbalancedest,
CASE
	WHEN amount <> (newbalancedest-oldbalancedest) THEN 'Incorrect New Balance in Destination'
	ELSE 'For investigation'
END AS Controls
INTO destinationactivity
FROM fraud_trans

-- Zeroed out transactions where destination new balances match the amount transacted
SELECT type, COUNT(type) AS NumOfTrans
FROM destinationactivity
WHERE controls LIKE '%investigation%'
GROUP BY type
ORDER BY COUNT(type) DESC