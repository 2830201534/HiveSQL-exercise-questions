-- TODO 初级练习 初级函数

-- 1.从订单明细表（order_detail）、商品信息表（sku_info）中筛选出2021年总销量小于100的商品id、商品名及其销量
-- 假设今天的日期是2022-01-10，不考虑上架时间小于一个月（30天）的商品。
select
    od.sku_id,
    si.name,
    sum(sku_num) total_sku_num
from
    order_detail od
join
        sku_info si
on
    od.sku_id = si.sku_id
where
    year(od.create_date) = 2021
    and
    datediff("2022-01-10",od.create_date) > 30
group by
    od.sku_id,si.name
having
    total_sku_num < 100;

-- 2.从用户登录明细表（user_login_detail）中查询每天的新增用户数。
-- 若一个用户在某天登录了，且在这一天之前没登录过，则认为该用户为这一天的新增用户。
select
    login_date,
    count(1) cnt
from
    (select
        date(login_ts) login_date,
        lag(login_ts,1,"1970-01-01") over (partition by user_id order by login_ts) lag_day
    from
        user_login_detail
     )t1
where
    lag_day = "1970-01-01"
group by
    login_date;

-- 3.从用户登录明细表（user_login_detail）和订单信息表（order_info）中
-- 查询每个用户的注册日期（首次登录日期）、总登录次数，以及2021年的【登录次数、订单数和订单总额】。
select
    t1.user_id,
    t1.login_date,
    t2.user_total_login_cnt,
    nvl(t4.user_2021_login_cnt,0) user_2021_login_cnt,
    nvl(t3.user_2021_order_cnt,0) user_2021_order_cnt,
    nvl(t3.user_2021_order_total_amount,0) user_2021_order_total_amount
from
    (select
        user_id,
        login_date
    from
        (select
            user_id,
            date(login_ts) login_date,
            lag(login_ts,1,"1970-01-01") over (partition by user_id order by login_ts) lag_day
        from
            user_login_detail
         )t1
    where
        lag_day = "1970-01-01"
    group by
        user_id,login_date)t1
left join
    (select
        user_id,
        count(1) user_total_login_cnt
    from
        user_login_detail
    group by
        user_id)t2
on
    t1.user_id = t2.user_id
left join
    (select
        user_id,
        count(order_id) user_2021_order_cnt,
        sum(total_amount) user_2021_order_total_amount
    from
        order_info
    where
        year(create_date) = 2021
    group by
        user_id)t3
on
    t1.user_id = t3.user_id
left join
    (select
        user_id,
        count(1) user_2021_login_cnt
    from
        user_login_detail
    where
        year(login_ts) = 2021
    group by
        user_id)t4
on
    t1.user_id = t4.user_id
order by
    cast(t1.user_id as int);

--4.请向所有用户推荐其朋友收藏但是自己未收藏的商品，
-- 从好友关系表（friendship_info）和收藏表（favor_info）中查询出应向哪位用户推荐哪些商品。
with my_sku_table AS (
    select
        user_id,
        collect_set(sku_id) my_sku_id
    from
        favor_info
    group by
        user_id)
select
    distinct
    fri.user1_id,
    fai.sku_id
from
    friendship_info fri
left join
         favor_info fai
on
    fri.user2_id=fai.user_id
left join
        my_sku_table mst
on
    fri.user1_id = mst.user_id
where
    fai.sku_id is not null
    and
    array_contains(mst.my_sku_id,fai.sku_id) is false;

-- 5.男性和女性每日的购物总金额统计
-- 从订单信息表（order_info）和用户信息表（user_info）中
-- 分别统计每天男性和女性用户的订单总金额，如果当天男性或者女性没有购物，则统计结果为0。
select
    date(oi.create_date) create_date,
    nvl(sum(`if`(ui.gender=="男",oi.total_amount,0)),0) total_amount_male,
    nvl(sum(`if`(ui.gender=="女",oi.total_amount,0)),0) total_amount_female
from
    order_info oi
join
    user_info ui
