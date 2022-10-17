sELECT * FROM HISTORICO_MOV_CARTERA HMC
WHERE HMC.NUMERO_ASIENTO_BORRADOR=17210 AND HMC.EMPRESA='004'

sELECT * FROM HISTORICO_ASIENTOS HA
WHERE HA.NUMERO_ASIENTO_BORRADOR= 17210 AND EMPRESA= '004'

select 

(CASE HMC.TIPO_MOVIMIENTO WHEN 'CONSR' THEN 'COBROS' WHEN 'CDOCU' THEN 'DOC-ORIG' else 'AGRUP' END) TIPO_OP
DECODE(HMC.TIPO_MOVIMIENTO,'CDOCU','DOC-ORIG','CONSR','COBROS','AGRUP') FLAG

with X as (
SELECT TO_CHAR(HMC.FECHA_ASIENTO,'MM') MES, TO_CHAR(HMC.FECHA_ASIENTO,'YYYY') YEAR, DECODE(HMC.TIPO_MOVIMIENTO,'CDOCU','DOC-ORIG','CONSR','COBROS','AGRUP') FLAG,substr(HMC.DOCUMENTO,1,10) id_doc ,(CASE HMC.DOCUMENTO_VIVO WHEN 'S' THEN 1 WHEN 'N' THEN 2 ELSE 2 END) ID, HMC.NUMERO_ASIENTO_BORRADOR ASIENTO, HMC.FECHA_ASIENTO, hmc.FECHA_MOVIMIENTO,HMC.TIPO_MOVIMIENTO, HMC.DOCUMENTO, HMC.CODIGO_CLIENTE, HMC.FECHA_FACTURA, hmc.fecha_vencimiento, hmc.importe, hmc.importe_cobrado, hmc.importe_Condonado, (HMC.importe_cobrado) + (hmc.importe_Condonado) TOTAL_COBR, (HMC.IMPORTE_IMPAGADO) IMPAG, HMC.IMPORTE_SUSTITUIDO,(HMC.IMPORTE)-(HMC.IMPORTE_SUSTITUIDO) vr_Pendiente_dag,  hmc.IMPORTE_MOV 
FROM HISTORICO_MOV_CARTERA HMC, HISTORICO_ASIENTOS HA
WHERE HMC.NUMERO_ASIENTO_BORRADOR = HA.NUMERO_ASIENTO_BORRADOR AND HMC.FECHA_ASIENTO = HA.fecha_asiento
AND TO_DATE(HA.FECHA_ASIENTO,'DD/MM/YYYY') <= TO_DATE('30/09/2022','DD/MM/YYYY') AND HMC.EMPRESA = '004' and hmc.codigo_cliente='008798' and hmc.documento like ('210/004727')
ORDER BY HMC.DOCUMENTO,HMC.FECHA_FACTURA, HMC.FECHA_ASIENTO
)
select  MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO,  SUM(IMPORTE) vr_orig, 0 vr_cobrado, 0 vr_cond, 0 TOTAL_COBR,0 IMPAG, 0 vr_sust, 0 vr_Pendiente_dag, sum(IMPORTE_MOV) IMPORTE_MOV
from x where FLAG IN ('DOC-ORIG')
group by MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO
union all 
select  MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO,  0 vr_orig, sum(IMPORTE_COBRADO) vr_cobrado, sum(IMPORTE_CONDONADO) vr_cond, sum(TOTAL_COBR) TOTAL_COBR,0 IMPAG, 0 vr_sust, 0 vr_Pendiente_dag, sum(IMPORTE_MOV) IMPORTE_MOV
from x where FLAG IN ('COBROS')
group by MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO
union all
select  MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO,  0 vr_orig, 0 vr_cobrado, 0 vr_cond, 0 TOTAL_COBR,0 IMPAG, sum(importe_sustituido) vr_sust, 0 vr_Pendiente_dag, sum(IMPORTE_MOV) IMPORTE_MOV
from x where FLAG not IN ('DOC-ORIG', 'COBROS')
group by MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO



