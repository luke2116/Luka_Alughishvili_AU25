/* Task 1: Retrieve every Animation movie released in 2017-2019 with rental rate greater than 1.

Business Logic:
The marketing team needs this list to promote family friendly content.
We are using the dvdrental database.
Joins are: film - film_category - category.
Filters are: category = 'Animation', release_year BETWEEN 2017 AND 2019, rental_rate > 1.
following columns will be displayed: title, release_year and rental_rate.
The results will be sorted alphabeticlly by title.
*/


-----------------------------------------------------------------
-- Using CTE
WITH animation_movies AS (
    SELECT f.title,
        f.release_year,
        f.rental_rate
    FROM public.film AS f
    -- Join film to film_category to get category relationships
    INNER JOIN public.film_category AS fc ON f.film_id = fc.film_id
    -- Join for identifying only Animation movies
    INNER JOIN public.category AS c ON fc.category_id = c.category_id
    --Filtering: Category, date and rating
    WHERE c.name = 'Animation'
      AND f.release_year BETWEEN 2017 AND 2019
      AND f.rental_rate > 1                      
)
SELECT *
FROM animation_movies
ORDER BY title;

-----------------------------------------------------------------
-- Using Subquery. We first identify all Animation films and then filter the main film table
SELECT f.title,
    f.release_year,
    f.rental_rate
FROM public.film  AS f
WHERE f.film_id IN (
-- Identifying all Animation movies
    SELECT fc.film_id
    FROM public.film_category AS fc
    INNER JOIN public.category As c ON fc.category_id = c.category_id
    WHERE c.name = 'Animation'  
)
--Filtering:date and rating
AND f.release_year BETWEEN 2017 AND 2019 
AND f.rental_rate > 1
ORDER BY f.title ;

-----------------------------------------------------------------
-- Using  joins
SELECT f.title,
    f.release_year,
    f.rental_rate
FROM public.film AS f
INNER JOIN public.film_category As fc ON f.film_id = fc.film_id
INNER JOIN public.category AS c ON fc.category_id = c.category_id
WHERE c.name = 'Animation'                   
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
ORDER BY f.title;




-----------------------------------------------------------------
/*
Task 2 part1: Show 3 employees which generated the most revenue in 2017.

Business Logic:
HR wants to find the best performing employees by total payment amount in 2017.
staff member could have worked in more than 1 stores.
We are using the dvdrental database.
Tables staff, store and payment are used.
Only payments made in 2017.
Output columns are first_name, last_name, store_id, total_revenue.
- Sort by total_revenue DESC, limit 3.
*/


-----------------------------------------------------------------
-- Usig CTE 

-- Calculating each staff member's total revenue in 2017
WITH staff_revenue AS (
    SELECT p.staff_id,
        DATE_PART('year', p.payment_date) AS payment_year,
        SUM(p.amount) AS total_revenue 
    FROM public.payment AS p
    WHERE p.payment_date >= '2017-01-01'
  AND p.payment_date < '2018-01-01'
    GROUP BY p.staff_id, payment_year
),

