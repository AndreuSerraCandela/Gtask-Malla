page 50083 "Detalle Parte Tarea"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Detalle Parte Tarea';
    PageType = ListPart;
    SourceTable = "Detalle Parte";
    SourceTableView = where(Tipo = const(Tarea));

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Nº Linea"; Rec."Nº Linea")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de línea.';
                    Visible = false;
                }
                field("Nº Tarea"; Rec."Nº Tarea")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la tarea de usuario asociada.';
                }
                field(Descripcion; Rec.Descripcion)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción de la tarea.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Tipo := Rec.Tipo::Tarea;
    end;
}
