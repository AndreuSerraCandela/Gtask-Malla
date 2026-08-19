pageextension 50115 FichaParadaBusExtension extends "Ficha Parada Bus"
{
    layout
    {

        modify("Fecha instalación")
        {
            Caption = 'Detalle Log Parada';


            trigger OnDrillDown()
            var
                DetalleLogParada: Page "Detalle Log Parada";
            begin
                DetalleLogParada.SetEmplazamiento(Rec);
                DetalleLogParada.Run();
            end;


        }




        addlast(Content)
        {
            group(GrupoActuacionesTIP)
            {
                Caption = 'Lista de Actuaciones TIP';
                part(PartActuacionesTIP; "Lista Actuaciones TIP")
                {
                    ApplicationArea = All;
                    Caption = 'Actuaciones';
                    SubPageLink = Recurso = FIELD("Nº Emplazamiento");
                    UpdatePropagation = Both;
                }
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
                Caption = 'Mantenimientos';
                Image = OrderList;
                ToolTip = 'Abre los mantenimientos (órdenes de trabajo preventivas) de esta parada';

                trigger OnAction()
                var
                    Incidencias: Record Incidencias;
                begin
                    Incidencias.SetRange(Recurso, Rec."Nº Emplazamiento");
                    Incidencias.SetRange("Tipo Elemento", Incidencias."Tipo Elemento"::Parada);
                    Page.Run(Page::"Lista Mantenimientos", Incidencias);
                end;
            }
            action(CrearOrdenMantenimiento)
            {
                ApplicationArea = All;
                Caption = 'Crear orden mantenimiento';
                Image = CreateDocument;
                ToolTip = 'Crea una orden EMT de mantenimiento programado para esta parada.';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    NoIncidencia: Code[20];
                begin
                    NoIncidencia := Gtask.CrearIncidenciaMantenimientoEmplazamiento(Rec);
                    if NoIncidencia <> '' then
                        Message('Orden de mantenimiento: %1', NoIncidencia);
                end;
            }
        }
    }
}
