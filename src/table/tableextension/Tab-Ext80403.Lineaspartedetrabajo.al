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
            if (Tipo = const(Nacional)) Resource where("Producción" = const(true));
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                Item: Record Item;
                Resource: Record Resource;

            begin
                if No = '' then
                    exit;
                if Item.Get(No) then
                    Descripcion := Item.Description
                else
                    if Resource.Get(No) then
                        Descripcion := Resource.Name;
                UpdateUnitPriceByField(Rec.FieldNo(No));
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
            trigger OnValidate()
            begin
                Importe := Precio * Cantidad * (1 - Dto / 100);
            end;

        }
        field(80008; Precio; Decimal)
        {
            Caption = 'Precio';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                Importe := Precio * Cantidad * (1 - Dto / 100);
            end;
        }
        //Dto
        field(80009; Dto; Decimal)
        {
            Caption = 'Dto';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                Importe := Precio * Cantidad * (1 - Dto / 100);
            end;
        }
        //importe
        field(80010; Importe; Decimal)
        {
            Caption = 'Importe';
            DataClassification = ToBeClassified;
        }

        field(80011; "Job Line No."; Integer)
        {
            Caption = 'Job Line No.';
            DataClassification = ToBeClassified;
        }
        field(80012; Finalizada; Boolean)
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
                TimeSheetLine.SetRange(Finalizada, false);
                Pendientes := false;
                if TimeSheetLine.FindFirst() then
                    repeat
                        If TimeSheetLine."Job Line No." <> -1 then
                            Pendientes := true;
                    until TimeSheetLine.Next() = 0;
                If not Pendientes then begin
                    TimeSheetLine.Reset();
                    TimeSheetLine.SetRange("Job No.", "Job No.");
                    TimeSheetLine.SetRange("Job Line No.", -1);
                    TimeSheetLine.SetRange(Finalizada, false);
                    if TimeSheetLine.FindFirst() then begin
                        TimeSheetLine.Finalizada := true;
                        TimeSheetLine.Modify();
                    end;
                end;

            end;
        }
        field(80013; "Comprobada"; Boolean)
        {
            Caption = 'Comprobada';
            DataClassification = ToBeClassified;
        }
        field(80014; "Enviada"; Boolean)
        {
            Caption = 'Enviada';
            DataClassification = ToBeClassified;
        }
        field(80015; "Fecha Orden"; Date)
        {
            Caption = 'Fecha Orden';
            DataClassification = ToBeClassified;
        }
        field(80016; Formato; Text[20])
        {
            Caption = 'Formato';
            DataClassification = ToBeClassified;
        }
        field(80017; Soportes; Text[30])
        {
            Caption = 'Soportes';
            DataClassification = ToBeClassified;
        }
        field(80018; Recibido; Boolean)
        {
            Caption = 'Recibido';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                if Recibido then
                    "Fecha Recibido" := CurrentDateTime;
            end;
        }
        field(80019; "Fecha Recibido"; DateTime)
        {
            Caption = 'Fecha Recibido';
            DataClassification = ToBeClassified;
        }
        field(80020; "Nº Contrato"; code[20])
        {
            Caption = 'Nº Contrato';
            DataClassification = ToBeClassified;
            TableRelation = "Sales Header"."No.";
        }
    }
    keys
    {
        Key(Nom; "No", "Fecha Orden") { }
    }
    trigger OnAfterDelete()
    begin
        If Finalizada then Error('No se puede borrar una línea finalizada');
    end;

    trigger OnAfterModify()
    begin
        If Finalizada then Error('No se puede modificar una línea finalizada');
    end;

    procedure UpdateUnitPriceByField(CalledByFieldNo: Integer)
    var
        BlanketOrderSalesLine: Record "Sales Line";
        IsHandled: Boolean;
        PriceCalculation: Interface "Price Calculation";
        PriceType: Enum "Price Type";
    begin

        case Tipo of
            Tipo::Producto,
            Tipo::Recurso:
                begin



                    PriceCalculation.ApplyDiscount();
                    ApplyPrice(CalledByFieldNo, PriceCalculation);

                end;
        end;


    end;

    procedure GetPriceCalculationHandler(PriceType: Enum "Price Type"; var PriceCalculation: Interface "Price Calculation")
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        SalesLine: Record "Sales Line";
    begin
        GetLineWithPrice(LineWithPrice);
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := 'PRUEBA';
        SalesLine."Line No." := 10000;
        Case Rec.Tipo of
            Rec.Tipo::Producto:
                begin
                    SalesLine.Type := SalesLine.Type::Item;
                end;
            Rec.Tipo::Recurso:
                begin
                    SalesLine.Type := SalesLine.Type::Resource;
                end;

        End;
        SalesLine."No." := Rec.No;
        SalesLine.Quantity := Rec.Cantidad;
        LineWithPrice.SetLine(PriceType, SalesLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
    end;

    procedure ApplyPrice(CalledByFieldNo: Integer; var PriceCalculation: Interface "Price Calculation")
    begin
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        GetLineWithCalculatedPrice(PriceCalculation);

    end;

    local procedure GetLineWithCalculatedPrice(var PriceCalculation: Interface "Price Calculation")
    var
        Line: Variant;
        SalesLine: Record "Sales Line";
    begin
        PriceCalculation.GetLine(Line);
        SalesLine := Line;
        Rec.Precio := SalesLine."Unit Price";
        Rec.Dto := SalesLine."Line Discount %";
        Rec.Importe := SalesLine.Amount;
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        LineWithPrice := SalesLinePrice;

    end;

}
