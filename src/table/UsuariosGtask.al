table 7001209 "UsuariosGtask"
{
    DrillDownPageId = UsuariosGtask;
    LookupPageId = UsuariosGtask;
    fields
    {
        // Define your fields here
        //Id usuario
        field(1; "Id Usuario"; Guid)
        {
            DataClassification = ToBeClassified;
            TableRelation = User."User Security ID";
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                User: Record User;
            begin
                if not User.Get(User."User Security ID") then
                    Exit;
                Nombre := User."Full Name";
                Email := User."Contact Email";
            end;
        }
        //Nombre
        field(2; "Nombre"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        //email
        field(3; "Email"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        //ID Gtask
        field(4; "Id Gtask"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        //Departamento
        field(5; Departamento; Text[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }
        //servicio


        //Responsable
        field(6; "Responsable"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        //Supervisor    
        field(7; "Supervisor"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Id Gtask Providsional"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Define your keys here
        key(PK; "Id Gtask")
        {
            Clustered = true;

        }
    }

    // Define your other properties here
}
//Crear page
page 7001184 "UsuariosGtask"
{
    PageType = List;
    SourceTable = UsuariosGtask;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Usuarios Gtask';
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Id Usuario"; Rec."Id Usuario")
                {
                    ApplicationArea = All;
                }
                field("Nombre"; Rec."Nombre")
                {
                    ApplicationArea = All;
                }
                field("Email"; Rec."Email")
                {
                    ApplicationArea = All;
                }
                field("Id Gtask"; Rec."Id Gtask")
                {
                    ApplicationArea = All;
                }
                field("Departamento"; Rec."Departamento")
                {
                    ApplicationArea = All;
                }
                field("Responsable"; Rec."Responsable")
                {
                    ApplicationArea = All;
                }
                field("Supervisor"; Rec."Supervisor")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Crear Usuarios BC")
            {
                ApplicationArea = All;
                Caption = 'Crear Usuarios BC';
                Image = Import;
                trigger OnAction()
                var
                    UsuariosGtask: Record "UsuariosGtask";
                    User: Record User;
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.CreateUsers(UsuariosGtask);
                    Commit();
                    if UsuariosGtask.FindSet() then
                        repeat
                            User.SetRange("Contact Email", UsuariosGtask."Email");
                            If (Not User.FindFirst()) And (not User.Get(UsuariosGtask."Id Usuario")) then begin
                                User.Init();
                                user.Validate("User Name", UsuariosGtask."Nombre");
                                User."User Security ID" := CreateGuid();
                                UsuariosGtask."Id Usuario" := User."User Security ID";
                                User."License Type" := User."License Type"::"External User";
                                User."Full Name" := UsuariosGtask."Nombre";
                                User."Contact Email" := UsuariosGtask."Email";
                                User.Insert(true);
                                UsuariosGtask.Modify(true);
                            end;
                        until usuariosGtask.next = 0;
                end;
            }
        }
    }
}
