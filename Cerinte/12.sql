-- trigger ldd
-- inregistram modificarile care se realizeaza la schema  pe tabele / subprograme / triggeri / pachete 
-- nu indexi, secvente, tipuri, views=)

create table modificari(
        utilizator varchar2(20),
        eveniment varchar2(40),
        obiect varchar2(30),
        proprietar varchar2(30),
        baza_de_date varchar2(50),
        data date
);

create or replace trigger inregistrareModificari
    before create or alter or drop on schema

begin

    if lower(sys.dictionary_obj_type) in ('table', 'function', 'procedure', 'trigger', 'package') then
        insert into modificari values (sys.login_user, sys.sysevent, sys.dictionary_obj_name, sys.dictionary_obj_owner, 
                                        sys.database_name, sysdate);
    end if;
    
end;
/

drop trigger inregistrareModificari;

create table temp(
    random number
);

select * from modificari;

drop table modificari;
drop table temp;
    