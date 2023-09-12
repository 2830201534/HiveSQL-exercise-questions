-- TODO 中级练习

--1.查询订单明细表（order_detail）中销量（下单件数）排名第二的商品id
-- 如果不存在返回null，如果存在多个排名第二的商品则需要全部返回。
select
    nvl(sku_id,null) sku_id
from
    (select
        sku_id,
        dense_rank() over (order by total_sku_num desc) dk
    from
        (select
            sku_id,
            sum(sku_num) total_sku_num
        from
            order_detail
        group by
            sku_id)t1)t2
where
    dk = 2;


--2.查询订单信息表(order_info)中最少连续3天下单的用户id
select
    distinct user_id
from
    (select
        user_id,
        create_date,
        lag(create_date,1,"1970-01-01") over (partition by user_id order by create_date) lag_day,
        lead(create_date,1,"9999-99-99") over (partition by user_id order by create_date) lead_day
    from
        (select
            user_id,
            create_date
        from
            order_info
        group by
            user_id, create_date)t1)t2
where
    datediff(create_date,lag_day) = 1
    and
    datediff(lead_day,create_date) = 1;

--3.从订单明细表(order_detail)统计各品类销售出的商品种类数及累积销量最好的商品
select
    category_id,
    category_name,
    sku_id,
    name,
    total_sku_num,
    sku_cnt
from
    (select
        ci.category_id,
        ci.category_name,
        s.sku_id,
        s.name,
        total_sku_num,
        count(1) over(partition by ci.category_id) sku_cnt,
        dense_rank() over(partition by ci.category_id order by total_sku_num desc) dk
    from
        (select
            si.category_id,
            si.sku_id,
            sum(sku_num) total_sku_num
        from
            order_detail od
        left join
                sku_info si
        on
            od.sku_id = si.sku_id
        group by
            si.category_id,
            si.sku_id)t1
    left join
            category_info ci
    on
        t1.category_id = ci.category_id
    left join
            sku_info s
    on
        t1.sku_id = s.sku_id)t2
where
    dk = 1;

--4.从订单信息表(order_info)中
-- 统计每个用户截止其每个下单日期的累积消费金额以及每个用户在其每个下单日期的VIP等级。
-- 用户vip等级根据累积消费金额计算，计算规则如下：
-- 设累积消费总额为X，
-- 若0=<X<10000,则vip等级为普通会员
-- 若10000<=X<30000,则vip等级为青铜会员
-- 若30000<=X<50000,则vip等级为白银会员
-- 若50000<=X<80000,则vip为黄金会员
-- 若80000<=X<100000,则vip等级为白金会员
-- 若X>=100000,则vip等级为钻石会员
select
    user_id,
    create_date,
    today_total_amount,
    case when today_total_amount >= 0 and today_total_amount < 10000
         then "普通会员"
         when today_total_amount >= 10000 and today_total_amount < 30000
         then "青铜会员"
         when today_total_amount >= 30000 and today_total_amount < 50000
         then "白银会员"
         when today_total_amount >= 50000 and today_total_amount < 80000
         then "黄金会员"
         when today_total_amount >= 80000 and today_total_amount < 100000
         then "白金会员"
         else "钻石会员"
    end  customer_level
from
    (select
        distinct
        user_id,
        create_date,
        sum(total_amount) over(partition by user_id order by create_date) today_total_amount
    from
        order_info)t1;

--5.从订单信息表(order_info)中查询
-- 首次下单后第二天仍然下单的用户占所有下单用户的比例，结果保留一位小数，使用百分数显示
select
     concat(cast(two_day_order_user/total_user_cnt as decimal(8,1))*100,"%") rate
from
    (select
        count(distinct user_id) two_day_order_user
    from
        (select
            user_id,
            create_date,
            lead(create_date,1,"9999-99-99") over(partition by user_id order by create_date) lead_day,
            rank() over (partition by user_id order by create_date) rk
        from
            order_info
        group by
            user_id,
            create_date)t1
    where
        datediff(lead_day,create_date) = 1 and rk = 1)t2,
    (select count(distinct user_id) total_user_cnt from order_info)t3;

