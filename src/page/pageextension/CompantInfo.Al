/// <summary>
/// PageExtension CompantInfo (ID 80205) extends Record Company Information.
/// </summary>
pageextension 92151 CompantInfoTask extends "Company Information"
{
    layout
    {
        addlast(content)
        {
            group(Task)
            {
                field("Url Task"; Rec."Url Task")
                {
                    ApplicationArea = All;
                    Caption = 'Url Task';
                    ToolTip = 'Url Task';
                }
                field("Usuario Task"; Rec."Usuario Task")
                {
                    ApplicationArea = All;
                    Caption = 'Usuario Task';
                    ToolTip = 'Usuario Task';
                }
                field("Password Task"; Rec."Password Task")
                {
                    ApplicationArea = All;
                    Caption = 'Password Task';
                    ToolTip = 'Password Task';
                }
            }

        }


    }
    var
        Permisos: Boolean;
        EmpPer: Boolean;

    trigger OnAfterGetRecord()
    var
        rMem: Record "Access Control";
        Application: Record "Application Area";
    begin
        EmpPer := false;
        Application.SetRange("Company Name", CompanyName);
        If Application.FindFirst() Then EmpPer := Application.BasicHR;
        rMem.SetRange("User Security ID", UserSecurityId());
        rMem.SetRange("Role ID", 'ESP');
        Permisos := rMem.FindFirst();
    end;

}