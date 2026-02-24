tableextension 92407 ZonasLimpiezaExt extends "Zonas Limpieza"
{
    fields
    {
        field(50000; Responsable; Guid)
        {
            Caption = 'Responsable';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Security ID";
        }
        field(50001; Supervisor; Guid)
        {
            Caption = 'Supervisor';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Security ID";
        }
        field(50002; Categoria; Code[20])
        {
            Caption = 'Categoría';
            DataClassification = ToBeClassified;
            TableRelation = "User Task Group".Code;
        }
        field(50003; Departamento; Text[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center".Code;
        }
        field(50004; Servicio; Text[20])
        {
            Caption = 'Servicio';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center".Code;
        }
        field(50005; "Correos Copia"; Text[1024])
        {
            Caption = 'Correos en copia';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(50006; "Tipo Tarea"; Text[50])
        {
            Caption = 'Tipo de tarea';
            DataClassification = ToBeClassified;
        }
    }
}
