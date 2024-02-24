create or replace function cursTerminat 
    (v_id_curs in curs.id_curs%type)
return boolean
is

    v_data_inceput date;
    v_durata curs.durata%type;

begin

    select data_inceput, durata
    into v_data_inceput, v_durata
    from curs
    where id_curs = v_id_curs;
    
    if v_data_inceput + (v_durata * 7) < sysdate then
        return true;
    else 
        return false;
    end if;

exception
    -- daca cumva cursul nu e in baza de date
    when no_data_found then
        return null;

end;
/


create or replace function medieCursantCurs 
    (v_id_cursant in cursant.id_cursant%type,
    v_id_curs in curs.id_curs%type)
return number
is

    v_medie number;

begin

    select avg(decode(least(data_predare, termen_limita), data_predare, nota, 0))
    into v_medie
    from curs_proiect_cursant
    where id_curs = v_id_curs
    and id_cursant = v_id_cursant
    group by id_curs, id_cursant;
    
    return v_medie;

exception

    -- daca cursantul nu a participat la curs
    when no_data_found then
        raise_application_error(-20003, 'Cursantul dat nu a participat la curs!');

end;
/


create or replace procedure informatiiCursant
    (v_id_cursant in cursant.id_cursant%type)
is
    
    -- cursoare
    -- imi ia cursurile la care a participat cursantul + detalii
    cursor cCursuri is
        select distinct cpc.id_curs, nume || ' ' || prenume nume_instr, tip || ' ' || nivel descriere, 
                        data_inceput + (durata * 7) data_terminare
        from curs_proiect_cursant cpc, curs c, angajati a, instructor i
        where cpc.id_cursant = v_id_cursant
        and c.id_curs = cpc.id_curs
        and c.id_angajat = i.id_angajat
        and i.id_angajat = a.id_angajat;
        
    type detaliiCursExtinse is record
    (
        cod curs.id_curs%type,
        nume_instr varchar2(40),
        descriere varchar2(30),
        dataa date
    );
    
    v_curs detaliiCursExtinse;
    v_nume varchar2(40);
    v_medie number;
    cnt_cursuri number := 0;

begin
    
    -- pentru o afisare draguta aducem niste date despre cursant
    select nume_cursant || ' ' || prenume_cursant
    into v_nume
    from cursant
    where id_cursant = v_id_cursant;
    
    dbms_output.put_line('Cursantul ' || upper(v_nume) || ' a participat la urmatoarele cursuri: ');

    -- trecem prin cursurile la care a participat cursantul
    open cCursuri;
    loop
    
        fetch cCursuri into v_curs;
        exit when cCursuri%notfound;
        
        -- pentru fiecare curs verificam daca s-a terminat, daca da, calculam media
        if cursTerminat(v_curs.cod) = true then
            
            cnt_cursuri := cnt_cursuri + 1;
            
            -- afisam media
            v_medie := medieCursantCurs(v_id_cursant, v_curs.cod);
            dbms_output.put('- la cursul ' || v_curs.cod || ' de ' || v_curs.descriere || ' predat de ' || v_curs.nume_instr 
                            || ' terminat in ' || 'data de ' || to_char(v_curs.dataa, 'dd.mm.yyyy') 
                            || ' a obtinut media ' || v_medie);
                            
            if v_medie >= 5 then
                dbms_output.put_line(' - PROMOVAT');
            else
                dbms_output.put_line(' - NEPROMOVAT');
            end if;
        
        end if;
        
    end loop;
    close cCursuri;
    
    -- daca cumva nu am afisat niciun curs
    if cnt_cursuri = 0 then
    
        dbms_output.new_line();
        dbms_output.put_line('Cursantul dat nu a participat inca la niciun curs care sa se fi terminat!');
    
    end if;

exception

    -- daca nu avem id-ul in baza de date
    when no_data_found then
        raise_application_error(-20003, 'Id-ul dat nu este asociat niciunui cursant inregistrat!');    
        
end;
/

begin
    informatiiCursant(4001);
end;
/

select * from cursant;


-- procedura pt un curs dat in ce sedii si cand e programat
create or replace procedure programCurs
    (v_id_curs in curs.id_curs%type)
is

    -- cursor parametrizat pentru obtinerea zilelor din saptamana
    cursor cZile (v_id_sediu sedii.id_sediu%type) is
        select ziua_din_saptamana
        from organizare_curs
        where id_curs = v_id_curs
        and id_sediu = v_id_sediu;
        
    type detaliiCurs is record
    (
        cod curs.id_curs%type,
        nume_instr varchar2(40),
        descriere varchar2(30)
    );
    
    v_detalii_curs detaliiCurs;
    v_adresa_sediu varchar2(60);
    -- nu ar trebui sa se inatmple dar daca cumva cursul nu e organizat in niciun sediu
    afisare_sedii boolean := false;

