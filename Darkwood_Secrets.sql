/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Лысак Мария
 * Дата: 26.12.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT 
	COUNT(id) AS number_of_users,
	SUM(payer) AS number_of_payers,
	ROUND(AVG(payer),3) AS payer_part
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT
	r.race_id,
	r.race,
	SUM(u.payer) AS number_of_payers,
	COUNT(*) AS number_of_players,
	ROUND(AVG(u.payer),3) AS part_of_payers
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id=r.race_id
GROUP BY r.race, r.race_id
ORDER BY number_of_players DESC;
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT
  COUNT(DISTINCT transaction_id) AS number_of_purchases,
  SUM(amount) AS sum_of_purchases,
  MIN(amount) AS min_amount,
  MAX(amount) AS max_amount,
  ROUND(AVG(amount)::numeric, 3) AS avg_amount,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY amount)::numeric,3) AS median,
  ROUND(STDDEV(amount)::numeric,3) AS stand_dev
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
SELECT
	COUNT(transaction_id) AS number_of_purchases,
	COUNT(transaction_id) FILTER(WHERE amount=0) AS zero_purchases,
	COUNT(transaction_id) FILTER(WHERE amount=0)/COUNT(transaction_id)::real AS zero__part
FROM fantasy.events;

-- 2.3: Популярные эпические предметы:
WITH sales AS (
  SELECT 
    i.item_code, 
    i.game_items,
    COUNT(e.transaction_id) AS item_sales,
    (SELECT COUNT(*) FROM fantasy.events WHERE amount > 0)  AS all_sales 
  FROM fantasy.events AS e
  LEFT JOIN fantasy.items AS i ON e.item_code=i.item_code
  WHERE e.amount>0
  GROUP BY i.item_code, i.game_items
),
payers AS (
  SELECT
    item_code,
    COUNT(DISTINCT id) AS buyers,
    (SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount>0) AS pay_id
  FROM fantasy.events
  WHERE amount>0
  GROUP BY item_code
)
SELECT 
  s.item_code, 
  s.game_items,
  s.item_sales,
  ROUND(s.item_sales/s.all_sales::numeric,3)*100 AS part_of_sales,
  ROUND(p.buyers/p.pay_id::numeric,3)*100 AS part_of_users
FROM sales AS s
LEFT JOIN payers AS p ON s.item_code=p.item_code
ORDER BY item_sales DESC;
-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH payers AS (
	SELECT
		u.race_id,
		COUNT(DISTINCT u.id) AS pay_players
	FROM fantasy.users AS u
	JOIN fantasy.events AS e ON u.id=e.id
	WHERE u.payer=1 AND e.amount>0
	GROUP BY u.race_id
),
player_activity AS (
	SELECT
		u.race_id,
		COUNT(e.transaction_id) AS all_trans,
		COUNT(DISTINCT e.id) AS buy_players,
		SUM(e.amount) AS sum_purchases
	FROM fantasy.users AS u
	JOIN fantasy.events AS e USING(id)
	WHERE amount>0
	GROUP BY u.race_id
)
SELECT
	u.race_id,
	r.race,
	COUNT(*) AS all_users,
	pa.buy_players,
	p.pay_players,
	pa.all_trans,
	pa.sum_purchases,
	ROUND(p.pay_players/pa.buy_players::numeric,3) AS part_of_pay_buyers,
	ROUND(pa.buy_players/COUNT(*)::numeric,3) AS part_of_buyers,
	ROUND(pa.all_trans/pa.buy_players::numeric,3) AS purch_per_player,
	ROUND((pa.sum_purchases/pa.all_trans)::numeric,3) AS avg_amount,
	ROUND((pa.sum_purchases/pa.buy_players)::numeric,3) AS sum_avg_amount
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id=r.race_id
JOIN payers AS p ON u.race_id=p.race_id
JOIN player_activity AS pa ON u.race_id=pa.race_id
GROUP BY u.race_id,r.race,buy_players,pay_players,pa.all_trans,pa.sum_purchases
ORDER BY all_users DESC;