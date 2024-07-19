pageextension 92153 UserTaskGroupMembers extends "User Task Group Members"
{
    layout
    {
        addlast(Group)
        {

            field("Responsable"; Rec."Responsable")
            {
                ApplicationArea = All;
            }
            field("Supervisor"; Rec."Supervisor")
            {
                ApplicationArea = All;
            }


        }
        addfirst("Group")
        {
            field("Nombre"; Rec."Nombre")
            {
                ApplicationArea = All;
            }
        }
        modify("User Name")
        {
            Visible = false;
        }

    }
}