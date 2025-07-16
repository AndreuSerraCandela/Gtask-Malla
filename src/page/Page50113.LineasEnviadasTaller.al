/// <summary>
/// Page Lineas Enviadas Taller (ID 50113)
/// </summary>
page 50113 "Lineas Enviadas Taller"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Líneas Enviadas al Taller';
    CardPageId = "Purchase Order";
    SourceTable = "Purchase Line";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Tipo Documento';
                    ToolTip = 'Tipo de documento de compra';
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº Documento';
                    ToolTip = 'Número del documento de compra';
                    Editable = false;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº Proveedor';
                    ToolTip = 'Número del proveedor';
                    Editable = false;
                }
                field("Nombre Proveedor"; NombreProveedor(Rec."Buy-from Vendor No."))
                {
                    ApplicationArea = All;
                    Caption = 'Nombre Proveedor';
                    ToolTip = 'Nombre del proveedor';
                    Editable = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº Línea';
                    ToolTip = 'Número de línea';
                    Editable = false;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    Caption = 'Tipo';
                    ToolTip = 'Tipo de línea (Artículo, Cuenta, etc.)';
                    Editable = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº';
                    ToolTip = 'Número del artículo o cuenta';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Descripción';
                    ToolTip = 'Descripción del artículo o servicio';
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Cantidad';
                    ToolTip = 'Cantidad solicitada';
                    Editable = false;
                }
                field("Validar Cantidad recibida"; Rec."Validar Cantidad recibida")
                {
                    ApplicationArea = All;
                    Caption = 'Validar Cantidad recibida';
                    ToolTip = 'Indica si la línea de compra ha sido validada por la cantidad recibida';
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Validar Cantidad recibida" then begin
                            PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.");
                            PurchaseLine.Validate("Validar Cantidad recibida", Rec."Validar Cantidad recibida");
                            PurchaseLine.Modify();
                        end;
                    end;
                }
                field("Qty. to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = All;
                    Caption = 'Cantidad a Recibir';
                    ToolTip = 'Cantidad a recibir';
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Validar Cantidad recibida" then begin
                            PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.");
                            PurchaseLine.Validate("Qty. to Receive", Rec."Qty. to Receive");
                            PurchaseLine.Modify();
                        end;
                    end;

                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Código U.M.';
                    ToolTip = 'Código de unidad de medida';
                    Editable = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Coste Unitario Directo';
                    ToolTip = 'Coste unitario directo';
                    Editable = false;
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Importe Línea';
                    ToolTip = 'Importe total de la línea';
                    Editable = false;
                    Visible = false;
                }
                field("Enviado a Taller"; Rec."Enviado a Taller")
                {
                    ApplicationArea = All;
                    Caption = 'Enviado a Taller';
                    ToolTip = 'Indica si la línea ha sido enviada al taller';
                    Editable = false;
                }
                field("Validado PB"; Rec."Validado PB")
                {
                    ApplicationArea = All;
                    Caption = 'Validado PB';
                    ToolTip = 'Indica si la línea ha sido validada por PB';
                    Editable = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha Recepción Esperada';
                    ToolTip = 'Fecha esperada de recepción';
                    Editable = false;
                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Cargar Líneas")
            {
                ApplicationArea = All;
                Caption = 'Cargar Líneas';
                Image = Refresh;
                ToolTip = 'Carga las líneas enviadas al taller pero no validadas';

                trigger OnAction()
                begin
                    CargarLineas();
                end;
            }

            action("Validar Seleccionadas")
            {
                ApplicationArea = All;
                Caption = 'Validar Seleccionadas';
                Image = Approve;
                ToolTip = 'Marca las líneas seleccionadas como validadas por PB';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                    Gtask: Codeunit GTask;
                    Contrato: Record "Sales Header";
                    PurchaseHeader: Record "Purchase Header";
                begin
                    If not Control.CompruebaPermisos(UserSecurityId(), 'VALIDARPB', CompanyName) then
                        exit;

                    if not Confirm('¿Está seguro de que desea marcar las líneas seleccionadas como validadas por PB?') then
                        exit;

                    LineCount := 0;
                    if Rec.FindSet() then begin
                        repeat
                            if Rec."Enviado a Taller" and not Rec."Validado PB" then begin
                                PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.");
                                PurchaseLine.Validate("Validado PB", true);
                                PurchaseLine.Modify();
                                PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                                if not PurchaseHeader."Correo Comercial Enviado" then begin
                                    if PurchaseHeader."Nº Proyecto" <> '' then begin
                                        Contrato.SetRange("Nº Proyecto", PurchaseHeader."Nº Proyecto");
                                        if Contrato.FindFirst() then begin
                                            Gtask.EnviaCorreoComercial('Mercancía Recibida', Contrato, Contrato."Salesperson Code", true, 'Mercancía Recibida', '');
                                        end;
                                    end;
                                    // Marcar como enviado
                                    PurchaseHeader."Correo Comercial Enviado" := true;
                                    PurchaseHeader.Modify();
                                end;
                                LineCount += 1;
                            end;
                        until Rec.Next() = 0;
                    end;

                    if LineCount > 0 then begin
                        Message('Se han validado %1 líneas por PB.', LineCount);
                        CargarLineas(); // Recargar la lista
                    end else
                        Message('No se encontraron líneas para validar.');
                end;
            }

            action("Crear Entrada Mercancía")
            {
                ApplicationArea = All;
                Caption = 'Crear Entrada Mercancía';
                Image = CreateDocument;
                ToolTip = 'Crea una entrada de mercancía para las líneas seleccionadas';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                    PurchaseLine: Record "Purchase Line";
                    LineCount: Integer;
                begin
                    if not Confirm('¿Está seguro de que desea crear entradas de mercancía para las líneas seleccionadas?') then
                        exit;

                    LineCount := 0;
                    if Rec.FindSet() then begin
                        repeat
                            if Rec."Enviado a Taller" and not Rec."Validado PB" then begin
                                // Aquí iría la lógica para crear la entrada de mercancía
                                // Por ahora solo marcamos como validada
                                PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.");
                                PurchaseLine.Validate("Validar Cantidad recibida", true);
                                PurchaseLine.Modify();
                                LineCount += 1;
                            end;
                        until Rec.Next() = 0;
                    end;

                    if LineCount > 0 then begin
                        Message('Se han procesado %1 líneas para entrada de mercancía.', LineCount);
                        CargarLineas(); // Recargar la lista
                    end else
                        Message('No se encontraron líneas para procesar.');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CargarLineas();
    end;

    local procedure NombreProveedor(VendorNo: Code[20]): Text[100]
    var
        Vendor: Record Vendor;
    begin
        If Vendor.Get(VendorNo) then
            exit(Vendor.Name);
    end;

    local procedure CargarLineas()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        PurchaseLine.SetRange("Enviado a Taller", true);
        PurchaseLine.SetRange("Validado PB", false);
        PurchaseLine.SetFilter("Line No.", '<>0');

        if PurchaseLine.FindSet() then begin
            repeat
                Rec.Init();
                Rec := PurchaseLine;
                Rec.Insert();
            until PurchaseLine.Next() = 0;
        end;

        CurrPage.Update(false);
    end;
}