begin
    
    -- aducem detalii despre curs
    select id_curs, nume || ' ' || prenume, tip || ' ' || nivel
    into v_detalii_curs
    from curs c, instructor i, angajati a
    where id_curs = v_id_curs
    and c.id_angajat = i.id_angajat
    and i.id_angajat = a.id_angajat; 
    
    dbms_output.put_line('Orarul cursului ' || v_detalii_curs.cod || ' de ' || v_detalii_curs.descriere || ' predat de '
                        || v_detalii_curs.nume_instr || ': ');

    -- treceum cu un ciclu cursor cu subcerere prin sedii
    for sediu in (select distinct id_sediu
                  from organizare_curs
                  where id_curs = v_id_curs) loop
                  
        afisare_sedii := true;
                  
        -- detalii sediu
        select strada || ' ' || oras
        into v_adresa_sediu
        from sedii
        where id_sediu = sediu.id_sediu;
        
        dbms_output.new_line();
        dbms_output.put_line('In sediul ' || v_adresa_sediu || ': ');
        
        for zi in cZile(sediu.id_sediu) loop
        
            dbms_output.put_line('- ' || zi.ziua_din_saptamana);
        
        end loop;
        
    end loop;
    
    -- daca nu am afisat niciun sediu
    if afisare_sedii = false then
    
        dbms_output.new_line();
        dbms_output.put_line('Cursul nu a fost programat inca in niciun sediu, va rugam reveniti in cateva zile');
        
    end if;
    
exception

    -- daca cumva cursul nu e in baza de date
    when no_data_found then
        raise_application_error(-20003, 'Id-ul cursului dat este invalid!');

end;
/

select * from curs;

begin
    programCurs(100);
end;
/

-- toate cursurile care incep dupa o data data
create or replace procedure cursuriViitoare
    (v_data in date)
is

    -- cursurile care incep dupa data primita ca parametru
    cursor cCursuri is
        select id_curs, tip || ' ' || nivel descriere, nume || ' ' || prenume nume_instr, data_inceput inceput
        from curs c, instructor i, angajati a
        where data_inceput > v_data
        and c.id_angajat = i.id_angajat
        and i.id_angajat = a.id_angajat
        order by data_inceput;
        
    type detaliiCursExtinse is record
    (
        cod curs.id_curs%type,
        nume_instr varchar2(40),
        descriere varchar2(30),
        dataa date
    );
    
    v_curs detaliiCursExtinse;
    afisare_curs boolean := false;

begin
    
    dbms_output.put_line('Dupa data de ' || to_char(v_data, 'dd.mm.yyyy') || ' incep urmatoarele cursuri: ');
    
    -- parcurgem cursurile cu un cursor
    open cCursuri;
    loop
        
        fetch cCursuri into v_curs;
        exit when cCursuri%notfound;
        
        afisare_curs := true;
        
        dbms_output.put_line(' - cursul ' || v_curs.cod || ' de ' || v_curs.descriere || ' predat de ' || v_curs.nume_instr ||
                             ' incepe in data de ' || to_char(v_curs.dataa, 'dd.mm.yyyy'));
    
    end loop;
    
    -- daca nu am gasit niciun curs
    if afisare_curs = false then
        dbms_output.new_line();
        dbms_output.put_line('Nu s-au gasit cursuri care sa inceapa dupa data introdusa');
    end if;
    
end;
/

select * from curs;

begin
    cursuriViitoare(to_date('01.01.2023', 'dd.mm.yyyy'));
end;
/

-- sa vedem daca ne iese cv asemanator cu o interfata -- nu ne iese =)((((
--ccept v_optiune prompt "Doriti sa: 1. Interogati activitatea unui cursant dupa cod  2. Afisati programul unui curs al carui id il cunoasteti 3. Afisati toate cursurile care urmeaza sa inceapa dupa o anumita data";

begin
    interfata(&v_optiune);
end;
/

create or replace procedure interfata
    (v_optiune in number)
is

    v_cod_cursant cursant.id_cursant%type;
    v_cod_curs curs.id_curs%type;
    v_data date;

begin
        
    case v_optiune
        
        when 1 then
            v_cod_cursant := &cod_cursant;
            informatiiCursant(v_cod_cursant);
        
        when 2 then
            v_cod_curs := &cod_curs;
            programCurs(v_cod_curs);
        
        when 3 then
            v_data := to_date('&data', 'dd.mm.yyyy');
            cursuriViitoare(v_data);
    
    end case;
    
end;
/