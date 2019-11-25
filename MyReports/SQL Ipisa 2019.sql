--Reporte de Pedidos Ipisa

select
ov.name pedido,
coalesce(fact."number",'') factura,
ov.validity_date fecha_pedido,
cli."name" cliente,
nusu."name" vendedor,
coalesce(nub."name",'') destino,
(
select case
	when count(id) = 0 then 'SF'
		else 'CF'
	end
from sale_order_line as ol
where ol.order_id = ov.id
and ol.product_id = 12
)tipo,
coalesce(tra."name",'') unidad,
coalesce(cast(cant.super as double precision),0) super,
coalesce(cast(cant.regular as double precision),0) regular,
coalesce(cast(cant.diesel as double precision),0) diesel,
coalesce(cast(cant.flete as double precision),0) flete,
coalesce(cast(prec.super as double precision),0) superpr,
coalesce(cast(prec.regular as double precision),0) regularpr,
coalesce(cast(prec.diesel as double precision),0) dieselpr,
coalesce(cast(prec.flete as double precision),0) fletepr,
coalesce(cast((
select case
	when sum(idp.amount)= 0 then 0
	else sum(idp.amount)
end idp
from account_invoice_tax as idp
where idp.invoice_id = fact.id
) as double precision),0)IDP,
cast(ov.amount_total as double precision) total,
(case
	when fact.state = 'open' then 'abierta'
	when fact.state = 'paid' then 'pagada'
	when fact.state = 'draft' then 'borrador'
	when fact.state = 'cancel' then 'cancelado'
	when fact.state is null then 'no aplica'
end)estado,
case
	when ov.state = 'draft' then 'presupuesto'
	when ov.state = 'sale' then 'pedido de venta'
	when ov.state = 'sent' then 'presupuesto enviado'
	when ov.state = 'done' then 'bloqueado'
	when ov.state = 'cancel' then 'cancelado'
