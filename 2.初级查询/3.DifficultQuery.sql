-- TODO 复杂查询
-- 1.查询没有学全所有课的学生的学号、姓名
select
    si.stu_id,
    si.stu_name,
    count(si.stu_id)
from
    student_info si
left join
    score_info s
on
    si.stu_id = s.stu_id
group by
    si.stu_id,si.stu_name
having
    count(si.stu_id) < (select count(*) from course_info);

-- 2.查询出只选修了三门课程的全部学生的学号和姓名
select
    si.stu_id,
    si.stu_name,
    count(si.stu_id) cnt
from
    student_info si
left join
    score_info s
on
    si.stu_id = s.stu_id
group by
    si.stu_id,si.stu_name
having
    cnt == 3;

-- 3.查询所有学生的学号、姓名、选课数、总成绩
select
    si.stu_id,
    si.stu_name,
    count(si.stu_id) cnt,
    nvl(sum(score),0) total_score
from
    student_info si
left join
    score_info s
on
    si.stu_id = s.stu_id
group by
    si.stu_id,si.stu_name;

-- TODO nvl 函数说明
-- 如果参数一的值为 null 那么则返回参数二的值

-- 4.查询平均成绩大于 85 的所有学生的学号、姓名和平均成绩
select
    si.stu_id,
    si.stu_name,
    avg(score) average_score
from
    student_info si
left join
    score_info s
on
    si.stu_id = s.stu_id
group by
    si.stu_id,si.stu_name
having average_score > 85;

-- 5.查询学生的选课情况：学号，姓名，课程号，课程名称
select
  sti.stu_id,
  sti.stu_name,
  ci.course_id,
  ci.course_name
from
  student_info sti
left join
  score_info sci
on
  sti.stu_id=sci.stu_id
left join
  course_info ci
on
  sci.course_id=ci.course_id;

-- 6.查询课程编号为03且课程成绩在80分以上的学生的学号和姓名及课程信息
select
    si.stu_id,
    si.stu_name,
    ci.course_id,
    ci.course_name,
    s.score
from
    student_info si
left join
    score_info s
on
    si.stu_id = s.stu_id
left join
    course_info ci
on
    s.course_id = ci.course_id
where
    s.course_id = "03"
    and
    s.score > 80;

-- 7.课程编号为"01"且课程分数小于60，按分数降序排列的学生信息
select
    si.stu_id,
    si.stu_name,
    s.score
from
    student_info si
left join
    score_info s
on
    si.stu_id = s.stu_id
where
    s.course_id = "01"
    and
    s.score < 60
order by
    s.score desc;

-- 8. 查询所有课程成绩在70分以上的学生的姓名、课程名称和分数，按分数升序排列
select
    si.stu_name,
    ci.course_name,
    sci.score
from
    student_info si
join
    (select
        stu_id,
        sum(if(score>70,0,1)) flag
    from
        score_info
    group by
        stu_id
    having flag == 0)t1
on
    si.stu_id = t1.stu_id
left join
    score_info sci
on
    sci.stu_id = si.stu_id
left join
    course_info ci
on
    sci.course_id = ci.course_id
order by
    sci.score;

-- 9.查询各个学生不同课程但成绩相同的学生编号、课程编号、学生成绩
select
    s1.stu_id,s1.course_id,s1.score
from
    score_info s1
left join
    score_info s2
on
    s1.stu_id = s2.stu_id
    and
    s1.score = s2.score
where
    s1.course_id != s2.course_id;

-- 10.查询课程编号为“01”的课程比“02”的课程成绩高的所有学生的学号
select
    s1.stu_id
from
    score_info s1
join
    score_info s2
on
    s1.stu_id = s2.stu_id
    and
    s1.course_id <> s2.course_id
where
    s1.course_id = "01"
    and
    s2.course_id = "02"
    and
    s1.score > s2.score;

-- 11.查询学过编号为“01”的课程并且也学过编号为“02”的课程的学生的学号、姓名
select
    s1.stu_id,
    si.stu_name
from
    score_info s1
join
    score_info s2
on
    s1.stu_id = s2.stu_id
    and
    s1.course_id <> s2.course_id
join
    student_info si
on
    s1.stu_id = si.stu_id
where
    s1.course_id = "01"
    and
    s2.course_id = "02";

-- 12.查询学过“李体音”老师所教的所有课的同学的学号、姓名
select
    si.stu_id,
    si.stu_name
from
    (select
         sci.stu_id,
         `if`(array_contains(t1.tea_course_id, course_id), 1, 0) flag
    from score_info sci,
       (select
            collect_list(ci.course_id) tea_course_id
       from
           course_info ci
       join
           teacher_info ti
       on
           ci.tea_id = ti.tea_id
        where ti.tea_name = "李体音"
        group by ti.tea_id) t1 )t2
join
        student_info si
on
    si.stu_id = t2.stu_id
group by
    si.stu_id,si.stu_name
having
    sum(flag) == (
       select
            count(1) cnt
       from
           course_info ci
       join
           teacher_info ti
       on
           ci.tea_id = ti.tea_id
        where ti.tea_name = "李体音"
        group by ti.tea_id);

-- 13.查询学过“李体音”老师所讲授的任意一门课程的学生的学号、姓名
select
    distinct
    sci.stu_id,
    sci.stu_name
from
    student_info sci,
    (select
        collect_set(ci.course_id) course_id_list
    from
        teacher_info ti
    join
            course_info ci
    on
        ti.tea_id = ci.tea_id
    where
        tea_name = "李体音"
    group by
        ti.tea_id)t1
join
        score_info si
on
    sci.stu_id = si.stu_id
where
    array_contains(t1.course_id_list,course_id);

-- 14.查询没学过"李体音"老师讲授的任一门课程的学生姓名
select
    si.stu_id,
    si.stu_name
from
    student_info si
left join
    (select
        distinct
        si.stu_id
    from
        student_info si
    join
            score_info s
    on
        si.stu_id = s.stu_id
    join
            course_info ci
    on
        s.course_id = ci.course_id
    where
        ci.course_id in
            (select  course_id
            from teacher_info ti
            join course_info ci on ti.tea_id = ci.tea_id
            where ti.tea_name="李体音"
            group by course_id))t1
on
    si.stu_id = t1.stu_id
where
    t1.stu_id is null;

-- 15.查询至少有一门课与学号为 “001” 的学生所学课程相同的学生的学号和姓名
select
    distinct
    si.stu_id,
    si.stu_name
from
    student_info si
join
        score_info s
on
    si.stu_id = s.stu_id
where course_id in
      (select
           course_id
       from
           score_info
       where
           stu_id = "001")
    and
    si.stu_id != "001";

-- 16.按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩
select
    si.stu_id,
    si.stu_name,
    score,
    t1.avg_score
from
    student_info si
left join
        score_info sci
on
    sci.stu_id = si.stu_id
left join
        (select
            si.stu_id,
            avg(score) avg_score
        from
            student_info si
        left join
                score_info sci
        on
            sci.stu_id = si.stu_id
        group by
            si.stu_id)t1
on
    t1.stu_id = si.stu_id
order by
    t1.avg_score desc;