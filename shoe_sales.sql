create database sql_project ;
SET SQL_SAFE_UPDATES = 0;

-- ------------------------------------------------------
-- Phase 0 : Data Transformation 
-- ------------------------------------------------------
select * from shoes_sales_dataset;
alter table shoes_sales_dataset modify
column Date date;
alter table shoes_sales_dataset modify 
column Price_USD decimal(7,2);
alter table shoes_sales_dataset modify
column Revenue_USD decimal(9,2);
 
 ---------------------------------------------------------
-- Phase 1: Data Understanding
----------------------------------------------------------
-- How many rows are in the dataset?
select count(Sale_id) as total_rows from shoes_sales_dataset;

-- How many columns are in the dataset?
select count(*) as total_columns
from information_schema.columns
where table_schema = 'sql_project'
and table_name = 'shoes_sales_dataset';

-- What is the date range of the sales?
select min(Date) as first_sales_date , max(Date) as last_sales_date
from shoes_sales_dataset;

-- Which brands are present?
select distinct Brand from shoes_sales_dataset;

-- Which countries are present?
select distinct Country from shoes_sales_dataset;

-- Which sales channels are present?
select distinct Sales_Channel from shoes_sales_dataset;

-- Which shoe types are present?
select distinct Shoe_Type from shoes_sales_dataset;


 ---------------------------------------------------------
-- Phase 2: Data Quality Checks
----------------------------------------------------------

-- Are there any duplicate records?
select count(Sale_ID) from shoes_sales_dataset
group by Sale_ID having count(Sale_ID) > 1 ;

-- Are there any missing values in important columns?
SELECT *
FROM shoes_sales_dataset
WHERE Sale_ID IS NULL OR TRIM(Sale_ID) = ''
   OR Date IS NULL
   OR Brand IS NULL OR TRIM(Brand) = ''
   OR Shoe_Type IS NULL OR TRIM(Shoe_Type) = ''
   OR Color IS NULL OR TRIM(Color) = ''
   OR Country IS NULL OR TRIM(Country) = ''
   OR Sales_Channel IS NULL OR TRIM(Sales_Channel) = ''
   OR Price_USD IS NULL
   OR Units_Sold IS NULL
   OR Revenue_USD IS NULL;
   
-- Is revenue correctly calculated from unit_price × units_sold?
select case
	when count(*) = 0
    then ' all rows are correct'
    else 'revenue calculation has errors'
    end as revenue_status
from shoes_sales_dataset
where Revenue_USD <> Price_USD * Units_Sold ;

-- Are there any negative values in unit_price, units_sold, or revenue?
select * from shoes_sales_dataset
where Price_USD < 0 or Units_Sold < 0 or Revenue_USD < 0 ;

-- Are the date values in the correct format?
select * from shoes_sales_dataset
where str_to_date (date, '%Y-%m-%d') is null ;

-- Are brand names and country names consistent?
select distinct Brand from shoes_sales_dataset;
 select distinct Country from shoes_sales_dataset;

 ---------------------------------------------------------
-- Phase 3: Basic Sales Analysis
----------------------------------------------------------

--  what is the total revenue?
select sum(Revenue_USD) as total_revenue from shoes_sales_dataset;

-- What is the total units sold?
select sum(Units_Sold) as total_units_sold from shoes_sales_dataset;

-- What is the average selling price?
select avg(Price_USD) as avg_sp from shoes_sales_dataset;

-- What is the total number of sales?
select count(Sale_ID) as total_sales from shoes_sales_dataset;

-- Which brand generates the highest revenue?
select Brand , sum(Revenue_USD) as revenue from shoes_sales_dataset
group by Brand order by revenue desc limit 1;

-- Which shoe type sells the most units?
select Shoe_Type , sum(Units_Sold ) as units_sold from shoes_sales_dataset
group by Shoe_Type order by Units_Sold  desc limit 1;

-- Which country generates the highest revenue?
select Country  , sum(Revenue_USD) as revenue from shoes_sales_dataset
group by Country order by revenue desc limit 1;

-- Which sales channel generates the highest revenue?
select Sales_Channel , sum(Revenue_USD) as revenue from shoes_sales_dataset
group by Sales_Channel order by revenue desc limit 1;


 ---------------------------------------------------------
-- Phase 4: Time Analysis
----------------------------------------------------------
-- What is the monthly revenue trend?
select date_format(Date, '%Y-%m')  as month , sum(Revenue_USD) as total_revenue
from shoes_sales_dataset group by month order by month;

-- Which month has the highest revenue?
select date_format(Date, '%Y-%m')  as month , sum(Revenue_USD) as total_revenue
from shoes_sales_dataset group by month order by total_revenue desc limit 1;

-- Which quarter has the highest revenue?
select concat(year(Date),'-Q',quarter(Date)) as quarter ,
	sum(Revenue_USD) as total_revenue
from shoes_sales_dataset
group by quarter
order by total_revenue desc limit 1 ;

-- Which month has the highest units sold?
select date_format(Date,'%Y-%m') as month , sum(Units_Sold)  as units_sold
from shoes_sales_dataset
group by month
order by units_sold
desc limit 1;

