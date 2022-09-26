-----------------------------------
-- Check dataset
SELECT *
FROM PortfolioProject.dbo.airbnb2;
----------------------------------
-- Converting data types, except price/service_fee as they have dollar sign in the string
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN id BIGINT;  
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN host_id BIGINT;  
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN Construction_year INT;  
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN minimum_nights INT;  
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN reviews_per_month float;  
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN review_rate_number INT;  
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN calculated_host_listings_count INT;  
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN availability_365 INT;  
----------------------------------
-- Check dataset
SELECT *
FROM PortfolioProject.dbo.airbnb2;
----------------------------------
-- Check id duplicates. Duplicates will have dup_count values > 1
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS dup_count
FROM PortfolioProject.dbo.airbnb2;

-- This give us 1082 rows of total duplicated values, which we need to remove duplicated values. First we need to create a new column to record row values
-- First we need to add a primary key to the table so that we can use it to remove duplicated values. 
ALTER TABLE PortfolioProject.dbo.airbnb2 ADD userkey INT identity(1,1) not null PRIMARY KEY

-- Delete duplicates values (Not best practice - best is to save to a temp table to continue, yet for the purpose of this exercise, we will delete the duplicates)
DELETE e FROM PortfolioProject.dbo.airbnb2 e
    INNER JOIN
    (
        SELECT *,
			ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS dup_count
		FROM PortfolioProject.dbo.airbnb2 t
    ) t ON e.userkey = t.userkey
    WHERE t.dup_count > 1;

-- (541 rows affected) We successfully removed duplicated data. Now id column is numeric and unique.
----------------------------------
-- Next we want to assess other columns. Name is something that can be null or empty in the case that the host does not do properly when listing the property. However, a property would not be legit if there is no host_id, so we would look into that.
SELECT *
FROM PortfolioProject.dbo.airbnb2
WHERE host_id IS NULL OR host_id LIKE '' OR host_id = 0;
-- Seems like host_id is okay. Plus, a host can list multiple properties, so we do not need to check duplicates for this column. 
SELECT * 
FROM PortfolioProject.dbo.airbnb2
WHERE host_identity_verified IS NULL OR host_identity_verified LIKE '';
-- After checking the data, host_name is there but their is no identity confirmation in the host_identity_verified column. There might be in the process of identification, so we would replace those values with 'progressing' so that it is clear in the meaning of the values. And change 'unconfirmed' to 'unverified', which means we cannot verify these hosts after the verification process. 
UPDATE PortfolioProject.dbo.airbnb2
SET host_identity_verified = 'unverified'
WHERE host_identity_verified = 'unconfirmed';

UPDATE PortfolioProject.dbo.airbnb2
SET host_identity_verified = 'verifying'
WHERE host_identity_verified IS NULL;

-- Let's recheck our data.
SELECT DISTINCT host_identity_verified
FROM PortfolioProject.dbo.airbnb2;
----------------------------------
-- After that, we will clean the country & country code table. As these locations are in New York and we are not going to join this table with any other tables of other places, we can just remove the country/country_code, or remove one of them. In this case we will remove one of them just to keep a record of the country of these properties. 
ALTER TABLE PortfolioProject.dbo.airbnb2
DROP COLUMN country_code;

-- And we noticed some missing values in the database, let's check it and fill NULL values with United States
SELECT DISTINCT country, COUNT(*) as count
FROM PortfolioProject.dbo.airbnb2
GROUP BY country;

UPDATE PortfolioProject.dbo.airbnb2
SET country = 'United States'
WHERE country IS NULL;

-- Duplicate the table
-- SELECT 
--   *
-- INTO PortfolioProject.dbo.airbnb1
-- FROM PortfolioProject.dbo.airbnb2

----------------------------------
-- Next let's check the 'instant_bookable' and 'cancellation_policy' columns
SELECT instant_bookable, cancellation_policy, COUNT(*)
FROM PortfolioProject.dbo.airbnb2
GROUP BY instant_bookable, cancellation_policy;
-- However, if we want to use these data to recheck with host about updating them, we list out these properties and send notification to hosts to update on these entries. 
SELECT * 
DELETE FROM PortfolioProject.dbo.airbnb2
WHERE instant_bookable IS NULL;
-- 105 rows was removed. 

-- Since the instant_bookable should have FALSE or TRUE values only, we do not have information about these NULL data, and the total number of them is not a lot (~ 100 records/100k we have), we would remove them. 
DELETE FROM PortfolioProject.dbo.airbnb2
WHERE instant_bookable IS NULL;
----------------------------------
-- Let's check room type
SELECT room_type, COUNT(*) as count
FROM PortfolioProject.dbo.airbnb2
GROUP BY room_type;
-- This looks clean.
----------------------------------
-- Next is contruction year. First we will rename the column.
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
EXECUTE sp_rename N'dbo.airbnb2.Construction_year', N'Tmp_construction_year_3', 'COLUMN' 
GO
EXECUTE sp_rename N'dbo.airbnb2.Tmp_construction_year_3', N'construction_year', 'COLUMN' 
GO
ALTER TABLE dbo.airbnb2 SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

