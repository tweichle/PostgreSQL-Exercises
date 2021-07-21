/*** Simple SQL Queries ***/
-- https://pgexercises.com/questions/basic/

/Users/yangweichle/Desktop/schema-horizontal.svg

https://pgexercises.com/img/schema-horizontal.svg


/* Retrieve everything from a table

Question: How can you retrieve all the information from the cd.facilities table? */

SELECT * FROM cd.facilities;


/* Retrieve specific columns from a table

Question: You want to print out a list of all of the facilities and their cost to members. How would you retrieve a list of only facility names and costs? */

SELECT name,
       membercost
  FROM cd.facilities;


/* Control which rows are retrieved

Question: How can you produce a list of facilities that charge a fee to members? */

SELECT *
  FROM cd.facilities
  WHERE membercost > 0;


/* Control which rows are retrieved - part 2

Question: How can you produce a list of facilities that charge a fee to members, and that fee is less than 1/50th of the monthly maintenance cost? Return the facid, facility name, member cost, and monthly maintenance of the facilities in question. */

SELECT facid,
       name,
	   membercost,
	   monthlymaintenance
  FROM cd.facilities
  WHERE membercost > 0 
    AND (membercost < monthlymaintenance/50.0);


/* Basic string searches

Question: How can you produce a list of all facilities with the word 'Tennis' in their name? */

SELECT *
  FROM cd.facilities
  WHERE name LIKE '%Tennis%';


/* Matching against multiple possible values

Question: How can you retrieve the details of facilities with ID 1 and 5? Try to do it without using the OR operator. */

SELECT *
  FROM cd.facilities
  WHERE facid IN (1, 5);


/* Classify results into buckets

Question: How can you produce a list of facilities, with each labelled as 'cheap' or 'expensive' depending on if their monthly maintenance cost is more than $100? Return the name and monthly maintenance of the facilities in question. */

SELECT name,
       CASE WHEN monthlymaintenance > 100 THEN 'expensive'
            ELSE 'cheap' END AS cost
  FROM cd.facilities;


/* Working with dates

Question: How can you produce a list of members who joined after the start of September 2012? Return the memid, surname, firstname, and joindate of the members in question. */

SELECT memid,
       surname,
       firstname,
       joindate
  FROM cd.members
  WHERE joindate >= '2012-09-01'; /* same as '2012-09-01 00:00:00' */


/* Removing duplicates, and ordering results

Question: How can you produce an ordered list of the first 10 surnames in the members table? The list must not contain duplicates. */

SELECT DISTINCT surname
  FROM cd.members
  ORDER BY surname
  LIMIT 10;


/* Combining results from multiple queries

Question: You, for some reason, want a combined list of all surnames and all facility names. Yes, this is a contrived example :-). Produce that list! */

SELECT DISTINCT surname
  FROM cd.members
UNION ALL
SELECT DISTINCT name AS surname
  FROM cd.facilities;

SELECT surname
  FROM cd.members
UNION
SELECT name AS surname
  FROM cd.facilities;


/* Simple aggregation

Question: You'd like to get the signup date of your last member. How can you retrieve this information? */

SELECT MAX(joindate) AS latest
  FROM cd.members;


/* More aggregation

Question: You'd like to get the first and last name of the last member(s) who signed up - not just the date. How can you do that? */

SELECT firstname,
       surname,
       joindate
  FROM cd.members
  WHERE joindate = (SELECT MAX(joindate)
		     FROM cd.members);

SELECT firstname,
       surname,
       joindate
  FROM cd.members
  ORDER BY joindate
  LIMIT 1; /* Note that this approach does not cover the extremely unlikely event of two people joining at the exact same time */



/*** Joins and Subqueries ***/
-- https://pgexercises.com/questions/joins/

/Users/yangweichle/Desktop/schema-horizontal.svg

https://pgexercises.com/img/schema-horizontal.svg


/* Retrieve the start times of members' bookings

Question: How can you produce a list of the start times for bookings by members named 'David Farrell'? */

SELECT b.starttime
  FROM cd.members AS m
  INNER JOIN cd.bookings AS b
    ON m.memid = b.memid
  WHERE m.firstname = 'David' AND m.surname = 'Farrell';

SELECT b.starttime
  FROM cd.members AS m
  INNER JOIN cd.bookings AS b
    ON m.memid = b.memid
  WHERE CONCAT(m.firstname, ' ', m.surname) = 'David Farrell';


/* Work out the start times of bookings for tennis courts

Question: How can you produce a list of the start times for bookings for tennis courts, for the date '2012-09-21'? Return a list of start time and facility name pairings, ordered by the time. */

SELECT b.starttime AS start,
       f.name
  FROM cd.bookings AS b
  INNER JOIN cd.facilities AS f
    ON b.facid = f.facid
  WHERE f.name LIKE '%Tennis Court%' /* alternative: f.name in ('Tennis Court 2', 'Tennis Court 1') */
    AND b.starttime >= '2012-09-21' AND b.starttime < '2012-09-22'
  ORDER BY b.starttime;


