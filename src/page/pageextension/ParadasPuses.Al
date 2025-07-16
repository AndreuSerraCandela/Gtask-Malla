pageextension 92169 BusExtension extends "Paradas Bus"
{
    actions
    {


        addlast(Processing)
        {
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
                    OperarioLimpieza: Guid;
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
                    UsuariosGtask.ChangeCompany('Malla Publicidad');
                    UsuariosGtask.SetFilter("Id Usuario Limpieza EMT", '<>%1', 0);
                    if not UsuariosGtask.FindFirst() then
                        Error('No se encontró ningún operario de limpieza');

                    OperarioLimpieza := UsuariosGtask."Id Usuario";

                    // Calcular próximo día marcado para esta zona de limpieza
                    ProximoDiaLimpieza := CalcularProximoDiaLimpieza(ZonasLimpieza);

                    if ProximoDiaLimpieza = 0D then
                        Error('No hay días marcados para limpieza en la zona %1', ZonasLimpieza.Descripción);

                    FechaInicio := ProximoDiaLimpieza;
                    FechaFin := ProximoDiaLimpieza;

                    // Buscar emplazamientos en esta zona de limpieza que tengan recursos OPI
                    Emplazamientos.SetRange("Zona Limpieza", ZonaSeleccionada);
                    Emplazamientos.SetFilter(Operario, '<>%1', 0);
                    if Emplazamientos.FindSet() then begin
                        repeat
                            UsuariosGtask.ChangeCompany('Malla Publicidad');
                            UsuariosGtask.SetRange("Id Usuario Limpieza EMT", Emplazamientos.Operario);

                            if UsuariosGtask.FindFirst() then begin
                                // Crear tarea de limpieza para este emplazamiento OPI
                                OperarioLimpieza := UsuariosGtask."Id Usuario";
                                //  Comprobar si la tarea ya existe
                                UserTask.SetRange(Id_record, Emplazamientos.RecordId);
                                UserTask.SetRange("Start DateTime", CreateDateTime(FechaInicio, 080000T));
                                if not UserTask.FindFirst() then begin
                                    RecRef.GetTable(Emplazamientos);
                                    Responsable := UsuariosGtask."Id Usuario";
                                    Gtask.CrearTareaLimpieza(RecRef, 'Limpieza OPI ' + Emplazamientos."Nº Emplazamiento", Responsable, Supervisor, 'TALLER', 'TECNICO', 'LIMPIEZA',
                                    'Tarea de limpieza para el emplazamiento OPI ' + Emplazamientos."Nº Emplazamiento" +
                                                        ' - ' + Emplazamientos."Descripción" + ' en la zona de limpieza ' + ZonasLimpieza."Descripción" + ' - ' + ZonasLimpieza."Descripción Detallada"
                                     + Emplazamientos."Nº Emplazamiento", false, '', FechaInicio);

                                    ContadorTareas += 1;
                                end;
                            end;
                        until Emplazamientos.Next() = 0;

                        if ContadorTareas > 0 then
                            Message('Se han creado %1 tareas de limpieza para emplazamientos OPI en la zona %2', ContadorTareas, ZonasLimpieza.Descripción)
                        else
                            Message('No se encontraron emplazamientos con recursos OPI en la zona %1', ZonasLimpieza.Descripción);
                    end else
                        Message('No se encontraron emplazamientos en la zona de limpieza %1', ZonasLimpieza.Descripción);
                end;
            }
        }
    }

    local procedure CalcularProximoDiaLimpieza(ZonaLimpieza: Record "Zonas Limpieza"): Date
    var
        FechaActual: Date;
        DiaSemana: Integer;
        DiasAñadir: Integer;
        MaxDias: Integer;
    begin
        FechaActual := CalcDate(ZonaLimpieza.Periodicidad, WorkDate()); // Empezar desde mañana
        exit(FechaActual);
    end;

}
