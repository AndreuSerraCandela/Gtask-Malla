tableextension 92405 Categorias extends "User Task Group"
{
    fields
    {
        field(92000; "Material Fijación"; enum "Material de Fijación")
        {

        }
        field(62001; "Tipo de Tarea"; Text[20])
        {
            Caption = 'Tipo de Tarea';
            DataClassification = ToBeClassified;
        }
    }
}