/* Produce a list of all members who have recommended another member

Question: How can you output a list of all members who have recommended another member? Ensure that there are no duplicates in the list, and that results are ordered by (surname, firstname). */

SELECT DISTINCT rec.firstname,
       rec.surname
  FROM cd.members AS m
  INNER JOIN cd.members AS rec
    ON m.recommendedby = rec.memid
  ORDER BY rec.surname, 
           rec.firstname;


/* Produce a list of all members, along with their recommender

Question: How can you output a list of all members, including the individual who recommended them (if any)? Ensure that results are ordered by (surname, firstname). */

SELECT m.firstname AS memfname,
       m.surname AS memsname,
       rec.firstname AS recfname,
       rec.surname AS recsname
  FROM cd.members AS m
  LEFT JOIN cd.members AS rec
    ON m.recommendedby = rec.memid
  ORDER BY m.surname, 
           m.firstname;

SELECT m.firstname AS memfname,
       m.surname AS memsname,
       rec.firstname AS recfname,
       rec.surname AS recsname
  FROM cd.members AS m
  LEFT JOIN cd.members AS rec
    ON m.recommendedby = rec.memid
  ORDER BY memsname, /* Note: Aliases can be used in ORDER BY */
           memfname;


*/ Produce a list of all members who have used a tennis court

Question: How can you produce a list of all members who have used a tennis court? Include in your output the name of the court, and the name of the member formatted as a single column. Ensure no duplicate data, and order by the member name followed by the facility name. /*

SELECT DISTINCT CONCAT(m.firstname, ' ', m.surname) AS member, /* Note: Can concatenate strings using m.firstname || ' ' || m.surname as member */
       f.name AS facility
  FROM cd.members AS m
  INNER JOIN cd.bookings AS b
    ON m.memid = b.memid
  INNER JOIN cd.facilities AS f
    ON b.facid = f.facid
  WHERE f.name LIKE '%Tennis Court%'
  ORDER BY member,
           facility;


/* Produce a list of costly bookings

Question: How can you produce a list of bookings on the day of 2012-09-14 which will cost the member (or guest) more than $30? Remember that guests have different costs to members (the listed costs are per half-hour 'slot'), and the guest user is always ID 0. Include in your output the name of the facility, the name of the member formatted as a single column, and the cost. Order by descending cost, and do not use any subqueries. */

SELECT CONCAT(m.firstname, ' ', m.surname) AS member,
       f.name AS facility,
       CASE WHEN m.memid = 0 THEN b.slots*f.guestcost
            ELSE b.slots*f.membercost END AS cost
  FROM cd.members AS m
  INNER JOIN cd.bookings AS b
    ON m.memid = b.memid
  INNER JOIN cd.facilities AS f
    ON b.facid = f.facid
  WHERE b.starttime >= '2012-09-14' AND b.starttime < '2012-09-15'
    AND ((m.memid != 0 AND b.slots*f.membercost > 30) OR 
		(m.memid = 0 AND b.slots*f.guestcost > 30))
  ORDER BY cost DESC;


/* Produce a list of all members, along with their recommender, using no joins.

Question: How can you output a list of all members, including the individual who recommended them (if any), without using any joins? Ensure that there are no duplicates in the list, and that each firstname + surname pairing is formatted as a column and ordered. */

SELECT DISTINCT CONCAT(m.firstname, ' ', m.surname) AS member,
       (SELECT CONCAT(rec.firstname, ' ', rec.surname) AS recommender
          FROM cd.members AS rec
          WHERE rec.memid = m.recommendedby)
  FROM cd.members AS m
  ORDER BY member;


/* Produce a list of costly bookings, using a subquery

Question: The Produce a list of costly bookings exercise contained some messy logic: we had to calculate the booking cost in both the WHERE clause and the CASE statement. Try to simplify this calculation using subqueries. For reference, the question was:
How can you produce a list of bookings on the day of 2012-09-14 which will cost the member (or guest) more than $30? Remember that guests have different costs to members (the listed costs are per half-hour 'slot'), and the guest user is always ID 0. Include in your output the name of the facility, the name of the member formatted as a single column, and the cost. Order by descending cost. */

SELECT c.member, 
       c.facility, 
       c.cost
  FROM (SELECT CONCAT(m.firstname, ' ', m.surname) AS member,
               f.name AS facility,
               CASE WHEN m.memid = 0 THEN b.slots*f.guestcost
                    ELSE b.slots*f.membercost END AS cost
  
          FROM cd.members AS m
          INNER JOIN cd.bookings AS b
            ON m.memid = b.memid
          INNER JOIN cd.facilities AS f
            ON b.facid = f.facid
          WHERE b.starttime >= '2012-09-14' AND b.starttime < '2012-09-15') AS c
  WHERE c.cost > 30
  ORDER BY c.cost DESC;