--6.从订单明细表(order_detail)统计每个商品销售首年的年份，销售数量和销售总额。
select
    sku_id, first_year, total_num, total_price
from
    (select
        sku_id,
        first_year,
        total_num,
        total_price,
        rank() over (partition by sku_id order by first_year) rk
    from
        (select
            sku_id,
            year(create_date) first_year,
            sum(sku_num) total_num,
            sum(sku_num*price) total_price
        from
            order_detail
        group by
            sku_id,
            year(create_date) )t1 )t2
where
    rk = 1
order by
    cast(sku_id as int);

--7.从订单明细表（order_detail）中统计出每种商品销售件数最多的日期及当日销量，
-- 如果有同一商品多日销量并列的情况，取其中的最小日期。
select
    sku_id,
    create_date,
    day_sku_num
from
    (select
        sku_id,
        create_date,
        day_sku_num,
        row_number() over (partition by sku_id order by day_sku_num desc,create_date asc) rn
    from
        (select
            sku_id,
            create_date,
            sum(sku_num) day_sku_num
        from
            order_detail
        group by
            sku_id,
            create_date)t1 )t2
where
    rn = 1
order by
    cast(sku_id as int);


--8.从订单明细表（order_detail）中查询累积销售件数高于其所属品类平均数的商品
select
    sku_id,
    name,
    total_sku_num,
    category_id,
    category_name,
    cast(`floor`(category_total_sku_num / sku_cnt) as decimal(10,0)) category_sku_num_avg
from
    (select
        si.sku_id,
        total_sku_num,
        name,
        category_name,
        ci.category_id,
        sum(total_sku_num) over(partition by ci.category_id) category_total_sku_num,
        count(distinct si.sku_id) over(partition by ci.category_id) sku_cnt
    from
        sku_info si
    join
        (select
            sku_id,
            sum(sku_num) total_sku_num
        from
            order_detail
        group by
            sku_id)t1
    on
        si.sku_id = t1.sku_id
    left join
            category_info ci
    on
        si.category_id = ci.category_id)t2
where
    category_total_sku_num / sku_cnt < total_sku_num
order by
    cast(sku_id as int);

--9.查询所有商品（sku_info表）截至到2021年10月01号的最新商品价格（需要结合价格修改表进行分析）
select
    sku_id, change_date, now_price
from
    (select
        distinct
        si.sku_id,
        change_date,
        `if`(spmd.new_price is null,si.price,spmd.new_price) now_price,
        rank() over (partition by si.sku_id order by change_date desc) rk
    from
        sku_info si
    left join
        sku_price_modify_detail spmd
    on
        si.sku_id = spmd.sku_id
    where
        datediff("2021-10-01",change_date) >= 0 )t1
where
    rk = 1
order by
    cast(sku_id as int);

--10.订单配送中，如果期望配送日期和下单日期相同，称为即时订单，如果期望配送日期和下单日期不同，称为计划订单。
-- 请从配送信息表（delivery_info）中求出每个用户的首单（用户的第一个订单）中即时订单占首单的比例，
-- 保留两位小数，以小数形式显示。
select
    distinct cast(now_delivery_cnt/total_cnt as decimal(8,2))
from
    (select
        sum(if(order_date=custom_date,1,0)) over() now_delivery_cnt,
        count(user_id) over () total_cnt
    from
        (select
            user_id,
            order_date,
            custom_date,
            row_number() over (partition by user_id order by order_date,custom_date) rn
        from
            delivery_info)t1
    where
        rn = 1)t2;

--11.从登录明细表（user_login_detail）中查询
-- 所有用户的连续登录两天及以上的日期区间，以登录时间（login_ts）为准。
select
    user_id,
    min(login_date),
    max(login_date)
from
    (select
        user_id,
        login_date,
        date_sub(login_date,rn) same_day
    from
        (select
            user_id,
            to_date(login_ts) login_date,
            row_number() over (partition by user_id order by to_date(login_ts)) rn
        from
            user_login_detail
        group by
            user_id,
            to_date(login_ts) )t1 )t2