--Finding the (last store for each staff member
last_store AS (
    SELECT DISTINCT ON (p.staff_id)
        p.staff_id,
        s.store_id
    FROM public.payment As p
    INNER JOIN public.staff AS s ON p.staff_id = s.staff_id
    WHERE p.payment_date >= '2017-01-01'
  		AND p.payment_date < '2018-01-01'

    ORDER BY p.staff_id, p.payment_date DESC
)

--Combine both results and displaying the top 3 staff by total revenue
SELECT 
    st.first_name,
    st.last_name,
    ls.store_id,
    sr.total_revenue
FROM staff_revenue AS sr
INNER JOIN public.staff AS st ON sr.staff_id = st.staff_id
INNER JOIN last_store AS ls ON sr.staff_id = ls.staff_id
ORDER BY sr.total_revenue DESC
LIMIT 3;


-----------------------------------------------------------------
--Using subquery 
--Finding every staff member who had payments in 2017
SELECT 
    s.first_name,
    s.last_name,

    -- Finding the last store where each staff member worked based on the latest payment
    (
        SELECT st.store_id
        FROM public.payment AS p2
        INNER JOIN public.staff AS st ON p2.staff_id = st.staff_id
		WHERE p2.staff_id = s.staff_id
  			AND p2.payment_date >= '2017-01-01'
  			AND p2.payment_date < '2018-01-01'

        ORDER BY p2.payment_date DESC     -- Get the most recent store
        LIMIT 1
    ) AS store_id,

    -- Step 3: Calculate total revenue per staff for 2017
    (
        SELECT SUM(p3.amount)
        FROM public.payment AS p3
        WHERE p3.staff_id = s.staff_id
  			AND p3.payment_date >= '2017-01-01'
  			AND p3.payment_date < '2018-01-01'

    ) AS total_revenue

FROM public.staff AS s
WHERE s.staff_id IN (
    SELECT DISTINCT p.staff_id
    FROM public.payment AS p
    WHERE p.payment_date >= '2017-01-01'
  		AND p.payment_date < '2018-01-01'

)
ORDER BY total_revenue DESC
LIMIT 3;




-----------------------------------------------------------------
-- Using joins

SELECT
    st.first_name,
    st.last_name,
    st.store_id,
    SUM(p.amount) AS total_revenue
-- Join to link staff and their payments
FROM public.staff AS st
INNER JOIN public.payment AS p
    ON st.staff_id = p.staff_id
WHERE
    p.payment_date >= '2017-01-01'
    AND p.payment_date < '2018-01-01'
GROUP BY
    st.staff_id, st.first_name, st.last_name, st.store_id
ORDER BY
    total_revenue DESC
LIMIT 3;


-----------------------------------------------------------------
/*
Task 2 Part2: We havbe to identify 5 most rented movies
and determine the expected audience age group using the
given film rating system.

Business Logic:
Identify the top 5 films by rental numbers.
We are using tables: film, inventory, rental.
Jons are: inventory - film.
Each film has a rating (G, PG, PG-13, R, NC-17).
Output columns: film_title, rental_count, rating, expected_audience_age_group
Sorted by rental_count DESC and limited to 5.
*/
-----------------------------------------------------------------

--Using CCTE

-- Count rentals per film
WITH film_rentals AS (
    SELECT 
        f.film_id,
        f.title AS film_title,
        f.rating,
        COUNT(r.rental_id) AS rental_count
    FROM public.film AS f
    INNER JOIN public.inventory AS i ON f.film_id = i.film_id
    INNER JOIN public.rental AS r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.title, f.rating
)

-- Step 2: Adding age group mapping and pick the top 5
SELECT 
    fr.film_title,
    fr.rating,
    fr.rental_count,
    CASE fr.rating
        WHEN 'G' THEN 'All Ages'
        WHEN 'PG' THEN 'Children 8 +'
        WHEN 'PG-13' THEN 'Teens 13 +'
        WHEN 'R' THEN 'Adults 17 +'
        WHEN 'NC-17' THEN 'Adults Only 18 +'
        ELSE 'Unknown'
    END AS AudienceAgeGroup
FROM film_rentals AS fr
ORDER BY fr.rental_count DESC
LIMIT 5;

-----------------------------------------------------------------
--Using subquery
SELECT
    fr.film_title,
    fr.rating,
    fr.rental_count,
    CASE fr.rating
       WHEN 'G' THEN 'All Ages'
        WHEN 'PG' THEN 'Children 8 +'
        WHEN 'PG-13' THEN 'Teens 13 +'
        WHEN 'R' THEN 'Adults 17 +'
        WHEN 'NC-17' THEN 'Adults Only 18 +'
        ELSE 'Unknown'
    END AS AudienceAgeGroup
FROM (
    SELECT 
        f.film_id,
        f.title AS film_title,
        f.rating,
        COUNT(r.rental_id) AS rental_count
    FROM public.film AS f
    INNER JOIN public.inventory AS i ON f.film_id = i.film_id
    INNER JOIN public.rental AS r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.title, f.rating
) AS fr
ORDER BY fr.rental_count DESC
LIMIT 5;

-----------------------------------------------------------------
--Using Joins
SELECT
    f.title AS film_title,
    f.rating,
    COUNT(r.rental_id) AS rental_count,
    CASE f.rating
       WHEN 'G' THEN 'All Ages'
        WHEN 'PG' THEN 'Children 8 +'
        WHEN 'PG-13' THEN 'Teens 13 +'
        WHEN 'R' THEN 'Adults 17 +'
        WHEN 'NC-17' THEN 'Adults Only 18 +'
        ELSE 'Unknown'
    END AS AudienceAgeGroup
FROM public.film AS f
INNER JOIN public.inventory AS i ON f.film_id = i.film_id
INNER JOIN public.rental AS r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;



-----------------------------------------------------------------
/*
Task 3: Identify which actors or actresses had long inactivity periods compared to others.

Business Logic:
The stores marketing team wants to analyze actors inactivity to identify:
Those who had notable breaks in their acting careers for comeback campaigns.
Those who were consistently active for promotions.

We interpret this in two  analytical ways:

V1: Find the gap between each actor's latest movie release year and 2025.

V2: Find the longest gap between sequential film release years per actor
(to show which actors had the biggest break between two roles).

*/
-----------------------------------------------------------------

/*
V1: Gap between latest release year and current year per actor.
Goal: Find how long it has been since each actor last appeared in a movie.
*/

-----------------------------------------------------------------
--Using cte
WITH actor_last_film AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS last_movie_year          
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    first_name,
    last_name,
    last_movie_year,
    -- Gap between current year and last movie
    (2025 - last_movie_year) AS years_inactive          
FROM actor_last_film
-- Longest inactivity first
ORDER BY years_inactive DESC;     


-----------------------------------------------------------------
--Using subquery
SELECT 
    a.first_name,
    a.last_name,
    --find the latest release year for this actor
    (
        SELECT MAX(f.release_year)
        FROM public.film AS f
        INNER JOIN public.film_actor AS fa ON f.film_id = fa.film_id
        WHERE fa.actor_id = a.actor_id
    ) AS last_movie_year,
    --calculate inactivity period from that last movie
    (2025 - (
        SELECT MAX(f.release_year)
        FROM public.film AS f
        INNER JOIN public.film_actor AS fa ON f.film_id = fa.film_id
        WHERE fa.actor_id = a.actor_id
    )) AS years_inactive
FROM public.actor AS a
ORDER BY years_inactive DESC;

-----------------------------------------------------------------
--Using Joins
SELECT 
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS last_movie_year,
    (2025 - MAX(f.release_year)) AS years_inactive
FROM public.actor AS a
INNER JOIN public.film_actor AS fa ON a.actor_id = fa.actor_id
INNER JOIN public.film AS f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_inactive DESC;


-----------------------------------------------------------------
/*
V2: Longest gap between sequential films of actor.
We need to find actors who had the biggest career breaks between any two films.
*/
-----------------------------------------------------------------

/*
cte: Find longest inactivity gap per actor
Logic: For each actor, calculate the difference between the earliest and latest film release years.
Assumption: The longest inactivity gap equals MAX(release_year) - MIN(release_year).
*/

WITH actor_years AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        MIN(f.release_year)::int AS first_movie_year, 
        MAX(f.release_year)::int AS last_movie_year
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa 
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f 
        ON fa.film_id = f.film_id
    WHERE f.release_year IS NOT NULL
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    first_name,
    last_name,
    (last_movie_year - first_movie_year) AS longest_gap_years
FROM actor_years
ORDER BY longest_gap_years DESC;



-----------------------------------------------------------------
/*
joins: Find longest inactivity gap per actor
Logic identical to CTE, but written in a single grouped query.
*/

SELECT 
    a.first_name,
    a.last_name,
    (MAX(f.release_year)::int - MIN(f.release_year)::int) AS longest_gap_years
FROM public.actor AS a
INNER JOIN public.film_actor AS fa 
    ON a.actor_id = fa.actor_id
INNER JOIN public.film AS f 
    ON fa.film_id = f.film_id
WHERE f.release_year IS NOT NULL
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY longest_gap_years DESC;


/*
Subquery: Find longest inactivity gap per actor
Logic identical to CTE and JOIN, but calculated per actor using a correlated subquery.
*/

SELECT 
    a.first_name,
    a.last_name,
    (
        SELECT 
            MAX(f.release_year)::int - MIN(f.release_year)::int
        FROM public.film_actor AS fa
        INNER JOIN public.film AS f 
            ON fa.film_id = f.film_id
        WHERE fa.actor_id = a.actor_id
          AND f.release_year IS NOT NULL
    ) AS longest_gap_years
FROM public.actor AS a
ORDER BY longest_gap_years DESC;

/* Subquery version gives different output from cte and joins.
I think it is because of the way program executes the subquery separately for each actor
since it runs the calculation one actor at a time it might handle data differently in each run.
The cte and join versions process all actors together in one grouped calculation and i think it results in consistent logic and produces matching results. 
*/






















































