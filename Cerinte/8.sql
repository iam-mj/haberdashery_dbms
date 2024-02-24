-- functie, 3 tabele, 2 exceptii proprii
-- pentru o data data, bonurile tranzactiilor din ziua respectiva -> exceptie in data respectiva nu s-au realizat tranzactii,
-- data e din viitor =), returnam totalul tranzactiilor

create or replace function totalData
    (v_data in date)
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
    
end;
/

-- nu avem tranzactii
declare
    v_data date;
    v_profit number;
begin
    v_data := sysdate;
    v_profit := totalData(v_data);
    
    dbms_output.put_line('TOTAL ' || v_data || ': ' || v_profit);
end;
/

-- data din viitor
declare
    v_data date;
    v_profit number;
begin
    v_data := sysdate + 1;
    v_profit := totalData(v_data);
    
    dbms_output.put_line('TOTAL ' || v_data || ': ' || v_profit);
end;
/

select * from tranzactii;

declare
    v_data date;
    v_profit number;
begin
    v_data := to_date('13/04/2023', 'DD/MM/YYYY');
    v_profit := totalData(v_data);
    
    dbms_output.put_line('TOTAL ' || v_data || ': ' || v_profit);
end;
/