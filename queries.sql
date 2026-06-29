--1.Most Booked Neighbourhood
SELECT 
	neighbourhood,
	neighbourhood_group,
	COUNT(number_of_reviews) AS bookings
FROM AB_NYC_2019
GROUP BY neighbourhood
ORDER BY bookings DESC
LIMIT 10;

--2.Average Price per Room Type
SELECT
	room_type,
	ROUND(AVG(price),2) as average_room_price
FROM AB_NYC_2019
GROUP BY room_type
ORDER BY average_room_price;

--3.Price Tier Segmentation
SELECT 
    CASE
        WHEN price < 75  THEN 'Budget'
        WHEN price < 150 THEN 'Mid-Range'
        WHEN price < 300 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_tier,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price
FROM AB_NYC_2019
WHERE price > 0
GROUP BY price_tier
ORDER BY avg_price;

--4.Top 20 Hosts with most Listings
SELECT
	host_id,
	host_name,
	COUNT(*) AS listings_count
FROM AB_NYC_2019
GROUP BY host_id
ORDER BY listings_count DESC
LIMIT 20;

--5.Total Reviews by Borough
WITH borough_reviews AS (
	SELECT
		neighbourhood_group AS borough,
		SUM(number_of_reviews) AS total_reviews
	FROM AB_NYC_2019
	GROUP BY neighbourhood_group
	)
SELECT
	borough,
	total_reviews,
	ROUND(100.0 * total_reviews / SUM(total_reviews) OVER (), 1) AS pct_of_total
FROM borough_reviews
ORDER BY total_reviews DESC;

--6.High Price, Low Reviews (overpriced risk flags)
SELECT
	id,
	name,
	price,
	number_of_reviews,
	neighbourhood
FROM AB_NYC_2019
WHERE price > 300
	AND number_of_reviews BETWEEN 1 AND 4
ORDER BY number_of_reviews, price DESC;

--7.Overprice Listings as per Neighbourhood Average Price
WITH neighbourhood_avg AS (
    SELECT neighbourhood,
           ROUND(AVG(price), 2) AS avg_neighbourhood_price
    FROM AB_NYC_2019
    WHERE price > 0
    GROUP BY neighbourhood
)
SELECT l.id,
       l.name,
       l.neighbourhood,
       l.price,
       n.avg_neighbourhood_price,
       ROUND(l.price - n.avg_neighbourhood_price, 2) AS price_vs_avg
FROM AB_NYC_2019 l
JOIN neighbourhood_avg n ON l.neighbourhood = n.neighbourhood
ORDER BY price_vs_avg DESC
LIMIT 20;

--8.Listing with no recent reviews
SELECT
       name,
       room_type,
       last_review,
       number_of_reviews,
       ROUND(JULIANDAY('2019-12-31') - JULIANDAY(last_review)) AS days_since_review
FROM AB_NYC_2019
WHERE last_review IS NOT NULL
  AND JULIANDAY('2019-12-31') - JULIANDAY(last_review) > 365
ORDER BY days_since_review DESC
LIMIT 20;

--9.Neighbourhood ranking by avg price within each borough 
WITH neighbourhood_pricing AS (
    SELECT neighbourhood_group AS borough,
           neighbourhood,
           ROUND(AVG(price), 2) AS avg_price,
           COUNT(*) AS listing_count
    FROM AB_NYC_2019
    WHERE price > 0
    GROUP BY neighbourhood_group, neighbourhood
    HAVING COUNT(*) >= 10
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY borough ORDER BY avg_price DESC) AS price_rank
    FROM neighbourhood_pricing
)
SELECT borough, neighbourhood, avg_price, listing_count, price_rank
FROM ranked
WHERE price_rank <= 5
ORDER BY borough, price_rank;

--10.String functions: host name audit
SELECT 
	host_id,
	host_name,
	LENGTH(host_name) AS name_length,
	UPPER(host_name) AS name_upper,
		CASE
			WHEN LENGTH(host_name) <= 3 THEN 'Flag - unusually short'
			ELSE 'OK'
		END AS name_flag
FROM AB_NYC_2019
GROUP BY host_id, host_name
ORDER BY name_length ASC
LIMIT 30;