select * from sales
select * from members
select * from menu

--1.What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as Total_Amount
from sales s
join menu m
on s.product_id = m.product_id
group by s.customer_id
order by Total_Amount desc

--2.How many days has each customer visited the restaurant?
select customer_id,count(Distinct(order_date)) as Visited_days
from sales
Group by customer_id
Order by Visited_days desc

--3.What was the first item from the menu purchased by each customer?
with first_item_purchase as 
(
	select s.customer_id,s.order_date,m.product_id,m.product_name,
	DENSE_RANK() over(partition by s.customer_id order by s.order_date) as Item_Ranks
	from sales s
	join menu m
	on s.product_id = m.product_id
)
select customer_id,product_name
from first_item_purchase
where Item_Ranks = 1
Group by customer_id,product_name
order by customer_id,product_name

--4.What is the most purchased item on the menu and how many times was it purchased by all customers?
select TOP 1 m.product_name,COUNT(s.order_date) as orders 
from sales s
join menu m
on s.product_id = m.product_id
Group by m.product_name
order by 2 desc

--5.Which item was the most popular for each customer?
with most_popular_item as
(
	select s.customer_id,COUNT(s.order_date) as order_count,m.product_name,
	DENSE_RANK() over(partition by s.customer_id order by count(s.customer_id)desc) as odr_rnk
	from sales s
	join menu m
	on s.product_id = m.product_id
	Group by s.customer_id,m.product_name
)
select customer_id,product_name,order_count
from most_popular_item
where odr_rnk = 1

--6.Which item was purchased first by the customer after they became a member?
with joined_member as
(
	select s.customer_id,m.product_name,
	DENSE_RANK() over(partition by s.customer_id order by s.order_date) as rnk_id
	from menu m
	join sales s
	on m.product_id = s.product_id
	join members ms
	on ms.customer_id = s.customer_id
	where s.order_date > ms.join_date
)
select customer_id,product_name
from joined_member
where rnk_id = 1

--7.Which item was purchased just before the customer became a member?
with joined_member as
(
	select s.customer_id,m.product_name,
	DENSE_RANK() over(partition by s.customer_id order by s.order_date) as rnk_id
	from menu m
	join sales s
	on m.product_id = s.product_id
	join members ms
	on ms.customer_id = s.customer_id
	where s.order_date < ms.join_date
)
select customer_id,product_name
from joined_member
where rnk_id = 1

--8.What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(s.product_id) as total_items,sum(m.price) as total_amount
from sales s
join members me
on s.customer_id = me.customer_id
join menu m 
on m.product_id = s.product_id
where s.order_date < me.join_date
Group by s.customer_id

--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points as
(
	select *,CASE 
				WHEN product_name = 'sushi' THEN price * 20
				ELSE price * 10
				END as points
	from menu
)
select s.customer_id,sum(p.points) as Total_points
from sales s
join points p 
on p.product_id = s.product_id
Group by s.customer_id


--JOIN ALL THE THINGS   Giving who has mumbers with Y and N
with members_joined as
(
	select s.customer_id,s.order_date,m.product_name,m.price,me.join_date,
	case when order_date > join_date then 'Y'
     Else 'N'
	 End as Members
	from sales s
	join members me
	on me.customer_id = s.customer_id
	join menu m
	on m.product_id = s.product_id
)
select customer_id,order_date,product_name,price,Members
from members_joined


--RANKING ALL THE THINGS   Giving members as Y or N and Ranking for only members
with members_joined as
(
	select s.customer_id,s.order_date,m.product_name,m.price,me.join_date,
	case when order_date > join_date then 'Y'
     Else 'N'
	 End as Members
	from sales s
	join members me
	on me.customer_id = s.customer_id
	join menu m
	on m.product_id = s.product_id
)
select customer_id,order_date,product_name,price,Members,
	CASE when Members = 'N' Then Null
	ELSE RANK() over(partition by customer_id,Members order by order_date)
	END as Ranking
from members_joined