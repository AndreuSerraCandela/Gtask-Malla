page 50120 "Ordenes Trabajo"
{
    PageType = Card;
    Caption = 'Orden de trabajo';
    SourceTable = "Incidencias";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(Incidencia)
            {
                Caption = 'Petición';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Descripción Ampliada"; Description)
                {
                    MultiLine = true;
                    Caption = 'Descripción Ampliada';

                    ExtendedDatatype = RichContent;
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec.SetWorkDescription(description);
                    end;
                }
                field("Parte Trabajo"; Rec."Parte Trabajo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número del parte / orden de trabajo EMT vinculado a la petición.';
                }


            }
            group(Orden)
            {
                Caption = 'Orden EMT';
                Visible = OrdenExiste;

                field("No. Orden"; TimeSheetHeader."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Cliente; TimeSheetHeader.Cliente)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Nombre Cliente"; TimeSheetHeader."Nombre Cliente")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Starting Date"; "StartingDate")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        TimeSheetHeader.Validate("Starting Date", StartingDate);
                    end;
                }
                field("Ending Date"; "EndingDate")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        TimeSheetHeader.Validate("Ending Date", EndingDate);
                    end;
                }
                field("Estado orden"; Estado)
                {
                    Caption = 'Estado orden';
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnValidate()
                    begin
                        TimeSheetHeader.Validate(Estado, Estado);
                    end;

                }
            }
            part(Lines; "Líneas Parte de Trabajo")
            {
                ApplicationArea = All;
                SubPageLink = "Time Sheet No." = field("Parte Trabajo");
            }
        }
        area(factboxes)
        {
            part(Documentos; "Doc. Attachment List FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(Database::"Time Sheet Header"), "No." = field("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImprimirOrden)
            {
                ApplicationArea = All;
                Caption = 'Imprimir';
                Image = Print;
                ToolTip = 'Imprime la orden de trabajo (parte EMT y líneas).';

                trigger OnAction()
                var
                    TimeSheetLine: Record "Time Sheet Line";
                begin
                    Rec.TestField("Parte Trabajo");
                    TimeSheetLine.SetRange("Time Sheet No.", Rec."Parte Trabajo");
                    Report.RunModal(Report::"Ordenes Trabajo", true, false, TimeSheetLine);
                end;
            }
            action(Facturar)
            {
                ApplicationArea = All;
                Caption = 'Facturar';
                Image = Invoice;
                ToolTip = 'Crea y registra la factura de venta desde las líneas del parte y marca la orden como facturada.';

                trigger OnAction()
                begin
                    FacturarOrdenEMT();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ImprimirOrden_Promoted; ImprimirOrden)
            {
            }
            actionref(Facturar_Promoted; Facturar) { }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CargarCabeceraOrden();
    end;

    trigger OnAfterGetRecord()
    var
        Usuario: Record UsuariosGtask;
    begin
        Description := Rec.GetWorkDescription();
        If not IsNullGuid(Rec.Usuario) then begin
            Usuario.SetRange("Id Usuario", Rec.Usuario);
            If Usuario.FindFirst() then begin
                NombreUsuario := Usuario.Nombre + ' ' + Usuario.Apellido;
            end;
        end;

    end;

    var
        Description: Text;
        NombreUsuario: Text;

    trigger OnModifyRecord(): Boolean
    begin
        CargarCabeceraOrden();
        exit(true);
    end;

    var
        TimeSheetHeader: Record "Time Sheet Header";
        OrdenExiste: Boolean;
        StartingDate: Date;
        EndingDate: Date;
        Estado: Option " ",Abierto,Cerrado,Facturado;

    local procedure CargarCabeceraOrden()
    var

    begin

        OrdenExiste := false;
        Clear(TimeSheetHeader);
        if Rec."Parte Trabajo" <> '' then
            if TimeSheetHeader.Get(Rec."Parte Trabajo") then
                OrdenExiste := true;
        StartingDate := TimeSheetHeader."Starting Date";
        EndingDate := TimeSheetHeader."Ending Date";
        Estado := TimeSheetHeader.Estado;
    end;

    local procedure FacturarOrdenEMT()
    var
        TSH: Record "Time Sheet Header";
    begin
        Rec.TestField("Parte Trabajo");
        if not TSH.Get(Rec."Parte Trabajo") then
            Error('No existe la orden de trabajo %1.', Rec."Parte Trabajo");
        if TSH.Tipo <> TSH.Tipo::EMT then
            Error('La orden %1 no es de tipo EMT.', TSH."No.");
        if TSH.Estado = TSH.Estado::Facturado then
            Error('La orden %1 ya está marcada como facturada.', TSH."No.");
        if not Confirm('¿Crear factura para la orden %1?', false, TSH."No.") then
            exit;
        TSH.Estado := TSH.Estado::Facturado;
        TSH."Id Factura" := CrearFactura(TSH);
        TSH.Modify(true);
        CargarCabeceraOrden();
        CurrPage.Update(false);
    end;

    local procedure CrearFactura(TSH: Record "Time Sheet Header"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TimeSheetLine: Record "Time Sheet Line";
        Item: Record Item;
        Resource: Record Resource;
        LineNo: Integer;
        Qty: Decimal;
        NroAntesRegistro: Code[20];
    begin
        TSH.TestField(Cliente);
        TimeSheetLine.SetRange("Time Sheet No.", TSH."No.");
        if not TimeSheetLine.FindSet() then
            Error('No hay líneas en el parte %1.', TSH."No.");

        SalesHeader.Init();
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Sell-to Customer No.", TSH.Cliente);
        if TSH."Cód. Dirección Envio" <> '' then
            SalesHeader.Validate("Ship-to Code", TSH."Cód. Dirección Envio");
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Document Date", WorkDate());
        SalesHeader."Your Reference" := CopyStr('Parte ' + TSH."No.", 1, MaxStrLen(SalesHeader."Your Reference"));
        SalesHeader.Insert(true);

        LineNo := 0;
        repeat
            if LineaParteDebeFacturarse(TimeSheetLine) then begin
                Qty := TimeSheetLine.Cantidad;
                if Qty = 0 then
                    Qty := 1;

                LineNo += 10000;
                SalesLine.Init();
                SalesLine.Validate("Document Type", SalesHeader."Document Type");
                SalesLine.Validate("Document No.", SalesHeader."No.");
                SalesLine.Validate("Line No.", LineNo);

                case TimeSheetLine.Tipo of
                    TimeSheetLine.Tipo::Producto:
                        begin
                            if not Item.Get(TimeSheetLine.No) then
                                Error('Producto %1 no encontrado en la línea %2.', TimeSheetLine.No, TimeSheetLine."Line No.");
                            SalesLine.Validate(Type, SalesLine.Type::Item);
                            SalesLine.Validate("No.", TimeSheetLine.No);
                        end;
                    TimeSheetLine.Tipo::Recurso, TimeSheetLine.Tipo::Nacional, TimeSheetLine.Tipo::Trabajo:
                        begin
                            if not Resource.Get(TimeSheetLine.No) then
                                Error('Recurso %1 no encontrado en la línea %2.', TimeSheetLine.No, TimeSheetLine."Line No.");
                            SalesLine.Validate(Type, SalesLine.Type::Resource);
                            SalesLine.Validate("No.", TimeSheetLine.No);
                        end;
                    else
                        if Item.Get(TimeSheetLine.No) then begin
                            SalesLine.Validate(Type, SalesLine.Type::Item);
                            SalesLine.Validate("No.", TimeSheetLine.No);
                        end else
                            if Resource.Get(TimeSheetLine.No) then begin
                                SalesLine.Validate(Type, SalesLine.Type::Resource);
                                SalesLine.Validate("No.", TimeSheetLine.No);
                            end else
                                Error('La línea %1 del parte no tiene tipo reconocible ni código válido.', TimeSheetLine."Line No.");
                end;

                SalesLine.Validate(Quantity, Qty);
                if TimeSheetLine.Descripcion <> '' then
                    SalesLine.Validate(Description, TimeSheetLine.Descripcion);
                if TimeSheetLine.Precio <> 0 then
                    SalesLine.Validate("Unit Price", TimeSheetLine.Precio);
                if TimeSheetLine.Dto <> 0 then
                    SalesLine.Validate("Line Discount %", TimeSheetLine.Dto);

                SalesLine.Insert(true);
            end;
        until TimeSheetLine.Next() = 0;

        if LineNo = 0 then
            Error('No se ha podido crear ninguna línea de factura a partir del parte.');

        NroAntesRegistro := SalesHeader."No.";


        exit(NroAntesRegistro);
    end;

    local procedure LineaParteDebeFacturarse(TimeSheetLine: Record "Time Sheet Line"): Boolean
    begin
        if TimeSheetLine.No = '' then
            exit(false);
        exit(true);
    end;
}
