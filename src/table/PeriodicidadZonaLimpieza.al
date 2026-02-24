table 7001251 "Periodicidad Zona Limpieza"
{
    Caption = 'Periodicidad Zona Limpieza';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id Zona Limpieza"; Integer)
        {
            Caption = 'Id Zona Limpieza';
            DataClassification = ToBeClassified;
            TableRelation = "Zonas Limpieza".Id;
        }
        field(2; "Línea"; Integer)
        {
            Caption = 'Línea';
            DataClassification = ToBeClassified;
        }
        field(10; "Tipo Periodicidad"; Enum "Tipo Periodicidad Limpieza")
        {
            Caption = 'Tipo periodicidad';
            DataClassification = ToBeClassified;
        }
        field(11; "Día Semana"; Enum "Día Semana Limpieza")
        {
            Caption = 'Día de la semana';
            DataClassification = ToBeClassified;
        }
        field(12; "Día del mes"; Integer)
        {
            Caption = 'Día del mes (1-31)';
            DataClassification = ToBeClassified;
            MinValue = 0;
            MaxValue = 31;
        }
        field(13; Temporada; Enum "Temporada Limpieza")
        {
            Caption = 'Temporada';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Id Zona Limpieza", "Línea")
        {
            Clustered = true;
        }
    }
}