group by
    user_id,same_day
having
    count(user_id) >= 2;

--12.从订单信息表（order_info）中查询出每个用户的最近三笔订单
select
    order_id, user_id, create_date, total_amount
from
    (select
        order_id,
        user_id,
        create_date,
        total_amount,
        row_number() over (partition by user_id order by create_date desc) rn
    from
        order_info)t1
where
    rn <= 3
order by
    user_id,
    create_date asc;

--13.从登录明细表（user_login_detail）中
-- 查询每个用户两个登录日期（以login_ts为准）之间的最大的空档期。
-- 统计最大空档期时，用户最后一次登录至今的空档也要考虑在内，假设今天为2021-10-10。
select
    user_id,
    login_date,
    next_login_date,
    lagout_day_cnt
from
    (select
        user_id,
        login_date,
        next_login_date,
        lagout_day_cnt,
        row_number() over(partition by user_id order by lagout_day_cnt desc) rn
    from
        (select
            user_id,
            login_date,
            next_login_date,
            datediff(next_login_date,login_date) lagout_day_cnt
        from
            (select
                user_id,
                to_date(login_ts) login_date,
                lead(to_date(login_ts),1,"2021-10-10") over (partition by user_id order by to_date(login_ts)) next_login_date
            from
                user_login_detail
            group by
                user_id,
                to_date(login_ts) )t1 )t2 )t3
where
    rn = 1;

--14.从登录明细表（user_login_detail）中查询在相同时刻（指登入和登出这个时区内），多地登陆（ip_address不同）的用户
select
    user_id,
    count(distinct ip_address) cnt
from
    (select
        user_id,
        ip_address,
        login_date,
        login_ts,
        logout_ts,
        lead(login_ts,1,null) over(partition by user_id,login_date order by login_ts) lead_login_ts,
        lead(ip_address,1,null) over(partition by user_id,login_date order by login_ts) lead_ip_address
    from
        (select
            user_id,
            ip_address,
            to_date(login_ts) login_date,
            login_ts,
            logout_ts
        from
            user_login_detail )t1 )t2
where
    ip_address <> lead_ip_address
    and
    unix_timestamp(lead_login_ts,"yyyy-MM-dd HH:mm:ss") >= unix_timestamp(login_ts,"yyyy-MM-dd HH:mm:ss")
    and
    unix_timestamp(lead_login_ts,"yyyy-MM-dd HH:mm:ss") <= unix_timestamp(logout_ts,"yyyy-MM-dd HH:mm:ss")
group by
    user_id;

--15.商家要求每个商品每个月需要售卖出一定的销售总额
--假设1号商品销售总额大于21000，2号商品销售总额大于10000，其余商品没有要求
--请写出SQL从订单详情表中（order_detail）查询连续两个月销售总额大于等于任务总额的商品
select
    sku_id,
    year,
    month,
    next_month,
    tow_month_total_amount
from
    (select
        sku_id,
        year,
        month,
        t3.next_month,
        month_total_amount + next_month_total_amount tow_month_total_amount
    from
        (select
            sku_id,
            year,
            month,
            month_total_amount,
            lead(month,1,null) over(partition by sku_id,year order by month) next_month,
            lead(month_total_amount,1,null) over(partition by sku_id,year order by month) next_month_total_amount
        from
            (select
                sku_id,
                year,
                month,
                sum(sku_num*price) month_total_amount
            from
                (select
                    sku_id,
                    year(create_date) year,
                    month(create_date) month,
                    price,
                    sku_num
                from
                    order_detail
                where
                    sku_id in ('1','2') )t1
            group by
                sku_id, year, month )t2 )t3
    where
        t3.next_month is not null
        and
        t3.next_month - month = 1 )t4
where
    `if`(sku_id = 1 and tow_month_total_amount > 21000,true,false)
    or
    `if`(sku_id = 2 and tow_month_total_amount > 20000,true,false);

--16.从订单详情表中（order_detail）和商品（sku_info）中查询
-- 各个品类销售数量前三的商品。如果该品类小于三个商品，则输出该品类下所有的商品销售总量。
-- 注意，统计的是销售量，不是销售额！
select
    sku_id, category_id, total_amount,dk
