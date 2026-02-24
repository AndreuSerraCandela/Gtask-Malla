page 50108 "Periodicidad Zona Limpieza"
{
    Caption = 'Periodicidad limpieza';
    PageType = ListPart;
    SourceTable = "Periodicidad Zona Limpieza";
    SourceTableView = sorting("Id Zona Limpieza", "Línea");
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Tipo Periodicidad"; Rec."Tipo Periodicidad")
                {
                    ApplicationArea = All;
                    ToolTip = 'Día semanal: ej. todos los lunes y viernes. Día del mes: ej. día 1 y 15.';
                }
                field("Día Semana"; Rec."Día Semana")
                {
                    ApplicationArea = All;
                    //Visible = Rec."Tipo Periodicidad" = Rec."Tipo Periodicidad"::"Día semanal";
                    ToolTip = 'Cuando el tipo es Día semanal, indica el día de la semana (solo laborables L-V).';
                }
                field("Día del mes"; Rec."Día del mes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Día del mes (1-31). Puede haber varias líneas para varios días, ej. 1 y 15.';
                }
                field(Temporada; Rec.Temporada)
                {
                    ApplicationArea = All;
                    ToolTip = 'Todas = todo el año. Verano = abr-oct. Invierno = nov-mar.';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Periodicidad: Record "Periodicidad Zona Limpieza";
    begin
        if Rec."Id Zona Limpieza" = 0 then
            exit(false);
        if Rec."Línea" = 0 then begin
            Periodicidad.SetRange("Id Zona Limpieza", Rec."Id Zona Limpieza");
            if Periodicidad.FindLast() then
                Rec."Línea" := Periodicidad."Línea" + 1
            else
                Rec."Línea" := 1;
        end;
        exit(true);
    end;
}