end estado_ov
from sale_order as ov
left join account_invoice as fact
on fact.origin = ov."name"
inner join res_partner as cli
on ov.partner_id = cli.id
inner join res_users as usu
on ov.user_id = usu.id
inner join res_partner as nusu
on usu.partner_id = nusu.id
left join x_ubicacion_partner as ub
on ov.x_ubicacion_id = ub.id
left join x_ubicacion as nub
on ub."name" = nub.id
left join x_tranporte as tra
on fact.x_transporte_id = tra.id
left join(
select cant.order_id, cant.super, cant.regular, cant.diesel, cant.flete
from crosstab(
'select 
info.order_id,
pla.descripcion,
info.cantidad
from (
select id produc_id, "name" descripcion
from product_template
where id in (8,9,10,12)) as pla
left join
(	
select 
so.id order_id,
sol.product_id, 
sum(sol.product_uom_qty) cantidad
from sale_order as so
left join sale_order_line sol
on so.id = sol.order_id
where sol.product_id in (8,9,10,12)
group by so.id, sol.product_id
) as info
on pla.produc_id = info.product_id
order by order_id desc', --este es el sql que trae las 3 filas (rowid,category, value)
'select "name" descripcion
from product_template
where id in (8,9,10,12)
order by id' --este es el sql de las columnas
) as cant
("order_id" numeric, "super" varchar, "regular" varchar, "diesel" varchar, "flete" varchar)) as cant
on ov.id = cant.order_id
left join (
select prec.order_id, prec.super, prec.regular, prec.diesel, prec.flete
from crosstab(
'select 
info.order_id,
pla.descripcion,
info.precio
from (
select id produc_id, "name" descripcion
from product_template
where id in (8,9,10,12)) as pla
left join
(	
select 
so.id order_id,
sol.product_id,
sum(sol.price_unit) precio
from sale_order as so
left join sale_order_line sol
on so.id = sol.order_id
where sol.product_id in (8,9,10,12)
group by so.id, sol.product_id
) as info
on pla.produc_id = info.product_id
order by order_id desc', --este es el sql que trae las 3 filas (rowid,category, value)
'select "name" descripcion
from product_template
where id in (8,9,10,12)
order by id' --este es el sql de las columnas
) as prec
("order_id" numeric, "super" varchar, "regular" varchar, "diesel" varchar, "flete" varchar)) as prec
on ov.id = prec.order_id
where cast(ov.validity_date::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
and $X{IN,ov.partner_id,p_id_cliente_t}
order by ov.validity_date

--Se debe ejecutar esta sentencia para que aplique la funcion crosstab en el servidor
CREATE EXTENSION IF NOT EXISTS tablefunc;


--Para el filtro de clientes en Jasper Server
select id, "name"
from res_partner
where customer = true
and "name" is not null
order by "name"

	
	
--Reporte de Facturas Ipisa

select
fact.date_invoice fecha,
dia.serie_venta serie,
fact."number" numero,
fact.origin pedido,
tra."name" transportista,
tra.x_nit nittra,
cam.x_placa placa,
cam."name" unidad,
cli."name" cliente,
cli.vat nit,
coalesce(cast(infdoc.super as double precision),0) super,
coalesce(cast(infdoc.regular as double precision),0) regular,
coalesce(cast(infdoc.diesel as double precision),0) diesel,
fact.amount_total total
from account_invoice as fact
inner join sale_order as ped
on fact.origin = ped."name"
inner join account_journal as dia
on fact.journal_id = dia.id
inner join x_tranportista as tra
on fact.x_transportista_id = tra.id
inner join x_tranporte as cam
on fact.x_transporte_id = cam.id
inner join res_partner as cli
on fact.partner_id = cli.id
inner join
(
select pr.fact_id, pr.super, pr.regular, pr.diesel
from crosstab(
'select
dat.fact_id,cat.descripcion,dat.total
from (
select id,"name" descripcion
from product_template
where id in (8,9,10)) as cat
left join
(
select invoice_id fact_id, pro.id, sum(price_subtotal) total
from account_invoice_line as li
inner join product_template as pro
on li.product_id = pro.id
where pro.id in (8,9,10)
group by invoice_id, pro.id) as dat
on cat.id = dat.id
order by dat.fact_id desc',
'select "name" descripcion
from product_template
where id in (8,9,10)
order by id'
) as pr(fact_id numeric, "super" varchar, "regular" varchar, "diesel" varchar)
) as infdoc
on fact.id = infdoc.fact_id
where fact.state != 'cancel'
and cast(fact.date_invoice::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
order by fact.date_invoice


--Reporte de Saldos Ipisa

select
nven."name" vendedor,
trim(cli."ref")||'  -  '||trim(cli."name") cliente,
fact."number" factura,
date_invoice fecha,
coalesce(cast(current_date-date_invoice as double precision),0) dias_transcurridos,
dic."name" dias_credito,
info."0-2", info."3-5", info."6-8", info."9-10", info."mas de 10",
residual saldo
from account_invoice as fact
inner join res_users as ven
on fact.user_id = ven.id
inner join res_partner as nven
on ven.partner_id = nven.id
inner join res_partner as cli
on cli.id = fact.partner_id
inner join account_payment_term as dic
on fact.payment_term_id = dic.id
inner join (
select
id,
coalesce(cast("0-2" as double precision),0) as "0-2",
coalesce(cast("3-5" as double precision),0) as "3-5",
coalesce(cast("6-8" as double precision),0) as "6-8",
coalesce(cast("9-10" as double precision),0) as "9-10",
coalesce(cast("mas de 10" as double precision),0) as "mas de 10"
from(
select *
from crosstab(
'select
id,
case 
	when current_date-date_invoice between 0 and 2 then ''0-2''
	when current_date-date_invoice between 3 and 5 then ''3-5''
	when current_date-date_invoice between 6 and 8 then ''6-8''
	when current_date-date_invoice between 9 and 10 then ''9-10''
	when current_date-date_invoice > 10 then ''mas de 10''
end rango,
residual
from account_invoice
where current_date-date_invoice>=0',
'select rango
from(
select ''0-2'' as rango
union
select ''3-5'' as rango
union
select ''6-8'' as rango
union
select ''9-10'' as rango
union
select ''mas de 10'' as rango) as r
order by 1'
)as(id numeric, "0-2" varchar, "3-5" varchar, "6-8" varchar, "9-10" varchar, "mas de 10" varchar))as inf
) as info
on fact.id = info.id
where current_date-fact.date_invoice>=0
and fact.payment_term_id not in (1,6)
and fact.residual > 0
order by date_invoice

----Reporte de Seguro


select 
uni.x_corredor as corredor, 
tra."name" as transportista,
uni."name" as unidad,
uni.x_placa as placa,
fac.date_invoice as fecha,
fac."number" as factura,
fac.origin as pedido,
cli."ref" ||' '||cli."name" cliente,
sum(det.quantity) as volumen,
round(sum(det.quantity)*0.056,2) as seguro
from account_invoice as fac
inner join x_tranportista as tra
on fac.x_transportista_id = tra.id
inner join x_tranporte as uni
on fac.x_transporte_id = uni.id
inner join res_partner as cli
on fac.partner_id = cli.id
inner join account_invoice_line as det
on fac.id = det.invoice_id
where state in ('open','paid')
and cast(fac.date_invoice::text as date) between cast($P{p_fecha_inicio_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
group by
uni.x_corredor, 
tra."name",
fac.date_invoice,
fac."number",
fac.origin,
cli."ref" ||' '||cli."name",
uni."name",
uni.x_placa
order by 
fac.date_invoice



----Reporte Facturacion



select 
fact.id,
fact."number",
case 
	when position('-' in fact."number")-1 > 0 then
		 substr(fact."number",1,position('-' in fact."number")-1)
	 else	 	
	 	substr(fact."number",1,position('/' in fact."number")+position('/' in substr(fact."number",position('/' in fact."number")+1))-1)
 end serie,
case 
	when position('-' in fact."number")-1 > 0 then
		cast(substr(fact."number",(position('-' in fact."number")+1)) as integer)
	else
		cast(substr(substr(fact."number",position('/' in fact."number")+1),position('/' in substr(fact."number",position('/' in fact."number")+1))+1) as integer)
end numero,
fact.date_invoice as fecha,
cli.vat as nit,
cli."name" as nombre,
cli.street as direccion,
coalesce(cast(cant.super as double precision),0) super,
coalesce(cast(cant.regular as double precision),0) regular,
coalesce(cast(cant.diesel as double precision),0) diesel,
coalesce(cast(cant.flete as double precision),0) flete,
coalesce(cast(total.totsuper as double precision),0) totsuper,
coalesce(cast(total.totregular as double precision),0) totregular,
coalesce(cast(total.totdiesel as double precision),0) totdiesel,
coalesce(cast(total.totflete as double precision),0) totflete,
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
end estado
from account_invoice as fact
inner join res_partner as cli
on fact.partner_id = cli.id
inner join account_journal as di
on fact.journal_id = di.id
left join (
select cant.invoice_id, cant.super, cant.regular, cant.diesel, cant.flete
from crosstab(
'select 
info.invoice_id,
pla.descripcion,
info.cantidad
from (
select id produc_id, "name" descripcion
from product_template
where id in (8,9,10,12)) as pla
left join
(	
select 
ai.id invoice_id,
ail.product_id, 
sum(ail.quantity) cantidad
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
where ail.product_id in (8,9,10,12)
group by ai.id, ail.product_id
) as info
on pla.produc_id = info.product_id
order by invoice_id desc',
'select "name" descripcion
from product_template
where id in (8,9,10,12)
order by id'
)as cant
("invoice_id" numeric, "super" varchar, "regular" varchar, "diesel" varchar, "flete" varchar)
) as cant
on fact.id = cant.invoice_id
left join (
select prec.invoice_id, prec.totsuper, prec.totregular, prec.totdiesel, prec.totflete
from crosstab(
'select 
info.invoice_id,
pla.descripcion,
info.total
from (
select id produc_id, "name" descripcion
from product_template
where id in (8,9,10,12)) as pla
left join
(	
select 
ai.id invoice_id,
ail.product_id, 
sum(ail.price_subtotal) total
from account_invoice as ai
left join account_invoice_line as ail
on ai.id = ail.invoice_id
where ail.product_id in (8,9,10,12)
group by ai.id, ail.product_id
) as info
on pla.produc_id = info.product_id
order by invoice_id desc',
'select "name" descripcion
from product_template
where id in (8,9,10,12)
order by id'
)as prec
("invoice_id" numeric, "totsuper" varchar, "totregular" varchar, "totdiesel" varchar, "totflete" varchar)
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
where id in (2,4,6,8)) as tax
left join
(	
select 
ai.id invoice_id,
ait.tax_id, 
sum(ait.amount) imp
from account_invoice as ai
left join account_invoice_tax as ait
on ai.id = ait.invoice_id
where ait.tax_id in (2,4,6,8)
group by ai.id, ait.tax_id
) as info
on tax.id = info.tax_id
order by invoice_id desc',
'select d.descripcion
from(
select
case 
	when id = 6 then 1
	when id = 4 then 2
	when id = 8 then 3
	when id = 2 then 4
end ide,
"name" descripcion
from account_tax
where id in (2,4,6,8)
order by ide) as d'
)as tax
("invoice_id" numeric, "idpsuper" varchar, "idpregular" varchar, "idpdiesel" varchar, "iva" varchar)
) as imp
on fact.id = imp.invoice_id
where fact."type" = 'out_invoice'
and cast(fact.date_invoice::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
and $X{IN,fact.partner_id,p_id_cliente_t}
order by fact.date_invoice

--Para el filtro de clientes en Jasper Server
select rp.id,
case when rp.vat is null then
	rp."name"
	else
	rp."name"||' - '||vat
end as name
from res_partner rp
where rp.customer = 'true'
order by rp."name"



