page 50134 "Checklist Tarea Usuario"
{
    Caption = 'Checklist';
    PageType = ListPart;
    SourceTable = "Checklist Tarea Usuario";
    AutoSplitKey = true;
    DelayedInsert = true;
    MultipleNewLines = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Nº Línea"; Rec."Nº Línea")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                }
                field(Obligatorio; Rec.Obligatorio)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Completado; Rec.Completado)
                {
                    ApplicationArea = All;
                }
                field("Fecha Completado"; Rec."Fecha Completado")
                {
                    ApplicationArea = All;
                }
                field("Completado por"; Rec."Completado por")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }
}
