page 50131 "Panel Gerencia Paradas Bus"
{
    ApplicationArea = All;
    Caption = 'Panel gerencia Paradas Bus';
    PageType = Card;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filtros';

                field(ZonaLimpiezaFiltro; FiltroZonaLimpieza)
                {
                    ApplicationArea = All;
                    Caption = 'Zona limpieza';
                    TableRelation = "Zonas Limpieza".Id;
                    ToolTip = 'Vacío = todas las zonas.';

                    trigger OnValidate()
                    begin
                        CalculateDashboard();
                    end;
                }
                field(ZonaRevisionFiltro; FiltroZonaRevision)
                {
                    ApplicationArea = All;
                    Caption = 'Zona revisión';
                    TableRelation = "Zonas Limpieza".Id;
                    ToolTip = 'Vacío = todas las zonas.';

                    trigger OnValidate()
                    begin
                        CalculateDashboard();
                    end;
                }
                field(EstadoTipFiltro; FiltroEstadoTip)
                {
                    ApplicationArea = All;
                    Caption = 'Estado TIP';
                    ToolTip = 'Filtro BC sobre estado TIP, por ejemplo Activa|Baja.';

                    trigger OnValidate()
                    begin
                        CalculateDashboard();
                    end;
                }
            }

            usercontrol(Dashboard; "Paradas Bus Dashboard AddIn")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    DashboardReady := true;
                    SendDashboard();
                end;

                trigger ShowParadas()
                begin
                    OpenParadasFiltradas();
                end;

                trigger ShowPalos()
                begin
                    OpenParadasPorFamilia(true);
                end;

                trigger ShowMarquesinas()
                begin
                    OpenParadasPorFamilia(false);
                end;

                trigger ShowIncidencias()
                begin
                    OpenIncidencias(false);
                end;

                trigger ShowOrdenesTrabajo()
                begin
                    OpenIncidencias(true);
                end;

                trigger ShowIncidenciasEnProgreso()
                begin
                    OpenIncidenciasEnProgreso();
                end;

                trigger ShowLimpiezaFinalizadas()
                begin
                    OpenTareas('LIMPIEZA', 'FIN');
                end;

                trigger ShowLimpiezaPendientes()
                begin
                    OpenTareas('LIMPIEZA', 'PEN');
                end;

                trigger ShowLimpiezaVencidas()
                begin
                    OpenTareas('LIMPIEZA', 'VEN');
                end;

                trigger ShowRevisionFinalizadas()
                begin
                    OpenTareas('REVISION', 'FIN');
                end;

                trigger ShowRevisionPendientes()
                begin
                    OpenTareas('REVISION', 'PEN');
                end;

                trigger ShowRevisionVencidas()
                begin
                    OpenTareas('REVISION', 'VEN');
                end;

                trigger ShowMantenimientoVencido()
                begin
                    OpenMantenimientos(true);
                end;

                trigger ShowMantenimientoProgramado()
                begin
                    OpenMantenimientos(false);
                end;

                trigger ShowOrdenesTrabajoAprobadas()
                begin
                    OpenOrdenesTrabajoAprobadas();
                end;

                trigger ShowOrdenesTrabajoPendientes()
                begin
                    OpenOrdenesTrabajoPendientes();
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshDashboard)
            {
                ApplicationArea = All;
                Caption = 'Actualizar';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    CalculateDashboard();
                    SendDashboard();
                end;
            }
            action(OpenParadas)
            {
                ApplicationArea = All;
                Caption = 'Ver paradas';
                Image = List;

                trigger OnAction()
                begin
                    OpenParadasFiltradas();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CalculateDashboard();
    end;

    local procedure CalculateDashboard()
    var
        Emplaz: Record Emplazamientos;
        Inc: Record Incidencias;
        TipoTxt: Text;
        TiposCount: Dictionary of [Text, Integer];
    begin
        Clear(TotalParadas);
        Clear(ParadasPalos);
        Clear(ParadasMarquesinas);
        Clear(IncidenciasAbiertas);
        Clear(OrdenesTrabajoAbiertas);
        Clear(IncidenciasEnProgreso);
        Clear(LimpFinalizadas);
        Clear(LimpPendientes);
        Clear(LimpVencidas);
        Clear(RevFinalizadas);
        Clear(RevPendientes);
        Clear(RevVencidas);
        Clear(MantProgramado30d);
        Clear(MantVencido);
        Clear(OrdenesTrabajoAprobadas);
        Clear(OrdenesTrabajoPendientes);
        ConstruirFiltroParadas();
        BuildPeriodText();

        ContarParadasPorFamilia();

        IncidenciasAbiertas := ContarIncidencias(false);
        OrdenesTrabajoAbiertas := ContarIncidencias(true);
        IncidenciasEnProgreso := ContarIncidenciasEnProgreso();

        LimpFinalizadas := ContarTareas('LIMPIEZA', 'FIN');
        LimpPendientes := ContarTareas('LIMPIEZA', 'PEN');
        LimpVencidas := ContarTareas('LIMPIEZA', 'VEN');
        RevFinalizadas := ContarTareas('REVISION', 'FIN');
        RevPendientes := ContarTareas('REVISION', 'PEN');
        RevVencidas := ContarTareas('REVISION', 'VEN');

        AplicarFiltroEmplazamientos(Emplaz);
        Emplaz.SetFilter("Fecha Próximo Mantenimiento", '%1..%2', WorkDate() + 1, CalcDate('<+30D>', WorkDate()));
        MantProgramado30d := Emplaz.Count();

        AplicarFiltroEmplazamientos(Emplaz);
        Emplaz.SetFilter("Fecha Próximo Mantenimiento", '<>%1&<=%2', 0D, WorkDate());
        MantVencido := Emplaz.Count();

        OrdenesTrabajoPendientes := ContarOrdenesTrabajoPendientes();
        OrdenesTrabajoAprobadas := ContarOrdenesTrabajoAprobadas();
        ContarObjetivosVsRealizadas();

        FiltroParadasTmp.Reset();
        if FiltroParadasTmp.FindSet() then
            repeat
                TipoTxt := FiltroParadasTmp.Value;
                if TipoTxt = '' then
                    TipoTxt := 'Sin tipo';
                if TiposCount.ContainsKey(TipoTxt) then
                    TiposCount.Set(TipoTxt, TiposCount.Get(TipoTxt) + 1)
                else
                    TiposCount.Add(TipoTxt, 1);
            until FiltroParadasTmp.Next() = 0;

        foreach TipoTxt in TiposCount.Keys() do
            UpdateTopTipo(TipoTxt, TiposCount.Get(TipoTxt));

        BuildDashboardPayload();
        SendDashboard();
    end;

    local procedure BuildPeriodText()
    var
        ZonaLimp: Record "Zonas Limpieza";
        ZonaRev: Record "Zonas Limpieza";
    begin
        PeriodText := 'Todas las paradas bus';
        if FiltroZonaLimpieza <> 0 then begin
            if ZonaLimp.Get(FiltroZonaLimpieza) then
                PeriodText := 'Zona limpieza: ' + ZonaLimp.Descripción;
        end;
        if FiltroZonaRevision <> 0 then begin
            if ZonaRev.Get(FiltroZonaRevision) then
                if PeriodText = 'Todas las paradas bus' then
                    PeriodText := 'Zona revisión: ' + ZonaRev.Descripción
                else
                    PeriodText += ' · Rev: ' + ZonaRev.Descripción;
        end;
        if FiltroEstadoTip <> '' then
            PeriodText += ' · TIP: ' + FiltroEstadoTip;
    end;

    local procedure ConstruirFiltroParadas()
    var
        Emplaz: Record Emplazamientos;
        Idx: Integer;
    begin
        FiltroParadasTmp.Reset();
        FiltroParadasTmp.DeleteAll();
        AplicarFiltroEmplazamientos(Emplaz);
        Idx := 0;
        if Emplaz.FindSet() then
            repeat
                Idx += 1;
                FiltroParadasTmp.Init();
                FiltroParadasTmp.ID := Idx;
                FiltroParadasTmp.Name := Emplaz."Nº Emplazamiento";
                FiltroParadasTmp.Value := Format(Emplaz."Tipo Parada");
                FiltroParadasTmp.Insert();
            until Emplaz.Next() = 0;
    end;

    local procedure AplicarFiltroEmplazamientos(var Emplaz: Record Emplazamientos)
    begin
        Emplaz.Reset();
        Emplaz.SetRange("Tipo Emplazamiento", Emplaz."Tipo Emplazamiento"::Opis);
        if FiltroZonaLimpieza <> 0 then
            Emplaz.SetRange("Zona Limpieza", FiltroZonaLimpieza);
        if FiltroZonaRevision <> 0 then
            Emplaz.SetRange("Zona Revisión", FiltroZonaRevision);
        if FiltroEstadoTip <> '' then
            Emplaz.SetFilter("Estado Parada", FiltroEstadoTip);
    end;

    local procedure ContarIncidencias(SoloPeticiones: Boolean): Integer
    var
        Inc: Record Incidencias;
    begin
        Inc.Reset();
        Inc.SetRange("Tipo Elemento", Inc."Tipo Elemento"::Parada);
        Inc.SetRange("Es Peticion", SoloPeticiones);
        Inc.SetFilter(Estado, '<>%1&<>%2', Inc.Estado::Cerrada, Inc.Estado::Facturada);
        AplicarFiltroIncidenciasPorParada(Inc);
        exit(Inc.Count());
    end;

    local procedure ContarIncidenciasEnProgreso(): Integer
    var
        Inc: Record Incidencias;
    begin
        Inc.Reset();
        Inc.SetRange("Tipo Elemento", Inc."Tipo Elemento"::Parada);
        Inc.SetRange("Es Peticion", false);
        Inc.SetRange(Estado, Inc.Estado::EnProgreso);
        AplicarFiltroIncidenciasPorParada(Inc);
        exit(Inc.Count());
    end;

    local procedure AplicarFiltroIncidenciasPorParada(var Inc: Record Incidencias)
    var
        FiltroTxt: Text;
    begin
        // Recurso en paradas = Nº emplazamiento (parada bus), no recurso BC.
        FiltroParadasTmp.Reset();
        if FiltroParadasTmp.FindSet() then
            repeat
                if FiltroTxt <> '' then
                    FiltroTxt += '|';
                FiltroTxt += FiltroParadasTmp.Name;
            until FiltroParadasTmp.Next() = 0;
        if FiltroTxt = '' then
            FiltroTxt := '##NOMATCH##';
        Inc.SetFilter(Recurso, FiltroTxt);
    end;

    local procedure ContarTareas(TipoTarea: Text; Modo: Text): Integer
    var
        UserTask: Record "User Task";
        Emplaz: Record Emplazamientos;
        NEmplaz: Code[20];
        Contador: Integer;
    begin
        UserTask.SetRange("Object ID", Page::"Ficha Parada Bus");
        UserTask.SetRange(TipoTarea, TipoTarea);
        case Modo of
            'FIN':
                UserTask.SetRange(Estado, UserTask.Estado::Finalizado);
            'PEN':
                begin
                    UserTask.SetFilter(Estado, '%1|%2', UserTask.Estado::Pendiente, UserTask.Estado::"En Proceso");
                    UserTask.SetFilter("Due DateTime", '>=%1', CurrentDateTime);
                end;
            'VEN':
                begin
                    UserTask.SetFilter(Estado, '%1|%2', UserTask.Estado::Pendiente, UserTask.Estado::"En Proceso");
                    UserTask.SetFilter("Due DateTime", '<%1', CurrentDateTime);
                end;
        end;
        if UserTask.FindSet() then
            repeat
                NEmplaz := ObtenerEmplazamientoDeTarea(UserTask);
                if NEmplaz = '' then
                    continue;
                if not EstaParadaEnFiltro(NEmplaz) then
                    continue;
                if Emplaz.Get(Emplaz."Tipo Emplazamiento"::Opis, NEmplaz) then
                    Contador += 1;
            until UserTask.Next() = 0;
        exit(Contador);
    end;

    local procedure ObtenerEmplazamientoDeTarea(UserTask: Record "User Task"): Code[20]
    var
        Emplaz: Record Emplazamientos;
    begin
        if UserTask.Id_record.TableNo <> Database::Emplazamientos then
            exit('');
        if not Emplaz.Get(UserTask.Id_record) then
            exit('');
        exit(Emplaz."Nº Emplazamiento");
    end;

    local procedure EstaParadaEnFiltro(NEmplaz: Code[20]): Boolean
    begin
        FiltroParadasTmp.Reset();
        FiltroParadasTmp.SetRange(Name, NEmplaz);
        exit(FiltroParadasTmp.FindFirst());
    end;

    local procedure ContarOrdenesTrabajoPendientes(): Integer
    begin
        exit(ContarOrdenesTrabajoPorEstado('PEN'));
    end;

    local procedure ContarOrdenesTrabajoAprobadas(): Integer
    begin
        exit(ContarOrdenesTrabajoPorEstado('APR'));
    end;

    local procedure ContarOrdenesTrabajoPorEstado(Modo: Code[3]): Integer
    var
        Inc: Record Incidencias;
    begin
        Inc.Reset();
        Inc.SetRange("Tipo Elemento", Inc."Tipo Elemento"::Parada);
        Inc.SetRange("Es Peticion", true);
        case Modo of
            'PEN':
                Inc.SetFilter(Estado, '%1|%2', Inc.Estado::Abierta, Inc.Estado::EnProgreso);
            'APR':
                Inc.SetRange(Estado, Inc.Estado::"Presupuesto Aprobado");
        end;
        AplicarFiltroIncidenciasPorParada(Inc);
        exit(Inc.Count());
    end;

    local procedure AplicarFiltroOrdenesTrabajo(var Inc: Record Incidencias; Modo: Code[3])
    begin
        Inc.Reset();
        Inc.SetRange("Tipo Elemento", Inc."Tipo Elemento"::Parada);
        Inc.SetRange("Es Peticion", true);
        case Modo of
            'PEN':
                Inc.SetFilter(Estado, '%1|%2', Inc.Estado::Abierta, Inc.Estado::EnProgreso);
            'APR':
                Inc.SetRange(Estado, Inc.Estado::"Presupuesto Aprobado");
        end;
        AplicarFiltroIncidenciasPorParada(Inc);
    end;

    local procedure UpdateTopTipo(TipoTxt: Text; Cantidad: Integer)
    var
        Index: Integer;
        MoveIndex: Integer;
    begin
        for Index := 1 to ArrayLen(TopTipoLabel) do
            if (TopTipoLabel[Index] = '') or (Cantidad > TopTipoValue[Index]) then begin
                for MoveIndex := ArrayLen(TopTipoValue) downto Index + 1 do begin
                    TopTipoValue[MoveIndex] := TopTipoValue[MoveIndex - 1];
                    TopTipoLabel[MoveIndex] := TopTipoLabel[MoveIndex - 1];
                end;
                TopTipoValue[Index] := Cantidad;
                TopTipoLabel[Index] := CopyStr(TipoTxt, 1, MaxStrLen(TopTipoLabel[Index]));
                exit;
            end;
    end;

    local procedure BuildDashboardPayload()
    var
        Root: JsonObject;
        Summary: JsonObject;
        Limpieza: JsonObject;
        Revision: JsonObject;
        Incidencias: JsonObject;
        Maintenance: JsonObject;
        TaskHealth: JsonObject;
        TopTipos: JsonArray;
    begin
        Summary.Add('totalParadas', TotalParadas);
        Summary.Add('palos', ParadasPalos);
        Summary.Add('marquesinas', ParadasMarquesinas);
        Summary.Add('incidencias', IncidenciasAbiertas);
        Summary.Add('ordenes', OrdenesTrabajoAbiertas);
        Root.Add('summary', Summary);

        Limpieza.Add('fin', LimpFinalizadas);
        Limpieza.Add('pen', LimpPendientes);
        Limpieza.Add('ven', LimpVencidas);
        Root.Add('limpieza', Limpieza);

        Revision.Add('fin', RevFinalizadas);
        Revision.Add('pen', RevPendientes);
        Revision.Add('ven', RevVencidas);
        Root.Add('revision', Revision);

        Incidencias.Add('taller', IncidenciasAbiertas);
        Incidencias.Add('ordenes', OrdenesTrabajoAbiertas);
        Incidencias.Add('progreso', IncidenciasEnProgreso);
        Root.Add('incidencias', Incidencias);

        TaskHealth.Add('fin', LimpFinalizadas + RevFinalizadas);
        TaskHealth.Add('pen', LimpPendientes + RevPendientes);
        TaskHealth.Add('ven', LimpVencidas + RevVencidas);
        Root.Add('taskHealth', TaskHealth);

        Maintenance.Add('programado', MantProgramado30d);
        Maintenance.Add('vencido', MantVencido);
        Maintenance.Add('aprobadas', OrdenesTrabajoAprobadas);
        Maintenance.Add('pendientes', OrdenesTrabajoPendientes);
        Root.Add('maintenance', Maintenance);

        BuildTipoArray(TopTipos);
        Root.Add('topTipos', TopTipos);
        Root.Add('objetivos', BuildObjetivosArray());
        Root.Add('objetivoPeriodo', ObjetivoPeriodoText);
        Root.Add('period', PeriodText);

        Root.WriteTo(DashboardPayload);
    end;

    local procedure ContarObjetivosVsRealizadas()
    var
        Emplaz: Record Emplazamientos;
        Hechas: Dictionary of [Text, Integer];
        InicioSemana: Date;
        FinSemana: Date;
        InicioMes: Date;
        FinMes: Date;
        Tipo: Integer;
        Veces: Integer;
        Periodo: Integer;
        Realizadas: Integer;
    begin
        Clear(ObjHechas);
        Clear(ObjMeta);
        Clear(ObjParadas);
        Clear(ObjCumplen);
        InicioSemana := WorkDate() - (Date2DWY(WorkDate(), 3) - 1);
        FinSemana := InicioSemana + 6;
        InicioMes := CalcDate('<-CM>', WorkDate());
        FinMes := CalcDate('<CM>', WorkDate());
        ObjetivoPeriodoText := StrSubstNo('Semana %1–%2 · Mes %3–%4', InicioSemana, FinSemana, InicioMes, FinMes);
        CargarTareasFinalizadas(Hechas, InicioSemana, FinSemana, InicioMes, FinMes);

        FiltroParadasTmp.Reset();
        if FiltroParadasTmp.FindSet() then
            repeat
                if Emplaz.Get(Emplaz."Tipo Emplazamiento"::Opis, FiltroParadasTmp.Name) then
                    for Tipo := 1 to 5 do begin
                        LeerObjetivoParada(Emplaz, Tipo, Veces, Periodo);
                        if (Veces > 0) and (Periodo in [1, 2]) then begin
                            Realizadas := HechasDe(Hechas, Emplaz."Nº Emplazamiento", Tipo, Periodo);
                            ObjParadas[Tipo] += 1;
                            ObjMeta[Tipo] += Veces;
                            ObjHechas[Tipo] += Realizadas;
                            if Realizadas >= Veces then
                                ObjCumplen[Tipo] += 1;
                        end;
                    end;
            until FiltroParadasTmp.Next() = 0;
    end;

    local procedure CargarTareasFinalizadas(var Hechas: Dictionary of [Text, Integer]; InicioSemana: Date; FinSemana: Date; InicioMes: Date; FinMes: Date)
    var
        UserTask: Record "User Task";
        NEmplaz: Code[20];
        Fecha: Date;
        Tipo: Integer;
        Desde: Date;
        Hasta: Date;
    begin
        if InicioSemana < InicioMes then
            Desde := InicioSemana
        else
            Desde := InicioMes;
        if FinSemana > FinMes then
            Hasta := FinSemana
        else
            Hasta := FinMes;

        UserTask.SetRange("Object ID", Page::"Ficha Parada Bus");
        UserTask.SetRange(Estado, UserTask.Estado::Finalizado);
        UserTask.SetRange("Start DateTime", CreateDateTime(Desde, 0T), CreateDateTime(Hasta, 235959T));
        if UserTask.FindSet() then
            repeat
                NEmplaz := ObtenerEmplazamientoDeTarea(UserTask);
                if (NEmplaz = '') or (not EstaParadaEnFiltro(NEmplaz)) then
                    continue;
                Tipo := TipoObjetivoDeTarea(UserTask);
                if Tipo = 0 then
                    continue;
                Fecha := DT2Date(UserTask."Start DateTime");
                if (Fecha >= InicioSemana) and (Fecha <= FinSemana) then
                    SumarHecha(Hechas, NEmplaz, Tipo, 1);
                if (Fecha >= InicioMes) and (Fecha <= FinMes) then
                    SumarHecha(Hechas, NEmplaz, Tipo, 2);
            until UserTask.Next() = 0;
    end;

    local procedure TipoObjetivoDeTarea(UserTask: Record "User Task"): Integer
    begin
        if UserTask."Tipo objetivo" <> UserTask."Tipo objetivo"::" " then
            exit(UserTask."Tipo objetivo");
        case UpperCase(UserTask.TipoTarea) of
            'LIMPIEZA':
                exit(UserTask."Tipo objetivo"::Limpieza);
            'REVISION', 'REVISIÓN':
                exit(UserTask."Tipo objetivo"::"Revisión");
        end;
        exit(0);
    end;

    local procedure LeerObjetivoParada(Emplaz: Record Emplazamientos; Tipo: Integer; var Veces: Integer; var Periodo: Integer)
    begin
        Veces := 0;
        Periodo := 0;
        case Tipo of
            1:
                begin
                    Veces := Emplaz."Veces Limpieza";
                    Periodo := Emplaz."Periodo Limpieza";
                end;
            2:
                begin
                    Veces := Emplaz."Veces Revisión";
                    Periodo := Emplaz."Periodo Revisión";
                end;
            3:
                begin
                    Veces := Emplaz."Veces Techos";
                    Periodo := Emplaz."Periodo Techos";
                end;
            4:
                begin
                    Veces := Emplaz."Veces Limpieza a Presión";
                    Periodo := Emplaz."Periodo Limpieza a Presión";
                end;
            5:
                begin
                    Veces := Emplaz."Veces Mantenimiento";
                    Periodo := Emplaz."Periodo Mantenimiento";
                end;
        end;
    end;

    local procedure SumarHecha(var Hechas: Dictionary of [Text, Integer]; NEmplaz: Code[20]; Tipo: Integer; Periodo: Integer)
    var
        Clave: Text;
    begin
        Clave := NEmplaz + '|' + Format(Tipo) + '|' + Format(Periodo);
        if Hechas.ContainsKey(Clave) then
            Hechas.Set(Clave, Hechas.Get(Clave) + 1)
        else
            Hechas.Add(Clave, 1);
    end;

    local procedure HechasDe(var Hechas: Dictionary of [Text, Integer]; NEmplaz: Code[20]; Tipo: Integer; Periodo: Integer): Integer
    var
        Clave: Text;
    begin
        Clave := NEmplaz + '|' + Format(Tipo) + '|' + Format(Periodo);
        if Hechas.ContainsKey(Clave) then
            exit(Hechas.Get(Clave));
        exit(0);
    end;

    local procedure BuildObjetivosArray() Resultado: JsonArray
    var
        Item: JsonObject;
        Tipo: Integer;
        Etiquetas: array[5] of Text;
    begin
        Etiquetas[1] := 'Limpieza';
        Etiquetas[2] := 'Revisión';
        Etiquetas[3] := 'Techos';
        Etiquetas[4] := 'Limpieza a presión';
        Etiquetas[5] := 'Mantenimiento';
        for Tipo := 1 to 5 do
            if ObjParadas[Tipo] > 0 then begin
                Clear(Item);
                Item.Add('label', Etiquetas[Tipo]);
                Item.Add('hechas', ObjHechas[Tipo]);
                Item.Add('objetivo', ObjMeta[Tipo]);
                Item.Add('paradas', ObjParadas[Tipo]);
                Item.Add('cumplen', ObjCumplen[Tipo]);
                Resultado.Add(Item);
            end;
    end;

    local procedure BuildTipoArray(var Tipos: JsonArray)
    var
        Tipo: JsonObject;
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(TopTipoLabel) do
            if TopTipoLabel[Index] <> '' then begin
                Clear(Tipo);
                Tipo.Add('label', TopTipoLabel[Index]);
                Tipo.Add('value', TopTipoValue[Index]);
                Tipos.Add(Tipo);
            end;
    end;

    local procedure SendDashboard()
    begin
        if not DashboardReady then
            exit;
        if DashboardPayload = '' then
            exit;
        CurrPage.Dashboard.Render(DashboardPayload);
    end;

    local procedure OpenParadasFiltradas()
    var
        Emplaz: Record Emplazamientos;
    begin
        AplicarFiltroEmplazamientos(Emplaz);
        Page.Run(Page::"Paradas Bus", Emplaz);
    end;

    local procedure ContarParadasPorFamilia()
    var
        Emplaz: Record Emplazamientos;
        TipoTxt: Text;
    begin
        Clear(TotalParadas);
        Clear(ParadasPalos);
        Clear(ParadasMarquesinas);
        AplicarFiltroEmplazamientos(Emplaz);
        if Emplaz.FindSet() then
            repeat
                TotalParadas += 1;
                TipoTxt := Format(Emplaz."Tipo Parada");
                if EsTipoPalo(TipoTxt) then
                    ParadasPalos += 1
                else
                    ParadasMarquesinas += 1;
            until Emplaz.Next() = 0;
    end;

    local procedure EsTipoPalo(TipoParadaTxt: Text): Boolean
    begin
        TipoParadaTxt := DelChr(TipoParadaTxt, '<>', ' ');
        if TipoParadaTxt = '' then
            exit(false);
        if TipoParadaTxt = 'PA' then
            exit(true);
        exit(CopyStr(TipoParadaTxt, 1, 2) = 'PI');
    end;

    local procedure OpenParadasPorFamilia(EsPalo: Boolean)
    var
        Emplaz: Record Emplazamientos;
        FiltroTxt: Text;
    begin
        FiltroParadasTmp.Reset();
        if FiltroParadasTmp.FindSet() then
            repeat
                if EsTipoPalo(FiltroParadasTmp.Value) = EsPalo then begin
                    if FiltroTxt <> '' then
                        FiltroTxt += '|';
                    FiltroTxt += FiltroParadasTmp.Name;
                end;
            until FiltroParadasTmp.Next() = 0;
        if FiltroTxt = '' then
            FiltroTxt := '##NOMATCH##';
        Emplaz.Reset();
        Emplaz.SetRange("Tipo Emplazamiento", Emplaz."Tipo Emplazamiento"::Opis);
        Emplaz.SetFilter("Nº Emplazamiento", FiltroTxt);
        Page.Run(Page::"Paradas Bus", Emplaz);
    end;

    local procedure OpenIncidencias(SoloPeticiones: Boolean)
    var
        Inc: Record Incidencias;
    begin
        Inc.Reset();
        Inc.SetRange("Tipo Elemento", Inc."Tipo Elemento"::Parada);
        Inc.SetRange("Es Peticion", SoloPeticiones);
        Inc.SetFilter(Estado, '<>%1&<>%2', Inc.Estado::Cerrada, Inc.Estado::Facturada);
        AplicarFiltroIncidenciasPorParada(Inc);
        if SoloPeticiones then
            Page.Run(Page::"Lista Mantenimientos", Inc)
        else
            Page.Run(Page::"Lista Incidencias Taller", Inc);
    end;

    local procedure OpenIncidenciasEnProgreso()
    var
        Inc: Record Incidencias;
    begin
        Inc.Reset();
        Inc.SetRange("Tipo Elemento", Inc."Tipo Elemento"::Parada);
        Inc.SetRange("Es Peticion", false);
        Inc.SetRange(Estado, Inc.Estado::EnProgreso);
        AplicarFiltroIncidenciasPorParada(Inc);
        Page.Run(Page::"Lista Incidencias Taller", Inc);
    end;

    local procedure OpenTareas(TipoTarea: Text; Modo: Text)
    var
        UserTask: Record "User Task";
        NEmplaz: Code[20];
    begin
        UserTask.Reset();
        UserTask.SetRange("Object ID", Page::"Ficha Parada Bus");
        UserTask.SetRange(TipoTarea, TipoTarea);
        case Modo of
            'FIN':
                UserTask.SetRange(Estado, UserTask.Estado::Finalizado);
            'PEN':
                begin
                    UserTask.SetFilter(Estado, '%1|%2', UserTask.Estado::Pendiente, UserTask.Estado::"En Proceso");
                    UserTask.SetFilter("Due DateTime", '>=%1', CurrentDateTime);
                end;
            'VEN':
                begin
                    UserTask.SetFilter(Estado, '%1|%2', UserTask.Estado::Pendiente, UserTask.Estado::"En Proceso");
                    UserTask.SetFilter("Due DateTime", '<%1', CurrentDateTime);
                end;
        end;
        UserTask.ClearMarks();
        if UserTask.FindSet() then
            repeat
                NEmplaz := ObtenerEmplazamientoDeTarea(UserTask);
                if (NEmplaz <> '') and EstaParadaEnFiltro(NEmplaz) then
                    UserTask.Mark(true);
            until UserTask.Next() = 0;
        UserTask.MarkedOnly(true);
        Page.Run(Page::"User Task List", UserTask);
    end;

    local procedure OpenOrdenesTrabajoPendientes()
    var
        Inc: Record Incidencias;
    begin
        AplicarFiltroOrdenesTrabajo(Inc, 'PEN');
        Page.Run(Page::"Lista Mantenimientos", Inc);
    end;

    local procedure OpenOrdenesTrabajoAprobadas()
    var
        Inc: Record Incidencias;
    begin
        AplicarFiltroOrdenesTrabajo(Inc, 'APR');
        Page.Run(Page::"Lista Mantenimientos", Inc);
    end;

    local procedure OpenMantenimientos(SoloVencidos: Boolean)
    var
        Emplaz: Record Emplazamientos;
    begin
        AplicarFiltroEmplazamientos(Emplaz);
        Emplaz.SetFilter("Fecha Próximo Mantenimiento", '<>%1', 0D);
        if SoloVencidos then
            Emplaz.SetFilter("Fecha Próximo Mantenimiento", '<=%1', WorkDate())
        else
            Emplaz.SetFilter("Fecha Próximo Mantenimiento", '%1..%2', WorkDate() + 1, CalcDate('<+30D>', WorkDate()));
        Page.Run(Page::"Paradas Bus", Emplaz);
    end;

    var
        FiltroZonaLimpieza: Integer;
        FiltroZonaRevision: Integer;
        FiltroEstadoTip: Text[80];
        TotalParadas: Integer;
        ParadasPalos: Integer;
        ParadasMarquesinas: Integer;
        IncidenciasAbiertas: Integer;
        OrdenesTrabajoAbiertas: Integer;
        IncidenciasEnProgreso: Integer;
        LimpFinalizadas: Integer;
        LimpPendientes: Integer;
        LimpVencidas: Integer;
        RevFinalizadas: Integer;
        RevPendientes: Integer;
        RevVencidas: Integer;
        MantProgramado30d: Integer;
        MantVencido: Integer;
        OrdenesTrabajoAprobadas: Integer;
        OrdenesTrabajoPendientes: Integer;
        ObjHechas: array[5] of Integer;
        ObjMeta: array[5] of Integer;
        ObjParadas: array[5] of Integer;
        ObjCumplen: array[5] of Integer;
        ObjetivoPeriodoText: Text[120];
        TopTipoLabel: array[8] of Text[50];
        TopTipoValue: array[8] of Integer;
        PeriodText: Text[120];
        DashboardPayload: Text;
        DashboardReady: Boolean;
        FiltroParadasTmp: Record "Name/Value Buffer" temporary;
}
