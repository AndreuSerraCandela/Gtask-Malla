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
        //Apellido
        field(9; "Apellido"; Text[250])
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
        field(50005; Tecnico; Code[20])
        {
            TableRelation = "Salesperson/Purchaser"."Code";
        }
        field(50006; "Id Usuario Limpieza EMT"; Integer)
        {
            DataClassification = ToBeClassified;
            ObsoleteState = Removed;
        }
        field(50007; "Teléfono"; Text[30])
        {
            Caption = 'Teléfono';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(50008; "Empleado"; Code[20])
        {
            Caption = 'Nº empleado';
            DataClassification = ToBeClassified;
            TableRelation = Employee."No.";
            trigger OnValidate()
            var
                Employee: Record Employee;
            begin
                if not Employee.Get(Employee."No.") then
                    Exit;
                Employee.UserGtask := Rec."Id Gtask";
            end;

        }
        field(50009; "Usuario EMT"; Text[100])
        {
            Caption = 'Usuario EMT';
            DataClassification = ToBeClassified;
        }
        field(50010; Grupo; Code[20])
        {
            Caption = 'Grupo';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                Procesos_GTask: Codeunit Procesos_GTask;
            begin
                // Pasar Grupo en memoria: en OnValidate aún no está guardado en BD.
                Procesos_GTask.ActualizarGruposTareasExistentes("Id Usuario", Grupo);
            end;
        }
        field(50011; "Puede crear dosieres"; Boolean)
        {
            Caption = 'Puede crear dosieres';
            DataClassification = CustomerContent;
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
