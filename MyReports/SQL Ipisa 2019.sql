--Reporte de Pedidos Ipisa

select 
ov.name pedido,
coalesce(fact."number",'') factura,
ov.date_order fecha_pedido,
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
	when fact.state is null then 'sin factura'
end)estado
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
where ov.date_order between $P{p_fecha_inicial_t} and $P{p_fecha_final_t}
and $X{IN,ov.partner_id,p_id_cliente_t}
order by ov.id

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
and fact.date_invoice between $P{p_fecha_inicial_t} and $P{p_fecha_final_t}
order by fact.id desc