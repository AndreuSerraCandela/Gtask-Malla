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
                DrillDown = true;
                ToolTip = 'Responsable de la tarea';


                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.SetRange("Id Usuario", Rec."Assigned To");
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate("Assigned To", User."Id Usuario");
                        CurrPage.Update(true);
                    end;
                end;

            }
            field(Supervisor; Rec."Supervisor User Name")
            {
                Caption = 'Suipervisor';
                ApplicationArea = Basic, Suite;
                DrillDown = true;
                ToolTip = 'Especifique el supervisor de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.SetRange("Id Usuario", Rec.Supervisor);
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate(Supervisor, User."Id Usuario");
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
            field(Categoria; Rec."Categoría")
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
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.SetRange("Id Usuario", Rec."Assigned To");
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate("Assigned To", User."Id Usuario");
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
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.SetRange("Id Usuario", Rec.Supervisor);
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;
                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate(Supervisor, User."Id Usuario");
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
