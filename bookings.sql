-- 1. В каких городах больше одного аэропорта?
select * from airports_data ad; 
select city, count(a.airport_name)   
from airports a 
group by a.city   
having count(a.airport_name)>1;

--2.В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?          
select a.airport_name  from airports a
inner join (select distinct f.departure_airport
from aircrafts a 
inner join flights f on f.aircraft_code = a.aircraft_code
where (f.scheduled_arrival-f.scheduled_departure) = (select max(f.scheduled_arrival-f.scheduled_departure) as time 
                                                     from flights f))  max_flights_airports
on a.airport_code = max_flights_airports.departure_airport

-- второй способ 
select a.airport_name  from airports a
inner join (select distinct f.departure_airport
from aircrafts a 
inner join flights_v f on f.aircraft_code = a.aircraft_code
where f.scheduled_duration  = (select max(fv.scheduled_duration)
                                                     from flights_v fv ))  max_flights_airports
on a.airport_code = max_flights_airports.departure_airport

--3.Вывести 10 рейсов с максимальным временем задержки вылета
 select fv.actual_departure - fv.scheduled_departure as delay_time, fv.flight_no 
 from flights_v fv 
 where fv.actual_departure is not null 
 order by (fv.actual_departure - fv.scheduled_departure) desc 
 limit 10
 
 --4.Были ли брони, по которым не были получены посадочные талоны?
select count(*) as "Не получены ПТ"
from (select*from tickets t  
      full join boarding_passes bp on t.ticket_no = bp.ticket_no 
      where bp.flight_id is null) p 

 
--5.Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого 
--аэропорта на каждый день.Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело
--из данного аэропорта на этом или более ранних рейсах в течении дня.

with passnger_in_flights as 
(select flight_id, count(boarding_no)  as number_
            from boarding_passes bp 
            group by bp.flight_id),
number_of_seats as 
(select aircraft_code, count(seat_no)::numeric  as number_of_seat 
from  seats s 
group by aircraft_code),
passnger_in_airport as 
(select departure_airport,
      date_trunc('d', actual_departure) as date_,
      sum(number_)as number_passenger,
      nf.number_of_seat
  from flights f 
       inner join passnger_in_flights pf on f.flight_id = pf.flight_id
       inner join number_of_seats nf on f.aircraft_code =nf.aircraft_code
  where  f.status ='Arrived' 
  group by f.departure_airport,date_,nf.number_of_seat)
 select *,sum(number_passenger)over (PARTITION by departure_airport order by date_ ) as passnger_sum,
         (number_of_seat - number_passenger)/number_of_seat*100 as percent_
 from passnger_in_airport
 
--6.Найдите процентное соотношение перелетов по типам самолетов от общего количества.
 
select aircraft_code as model, 
       round (all_flights/(sum(all_flights) over())*100,2) as percent_by_aircraft_type
from (select aircraft_code, 
             count(*) as all_flights
      from flights f2 
      group by aircraft_code) all_



