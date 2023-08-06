-- 1.查询姓名中带“山”的学生名单
select * from student_info where stu_name like "%山%";

-- 2.查询姓“王”老师的个数
select count(1) cnt from teacher_info where tea_name like "%王%";

-- 3.检索课程编号为“04”且分数小于60的学生的分数信息，结果按分数降序排列
select
    ci.course_id,
    ci.course_name,
    ci.tea_id,
    si.stu_id,
    si.score
from
    course_info ci
join
        score_info si
    on
        ci.course_id = si.course_id
where
    ci.course_id="04" and si.score < 60
order by
    score desc ;

-- 4.查询数学成绩不及格(<60)的学生信息和其对应的数学学科成绩，按照学号升序排序
select
   si.stu_id, stu_name, birthday, sex, si.course_id, si.score
from
    (select course_id from course_info where course_name="数学") ci,student_info
join
        score_info si
on
    ci.course_id = si.course_id
    and
    student_info.stu_id = si.stu_id
where
    si.score < 60
order by
    si.stu_id;


