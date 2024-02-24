-- trigger pt comanda -> un curs nu poate fi inserat decat daca am un prof cu maxim un curs si un sediu cu maxim 6

create or replace trigger triggCurs
    before insert on curs

declare
    
    nuAvemInstructor exception;
    nuAvemSediu exception;
    
    type tablouIdInstr is table of instructor.id_angajat%type;
    type tablouIdSedii is table of sedii.id_sediu%type;
    
    v_id_instructori tablouIdInstr;
    v_id_sedii tablouIdSedii;
    
begin

    -- id-urile instructorilor cu maxim un curs (inclusiv care nu predau niciun curs)
    select i.id_angajat
    bulk collect into v_id_instructori
    from curs c, instructor i
    where c.id_angajat(+) = i.id_angajat
    group by i.id_angajat
    having count(id_curs) < 2;
    
    if v_id_instructori.count = 0 then
        raise nuAvemInstructor;
    end if;
        
    -- id-urile sediilor ce gazduiesc mai putin de 7 cursuri (inclusiv care nu gazduiesc niciun curs)
    select s.id_sediu
    bulk collect into v_id_sedii
    from organizare_curs oc, sedii s
    where oc.id_sediu(+) = s.id_sediu
    group by s.id_sediu
    having count(id_curs) < 7;
    
    if v_id_sedii.count = 0 then
        raise nuAvemSediu;
    end if;

exception

    when nuAvemInstructor then
        raise_application_error(-20003, 'Nu avem destui instructori pentru a mai adauga un curs!');
        
    when nuAvemSediu then
        raise_application_error(-20003, 'Nu avem destule sedii pentru a mai adauga un curs!');

end;
/

select i.id_angajat, count(id_curs)
from curs c, instructor i
where c.id_angajat(+) = i.id_angajat
group by i.id_angajat
having count(id_curs) < 2;

delete
from angajati 
where id_angajat in (1007, 1009);

insert into curs values (111, 1006, 'impletit', 'incepatori', to_date('12.01.2024', 'dd.mm.yyyy'), 20);

rollback;

select s.id_sediu, count(id_curs)
from organizare_curs oc, sedii s
where oc.id_sediu(+) = s.id_sediu
group by s.id_sediu
having count(id_curs) < 2;

insert into organizare_curs values(107, 202, 'luni');

drop trigger triggCurs;


