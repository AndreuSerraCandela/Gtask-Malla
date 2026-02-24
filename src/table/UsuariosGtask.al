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
        field(50005; Tecnico; Code[20])
        {
            TableRelation = "Salesperson/Purchaser"."Code";
        }
        field(50006; "Id Usuario Limpieza EMT"; Integer)
        {
            DataClassification = ToBeClassified;
            ObsoleteState = Removed;
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