from
    (select
        od.sku_id,
        si.category_id,
        od.total_amount,
        dense_rank() over (partition by si.category_id order by od.total_amount desc) dk
    from
        (select
            sku_id,
            sum(sku_num) total_amount
        from
            order_detail
        group by
            sku_id) od
        join
                sku_info si
        on
            od.sku_id = si.sku_id )t1
where
    dk <= 3;

--17.从商品信息表（sku_info）中，统计每个分类中商品价格的中位数，
-- 如果某分类中商品个数为偶数，则输出中间两个价格的平均值，如果是奇数，则输出中间价格即可。
select
    distinct
    category_id,
    cast( `if`(
        flag = 0,
        price,
        avg(price) over(partition by category_id)
        ) as decimal(16,2)) median
from
    (select
        category_id,
        price,
        rn,
        `if`(max_rn % 2 = 0,1,0) flag,
        ceil(max_rn / 2) index
    from
        (select
            category_id,
            price,
            rn,
            max(rn) over(partition by category_id) max_rn
        from
            (select
                category_id,
                price,
                row_number() over (partition by category_id order by price) rn
            from
                sku_info )t1 )t2 )t3
where
    (flag = 1 and rn = index or rn = index+1)
    or
    (flag = 0 and rn = index);

--18.从订单详情表（order_detail）中找出销售额连续3天超过100的商品
select
    sku_id,
    lag_day,
    create_date,
    lead_day,
    lag_total_amount,
    total_amount,
    lead_total_amount,
    lag_total_amount + total_amount + lead_total_amount three_day_total_amount
from
    (select
      sku_id,
      create_date,
      total_amount,
      lag(create_date,1,"1970-01-01") over (partition by sku_id order by create_date) lag_day,
      lead(create_date,1,"9999-99-99") over (partition by sku_id order by create_date) lead_day,
      lag(total_amount,1,0) over (partition by sku_id order by create_date) lag_total_amount,
      lead(total_amount,1,0) over (partition by sku_id order by create_date) lead_total_amount
    from
        (select
            sku_id,
            create_date,
            sum(sku_num*price) total_amount
        from
            order_detail
        group by
            sku_id,
            create_date )t1 )t2
where
    datediff(create_date,lag_day) = 1
    and
    datediff(lead_day,create_date) = 1
    and
    total_amount > 100
    and
    lag_total_amount > 100
    and
    lead_total_amount > 100;

--19.从订单详情表（order_detail）中，求出商品连续售卖的时间区间
select
    sku_id,
    min(create_date) start_date,
    max(create_date) end_date
from
    (select
        sku_id,
        create_date,
        date_sub(create_date,row_number() over (partition by sku_id order by create_date)) date_rn
    from
        (select
            sku_id,
            create_date
        from
            order_detail
        group by
            sku_id,
            create_date )t1 )t2
group by
    sku_id,
    date_rn
having
    count(1) > 1
order by
    cast(sku_id as bigint);

--20.从商品价格变更明细表（sku_price_modify_detail）
-- 得到最近一次价格的涨幅情况，并按照涨幅升序排序。
select
    distinct
    sku_id,
    cast(last_value-first_value as decimal) change_price
from
    (select
        sku_id,
        first_value(new_price) over (partition by sku_id order by change_date rows between unbounded preceding and unbounded following) first_value,
        last_value(new_price) over (partition by sku_id order by change_date rows between unbounded preceding and unbounded following ) last_value
    from
        (select
            sku_id,
            new_price,
            change_date,
            rn,
            max(rn) over (partition by sku_id) max_rn
        from
            (select
                sku_id,
                new_price,
                change_date,
                row_number() over (partition by sku_id order by change_date desc) rn
            from
                sku_price_modify_detail )t1 )t2
    where
        rn = max_rn
        or
        rn = max_rn-1 )t3
order by
    change_price;

