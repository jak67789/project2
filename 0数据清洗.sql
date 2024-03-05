#查看重复值
SELECT user_id, item_id, time_stamp
FROM userbehavior
GROUP BY user_id, item_id, time_stamp
HAVING COUNT(*) > 1;

#查看缺失值
SELECT count(user_id), count(item_id), count(category), count(behavior), count(time_stamp)
FROM userbehavior;

#时间格式转换
UPDATE userbehavior
SET time = FROM_UNIXTIME(time_stamp, '%Y-%m-%d %H:%i:%s'),
	date = FROM_UNIXTIME(time_stamp, '%Y-%m-%d'),
	hour = FROM_UNIXTIME(time_stamp, '%H');


#检查日期是否都在2017年11月25日至2017年12月3日之间
SELECT MIN(date), MAX(date)
FROM userbehavior;

#排除日期不在2017年11月25日至2017年12月3日之间的数据
DELETE FROM userbehavior
WHERE date < '2017-11-25' OR date > '2017-12-03';


#复购率
SELECT SUM(IF(购买数 > 1, 1, 0)) AS '复购总人数'
	,COUNT(user_id) AS '购买总人数'
	,ROUND(100 * SUM(IF(购买数 > 1, 1, 0)) / COUNT(user_id), 2) AS '复购率'
FROM 用户行为数据
WHERE 购买数 > 0;