/*** Modifying data ***/
-- https://pgexercises.com/questions/updates/

/Users/yangweichle/Desktop/schema-horizontal.svg

https://pgexercises.com/img/schema-horizontal.svg


/* Insert some data into a table

Question: The club is adding a new facility - a spa. We need to add it into the facilities table. Use the following values:

facid: 9, Name: 'Spa', membercost: 20, guestcost: 30, initialoutlay: 100000, monthlymaintenance: 800. */

INSERT INTO cd.facilities (facid, name, membercost, guestcost, initialoutlay, monthlymaintenance)
VALUES (9, 'Spa', 20, 30, 100000, 800);


/* Insert multiple rows of data into a table

Question: In the previous exercise, you learned how to add a facility. Now you're going to add multiple facilities in one command. Use the following values:

facid: 9, Name: 'Spa', membercost: 20, guestcost: 30, initialoutlay: 100000, monthlymaintenance: 800.
facid: 10, Name: 'Squash Court 2', membercost: 3.5, guestcost: 17.5, initialoutlay: 5000, monthlymaintenance: 80. */

INSERT INTO cd.facilities (facid, name, membercost, guestcost, initialoutlay, monthlymaintenance)
VALUES (9, 'Spa', 20, 30, 100000, 800),
       (10, 'Squash Court 2', 3.5, 17.5, 5000, 80);

INSERT INTO cd.facilities (facid, name, membercost, guestcost, initialoutlay, monthlymaintenance)
SELECT 9, 'Spa', 20, 30, 100000, 800
  UNION ALL
SELECT 10, 'Squash Court 2', 3.5, 17.5, 5000, 80;


/* Insert calculated data into a table

Question: Let's try adding the spa to the facilities table again. This time, though, we want to automatically generate the value for the next facid, rather than specifying it as a constant. Use the following values for everything else:

Name: 'Spa', membercost: 20, guestcost: 30, initialoutlay: 100000, monthlymaintenance: 800. */

INSERT INTO cd.facilities (facid, name, membercost, guestcost, initialoutlay, monthlymaintenance)
SELECT (SELECT MAX(facid) FROM cd.facilities)+1, 'Spa', 20, 30, 100000, 800;  


/* Update some existing data

Question: We made a mistake when entering the data for the second tennis court. The initial outlay was 10000 rather than 8000: you need to alter the data to fix the error. */

UPDATE cd.facilities
  SET initialoutlay = 10000
  WHERE facid = 1;


/* Update multiple rows and columns at the same time

Question: We want to increase the price of the tennis courts for both members and guests. Update the costs to be 6 for members, and 30 for guests. */

UPDATE cd.facilities
  SET membercost = 6,
      guestcost = 30
  WHERE name LIKE '%Tennis Court%';

UPDATE cd.facilities
  SET membercost = 6,
      guestcost = 30
  WHERE facid IN (0, 1);


/* Update a row based on the contents of another row

Question: We want to alter the price of the second tennis court so that it costs 10% more than the first one. Try to do this without using constant values for the prices, so that we can reuse the statement if we want to. */

UPDATE cd.facilities
  SET membercost = (SELECT membercost*1.1 FROM cd.facilities WHERE facid = 0),
      guestcost = (SELECT guestcost*1.1 FROM cd.facilities WHERE facid = 0)
  WHERE facid = 1;


/* Delete all bookings

Question: As part of a clearout of our database, we want to delete all bookings from the cd.bookings table. How can we accomplish this? */

DELETE FROM cd.bookings;


/* Delete a member from the cd.members table

Question: We want to remove member 37, who has never made a booking, from our database. How can we achieve that? */

DELETE FROM cd.members
  WHERE memid = 37;


/* Delete based on a subquery

Question: In our previous exercises, we deleted a specific member who had never made a booking. How can we make that more general, to delete all members who have never made a booking? */

DELETE FROM cd.members
  WHERE memid NOT IN (SELECT memid FROM cd.bookings);



/*** Aggregation ***/
-- https://pgexercises.com/questions/aggregates/

/Users/yangweichle/Desktop/schema-horizontal.svg

https://pgexercises.com/img/schema-horizontal.svg


/* Count the number of facilities

Question: For our first foray into aggregates, we're going to stick to something simple. We want to know how many facilities exist - simply produce a total count. */

SELECT COUNT(facid)
  FROM cd.facilities;

SELECT COUNT(*)
  FROM cd.facilities;


/* Count the number of expensive facilities

Question: Produce a count of the number of facilities that have a cost to guests of 10 or more. */

SELECT COUNT(facid)
  FROM cd.facilities
  WHERE guestcost >= 10;

SELECT COUNT(*)
  FROM cd.facilities
  WHERE guestcost >= 10;


/* Count the number of recommendations each member makes.

Question: Produce a count of the number of recommendations each member has made. Order by member ID. */

SELECT recommendedby,
       COUNT(*) AS count
  FROM cd.members
  WHERE recommendedby IS NOT NULL
  GROUP BY recommendedby
  ORDER BY recommendedby;


