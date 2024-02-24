-- 6 - un subprogram stocat independent in care sa folosesc toate cele 3 tipuri de colectii
-- pt fiecare sediu sa afisez programul pt fiecare zi din saptamana -> cursul + numele profesorului + numarul de cursanti

select * from sedii;
select * from organizare_curs;
-- vector pt sedii fiindca stim cate avem => putem pune limita linistiti
-- tablou imbricat pt cursuri fiindca facem bulk collect si pt a scapa de constructor si extindere

create or replace procedure programSedii is
    
    --cursor
    cursor cZile (sediu sedii.id_sediu%type) is
        select distinct ziua_din_saptamana zi
        from organizare_curs
        where id_sediu = sediu
        order by 1; -- le punem alfabetic => vor fi in ordine toate mai putin joi care va fi prima =)(

    --tipuri
    type vectorSedii is varray(10) of sedii.id_sediu%type; 
    
    type tablouCoduri is table of curs.id_curs%type index by pls_integer;
    
    type detaliiCurs is record
        (
            cod_curs curs.id_curs%type,
            nume_instructor varchar2(30),
            nr_cursanti number(3)
        );
    type tablouCurs is table of detaliiCurs;
    
    -- variabile
    v_sedii vectorSedii;
    v_cursuri tablouCurs;
    v_coduri tablouCoduri;
    
    begin
        -- luam toate codurile sediilor
        select distinct id_sediu
        bulk collect into v_sedii
        from sedii;
        
        -- calculam inainte detaliile despre cursuri -> un curs se organizeaza in zile diferite 
        -- in sedii diferite (sau nu neaparat)
        
        select c.id_curs, a.nume || ' ' || a.prenume, count(cpc.id_cursant)
        bulk collect into v_cursuri
        from curs_proiect_cursant cpc, curs c, angajati a, instructor i
        where cpc.id_curs (+) = c.id_curs -- vrem inclusiv detaliile cursurilor fara cursanti
        and c.id_angajat = i.id_angajat
        and a.id_angajat = i.id_angajat
        group by c.id_curs, a.nume, a.prenume;
        
        for i in v_sedii.first..v_sedii.last loop
            dbms_output.put_line('-- PROGRAMUL SEDIULUI ' || v_sedii(i) || ' --');
        
            -- gasim zilele din saptamana cand avem cursuri in sediu
            -- ciclu cursor
            for v_ziCurenta in cZile(v_sedii(i)) loop
                
                exit when cZile%NOTFOUND;
                
                -- pt fiecare zi, ii aducem si codurile cursurilor
                select id_curs
                bulk collect into v_coduri
                from organizare_curs
                where id_sediu = v_sedii(i)
                and ziua_din_saptamana = v_ziCurenta.zi;
                
                dbms_output.new_line;
                dbms_output.put_line(upper(v_ziCurenta.zi) || ':');
                
                -- afisam detaliile cursurilor din ziua respectiva
                for j in v_coduri.first..v_coduri.last loop
                    -- il cautam in detalii
                    for k in v_cursuri.first..v_cursuri.last loop
                        if v_cursuri(k).cod_curs = v_coduri(j) then
                            dbms_output.put_line('- cursul ' || v_cursuri(k).cod_curs || ' predat de ' || 
                                                  v_cursuri(k).nume_instructor || ' cu ' || v_cursuri(k).nr_cursanti 
                                                  || ' cursanti');
                        end if;
                        exit when v_coduri(j) = v_cursuri(k).cod_curs; -- dupa ce l-am gasit
                    end loop;
                end loop;
            
            end loop;
            
            dbms_output.new_line;
            dbms_output.new_line;
            
        end loop;
        
    end programSedii;
    /
    
begin
    programSedii();
end;
/
    