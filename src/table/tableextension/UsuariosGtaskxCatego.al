tableextension 92404 "User Task Group Member" extends "User Task Group Member"
{
    fields

    // Define your fields here

    {
        modify("User Security ID")
        {
            TableRelation = User."User Security ID";
        }


        field(50000; "Responsable"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        //Supervisor    
        field(50001; "Supervisor"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(50002; "Departamento"; Text[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }
        field(50003; "Usuario"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(50004; "Copiado en Mail"; Boolean)
        {

        }


    }



}
