pageextension 92175 FichaParadaBusExtension extends "Ficha Parada Bus"
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
            field("Estado Parada"; Rec."Estado Parada")
            {
                Caption = 'Estado TIP';
            }
            field(Matricula; Rec.Contratado)
            {
                Caption = 'Matrícula';
            }

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
        }
    }
}
