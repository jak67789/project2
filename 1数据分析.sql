#数据分析

#复购率
SELECT SUM(IF(购买数 > 1, 1, 0)) AS '复购总人数'
	,COUNT(user_id) AS '购买总人数'
	,ROUND(100 * SUM(IF(购买数 > 1, 1, 0)) / COUNT(user_id), 2) AS '复购率'
FROM 用户行为数据
WHERE 购买数 > 0;

#UV、PV、UV/PV指标统计
CREATE VIEW UV_PV_UVPV
AS
SELECT COUNT(DISTINCT user_id) AS UV
	,SUM(IF(behavior = 'pv', 1, 0)) AS PV
	,SUM(IF(behavior = 'buy', 1, 0)) AS Buy
	,SUM(IF(behavior = 'cart', 1, 0)) AS Cart
	,SUM(IF(behavior = 'fav', 1, 0)) AS Fav
	,SUM(IF(behavior = 'pv', 1, 0)) / COUNT(DISTINCT user_id) AS 'PV/UV'
FROM userbehavior;

#创建以user_id分组的用户行为数据视图
CREATE VIEW 用户行为数据 AS
	SELECT user_id
		,COUNT(behavior) AS 用户行为总数
		,SUM(IF(behavior = 'pv', 1, 0)) AS '浏览数'
		,SUM(IF(behavior = 'fav', 1, 0)) AS '收藏数'
		,SUM(IF(behavior = 'cart', 1, 0)) AS '加购数'
		,SUM(IF(behavior = 'buy', 1, 0)) AS '购买数'
	FROM userbehavior
	GROUP BY user_id
	ORDER BY 用户行为总数 DESC;
	
SELECT * FROM 用户行为数据;


#复购率
CREATE VIEW 复购率
AS
SELECT SUM(IF(购买数 > 1, 1, 0)) AS '复购总人数'
	,COUNT(user_id) AS '购买总人数'
	,CONCAT(ROUND(100 * SUM(IF(购买数 > 1, 1, 0)) / COUNT(user_id), 2),"%")   AS '复购率'
FROM 用户行为数据
WHERE 购买数 > 0;


#支付转换率
CREATE VIEW 支付转换率
AS
SELECT SUM(IF(`购买数` > 0 , 1 , 0) )AS "购买用户数"
	,SUM(IF(`浏览数` > 0 , 1 , 0)) AS "访客数"
	,CONCAT(ROUND(100 * SUM(IF(`购买数` > 0 , 1 , 0))/SUM(IF(`浏览数` > 0 , 1 , 0))),"%") AS "支付转换率"
	FROM `用户行为数据`;


#用户总行为漏斗
CREATE VIEW 用户总行为计数
AS
SELECT behavior, COUNT(*)
FROM userbehavior
GROUP BY behavior
ORDER BY behavior DESC;

SELECT CONCAT(ROUND(100 * SUM(IF(behavior = 'cart', 1, 0)) / SUM(IF(behavior = 'pv', 1, 0)),2),'%') AS '浏览至加购转化率'
FROM userbehavior;

SELECT CONCAT(ROUND(100 * SUM(IF(behavior = 'buy', 1, 0)) / SUM(IF(behavior = 'cart', 1, 0)),2),'%') AS '加购至购买转化率'
FROM userbehavior;

#独立访客转化漏斗
CREATE VIEW 独立访客行为统计
AS
SELECT behavior, COUNT(DISTINCT user_id)
FROM userbehavior
GROUP BY behavior
ORDER BY behavior DESC;


#RFM模型分析法
#R 购买间隔
CREATE VIEW r_value
AS
SELECT user_id , DATEDIFF("2017-12-03",MAX(date)) AS R
FROM userbehavior
WHERE behavior = 'buy'
GROUP BY user_id
ORDER BY R ASC;

#根据R评价
CREATE VIEW r_score AS
SELECT user_id , R
	,CASE 
	WHEN R BETWEEN 0 AND 2 THEN 3
	WHEN R BETWEEN 2 AND 4 THEN 2
	ELSE 1
END AS R评分
FROM r_value
GROUP BY user_id
ORDER BY R DESC;