select FECHA_ASIENTO,FECHA_MOVIMIENTO,TIPO_MOVIMIENTO, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE,FECHA_VENCIMIENTO, ID, ASIENTO, IMPORTE vr_orig,IMPORTE_COBRADO vr_cobrado,IMPORTE_CONDONADO vr_cond,TOTAL_COBR,IMPAG,IMPORTE_SUSTITUIDO vr_sust, vr_Pendiente_dag, IMPORTE_MOV
from x where FLAG='DOC-ORIG'

/**** VERSION 2 DEL MODELO DE DATOS PARA CATERA */
DECODE(HMC.TIPO_MOVIMIENTO,'CDOCU','DOC-ORIG','CONSR','COBROS','AGRUP') FLAG

select MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE,c.nombre, fecha_vencimiento,  sum(vr_orig) vr_orig, sum(vr_cobrado) vr_cobrado, sum(vr_cond) vr_cond, sum(TOTAL_COBR) TOTAL_COBR, sum(IMPAG) IMPAG, sum(vr_sust) vr_sust, sum(vr_Pend_dag) vr_Pend_dag, sum(imp_mov) imp_mov, (SUM(vr_orig)-SUM(TOTAL_COBR)-SUM(vr_sust)) saldo 
from (
SELECT TO_CHAR(HMC.FECHA_ASIENTO,'MM') MES, TO_CHAR(HMC.FECHA_ASIENTO,'YYYY') YEAR, substr(HMC.DOCUMENTO,1,10) id_doc ,HMC.DOCUMENTO_VIVO, HMC.NUMERO_ASIENTO_BORRADOR ASIENTO, HMC.FECHA_ASIENTO, hmc.FECHA_MOVIMIENTO, HMC.TIPO_MOVIMIENTO, HMC.DOCUMENTO, HMC.CODIGO_CLIENTE, HMC.FECHA_FACTURA, hmc.fecha_vencimiento, hmc.importe vr_orig, 0 vr_cobrado, 0 vr_cond, 0 TOTAL_COBR, 0 IMPAG, 0 vr_sust, HMC.IMPORTE vr_Pend_dag, hmc.IMPORTE_MOV imp_mov 
FROM HISTORICO_MOV_CARTERA HMC, HISTORICO_ASIENTOS HA
WHERE HMC.NUMERO_ASIENTO_BORRADOR = HA.NUMERO_ASIENTO_BORRADOR AND HMC.FECHA_ASIENTO = HA.fecha_asiento and HMC.EMPRESA = '004' and hmc.TIPO_MOVIMIENTO = 'CDOCU' 
union all 
SELECT TO_CHAR(HMC.FECHA_ASIENTO,'MM') MES, TO_CHAR(HMC.FECHA_ASIENTO,'YYYY') YEAR, substr(HMC.DOCUMENTO,1,10) id_doc ,HMC.DOCUMENTO_VIVO, HMC.NUMERO_ASIENTO_BORRADOR ASIENTO, HMC.FECHA_ASIENTO, hmc.FECHA_MOVIMIENTO,HMC.TIPO_MOVIMIENTO, HMC.DOCUMENTO, HMC.CODIGO_CLIENTE, HMC.FECHA_FACTURA, hmc.fecha_vencimiento, 0 vr_orig, hmc.importe_cobrado vr_cobrado, hmc.importe_Condonado vr_cond, (HMC.importe_cobrado +hmc.importe_Condonado) TOTAL_COBR, 0  IMPAG, 0 vr_sust, 0 vr_Pend_dag, hmc.IMPORTE_MOV imp_mov 
FROM HISTORICO_MOV_CARTERA HMC, HISTORICO_ASIENTOS HA
WHERE HMC.NUMERO_ASIENTO_BORRADOR = HA.NUMERO_ASIENTO_BORRADOR AND HMC.FECHA_ASIENTO = HA.fecha_asiento and HMC.EMPRESA = '004' and hmc.TIPO_MOVIMIENTO ='CONSR' 
union all 
SELECT TO_CHAR(HMC.FECHA_ASIENTO,'MM') MES, TO_CHAR(HMC.FECHA_ASIENTO,'YYYY') YEAR, substr(HMC.DOCUMENTO,1,10) id_doc ,HMC.DOCUMENTO_VIVO, HMC.NUMERO_ASIENTO_BORRADOR ASIENTO, HMC.FECHA_ASIENTO, hmc.FECHA_MOVIMIENTO,HMC.TIPO_MOVIMIENTO, HMC.DOCUMENTO, HMC.CODIGO_CLIENTE, HMC.FECHA_FACTURA, hmc.fecha_vencimiento, 0 vr_orig, 0 vr_cobrado, 0 vr_cond, 0 TOTAL_COBR,0 IMPAG, HMC.IMPORTE_SUSTITUIDO vr_sust, (HMC.IMPORTE-HMC.IMPORTE_SUSTITUIDO) vr_Pend_dag, hmc.IMPORTE_MOV imp_mov 
FROM HISTORICO_MOV_CARTERA HMC, HISTORICO_ASIENTOS HA
WHERE HMC.NUMERO_ASIENTO_BORRADOR = HA.NUMERO_ASIENTO_BORRADOR AND HMC.FECHA_ASIENTO = HA.fecha_asiento and HMC.EMPRESA = '004' and hmc.TIPO_MOVIMIENTO not in ('CONSR','CDOCU') ) d, clientes c
WHERE d.codigo_cliente= c.codigo_rapido and c.codigo_empresa='004' and 
TO_DATE(FECHA_ASIENTO,'DD/MM/YYYY') <= TO_DATE('30/09/2022','DD/MM/YYYY') and codigo_cliente='008798' and documento like ('210/004727')
group by MES, YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE,c.nombre, fecha_vencimiento
ORDER BY d.id_DOC, d.FECHA_FACTURA, d.CODIGO_CLIENTE,c.nombre, d.fecha_vencimiento

