select
infcd.estatus,
infc.file,
infc.tipo_transporte,
infc.tipo_contenedor,
infc.no_contenedor,
infc.da,
infcd.producto,
infcd.unidades,
infcd.bultos,
infcd.cbm,
infcd.fecha_vencimiento,
infc.ingreso_cealsa,
infc.dias_estadia,
infcd.destino
from (
select
ct.id as contenedor_id,
fl."name" as file,
ct.tipo_transporte,
tc."name" as tipo_contenedor,
ct."name" no_contenedor,
da.duca_numero as da,
ct.fecha_llegada_recinto as ingreso_cealsa,
current_date - ct.fecha_llegada_recinto as dias_estadia
from wms_contenedor as ct
inner join documents_folder as fl
on ct.parent_folder_id = fl.id
left join wms_contenedor_tipo as tc
on ct.contenedor_tipo_id = tc.id
left join wms_duca_despacho as da
on ct.duca = da.id) as infc
inner join
(
select cd.contenedor_id,
case 
	when cd.estatus in ('exportacion','confirmar_pago') then 
		(case 
			when cd.estatus = 'exportacion' then 'Exportacion'
			when cd.estatus = 'confirmar_pago' then 'Confirmar Pago'
		 end)
	when cd.estatus not in ('exportacion','confirmar_pago') then
		(case 
			when ct.state != 'sol_aprobado' then
			(case
				when ct.state = 'reg_pendiente' then 'Pendiente Registro'
				when ct.state = 'sol_ingresado' then 'Solicitud Registro Ingresada'
			 end)
			when ct.state = 'sol_aprobado' and fr.state is null then 'Certificado Aprobada'
			when ct.state = 'sol_aprobado' and fr.state is not null then
			(case 
				when fr.state = 'cert_pendiente' then 'Pendiente Franquisia'
				when fr.state = 'sol_ingresado' then 'Solicitud Franquisia Ingresada'
				when fr.state = 'sol_aprobado' then 'Franquisia Aprobada'
			 end)
		 end)
end estatus,
pt."name" as producto,
infsq.quantity as unidades,
cdd.cantidad_bulto as bultos,
cdd.cbm,
cast(cdd.fecha_vencimiento as date) as fecha_vencimiento,
co."name" as destino,
sw.tipo_almacen,
cdd.product_id,
cdd.lot_name,
spt.default_location_dest_id location_id
from wms_contenedor_destino as cd
left join wms_contenedor_destino_detalle as cdd
on cd.id = cdd.contenedor_destino_id
left join product_product as pr
on cdd.product_id = pr.id
left join product_template as pt
on pr.product_tmpl_id = pt.id
left join res_partner as co
on cd.empresa_id = co.id
left join wms_franquicia as fr
on cdd.franquicia_id = fr.id
left join wms_certificado as ct
on cdd.certificado_id = ct.id
inner join stock_picking_type as spt
on cd.picking_type_id = spt.id
inner join stock_warehouse as sw
on spt.warehouse_id = sw.id
inner join stock_location as sl
on spt.default_location_dest_id = sl.id
inner join (
select sq.product_id, lt."name" lot_name, sq.location_id, quantity
from stock_quant as sq
inner join stock_production_lot as lt
on sq.lot_id = lt.id
where quantity >= 0
) as infsq
on cdd.product_id = infsq.product_id
and cdd.lot_name = infsq.lot_name
and spt.default_location_dest_id = infsq.location_id
where sw.tipo_almacen in ('fiscal','pais')
) as infcd
on infc.contenedor_id = infcd.contenedor_id






