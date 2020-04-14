--Cheque
--Consulta General (Control "Banco" Jasper) - (el identificador es p_diario)

select id, "name"
from account_journal aj
where type = 'bank'
and check_manual_sequencing = true
order by "name"

--consulta que depende de la General (Control "Cheque" Jasper) - (el identificador es p_cheque)

select ap.check_number as p_cheque, ap.check_number as cheque
from account_payment ap
where ap.payment_type = 'outbound'
and ap.state != 'cancelled'
and ap.check_number is not null
and $X{IN,ap.journal_id,p_diario}
order by ap.check_number desc


--Consulta del Reporte de Cheques

select
	ap.id id_pago,
	lo."name" prestamo,
	rp.nombre_cliente as empresa,
		to_char(ap.payment_date,'DD "de "')||
	case
	when to_char(ap.payment_date, 'MM')::numeric = 1 then 'Enero'
	when to_char(ap.payment_date, 'MM')::numeric = 2 then 'Febrero'
	when to_char(ap.payment_date, 'MM')::numeric = 3 then 'Marzo'
	when to_char(ap.payment_date, 'MM')::numeric = 4 then 'Abril'
	when to_char(ap.payment_date, 'MM')::numeric = 5 then 'Mayo'
	when to_char(ap.payment_date, 'MM')::numeric = 6 then 'Junio'
	when to_char(ap.payment_date, 'MM')::numeric = 7 then 'Julio'
	when to_char(ap.payment_date, 'MM')::numeric = 8 then 'Agosto'
	when to_char(ap.payment_date, 'MM')::numeric = 9 then 'Septiembre'
	when to_char(ap.payment_date, 'MM')::numeric = 10 then 'Octubre'
	when to_char(ap.payment_date, 'MM')::numeric = 11 then 'Noviembre'
	when to_char(ap.payment_date, 'MM')::numeric = 12 then 'Diciembre'
	end
	||to_char(ap.payment_date,'" del" yyyy')  payment_date,
	round(ap.amount::numeric,2) amount,
	f_moneda(1,
	ap.amount) as amount_letra,
	case
		when ap.description_pay is null then 
			ap.communication||' - No. Cheque: '||ap.check_number
		else
			ap.description_pay||' - No. Cheque: '||ap.check_number
	end descripcion,
	cta.code cuenta,
	cta."name" as descripcion_linea,
	li.debit,
	li.credit,
	ap.journal_id,
	ap.check_number
from
	account_payment as ap
inner join res_partner as rp on
	ap.partner_id = rp.id
inner join account_journal as aj on
	ap.journal_id = aj.id
left join partner_loan_details as lo on
	ap.loan_id = lo.id
inner join account_move_line as li on
	li.payment_id = ap.id
inner join account_account as cta on
	cta.id = li.account_id
where
	ap.payment_type = 'outbound'
	and $X{IN,ap.journal_id,p_diario}	
	and $X{IN,ap.check_number,p_cheque}
	order by ap.check_number desc










--Comprobante
--Consulta General (Control "Diario" Jasper) - (el identificador es p_diario)

select id, "name" as diario
from account_journal aj
where type = 'sale'
order by "name"


--consulta que depende de la General (Control "Documento" Jasper) - (el identificador es p_documento)


select ai.id, ai."number"
from account_invoice ai
inner join account_journal aj
on ai.journal_id = aj.id
where aj."type" = 'sale' 
and $X{IN,ai.journal_id,p_diario}
order by ai.id desc


select *
from(
select ai.id, ai."number"
from account_invoice ai
inner join account_journal aj
on ai.journal_id = aj.id
where ai."type" = 'out_invoice'
and $X{IN,ai.journal_id,p_diario}
order by ai.id desc) as t limit 50




--REPORTE DE COBROS


select * from (
select pr."name" prestamo, cli.nombre_cliente,
pr.fecha_vencimiento_vigente, 
case 
	when pr.saldo_pendiente < 0 then 0
	when pr.saldo_pendiente >= 0 then pr.saldo_pendiente/pr.interes_seguro_cuota
end factor,
pr.cuota_interes,
pr.cuota_seguro,
pr.cuota_mora,
pr.cuota_interes+pr.cuota_seguro+pr.cuota_mora as CSM,
pr.saldo_pendiente
from partner_loan_details as pr
inner join res_partner as cli
on pr.partner_id = cli.id
where pr.state = 'actual'
and cast(pr.fecha_vencimiento_vigente::text as date) between cast($P{p_fecha_inicial_t}::text as date) and cast($P{p_fecha_final_t}::text as date)
) as da
order by da.factor desc


--PARAMETROS

/*

p_fecha_inicial
p_fecha_final

*/