/* List the total slots booked per facility

Question: Produce a list of the total number of slots booked per facility. For now, just produce an output table consisting of facility id and slots, sorted by facility id. */

SELECT facid,
       SUM(slots) AS "Total Slots"
  FROM cd.bookings
  GROUP BY facid
  ORDER BY facid;


/* List the total slots booked per facility in a given month

Question: Produce a list of the total number of slots booked per facility in the month of September 2012. Produce an output table consisting of facility id and slots, sorted by the number of slots. */

SELECT facid,
       SUM(slots) AS "Total Slots"
  FROM cd.bookings
  WHERE starttime >= '2012-09-01' AND starttime < '2012-10-01'
  GROUP BY facid
  ORDER BY SUM(slots);

SELECT facid,
       SUM(slots) AS "Total Slots"
  FROM cd.bookings
  WHERE starttime >= '2012-09-01' AND starttime < '2012-10-01'
  GROUP BY facid
  ORDER BY "Total Slots"; /* Note: Aliases can be used in ORDER BY */


/* List the total slots booked per facility per month

Question: Produce a list of the total number of slots booked per facility per month in the year of 2012. Produce an output table consisting of facility id and slots, sorted by the id and month. */

SELECT facid,
       EXTRACT(MONTH FROM starttime) as month,
       SUM(slots) AS "Total Slots"
  FROM cd.bookings
  WHERE starttime >= '2012-01-01' AND starttime < '2013-01-01'
  GROUP BY facid, 
           month
  ORDER BY facid,
           month;

SELECT facid,
       EXTRACT(MONTH FROM starttime) as month,
       SUM(slots) AS "Total Slots"
  FROM cd.bookings
  WHERE EXTRACT(YEAR FROM starttime) = 2012 /* Note: Extracting year in the WHERE clause instead of explicitly listing date ranges. This can cause performance issues on larger tables. */
  GROUP BY facid, 
           month
  ORDER BY facid,
           month;


/* Find the count of members who have made at least one booking

Question: Find the total number of members (including guests) who have made at least one booking. */

SELECT COUNT(DISTINCT memid) AS count
  FROM cd.bookings;


/* List facilities with more than 1000 slots booked

Question: Produce a list of facilities with more than 1000 slots booked. Produce an output table consisting of facility id and slots, sorted by facility id. */

SELECT facid,
       SUM(slots) AS "Total Slots"
  FROM cd.bookings
  GROUP BY facid
  HAVING SUM(slots) > 1000
  ORDER BY facid;


/* Find the total revenue of each facility

Question: Produce a list of facilities along with their total revenue. The output table should consist of facility name and revenue, sorted by revenue. Remember that there's a different cost for guests and members! */

SELECT f.name,
       SUM(CASE WHEN b.memid = 0 THEN b.slots*f.guestcost
                ELSE b.slots*f.membercost END) AS revenue
  FROM cd.bookings AS b
  INNER JOIN cd.facilities AS f
    ON b.facid = f.facid
  GROUP BY f.name
  ORDER BY revenue;


/* Find facilities with a total revenue less than 1000

Question: Produce a list of facilities with a total revenue less than 1000. Produce an output table consisting of facility name and revenue, sorted by revenue. Remember that there's a different cost for guests and members! */

SELECT rev.name,
       rev.revenue
  FROM (SELECT f.name,
               SUM(CASE WHEN b.memid = 0 THEN b.slots*f.guestcost
                        ELSE b.slots*f.membercost END) AS revenue
          FROM cd.bookings AS b
          INNER JOIN cd.facilities AS f
            ON b.facid = f.facid
          GROUP BY f.name) AS rev
  WHERE rev.revenue < 1000
  ORDER BY rev.revenue;


/* Output the facility id that has the highest number of slots booked

Question: Output the facility id that has the highest number of slots booked. For bonus points, try a version without a LIMIT clause. This version will probably look messy! */

/* SIMPLEST SOLUTION...BUT IN THE EVENT OF A TIE, IT WILL ONLY OUTPUT ONE RESULT
SELECT facid,
       SUM(slots) AS "Total Slots"
  FROM cd.bookings
  GROUP BY facid
  ORDER BY "Total Slots" DESC
  LIMIT 1;

/* ALTERNATIVE SOLUTION USING Common Table Expressions (CTEs) */
WITH sum AS (
SELECT facid, 
       SUM(slots) AS totalslots
  FROM cd.bookings
  GROUP BY facid
)

SELECT facid, 
       totalslots 
  FROM sum
  WHERE totalslots = (SELECT MAX(totalslots) 
		       FROM sum);


/* List the total slots booked per facility per month, part 2

Question: Produce a list of the total number of slots booked per facility per month in the year of 2012. In this version, include output rows containing totals for all months per facility, and a total for all months for all facilities. The output table should consist of facility id, month and slots, sorted by the id and month. When calculating the aggregated values for all months and all facids, return null values in the month and facid columns. */

