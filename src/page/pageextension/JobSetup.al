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
            field("Peticiones Nos."; Rec."Peticiones Nos.")
            {
                ApplicationArea = All;
                ToolTip = 'Serie numérica para órdenes de trabajo. Las incidencias normales usan Incidencias Nos.';
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
                field("Cliente EMT x defecto"; Rec."Cliente EMT x defecto")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cliente EMT x defecto';
                }
            }
            group("Plantillas Mantenimiento")
            {
                Caption = 'Plantillas mantenimiento';

                field("Plantilla Opis"; Rec."Plantilla Opis")
                {
                    ApplicationArea = All;
                    ToolTip = 'Parte plantilla por defecto para emplazamientos Opis (paradas bus / EMT) si el tipo de recurso no tiene plantilla propia.';
                }
                field("Plantilla Vallas"; Rec."Plantilla Vallas")
                {
                    ApplicationArea = All;
                    ToolTip = 'Parte plantilla por defecto para emplazamientos Vallas.';
                }
                field("Plantilla Otros"; Rec."Plantilla Otros")
                {
                    ApplicationArea = All;
                    ToolTip = 'Parte plantilla por defecto para emplazamientos Otros.';
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

    actions
    {
        addlast(processing)
        {
            action(AbrirPartesPlantilla)
            {
                ApplicationArea = All;
                Caption = 'Partes plantilla';
                Image = Template;
                RunObject = page "Partes Plantilla";
                ToolTip = 'Mantiene las cabeceras de parte marcadas como plantilla.';
            }
        }
    }
}