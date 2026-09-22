pageextension 92174 "Resource List GTask Ext" extends "Resource List"
{
    actions
    {
        addlast(Processing)
        {
            action(ConsultarPeticiones)
            {
                ApplicationArea = All;
                Caption = 'Peticiones';
                Image = OrderList;
                ToolTip = 'Histórico de peticiones del recurso seleccionado. El filtro se puede cambiar.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                begin
                    RecursoSeleccionado(Resource);
                    Gtask.AbrirHistoricoRecurso(Resource, 'Peticion');
                end;
            }
            action(ConsultarIncidencias)
            {
                ApplicationArea = All;
                Caption = 'Incidencias';
                Image = ErrorLog;
                ToolTip = 'Histórico de incidencias correctivas del recurso seleccionado. El filtro se puede cambiar.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                begin
                    RecursoSeleccionado(Resource);
                    Gtask.AbrirHistoricoRecurso(Resource, 'Incidencia');
                end;
            }
            action(ConsultarMantenimientos)
            {
                ApplicationArea = All;
                Caption = 'Mantenimientos';
                Image = MaintenanceLedger;
                ToolTip = 'Histórico de mantenimientos preventivos del recurso seleccionado. El filtro se puede cambiar.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                begin
                    RecursoSeleccionado(Resource);
                    Gtask.AbrirHistoricoRecurso(Resource, 'Mantenimiento');
                end;
            }
            action(NuevaPeticion)
            {
                ApplicationArea = All;
                Caption = 'Nueva petición';
                Image = NewDocument;
                ToolTip = 'Crea una petición interna del recurso seleccionado y su orden de trabajo.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                    NoIncidencia: Code[20];
                begin
                    RecursoSeleccionado(Resource);
                    NoIncidencia := Gtask.CrearPeticionInternaRecurso(Resource);
                    Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(NuevaIncidencia)
            {
                ApplicationArea = All;
                Caption = 'Nueva incidencia';
                Image = NewDocument;
                ToolTip = 'Crea una incidencia correctiva del recurso seleccionado, sin orden de trabajo.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                    SubTipo: Enum "SubTipo Incidencia";
                    NoIncidencia: Code[20];
                begin
                    RecursoSeleccionado(Resource);
                    NoIncidencia := Gtask.AltaIncidenciaRecurso(Resource, SubTipo::Otras);
                    Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(NuevoMantenimiento)
            {
                ApplicationArea = All;
                Caption = 'Nuevo mantenimiento';
                Image = CreateDocument;
                ToolTip = 'Crea un mantenimiento preventivo del recurso seleccionado y su orden de trabajo.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                    NoIncidencia: Code[20];
                begin
                    RecursoSeleccionado(Resource);
                    NoIncidencia := Gtask.CrearIncidenciaMantenimientoRecurso(Resource, '', false);
                    if NoIncidencia = '' then
                        Message('No se ha podido crear el mantenimiento. Compruebe la periodicidad del recurso.')
                    else
                        Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(AsignarZonaMantenimiento)
            {
                ApplicationArea = All;
                Caption = 'Asignar zona mantenimiento';
                Image = Apply;
                ToolTip = 'Asigna la misma zona de mantenimiento a todos los recursos seleccionados.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    Gtask: Codeunit Gtask;
                begin
                    CurrPage.SetSelectionFilter(Resource);
                    Gtask.AsignarZonaMantenimientoRecursos(Resource);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(ConsultarPeticiones_Promoted; ConsultarPeticiones) { }
            actionref(ConsultarIncidencias_Promoted; ConsultarIncidencias) { }
            actionref(ConsultarMantenimientos_Promoted; ConsultarMantenimientos) { }
            actionref(NuevaPeticion_Promoted; NuevaPeticion) { }
            actionref(NuevaIncidencia_Promoted; NuevaIncidencia) { }
            actionref(NuevoMantenimiento_Promoted; NuevoMantenimiento) { }
            actionref(AsignarZonaMantenimiento_Promoted; AsignarZonaMantenimiento) { }
        }
    }

    local procedure RecursoSeleccionado(var Resource: Record Resource)
    begin
        CurrPage.SetSelectionFilter(Resource);
        if not Resource.FindFirst() then
            Resource := Rec;
        Resource.TestField("No.");
    end;
}
