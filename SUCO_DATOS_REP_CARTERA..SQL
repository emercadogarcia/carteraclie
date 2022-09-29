-- SUCPROCEDURE O_DATOS_REP_CARTERA
CREATE OR REPLACE PROCEDURE       SUCO_DATOS_REP_CARTERA(P_EMPRESA VARCHAR2,P_FECHAI DATE,P_FECHAF DATE,P_USUARIO VARCHAR2)
IS

    CURSOR CLIENTES IS 
        SELECT CODIGO_RAPIDO, NIF, NOMBRE  FROM CLIENTES CL WHERE 
        EXISTS(SELECT 1 FROM HISTORICO_DETALLADO_APUNTES HD 
        WHERE CL.CODIGO_EMPRESA=HD.EMPRESA AND CL.CODIGO_RAPIDO=HD.CODIGO_ENTIDAD AND HD.ENTIDAD='CL'
        AND HD.EMPRESA= P_EMPRESA);
    CURSOR S_INICIAL (P_CLIENTE VARCHAR2 )IS select  AL.CARACTER_ASIENTO C_CONTA,          
            al.codigo_cuenta CUENTA,
            SUM(IMPORTE) V_ORI,
            SUM(IMPORTE_COMPENSADO) COMP, 
            SUM(IMPORTE_SUSTITUIDO) SUST, 
            SUM(IMPORTE_ENDOSADO) ENDO,  
            SUM(IMPORTE_DESCUENTO_PRONTO_PAGO)D_PPAGO,
            SUM(IMPORTE_RECARGO_FINANCIERO) R_FIN,
            SUM(IMPORTE_COBRADO) ABONOS, 
            SUM(IMPORTE)- SUM(IMPORTE_COMPENSADO) -  SUM(IMPORTE_SUSTITUIDO) - SUM(IMPORTE_COBRADO) SALDO 
         from AUDITORIA_HC_CAB AC, AUDITORIA_HC_LIN AL, clientes ent
         WHERE AC.ID_CONSULTA=AL.ID_CONSULTA  and AL.EMPRESA = ent.codigo_empresa
            and al.codigo_cliente=ent.codigo_rapido
            AND AL.EMPRESA=P_EMPRESA AND AC.FECHA_FILTRO= P_FECHAI AND AL.CODIGO_CLIENTE=ENT.CODIGO_RAPIDO 
            AND AL.CODIGO_CLIENTE= P_CLIENTE AND AL.EMPRESA=P_EMPRESA --AND ENT.CODIGO_RAPIDO='000272'
            
            and al.caracter_asiento='0101'

            GROUP BY al.empresa, AL.CARACTER_ASIENTO, AC.ID_CONSULTA, to_char(Ac.FECHA_FILTRO,'YYYY'),ac.fecha_filtro, 
            al.codigo_cuenta, al.codigo_cliente, ent.codigo_rapido;
    
        CURSOR FACTURAS_NOTAS (P_CLIENTE VARCHAR2, P_CCONTA VARCHAR2) IS select  fv.numero_serie, sum(fv.imp_fac_bruto) bruto, 
                sum(fv.importe_fac_neto) neto, 
                sum(fv.liquido_factura) liq, 
                sum(fv.imp_fac_dto1) dto1,
                sum(fv.imp_fac_dto2) dto2,
                sum(fv.coste_bruto) costo,
                sum((select max(base)  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje >0)) b_iva_vr,
                sum((select sum(importe)  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje >0)) vr_iva,
                sum((select max(base)  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje =0)) b_iva_0,
                sum((select max(base)  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto not like 'I%' 
                and porcentaje >0)) b_rets,
                sum((select sum(importe)  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto not like 'I%' 
                and porcentaje >0)) vr_rets
            from facturas_ventas fv
            where fv.empresa=P_EMPRESA and
                fv.ejercicio =TO_CHAR(P_FECHAF,'YYYY') AND FECHA_FACTURA <=P_FECHAF
                AND cliente=P_CLIENTE AND (fv.numero_serie LIKE 'N%' OR fv.numero_serie  IN ('PHC', 'PHD'))
                AND fv.centro_Contable = P_CCONTA
                --numero_asiento_borrador
                group by fv.centro_Contable, fv.numero_serie, fv.empresa, fv.ejercicio;
                
                
 V_CTRL VARCHAR2(2);
 v_serie varchar2(10);
 vr_bruto numeric(18,2);
 vr_neto numeric(18,2);
 vr_liq numeric(18,2);
 vr_dcto1 numeric(18,2);
 vr_dcto2 numeric(18,2);
 vr_costo numeric(18,2);
 vr_gravado numeric(18,2);
 vr_iva numeric(18,2);
 vr_no_grav numeric(18,2);
 vr_total_base numeric(18,2);
 vr_rets numeric(18,2);
 vr_saldo_f numeric(18,2);
 vr_dif_saldo numeric(18,2);
 
 v_serie_n varchar2(10);
 vr_bruto_n numeric(18,2);
 vr_neto_n numeric(18,2);
 vr_liq_n numeric(18,2);
 vr_dcto1_n numeric(18,2);
 vr_dcto2_n numeric(18,2);
 vr_costo_n numeric(18,2);
 vr_gravado_n numeric(18,2);
 vr_iva_n numeric(18,2);
 vr_no_grav_n numeric(18,2);
 vr_total_base_n numeric(18,2);
 vr_rets_n numeric(18,2);
 
 vr_ori numeric(18,2);
 vr_cob numeric(18,2);
 vr_sust numeric(18,2);
 vr_impag numeric(18,2);
 vr_cond numeric(18,2);
 vr_efectivo numeric(18,2);
 vr_total numeric(18,2);
 vr_dif_cam numeric(18,2);
 
 v_imp_dag numeric(18,2);
 v_imp_sust_dag numeric(18,2);
 v_real_dag numeric(18,2);
 
 vr_difer numeric(18,2);
 

