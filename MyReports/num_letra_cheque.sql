CREATE OR REPLACE FUNCTION public.f_moneda(moneda numeric, num numeric)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$-- Función que devuelve la cadena de texto en castellano que corresponde a un número.
-- Parámetros: número con 2 decimales, máximo 999.999.999,99.
 
DECLARE
 d VARCHAR[];
 f VARCHAR[];
 g VARCHAR[];
 numt VARCHAR;
 txt VARCHAR;
 a INTEGER;
 a1 INTEGER;
 a11 INTEGER;
 a2 INTEGER;
 n INTEGER;
 p INTEGER;
 negativo BOOLEAN;
BEGIN
 -- Máximo 999.999.999,99
 IF num > 999999999.99 THEN
  RETURN '---';
 END IF;
 txt = '';
 d = ARRAY[' un',' dos',' tres',' cuatro',' cinco',' seis',' siete',' ocho',' nueve',' diez',' once',' doce',' trece',' catorce',' quince',
  ' dieciseis',' diecisiete',' dieciocho',' diecinueve',' veinte',' veintiun',' veintidos', ' veintitres', ' veinticuatro', ' veinticinco',
  ' veintiseis',' veintisiete',' veintiocho',' veintinueve'];
 f = ARRAY ['','',' treinta',' cuarenta',' cincuenta',' sesenta',' setenta',' ochenta', ' noventa'];
 g= ARRAY [' ciento',' doscientos',' trescientos',' cuatrocientos',' quinientos',' seiscientos',' setecientos',' ochocientos',' novecientos'];
 
 numt = LPAD((num::numeric(12,2))::text,12,'0');
 IF strpos(numt,'-') > 0 THEN
    negativo = TRUE;
 ELSE
    negativo = FALSE;
 END IF;
 raise notice '%', numt;
 numt = TRANSLATE(numt,'-','0');
 numt = TRANSLATE(numt,'.,','');
 RAISE NOTICE '%',numt;
 -- Trato 4 grupos: millones, miles, unidades y decimales
 p = 1;
 FOR i IN 1..4 LOOP
  IF i < 4 THEN
   n = substring(numt::text FROM p FOR 3);
  raise notice '%',n;
  ELSE
   n = substring(numt::text FROM p FOR 2);
  END IF;
  p = p + 3;
  IF i = 4 THEN
   IF txt = '' THEN
    txt = ' cero';
   END IF;
   IF n > 0 THEN
   -- Empieza con los decimales
    txt = txt || ' con';
   END IF;
  END IF;
  -- Centenas
  IF n > 99 THEN
   a = substring(n::text FROM 1 FOR 1);
   a1 = substring(n::text FROM 2 FOR 2);
   IF a = 1 THEN
    IF a1 = 0 THEN
     txt = txt || ' cien';
    ELSE
     txt = txt || ' ciento';
    END IF;
   ELSE
    txt = txt || g[a];
   END IF;
  ELSE
   a1 = n;
  END IF;
  -- Decenas
  a = a1;
  IF a > 0 THEN
   IF a < 30 THEN
    IF a = 21 AND (i = 3 OR i = 4) then
     if i!=4 then
     	txt = txt || ' veintiuno';
     else
        txt = txt || ' '||a||'/100';
     end if;
    ELSIF n = 1 AND i = 2 THEN
     txt = txt;
    ELSIF a = 1 AND (i = 3 OR i = 4)then
     if i!=4 then
      txt = txt || ' un';
     else
      txt = txt || ' '||a||'/100';
     end if;
    ELSE
     if i!=4 then
      txt = txt || d[a];
     else
      txt = txt || ' '||a||'/100';
     end if;
    END IF;
   ELSE
    a1 = substring(a::text FROM 1 FOR 1);
    a11 = substring(a::text FROM 1 FOR 2);
    a2 = substring(a::text FROM 2 FOR 1);
    IF a2 = 1 AND (i = 3 OR i = 4) then
     if i!=4 then
      txt = txt || f[a1] || ' y' || ' uno';
     else
      txt = txt || ' '||a11||'/100';
     end if;
    ELSE
     IF a2 <> 0 THEN
      if i!=4 then 
       txt = txt || f[a1] || ' y' || d[a2];
      else
       txt = txt || ' '||a11||'/100';
      end if;
     ELSE
      if i!=4 then
       txt = txt || f[a1];
      else
       txt = txt || ' '||a11||'/100';
      end if;
     END IF;
    END IF;
   END IF;
  END IF;
  IF n > 0 THEN
   IF i = 1 THEN
    IF n = 1 THEN
     txt = txt || ' millón';
    ELSE
     txt = txt || ' millones';
    END IF;
   ELSIF i = 2 THEN
    txt = txt || ' mil';
   END IF;  
  END IF;
 END LOOP;
 txt = LTRIM(txt);
 IF negativo = TRUE THEN
    txt= '-' || txt;
 END IF;

 IF moneda = 1 Then
 IF position('con' in txt) > 0 THEN
    RETURN overlay(txt placing 'quetzales con' from position('con' in txt) for 3);--||' centavos';
 ELSE
    RETURN txt|| ' quetzales exactos';
 END IF;
 END IF;

 IF moneda = 2 Then
 IF  position('con' in txt) > 0 THEN
    RETURN overlay(txt placing 'dolares con' from position('con' in txt) for 3);--||' centavos';
 ELSE
    RETURN txt|| ' dolares exactos';
 END IF;
 END IF;
END;
$function$
;
