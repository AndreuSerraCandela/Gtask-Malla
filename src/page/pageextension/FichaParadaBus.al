pageextension 50115 FichaParadaBusExtension extends "Ficha Parada Bus"
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
                ToolTip = 'Histórico de peticiones de esta parada. El filtro se puede cambiar.';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.AbrirHistoricoParada(Rec, 'Peticion');
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
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.AbrirHistoricoParada(Rec, 'Incidencia');
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
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.AbrirHistoricoParada(Rec, 'Mantenimiento');
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
                    Gtask: Codeunit Gtask;
                    NoIncidencia: Code[20];
                begin
                    NoIncidencia := Gtask.CrearPeticionEMTParada(Rec);
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
                    Gtask: Codeunit Gtask;
                    SubTipo: Enum "SubTipo Incidencia";
                    NoIncidencia: Code[20];
                begin
                    NoIncidencia := Gtask.AltaIncidenciaParada(Rec, SubTipo::Otras);
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
                    Gtask: Codeunit Gtask;
                    NoIncidencia: Code[20];
                begin
                    NoIncidencia := Gtask.CrearIncidenciaMantenimientoEmplazamiento(Rec);
                    if NoIncidencia = '' then
                        Message('No se ha podido crear el mantenimiento. Compruebe la periodicidad de la parada.')
                    else
                        Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(NuevaActuacionTIP)
            {
                ApplicationArea = All;
                Caption = 'Nueva incidencia TIP';
                Image = Create;
                ToolTip = 'Crea una incidencia de subtipo Tip para esta parada.';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    SubTipo: Enum "SubTipo Incidencia";
                    NoIncidencia: Code[20];
                begin
                    NoIncidencia := Gtask.AltaIncidenciaParada(Rec, SubTipo::Tip);
                    Gtask.AbrirFichaMovimiento(NoIncidencia);
                end;
            }
            action(DetalleLogParada)
            {
                ApplicationArea = All;
                Caption = 'Detalle log parada';
                Image = History;
                ToolTip = 'Tareas de esta parada. Abra cada línea para ver o subir documentación adjunta.';

                trigger OnAction()
                var
                    DetalleLogParada: Page "Detalle Log Parada";
                begin
                    DetalleLogParada.SetEmplazamiento(Rec);
                    DetalleLogParada.Run();
                end;
            }
        }
        addfirst(Category_Process)
        {
            actionref(ConsultarPeticiones_Promoted; ConsultarPeticiones) { }
            actionref(ConsultarIncidencias_Promoted; ConsultarIncidencias) { }
            actionref(ConsultarMantenimientos_Promoted; ConsultarMantenimientos) { }
            actionref(NuevaPeticionEMT_Promoted; NuevaPeticionEMT) { }
            actionref(NuevaIncidencia_Promoted; NuevaIncidencia) { }
            actionref(NuevoMantenimiento_Promoted; NuevoMantenimiento) { }
            actionref(NuevaActuacionTIP_Promoted; NuevaActuacionTIP) { }
            actionref(DetalleLogParada_Promoted; DetalleLogParada) { }
        }
    }
}
