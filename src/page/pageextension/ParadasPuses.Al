pageextension 92169 BusExtension extends "Paradas Bus"
{
    layout
    {
        modify(ABA)
        {
            Caption = 'Check CERTIFICACIONES';
        }
        modify(SAE)
        {
            Caption = 'TIP';
        }
        addbefore(SAE)
        {
            field(Matricula; Rec.Contratado)
            {
                Caption = 'Matrícula';
            }
        }
        modify("Estado Parada")
        {
            Caption = 'Estado TIP';
        }
        addafter("Zona Limpieza")
        {
            field("Objetivo Limpieza"; Rec."Veces Limpieza")
            {
                ApplicationArea = All;
            }
            field("Periodo Limpieza"; Rec."Periodo Limpieza")
            {
                ApplicationArea = All;
            }
            field("Zona Revisión"; Rec."Zona Revisión")
            {
                Caption = 'Zona Revisión';
            }

            field("Objetivo Revisión"; Rec."Veces Revisión")
            {
                ApplicationArea = All;
            }
            field("Periodo Revisión"; Rec."Periodo Revisión")
            {
                ApplicationArea = All;
            }

            field("Zona Techos"; Rec."Zona Techos")
            {
                ApplicationArea = All;
            }
            field("Objetivo Techos"; Rec."Veces Techos")
            {
                ApplicationArea = All;
            }
            field("Periodo Techos"; Rec."Periodo Techos")
            {
                ApplicationArea = All;
            }
            field("Zona Limpieza a Presión"; Rec."Zona Limpieza a Presión")
            {
                ApplicationArea = All;
            }
            field("Objetivo Limpieza a Presión"; Rec."Veces Limpieza a Presión")
            {
                ApplicationArea = All;
            }
            field("Periodo Limpieza a Presión"; Rec."Periodo Limpieza a Presión")
            {
                ApplicationArea = All;
            }
            field("Zona Mantenimiento"; Rec."Zona Mantenimiento")
            {
                ApplicationArea = All;
            }
            field("Objetivo Mantenimiento"; Rec."Veces Mantenimiento")
            {
                ApplicationArea = All;
            }
            field("Periodo Mantenimiento"; Rec."Periodo Mantenimiento")
            {
                ApplicationArea = All;
            }
            field(TieneOPI; TieneOpi)
            {
                ApplicationArea = All;
                Caption = 'Tiene OPI';
                ToolTip = 'Indica si la parada tiene algún recurso OPI activo montado.';
                Editable = false;
            }
            field(TipoOPI; TipoOpiTxt)
            {
                ApplicationArea = All;
                Caption = 'Tipo OPI';
                ToolTip = 'Clasificación del OPI en la parada: Digital, Papel, Mixto (ambos) o vacío si no hay OPI.';
                Editable = false;
            }
        }
    }
    actions
    {


        addlast(Processing)
        {
            action(DetalleLogParada)
            {
                ApplicationArea = All;
                Caption = 'Detalle log parada';
                Image = History;
                ToolTip = 'Tareas de la parada seleccionada. Las peticiones, incidencias y mantenimientos están en el histórico de movimientos.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    DetalleLogParada: Page "Detalle Log Parada";
                begin
                    CurrPage.SetSelectionFilter(Parada);
                    if not Parada.FindFirst() then
                        Parada := Rec;
                    Parada.TestField("Nº Emplazamiento");
                    DetalleLogParada.SetEmplazamiento(Parada);
                    DetalleLogParada.Run();
                end;
            }
            action(NuevaActuacionTIP)
            {
                ApplicationArea = All;
                Caption = 'Nueva incidencia TIP';
                Image = Create;
                ToolTip = 'Crea una incidencia de subtipo Tip para la parada seleccionada.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                    SubTipo: Enum "SubTipo Incidencia";
                    NoIncidencia: Code[20];
                begin
                    ParadaSeleccionada(Parada);
                    NoIncidencia := Gtask.AltaIncidenciaParada(Parada, SubTipo::Tip);
                    Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(PanelGerenciaParadasBus)
            {
                ApplicationArea = All;
                Caption = 'Panel gerencia';
                Image = Report;
                ToolTip = 'Abre el panel de indicadores de paradas bus, tareas de limpieza/revisión, mantenimiento y partes de trabajo.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Panel Gerencia Paradas Bus");
                end;
            }
            action(ConsultarPeticiones)
            {
                ApplicationArea = All;
                Caption = 'Peticiones';
                Image = OrderList;
                ToolTip = 'Histórico de peticiones de esta parada. El filtro se puede cambiar.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                begin
                    ParadaSeleccionada(Parada);
                    Gtask.AbrirHistoricoParada(Parada, 'Peticion');
                end;
            }
            action(ConsultarIncidencias)
            {
                ApplicationArea = All;
                Caption = 'Incidencias';
                Image = ErrorLog;
                ToolTip = 'Histórico de incidencias correctivas de esta parada, incluido el subtipo Tip. El filtro se puede cambiar.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                begin
                    ParadaSeleccionada(Parada);
                    Gtask.AbrirHistoricoParada(Parada, 'Incidencia');
                end;
            }
            action(ConsultarMantenimientos)
            {
                ApplicationArea = All;
                Caption = 'Mantenimientos';
                Image = MaintenanceLedger;
                ToolTip = 'Histórico de mantenimientos preventivos de esta parada. El filtro se puede cambiar.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                begin
                    ParadaSeleccionada(Parada);
                    Gtask.AbrirHistoricoParada(Parada, 'Mantenimiento');
                end;
            }
            action(NuevaPeticionEMT)
            {
                ApplicationArea = All;
                Caption = 'Petición EMT';
                Image = NewDocument;
                ToolTip = 'Crea una petición externa EMT de esta parada y su orden de trabajo.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                    NoIncidencia: Code[20];
                begin
                    ParadaSeleccionada(Parada);
                    NoIncidencia := Gtask.CrearPeticionEMTParada(Parada);
                    Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(NuevaIncidencia)
            {
                ApplicationArea = All;
                Caption = 'Nueva incidencia';
                Image = NewDocument;
                ToolTip = 'Crea una incidencia correctiva de esta parada, sin orden de trabajo.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                    SubTipo: Enum "SubTipo Incidencia";
                    NoIncidencia: Code[20];
                begin
                    ParadaSeleccionada(Parada);
                    NoIncidencia := Gtask.AltaIncidenciaParada(Parada, SubTipo::Otras);
                    Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(NuevoMantenimiento)
            {
                ApplicationArea = All;
                Caption = 'Nuevo mantenimiento';
                Image = CreateDocument;
                ToolTip = 'Crea un mantenimiento preventivo de esta parada y su orden de trabajo.';

                trigger OnAction()
                var
                    Parada: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                    NoIncidencia: Code[20];
                begin
                    ParadaSeleccionada(Parada);
                    NoIncidencia := Gtask.CrearIncidenciaMantenimientoEmplazamiento(Parada);
                    if NoIncidencia = '' then
                        Message('No se ha podido crear el mantenimiento. Compruebe la periodicidad de la parada.')
                    else
                        Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            //Consultar tareas limpieza
            action("Consultar Tareas Limpieza")
            {
                ApplicationArea = All;
                Caption = 'Consultar Tareas Limpieza';
                Image = TaskPage;
                ToolTip = 'Consultar tareas de limpieza para los emplazamientos OPI de las zonas de limpieza';

                trigger OnAction()
                var
                    UserTask: Record "User Task";
                begin
                    UserTask.SetRange("User Task Group Assigned To", 'LIMPIEZA');
                    UserTask.SetRange(Id_record, Rec.RecordId);
                    Page.Run(Page::"User Task List", UserTask);
                end;
            }
            action("Consultar Tareas Revisión")
            {
                ApplicationArea = All;
                Caption = 'Consultar Tareas Revisión';
                Image = TaskPage;
                ToolTip = 'Consultar tareas de revisión para los emplazamientos OPI de las zonas de revisión';

                trigger OnAction()
                var
                    UserTask: Record "User Task";
                begin
                    UserTask.SetRange("User Task Group Assigned To", 'REVISION');
                    UserTask.SetRange(Id_record, Rec.RecordId);
                    Page.Run(Page::"User Task List", UserTask);
                end;
            }
            action(BorrarTareasLimpieza)
            {
                ApplicationArea = All;
                Caption = 'Borrar Tareas Limpieza';
                Image = TaskPage;
                ToolTip = 'Borrar tareas de limpieza para los emplazamientos OPI de las zonas de limpieza';
                trigger OnAction()
                var
                    Paradas: Record Emplazamientos;
                    UserTask: Record "User Task";
                    Control: Codeunit ControlProcesos;
                begin
                    If not Control.CompruebaPermisos(UserSecurityId(), 'BORRARTAREAS', CompanyName) then
                        Error('No tiene permisos para borrar tareas');
                    if not Confirm('¿Está seguro de que desea borrar las tareas de limpieza para los emplazamientos OPI de las zonas de limpieza?', false) then
                        exit;
                    CurrPage.SetSelectionFilter(Paradas);
                    if Paradas.FindSet() then
                        repeat
                            UserTask.SetRange(Id_record, Paradas.RecordId);
                            UserTask.SetRange("User Task Group Assigned To", 'LIMPIEZA');
                            UserTask.SetRange(Estado, UserTask.Estado::Pendiente, UserTask.Estado::Pendiente);
                            UserTask.DeleteAll();
                        until Paradas.Next() = 0;
                end;
            }
            action(BorrarTareasRevisión)
            {
                ApplicationArea = All;
                Caption = 'Borrar Tareas Revisión';
                Image = TaskPage;
                ToolTip = 'Borrar tareas de revisión para los emplazamientos OPI de las zonas de revisión';
                trigger OnAction()
                var
                    Paradas: Record Emplazamientos;
                    UserTask: Record "User Task";
                    Control: Codeunit ControlProcesos;
                begin
                    If not Control.CompruebaPermisos(UserSecurityId(), 'BORRARTAREAS', CompanyName) then
                        Error('No tiene permisos para borrar tareas');
                    if not Confirm('¿Está seguro de que desea borrar las tareas de revisión para los emplazamientos OPI de las zonas de revisión?', false) then
                        exit;
                    CurrPage.SetSelectionFilter(Paradas);
                    if Paradas.FindSet() then
                        repeat
                            UserTask.SetRange(Id_record, Paradas.RecordId);
                            UserTask.SetRange("User Task Group Assigned To", 'REVISION');
                            UserTask.SetRange(Estado, UserTask.Estado::Pendiente, UserTask.Estado::Pendiente);
                            UserTask.DeleteAll();
                        until Paradas.Next() = 0;
                end;
            }
            // action(CerrarTareasRevisión)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Cierra Tareas Revisión';
            //     Image = TaskPage;
            //     ToolTip = 'Cierra tareas de revisión para los emplazamientos OPI de las zonas de revisión';
            //     trigger OnAction()
            //     var
            //         Paradas: Record Emplazamientos;
            //         UserTask: Record "User Task";
            //     begin
            //         CurrPage.SetSelectionFilter(Paradas);
            //         if Paradas.FindSet() then
            //             repeat
            //                 UserTask.SetRange(Id_record, Paradas.RecordId);
            //                 UserTask.SetRange("User Task Group Assigned To", 'REVISION');
            //                 UserTask.SetRange(Estado, UserTask.Estado::Pendiente, UserTask.Estado::Pendiente);
            //                 UserTask.ModifyAll(Estado, UserTask.Estado::Finalizado);
            //             until Paradas.Next() = 0;
            //     end;
            // }
            action("Crear Tareas Limpieza")
            {
                ApplicationArea = All;
                Caption = 'Crear Tareas Limpieza';
                Image = TaskPage;
                ToolTip = 'Crear tareas de limpieza para los emplazamientos OPI de las zonas de limpieza';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    UserTask: Record "User Task";
                    UsuariosGtask: Record UsuariosGtask;
                    Emplazamientos: Record Emplazamientos;
                    Resource: Record Resource;
                    ZonasLimpieza: Record "Zonas Limpieza";
                    FechaInicio: Date;
                    FechaFin: Date;
                    //OperarioLimpieza: Guid;
                    RecRef: RecordRef;
                    ContadorTareas: Integer;
                    ProximoDiaLimpieza: Date;
                    ZonaSeleccionada: Integer;
                    Responsable: Guid;
                    Supervisor: Guid;
                    Categoria: Code[20];
                    Categorias: Record "User Task Group";
                    EmailResponsable: Text;
                    EmailSupervisor: Text;
                    ListaCorreos: List of [Text];
                begin
                    // Solicitar al usuario que seleccione una zona de limpieza
                    if Page.RunModal(Page::"Zonas Limpieza", ZonasLimpieza) <> Action::LookupOK then
                        exit;

                    ZonaSeleccionada := ZonasLimpieza.Id;

                    // Verificar que hay un operario de limpieza asignado
                    // UsuariosGtask.ChangeCompany('Malla Publicidad');
                    // UsuariosGtask.SetFilter("Id Usuario Limpieza EMT", '<>%1', 0);
                    // if not UsuariosGtask.FindFirst() then
                    //     Error('No se encontró ningún operario de limpieza');
                    if IsNullGuid(ZonasLimpieza.Responsable) then
                        Error('No se encontró ningún responsable de limpieza');
                    UsuariosGtask.SetRange("Id Usuario", ZonasLimpieza.Responsable);
                    if not UsuariosGtask.FindFirst() then
                        Error('No se encontró ningún responsable de limpieza');
                    //OperarioLimpieza := UsuariosGtask."Id Usuario";

                    // Calcular próximo día marcado para esta zona de limpieza
                    ProximoDiaLimpieza := UserTask.CalcularProximoDiaLimpieza(ZonasLimpieza, WorkDate());

                    if ProximoDiaLimpieza = 0D then
                        Error('No hay días marcados para limpieza en la zona %1', ZonasLimpieza.Descripción);

                    FechaInicio := ProximoDiaLimpieza;
                    FechaFin := ProximoDiaLimpieza;

                    // Buscar emplazamientos en esta zona de limpieza que tengan recursos OPI
                    Emplazamientos.SetRange("Zona Limpieza", ZonaSeleccionada);
                    //Emplazamientos.SetFilter(Operario, '<>%1', 0);
                    if Emplazamientos.FindSet() then begin
                        repeat
                            UsuariosGtask.ChangeCompany('Malla Publicidad');
                            UsuariosGtask.SetRange("Id Usuario", ZonasLimpieza.Responsable);

                            if UsuariosGtask.FindFirst() then begin
                                // Crear tarea de limpieza para esta Parada Bus
                                //OperarioLimpieza := UsuariosGtask."Id Usuario";
                                //  Comprobar si la tarea ya existe
                                UserTask.SetRange(Id_record, Emplazamientos.RecordId);
                                UserTask.SetRange("Start DateTime", CreateDateTime(FechaInicio, 080000T));
                                if not UserTask.FindFirst() then begin
                                    RecRef.GetTable(Emplazamientos);
                                    Responsable := UsuariosGtask."Id Usuario";
                                    If Gtask.CrearTareaLimpieza('LIMPIEZA', RecRef, 'Limpieza Parada ' + Emplazamientos."Nº Emplazamiento", Emplazamientos."Zona Limpieza",
                                    'Tarea de limpieza para la Parada ' + Emplazamientos."Nº Emplazamiento" +
                                                        ' - ' + Emplazamientos."Descripción" + ' en la zona de limpieza ' + ZonasLimpieza."Descripción" + ' - ' + ZonasLimpieza."Descripción Detallada"
                                     , false, '', FechaInicio, true, 0) then
                                        ContadorTareas += 1;
                                end;
                            end;
                        until Emplazamientos.Next() = 0;

                        if ContadorTareas > 0 then
                            Message('Se han creado %1 tareas de limpieza para Paradas Bus en la zona %2', ContadorTareas, ZonasLimpieza.Descripción)
                        else
                            Message('No se encontraron Paradas Bus en la zona %1', ZonasLimpieza.Descripción);
                    end else
                        Message('No se encontraron Paradas Bus en la zona de limpieza %1', ZonasLimpieza.Descripción);
                end;
            }
            //Crear Trabajos de Revisión, Son Todas las categorías de Tipo 'REVISION'
            action("Crear Tareas de Revisión")
            {
                ApplicationArea = All;
                Caption = 'Crear Trabajos de Revisión';
                Image = TaskPage;
                ToolTip = 'Crear trabajos de revisión para los emplazamientos OPI de las zonas de revisión';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    UserTask: Record "User Task";
                    UsuariosGtask: Record UsuariosGtask;
                    Emplazamientos: Record Emplazamientos;
                    Resource: Record Resource;
                    ZonasLimpieza: Record "Zonas Limpieza";
                    FechaInicio: Date;
                    FechaFin: Date;
                    //OperarioLimpieza: Guid;
                    RecRef: RecordRef;
                    ContadorTareas: Integer;
                    ProximoDiaLimpieza: Date;
                    ZonaSeleccionada: Integer;
                    Responsable: Guid;
                    Supervisor: Guid;
                    Categoria: Code[20];
                    Categorias: Record "User Task Group";
                    EmailResponsable: Text;
                    EmailSupervisor: Text;
                    ListaCorreos: List of [Text];
                begin
                    // Solicitar al usuario que seleccione una zona de limpieza
                    if Page.RunModal(Page::"Zonas Limpieza", ZonasLimpieza) <> Action::LookupOK then
                        exit;

                    ZonaSeleccionada := ZonasLimpieza.Id;

                    // Verificar que hay un operario de limpieza asignado
                    // UsuariosGtask.ChangeCompany('Malla Publicidad');
                    // UsuariosGtask.SetFilter("Id Usuario Limpieza EMT", '<>%1', 0);
                    // if not UsuariosGtask.FindFirst() then
                    //     Error('No se encontró ningún operario de limpieza');
                    if IsNullGuid(ZonasLimpieza.Responsable) then
                        Error('No se encontró ningún responsable de revisión');
                    UsuariosGtask.SetRange("Id Usuario", ZonasLimpieza.Responsable);
                    if not UsuariosGtask.FindFirst() then
                        Error('No se encontró ningún responsable de revisión');
                    //OperarioLimpieza := UsuariosGtask."Id Usuario";

                    // Calcular próximo día marcado para esta zona de limpieza
                    ProximoDiaLimpieza := UserTask.CalcularProximoDiaLimpieza(ZonasLimpieza, WorkDate());

                    if ProximoDiaLimpieza = 0D then
                        Error('No hay días marcados para limpieza en la zona %1', ZonasLimpieza.Descripción);

                    FechaInicio := ProximoDiaLimpieza;
                    FechaFin := ProximoDiaLimpieza;

                    // Buscar emplazamientos en esta zona de revisión que tengan recursos OPI
                    Emplazamientos.SetRange("Zona Revisión", ZonaSeleccionada);
                    //Emplazamientos.SetFilter(Operario, '<>%1', 0);
                    if Emplazamientos.FindSet() then begin
                        repeat
                            UsuariosGtask.ChangeCompany('Malla Publicidad');
                            UsuariosGtask.SetRange("Id Usuario", ZonasLimpieza.Responsable);

                            if UsuariosGtask.FindFirst() then begin
                                // Crear tarea de limpieza para esta Parada Bus
                                //OperarioLimpieza := UsuariosGtask."Id Usuario";
                                //  Comprobar si la tarea ya existe
                                UserTask.SetRange(Id_record, Emplazamientos.RecordId);
                                UserTask.SetRange("Start DateTime", CreateDateTime(FechaInicio, 080000T));
                                if not UserTask.FindFirst() then begin
                                    RecRef.GetTable(Emplazamientos);
                                    Responsable := UsuariosGtask."Id Usuario";
                                    If Gtask.CrearTareaLimpieza('REVISION', RecRef, 'Revisión Parada ' + Emplazamientos."Nº Emplazamiento", Emplazamientos."Zona Revisión",
                                    'Tarea de revisión para la Parada ' + Emplazamientos."Nº Emplazamiento" +
                                                        ' - ' + Emplazamientos."Descripción" + ' en la zona de revisión ' + ZonasLimpieza."Descripción" + ' - ' + ZonasLimpieza."Descripción Detallada"
                                     , false, '', FechaInicio, true, 0) then
                                        ContadorTareas += 1;
                                end;
                            end;
                        until Emplazamientos.Next() = 0;

                        if ContadorTareas > 0 then
                            Message('Se han creado %1 tareas de revisión para Paradas Bus en la zona %2', ContadorTareas, ZonasLimpieza.Descripción)
                        else
                            Message('No se encontraron Paradas Bus en la zona %1', ZonasLimpieza.Descripción);
                    end else
                        Message('No se encontraron Paradas Bus en la zona de revisión %1', ZonasLimpieza.Descripción);
                end;
            }
            action(ProcesarMantenimientosVencidos)
            {
                ApplicationArea = All;
                Caption = 'Crear órdenes mantenimiento vencidas';
                Image = CreateDocument;
                ToolTip = 'Crea órdenes de mantenimiento para emplazamientos Opis, Vallas y Otros con fecha de próximo mantenimiento vencida.';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    N: Integer;
                begin
                    if not Confirm('¿Crear órdenes de mantenimiento para todos los emplazamientos con mantenimiento vencido?', false) then
                        exit;
                    N := Gtask.ProcesarMantenimientosVencidos();
                    Message('Se han creado %1 órdenes de mantenimiento.', N);
                end;
            }
            action(AsignarZonaMantenimiento)
            {
                ApplicationArea = All;
                Caption = 'Asignar zona mantenimiento';
                Image = Apply;
                ToolTip = 'Asigna la misma zona de mantenimiento a todas las paradas seleccionadas.';

                trigger OnAction()
                var
                    Paradas: Record Emplazamientos;
                    Gtask: Codeunit Gtask;
                begin
                    CurrPage.SetSelectionFilter(Paradas);
                    Gtask.AsignarZonaMantenimientoEmplazamientos(Paradas);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(ConsultarPeticiones_Promoted; ConsultarPeticiones) { }
            actionref(ConsultarIncidencias_Promoted; ConsultarIncidencias) { }
            actionref(ConsultarMantenimientos_Promoted; ConsultarMantenimientos) { }
            actionref(NuevaPeticionEMT_Promoted; NuevaPeticionEMT) { }
            actionref(NuevaIncidencia_Promoted; NuevaIncidencia) { }
            actionref(NuevoMantenimiento_Promoted; NuevoMantenimiento) { }
            actionref(NuevaActuacionTIP_Promoted; NuevaActuacionTIP) { }
            actionref(DetalleLogParada_Promoted; DetalleLogParada) { }
            actionref(AsignarZonaMantenimiento_Promoted; AsignarZonaMantenimiento) { }
        }
    }

    var
        TieneOpi: Boolean;
        TipoOpiTxt: Text[20];

    local procedure ParadaSeleccionada(var Parada: Record Emplazamientos)
    begin
        CurrPage.SetSelectionFilter(Parada);
        if not Parada.FindFirst() then
            Parada := Rec;
        Parada.TestField("Nº Emplazamiento");
    end;

    trigger OnAfterGetRecord()
    begin
        CalcularOpiParada(TieneOpi, TipoOpiTxt);
    end;

    local procedure CalcularOpiParada(var TieneOpiOut: Boolean; var TipoOpiOut: Text[20])
    var
        Resource: Record Resource;
        HayDigital: Boolean;
        HayPapel: Boolean;
    begin
        TieneOpiOut := false;
        TipoOpiOut := '';
        if Rec."Nº Emplazamiento" = '' then
            exit;

        Resource.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
        Resource.SetRange(Blocked, false);
        Resource.SetRange("Fecha baja", 0D);
        if Resource.FindSet() then
            repeat
                if EsTipoRecursoOpiDigital(Resource."Tipo Recurso") then
                    HayDigital := true;
                if EsTipoRecursoOpiPapel(Resource."Tipo Recurso") then
                    HayPapel := true;
            until Resource.Next() = 0;

        TieneOpiOut := HayDigital or HayPapel;
        if not TieneOpiOut then
            exit;

        if HayDigital and HayPapel then
            TipoOpiOut := 'Mixto'
        else
            if HayDigital then
                TipoOpiOut := 'Digital'
            else
                TipoOpiOut := 'Papel';
    end;

    // Códigos Tipo Recurso OPI (SQL Malla2009): Malla Publicidad, Grepsa, Ibiza/Menorca Publicidad S_A_ — máx. 10 chars (Code[10]).
    local procedure EsTipoRecursoOpiDigital(TipoRecurso: Code[10]): Boolean
    begin
        exit(TipoRecurso in ['OPIDIGITAL', 'PANT.LED', 'POSTLED', 'OPI DIGIT.', 'P.LEDS']);
    end;

    local procedure EsTipoRecursoOpiPapel(TipoRecurso: Code[10]): Boolean
    begin
        exit(TipoRecurso in ['OPI', 'OPI ROT.', 'MINI OPI', 'OPIS AJENO', 'LUM1,5X1,1', 'RELOJ', 'PLANIMETRO', 'ALQOPI', 'LUMINOSOS', 'OPI SMAP', 'PANTALLA', 'DECOPIS']);
    end;
}