/* BETTER SOLUTION USING ROLLUP */
SELECT facid,
       EXTRACT(MONTH FROM starttime) AS month,
       SUM(slots) AS slots
  FROM cd.bookings
  WHERE EXTRACT(YEAR FROM starttime) = 2012
  GROUP BY ROLLUP(facid,                         /* Note: ROLLUP is used to calculate the aggregated totals for all months per facility and total for all months for all facilities */
                  month)
  ORDER BY facid,
           month;

/* ALTERNATIVE SOLUTION USING Common Table Expressions (CTEs) */
WITH bookings AS (
SELECT facid, 
       EXTRACT(MONTH FROM starttime) AS month, 
       slots
  FROM cd.bookings
  WHERE starttime >= '2012-01-01' AND starttime < '2013-01-01'
)

SELECT facid, 
       month, 
       SUM(slots)
  FROM bookings 
  GROUP BY facid, 
           month
UNION ALL
SELECT facid, 
       NULL, 
       SUM(slots)
  FROM bookings 
  GROUP BY facid
UNION ALL
SELECT NULL,
       NULL, 
       SUM(slots) 
  FROM bookings
  ORDER BY facid, 
           month;


/* List the total hours booked per named facility

Question: Produce a list of the total number of hours booked per facility, remembering that a slot lasts half an hour. The output table should consist of the facility id, name, and hours booked, sorted by facility id. Try formatting the hours to two decimal places. */

SELECT b.facid,
       f.name,
       ROUND(SUM(b.slots/2.0), 2) AS "Total Hours"
  FROM cd.bookings AS b
  INNER JOIN cd.facilities AS f
    ON b.facid = f.facid
  GROUP BY b.facid,
           f.name
  ORDER BY b.facid;


/* List each member's first booking after September 1st 2012

Question: Produce a list of each member name, id, and their first booking after September 1st 2012. Order by member ID. */

SELECT m.surname,
       m.firstname,
       m.memid,
       MIN(b.starttime) AS starttime
  FROM cd.members AS m
  INNER JOIN cd.bookings AS b
    ON m.memid = b.memid
  WHERE b.starttime >= '2012-09-01'
  GROUP BY m.surname, 
           m.firstname, 
		   m.memid
  ORDER BY m.memid;


/* Produce a list of member names, with each row containing the total member count

Question: Produce a list of member names, with each row containing the total member count. Order by join date, and include guest members. */

/* ALTERNATIVE SOLUTION USING WINDOW FUNCTION */
SELECT COUNT(*) OVER() AS count, 
       firstname,
       surname
  FROM cd.members
  ORDER BY joindate;


SELECT (SELECT COUNT(memid) AS count FROM cd.members),
       firstname,
       surname
  FROM cd.members
  ORDER BY joindate;

/* Produce a count of all members who joined in the same month as that member: */

SELECT COUNT(*) OVER(PARTITION BY date_trunc('MONTH', joindate)),
       firstname,
       surname
  FROM cd.members
  ORDER BY joindate;

/* Produce a count of what number joinee they were that month: */

SELECT COUNT(*) OVER(PARTITION BY date_trunc('MONTH', joindate) ORDER BY joindate),
       firstname,
       surname
  FROM cd.members
  ORDER BY joindate;

/* You can have multiple unrelated window functions in the same query: */

SELECT COUNT(*) OVER(PARTITION BY date_trunc('MONTH', joindate) ORDER BY joindate ASC),
       COUNT(*) OVER(PARTITION BY date_trunc('MONTH', joindate) ORDER BY joindate DESC),
       firstname,
       surname
  FROM cd.members
  ORDER BY joindate;


/* Produce a numbered list of members

Question: Produce a monotonically increasing numbered list of members (including guests), ordered by their date of joining. Remember that member IDs are not guaranteed to be sequential. */

SELECT ROW_NUMBER() OVER(ORDER BY joindate) AS row_number,
       firstname,
       surname
  FROM cd.members;

/* ALTERNATIVE SOLUTION */
SELECT COUNT(*) OVER(ORDER BY joindate) AS row_number,
       firstname,
       surname
  FROM cd.members;


/* Output the facility id that has the highest number of slots booked, again

Question: Output the facility id that has the highest number of slots booked. Ensure that in the event of a tie, all tieing results get output. */

SELECT ranked.facid,
       ranked.total
  FROM (SELECT facid,
               SUM(slots) AS total,
               RANK() OVER(ORDER BY SUM(slots) DESC) AS rank
          FROM cd.bookings
          GROUP BY facid) AS ranked
  WHERE ranked.rank = 1;


/* Rank members by (rounded) hours used

Question: Produce a list of members (including guests), along with the number of hours they've booked in facilities, rounded to the nearest ten hours. Rank them by this rounded figure, producing output of first name, surname, rounded hours, rank. Sort by rank, surname, and first name. */

