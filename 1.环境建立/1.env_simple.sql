-- TODO 基础查询环境建立

-- TODO 1.创建相关数据表
-- 创建学生表
DROP TABLE IF EXISTS student_info;
create table if not exists student_info(
    stu_id string COMMENT '学生id',
    stu_name string COMMENT '学生姓名',
    birthday string COMMENT '出生日期',
    sex string COMMENT '性别'
)
row format delimited fields terminated by ','
stored as textfile;

-- 创建课程表
DROP TABLE IF EXISTS course_info;
create table if not exists course_info(
    course_id string COMMENT '课程id',
    course_name string COMMENT '课程名',
    tea_id string COMMENT '任课老师id'
)
row format delimited fields terminated by ','
stored as textfile;

-- 创建老师表
DROP TABLE IF EXISTS teacher_info;
create table if not exists teacher_info(
    tea_id string COMMENT '老师id',
    tea_name string COMMENT '老师姓名'
)
row format delimited fields terminated by ','
stored as textfile;

-- 创建分数表
DROP TABLE IF EXISTS score_info;
create table if not exists score_info(
    stu_id string COMMENT '学生id',
    course_id string COMMENT '课程id',
    score int COMMENT '成绩'
)
row format delimited fields terminated by ','
stored as textfile;


-- TODO 2.载入数据
-- 注意更换数据文件路径
load data local inpath '/opt/software/HiveSQLStudy/student_info.txt' into table student_info;

load data local inpath '/opt/software/HiveSQLStudy/course_info.txt' into table course_info;

load data local inpath '/opt/software/HiveSQLStudy/teacher_info.txt' into table teacher_info;

load data local inpath '/opt/software/HiveSQLStudy/score_info.txt' into table score_info;
