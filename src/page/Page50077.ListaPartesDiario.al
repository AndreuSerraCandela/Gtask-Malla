page 50077 "Lista Partes Diario"
{
    ApplicationArea = All;
    Caption = 'Partes diario';
    CardPageId = "Parte Diario";
    PageType = List;
    SourceTable = "Partes de Trabajo";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Nº Parte"; Rec."Nº Parte")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número del parte diario.';
                }
                field("Fecha Parte"; Rec."Fecha Parte")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha del parte.';
                }
                field(Empleado; Rec.Empleado)
                {
                    ApplicationArea = All;
                    ToolTip = 'Empleado asociado al parte.';
                }
                field("Hora Entrada"; Rec."Hora Entrada")
                {
                    ApplicationArea = All;
                    ToolTip = 'Hora de entrada.';
                }
                field("Hora Salida"; Rec."Hora Salida")
                {
                    ApplicationArea = All;
                    ToolTip = 'Hora de salida.';
                }
                field(Horas; Rec.Horas)
                {
                    ApplicationArea = All;
                    ToolTip = 'Horas trabajadas.';
                }
                field(Empresa; Rec.Empresa)
                {
                    ApplicationArea = All;
                    ToolTip = 'Empresa del parte.';
                }
                field("Texto Trabajo"; Rec."Texto Trabajo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del trabajo realizado.';
                }
            }
        }
    }
}
