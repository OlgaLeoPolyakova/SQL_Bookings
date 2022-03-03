--������� 1. � ����� ������� ������ ������ ���������?
 
select a.city
from airports a
group by a.city
having count(a.city) > 1 
; -- ������� ��������� ������� �� ������� � � ������� having ������ ������, ���������� ����� ����� ������

--������� 2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
--(���������) 

select distinct r.departure_airport_name
from routes r
join aircrafts a on r.aircraft_code = a.aircraft_code
where a.range = (
   select max(a.range) 
   from aircrafts a)
; -- ��������� ������� ������������ ��������� ������,   
--���������� ���.������������� routes � �������� aircrafts 
--�� ������� ��������� ����������� �������� ��������� 
--� ������������ ���������� ������ (����� ��������� � ����������) � ���������� ������� ���������

--������� 3. ������� 10 ������ � ������������ �������� �������� ������
--(�������� LIMIT)

select f.flight_no, (f.actual_departure - f.scheduled_departure) d
from flights f
where f.actual_departure - f.scheduled_departure is not null
order by d desc
limit (10)
; -- ������� ������� ��������� ����������� 
--� ������������ ������� ������ ������������� �� ��������, ��������� �� NULL

--������� 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?
--(������ ��� JOIN)

select t.book_ref
from tickets t 
left outer join boarding_passes bp on t.ticket_no = bp.ticket_no
where boarding_no isnull
; -- ��� ����, ����� ��������� "������ ��������" ������������, �� ������� ������������ � ����������� ��������,
-- ������������ ����� ������� ����������, � ��� �� �����������������, ������� ������� ���������

--������� 5. ������� ��������� ����� ��� ������� �����, 
--�� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - 
--��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
--(������� �������, ����������).

select distinct f.departure_airport, f.actual_departure, 
   count(bp.boarding_no) over (partition by f.departure_airport, f.actual_departure order by f.actual_departure), 
   bp.flight_id, seats_relation.free_seats, seats_relation.percentage    
from boarding_passes bp 
join flights f on bp.flight_id = f.flight_id 
join (    
   select distinct taken_seats.flight_id as flight_id, all_seats.count::float - taken_seats.count as free_seats, 
      ((all_seats.count::float - taken_seats.count)*100/all_seats.count) as percentage --���������� ���������
   from (      
      select f.flight_id, count(s.seat_no)
      from seats s
      join flights f on s.aircraft_code = f.aircraft_code
      group by f.flight_id 
      ) as all_seats --����� ����� � ��������
   join (
      select bp.flight_id, count(bp.boarding_no)
      from boarding_passes bp
      group by bp.flight_id      
      ) as taken_seats --������� ����� � ��������
   on all_seats.flight_id = taken_seats.flight_id
) as seats_relation on bp.flight_id = seats_relation.flight_id 
where f.actual_departure is not null
order by f.departure_airport, f.actual_departure
; --���������� ������� ������ �������,��������������, ����� � ������� ����� � ��������, 
--� ���������� ����� �������� ������ ����������� ���������� ��������� ��������� ���� � �������� 
--� ������ ���������� ����. ������� ������� ������� ����������� ���������� ���������� ���������� 
--��������� ���������� order by � ����������� �� ��������� ����������� � ������� ������, ������ �� ������� 
--����������������� ������, ���������� �������� � ���� ��������� ������� ������.

--������� 6. ������� ���������� ��������� ��������� �� ����� ��������� �� ������ ����������
--(���������, �������� ROUND)

select f.aircraft_code, 
   round(count(f.flight_id)::float / (
      select count(f.flight_id)::float 
      from flights f)*100) as relation
from flights f
group by f.aircraft_code
;
-- ������� ������������ ���� ���������, ����� ������������ � ����������� �� ������
-- ���������� ��������� ���������� ��������� ������ � ���� �� ���� � ������ ����������.
-- � �������������� ����������. ����� ��������� ���������� ���������� � ���� float, �����
-- ��������� �������� round

--������� 7. ���� �� ������, � ������� ����� ��������� ������-������� �������, 
--��� ������-������� � ������ ��������? (CTE) 

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
--CTE ��������� ������ �� �����. ������ �� CTE ��������� ������� ������ �� ���������
--������������ ������ ������������, � � �������� ������� ����� ������� ������������ ��� �������
-- � ������ ������ ��������

--������� 8. ����� ������ �������� ��� ������ ������? (��������� ������������ � ����������� FROM,
--�������������� ��������� �������������, �������� EXCEPT)

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
; -- ������������� ������� ������ ������� �����������, ����� ������ ������� � ������ �� ��������� ������������,
--�������� ������ ������� ������ ��������� ��������� ������� 
--� �������� �� ���� ������������ � ���� ������ ������ ���������

--������� 9. ��������� ���������� ����� �����������, ���������� ������� �������.
  -- �������� � ���������� ������������ ���������� ��������� � ���������, 
  -- ������������� ��� ����� (�������� RADIANS ��� ������������� sind/cosd).

create materialized view coordinates as 
     select a.airport_code, radians(a.longitude) as rad_long, radians(a.latitude) as rad_lat
     from airports a
;-- ���������� � ��������
  
create materialized view direct_flights as 
   select distinct f.departure_airport, f.arrival_airport, f.aircraft_code 
   from flights f
;-- "������ �����"

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

-- ������ ����������������� ������������� ������� ������ ���������� � �� ��������������� ������������,
-- ������������� � �������, ������ ���.������������� ������� ������ ������ ������,
-- � �������� ������� ����������� � ������� ������� ��������� ���������� ����� �������� � �������
-- ������������ ��������� ���������, ������������� ������ �����. (���������� � ����������� FROM ��������� 
-- ������ ��� ���������� � ������� �������)
