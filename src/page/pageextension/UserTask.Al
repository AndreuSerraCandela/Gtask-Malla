pageextension 92154 "UserTask" extends "User Task card"
{
    layout
    {
        addafter("User Task Group Assigned To")
        {
            field(Job; Rec."Job No.")
            {
                Caption = 'Nº Proyecto';
                ApplicationArea = All;
            }
        }

        addfirst(FactBoxes)
        {
            part(DocumentAttach; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Document Attachment Factbox';
                SubPageLink = "No." = field("No."), "Table ID" = const(Database::"User Task");
            }

        }

    }
}
