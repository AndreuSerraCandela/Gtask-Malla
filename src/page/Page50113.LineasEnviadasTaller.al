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
    SourceTableView = sorting(Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Expected Receipt Date");
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
                    StyleExpr = Color;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº Documento';
                    ToolTip = 'Número del documento de compra';
                    Editable = false;
                    StyleExpr = Color;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº Proveedor';
                    ToolTip = 'Número del proveedor';
                    Editable = false;
                    StyleExpr = Color;
                }
                field("Nombre Proveedor"; NombreProveedor(Rec."Buy-from Vendor No."))
                {
                    ApplicationArea = All;
                    Caption = 'Nombre Proveedor';
                    ToolTip = 'Nombre del proveedor';
                    Editable = false;
                    StyleExpr = Color;
                }
                field("Urgente"; Rec."Urgente")
                {
                    ApplicationArea = All;
                    Caption = 'Urgente';
                    ToolTip = 'Indica si la línea de compra es urgente';
                    Editable = true;
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Urgente" then
                            Color := 'Unfavorable'
                        else
                            Color := 'None';
                        PurchaseLine.ChangeCompany(Rec."Empresa");
                        if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then Exit;
                        PurchaseLine.Validate("Urgente", Rec."Urgente");
                        PurchaseLine.Modify();
                    end;
                }
                field("Fecha Inclusión"; Rec."Fecha Inclusión")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha Pedido';
                    ToolTip = 'Fecha de inclusión de la línea de compra';
                    StyleExpr = Color;
                    Editable = false;
                }
                field("Empresa"; Rec."Empresa")
                {
                    ApplicationArea = All;
                    Caption = 'Empresa';
                    ToolTip = 'Empresa desde la que se envió la línea al taller';
                    Editable = false;
                    StyleExpr = Color;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº Línea';
                    ToolTip = 'Número de línea';
                    Editable = false;
                    StyleExpr = Color;
                    Visible = false;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    Caption = 'Tipo';
                    ToolTip = 'Tipo de línea (Artículo, Cuenta, etc.)';
                    Editable = false;
                    StyleExpr = Color;
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'Nº';
                    ToolTip = 'Número del artículo o cuenta';
                    Editable = false;
                    StyleExpr = Color;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Descripción';
                    ToolTip = 'Descripción del artículo o servicio';
                    Editable = false;
                    StyleExpr = Color;
                }
                field("Description Proyecto"; DescriptionProyecto)
                {
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseHeader: Record "Purchase Header";

                    begin
                        PurchaseHeader.ChangeCompany(Rec."Empresa");
                        if not PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then Exit;
                        PurchaseHeader.Validate("Descripcion Proyecto", Copystr(DescriptionProyecto, 1, MaxStrLen(PurchaseHeader."Descripcion proyecto")));
                        PurchaseHeader.Modify();
                    end;
                }
                field("Estado Firma Contrato"; EstadoFirmaContrato())
                {
                    ApplicationArea = All;
                    Caption = 'Estado Firma Contrato';
                    ToolTip = 'Estado de la firma del contrato';
                    Editable = false;
                    StyleExpr = Color;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Cantidad';
                    ToolTip = 'Cantidad solicitada';
                    Editable = false;
                    StyleExpr = Color;
                }
                field("Validar Cantidad recibida"; Rec."Validar Cantidad recibida")
                {
                    ApplicationArea = All;
                    Caption = 'Validar Cantidad recibida';
                    ToolTip = 'Indica si la línea de compra ha sido validada por la cantidad recibida';
                    Importance = Promoted;
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Validar Cantidad recibida" then begin
                            PurchaseLine.ChangeCompany(Rec."Empresa");
                            if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then Exit;
                            PurchaseLine.Validate("Validar Cantidad recibida", Rec."Validar Cantidad recibida");
                            PurchaseLine.Modify();
                            Rec."Fecha Recepción" := currentdatetime();
                        end;
                    end;
                }
                field("Cantidad Recibida"; Rec."Cantidad Recibida")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Cantidad Recibida';
                    ToolTip = 'Cantidad recibida';
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Validar Cantidad recibida" then begin
                            PurchaseLine.ChangeCompany(Rec."Empresa");
                            if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then Exit;
                            PurchaseLine.Validate("Cantidad Recibida", Rec."Cantidad Recibida");
                            PurchaseLine.Modify();
                            Rec."Cantidad Recibida" := PurchaseLine."Cantidad Recibida";
                            If Rec."Fecha Recepción" = 0DT then Rec."Fecha Recepción" := currentdatetime();
                        end;
                    end;

                }
                field("Fecha Recepción"; Rec."Fecha Recepción")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha de Recepción';
                    ToolTip = 'Fecha de recepción';
                    Editable = false;
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Fecha Recepción" <> 0DT then begin
                            PurchaseLine.ChangeCompany(Rec."Empresa");
                            if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then Exit;
                            PurchaseLine.Validate("Fecha Recepción", Rec."Fecha Recepción");
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
                    StyleExpr = Color;
                    Visible = false;
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
                    StyleExpr = Color;
                }
                field("Validado PB"; Rec."Validado PB")
                {
                    ApplicationArea = All;
                    Caption = 'Validado PB';
                    ToolTip = 'Indica si la línea ha sido validada por PB';
                    Editable = false;
                    StyleExpr = Color;
                }

                field("Observaciones"; Rec."Observaciones")
                {
                    ApplicationArea = All;
                    Caption = 'Observaciones';
                    ToolTip = 'Observaciones de la línea de compra';
                    Editable = true;
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Observaciones" <> '' then begin
                            PurchaseLine.ChangeCompany(Rec."Empresa");
                            if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then Exit;
                            PurchaseLine.Validate("Observaciones", Rec."Observaciones");
                            PurchaseLine.Modify();
                        end;
                    end;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha Recepción Esperada';
                    ToolTip = 'Fecha esperada de recepción';
                    Editable = false;
                    StyleExpr = Color;
                }

                field("Fecha Fijación"; Rec."Fecha Fijación")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha Fijación';
                    ToolTip = 'Fecha de fijación de la línea de compra';
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Fecha Fijación" <> 0D then begin
                            PurchaseLine.ChangeCompany(Rec."Empresa");
                            if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then Exit;
                            PurchaseLine.Validate("Fecha Fijación", Rec."Fecha Fijación");
                            PurchaseLine.Modify();
                        end;
                    end;
                }



                field("Produccion Relacionada"; Rec."Produccion Relacionada")
                {
                    ApplicationArea = All;
                    Caption = 'Produccion Relacionada/Orden Trabajo';
                    ToolTip = 'Indica si la línea de compra es produccion relacionada/orden trabajo';
                    Editable = true;
                    StyleExpr = Color;
                    trigger OnValidate()
                    var
                        PurchaseLine: Record "Purchase Line";
                    begin
                        if Rec."Produccion Relacionada" then
                            Rec."Produccion Relacionada" := true;
                        //Color azul
                        If Rec."Produccion Relacionada" then
                            Color := 'Favorable'
                        else
                            Color := 'Standard';
                        PurchaseLine.ChangeCompany(Rec."Empresa");
                        if not PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then Exit;
                        PurchaseLine.Validate("Produccion Relacionada", Rec."Produccion Relacionada");
                        PurchaseLine.Modify();
                    end;
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
                Caption = 'Validar Seleccionadas PB';
                Image = Approve;
                ToolTip = 'Marca las líneas seleccionadas como validadas por PB';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                    Gtask: Codeunit GTask;
                    Procesos_GTask: Codeunit Procesos_GTask;
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
                                PurchaseLine.ChangeCompany(Rec."Empresa");
                                If PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then begin
                                    PurchaseLine.Validate("Validado PB", true);
                                    PurchaseLine.Modify();

                                    PurchaseHeader.ChangeCompany(Rec."Empresa");
                                    PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                                    if not PurchaseHeader."Correo Comercial Enviado" then begin
                                        if PurchaseHeader."Nº Proyecto" <> '' then begin
                                            Contrato.ChangeCompany(Rec."Empresa");
                                            Contrato.SetRange("Nº Proyecto", PurchaseHeader."Nº Proyecto");
                                            if Contrato.FindFirst() then begin
                                                Procesos_GTask.EnviaCorreoComercial('Mercancía Recibida', Contrato, Contrato."Salesperson Code", true, 'Mercancía Recibida', '');
                                            end;
                                        end;
                                        // Marcar como enviado
                                        PurchaseHeader."Correo Comercial Enviado" := true;
                                        PurchaseHeader.Modify();
                                    end;
                                    LineCount += 1;
                                end;
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
                                PurchaseLine.ChangeCompany(Rec."Empresa");
                                PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.");
                                PurchaseLine.Validate("Validar Cantidad recibida", true);
                                PurchaseLine.Modify();
                                LineCount += 1;
                                Rec."Validar Cantidad recibida" := true;
                                Rec.Modify();
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
            action("Quitar de la lista")
            {
                ApplicationArea = All;
                Caption = 'Quitar de la lista';
                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                begin
                    CurrPage.SetSelectionFilter(PurchaseLine);
                    if PurchaseLine.FindSet() then begin
                        repeat
                            PurchaseLine.ChangeCompany(Rec."Empresa");
                            PurchaseLine."Enviado a Taller" := false;
                            PurchaseLine."Validado PB" := false;
                            PurchaseLine."Validar Cantidad recibida" := false;
                            PurchaseLine.Modify();
                            If Rec.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then
                                Rec.Delete();
                        until PurchaseLine.Next() = 0;
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CargarLineas();
    end;

    var
        DescriptionProyecto: Text;
        Color: Text;

    trigger OnAfterGetRecord()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if Rec."Urgente" then
            Color := 'Unfavorable'
        else
            Color := 'Standard';
        if Rec."Produccion Relacionada" then
            Color := 'Favorable';
        PurchaseHeader.ChangeCompany(Rec."Empresa");
        If PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") Then
            DescriptionProyecto := PurchaseHeader."Descripcion proyecto"
        else
            DescriptionProyecto := '';

    end;

    local procedure NombreProveedor(VendorNo: Code[20]): Text[100]
    var
        Vendor: Record Vendor;
    begin
        Vendor.ChangeCompany(Rec."Empresa");
        If Vendor.Get(VendorNo) then
            exit(Vendor.Name);
    end;

    local procedure CargarLineas()
    var
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        Company: Record Company;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        Company.FindSet();
        repeat
            PurchaseLine.ChangeCompany(Company.Name);
            PurchaseHeader.ChangeCompany(Company.Name);
            JobPlanningLine.ChangeCompany(Company.Name);
            Job.ChangeCompany(Company.Name);

            PurchaseLine.Reset();
            PurchaseLine.SetRange("Enviado a Taller", true);
            PurchaseLine.SetRange("Validado PB", false);
            PurchaseLine.SetFilter("Line No.", '<>0');
            PurchaseLine.SetFilter(Description, '<>%1', '');

            if PurchaseLine.FindSet() then begin
                repeat
                    Rec.Init();
                    Rec := PurchaseLine;
                    if Rec."Fecha Fijación" = 0D then begin
                        if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then begin
                            JobPlanningLine.SetRange("Job No.", PurchaseHeader."Nº Proyecto");
                            JobPlanningLine.SetRange("Job Task No.", PurchaseLine."Job Task No.");
                            JobPlanningLine.SetRange("Line No.", PurchaseLine."Linea de proyecto");
                            if JobPlanningLine.FindFirst() then
                                Rec."Fecha Fijación" := JobPlanningLine."Planning Date"
                            else begin
                                JobPlanningLine.Reset();
                                JobPlanningLine.SetRange("Job No.", PurchaseHeader."Nº Proyecto");
                                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
                                if JobPlanningLine.FindFirst() then
                                    Rec."Fecha Fijación" := JobPlanningLine."Planning Date";
                            end;
                        end;
                    end;
                    Rec.Insert();
                until PurchaseLine.Next() = 0;
            end;
        until Company.Next() = 0;

        CurrPage.Update(false);
    end;

    // local procedure DescriptionProyecto(): Text
    // var
    //     Job: Record Job;
    //     PurchaseHeader: Record "Purchase Header";
    // begin
    //     PurchaseHeader.ChangeCompany(Rec."Empresa");
    //     Job.ChangeCompany(Rec."Empresa");
    //     If not PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then exit('');
    //     if Job.Get(PurchaseHeader."Nº Proyecto") then
    //         exit(Job.Description)
    //     else
    //         exit('');
    // end;

    local procedure EstadoFirmaContrato(): Text
    var
        Contrato: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.ChangeCompany(Rec."Empresa");
        Contrato.ChangeCompany(Rec."Empresa");
        If not PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then exit('');
        Contrato.SetRange("Nº Proyecto", PurchaseHeader."Nº Proyecto");
        if Contrato.FindFirst() then
            exit(Format(Contrato."Estado"))
        else
            exit('');

    end;
}