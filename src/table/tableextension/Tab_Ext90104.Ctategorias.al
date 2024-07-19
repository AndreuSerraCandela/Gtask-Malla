tableextension 92104 "User Task Group Members Ext" extends "User Task Group Member"
{
    fields
    {
        //Responsable
        field(50000; "Responsable"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        //Supervisor    
        field(50001; "Supervisor"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(50003; "Nombre"; Code[50])
        {
            CalcFormula = Lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Caption = 'User Name';
            Editable = false;
            FieldClass = FlowField;
        }

    }
}