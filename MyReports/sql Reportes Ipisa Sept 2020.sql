--*****************************CIERRE DE ESTACIONES*******************
select 
ps.id,
ps.user_id,
ps."name" as sesion,
rpu."name" as usuario,
po.date_order as fecha,
prc."name" as cliente,
prc.vat as nit,
ai."number" as factura,
po.pos_reference as pedido,
case 
when po.state = 'draft' then 'Nuevo'
when po.state = 'cancel' then 'Cancelado'
when po.state = 'paid' then 'Pagado'
when po.state = 'done' then 'Publicado'
when po.state = 'invoiced' then 'Facturado'
end as estado,
pp.default_code as producto,
ail.quantity as cantidad,
ai.amount_total as total
from pos_order as po
inner join pos_session as ps
on po.session_id = ps.id
inner join res_users as ru
on po.user_id = ru.id
inner join res_partner as rpu
on ru.partner_id = rpu.id
inner join res_partner as prc
on po.partner_id = prc.id
inner join account_invoice as ai
on po."name" = ai.origin
inner join account_invoice_line as ail
on ai.id = ail.invoice_id
inner join pos_order_line as pol
on pol.order_id = po.id
inner join product_product as pp
on pol.product_id = pp.id
where cast(po.date_order::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
and $X{IN,ps.user_id,p_id_user_t}
and $X{IN,ps.id,p_id_sesion_t}

--**********************SQL PARAMETROS JASPER ************************

--******SESIONES
select inf.id, inf.sesion
from (
select distinct ps."name" as sesion, ps.id
from pos_session as ps
order by ps.id desc) as inf limit 50

--******USUARIOS
select inf.id, inf.usuario
from(
select distinct rpu."name" as usuario, ps.user_id as id
from pos_session as ps
inner join res_users as ru
on ps.user_id = ru.id
inner join res_partner as rpu
on ru.partner_id = rpu.id
where ps.user_id != 6
order by rpu."name") as inf


--**********************************************************************

--*****************************VENTAS SOLUNION*******************

select
ai.date_invoice as fecha,
ai."number" as numero,
ai.amount_total as monto,
rpc.x_codigo_solunion as codigo_solunion,
rpc.vat as nit,
rpc.x_razon_social as razon_social,
rpc."ref" as codigo_externo,
rpc."name" as cliente,
sum(ail.quantity) as cantidad,
rpc.credit_control as credito,
rpu."name" as vendedor
from account_invoice as ai
inner join res_partner as rpc
on ai.partner_id = rpc.id
inner join account_invoice_line as ail
on ail.invoice_id = ai.id
inner join res_users as ru
on ai.user_id = ru.id
inner join res_partner as rpu
on ru.partner_id = rpu.id
where cast(ai.date_invoice::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
and $X{IN,ai.user_id,p_id_user_t}
and $X{IN,rpc.credit_control,p_credito_t}
group by
ai.date_invoice,ai."number", ai.amount_total,
rpc.x_codigo_solunion, rpc.vat, rpc.x_razon_social,
rpc."ref", rpc."name",rpc.credit_control,rpu."name"
order by ai.date_invoice



--******USUARIOS
select inf.id, inf.vendedor
from(
select distinct rpu."name" as vendedor, ai.user_id as id
from account_invoice as ai
inner join res_users as ru
on ai.user_id = ru.id
inner join res_partner as rpu
on ru.partner_id = rpu.id
where ai.user_id not in (6,1)
order by rpu."name") as inf

--********Credito

select 'si' as id, 'Si' as name
union
select 'no' as id, 'No' as name


--**********************************************************************

--*****************************HISTORIAL DE PAGOS*******************

select
ai.origin as pedido,
rpc."name" as cliente,
ai."number" as numero_factura,
ai.date_invoice as fecha_factura,
ai.amount_total as total,
ap.payment_date as fecha_deposito,
ap.amount as abonado,
ap.x_recibo_caja as recibo,
ap.x_deposito as boleta,
aj."name" as banco
from account_invoice as ai
inner join sale_order as so
on ai.origin = so."name"
inner join res_partner as rpc
on ai.partner_id = rpc.id
inner join payment_invoice_line as pil
on pil.invoice_id = ai.id
inner join account_payment as ap
on pil.payment_id = ap.id
inner join account_journal as aj
on ap.journal_id = aj.id
where ai.state = 'paid'
and cast(ai.date_invoice::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
and $X{IN,ai.partner_id,p_id_cliente_t}


select distinct ai.partner_id as id, rpc."name"
from account_invoice as ai
inner join res_partner as rpc
on ai.partner_id = rpc.id
where ai.state = 'paid'
order by rpc."name"

--**********************************************************************


--*****************************FACTURACION ESTACIONES *******************


select 
fact.id,
fact."number",
fact.mpfel_serial as serie,
fact.mpfel_number as numero,
fact.date_invoice as fecha,
cli.vat as nit,
cli."name" as nombre,
cli.street as direccion,
coalesce(cast(cant.super as double precision),0) super,
coalesce(cast(cant.regular as double precision),0) regular,
coalesce(cast(cant.diesel as double precision),0) diesel,
coalesce(cast(cant.otros as double precision),0) flete,
coalesce(cast(total.totsuper as double precision),0) totsuper,
coalesce(cast(total.totregular as double precision),0) totregular,
coalesce(cast(total.totdiesel as double precision),0) totdiesel,
coalesce(cast(total.tototros as double precision),0) totflete,
coalesce(cast(imp.idpsuper as double precision),0) idpsuper,
coalesce(cast(imp.idpregular as double precision),0) idpregular,
coalesce(cast(imp.idpdiesel as double precision),0) idpdiesel,
coalesce(cast(imp.iva as double precision),0) iva,
fact.amount_total as total,
case 
	when fact.state = 'open' then 'Abierta'
	when fact.state = 'paid' then 'Pagada'
	when fact.state = 'draft' then 'Borrador'
	when fact.state = 'cancel' then 'Cancelado'
end estado,
di."name" as diario_factura
from account_invoice as fact
inner join res_partner as cli
on fact.partner_id = cli.id
inner join account_journal as di
on fact.journal_id = di.id
left join (
select cant.invoice_id, cant.super, cant.regular, cant.diesel, cant.otros
from crosstab(
'
select
t.invoice_id,
t.descripcion,
t.cantidad
from
(
--------------------------
select 
info.invoice_id,
pla.descripcion,
info.cantidad
from (
select pp.id produc_id, pt."name" descripcion
from product_template as pt
inner join product_product as pp
on pp.product_tmpl_id = pt.id
where pp.id in (78,79)
) as pla
left join
(	
select 
ai.id invoice_id,
ail.product_id, 
sum(ail.quantity) cantidad
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
inner join account_journal as aj
on ai.journal_id = aj.id
where ail.product_id in (78,79)
and aj.mpfel_type = ''FACT''
group by ai.id, ail.product_id
) as info
on pla.produc_id = info.product_id
----------------------------------
union all
select 
invoice_id,
descripcion,
sum(cantidad) as cantidad
from
(
select 
ai.id invoice_id,
''Diesel'' as descripcion,
ail.quantity as cantidad
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
inner join account_journal as aj
on ai.journal_id = aj.id
where ail.product_id = 80
and aj.mpfel_type = ''FACT''
union all
select 
ai.id invoice_id,
''Diesel'' as descripcion,
ail.quantity as cantidad
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
inner join account_journal as aj
on ai.journal_id = aj.id
where ail.product_id = 81
and aj.mpfel_type = ''FACT''
) as tdi
group by invoice_id,descripcion
--------------------------------------
union all
select 
ai.id invoice_id,
''Otros'' as descripcion,
ail.quantity as cantidad
from account_invoice as ai
inner join account_invoice_line as ail
on ai.id = ail.invoice_id
join x_producto_reporte as xpr
on ail.product_id = xpr.x_producto_id
inner join account_journal as aj
on ai.journal_id = aj.id
where aj.mpfel_type = ''FACT''
) as t
order by t.invoice_id desc
',
'select descripcion
from(
select 1 as idt, ''Gasolina Superior'' as descripcion
union all
select 2 as idt, ''Gasolina Regular'' as descripcion
union all
select 3 as idt, ''Diesel'' as descripcion
union all
select 4 as idt, ''Otros'' as descripcion
) as dt
order by dt.idt'
)as cant
("invoice_id" numeric, "super" varchar, "regular" varchar, "diesel" varchar, "otros" varchar)
) as cant
on fact.id = cant.invoice_id
left join (
select prec.invoice_id, prec.totsuper, prec.totregular, prec.totdiesel, prec.tototros
from crosstab(
'
select
t.invoice_id,
t.descripcion,
t.total
from
(
select 
info.invoice_id,
pla.descripcion,
info.total
from (
select pp.id produc_id, pt."name" descripcion
from product_template as pt
inner join product_product as pp
on pp.product_tmpl_id = pt.id
where pp.id in (78,79)
) as pla
left join
(	
select 
ai.id invoice_id,
ail.product_id, 
sum(ail.price_subtotal) total
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
inner join account_journal as aj
on ai.journal_id = aj.id
where ail.product_id in (78,79)
and aj.mpfel_type = ''FACT''
group by ai.id, ail.product_id
) as info
on pla.produc_id = info.product_id
--------------------------
union all 
select 
invoice_id,
descripcion,
sum(total) as total
from
(
select 
ai.id invoice_id,
''Diesel'' as descripcion,
ail.price_subtotal as total
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
inner join account_journal as aj
on ai.journal_id = aj.id
where ail.product_id = 80
and aj.mpfel_type = ''FACT''
--------------------------
union all
select 
ai.id invoice_id,
''Diesel'' as descripcion,
ail.price_subtotal
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
inner join account_journal as aj
on ai.journal_id = aj.id
where ail.product_id = 81
and aj.mpfel_type = ''FACT''
---------------------------------
union all
select 
ai.id invoice_id,
''Otros'' as descripcion,
ail.price_subtotal
from account_invoice as ai
inner join account_invoice_line as ail
on ai.id = ail.invoice_id
join x_producto_reporte as xpr
on ail.product_id = xpr.x_producto_id
inner join account_journal as aj
on ai.journal_id = aj.id
where aj.mpfel_type = ''FACT''
) as tdi
group by invoice_id,descripcion
) as t
order by t.invoice_id desc
',
'select descripcion
from(
select 1 as idt, ''Gasolina Superior'' as descripcion
union all
select 2 as idt, ''Gasolina Regular'' as descripcion
union all
select 3 as idt, ''Diesel'' as descripcion
union all
select 4 as idt, ''Otros'' as descripcion
) as dt
order by dt.idt'
)as prec
("invoice_id" numeric, "totsuper" varchar, "totregular" varchar, "totdiesel" varchar, "tototros" varchar)
) as total
on fact.id = total.invoice_id
left join (
select tax.invoice_id, tax.idpsuper, tax.idpregular, tax.idpdiesel, tax.iva
from crosstab(
'select 
info.invoice_id,
tax.descripcion,
info.imp
from (
select id, "name" descripcion
from account_tax
where id in (76,79,81,89)) as tax
left join
(	
select 
ai.id invoice_id,
ait.tax_id, 
sum(ait.amount) imp
from account_invoice as ai
left join account_invoice_tax as ait
on ai.id = ait.invoice_id
inner join account_journal as aj
on ai.journal_id = aj.id
where ait.tax_id in (76,79,81,89)
--and aj.mpfel_type = ''FACT''
group by ai.id, ait.tax_id
) as info
on tax.id = info.tax_id
order by invoice_id desc',
'select d.descripcion
from(
select
case 
	when id = 79 then 1
	when id = 76 then 2
	when id = 81 then 3
	when id = 89 then 4
end ide,
"name" descripcion
from account_tax
where id in (76,79,81,89)
order by ide) as d'
)as tax
("invoice_id" numeric, "idpsuper" varchar, "idpregular" varchar, "idpdiesel" varchar, "iva" varchar)
) as imp
on fact.id = imp.invoice_id
where fact."type" = 'out_invoice'
and di.mpfel_type = 'FACT'
and cast(fact.date_invoice::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
and $X{IN,fact.partner_id,p_id_cliente_t}
order by fact.date_invoice


--******CLIENTES
select rp.id,
case when rp.vat is null then
	rp."name"
	else
	rp."name"||' - '||vat
end as name
from res_partner rp
where rp.customer = 'true'
order by rp."name"



