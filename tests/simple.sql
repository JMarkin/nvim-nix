select count(*) from
    checks
limit 100;

select pc.counter from "public".parent_counter pc;


insert into "public".parent_counter (counter) values generate_series(1, 100);
