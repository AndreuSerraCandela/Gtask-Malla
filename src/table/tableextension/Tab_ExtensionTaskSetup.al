// tableextension 92404 "Tab_ExtensionTaskSetup" extends "User Setup"
// {
//     fields
//     {
//         field(50100; "Departamento"; Text[50])
//         { }
//         field(50101; "Responsable"; Boolean)
//         { }
//         field(50102; "Supervisor"; Boolean)
//         { }

//     }
// }

tableextension 92500 "Tab_ExtensionTaskSetup2" extends "Jobs Setup"
{
    fields
    {
        field(50110; "Incidencias Nos."; Code[20])
        {
            Caption = 'Incidencias Nos.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
    }
}