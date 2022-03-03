--Задание 1. В каких городах больше одного аэропорта?
 
select a.city
from airports a
group by a.city
having count(a.city) > 1 
; -- сначала группирую выборку по городам и с помощью having вывожу группы, содержащие более одной строки

--Задание 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
--(Подзапрос) 

select distinct r.departure_airport_name
from routes r
join aircrafts a on r.aircraft_code = a.aircraft_code
where a.range = (
   select max(a.range) 
   from aircrafts a)
; -- подзапрос выводит максимальную дальность полета,   
--соединение мат.представления routes с таблицей aircrafts 
--по условию равенства конкретного значения дальности 
--с максимальной дальностью полета (здесь обращаюсь к подзапросу) и определяет искомые аэропорты

--Задание 3. Вывести 10 рейсов с максимальным временем задержки вылета
--(Оператор LIMIT)

select f.flight_no, (f.actual_departure - f.scheduled_departure) d
from flights f
where f.actual_departure - f.scheduled_departure is not null
order by d desc
limit (10)
; -- разница времени реального отправления 
--и планируемого времени вылета отфильтрована по значению, отличного от NULL

--Задание 4. Были ли брони, по которым не были получены посадочные талоны?
--(Верный тип JOIN)

select t.book_ref
from tickets t 
left outer join boarding_passes bp on t.ticket_no = bp.ticket_no
where boarding_no isnull
; -- для того, чтобы вычислить "пустые значения" бронирований, не имеющих соответствия с посадочными талонами,
-- используется левое внешнее соединение, и они же отфильтровываются, выдавая искомый результат

--Задание 5. Найдите свободные места для каждого рейса, 
--их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - 
--суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--(Оконная функция, подзапросы).

select distinct f.departure_airport, f.actual_departure, 
   count(bp.boarding_no) over (partition by f.departure_airport, f.actual_departure order by f.actual_departure), 
   bp.flight_id, seats_relation.free_seats, seats_relation.percentage    
from boarding_passes bp 
join flights f on bp.flight_id = f.flight_id 
join (    
   select distinct taken_seats.flight_id as flight_id, all_seats.count::float - taken_seats.count as free_seats, 
      ((all_seats.count::float - taken_seats.count)*100/all_seats.count) as percentage --процентное отношение
   from (      
      select f.flight_id, count(s.seat_no)
      from seats s
      join flights f on s.aircraft_code = f.aircraft_code
      group by f.flight_id 
      ) as all_seats --общие места в самолете
   join (
      select bp.flight_id, count(bp.boarding_no)
      from boarding_passes bp
      group by bp.flight_id      
      ) as taken_seats --занятые места в самолете
   on all_seats.flight_id = taken_seats.flight_id
) as seats_relation on bp.flight_id = seats_relation.flight_id 
where f.actual_departure is not null
order by f.departure_airport, f.actual_departure
; --подзапросы нижнего уровня выводят,соответственно, общие и занятые места в самолете, 
--в подзапросе более высокого уровня вычисляется процентное отношение свободных мест в самолете 
--к общему количеству мест. Оконная функция считает нарастающее количество вывезенных пассажиров 
--благодаря сортировке order by в группировке по аэропорту отправления и времени вылета, причем по условию 
--отфильтровываются строки, содержащие значение в поле реального времени вылета.

--Задание 6. Найдите процентное отношение перелетов по типам самолетов от общего количества
--(Подзапрос, оператор ROUND)

select f.aircraft_code, 
   round(count(f.flight_id)::float / (
      select count(f.flight_id)::float 
      from flights f)*100) as relation
from flights f
group by f.aircraft_code
;
-- сначала группируются типы самолетов, затем определяется и округляется до целого
-- процентное отношение количества самолетов одного и того же типа к общему количеству.
-- с использованием подзапроса. Здесь интересно приведение количества к типу float, чтобы
-- отработал оператор round

--Задание 7. Были ли города, в которые можно добраться бизнес-классом дешевле, 
--чем эконом-классом в рамках перелета? (CTE) 

with segr_rows as (
   select tf.flight_id, fv.arrival_city, tf.fare_conditions, tf.amount 
   from flights_v fv
   join ticket_flights tf on fv.flight_id = tf.flight_id
   where tf.fare_conditions = 'Business'
   group by tf.flight_id, fv.arrival_city, tf.fare_conditions, tf.amount
), segr_rows1 as (
   select tf.flight_id, fv.arrival_city, tf.fare_conditions, tf.amount 
   from flights_v fv
   join ticket_flights tf on fv.flight_id = tf.flight_id
   where tf.fare_conditions = 'Economy' 
   group by tf.flight_id, fv.arrival_city, tf.fare_conditions, tf.amount
   )
select distinct segr_rows1.arrival_city
from segr_rows1, segr_rows
where segr_rows1.amount - segr_rows.amount > 0 and segr_rows1.flight_id = segr_rows.flight_id
;
--CTE разделяет запрос на части. Каждый из CTE формирует выборку данных по стоимости
--относительно класса обслуживания, а в основном запросе через условие сравниваются эти выборки
-- в рамках одного перелета

--Задание 8. Между какими городами нет прямых рейсов? (Декартово произведение в предложении FROM,
--самостоятельно созданные представления, оператор EXCEPT)

create view dc as
   select r.departure_city
   from routes r
;
 
create view c as
   select distinct a.city 
   from airports a
;

create view cdc as
   select * from c, dc
;

select cdc.departure_city, cdc.city
from cdc
where cdc.departure_city <> cdc.city
except 
select r.departure_city, r.arrival_city 
from routes r
; -- представления создают список городов отправления, общий список городов и список их декартова произведения,
--основной запрос выводит список возможных сочетаний городов 
--и вычитает из него существующий в базе список прямых сообщений

--Задание 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами.
  -- Сравните с допустимой максимальной дальностью перелетов в самолетах, 
  -- обслуживающих эти рейсы (оператор RADIANS или использование sind/cosd).

create materialized view coordinates as 
     select a.airport_code, radians(a.longitude) as rad_long, radians(a.latitude) as rad_lat
     from airports a
;-- координаты в радианах
  
create materialized view direct_flights as 
   select distinct f.departure_airport, f.arrival_airport, f.aircraft_code 
   from flights f
;-- "прямые рейсы"

select distinct df.departure_airport, df.arrival_airport, df.aircraft_code,
   (acos(sin(rad_lat_a)*sin(rad_lat_b) + cos(rad_lat_a)*cos(rad_lat_b)*cos(rad_long_a - rad_long_b))) * 6371 as L, 
   a2.range
from direct_flights df
join (
   select df.departure_airport, c.rad_lat as rad_lat_a, c.rad_long as rad_long_a
   from direct_flights df
   join coordinates c on df.departure_airport = c.airport_code
   ) 
   a on df.departure_airport = a.departure_airport
join (
   select df.arrival_airport, c.rad_lat as rad_lat_b, c.rad_long as rad_long_b  
   from direct_flights df
   join coordinates c on df.arrival_airport = c.airport_code
   ) 
   b on df.arrival_airport = b.arrival_airport
join aircrafts a2 on df.aircraft_code = a2.aircraft_code
;

-- первое материализованное представление создает список аэропортов с их географическими координатами,
-- переведенными в радианы, второе мат.представление создает список прямых рейсов,
-- в основном запросе приведенная в задании формула вычисляет расстояние между городами и выводит
-- максимальную дальность самолетов, обслуживающих прямые рейсы. (Подзапросы в предложении FROM формируют 
-- списки для вычисления с помощью формулы)
