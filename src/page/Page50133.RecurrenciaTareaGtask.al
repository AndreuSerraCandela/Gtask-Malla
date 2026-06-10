page 50133 "Recurrencia Tarea Gtask"
{
    ApplicationArea = All;
    Caption = 'Recurrencia de tarea';
    PageType = Card;
    SourceTable = "User Task";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Recurrencia';

                field(RecurrenciaActiva; Rec.RecurrenciaActiva)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si la tarea se repetirá al finalizarse según la fórmula configurada.';
                }
                field(FormulaRecurrencia; Rec.FormulaRecurrencia)
                {
                    ApplicationArea = All;
                    Enabled = Rec.RecurrenciaActiva;
                    ToolTip = 'Ejemplos: 1D (diaria), 1W (semanal), 1M (mensual), 3M (trimestral).';
                }
                field(TextoRecurrencia; Rec.TextoRecurrencia)
                {
                    ApplicationArea = All;
                    ToolTip = 'Resumen de la recurrencia guardada en la tarea.';
                }
                field(RecurrenciaFin; Rec.RecurrenciaFin)
                {
                    ApplicationArea = All;
                    Enabled = Rec.RecurrenciaActiva;
                    ToolTip = 'Fecha límite para generar nuevas ocurrencias. Vacío = sin límite.';
                }
                field(TareaRecurrenteOrigen; Rec.TareaRecurrenteOrigen)
                {
                    ApplicationArea = All;
                    ToolTip = 'Primera tarea de la serie recurrente.';
                }
                field(SiguienteOcurrenciaCreada; Rec.SiguienteOcurrenciaCreada)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si ya se generó la siguiente ocurrencia al finalizar esta tarea.';
                }
            }
            group(Aviso)
            {
                Caption = 'Aviso por correo';

                field(Avisar; Rec.Avisar)
                {
                    ApplicationArea = All;
                    ToolTip = 'Envía un correo al responsable el día de aviso (cola GTask).';
                }
                field(DiasAntesAviso; Rec.DiasAntesAviso)
                {
                    ApplicationArea = All;
                    Enabled = Rec.Avisar;
                    ToolTip = 'Número de días antes del vencimiento en que se enviará el aviso.';
                }
                field(FechaAviso; Rec.FechaAviso)
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha calculada en la que se enviará el correo de aviso.';
                }
                field(AvisoEnviado; Rec.AvisoEnviado)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si ya se envió el aviso para esta ocurrencia.';
                }
            }
            group(CamposCopiados)
            {
                Caption = 'Campos que se copian a la siguiente ocurrencia';

                field(Categoria; Rec."Categoría")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Departamento; Rec.Departamento)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Servicio; Rec.Servicio)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(ZonaLimpieza; Rec.ZonaLimpieza)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(TipoTarea; Rec.TipoTarea)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Guardar)
            {
                ApplicationArea = All;
                Caption = 'Guardar';
                Image = Save;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if Rec.RecurrenciaActiva and (Format(Rec.FormulaRecurrencia) = '') then
                        Error('Indique la fórmula de recurrencia (por ejemplo 1W, 1M).');
                    Rec.ActualizarFechaAviso();
                    Rec.Modify(true);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ActualizarFechaAviso();
    end;
}