SELECT m.firstname,
       m.surname,
       ROUND(SUM(b.slots/2.0), -1) AS hours,
       RANK() OVER(ORDER BY ROUND(SUM(b.slots/2.0), -1) DESC) AS rank
  FROM cd.members AS m
  INNER JOIN cd.bookings AS b
    ON m.memid = b.memid
  GROUP BY m.firstname, 
           m.surname
  ORDER BY rank,
           m.surname, 
           m.firstname;


/* Find the top three revenue generating facilities

Question: Produce a list of the top three revenue generating facilities (including ties). Output facility name and rank, sorted by rank and facility name. */

SELECT sub.name, 
       sub.rank
  FROM (SELECT f.name,
               RANK() OVER(ORDER BY SUM(CASE WHEN b.memid = 0 THEN b.slots*f.guestcost
                                             ELSE b.slots*f.membercost END) DESC) AS rank
          FROM cd.bookings AS b
          INNER JOIN cd.facilities AS f
            ON b.facid = f.facid
          GROUP BY f.name) AS sub
  WHERE sub.rank <= 3
  ORDER BY sub.rank, 
           sub.name;


/* Classify facilities by value

Question: Classify facilities into equally sized groups of high, average, and low based on their revenue. Order by classification and facility name. */ 

SELECT sub.name, 
       CASE WHEN sub.tertile = 1 THEN 'high'
            WHEN sub.tertile = 2 THEN 'average'
            ELSE 'low' END AS revenue
  FROM (SELECT f.name,
               NTILE(3) OVER(ORDER BY SUM(CASE WHEN b.memid = 0 THEN b.slots*f.guestcost
                                               ELSE b.slots*f.membercost END) DESC) AS tertile
          FROM cd.bookings AS b
          INNER JOIN cd.facilities AS f
            ON b.facid = f.facid
          GROUP BY f.name) AS sub
  ORDER BY sub.tertile, 
           sub.name;



/* Calculate the payback time for each facility

Question: Based on the 3 complete months of data so far, calculate the amount of time each facility will take to repay its cost of ownership. Remember to take into account ongoing monthly maintenance. Output facility name and payback time in months, order by facility name. Don't worry about differences in month lengths, we're only looking for a rough value here! */

/* HARDCODING MONTHS */
SELECT f.name, 
       f.initialoutlay / ((SUM(CASE WHEN b.memid = 0 THEN b.slots*f.guestcost
		                 ELSE b.slots*f.membercost END) / 3.0) - f.monthlymaintenance) AS months
  FROM cd.bookings AS b
  INNER JOIN cd.facilities AS f
    ON b.facid = f.facid
  GROUP BY f.facid
  ORDER BY f.name;

/* ALSO HARDCODING MONTHS; USING SUBQUERY TO CLARIFY WHAT IS GOING ON */
SELECT sub.name, 
       sub.initialoutlay / (sub.monthlyrevenue - sub.monthlymaintenance) as months 
  FROM (SELECT f.name, 
               f.initialoutlay,
               f.monthlymaintenance,
               SUM(CASE WHEN b.memid = 0 THEN b.slots*f.guestcost
		       ELSE b.slots*f.membercost END) / 3.0 as monthlyrevenue
          FROM cd.bookings AS b
          INNER JOIN cd.facilities AS f
            ON b.facid = f.facid
          GROUP BY f.facid) AS sub
 ORDER BY sub.name;


/* Calculate a rolling average of total revenue

Question: For each day in August 2012, calculate a rolling average of total revenue over the previous 15 days. Output should contain date and revenue columns, sorted by the date. Remember to account for the possibility of a day having zero revenue. This one's a bit tough, so don't be afraid to check out the hint! */

SELECT dategen.date, 
       (-- correlated subquery that, for each day fed into it,
        -- finds the average revenue for the last 15 days
        SELECT SUM(CASE WHEN b.memid = 0 THEN b.slots*f.guestcost
		       ELSE b.slots*f.membercost END) AS rev
          FROM cd.bookings AS b
          INNER JOIN cd.facilities AS f
            ON b.facid = f.facid
          WHERE b.starttime > dategen.date - interval '14 days'
            AND b.starttime < dategen.date + interval '1 day')/15 AS revenue
  FROM (-- generates a list of days in august
        SELECT CAST(GENERATE_SERIES(TIMESTAMP '2012-08-01', TIMESTAMP '2012-08-31', INTERVAL '1 day') AS DATE) AS date) AS dategen
  ORDER BY dategen.date;



/*** Working with Timestamps ***/
-- https://pgexercises.com/questions/date/

/Users/yangweichle/Desktop/schema-horizontal.svg

https://pgexercises.com/img/schema-horizontal.svg


/* Produce a timestamp for 1 a.m. on the 31st of August 2012

Question: Produce a timestamp for 1 a.m. on the 31st of August 2012. */

SELECT TIMESTAMP '2012-08-31 01:00:00';

/* ALTERNATIVE SOLUTION */
SELECT TIMESTAMP '2012-08-31 01:00:00' AS timestamp;