-- Is revenue increasing or decreasing over time?
with revenue as (
	select date_format(Date, '%Y-%m') as month , sum(Revenue_USD) as total_revenue
    from shoes_sales_dataset
    group by month 
    order by month
    )
select month, total_revenue , total_revenue - lag(total_revenue) over (order by month)
as running_revenue, 
case
	when total_revenue >
    lag (total_revenue) over (order by month)
    then 'increasing'
	when total_revenue < 
    lag(total_revenue) over (order by month) 
    then 'decreasing'
    
    else 'No change'
end as revenue_trend
from revenue ;


-- ---------------------------------------------------------
-- Phase 5: Product Analysis
-- ----------------------------------------------------------

-- Which brand has the highest average selling price?
select brand , round(avg(Price_USD),2) as highest_avg_sp
from shoes_sales_dataset group by brand order by highest_avg_sp desc limit 1 ;

-- Which shoe type has the highest average selling price?
select Shoe_Type , round(avg(Price_USD),2) as highest_avg_sp
from shoes_sales_dataset group by Shoe_Type order by highest_avg_sp desc limit 1 ;

-- Which price band generates the highest revenue?
alter table shoes_sales_dataset add column Price_band varchar(10);
update shoes_sales_dataset
set Price_band =case
		when Price_USD < 51 then 'Budget'
		when Price_USD < 151 then 'Mid-Range'
		else 'Premium'
	end;
select Price_band , sum(Revenue_USD) as revenue
from shoes_sales_dataset
group by price_band order by revenue desc limit 1 ;

-- Which price band sells the most units?
select Price_band , sum(Units_Sold) as units
from shoes_sales_dataset
group by price_band order by units desc limit 1 ;

-- Which brand contributes the highest percentage of total revenue?
with brand_revenue as (
	select Brand, sum(Revenue_USD) as total_revenue from
    shoes_sales_dataset group by Brand order by Brand )
select Brand, total_revenue, round(total_revenue *100/sum(total_revenue) over (), 2)
as percentage from brand_revenue
group by brand 
order by percentage desc limit 1;

-- Rank all brands by revenue using RANK().
with brand_revenue as (
	select Brand, sum(Revenue_USD) as total_revenue from
    shoes_sales_dataset group by Brand order by Brand )
select Brand, total_revenue, rank() over (order by total_revenue desc ) as  revenue_rank
from brand_revenue;

-- What is each brand's share (%) of total revenue?
with brand_revenue as (
	select Brand, sum(Revenue_USD) as total_revenue from
    shoes_sales_dataset group by Brand order by Brand )
select Brand, total_revenue, round(total_revenue *100/sum(total_revenue) over (), 2)
as percentage from brand_revenue
group by brand 
order by percentage desc;

 ---------------------------------------------------------
-- Phase 6: Customer and Market Analysis
----------------------------------------------------------

-- Which sales channel contributes the most revenue?
select Sales_Channel, sum(Revenue_USD) as revenue from shoes_sales_dataset
group by Sales_Channel order by revenue desc limit 1 ;

-- Which country contributes the most revenue?
select Country, sum(Revenue_USD) as revenue from shoes_sales_dataset
group by Country order by revenue desc limit 1 ;

-- What percentage of revenue comes from each sales channel?
with sales_channel as (
	 select Sales_Channel, sum(Revenue_USD) as revenue
     from shoes_sales_dataset group by Sales_Channel order by Sales_Channel
     )
select Sales_Channel, revenue, round( revenue * 100 / sum(revenue)over (),2) as percentage 
from sales_channel group by Sales_Channel  ;

-- Which sales channel performs best in each country?
with channel_rnk as (
	select Country as country, Sales_Channel as sales_channel, sum(Revenue_USD) as total_revenue
	from shoes_sales_dataset group by Country, Sales_Channel)
		select country , sales_channel,  total_revenue from (
			select country , sales_channel , total_revenue,
			rank () over (partition by country order by total_revenue desc) as channel_rank
			from channel_rnk) rnk
		where channel_rank = 1
        order by country ;
	
-- Which price band is most popular in each country?
with band_rnk as (
	select Country as country, Price_band as price_band, sum(Units_Sold) as total_units
	from shoes_sales_dataset group by Country, price_band)
		select country , price_band,  total_units from (
			select country , price_band, total_units,
			rank () over (partition by country order by total_units desc) as price_rank
			from band_rnk) rnk
		where price_rank = 1
        order by country ;
        
-- Which country buys the highest average-priced products?
with band_rnk as 
	(select Country as country,  avg(Price_USD) as avg_price
	from shoes_sales_dataset group by Country)
		select country ,  avg_price from (
			select country , avg_price,
			rank () over (order by avg_price desc) as price_rank
			from band_rnk) rnk
		where price_rank = 1
        order by country ;
        
-- Which country has the highest average units per sale?
with band_rnk as (
	select Country as country,  avg(Units_Sold) as total_units
	from shoes_sales_dataset group by Country)
		select country ,  total_units from (
			select country , total_units,
			rank () over (order by total_units desc) as price_rank
			from band_rnk) rnk
		where price_rank = 1
        order by country ;


 