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
                    "Cantidad Recibida" := Quantity;
                    "Fecha Recepción" := currentdatetime();
                end;

            end;
        }
        field(50004; "Fecha Fijación"; Date)
        {
            Caption = 'Fecha Fijación';
            DataClassification = CustomerContent;
            Description = 'Fecha de fijación de la línea de compra';
        }
        //Observaciones
        field(50005; "Observaciones"; Text[250])
        {
            Caption = 'Observaciones';
            DataClassification = CustomerContent;
            Description = 'Observaciones de la línea de compra';
        }
        field(50006; Urgente; Boolean)
        {
            Caption = 'Urgente';
            DataClassification = CustomerContent;
            Description = 'Indica si la línea de compra es urgente';
        }
        field(50007; "Fecha Inclusión"; Date)
        {
            Caption = 'Fecha Fijación';
            DataClassification = CustomerContent;
            Description = 'Fecha de fijación de la línea de compra';
        }
        field(50008; "Cantidad Recibida"; Decimal)
        {
            Caption = 'Cantidad Recibida';
            DataClassification = CustomerContent;
            Description = 'Cantidad recibida de la línea de compra';
            trigger OnValidate()
            begin
                If "Fecha Recepción" = 0DT then "Fecha Recepción" := currentdatetime();
            end;
        }
        field(50009; "Produccion Relacionada"; Boolean)
        {
            Caption = 'Produccion Relacionada/Orden Trabajo';
            DataClassification = CustomerContent;
            Description = 'Indica si la línea de compra es urgente';
        }
        field(50010; "Empresa"; Text[30])
        {
            Caption = 'Empresa';
            DataClassification = CustomerContent;
            Description = 'Empresa desde la que se envió la línea al taller';
        }
        field(50012; "Fecha Recepción"; DateTime)
        {
            Caption = 'Fecha Recepción';
            DataClassification = CustomerContent;
            Description = 'Fecha de recepción esperada de la línea de compra';
        }
    }
}