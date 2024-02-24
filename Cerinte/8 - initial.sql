-- ne plac tablourile imbricate - nu mai e nevoie de constructor / extend daca facem bulk collect in ele + nu au limita

-- functie, 3 tabele intr-o comanda sql + exceptii proprii
-- dat numele unui prof si a unui cursant - media cursantului la toate cursurile tinute de instructor la care a participat
-- exceptie - nu a participat la niciun curs de-al unstructorului, instructorul nu a tinut niciun curs, nu e instructor, nu 
-- avem cursantul in baza de date, daca avem doi cursanti cu acelasi nume? - ii returnam pe amandoi

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
        and a.nume = v_numeInstructor;
    
    -- tipuri
    type tablouCoduri is table of number;
    type descriereCurs is record
    (
        cod curs.id_curs%type,
        descriere varchar2(100),
        instructor varchar2(100),
        medie number
    );
    
    -- variabile
    v_cursor refcursor;
    v_coduri_cursanti tablouCoduri; -- id-urile cursantilor cu numele dat
    v_cursuri_cursant tablouCoduri; -- cursurile la care participa un cursant
    v_detalii_curs descriereCurs;
    
    nuAvemInstructor exception;
    nuAvemCursant exception;
    nuAreCursuriPredate exception; -- instructorul nu a predat cursuri
    nuAreCursuriComune exception; -- cursantul nu a participat la cursuri ale instructorului
    
    v_nume_cursant varchar2(100);
    v_instructor angajati.id_angajat%type;
    v_cursuri_predate boolean;
    v_cursuri_comune boolean;
    
begin

    v_cursuri_predate := false; -- instructorii au predat macar un curs?
    v_cursuri_comune := false; -- am afisat macar un curs?
    
    -- obtinem toti cursantii cu numele dat
    select id_cursant
    bulk collect into v_coduri_cursanti
    from cursant
    where nume_cursant = v_numeCursant;
    
    if v_coduriCursant.count = 0 then
        raise nuAvemCursant;
    end if;
    
    -- pentru fiecare cursant
    for i in v_coduri_cursanti.first..v_coduri_cursanti.last loop
        
        select nume_cursant || ' ' || prenume_cursant
        into v_nume_cursant
        from cursant
        where id_cursant = v_coduri_cursanti(i);
        
        dbms_output.put_line('Pentru cursantul ' || upper(v_nume_cursant) || ': ');
        
        -- tinem minte la ce cursuri a participat
        
        select distinct id_curs
        into v_cursuri_cursant
        from curs_proiect_cursant cpc
        where cpc.id_cursant = v_coduri_cursanti(i);
        
        -- trecem prin fiecare instructor si cursurile pe care le-a predat
        open cInstructor;
        if cInstructor%notfound then
            raise nuAvemInstructor;
        end if;
        
        loop
            
            fetch cInstructor into v_instructor, v_cursor;
            exit when cInstructor%notfound;
            
            -- daca avem macar un curs predat de instructor
            if v_cursor%found then
            
                v_cursuri_predate := true;
                
                loop 
                
                    fetch v_cursor into v_cod_curs;
                    exit when v_cursor%notfound;
                    
                    -- verificam daca cursantul nostru a participat la cursul curent
                    
                    for j in v_cursuri_cursant.first..v_cursuri_cursant.last loop
                    
                        if v_cursuri_cursant(j) = v_cod_curs then
                            
                            v_cursuri_comune := true;
                            
                            -- calculam media si afisam detalii
                            -- again facem chestii ilegale ca sa iasa 3 tabele?? =(( pp ca nu-i ok daca am 4.......
                            
                            select c.id_curs, tip || ' ' || nivel descriere_curs, nume || ' ' || prenume nume_instructor,
                                avg(nvl(decode(least(data_predare, termen_limita), data_predare, nota), 0)) medie
                            into v_detalii_curs
                            from curs_proiect_cursant cpc, curs c, angajati a
                            where cpc.id_curs = v_cod_curs
                            and cpc.id_cursant = v_coduri_cursanti(i)
                            and cpc.id_curs = c.id_curs
                            and c.id_angajat = a.id_angajat
                            group by cpc.id_cursant, c.id_curs, tip, nivel, nume, prenume;
                            
                            dbms_output.put_line('- la cursul ' || v_detalii_curs.cod || ' de ' || v_detalii_curs.descriere ||
                                                ' predat de ' || v_detalii_curs.instructor || ' a avut media ' 
                                                || v_detalii_curs.medie);
                            
                        end if;
                        exit when v_cursuri_cursant(j) = v_cod_curs; -- iesim dupa ce il gasim
                    
                    end loop;
                
                end loop;
            end if;
            
        end loop;
        close cInstructor;
        
        dbms_output.newline;
        
    end loop;
    
    -- la final verificam valorile flag-urilor
    if v_cursuri_predate = false then
        raise nuAreCursuriPredate;
    elsif v_cursuri_comune = false then
        raise nuAreCursuriComune
    end if;
    
end;
/