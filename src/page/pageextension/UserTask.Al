pageextension 92154 "UserTask" extends "User Task card"
{
    layout
    {
        modify("Assigned To User Name")
        {
            Visible = false;
        }
        addbefore("created by User Name")
        {
            field(Responsable; Rec."Assigned To User Name")
            {
                Caption = 'Responsable';
                ApplicationArea = Basic, Suite;
                DrillDown = false;
                ToolTip = 'Responsable de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record User;
                    Users: Page Users;
                begin
                    if User.Get(Rec."Assigned To") then
                        Users.SetRecord(User);

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate("Assigned To", User."User Security ID");
                        CurrPage.Update(true);
                    end;
                end;

            }
            field(Supervisor; Rec."Supervisor User Name")
            {
                Caption = 'Suipervisor';
                ApplicationArea = Basic, Suite;
                DrillDown = false;
                ToolTip = 'Especifique el supervisor de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record User;
                    Users: Page Users;
                begin
                    if User.Get(Rec."Supervisor") then
                        Users.SetRecord(User);

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate("Supervisor", User."User Security ID");
                        CurrPage.Update(true);
                    end;
                end;

            }
            field(Departamento; Rec.Departamento)
            {
                ApplicationArea = All;
            }
            field(Servicio; Rec.Servicio)
            {
                ApplicationArea = All;
            }
        }
        modify("User Task Group Assigned To")
        {
            Visible = false;

        }
        addafter("User Task Group Assigned To")
        {
            field(Categoria; Rec."User Task Group Assigned To")
            {
                Caption = 'Categoría';
                ApplicationArea = All;
            }
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
                Caption = 'Documentos Adjuntos';
                SubPageLink = "No." = field("No."), "Table ID" = const(Database::"User Task");
            }

        }


    }
}
pageextension 92157 "UserTaskList" extends "User Task List"
{
    layout
    {

        modify("Assigned To User Name")
        {
            Visible = false;
        }
        addbefore("created by User Name")
        {
            field(Responsable; Rec."Assigned To User Name")
            {
                Caption = 'Responsable';
                ApplicationArea = Basic, Suite;
                DrillDown = false;
                ToolTip = 'Responsable de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record User;
                    Users: Page Users;
                begin
                    if User.Get(Rec."Assigned To") then
                        Users.SetRecord(User);

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate("Assigned To", User."User Security ID");
                        CurrPage.Update(true);
                    end;
                end;

            }
            field(Supervisor; Rec."Supervisor User Name")
            {
                Caption = 'Responsable';
                ApplicationArea = Basic, Suite;
                DrillDown = false;
                ToolTip = 'Especifique el supervisor de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record User;
                    Users: Page Users;
                begin
                    if User.Get(Rec."Supervisor") then
                        Users.SetRecord(User);

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate("Supervisor", User."User Security ID");
                        CurrPage.Update(true);
                    end;
                end;

            }
            field(Departamento; Rec.Departamento)
            {
                ApplicationArea = All;
            }
            field(Servicio; Rec.Servicio)
            {
                ApplicationArea = All;
            }
        }
        modify("User Task Group Assigned To")
        {
            Caption = 'Categoría';

        }
        addafter("User Task Group Assigned To")
        {
            field(Job; Rec."Job No.")
            {
                Caption = 'Nº Proyecto';
                ApplicationArea = All;
            }
        }
    }
}