#R评分计数
SELECT `R评分` , COUNT(`R评分`)
FROM r_score
GROUP BY `R评分`
ORDER BY `R评分`;

#F消费频率
CREATE VIEW f_value 
AS
SELECT user_id, COUNT(behavior) AS F 
FROM userbehavior
WHERE behavior = 'buy'
GROUP BY user_id
ORDER BY F DESC;

#根据F值评价
CREATE VIEW f_score AS
SELECT user_id , F
	,CASE 
	WHEN F BETWEEN 1 AND 24 THEN 1
	WHEN F BETWEEN 25 AND 49 THEN 2
	ELSE 3
END AS F评分
FROM f_value
GROUP BY user_id
ORDER BY F DESC;

#F评分计数
SELECT `F评分` , COUNT(`F评分`)
FROM f_score
GROUP BY `F评分`
ORDER BY `F评分`;


#时间维度
#每天的用户行为分析
CREATE VIEW 每日用户行为分析
AS
SELECT date
	,COUNT(DISTINCT user_id) AS '每日用户数'
	,SUM(IF(behavior = 'pv', 1, 0)) AS '浏览数'
	,SUM(IF(behavior = 'fav', 1, 0)) AS '收藏数'
	,SUM(IF(behavior = 'cart', 1, 0)) AS '加购数'
	,SUM(IF(behavior = 'buy', 1, 0)) AS '购买数'
FROM userbehavior
GROUP BY date;

#每时用户行为分析
CREATE VIEW 每时用户行为分析
AS
SELECT hour
	,COUNT(DISTINCT user_id) AS '每日用户数'
	,SUM(IF(behavior = 'pv', 1, 0)) AS '浏览数'
	,SUM(IF(behavior = 'fav', 1, 0)) AS '收藏数'
	,SUM(IF(behavior = 'cart', 1, 0)) AS '加购数'
	,SUM(IF(behavior = 'buy', 1, 0)) AS '购买数'
FROM userbehavior
GROUP BY hour;


#商品维度
#售出商品总数
SELECT COUNT(DISTINCT item_id)
FROM userbehavior
WHERE behavior = 'buy';

#商品浏览量排行榜前10
CREATE VIEW 商品浏览量排行前10
AS
SELECT item_id, COUNT(behavior) AS '浏览次数'
FROM userbehavior
WHERE behavior = 'pv'
GROUP BY item_id
ORDER BY 浏览次数 DESC
LIMIT 10;

#商品销量排行榜前10
CREATE VIEW 商品销量排行前10
AS
SELECT item_id, COUNT(behavior) AS '购买次数'
FROM userbehavior
WHERE behavior = 'buy'
GROUP BY item_id
ORDER BY 购买次数 DESC
LIMIT 10;

#销售榜前50的商品的浏览量——相关分析
/*
SELECT 
a.item_id,
a.购买次数,
b.浏览次数
FROM(
CREATE VIEW buy_limit50
AS
SELECT item_id, COUNT(behavior) AS '购买次数'
FROM userbehavior
WHERE behavior = 'buy'
GROUP BY item_id
ORDER BY 购买次数 DESC
LIMIT 50
AS a
LEFT JOIN(
CREATE VIEW pv_limit50 AS p
AS
SELECT item_id, COUNT(behavior) AS '浏览次数'
FROM userbehavior
WHERE behavior = 'pv'
GROUP BY item_id
ORDER BY 浏览次数 DESC
LIMIT 50
AS b
on a.item_id = b.item_id)
*/

CREATE VIEW buy_limit50 AS  
SELECT item_id, COUNT(behavior) AS 购买次数  
FROM userbehavior  
WHERE behavior = 'buy'  
GROUP BY item_id  
ORDER BY 购买次数 DESC  
LIMIT 50;  

CREATE VIEW pv_limit50 AS  
SELECT item_id, COUNT(behavior) AS 浏览次数  
FROM userbehavior  
WHERE behavior = 'pv'  
GROUP BY item_id  
ORDER BY 浏览次数 DESC  
LIMIT 50;  

CREATE VIEW buy_pv_limit50_analysis
AS
SELECT a.item_id,  
a.购买次数,  
b.浏览次数  
FROM buy_limit50 a  
LEFT JOIN pv_limit50 b ON a.item_id = b.item_id;











