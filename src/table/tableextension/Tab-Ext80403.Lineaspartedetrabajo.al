/// <summary>
/// TableExtension Lineas parte de trabajo (ID 890403) extends Record Time Sheet Line.
/// </summary>
tableextension 92403 "Lineas parte de trabajo" extends "Time Sheet Line"
{
    Caption = 'Lineas parte de trabajo';

    fields
    {

        field(80003; Tipo; Option)
        {
            OptionMembers = " ",Producto,Recurso;
            Caption = 'Tipo';
            DataClassification = ToBeClassified;
        }
        field(80004; No; Code[20])
        {
            Caption = 'No';
            DataClassification = ToBeClassified;
            TableRelation = IF (Tipo = CONST(" ")) "Standard Text"
            ELSE
            IF (Tipo = CONST(Producto)) Item WHERE(Blocked = CONST(false))
            ELSE
            if (Tipo = const(Recurso)) Resource;
        }
        field(80005; Descripcion; Text[80])
        {
            Caption = 'Descripcion';
            DataClassification = ToBeClassified;
        }
        field(80006; Unidad; Code[20])
        {
            Caption = 'Unidad';
            DataClassification = ToBeClassified;
        }
        field(80007; Cantidad; Decimal)
        {
            Caption = 'Cantidad';
            DataClassification = ToBeClassified;
        }
    }


}
