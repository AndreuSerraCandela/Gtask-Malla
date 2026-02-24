/// <summary>
/// PageExtension JobSetupTask (ID 90150) extends Record Jobs Setup.
/// </summary>
pageextension 92150 JobSetupTask extends "Jobs Setup"
{
    layout
    {
        addafter("Job Nos.")
        {
            field("Incidencias Nos."; Rec."Incidencias Nos.")
            {
                ApplicationArea = All;
            }
        }
        addlast(content)
        {

            group(Task)
            {
                field("Crear Subtareas"; Rec."Crear subtareas")
                {
                    ApplicationArea = All;
                }

            }
            group("Tareas Limpieza Paradas Bus")
            {
                Caption = 'Tareas Limpieza Paradas Bus';
                field("Periodicidad Zona Crítica"; Rec."Periodicidad Zona Crítica")
                {
                    ApplicationArea = All;
                    ToolTip = 'Periodicidad de las tareas de limpieza en zona crítica (ej: 1D, 1W).';
                }
                field("Periodicidad Zona No Crítica"; Rec."Periodicidad Zona No Crítica")
                {
                    ApplicationArea = All;
                    ToolTip = 'Periodicidad de las tareas de limpieza en zona no crítica.';
                }
            }
            group("Debug")
            {
                field("Es Debug"; Rec."Es Debug")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}