BEGIN

DELETE FROM SUCO_TMP_CARTERA_CONS_ENT WHERE EMPRESA=P_EMPRESA AND F_INICIAL = P_FECHAI AND F_CORTE_FIN=P_FECHAF;
COMMIT;
FOR CL IN CLIENTES LOOP
        
            FOR SI IN S_INICIAL(CL.CODIGO_RAPIDO) LOOP
            
            /***LLAMADO DE FACTURACION */
            select nvl( fv.numero_serie,'.'), nvl(sum(fv.imp_fac_bruto),0) bruto, 
                nvl(sum(fv.importe_fac_neto),0) neto,              nvl(sum(fv.liquido_factura),0) liq, 
                nvl(sum(fv.imp_fac_dto1),0) dto1,                nvl(sum(fv.imp_fac_dto2),0) dto2,
                nvl(sum(fv.coste_bruto),0) costo,               
                (sum((select max(nvl(base,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje >0)) )b_iva_vr,
                sum((select sum(nvl(importe,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje >0)) vr_iva,
                sum((select max(nvl(base,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje =0)) b_iva_0,
                sum((select max(nvl(base,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto not like 'I%' 
                and porcentaje >0)) b_rets,
                sum((select sum(nvl(importe,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto not like 'I%' 
                and porcentaje >0)) vr_rets
             into v_serie , vr_bruto, vr_neto , vr_liq , vr_dcto1 , vr_dcto2 , vr_costo , vr_gravado , vr_iva,
                vr_no_grav , vr_total_base , vr_rets
            from facturas_ventas fv
            where fv.empresa=P_EMPRESA and
                fv.ejercicio =TO_CHAR(P_FECHAF,'YYYY') AND FECHA_FACTURA <=P_FECHAF
                AND cliente=CL.CODIGO_RAPIDO AND fv.numero_serie NOT LIKE 'N%' AND fv.numero_serie NOT IN ('PHC', 'PHD')
                AND fv.centro_Contable = SI.C_CONTA
                --numero_asiento_borrador
                group by fv.centro_Contable, fv.numero_serie, fv.empresa, fv.ejercicio;
                /*CIERRE LLAMADO FACTURAS***/
            
            /***/
            select  max(nvl(fv.numero_serie,'.')), sum(nvl(fv.imp_fac_bruto,0)) bruto, 
                sum(nvl(fv.importe_fac_neto,0)) neto, 
                sum(nvl(fv.liquido_factura,0)) liq, 
                sum(nvl(fv.imp_fac_dto1,0)) dto1,
                sum(nvl(fv.imp_fac_dto2,0)) dto2,
                sum(nvl(fv.coste_bruto,0)) costo,
                sum((select max(nvl(base,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje >0)) b_iva_vr,
                sum((select sum(nvl(importe,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje >0)) vr_iva,
                sum((select max(nvl(base,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto like 'I%' 
                and porcentaje =0)) b_iva_0,
                sum((select max(nvl(base,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto not like 'I%' 
                and porcentaje >0)) b_rets,
                sum((select sum(nvl(importe,0))  from facturas_ventas_impuestos fvi where fvi.empresa= fv.empresa 
                and fvi.numero_serie=FV.NUMERO_SERIE and fvi.numero_factura=fv.numero_factura and fvi.impuesto not like 'I%' 
                and porcentaje >0)) vr_rets
                into v_serie_n , vr_bruto_n, vr_neto_n , vr_liq_n , vr_dcto1_n , vr_dcto2_n , vr_costo_n , vr_gravado_n , vr_iva_n,
                vr_no_grav_n , vr_total_base_n , vr_rets_n
            from facturas_ventas fv
            where fv.empresa=P_EMPRESA and
                fv.ejercicio =TO_CHAR(P_FECHAF,'YYYY') AND FECHA_FACTURA <=P_FECHAF
                AND cliente=CL.CODIGO_RAPIDO  AND (fv.numero_serie LIKE 'N%' OR fv.numero_serie  IN ('PHC', 'PHD'))
                AND fv.centro_Contable = SI.C_CONTA
                --numero_asiento_borrador
                group by fv.centro_Contable,  fv.empresa, fv.ejercicio;
                /***/
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
               select        
                
                nvl(SUM(IMPORTE)- SUM(IMPORTE_COMPENSADO) -  SUM(IMPORTE_SUSTITUIDO) - SUM(IMPORTE_COBRADO),0) SALDO 
                into vr_saldo_f
                 from AUDITORIA_HC_CAB AC, AUDITORIA_HC_LIN AL, clientes ent
                 WHERE AC.ID_CONSULTA=AL.ID_CONSULTA  and AL.EMPRESA = ent.codigo_empresa
                    and al.codigo_cliente=ent.codigo_rapido
                    AND AL.EMPRESA=p_empresa AND AC.FECHA_FILTRO= P_FECHAF 
                    AND AL.CODIGO_CLIENTE=ENT.CODIGO_RAPIDO AND AL.CARACTER_ASIENTO=si.c_conta
                     AND ENT.CODIGO_RAPIDO=CL.CODIGO_RAPIDO AND AL.CODIGO_CUENTA=si.cuenta;

                vr_difer := 0;    
               IF SI.CUENTA LIKE '13%' THEN
                    vr_difer := vr_saldo_f -(si.saldo + vr_liq - (vr_total - vr_sust));
            
                    INSERT INTO SUCO_TMP_CARTERA_CONS_ENT (
                       EMPRESA, C_CONTABLE, CUENTA,D_CENTRO, 
                       C_CLIENTE, F_INICIAL, SALDO_INI, 
                       SERIE_FAC, MOV_FACTURAS, FACT_GRAVADA, FACT_NOGRAV, 
                       FACT_DCTOS, FACT_RETEN, fact_liquida,mov_cr_adic, MOV_COBROS, 
                       MOV_COBROS_TOT, MOV_COBROS_COND, MOV_COBROS_SUST, MOV_COBROS_REAL,NOTAS_CR, 
                       NOTAS_DEB, OTROS_MOV, PART_AJUST,VR_SALDO_FIN,VR_DIF_SALDO, F_CORTE_FIN) 
                    VALUES ( P_EMPRESA,
                     SI.C_CONTA,SI.CUENTA,
                     ' ',
                     CL.CODIGO_RAPIDO,
                     P_FECHAI,
                     SI.SALDO,
                     V_SERIE,
                     VR_liq,
                     VR_GRAVADO,
                     VR_NO_grav,
                     VR_BRUTO - VR_LIQ,
                     VR_RETS,
                     VR_GRAVADO + VR_NO_GRAV,
                     v_imp_sust_dag,
                     vr_efectivo,
                     vr_total,
                     vr_cond,
                     vr_sust,
                     vr_total - vr_sust + vr_difer,
                     vr_bruto_n,
                     0,
                     0,
                     0,
                     vr_saldo_f,
                      vr_difer,
                     P_FECHAF );
                     ELSE
                     INSERT INTO SUCO_TMP_CARTERA_CONS_ENT (
                       EMPRESA, C_CONTABLE, CUENTA,D_CENTRO, 
                       C_CLIENTE, F_INICIAL, SALDO_INI, 
                       SERIE_FAC, MOV_FACTURAS, FACT_GRAVADA, FACT_NOGRAV, 
                       FACT_DCTOS, FACT_RETEN, MOV_COBROS, 
                       MOV_COBROS_TOT, MOV_COBROS_COND, NOTAS_CR, 
                       NOTAS_DEB, OTROS_MOV, F_CORTE_FIN) 
                    VALUES ( P_EMPRESA,
                     SI.C_CONTA,SI.CUENTA,
                     ' ',
                     CL.CODIGO_RAPIDO,
                     P_FECHAI,
                     SI.SALDO,
                     ' ',
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     0,
                     P_FECHAF );
                     END IF;                 
            
            END LOOP;
            

END LOOP;
COMMIT;
END;
