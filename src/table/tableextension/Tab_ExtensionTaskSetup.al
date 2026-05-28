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
        field(50111; "Peticiones Nos."; Code[20])
        {
            Caption = 'Nº Órdenes trabajo';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(50112; "Periodicidad Zona Crítica"; DateFormula)
        {
            Caption = 'Periodicidad Zona Crítica';
            DataClassification = CustomerContent;
        }
        field(50113; "Periodicidad Zona No Crítica"; DateFormula)
        {
            Caption = 'Periodicidad Zona No Crítica';
            DataClassification = CustomerContent;
        }
        // Es debug
        field(50114; "Es Debug"; Boolean)
        {
            Caption = 'Es Debug';
            DataClassification = CustomerContent;
        }
        //Cliente EMT x defecto
        field(50115; "Cliente EMT x defecto"; Code[20])
        {
            Caption = 'Cliente EMT x defecto';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
        }
        field(50116; "Plantilla Opis"; Code[20])
        {
            Caption = 'Plantilla Opis';
            TableRelation = "Time Sheet Header"."No." where("Es Plantilla" = const(true));
            DataClassification = CustomerContent;
        }
        field(50117; "Plantilla Vallas"; Code[20])
        {
            Caption = 'Plantilla Vallas';
            TableRelation = "Time Sheet Header"."No." where("Es Plantilla" = const(true));
            DataClassification = CustomerContent;
        }
        field(50118; "Plantilla Otros"; Code[20])
        {
            Caption = 'Plantilla Otros';
            TableRelation = "Time Sheet Header"."No." where("Es Plantilla" = const(true));
            DataClassification = CustomerContent;
        }
    }
}