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
                    UserTask.SetRange("No.", Rec."Nº Emplazamiento");
                    UserTask.SetRange("User Task Group Assigned To", 'LIMPIEZA');
                    UserTask.SetRange(Id_record, Rec.RecordId);
                    Page.Run(Page::"User Task List", UserTask);
                end;
            }
            action("Consultar Tareas Puesta Apunto")
            {
                ApplicationArea = All;
                Caption = 'Consultar Tareas Puesta Apunto';
                Image = TaskPage;
                ToolTip = 'Consultar tareas de puesta apunto para los emplazamientos OPI de las zonas de limpieza';

                trigger OnAction()
                var
                    UserTask: Record "User Task";
                begin
                    UserTask.SetRange("No.", Rec."Nº Emplazamiento");
                    UserTask.SetRange("User Task Group Assigned To", 'PuestaApunto');
                    UserTask.SetRange(Id_record, Rec.RecordId);
                    Page.Run(0, UserTask);
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
            //Crear Trabajos de Puesta Apunto, Son Todas las categorías de Tipo 'PuestaApunto'
            action("Crear Trabajos de Puesta Apunto")
            {
                ApplicationArea = All;
                Caption = 'Crear Trabajos de Puesta Apunto';
                Image = TaskPage;
                ToolTip = 'Crear trabajos de puesta apunto para los emplazamientos OPI de las zonas de limpieza';

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
                    Categoria: Code[20];
                    Categorias: Record "User Task Group";
                    EmailResponsable: Text;
                    EmailSupervisor: Text;
                    ListaCorreos: List of [Text];
                    Periodicidad: DateFormula;
                begin
                    // Solicitar al usuario que seleccione una zona de limpieza
                    //No hace Falta Pedir Zona, porque es para todas, pero sí categoría y solo se crean las tareas de los elementos seleccionado, si no existe ninguna tarea para sese elemento y categoría
                    if Page.RunModal(Page::"User Task Groups", Categorias) <> Action::LookupOK then
                        exit;
                    Categoria := Categorias.Code;
                    CurrPage.SetSelectionFilter(Emplazamientos);
                    if Emplazamientos.FindSet() then begin
                        repeat
                            //Crear tarea de puesta apunto para esta Parada Bus
                            UserTask.SetRange("No.", Emplazamientos."Nº Emplazamiento");
                            UserTask.SetRange("User Task Group Assigned To", Categoria);
                            if not UserTask.FindFirst() then begin
                                RecRef.GetTable(Emplazamientos);
                                Gtask.CrearTareaLimpieza('PuestaApunto', RecRef, Categorias.Description + ' ' + Emplazamientos."Nº Emplazamiento", 0,
                                'Tarea de ' + Categorias.Description + ' para la Parada Bus ' + Emplazamientos."Nº Emplazamiento" +
                                ' - ' + Emplazamientos."Descripción" + ' en la zona de limpieza ' + ZonasLimpieza."Descripción" + ' - ' + ZonasLimpieza."Descripción Detallada"
                                + Emplazamientos."Nº Emplazamiento", false, '', FechaInicio, true, 0);
                            end;
                        until Emplazamientos.Next() = 0;
                    end else
                        Message('No se encontraron Paradas Bus seleccionadas');
                end;
            }
        }
    }


}
