USE Hospitality;
SELECT * FROM Datee;
SELECT * FROM Hotels;
SELECT * FROM Rooms;
SELECT * FROM [Aggregated Bookings];
SELECT * FROM Bookings;

--Which Hotel is doing the best business?
SELECT h.property_name,SUM(b.revenue_realized) AS realized_revenue
FROM Hotels h
JOIN Bookings b
ON h.property_id=b.property_id
GROUP BY h.property_name
ORDER BY realized_revenue DESC;


--Which hotel has the most customers
SELECT h.property_id,h.property_name,h.category,h.city,SUM(b.no_guests) AS total_guests
FROM hotels h
JOIN Bookings b
ON h.property_id=b.property_id
WHERE b.booking_status='Checked Out'
GROUP BY h.property_id,h.property_name,h.category,h.city
ORDER BY total_guests DESC;

--Which hotel has the most number of customer city and category wise
SELECT h.city,h.category,h.city,SUM(b.no_guests) AS total_guests
FROM hotels h
JOIN Bookings b
ON h.property_id=b.property_id
WHERE b.booking_status='Checked Out'
GROUP BY h.city,h.category
ORDER BY total_guests DESC;


--Which booking platform is used most by the customers for booking
SELECT booking_platform, COUNT(booking_id) as total_bookings
FROM Bookings
GROUP BY booking_platform
ORDER BY total_bookings DESC;


--Calculate the cancellation rate of each booking platform

with cte as
(
SELECT booking_platform,COUNT(booking_id) as total_bookings,
SUM(CASE
	WHEN booking_status='Cancelled' THEN 1
	ELSE 0
	END) AS cancellation
FROM Bookings
GROUP BY booking_platform
)
SELECT booking_platform,ROUND((CAST(cancellation as float)/total_bookings)*100,2) AS cancellation_rate
FROM cte;
--FINDINGS: HERE WE CAN FIND THAT EVERY PLATFORM AS EQUAL PERCENTAGE OF CANCELLATION RATE THAT IS ~25%


-- Find out the monthwise number of guests of each hotels
SELECT h.property_name,DATENAME(month,b.check_in_date) as monthh,SUM(b.no_guests) as no_of_guests
FROM Hotels h
JOIN Bookings b
ON h.property_id=b.property_id
WHERE b.booking_status != 'Cancelled'
GROUP BY h.property_name,DATENAME(month,b.check_in_date),MONTH(b.check_in_date)
ORDER BY h.property_name,MONTH(b.check_in_date)


--Find out the percentage change in the number of guests in each month in each hotel
with cte as
(
SELECT h.property_name,DATENAME(month,b.check_in_date) as monthh,MONTH(b.check_in_date) as month_no,SUM(b.no_guests) as no_of_guests,
LAG(SUM(b.no_guests)) OVER(PARTITION BY property_name ORDER BY MONTH(b.check_in_date)) as pre_month
FROM Hotels h
JOIN Bookings b
ON h.property_id=b.property_id
WHERE b.booking_status != 'Cancelled'
GROUP BY h.property_name,DATENAME(month,b.check_in_date),MONTH(b.check_in_date)
)
SELECT property_name,monthh,ROUND(((no_of_guests-pre_month)/(pre_month))*100,2)
FROM cte;
--FINDINGS: IN JUNE ALMOST EVERY HOTELS HAS NEGATIVE GROWTH WHICH SHOWS THAT JUNE IS NOT GOOD MONTH IN TOURISM


--Which class of room is most prefered by guests in each of the hotels
SELECT TOP 7 h.property_name,b.room_category,r.room_class,SUM(b.no_guests) as total_guests,
ROW_NUMBER() OVER(PARTITION BY property_name ORDER BY SUM(b.no_guests) DESC) as rnk
FROM Hotels h
JOIN Bookings b
ON h.property_id=b.property_id
JOIN Rooms r
ON b.room_category=r.room_id
GROUP BY h.property_name,b.room_category,r.room_class
ORDER BY ROW_NUMBER() OVER(PARTITION BY property_name ORDER BY SUM(b.no_guests) DESC);


--Calculate the maximum,minimum and average days guests stay in each hotels and find out which hotels has the best average stay

with cte as
(
SELECT h.property_name,h.city,b.booking_id,DATEDIFF(day,b.check_in_date,b.checkout_date) as stay_days,b.no_guests
FROM Hotels h
JOIN Bookings b
ON h.property_id=b.property_id
WHERE b.booking_status ='Checked Out'
)

SELECT property_name,MAX(stay_days) as maxi,MIN(stay_days) as mini,AVG(stay_days) as average
FROM cte
GROUP BY property_name;

--Breakdown of total guests and revenue of each hotels in each city per month
SELECT h.property_id,h.property_name,h.city,DATENAME(month,b.check_in_date) as mnth,SUM(b.no_guests) as total_guests,SUM(b.revenue_realized) AS total_revenue
FROM hotels h
JOIN Bookings b
ON h.property_id=b.property_id
GROUP BY h.property_id,h.property_name,h.city,MONTH(b.check_in_date),DATENAME(month,b.check_in_date)
ORDER BY h.property_name,h.city,MONTH(b.check_in_date)


--Calculate the average stay of guests per month in each hotel
SELECT h.property_id,h.property_name,DATENAME(month,b.check_in_date) as mnth,
AVG(DATEDIFF(day,b.check_in_date,b.checkout_date)) as total_stays,ROUND(AVG(no_guests),0) as guests
FROM hotels h
JOIN bookings b
ON h.property_id=b.property_id
WHERE b.booking_status='Checked Out'
GROUP BY h.property_id,h.property_name,DATENAME(month,b.check_in_date),MONTH(b.check_in_date)
ORDER BY h.property_id,h.property_name,MONTH(b.check_in_date)


--What is the average rating of  each hotels
SELECT h.property_id,h.property_name,h.city,ROUND(AVG(b.ratings_given),2) AS ratings
FROM hotels h
JOIN bookings b
ON h.property_id=b.property_id
WHERE b.ratings_given IS NOT NULL
GROUP BY h.property_id,h.property_name,h.city
ORDER BY ratings DESC;


--Revenue realized on each hotels on the basis of booking platform
with cte as
(
SELECT h.property_name,h.city,b.booking_platform,ROUND(AVG((b.revenue_realized/b.no_guests)),2) as revenue_per_person,
ROW_NUMBER() OVER(PARTITION BY h.property_name,h.city ORDER BY AVG(ROUND((b.revenue_realized/b.no_guests),2)) DESC) as rnk
FROM hotels h
JOIN bookings b
ON h.property_id=b.property_id
GROUP BY h.property_name,h.city,b.booking_platform
)
SELECT *
FROM cte
WHERE rnk IN (1,2,3);


--Which category hotels does the best business monthly?
SELECT h.category,DATENAME(month,b.check_in_date) as mnth,SUM(b.no_guests) as total_guests,SUM(b.revenue_realized) as total_revenue
FROM hotels h
JOIN bookings b
ON h.property_id=b.property_id
GROUP BY h.category,MONTH(b.check_in_date),DATENAME(month,b.check_in_date)
ORDER BY MONTH(b.check_in_date),SUM(b.revenue_realized) DESC;


--Platform generating the best revenue_realized rate
SELECT b.booking_platform,ROUND(AVG((b.revenue_realized/b.revenue_generated)*100),2)
FROM hotels h
JOIN bookings b
ON h.property_id=b.property_id
GROUP BY b.booking_platform;