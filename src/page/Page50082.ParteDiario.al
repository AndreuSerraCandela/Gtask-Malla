page 50082 "Parte Diario"
{
    ApplicationArea = All;
    Caption = 'Parte Diario';
    PageType = Card;
    SourceTable = "Partes de Trabajo";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Nº Parte"; Rec."Nº Parte")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número del parte diario.';
                }
                field("Fecha Parte"; Rec."Fecha Parte")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha del parte.';
                }
                field("Hora Entrada"; Rec."Hora Entrada")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la hora de entrada.';
                }
                field("Hora Salida"; Rec."Hora Salida")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la hora de salida.';
                }
                field(Horas; Rec.Horas)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica las horas trabajadas.';
                    Editable = false;
                }
                field(Empresa; Rec.Empresa)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la empresa.';
                }
                field(Empleado; Rec.Empleado)
                {
                    ApplicationArea = All;
                    ToolTip = 'Empleado del parte. Al asignarlo se añaden las tareas finalizadas del día.';

                    trigger OnValidate()
                    begin
                        CurrPage.Tareas.Page.Update(false);
                    end;
                }
                field("Texto Trabajo"; Rec."Texto Trabajo")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Especifica el texto descriptivo del trabajo realizado.';
                }
            }
            part(Tareas; "Detalle Parte Tarea")
            {
                ApplicationArea = All;
                Caption = 'Tareas';
                SubPageLink = "Nº Parte" = field("Nº Parte");
                SubPageView = where(Tipo = const(Tarea));
            }
            part(Residuos; "Detalle Parte Residuo")
            {
                ApplicationArea = All;
                Caption = 'Residuos';
                SubPageLink = "Nº Parte" = field("Nº Parte");
                SubPageView = where(Tipo = const(Residuo));
            }
        }
    }
}
