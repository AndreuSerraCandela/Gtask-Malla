page 50092 "Histórico movimientos"
{
    PageType = List;
    Caption = 'Histórico movimientos';
    SourceTable = Incidencias;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lineas)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Abre la petición, la incidencia o el mantenimiento.';

                    trigger OnDrillDown()
                    var
                        Gtask: Codeunit Gtask;
                    begin
                        Gtask.AbrirFichaMovimiento(Rec."No.");
                    end;
                }
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                }
                field("Es Peticion"; Rec."Es Peticion")
                {
                    ApplicationArea = All;
                    ToolTip = 'Petición. El filtro de la lista se puede cambiar.';
                }
                field("Tipo Intervención"; Rec."Tipo Intervención")
                {
                    ApplicationArea = All;
                    ToolTip = 'Correctivo es incidencia. Preventivo es mantenimiento.';
                }
                field("SubTipo Incidencia"; Rec."SubTipo Incidencia")
                {
                    ApplicationArea = All;
                    ToolTip = 'Oficio del movimiento. Tip es un subtipo de incidencia.';
                }
                field("Tipo Incidencia"; Rec."Tipo Incidencia")
                {
                    ApplicationArea = All;
                }
                field(Estado; Rec.Estado)
                {
                    ApplicationArea = All;
                }
                field("FechaHora"; Rec."FechaHora")
                {
                    ApplicationArea = All;
                }
                field("Tipo Elemento"; Rec."Tipo Elemento")
                {
                    ApplicationArea = All;
                }
                field(Recurso; Rec.Recurso)
                {
                    ApplicationArea = All;
                }
                field("Comunicado por EMT"; Rec."Comunicado por EMT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Petición externa EMT.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Abrir)
            {
                ApplicationArea = All;
                Caption = 'Abrir';
                Image = Edit;
                ToolTip = 'Abre la ficha del movimiento seleccionado.';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.AbrirFichaMovimiento(Rec."No.");
                end;
            }
        }
        area(Promoted)
        {
            actionref(Abrir_Promoted; Abrir) { }
        }
    }
}
