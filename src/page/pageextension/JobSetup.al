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
                field("Responsable Taller"; Rec."Responsable Taller")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}