/* Subtract timestamps from each other

Question: Find the result of subtracting the timestamp '2012-07-30 01:00:00' from the timestamp '2012-08-31 01:00:00' */

SELECT TIMESTAMP '2012-08-31 01:00:00' - TIMESTAMP '2012-07-30 01:00:00' AS interval;


/* Generate a list of all the dates in October 2012

Question: Produce a list of all the dates in October 2012. They can be output as a timestamp (with time set to midnight) or a date. */

SELECT GENERATE_SERIES(TIMESTAMP '2012-10-01', TIMESTAMP '2012-10-31', INTERVAL '1 day') AS ts


/* Get the day of the month from a timestamp

Question: Get the day of the month from the timestamp '2012-08-31' as an integer. */

SELECT EXTRACT(DAY FROM TIMESTAMP '2012-08-31') AS date_part;


/* Work out the number of seconds between timestamps

Question: Work out the number of seconds between the timestamps '2012-08-31 01:00:00' and '2012-09-02 00:00:00' */

/* Postgres specific trick */
SELECT EXTRACT(EPOCH FROM (TIMESTAMP '2012-09-02 00:00:00' - TIMESTAMP '2012-08-31 01:00:00')) AS date_part;

/* ALTERNATIVE CODE FOR OTHER SQL VERSIONS */
SELECT EXTRACT(DAY FROM ts.interval)*60*60*24 +
       EXTRACT(HOUR FROM ts.interval)*60*60 + 
       EXTRACT(MINUTE FROM ts.interval)*60 +
       EXTRACT(SECOND FROM ts.interval) AS date_part
  FROM (SELECT TIMESTAMP '2012-09-02 00:00:00' - '2012-08-31 01:00:00' AS interval) AS ts


/* Work out the number of days in each month of 2012

Question: For each month of the year in 2012, output the number of days in that month. Format the output as an integer column containing the month of the year, and a second column containing an interval data type. */

SELECT EXTRACT(MONTH FROM cal.month) as month,
       (cal.month + INTERVAL '1 month') - cal.month AS length
  FROM (SELECT GENERATE_SERIES(TIMESTAMP '2012-01-01', TIMESTAMP '2012-12-01', INTERVAL '1 month') AS month) AS cal
  ORDER BY cal.month;  


/* Work out the number of days remaining in the month

Question: For any given timestamp, work out the number of days remaining in the month. The current day should count as a whole day, regardless of the time. Use '2012-02-11 01:00:00' as an example timestamp for the purposes of making the answer. Format the output as a single interval value. */

SELECT (DATE_TRUNC('MONTH', ts.testts) + INTERVAL '1 month') - DATE_TRUNC('DAY', ts.testts) AS remaining
  FROM (SELECT timestamp '2012-02-11 01:00:00' AS testts) AS ts  


/* Work out the end time of bookings

Question: Return a list of the start and end time of the last 10 bookings (ordered by the time at which they end, followed by the time at which they start) in the system. */

SELECT starttime,
       starttime + slots*(INTERVAL '30 minutes') AS endtime
  FROM cd.bookings
  ORDER BY endtime DESC, 
           starttime DESC
  LIMIT 10;


/* Return a count of bookings for each month

Question: Return a count of bookings for each month, sorted by month */

SELECT DATE_TRUNC('MONTH', starttime) AS month,
       COUNT(*) AS count
  FROM cd.bookings
  GROUP BY month
  ORDER BY month;


/* Work out the utilization percentage for each facility by month

Question: Work out the utilization percentage for each facility by month, sorted by name and month, rounded to 1 decimal place. Opening time is 8am, closing time is 8.30pm. You can treat every month as a full month, regardless of if there were some dates the club was not open. */

SELECT sub.name, 
       sub.month, 
       ROUND((100*sub.slots)/CAST(25*(CAST((sub.month + INTERVAL '1 month') AS date) - CAST(sub.month AS date)) AS numeric), 1) AS utilisation
  FROM (SELECT f.name, 
               DATE_TRUNC('MONTH', b.starttime) AS month, 
               SUM(b.slots) AS slots
          FROM cd.bookings AS b
          INNER JOIN cd.facilities AS f
            ON b.facid = f.facid
          GROUP BY f.facid, 
                   month) AS sub
  ORDER BY sub.name, 
           sub.month;  



/*** String Operations ***/
-- https://pgexercises.com/questions/string/

/Users/yangweichle/Desktop/schema-horizontal.svg

https://pgexercises.com/img/schema-horizontal.svg


/* Format the names of members

Question: Output the names of all members, formatted as 'Surname, Firstname' */

SELECT CONCAT(surname, ', ', firstname) AS name 
  FROM cd.members;

SELECT surname || ', ' || firstname AS name 
  FROM cd.members  


/* Find facilities by a name prefix

Question: Find all facilities whose name begins with 'Tennis'. Retrieve all columns. */

