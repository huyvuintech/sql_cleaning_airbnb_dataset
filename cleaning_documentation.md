This documentation is made to record steps taken to clean the raw data. 

* Change column data types:
	+ id to bigint
	+ host_id to bigint
	+ Construction_year to int
	+ minimum_nights to int
	+ reviews_per_month to float
	+ review_rate_number to int
	+ calculated_host_listing_counts to int
	+ availability_365 to int
* Remove duplicates in id (-541 values was removed) 
* Update values in host_identity_verified
	+ 'NULL' to 'verifying'
	+ 'unconfirmed' to 'unverified'
* Remove column country_code
* Update values in country from 'NULL' to 'United States'
* Remove rows with 'NULL' value in column instant_bookable
* Rename column Construction_year to construction_year
* Change construction_year data type to varchar
* Update values in construction_year from 'NULL' to '2002 or earlier'
* Paste numeric values from column price to column new price
* Remove column price
* Paste numeric values from column service_fee to column new_service_fee
* Remove column service_fee