on
    oi.user_id = ui.user_id
group by
    date(oi.create_date);

-- 6.购买过商品1和商品2但是没有购买商品3的顾客
-- 从订单明细表（order_detail）中查询出所有购买过商品1和商品2，但是没有购买过商品3的用户。
select
    user_id,
    sku_id_list
from
    (select
        user_id,
        collect_set(sku_id) sku_id_list
    from
        order_detail od
    join
        order_info oi
    on
        oi.order_id = od.order_id
    group by
        oi.user_id)t1
where
    array_contains(sku_id_list,'1')
    and
    array_contains(sku_id_list,'2')
    and
    !array_contains(sku_id_list,'3');

--7.统计每日商品1和商品2销量的差值
--从订单明细表（order_detail）中统计每天商品1和商品2销量（件数）的差值（商品1销量-商品2销量）
select
    create_date,
    sum(`if`(sku_id = '1',sku_num,0)) - sum(`if`(sku_id = '2',sku_num,0)) difference
from
    order_detail
where
    sku_id in ('1','2')
group by
    create_date;

--8.根据商品销售情况进行商品分类
-- 通过订单详情表（order_detail）的数据，根据销售件数对商品进行分类
-- 销售件数0-5000为冷门商品，5001-19999为一般商品，20000以上为热门商品，统计不同类别商品的数量，
select
    category,
    count(1) cnt
from
    (select
        case when total_sku_num >=0 and total_sku_num <= 5000
             then "冷门商品"
             when total_sku_num >= 20000
             then "热门商品"
             else "一般商品"
        end category,
        total_sku_num
    from
        (select
            sku_id,
            sum(sku_num) total_sku_num
        from
            order_detail
        group by
            sku_id)t1 )t2
group by
    category;

--9.查询有新增用户的日期的新增用户数和新增用户一日留存率
-- 从用户登录明细表（user_login_detail）中统计有新增用户的日期的新增用户数（若某日未新增用户，则不出现在统计结果中），
-- 并统计这些新增用户的一日留存率。
-- 用户首次登录为当天新增，次日也登录则为一日留存。一日留存用户占新增用户数的比率为一日留存率。
with date_table AS (
select
    user_id,
    date(login_ts) login_date,
    lag(date(login_ts),1,"1970-01-01") over(partition by user_id order by login_ts) lag_date,
    lead(date(login_ts),1,"9999-01-01") over(partition by user_id order by login_ts) lead_date
from
    user_login_detail)

select
    t1.login_date,
    t1.first_login_cnt,
    nvl(cast(t2.second_login_cnt / t1.first_login_cnt as decimal(8,2)),0.00) leave_rate_1_day
from
    (select
        login_date,
        count(1) first_login_cnt
    from
        date_table
    where
        lag_date = "1970-01-01"
    group by
        login_date)t1
left join
        (select
            login_date,
            count(1) second_login_cnt
        from
            date_table
        where
            lag_date = "1970-01-01"
            and
            datediff(lead_date,login_date) = 1
        group by login_date)t2
on
    t1.login_date = t2.login_date;

-- 10.登录次数及交易次数统计
-- 分别从登录明细表（user_login_detail）和配送信息表（delivery_info）
-- 获取用户登录时间和下单时间字段，统计该用户每天的登陆次数和交易次数
select
    t1.login_date,
    t1.user_id,
    t1.login_cnt,
    nvl(t2.delivery_cnt,0) delivery_cnt
from
    (select
        user_id,
        date(login_ts) login_date,
        count(1) login_cnt
    from
        user_login_detail
    group by
        user_id,date(login_ts))t1
left join
    (select
        user_id,
        order_date,
        count(1) delivery_cnt
    from
        delivery_info
    group by
        user_id,order_date)t2
on
    t1.user_id=t2.user_id
    and
    t1.login_date=t2.order_date;

--11.统计每个商品各年度销售总额
-- 从订单明细表（order_detail）中统计每个商品各年度的销售总额
select
    year(create_date) year,
    sku_id,
    sum(price*sku_num) total_year_sku_amount
