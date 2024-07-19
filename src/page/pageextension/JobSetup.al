/// <summary>
/// PageExtension JobSetupTask (ID 90150) extends Record Jobs Setup.
/// </summary>
pageextension 92150 JobSetupTask extends "Jobs Setup"
{
    layout
    {
        addlast(content)
        {
            group(Task)
            {
                field("Crear Subtareas"; Rec."Crear subtareas")
                {
                    ApplicationArea = All;
                }

            }
        }
    }
}