/// <summary>
/// TableExtension Purchase Line (ID 39) extends Record "Purchase Line".
/// </summary>
tableextension 50039 "Purchase Line Ext" extends "Purchase Line"
{
    fields
    {
        field(50000; "Enviado a Taller"; Boolean)
        {
            Caption = 'Enviado a Taller';
            DataClassification = CustomerContent;
            Description = 'Indica si la línea de compra ha sido enviada al taller';
        }
        field(50001; "Validado PB"; Boolean)
        {
            Caption = 'Validado PB';
            DataClassification = CustomerContent;
            Description = 'Indica si la línea de compra ha sido validada por PB';
        }
        field(50002; "Validar Cantidad recibida"; Boolean)
        {
            Caption = 'Validar Cantidad recibida';
            DataClassification = CustomerContent;
            Description = 'Indica si la línea de compra ha sido validada por la cantidad recibida';
            trigger OnValidate()
            begin
                if "Validar Cantidad recibida" then begin
                    Validate("Qty. to Receive", Quantity - "Quantity Received");
                end;

            end;
        }

    }
}