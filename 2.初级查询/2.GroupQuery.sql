-- TODO 分组查询
-- 1.查询编号为“02”的课程的总成绩
select
    sum(score) total_score
from
    score_info
where
    course_id = "02"
group by course_id;

-- 2.查询参加考试的学生个数
-- group by
select
    count(1) cnt
from
    (select
        stu_id
    from
        score_info
    group by
        stu_id)t1;

-- distinct
select
    count(distinct stu_id) cnt
from
    score_info;

-- 3.查询各科成绩最高和最低的分，以如下的形式显示：课程号、最高分、最低分
select
    course_id,
    max(score) max_score,
    min(score) min_score
from
    score_info
group by
    course_id;

-- 4.查询每门课程有多少学生参加了考试（有考试成绩）
select
    course_id,
    count(1) cnt
from
    score_info
group by course_id;

-- 5.查询男生、女生人数
select
    sex,
    count(1) cnt
from
    student_info
group by
    sex;

-- 6.查询平均成绩大于60分的学生的学号和平均成绩
select
    stu_id,
    avg(score) avg_score
from
    score_info
group by
    stu_id
having
    avg_score > 60;

-- 7.查询至少考了四门课程的学生学号
select
    stu_id,
    count(1) cnt
from
    score_info
group by
    stu_id
having
    cnt >= 4;

-- 8.查询每门课程的平均成绩，结果按平均成绩升序排序，平均成绩相同时，按课程号降序排列
select
    course_id,
    avg(score) avg_score
from
    score_info
group by
    course_id
order by
    avg_score asc,
    course_id desc;

-- 9.统计参加考试人数大于等于15的学科
select
    course_id,
    count(1) cnt
from
    score_info
group by
    course_id
having
    cnt >= 15;

-- 10.查询学生的总成绩并按照总成绩降序排序
select
    stu_id,
    sum(score) total_score
from
    score_info
group by
    stu_id
order by
    total_score desc ;

-- 11.查询一共参加三门课程且其中一门为语文课程的学生的id和姓名
select
    st.stu_id,
    st.stu_name
from
    student_info st
join
    (select
        stu_id,
        count(*) cnt
    from
        score_info
    where
        stu_id in
        (select
             stu_id
        from
            score_info
        where
            course_id = (select course_id from course_info where course_name = '语文')
        )
    group by
        stu_id
    having
        count(*) = 3)t1
on
    t1.stu_id = st.stu_id;