from
    order_detail
group by
    year(create_date),
    sku_id;

--12.某周内每件商品每天销售情况
-- 从订单详情表（order_detail）中
-- 查询2021年9月27号-2021年10月3号这一周所有商品每天销售件数
select
    sku_id,
    sum(if(`dayofweek`(cast(create_date as date))=2,sku_num,0)) Monday,
    sum(if(`dayofweek`(cast(create_date  as date))=3,sku_num,0)) Tuesday,
    sum(if(`dayofweek`(cast(create_date  as date))=4,sku_num,0)) Wednesday,
    sum(if(`dayofweek`(cast(create_date  as date))=5,sku_num,0)) Thursday,
    sum(if(`dayofweek`(cast(create_date  as date))=6,sku_num,0)) Friday,
    sum(if(`dayofweek`(cast(create_date  as date))=7,sku_num,0)) Saturday,
    sum(if(`dayofweek`(cast(create_date  as date))=1,sku_num,0)) Sunday
from
    order_detail
where
    create_date >= "2021-09-27"
    and
    create_date <= "2021-10-03"
group by
    sku_id;

--13.同期商品售卖分析表
-- 从订单明细表（order_detail）中
-- 统计同一个商品在2020年和2021年中同一个月的销量对比
select
    sku_id,
    month(create_date) month,
    sum(`if`(year(create_date)=2020,sku_num,0)) total_2020_sku_num,
    sum(`if`(year(create_date)=2021,sku_num,0)) total_2021_sku_num
from
    order_detail
where
    year(create_date) in (2020,2021)
group by
    sku_id,
    month(create_date);

-- 14.国庆期间每个sku的收藏量和购买量
-- 从订单明细表（order_detail）和收藏信息表（favor_info）中
-- 统计2021年国庆节期间（10月1日-10月7日）每天各个商品的购买总数量和总收藏次数。
select
    od.sku_id,
    od.create_date,
    sum(od.sku_num) total_sku_num,
    count(1) total_favor_num
from
    order_detail od
left join
        favor_info fi
on
    od.sku_id = fi.sku_id
    and
    od.create_date = fi.create_date
where
    od.create_date >= "2021-10-01"
    and
    od.create_date <= "2021-10-07"
group by
    od.sku_id,
    od.create_date;

--15.国庆节期间各品类商品的7日动销率和滞销率
--动销率的定义为某品类的商品中一段时间内有销量的商品种类数占当前已上架总商品种类数的比例（有销量的商品种类数/已上架总商品种类数）。
--滞销率的定义为某分类商品中一段时间内没有销量的商品种类数占当前已上架总商品种类数的比例（没有销量的商品种类数/已上架总商品种类数）。
--只要当天任一店铺有任何商品的销量就输出该天的统计结果。
--从订单明细表（order_detail）和商品信息表（sku_info）表中统计2021年国庆节期间（10月1日-10月7日）
-- 每天各个分类的商品的动销率和滞销率
with t1 AS
    (select
        od.create_date,
        si.category_id,
        sum(sku_num) total_sku_num
    from
        order_detail od
    left join
            sku_info si
    on
        od.sku_id = si.sku_id
    where
        od.create_date >= "2021-10-01"
        and
        od.create_date <= "2021-10-07"
    group by
        od.create_date,
        si.category_id),
t2 AS (
    select
        count(distinct category_id) total_category_num
    from
        sku_info),
t3 AS (
    select
        create_date,
        count(distinct category_id) category_sale_cnt
    from
        t1
    group by
        create_date),
t4 AS (
    select
        create_date,
        total_category_num - category_sale_cnt category_no_sale_cnt
    from
        t2,t3)
select
    t3.create_date,
    cast(category_sale_cnt / t2.total_category_num as decimal(10,2)) sale_rate,
    cast(category_no_sale_cnt / t2.total_category_num as decimal(10,2)) no_sale_rate
from
    t3,t2
join
        t4
on
    t3.create_date = t4.create_date;