-- trigger la nivel de linie
-- la introducerea unui curs nou, acesta se va organiza automat in sediul care organizeaza cele mai putine
-- cursuri, in ziua cu cele mai putine cursuri

create or replace trigger trigg_inserare_curs
    after insert on curs
    for each row
    
declare

    -- tipuri
    type tablouCoduri is table of number;
    type cntZile is record (
        nume organizare_curs.ziua_din_saptamana%type,
        cnt number := 0
    );
    type tablouCntZile is table of cntZile index by pls_integer; -- ca nu-l mai extindem
    
    -- variabile
    v_sedii tablouCoduri;
    v_cnt_zile tablouCntZile;
    v_sediu sedii.id_sediu%type;
    v_minim number;
    v_zi organizare_curs.ziua_din_saptamana%type;
    
begin
    
    -- initializam controul pt zile
    v_cnt_zile(1).nume := 'luni';
    v_cnt_zile(2).nume := 'marti';
    v_cnt_zile(3).nume := 'miercuri';
    v_cnt_zile(4).nume := 'joi';
    v_cnt_zile(5).nume := 'vineri';
    v_cnt_zile(6).nume := 'sambata';
    v_cnt_zile(7).nume := 'duminica';
    
    -- trebuie sa aflam sediul (un sediu) care organizeaza cele mai putine cursuri
    select min(count(id_curs))
    into v_minim
    from organizare_curs
    group by id_sediu;
    
    select id_sediu
    bulk collect into v_sedii
    from organizare_curs
    group by id_sediu
    having count(id_curs) = v_minim;

    -- luam in considerare doar primul sediu pe care il gasim
    v_sediu := v_sedii(v_sedii.first);
    
    -- in acest sediu trebuie sa vd in ce zile si de cate ori se organizeaza cursuri
    for v_zi in (select ziua_din_saptamana
                 from organizare_curs
                 where id_sediu = v_sediu) loop
        dbms_output.put_line('Gasim ziua: ' || v_zi.ziua_din_saptamana);
        case lower(v_zi.ziua_din_saptamana)
            when 'luni' then 
                v_cnt_zile(1).cnt := v_cnt_zile(1).cnt + 1;
            when 'marti' then 
                v_cnt_zile(2).cnt := v_cnt_zile(2).cnt + 1;
            when 'miercuri' then 
                v_cnt_zile(3).cnt := v_cnt_zile(3).cnt + 1;
            when 'joi' then 
                v_cnt_zile(4).cnt := v_cnt_zile(4).cnt + 1;
            when 'vineri' then 
                v_cnt_zile(5).cnt := v_cnt_zile(5).cnt + 1;
            when 'sambata' then 
                v_cnt_zile(6).cnt := v_cnt_zile(6).cnt + 1;
            when 'duminica' then 
                v_cnt_zile(7).cnt := v_cnt_zile(7).cnt + 1;
        end case;
        dbms_output.put_line('Am terminat case-ul');
    end loop;
    
    -- trebuie sa aflam elementul cu cnt-ul minim
    v_minim := v_cnt_zile(1).cnt;
    v_zi := 'luni';
    
    for i in 2..7 loop
    
        if v_cnt_zile(i).cnt < v_minim then
            v_minim := v_cnt_zile(i).cnt;
            v_zi := v_cnt_zile(i).nume;
        end if;
    
    end loop;
    
    -- facem insert-ul suplimentar
    insert into organizare_curs values(:NEW.id_curs, v_sediu, v_zi);
    
end;
/

insert into curs values (121, 1000, 'brodat', 'avansati', sysdate, 20);
rollback;

select * from curs; 
select * from organizare_curs order by 2;

