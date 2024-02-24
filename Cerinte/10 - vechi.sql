-- trigger pt comanda, insert / delete pe stoc - sa nu ajungem sa avem < 5 produs in stoc + sa nu ajungem sa avem 
-- > 500 de produse in stoc - din motive de storage =)

create or replace trigger triggStoc
    after insert or delete on stoc
    
declare

    -- variabile
    preaPutinStoc exception;
    preaMultStoc exception;
    
    v_stoc_curent number;

begin

    -- cat stoc avem dupa realizarea operatiei
    select count(*)
    into v_stoc_curent
    from stoc;

    if deleting then
    
        if v_stoc_curent <= 5 then
            raise preaPutinStoc;
        end if;
        
    elsif inserting then
    
        if v_stoc_curent > 500 then
            raise preaMultStoc;
        end if;
        
    end if;

exception
    
    when preaPutinStoc then
        raise_application_error(-20003, 'Ramanem cu prea putine produse daca realizati operatia! Introduceti alte ' ||
                                'produse inainte de a le sterge pe acestea!');
    when preaMultStoc then
        raise_application_error(-20003, 'Avem prea multe produse in stoc! Stergeti alte produse inainte de a le adauga pe' ||
                                ' pe aceastea');
    when others then
        raise_application_error(-20003, 'Eroare la executarea comenzii de inserare / stergere din stoc!');
    
end;
/

select * 
from stoc;

delete 
from stoc
where 1 = 1;