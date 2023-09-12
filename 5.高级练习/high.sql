--TODO 高级练习

-- TODO 第一题
-- 现有各直播间的用户访问记录表（live_events）如下：
-- user_id(用户id)  live_id(直播间id) in_datetime(进入直播间的时间) out_datetime(离开直播间的时间)
-- 100	1	2021-12-1 19:30:00	2021-12-1 19:53:00
-- 100	2	2021-12-1 21:01:00	2021-12-1 22:00:00
-- 101	1	2021-12-1 19:05:00	2021-12-1 20:55:00
-- 表中每行数据表达的信息为，一个用户何时进入了一个直播间，又在何时离开了该直播间，
-- 现要求统计各直播间最大同时在线人数。
select
    live_id,
    max(total_users) max_total_users
from
    (select
        live_id,
        in_datetime,
        sum(flag) over(partition by live_id order by in_datetime) total_users
    from
        (select
            live_id,
            in_datetime,
            1 flag
        from
            high.live_events
        union all
        select
            live_id,
            out_datetime,
            -1 flag
        from
            high.live_events)t1 )t2
group by
    live_id;

-- TODO 第二题
-- 现有页面浏览记录表（page_view_events），表中有每个用户的每次页面访问记录。
-- 规定若同一用户的相邻两次访问记录时间间隔小于60s，则认为两次浏览记录属于同一会话。
-- 现有如下需求，为属于同一会话的访问记录增加一个相同的会话id字段，期望结果如下：
select
    user_id,
    page_id,
    view_timestamp,
    concat(user_id,"_",sum(flag) over(partition by user_id order by view_timestamp)) session_id
from
    (select
        user_id,
        page_id,
        view_timestamp,
        `if`(view_timestamp-lag_view_timestamp >= 60 ,1,0) flag
    from
        (select
            user_id,
            page_id,
            view_timestamp,
            lag(view_timestamp,1,0) over(partition by user_id order by view_timestamp) lag_view_timestamp
        from
            page_view_events)t1 )t2;

-- TODO 第三题
-- 现有各用户的登录记录表（login_events）如下，表中每行数据表达的信息是一个用户何时登录了平台。
-- user_id	login_datetime
-- 100	2021-12-01 19:00:00
-- 100	2021-12-01 19:30:00
-- 100	2021-12-02 21:01:00
-- 现要求统计各用户最长的连续登录天数，间断一天也算作连续
-- 例如：一个用户在1,3,5,6登录，则视为连续6天登录。期望结果如下：
select
    user_id,
    max(cnt) max_cnt
from
    (select
        user_id,
        login_date,
        sum(flag) over(partition by user_id order by login_date) cnt
    from
        (select
            user_id,
            login_date,
            `if`(
                    datediff(login_date,lag_login_date)<=2,
                    `if`(datediff(login_date,lag_login_date)=2,2,1),
                    if(lag_login_date="1970-01-01",1,0)
                ) flag
        from
            (select
                user_id,
                login_date,
                lag(login_date,1,"1970-01-01") over (partition by user_id order by login_date) lag_login_date
            from
                (select
                    user_id,
                    to_date(login_datetime) login_date
                from
                    login_events
                group by
                    user_id,to_date(login_datetime) )t1 )t2 )t3 )t4
group by
    user_id;

--TODO 第四题
-- 现有各品牌优惠周期表（promotion_info）如下，
-- 其记录了每个品牌的每个优惠活动的周期，其中同一品牌的不同优惠活动的周期可能会有交叉。
-- promotion_id	brand	start_date	end_date
--      1	oppo	2021-06-05	2021-06-09
--      2	oppo	2021-06-11	2021-06-21
--      3	vivo	2021-06-05	2021-06-15
-- 现要求统计每个品牌的优惠总天数，若某个品牌在同一天有多个优惠活动，则只按一天计算。

select
    brand,
    sum(datediff(end_date,start_date) + 1) days
from
    (select
        brand,
        max_end_date,
        `if`(
            max_end_date is null or start_date > max_end_date,
            start_date,
            date_add(max_end_date,1)) start_date,
        end_date
    from
        (select
            brand,
            start_date,
            end_date,
            max(end_date) over(partition by brand order by start_date rows between unbounded preceding and 1 preceding) max_end_date
        from
            promotion_info )t1 )t2
where
    end_date > start_date
group by
    brand;