-- 13 punem toate obiectele definite intr-un pachet

-- specificatia
create or replace package proiectSGBD as
    
    procedure programSedii;
    
    procedure profitFurnizor (v_idFurnizor in furnizori.id_furnizor%type);
    
    function totalData (v_data in date)
    return number; 
    
    procedure mediiCursantInstructor (v_numeCursant in cursant.nume_cursant%type,
                                      v_numeInstructor in angajati.nume%type);
    
end proiectSGBD;
/

-- corpul
create or replace package body proiectSGBD as

    -- 6
    procedure programSedii is
    
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
    
    
    -- 7
    procedure profitFurnizor (v_idFurnizor in furnizori.id_furnizor%type) is
        
        -- cursoare
        
        type refcursor is ref cursor;
        
        -- imi aduce informatii legate de tipuri de produse + produse
        cursor cTipuri is
            select tip_produs, cursor (select id_produs, nume_produs, pret
                                       from stoc s
                                       where s.id_tip = t.id_tip)
            from tipuri_produse t
            where id_furnizor = v_idFurnizor;
        
        -- imi calculeaza ce cantitate dintr-un produs s-a vandut
        cursor cCantitati (id stoc.id_produs%type) is
            select nvl(sum(cantitate), 0)
            from comanda
            where id_produs = id;
            
        -- tipuri
        type detaliiProdus is record
            (
                id stoc.id_produs%type,
                nume stoc.nume_produs%type,
                pret stoc.pret%type
            );
            
        -- variabile
        v_produse refcursor;
        v_produs detaliiProdus;
        
        v_nume_furnizor furnizori.nume_furnizor%type;
        v_nume_tip tipuri_produse.tip_produs%type;
        
        v_cantitate_produs comanda.cantitate%type;
        v_profit_produs number;
        v_profit_tip number;
        v_profit_total number;
        
    begin
        
        v_profit_total := 0;
        
        select nume_furnizor
        into v_nume_furnizor
        from furnizori
        where id_furnizor = v_idFurnizor;
        
        dbms_output.put_line('Furnizorul ' || v_nume_furnizor || ' furnizeaza urmatoarele produse: ');
        dbms_output.new_line;
        
        open cTipuri;
        loop
            fetch cTipuri into v_nume_tip, v_produse;
            exit when cTipuri%notfound;
            
            dbms_output.put_line('--------------------');
            dbms_output.put_line(upper(v_nume_tip) || ': ');
            dbms_output.new_line;
            
            v_profit_tip := 0; 
            
            loop
            
                fetch v_produse into v_produs;
                exit when v_produse%notfound;
                -- pt fiecare produs afisam numele si profitul total
                
                open cCantitati(v_produs.id);
                fetch cCantitati into v_cantitate_produs;
                close cCantitati;
                
                v_profit_produs := v_produs.pret * v_cantitate_produs;
                v_profit_tip := v_profit_tip + v_profit_produs; -- profitul pe tip creste
                
                dbms_output.put_line(v_produs.nume || ': ' || v_profit_produs || ' lei');
                
            end loop;
            
            dbms_output.new_line;
            dbms_output.put_line('TOTAL: ' || v_profit_tip || ' lei');
            dbms_output.put_line('------------------');
            dbms_output.new_line;
            
            v_profit_total := v_profit_total + v_profit_tip;
            
        end loop;
        
        close cTipuri;
        dbms_output.put_line('TOTAL FURNIZOR ' || upper(v_nume_furnizor) || ': ' || v_profit_total || ' lei');
        
    exception
        when no_data_found then
            dbms_output.put_line('Nu exista niciun furnizor cu acest id!');
    
    end profitFurnizor;
    
    
    -- 8
    function totalData (v_data in date)
    return number
    is
        -- tipuri
        
        type tablouCoduri is table of number;
    
        -- variabile
        
        v_tranzactii tablouCoduri;
        
        nuAvemTranzactii exception;
        dataViitoare exception;
        
        v_total number;
        v_total_tranzactie number;
        v_nume_vanzator varchar2(100);
        
    begin
        
        v_total := 0;
        
        if v_data > sysdate then
            raise dataViitoare;
        end if;
        
        -- gasim toate tranzactiile din data respectiva
        select id_tranzactie
        bulk collect into v_tranzactii
        from tranzactii
        where data = v_data;
        
        if v_tranzactii.count = 0 then
            raise nuAvemTranzactii;
        end if;
        
        dbms_output.put_line('In data de ' || v_data || ' avem urmatoarele tranzactii: ');
        
        for i in v_tranzactii.first..v_tranzactii.last loop
        
            dbms_output.new_line;
            v_total_tranzactie := 0;
            
            -- aflam cn a realizat tranzactia
            select a.nume || ' ' || a.prenume nume
            into v_nume_vanzator
            from tranzactii t, vanzator v, angajati a
            where t.id_angajat = v.id_angajat
                and v.id_angajat = a.id_angajat
                and t.id_tranzactie = v_tranzactii(i);
                
            dbms_output.put_line('TRANZACTIA ' || v_tranzactii(i) || ' realizata de ' || upper(v_nume_vanzator) || ': ');
            
            -- luam un ciclu cursor cu subcereri care sa-mi treaca prin comenzi
            for v_comanda in (select nume_produs, cantitate cant, pret
                              from comanda c, stoc s
                              where c.id_tranzactie = v_tranzactii(i)
                                  and c.id_produs = s.id_produs) loop
                
                dbms_output.put_line('- ' || v_comanda.nume_produs || ': ' || v_comanda.cant || 
                                     '(cantitate) x ' || v_comanda.pret || '(pret) = ' || v_comanda.cant * v_comanda.pret);
                v_total := v_total + v_comanda.cant * v_comanda.pret;
                v_total_tranzactie := v_total_tranzactie + v_comanda.cant * v_comanda.pret;
                
            end loop;
            
            dbms_output.put_line('TOTAL: ' || v_total_tranzactie);
        
        end loop;
        
        dbms_output.new_line;
        return v_total; -- returnam totalul pe toata ziua
        
    exception
        
        when dataViitoare then
            raise_application_error(-20003, 'Introduceti o data de dinaintea zilei de astazi!');
        when nuAvemTranzactii then
            raise_application_error(-20003, 'In aceasta data nu s-au realizat tranzactii!');
        when others then
            raise_application_error(-20003, 'Am intampinat probleme in functia totalData!');
        
    end totalData;
    
    -- 9
    procedure mediiCursantInstructor
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
            
    end mediiCursantInstructor;

end proiectSGBD;
/

begin
    proiectSGBD.programSedii;
end;
/

begin
    proiectSGBD.profitFurnizor(701);
end;
/

begin
    proiectSGBD.profitFurnizor(701);
end;
/

declare
    v_data date;
    v_profit number;
begin
    v_data := to_date('13/04/2023', 'DD/MM/YYYY');
    v_profit := proiectSGBD.totalData(v_data);
    
    dbms_output.put_line('TOTAL ' || v_data || ': ' || v_profit);
end;
/

begin
    proiectSGBD.mediiCursantInstructor('Miron','Buffay');
end;
/
