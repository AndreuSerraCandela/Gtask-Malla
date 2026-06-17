page 50084 "Detalle Parte Residuo"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Detalle Parte Residuo';
    PageType = ListPart;
    SourceTable = "Detalle Parte";
    SourceTableView = where(Tipo = const(Residuo));

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
                field(Descripcion; Rec.Descripcion)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción del residuo.';
                }
                field("Descripcion elim. residuos"; Rec."Descripcion elim. residuos")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción de la eliminación de residuos.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Tipo := Rec.Tipo::Residuo;
    end;
}