select
ct."name" contenedor,
fl."name" as expediente,
pr."name" as origen_mercaderia,
da.duca_numero as no_dua,
nav."name" as naviera,
tc."name" as tipo_contenedor,
ct.tipo_transporte as medio_llegada,
ct.fecha_zarpe,
ct.fecha_atraque,
ct.fecha_documentacion as recep_documento,
crt.fecha_ingreso as ingreso_cert,
crt.fecha_notificacion as notificacion_cert,
frq.fecha_ingreso as ingreso_exp_sat,
frq.fecha_notificacion as notificacion_exp_sat,
ct.fecha_validacion_duca,
ct.fecha_llegada_recinto as arribo_cealsa,
gas.sep as Serv_Extraord_Puerto,
gas.mln as Manejo_Local_Naviera,
gas.alm as Almacenaje,
gas.madoc as Manejo_Documentacion,
gas.pdtr as Pago_Tramite,
gas.apmpq as APM_PQ,
gas.oiras,
gas.march as Marchamo,
inftotgas.tqt as COST_TOT_hASTA_DA,
gas.cbl as Cargos_BL,
gas.udf as USO_DE_FIANZA,
gas.dem as Demoras,
gas.fm as flete_maritimo,
inftotgas.tdl as COSTO_TOT_DA_DOLARES,
ct.fecha_atraque-ct.fecha_zarpe as dias_transito,
ct.fecha_atraque-ct.fecha_documentacion as dias_anticip_recep,
crt.fecha_notificacion-crt.fecha_ingreso as tiempo_certificacion,
frq.fecha_ingreso-crt.fecha_notificacion as tiemp_sol_franq,
frq.fecha_notificacion-frq.fecha_ingreso as tiempo_franquisia,
ct.fecha_validacion_duca-ct.fecha_atraque as tiempo_total_dat,
ct.fecha_llegada_recinto-ct.fecha_validacion_duca as tiemp_tot_desp_cealsa,
ct.fecha_llegada_recinto-ct.fecha_atraque as tiemp_total_cont_acealsa,
ct.fecha_llegada_recinto-ct.fecha_zarpe as pendiente_nombre
from wms_contenedor as ct
inner join documents_folder as fl
on ct.parent_folder_id = fl.id
left join wms_contenedor_tipo as tc
on ct.contenedor_tipo_id = tc.id
left join wms_duca_despacho as da
on ct.duca = da.id
left join res_country as pr
on ct.pais_origen = pr.id
left join wms_naviera_tipo as nav
on ct.naviera_id = nav.id
left join (
select distinct cd.contenedor_id, ct.fecha_ingreso, ct.fecha_autorizacion as fecha_notificacion
from wms_contenedor_destino as cd
left join wms_contenedor_destino_detalle as cdd
on cd.id = cdd.contenedor_destino_id
left join wms_certificado as ct
on cdd.certificado_id = ct.id
where ct.fecha_ingreso is not null) as crt
on ct.id = crt.contenedor_id
left join (
select distinct cd.contenedor_id, fr.fecha_ingreso, fr.fecha_autorizacion as fecha_notificacion
from wms_contenedor_destino as cd
left join wms_contenedor_destino_detalle as cdd
on cd.id = cdd.contenedor_destino_id
left join wms_franquicia as fr
on cdd.franquicia_id = fr.id
where fr.fecha_ingreso is not null) as frq
on ct.id = frq.contenedor_id
left join (
select ge.contenedor_id, ge.sep, ge.mln,ge.alm,ge.madoc,ge.pdtr,
ge.apmpq, ge.oiras, ge.march, ge.cbl, ge.udf, ge.dem, ge.fm
from crosstab(
'select tgc.contenedor_id, tg."name" as descripcion, 
case
	when tgc.currency_id=2 then ''USD ''||tgc.valor
	when tgc.currency_id=84 then ''QTQ ''||tgc.valor
end valor
from wms_tipo_gasto_contenedor as tgc
inner join wms_tipo_gasto as tg
on tgc.tipo_gasto_id = tg.id',
'select "name" as descripcion
from wms_tipo_gasto as ga
order by id'
) as ge
("contenedor_id" numeric, "sep" varchar, "mln" varchar, "alm" varchar, "madoc" varchar, "pdtr" varchar,
 "apmpq" varchar, "oiras" varchar, "march" varchar, "cbl" varchar, "udf" varchar, "dem" varchar, "fm" varchar)
 ) as gas
on ct.id = gas.contenedor_id
left join (
select tgas.contenedor_id, tgas.tdl, tgas.tqt
from crosstab(
'select tgc.contenedor_id, mon."name" as moneda, sum(tgc.valor) total
from wms_tipo_gasto_contenedor as tgc
inner join wms_tipo_gasto as tg
on tgc.tipo_gasto_id = tg.id
inner join res_currency as mon
on tgc.currency_id = mon.id
group by tgc.contenedor_id, mon."name"
order by tgc.contenedor_id',
'select "name" as moneda
from res_currency
where id in (2,84)
order by id'
)as tgas ("contenedor_id" numeric, "tdl" varchar, "tqt" varchar)
) as inftotgas
on ct.id = inftotgas.contenedor_id