--- agrupaciones 
select  MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO,  SUM(IMPORTE) vr_orig, 0 vr_cobrado, 0 vr_cond, 0 TOTAL_COBR,0 IMPAG, 0 vr_sust, 0 vr_Pendiente_dag, sum(IMPORTE_MOV) IMPORTE_MOV
from x where FLAG IN ('DOC-ORIG')
group by MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO
union all 
select  MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO,  0 vr_orig, sum(IMPORTE_COBRADO) vr_cobrado, sum(IMPORTE_CONDONADO) vr_cond, sum(TOTAL_COBR) TOTAL_COBR,0 IMPAG, 0 vr_sust, 0 vr_Pendiente_dag, sum(IMPORTE_MOV) IMPORTE_MOV
from x where FLAG IN ('COBROS')
group by MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO
union all
select  MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO,  0 vr_orig, 0 vr_cobrado, 0 vr_cond, 0 TOTAL_COBR,0 IMPAG, sum(importe_sustituido) vr_sust, 0 vr_Pendiente_dag, sum(IMPORTE_MOV) IMPORTE_MOV
from x where FLAG not IN ('DOC-ORIG', 'COBROS')
group by MES,YEAR, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE, FECHA_VENCIMIENTO


/**** select inicial para el conjunto*/
select FECHA_ASIENTO,FECHA_MOVIMIENTO,TIPO_MOVIMIENTO, id_DOC, FECHA_FACTURA, CODIGO_CLIENTE,FECHA_VENCIMIENTO, ASIENTO


/** codigo para extraer datos */