SELECT *
  FROM cd.facilities
  WHERE name LIKE 'Tennis%';


/* Perform a case-insensitive search

Question: Perform a case-insensitive search to find all facilities whose name begins with 'tennis'. Retrieve all columns. */

SELECT *
  FROM cd.facilities
  WHERE LOWER(name) LIKE 'tennis%';

SELECT *
  FROM cd.facilities
  WHERE UPPER(name) LIKE 'TENNIS%';

SELECT *
  FROM cd.facilities
  WHERE name ILIKE 'tennis%';


/* Find telephone numbers with parentheses

Question: You've noticed that the club's member table has telephone numbers with very inconsistent formatting. You'd like to find all the telephone numbers that contain parentheses, returning the member ID and telephone number sorted by member ID. */

SELECT memid,
       telephone
  FROM cd.members
  WHERE telephone ~ '[()]'
  ORDER BY memid

SELECT memid,
       telephone
  FROM cd.members
  WHERE telephone SIMILAR TO '%[()]%'
  ORDER BY memid


/* Pad zip codes with leading zeroes

Question: The zip codes in our example dataset have had leading zeroes removed from them by virtue of being stored as a numeric type. Retrieve all zip codes from the members table, padding any zip codes less than 5 characters long with leading zeroes. Order by the new zip code. */

SELECT LPAD(CAST(zipcode as CHAR(5)), 5, '0') AS zip
  FROM cd.members
  ORDER BY zip;


/* Count the number of members whose surname starts with each letter of the alphabet

Question: You'd like to produce a count of how many members you have whose surname starts with each letter of the alphabet. Sort by the letter, and don't worry about printing out a letter if the count is 0. */

SELECT SUBSTR(surname, 1, 1) AS letter,
       COUNT(*) AS count
  FROM cd.members
  GROUP BY letter
  ORDER BY letter;


/* Clean up telephone numbers

Question: The telephone numbers in the database are very inconsistently formatted. You'd like to print a list of member ids and numbers that have had '-','(',')', and ' ' characters removed. Order by member id. */

SELECT memid,
       TRANSLATE(telephone, '-() ', '') AS telephone
  FROM cd.members
  ORDER BY memid;

SELECT memid,
       REGEXP_REPLACE(telephone, '[^0-9]', '', 'g') AS telephone
  FROM cd.members
  ORDER BY memid;



/*** Recursive Queries ***/
-- https://pgexercises.com/questions/recursive/

/Users/yangweichle/Desktop/schema-horizontal.svg

https://pgexercises.com/img/schema-horizontal.svg


/* Find the upward recommendation chain for member ID 27

Question: Find the upward recommendation chain for member ID 27: that is, the member who recommended them, and the member who recommended that member, and so on. Return member ID, first name, and surname. Order by descending member id. */

WITH RECURSIVE recommenders(recommender) AS (
-- <initial statement>
SELECT recommendedby
  FROM cd.members 
  WHERE memid = 27
UNION ALL
-- <recursive statement>
SELECT m.recommendedby
  FROM recommenders AS r
  INNER JOIN cd.members AS m
    ON m.memid = r.recommender
)

SELECT r.recommender, 
       m.firstname,
       m.surname
  FROM recommenders r
  INNER JOIN cd.members m
    ON r.recommender = m.memid
  ORDER BY memid DESC;


/* Find the downward recommendation chain for member ID 1

Question: Find the downward recommendation chain for member ID 1: that is, the members they recommended, the members those members recommended, and so on. Return member ID and name, and order by ascending member id. */

WITH RECURSIVE recommendeds(memid) AS (
-- <initial statement>
SELECT memid
  FROM cd.members 
  WHERE recommendedby = 1
UNION ALL
-- <recursive statement>
SELECT m.memid
  FROM recommendeds AS r
  INNER JOIN cd.members AS m
    ON m.recommendedby = r.memid
)

SELECT r.memid, 
       m.firstname,
       m.surname
  FROM recommendeds r
  INNER JOIN cd.members m
    ON r.memid = m.memid
  ORDER BY memid ASC;


/* Produce a CTE that can return the upward recommendation chain for any member

Question: Produce a CTE that can return the upward recommendation chain for any member. You should be able to select recommender from recommenders where member=x. Demonstrate it by getting the chains for members 12 and 22. Results table should have member and recommender, ordered by member ascending, recommender descending. */

WITH RECURSIVE recommenders(recommender, member) AS (
-- <initial statement>
SELECT recommendedby,
       memid
  FROM cd.members 
UNION ALL
-- <recursive statement>
SELECT m.recommendedby,
       r.member
  FROM recommenders AS r
  INNER JOIN cd.members AS m
    ON m.memid = r.recommender
)

SELECT r.member,
       r.recommender, 
       m.firstname,
       m.surname
  FROM recommenders r
  INNER JOIN cd.members m
    ON r.recommender = m.memid
  WHERE r.member = 22 OR r.member = 12
  ORDER BY r.member ASC, r.recommender DESC;
