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
            OptionMembers = " ",Producto,Recurso,Trabajo,Nacional;
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
            if (Tipo = const(Recurso)) Resource
            else
            if (Tipo = const(Nacional)) Resource where ("Producción"= const(true));
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                Item: Record Item;
                Resource: Record Resource;
            begin
                if Item.Get(No) then
                    Descripcion := Item.Description;
                if Resource.Get(No) then
                    Descripcion := Resource.Name;
            end;
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

        field(80009; "Job Line No."; Integer)
        {
            Caption = 'Job Line No.';
            DataClassification = ToBeClassified;
        }
        field(80010; Finalizada; Boolean)
        {
            Caption = 'Finalizada';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                TimeSheetLine: Record "Time Sheet Line";
                Pendientes: Boolean;
            begin
                TimeSheetLine.SetRange("Job No.", "Job No.");
                TimeSheetLine.SetFilter("Job Line No.", '<>%1', "Job Line No.");
                TimeSheetLine.SetRange(Finalizada,  false);
                Pendientes:=false;
                if TimeSheetLine.FindFirst() then repeat
                    If TimeSheetLine."Job Line No."<>-1 then
                        Pendientes:=true;
                until TimeSheetLine.Next() = 0;
                If not Pendientes then begin
                    TimeSheetLine.Reset();
                    TimeSheetLine.SetRange("Job No.", "Job No.");
                    TimeSheetLine.SetRange("Job Line No.",-1);
                    TimeSheetLine.SetRange(Finalizada,  false);
                    if TimeSheetLine.FindFirst() then begin
                        TimeSheetLine.Finalizada := true;
                        TimeSheetLine.Modify();
                    end;
                end;
                
            end;
        }
        field(80011; "Comprobada"; Boolean)
        {
            Caption = 'Comprobada';
            DataClassification = ToBeClassified;
        }
        field(80012; "Enviada"; Boolean)
        {
            Caption = 'Enviada';
            DataClassification = ToBeClassified;
        }
        field(80013; "Fecha Orden"; Date)
        {
            Caption = 'Fecha Orden';
            DataClassification = ToBeClassified;
        }
        field(80014; Formato; Text[20])
        {
            Caption = 'Formato';
            DataClassification = ToBeClassified;
        }
        field(80015; Soportes; Text[30])
        {
            Caption = 'Soportes';
            DataClassification = ToBeClassified;
        }
        field(80016; Recibido; Boolean)
        {
            Caption = 'Recibido';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                if Recibido then
                    "Fecha Recibido" := CurrentDateTime;
            end;
        }
        field(80017; "Fecha Recibido"; DateTime)
        {
            Caption = 'Fecha Recibido';
            DataClassification = ToBeClassified;
        }
        field(80018; "Nº Contrato"; code[20])
        {
            Caption = 'Nº Contrato';
            DataClassification = ToBeClassified;
            TableRelation = "Sales Header"."No.";
        }
    }
    keys
    {
        Key(Nom;"No","Fecha Orden"){}
    }
    trigger OnAfterDelete()
    begin
        If Finalizada then Error('No se puede borrar una línea finalizada');
    end;
    trigger OnAfterModify()
    begin
        If Finalizada then Error('No se puede modificar una línea finalizada');
    end;


}
