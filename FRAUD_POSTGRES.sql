CREATE TABLE fraud (
	step SMALLINT,
	type VARCHAR(50) NOT NULL,
	amount INTEGER,
	nameOrig VARCHAR(100),
	oldbalanceOrg INTEGER,
	newbalanceOrig INTEGER,
	nameDest VARCHAR(100),
	oldbalanceDest INTEGER,
	newbalanceDest INTEGER,
	isFraud SMALLINT NOT NULL,
	isFlaggedFraud SMALLINT NOT NULL)