/**CAPTURA DE DATOS DE COBROS REALIZADOS**/   
select  sum(hmc.importe) VR_ORI, 
                sum(hmc.importe_Condonado) VR_COND,
                sum(HMC.importe_sustituido) VR_SUST, sum(HMC.importe_cobrado) EFECTIVO,
                sum(HMC.importe_cobrado) + SUM(hmc.importe_Condonado) TOTAL_COBR,
                    SUM(HMC.IMPORTE_IMPAGADO)IMPAG, 
                SUM(HMC.DIFERENCIAS_CAMBIO) DIF_CAM
    into vr_ori, vr_cond,vr_sust , vr_efectivo, vr_total, vr_impag, vr_dif_cam
                    
    from historico_mov_cartera hmc, historico_cobros hc
    where   hmc.empresa = hc.empresa and hmc.documento = hc.documento  
                and hmc.fecha_factura= hc.fecha_factura and hmc.fecha_vencimiento=hc.fecha_vencimiento and 
                hmc.tipo_transaccion= hc.tipo_transaccion and
                hmc.empresa=P_EMPRESA AND HMC.CODIGO_CLIENTE=CL.CODIGO_RAPIDO AND hc.CARACTER_ASIENTO = si.c_conta
                and  TO_CHAR(HMC.FECHA_ASIENTO,'YYYY')  = TO_CHAR(to_date(P_FECHAF),'YYYY') 
                and hmc.fecha_asiento between p_fechai +1 and p_fechaf 
                and hc.codigo_cuenta =si.cuenta
                
    GROUP BY HMC.EMPRESA, HC.CARACTER_ASIENTO, HMC.CODIGO_CLIENTE,TO_CHAR(HMC.FECHA_ASIENTO,'YYYY')    ;
                                    
/***CAPTURA DE VALOR DE DAGG****/          
select SUM(HMC.IMPORTE), SUM(HMC.IMPORTE_SUSTITUIDO), SUM(HMC.IMPORTE)-SUM(HMC.IMPORTE_SUSTITUIDO)
    into v_imp_dag, v_imp_sust_dag, v_real_dag
    from historico_mov_cartera hmc, historico_cobros hc
    where 
    hmc.empresa = hc.empresa and hmc.documento = hc.documento  
                and hmc.fecha_factura= hc.fecha_factura and hmc.fecha_vencimiento=hc.fecha_vencimiento and 
                hmc.tipo_transaccion= hc.tipo_transaccion and
                hmc.empresa=P_EMPRESA AND HC.CARACTER_ASIENTO=SI.C_CONTA
                --AND HC.SERIE_JUSTIFICANTE NOT LIKE 'N%' AND HC.SERIE_JUSTIFICANTE NOT IN ('PHC','PHD')
                AND HMC.CODIGO_CLIENTE=CL.CODIGO_RAPIDO  AND HMC.TIPO_MOVIMIENTO NOT IN('CONSR','CDOCU')    
                and hc.codigo_cuenta =si.cuenta    
                and hmc.fecha_asiento between p_fechai +1 and p_fechaf;          
                                
               /**BUSQUEDA SALDO FINAL**/ 
select nvl(SUM(IMPORTE)- SUM(IMPORTE_COMPENSADO) -  SUM(IMPORTE_SUSTITUIDO) - SUM(IMPORTE_COBRADO),0) SALDO 
                into vr_saldo_f
                 from AUDITORIA_HC_CAB AC, AUDITORIA_HC_LIN AL, clientes ent
                 WHERE AC.ID_CONSULTA=AL.ID_CONSULTA  and AL.EMPRESA = ent.codigo_empresa
                    and al.codigo_cliente=ent.codigo_rapido
                    AND AL.EMPRESA=p_empresa AND AC.FECHA_FILTRO= P_FECHAF 
                    AND AL.CODIGO_CLIENTE=ENT.CODIGO_RAPIDO AND AL.CARACTER_ASIENTO=si.c_conta
                     AND ENT.CODIGO_RAPIDO=CL.CODIGO_RAPIDO AND AL.CODIGO_CUENTA=si.cuenta;


curl -Lo install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh sh install.sh