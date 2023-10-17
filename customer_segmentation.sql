-- check the number of rows and columns
select * from dbo.customer_shopping_data

-- check how many distinct customers there are
select distinct(customer_id) from dbo.customer_shopping_data

-- check for NULL values
select * from dbo.customer_shopping_data
where shopping_mall is NULL

-- check number of shopping sites
select count(distinct(shopping_mall)) as num_sites
from dbo.customer_shopping_data

-- Explore spending habbits according to demographic characteristics

-- which gender buys more products and spends more money?
select gender, sum(quantity)  orders, sum(price)  money_spent
from dbo.customer_shopping_data
group by gender

-- are there locations where predominant is one of the genders
select gender, count(gender) as n_visitors, shopping_mall from dbo.customer_shopping_data
group by shopping_mall, gender

-- predominant payment method preffered by gender
select gender, payment_method, count(payment_method) as count_payment_method
from dbo.customer_shopping_data
group by gender, payment_method

-- Explore locations revenue and bussy days

-- spending by mall
select shopping_mall, sum(quantity) orders, sum(price) sales
from customer_shopping_data
group by shopping_mall
order by 3 desc;

-- Recency, Frequency and Monetary (RFM) Analysis to identify "lost", "at risk", "slipping away" and "active" customers

with RFM as (
    select customer_id, gender, age, payment_method, shopping_mall,
        max(invoice_date) as last_order_date,
        sum(quantity) as total_orders,
        sum(price) as total_spent
    from dbo.customer_shopping_data
    group by customer_id, gender, age, payment_method, shopping_mall
),

rfm_calculation as (
    select *, 
        ntile(4) over (order by last_order_date) as rfm_recency,
        ntile(4) over (order by total_orders) as rfm_frequency,
        ntile(4) over (order by total_spent) as rfm_monetary
    from RFM
)

select *, (rfm_recency + rfm_frequency + rfm_monetary) as rfm_score,
    concat(rfm_recency, rfm_frequency, rfm_monetary) as rfm,
    (case
        when concat(rfm_recency, rfm_frequency, rfm_monetary) in ( '444', '412', '413', '414', '421', '423', '424', '431', '432', '434', '441', '442', '443') then 'active customers'
        when concat(rfm_recency, rfm_frequency, rfm_monetary) in ('111', '121', '123', '124', '131', '141', '142', '143', '144', '122', '132', '133', '134', '113', '112', '114') then 'lost customers'
        when concat(rfm_recency, rfm_frequency, rfm_monetary) in ('222', '221', '223', '224', '211', '212', '213', '214', '231', '2332', '233', '234', '241', '242', '243', '244') then 'at risk customers'
        when concat(rfm_recency, rfm_frequency, rfm_monetary) in ('331', '332', '333', '334', '321', '322', '323', '324', '311', '312', '313', '314', '341', '342', '343', '344') then 'slipping away customers'
    end) as rfm_segment
from rfm_calculation;

