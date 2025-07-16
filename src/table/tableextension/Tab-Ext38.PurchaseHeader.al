/// <summary>
/// TableExtension Purchase Header (ID 38) extends Record "Purchase Header".
/// </summary>
tableextension 50038 "Purchase Header Ext" extends "Purchase Header"
{
    fields
    {
        field(50000; "Correo Comercial Enviado"; Boolean)
        {
            Caption = 'Correo Comercial Enviado';
            DataClassification = CustomerContent;
            Description = 'Indica si ya se ha enviado el correo de notificación al comercial';
        }
    }
}