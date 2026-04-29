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
            field("Zona Revisión"; Rec."Zona Revisión")
            {
                Caption = 'Zona Revisión';
            }
        }
    }
    actions
    {


        addlast(Processing)
        {
            action(ConsultarIncidencias)
            {
                ApplicationArea = All;
                Caption = 'Consultar incidencias';
                Image = ErrorLog;
                ToolTip = 'Abre las incidencias de esta parada (sin órdenes de trabajo)';

                trigger OnAction()
                var
                    Incidencias: Record Incidencias;
                begin
                    Incidencias.SetRange(Recurso, Rec."Nº Emplazamiento");
                    Incidencias.SetRange("Tipo Elemento", Incidencias."Tipo Elemento"::Parada);
                    Incidencias.SetRange("Es Peticion", false);
                    Page.Run(Page::"Lista Incidencias Taller", Incidencias);
                end;
            }
            action(OrdenesTrabajo)
            {
                ApplicationArea = All;
                Caption = 'Órdenes de trabajo';
                Image = OrderList;
                ToolTip = 'Abre las órdenes de trabajo (incidencias tipo petición) de esta parada';

                trigger OnAction()
                var
                    Incidencias: Record Incidencias;
                begin
                    Incidencias.SetRange(Recurso, Rec."Nº Emplazamiento");
                    Incidencias.SetRange("Tipo Elemento", Incidencias."Tipo Elemento"::Parada);
                    Incidencias.SetRange("Es Peticion", true);
                    Page.Run(Page::"Lista Incidencias Taller", Incidencias);
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
                    Page.Run(0, UserTask);
                end;
            }
            action(BorrarTareasLimpiezaº)
            {
                ApplicationArea = All;
                Caption = 'Borrar Tareas Limpieza';
                Image = TaskPage;
                ToolTip = 'Borrar tareas de limpieza para los emplazamientos OPI de las zonas de limpieza';
                trigger OnAction()
                var
                    Paradas: Record Emplazamientos;
                    UserTask: Record "User Task";
                begin
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
                begin
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
        }
    }


}