--21.通过商品信息表（sku_info）订单信息表（order_info）订单明细表（order_detail）
-- 分析如果有一个用户成功下单两个及两个以上的购买成功的手机订单（购买商品为xiaomi 10，apple 12，xiaomi 13）
-- 那么输出这个用户的id及第一次成功购买手机的日期和最后一次成功购买手机的日期，以及购买手机成功的次数。
select
    user_id,
    first_date,
    last_date,
    count(user_id) total_cnt,
    sum(price*sku_num) total_amount
from
    (select
        user_id,
        create_date,
        price,
        sku_num,
        first_value(create_date) over(partition by user_id order by create_date rows between unbounded preceding and unbounded following) first_date,
        last_value(create_date) over(partition by user_id order by create_date rows between unbounded preceding and unbounded following) last_date
    from
        (select
            oi.user_id,
            od.create_date,
            od.price,
            od.sku_num
        from
            sku_info si
        join
                order_detail od
        on
            si.sku_id = od.sku_id
        join
                order_info oi
        on
            od.order_id = oi.order_id
        where
            si.name in ("xiaomi 10","apple 12","xiaomi 13") )t1 )t2
where
    create_date = first_date
    or
    create_date = last_date
group by
    user_id, first_date, last_date;

--22.用户等级：
--忠实用户：近7天活跃且非新用户
--新晋用户：近7天新增
--沉睡用户：近7天未活跃但是在7天前活跃
--流失用户：近30天未活跃但是在30天前活跃
--假设今天是数据中所有登录日期的最大值，从用户登录明细表中的用户登录时间给各用户分级，求出各等级用户的人数

select
    level,
    count(1) cnt
from (select case
                 when register_date >= date_add(today, -6)
                     then "新晋用户"
                 when last_login_date >= date_add(today, -6)
                     then "忠实用户"
                 when last_login_date >= date_add(today, -13)
                     then "沉睡用户"
                 when last_login_date < date_add(today, -29)
                     then "流失用户"
                 end level
      from (select user_id,
                   date_format(min(login_ts), "yyyy-MM-dd") register_date,
                   date_format(max(login_ts), "yyyy-MM-dd") last_login_date
            from user_login_detail
            group by user_id) t1
               join (select date_format(max(login_ts), "yyyy-MM-dd") today from user_login_detail) t2 )t3
group by
    level;

--23.用户每天签到可以领1金币，并可以累计签到天数，连续签到的第3、7天分别可以额外领2和6金币。
-- 每连续签到7天重新累积签到天数。
-- 从用户登录明细表中求出每个用户金币总数，并按照金币总数倒序排序
select
    user_id,
    sum(same_day_gold) total_gold
from
    (select
        user_id,
        case when same_day_cnt = 7 --连续签到7天
                then 1 * 7 + 8
            when same_day_cnt = 3 --连续签到3天
                then 1 * 3 + 2
            when same_day_cnt < 3 --连续签到小于3天
                then same_day_cnt * 1
            when same_day_cnt < 7 --连续签到小于7天
                then same_day_cnt * 1 + 2
            when same_day_cnt % 7 = 0 --连续签到等于7*n天
                then same_day_cnt / 7 * (1 * 7 + 8)
            when same_day_cnt % 7 >= 3 --连续签到大于7*n+3(>=)天
                then ceil(same_day_cnt / 7) * (1 * 7 + 8) + 2 + same_day_cnt % 7 * 1
            when same_day_cnt % 7 < 3 --连续签到小于7*n+2天
                then ceil(same_day_cnt / 7) * (1 * 7 + 8) + same_day_cnt % 7 * 1
        end same_day_gold
    from
        (select
            user_id,
            count(1) same_day_cnt
        from
            (select
                user_id,
                login_date,
                date_sub(login_date,rn) same_day
            from
                (select
                    user_id,
                    login_date,
                    row_number() over (partition by user_id order by login_date) rn
                from
                    (select
                         user_id,
                         to_date(login_ts) login_date
                    from
                        user_login_detail
                    group by
                        user_id,
                        to_date(login_ts) )t1 )t2 )t3
        group by
            user_id,same_day )t4 )t5
group by
    user_id
order by
    total_gold desc ;

select 17 % 7