---
SELECT construction_year, COUNT(*) AS count
FROM PortfolioProject.dbo.airbnb2
GROUP BY construction_year
ORDER BY construction_year DESC;

-- There is NULL values, we can understand it as constructed before 2003, yet the column data type is int, so we will return it to varchar, and update NULL values
ALTER TABLE PortfolioProject.dbo.airbnb2 ALTER COLUMN construction_year VARCHAR(max);  

UPDATE PortfolioProject.dbo.airbnb2
SET construction_year = '2002 or earlier'
WHERE construction_year IS NULL;
----------------------------------
-- Now price and service_fee are varchar, we want to convert it to int for further calculation. 
SELECT DISTINCT CHARINDEX('$',price)
FROM PortfolioProject.dbo.airbnb2

SELECT SUBSTRING(price, CHARINDEX('$',price)+1,len(price))
FROM PortfolioProject.dbo.airbnb2

-- We will create a new column with int value and convert old price values to this column and name this new_price
ALTER TABLE PortfolioProject.dbo.airbnb2
ADD new_price INT;

UPDATE a
SET a.new_price = b.price2
FROM PortfolioProject.dbo.airbnb2 AS a 
INNER JOIN 
(
	SELECT userkey,
			id, 
			CAST(REPLACE(TRIM(SUBSTRING(price, CHARINDEX('$',price)+1,len(price))),',','') AS INT) AS price2
	FROM PortfolioProject.dbo.airbnb2
) AS b
ON a.userkey = b.userkey AND a.id = b.id;

-- Recheck the data and drop the old price column
ALTER TABLE PortfolioProject.dbo.airbnb2
DROP COLUMN price;

-- Repeat all steps with service_fee column
ALTER TABLE PortfolioProject.dbo.airbnb2
ADD new_service_fee INT;

UPDATE a
SET a.new_service_fee = b.servicefee2
FROM PortfolioProject.dbo.airbnb2 AS a 
INNER JOIN 
(
	SELECT userkey,
			id, 
			CAST(REPLACE(TRIM(SUBSTRING(service_fee, CHARINDEX('$',service_fee)+1,len(service_fee))),',','') AS INT) AS servicefee2
	FROM PortfolioProject.dbo.airbnb2
) AS b
ON a.userkey = b.userkey AND a.id = b.id;

ALTER TABLE PortfolioProject.dbo.airbnb2
DROP COLUMN service_fee;

-- Lastly let's move new_price and service_fee to the previous position (before minimum_nights and after construction_year)
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_airbnb2
	(
	userkey int NOT NULL IDENTITY (1, 1),
	id bigint NULL,
	NAME varchar(MAX) NULL,
	host_id bigint NULL,
	host_identity_verified varchar(MAX) NULL,
	host_name varchar(MAX) NULL,
	neighbourhood_group varchar(MAX) NULL,
	neighbourhood varchar(MAX) NULL,
	lat float(53) NULL,
	long float(53) NULL,
	country varchar(MAX) NULL,
	instant_bookable varchar(MAX) NULL,
	cancellation_policy varchar(MAX) NULL,
	room_type varchar(MAX) NULL,
	construction_year varchar(MAX) NULL,
	new_price int NULL,
	new_service_fee int NULL,
	minimum_nights int NULL,
	number_of_reviews varchar(MAX) NULL,
	last_review date NULL,
	reviews_per_month float(53) NULL,
	review_rate_number int NULL,
	calculated_host_listings_count int NULL,
	availability_365 int NULL,
	house_rules varchar(MAX) NULL,
	license varchar(MAX) NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_airbnb2 SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_airbnb2 ON
GO
IF EXISTS(SELECT * FROM dbo.airbnb2)
	 EXEC('INSERT INTO dbo.Tmp_airbnb2 (userkey, id, NAME, host_id, host_identity_verified, host_name, neighbourhood_group, neighbourhood, lat, long, country, instant_bookable, cancellation_policy, room_type, construction_year, new_price, new_service_fee, minimum_nights, number_of_reviews, last_review, reviews_per_month, review_rate_number, calculated_host_listings_count, availability_365, house_rules, license)
		SELECT userkey, id, NAME, host_id, host_identity_verified, host_name, neighbourhood_group, neighbourhood, lat, long, country, instant_bookable, cancellation_policy, room_type, construction_year, new_price, new_service_fee, minimum_nights, number_of_reviews, last_review, reviews_per_month, review_rate_number, calculated_host_listings_count, availability_365, house_rules, license FROM dbo.airbnb2 WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_airbnb2 OFF
GO
DROP TABLE dbo.airbnb2
GO
EXECUTE sp_rename N'dbo.Tmp_airbnb2', N'airbnb2', 'OBJECT' 
GO
COMMIT

----------------------------------
-- Lastly, we want to look at the last_review date to see if the value is in right format
SELECT last_review,
		DAY(last_review) as day,
		MONTH(last_review) as month,
		YEAR(last_review) as year
FROM PortfolioProject.dbo.airbnb2

-- Everything looks fine. We should be good to grab up this exercise. 