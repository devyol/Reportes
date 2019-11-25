select
	ap.id id_pago,
	lo."name" prestamo,
	rp.nombre_cliente as empresa,
		to_char(ap.payment_date,'DD "de "')||
	case
	when to_char(now(), 'MM')::numeric = 1 then 'Enero'
	when to_char(now(), 'MM')::numeric = 2 then 'Febrero'
	when to_char(now(), 'MM')::numeric = 3 then 'Marzo'
	when to_char(now(), 'MM')::numeric = 4 then 'Abril'
	when to_char(now(), 'MM')::numeric = 5 then 'Mayo'
	when to_char(now(), 'MM')::numeric = 6 then 'Junio'
	when to_char(now(), 'MM')::numeric = 7 then 'Julio'
	when to_char(now(), 'MM')::numeric = 8 then 'Agosto'
	when to_char(now(), 'MM')::numeric = 9 then 'Septiembre'
	when to_char(now(), 'MM')::numeric = 10 then 'Octubre'
	when to_char(now(), 'MM')::numeric = 11 then 'Noviembre'
	when to_char(now(), 'MM')::numeric = 12 then 'Diciembre'
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
	and check_number = $P{p_cheque}
