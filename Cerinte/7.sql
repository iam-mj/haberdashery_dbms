-- subprogram stocat indepenedent cu 2 tipuri de cursoare, unul parametrizat dependent de celalalt
-- pentru un furnizor, toate produsele pe care le furnizeaza impartite pe tipuri si profitul total
-- acumulat din vanzarea fiecarui produs (+ fiecarui tip si in total)

select * from furnizori;

create or replace procedure profitFurnizor 
    (v_idFurnizor in furnizori.id_furnizor%type) is
    
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
end;
/


begin
    profitFurnizor(101);
end;
/