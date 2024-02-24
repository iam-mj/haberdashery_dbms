-- ne plac tablourile imbricate - nu mai e nevoie de constructor / extend daca facem bulk collect in ele + nu au limita

-- procedura, 5 tabele intr-o comanda sql + exceptii
-- dat numele unui prof si a unui cursant - media cursantului la toate cursurile tinute de instructor la care a participat
-- exceptie - nu a participat la niciun curs de-al unstructorului, instructorul nu a tinut niciun curs, nu e instructor, nu 
-- avem cursantul in baza de date, daca avem doi cursanti cu acelasi nume? - ii returnam pe amandoi

select * from cursant;
select * from angajati;
select * from curs; 
select * from curs_proiect_cursant;
select * from angajati;
select * from instructor;

create or replace procedure mediiCursantInstructor
    (v_numeCursant in cursant.nume_cursant%type,
     v_numeInstructor in angajati.nume%type)
is
    -- cursoare
    -- imi da informatii legate de instructori + cursurile le predau
    type refcursor is ref cursor;
    cursor cInstructor is
        select a.id_angajat, cursor (select id_curs
                                     from curs c
                                     where c.id_angajat = i.id_angajat)
        from angajati a, instructor i
        where a.id_angajat = i.id_angajat
        and lower(a.nume) = lower(v_numeInstructor);
    
    -- tipuri
    type tablouCoduri is table of number;
    type descriereCurs is record
    (
        cod curs.id_curs%type,
        descriere varchar2(100),
        instructor varchar2(100),
        medie number,
        dificultate proiect.dificultate%type
    );
    
    -- variabile
    v_cursor refcursor;
    v_cursuri_cursant tablouCoduri; -- cursurile la care participa un cursant
    v_detalii_curs descriereCurs;
    
    nuAvemInstructor exception;
    nuAreCursuriPredate exception; -- instructorul nu a predat cursuri
    nuAreCursuriComune exception; -- cursantul nu a participat la cursuri ale instructorului
    
    v_cod_cursant cursant.id_cursant%type;
    v_cod_curs curs.id_curs%type;
    v_nume_cursant varchar2(100);
    v_instructor angajati.id_angajat%type;
    v_cursuri_predate boolean;
    v_cursuri_comune boolean;
    
begin

    v_cursuri_predate := false; -- instructorii au predat macar un curs?
    v_cursuri_comune := false; -- am afisat macar un curs?
    
    -- obtinem cursantul cu numele dat
    -- no data found / too many rows
    select id_cursant, nume_cursant || ' ' || prenume_cursant
    into v_cod_cursant, v_nume_cursant
    from cursant
    where lower(nume_cursant) = lower(v_numeCursant);
    
    dbms_output.put_line('Pentru cursantul ' || upper(v_nume_cursant) || ': ');
    
    -- tinem minte la ce cursuri a participat
    
    select distinct id_curs
    bulk collect into v_cursuri_cursant
    from curs_proiect_cursant cpc
    where cpc.id_cursant = v_cod_cursant;
    
    -- trecem prin fiecare instructor si cursurile pe care le-a predat
    open cInstructor;
    
    if cInstructor%notfound then
        raise nuAvemInstructor;
    end if;
    
    loop
    
        fetch cInstructor into v_instructor, v_cursor;
        exit when cInstructor%notfound;
        
            loop 
            
                fetch v_cursor into v_cod_curs;
                exit when v_cursor%notfound;
                
                -- daca avem macar un curs predat de instructor
                if v_cursor%found then
                    v_cursuri_predate := true;
                end if;
                
                -- verificam daca cursantul nostru a participat la cursul curent
                
                for i in v_cursuri_cursant.first..v_cursuri_cursant.last loop
                
                    if v_cursuri_cursant(i) = v_cod_curs then
                        
                        v_cursuri_comune := true;
                        
                        -- calculam media si afisam detalii
                        
                        select c.id_curs, tip || ' ' || nivel descriere_curs, a.nume || ' ' || prenume nume_instructor,
                            avg(nota) medie, max(dificultate)
                        into v_detalii_curs
                        from curs_proiect_cursant cpc, curs c, angajati a, instructor i, proiect p
                        where cpc.id_curs = v_cod_curs
                            and cpc.id_cursant = v_cod_cursant
                            and cpc.id_curs = c.id_curs
                            and c.id_angajat = i.id_angajat
                            and i.id_angajat = a.id_angajat
                            and p.id_proiect = cpc.id_proiect
                            and least(data_predare, termen_limita) = data_predare
                        group by cpc.id_cursant, c.id_curs, tip, nivel, a.nume, prenume;
                        
                        dbms_output.new_line;
                        dbms_output.put_line('- la cursul ' || v_detalii_curs.cod || ' de ' || v_detalii_curs.descriere);
                        dbms_output.put_line('-- predat de ' || v_detalii_curs.instructor);
                        dbms_output.put_line('-- a avut media ' || v_detalii_curs.medie);
                        dbms_output.put_line('-- cel mai greu proiect a avut dificultatea ' || v_detalii_curs.dificultate
                                            || ' / 5');
                        
                    end if;
                    exit when v_cursuri_cursant(i) = v_cod_curs; -- iesim dupa ce il gasim
                
                end loop;
            
            end loop;
        
    end loop;
    close cInstructor;
    
    -- la final verificam valorile flag-urilor
    if v_cursuri_predate = false then
        raise nuAreCursuriPredate;
    elsif v_cursuri_comune = false then
        raise nuAreCursuriComune;
    end if;

exception
    when no_data_found then
        raise_application_error(-20003, 'Nu exista niciun cursant cu numele dat!');
    when too_many_rows then
        raise_application_error(-20003, 'Exista mai multi cursanti cu numele dat!');
    when nuAvemInstructor then
        raise_application_error(-20003, 'Nu avem niciun instructor cu numele dat!');
    when nuAreCursuriPredate then
        raise_application_error(-20003, 'Instructorul dat nu preda niciun curs!');
    when nuAreCursuriComune then
        dbms_output.put_line('Cursantul dat nu participa la niciun curs al instructorului dat');
end;
/

-- no data found
begin
    mediiCursantInstructor('Leahu', 'Asavinei');
end;
/
-- too many rows
begin
    mediiCursantInstructor('Grigore', 'Verdes');
end;
/
-- nuAvemCursuriComune
begin
    mediiCursantInstructor('Loboda','Leahu');
end;
/
-- nu avem instructor cu numele respectiv
begin
    mediiCursantInstructor('Sima', 'Miron');
end;
/

-- instructorul nu preda niciun curs
insert into angajati values(1010, 'McFell', 'Azira', '0728283283', 'aziraphale@gmail.com');
insert into instructor values(1010, sysdate);
begin
    mediiCursantInstructor('Sima', 'McFell');
end;
/
delete
from angajati
where nume = 'McFell';

begin
    mediiCursantInstructor('Miron','Buffay');
end;
/