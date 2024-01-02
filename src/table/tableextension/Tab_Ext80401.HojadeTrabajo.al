/// <summary>
/// TableExtension Hoja de Trabajo (ID 92401) extends Record Time Sheet Header.
/// </summary>
tableextension 92401 "Hoja de Trabajo" extends "Time Sheet Header"
{
    Caption = 'Hoja de Trabajo';

    fields
    {

        field(80002; Cliente; Code[20])
        {
            Caption = 'Cliente';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                Customer.get(Cliente);
                "Nombre Cliente" := Customer.Name;
                "Dirección" := Customer.Address;
            end;
        }
        field(80003; "Nombre Cliente"; Text[50])
        {
            Caption = 'Nombre Cliente';
            DataClassification = ToBeClassified;
        }
        field(80004; "Dirección"; Text[50])
        {
            Caption = 'Dirección';
            DataClassification = ToBeClassified;
        }
        field(80005; "Cód. Dirección Envio"; Code[20])
        {
            Caption = 'Cód. Dirección Envio';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                Dir: Record 222;
            begin
                if "Cód. Dirección Envio" <> '' then begin
                    Dir.Get(Cliente, "Cód. Dirección Envio");
                    "Dirección Envio" := Dir.Address;
                end else
                    "Dirección Envio" := '';
            end;
        }
        field(80006; "Dirección Envio"; Text[50])
        {
            Caption = 'Dirección Envio';
            DataClassification = ToBeClassified;
        }
        field(80007; Proyecto; Code[20])
        {
            Caption = 'Proyecto';
            DataClassification = ToBeClassified;
        }
        field(80008; "Fecha Inicio"; Date)
        {
            Caption = 'Fecha Inicio';
            DataClassification = ToBeClassified;
        }
        field(80009; "Fecha Fin"; Date)
        {
            Caption = 'Fecha Fin';
            DataClassification = ToBeClassified;
        }
        field(80010; Tarea; Integer)
        {
            TableRelation = "User Task".ID;
        }
        field(80011; "Producto Servicio"; code[20])
        {
            TableRelation = Resource where(Type = const(Machine));
            trigger OnValidate()
            var
                ProductoServicio: Record "Resource";
            begin
                ifProductoServicio.Get("Producto Servicio") then
                    "Descripción producto" := ProductoServicio.Name;
            end;
        }
        field(80012; "Descripción producto"; Text[80])
        {
            Editable = false;
        }
    }


}
