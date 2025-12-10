pageextension 92153 PurchaseOrderListExt extends "Purchase Order List"
{
    actions
    {
        addafter(Print)
        {

            action("Crear Tarea envio Taller")
            {
                ApplicationArea = All;
                Caption = 'Crear envio diario Parte Producción';
                Image = SendToMultiple;
                ToolTip = 'Crea una tarea para el envío diario de las líneas de produccuón al taller';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line" temporary;
                    PurchaseLineSource: Record "Purchase Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                    Gtask: Codeunit GTask;
                    FileName: Text;
                    Company: Record Company;
                    PurchaseHeader: Record "Purchase Header";
                    JobPlanningLine: Record "Job Planning Line";
                    Job: Record Job;
                    Procesos: Codeunit "Controlprocesos";
                begin
                    If not Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName) then
                        exit;

                    if not Confirm('¿Está seguro de que desea enviar las líneas al taller y crear una tarea?') then
                        exit;

                    // Limpiar tabla temporal
                    PurchaseLine.Reset();
                    PurchaseLine.DeleteAll();

                    // Cargar líneas de todas las empresas
                    Company.FindSet();
                    repeat
                        If Procesos.CompruebaPermisos(UserSecurityId(), 'SUPER', Company.Name) then begin
                            PurchaseLineSource.ChangeCompany(Company.Name);
                            PurchaseHeader.ChangeCompany(Company.Name);
                            JobPlanningLine.ChangeCompany(Company.Name);
                            Job.ChangeCompany(Company.Name);

                            PurchaseLineSource.Reset();
                            PurchaseLineSource.SetRange("Enviado a Taller", true);
                            PurchaseLineSource.SetRange("Validado PB", false);
                            PurchaseLineSource.SetFilter("Line No.", '<>0');
                            PurchaseLineSource.SetFilter(Description, '<>%1', '');

                            if PurchaseLineSource.FindSet() then begin
                                repeat
                                    PurchaseLine.Init();
                                    PurchaseLine := PurchaseLineSource;
                                    PurchaseLine."Empresa" := Company.Name;

                                    // Calcular Fecha Fijación si no está establecida
                                    if PurchaseLine."Fecha Fijación" = 0D then begin
                                        if PurchaseHeader.Get(PurchaseLineSource."Document Type", PurchaseLineSource."Document No.") then begin
                                            JobPlanningLine.SetRange("Job No.", PurchaseHeader."Nº Proyecto");
                                            JobPlanningLine.SetRange("Job Task No.", PurchaseLineSource."Job Task No.");
                                            JobPlanningLine.SetRange("Line No.", PurchaseLineSource."Linea de proyecto");
                                            if JobPlanningLine.FindFirst() then
                                                PurchaseLine."Fecha Fijación" := JobPlanningLine."Planning Date"
                                            else begin
                                                JobPlanningLine.Reset();
                                                JobPlanningLine.SetRange("Job No.", PurchaseHeader."Nº Proyecto");
                                                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
                                                if JobPlanningLine.FindFirst() then
                                                    PurchaseLine."Fecha Fijación" := JobPlanningLine."Planning Date";
                                            end;
                                        end;
                                    end;
                                    PurchaseLine.Insert();
                                until PurchaseLineSource.Next() = 0;
                            end;
                        end;
                    until Company.Next() = 0;

                    LineCount := PurchaseLine.Count();

                    if LineCount > 0 then begin
                        FileName := GenerarExcelLineasTaller(PurchaseLine);
                        CrearTareaTaller(PurchaseLine, LineCount, FileName, true);

                        // Generar Excel y enviar correo


                        Message('Se han enviado %1 líneas al taller. Se ha creado una tarea y enviado el correo.', LineCount);
                    end else
                        Message('No se encontraron líneas para enviar al taller.');
                end;
            }
        }
        addafter(Print_Promoted)
        {
            actionref(CrearTareaEnvioTaller; "Crear Tarea envio Taller")
            {
            }
        }
    }
    local procedure CrearTareaTaller(PurchaseLine: Record "Purchase Line"; LineCount: Integer; FileName: Text; EnvioLineas: Boolean)
    var
        Gtask: Codeunit GTask;
        RecRef: RecordRef;


    begin
        // Contar líneas enviadas al taller

        if (LineCount > 0) and (EnvioLineas) then begin
            RecRef.GetTable(PurchaseLine);
            Gtask.CrearTarea(RecRef,
                'PARTE DE PRODUCCIÓN ' + Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>'),
                'TALLER', 'COMPRAS',
                'Seguimiento Recepciones',
                'RECEPCIONES', true, FileName, '.xlsx');
        end else begin
            if not EnvioLineas then begin
                RecRef.GetTable(PurchaseLine);
                Gtask.CrearTarea(RecRef,
                    'Orden de trabajo ' + Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>'),
                    'TALLER', 'COMPRAS',
                    'Tareas Talles',
                    'PRODUCCION', false, '', '');
            end;
        end;
    end;

    local procedure GenerarExcelLineasTaller(var PurchaseLine: Record "Purchase Line" temporary): Text
    var
        ExcelBuffer: Record "Excel Buffer";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
        Base64Content: Text;
        RowNo: Integer;
        Base64: Codeunit "Base64 Convert";
        // Variables de formato para AddColumn
        // AddColumn(Value, IsFormula, CommentText, IsBold, IsItalics, IsUnderline, NumFormat, CellType)
        EsFormula: Boolean;
        TextoComentario: Text;
        EsNegrita: Boolean;
        EsCursiva: Boolean;
        EsSubrayado: Boolean;
        FormatoNumero: Text[30];
        TipoCelda: Option Number,Text,Date,Time;
        NoAnterior: Code[20];
        PrimeraLinea: Boolean;
    begin
        FileName := 'Lineas_Taller_' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>') + '.xlsx';

        // Configuración de formato para encabezados
        EsFormula := false;
        TextoComentario := '';
        EsNegrita := true;
        EsCursiva := false;
        EsSubrayado := false;
        FormatoNumero := '';
        TipoCelda := ExcelBuffer."Cell Type"::Text;

        // Limpiar ExcelBuffer
        ExcelBuffer.DeleteAll();

        // Crear encabezados
        // AddColumn(Value, IsFormula, CommentText, IsBold, IsItalics, IsUnderline, NumFormat, CellType)
        RowNo := 1;
        ExcelBuffer.NewRow();
        //ExcelBuffer.AddColumn('Tipo Documento', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
        ExcelBuffer.AddColumn('Nombre Proveedor', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
        ExcelBuffer.AddColumn('Nº Documento', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
        ExcelBuffer.AddColumn('Cantidad', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);//Qunatity
        ExcelBuffer.AddColumn('Formato', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);//Descripcion
        ExcelBuffer.AddColumn('Campaña', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);//Description Proyecto
        ExcelBuffer.AddColumn('Fecha Pedido', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); //FechaPedido
        ExcelBuffer.AddColumn('Fecha Fijación', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
        ExcelBuffer.AddColumn('Fecha de Recepción', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);

        ExcelBuffer.AddColumn('Validar Cantidad recibida', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
        ExcelBuffer.AddColumn('Cantidad Recibida', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);//Cantidad Recibida
        ExcelBuffer.AddColumn('Observaciones', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);

        // Configuración de formato para datos (sin negrita)
        EsNegrita := false;
        EsCursiva := false;
        EsSubrayado := false;
        //sorting(Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Expected Receipt Date");
        PurchaseLine.SetCurrentKey(Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Expected Receipt Date");

        NoAnterior := '';

        if PurchaseLine.FindSet() then begin
            repeat
                // Si cambió el campo "No.", insertar línea separadora con solo Formato
                if (PurchaseLine."No." <> NoAnterior) then begin
                    RowNo += 1;
                    ExcelBuffer.NewRow();
                    // Línea separadora: solo Formato (Description) en la columna correspondiente
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Nombre Proveedor
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Nº Documento
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Cantidad
                    ExcelBuffer.AddColumn(Formato(PurchaseLine), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Formato
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Campaña
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Fecha Pedido
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Fecha Fijación
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Fecha de Recepción
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Validar Cantidad recibida
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Cantidad Recibida
                    ExcelBuffer.AddColumn('', EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda); // Observaciones
                end;

                RowNo += 1;
                ExcelBuffer.NewRow();
                // AddColumn(Value, IsFormula, CommentText, IsBold, IsItalics, IsUnderline, NumFormat, CellType)
                // Orden debe coincidir exactamente con la cabecera
                ExcelBuffer.AddColumn(NombreProveedor(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Empresa"), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(PurchaseLine."Document No.", EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(Format(PurchaseLine.Quantity), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(PurchaseLine.Description, EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(DescriptionProyecto(PurchaseLine), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(Format(FechaPedido(PurchaseLine), 0, 4), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Fecha Fijación", 0, 4), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Requested Receipt Date", 0, 4), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Validar Cantidad recibida"), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Cantidad Recibida"), EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);
                ExcelBuffer.AddColumn(PurchaseLine."Observaciones", EsFormula, TextoComentario, EsNegrita, EsCursiva, EsSubrayado, FormatoNumero, TipoCelda);

                NoAnterior := PurchaseLine."No.";

            until PurchaseLine.Next() = 0;
        end;

        // Crear archivo Excel
        ExcelBuffer.CreateNewBook('Lineas_Taller');
        ExcelBuffer.WriteSheet('Lineas_Taller', CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.SetFriendlyFilename(FileName);
        TempBlob.CreateOutStream(OutStream);
        ExcelBuffer.SaveToStream(OutStream, true);
        TempBlob.CreateInStream(InStream);
        Base64Content := Base64.ToBase64(InStream);

        exit(Base64Content);
    end;

    local procedure NombreProveedor(VendorNo: Code[20]; Empresa: Text[30]): Text[100]
    var
        Vendor: Record Vendor;
        Procesos: Codeunit "Controlprocesos";
    begin
        If Procesos.CompruebaPermisos(UserSecurityId(), 'SUPER', Empresa) then Exit('');
        if Empresa <> '' then
            Vendor.ChangeCompany(Empresa);
        If Vendor.Get(VendorNo) then
            exit(Vendor.Name);
        exit('');
    end;

    local procedure DescriptionProyecto(PurchaseLine: Record "Purchase Line"): Text
    var
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        Procesos: Codeunit "Controlprocesos";
    begin
        If Procesos.CompruebaPermisos(UserSecurityId(), 'SUPER', PurchaseLine."Empresa") then Exit('');
        PurchaseHeader.ChangeCompany(PurchaseLine."Empresa");
        Job.ChangeCompany(PurchaseLine."Empresa");
        If not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then exit('');
        if Job.Get(PurchaseHeader."Nº Proyecto") then
            exit(Job.Description)
        else
            exit('');
    end;

    local procedure EstadoFirmaContrato(PurchaseLine: Record "Purchase Line"): Text
    var
        Contrato: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Procesos: Codeunit "Controlprocesos";
    begin
        If Procesos.CompruebaPermisos(UserSecurityId(), 'SUPER', PurchaseLine."Empresa") then Exit('');
        PurchaseHeader.ChangeCompany(PurchaseLine."Empresa");
        Contrato.ChangeCompany(PurchaseLine."Empresa");
        If not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then exit('');
        Contrato.SetRange("Nº Proyecto", PurchaseHeader."Nº Proyecto");
        if Contrato.FindFirst() then
            exit(Format(Contrato."Estado"))
        else
            exit('');
    end;

    local procedure FechaPedido(var PurchaseLine: Record "Purchase Line"): date
    var
        PurchaseHeader: Record "Purchase Header";
        Procesos: Codeunit "Controlprocesos";

    begin
        If Procesos.CompruebaPermisos(UserSecurityId(), 'SUPER', PurchaseLine."Empresa") then Exit(Today);
        PurchaseHeader.ChangeCompany(PurchaseLine."Empresa");
        if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit(PurchaseHeader."Order Date")
        else
            exit(Today);
    end;

    local procedure Formato(var PurchaseLine: Record "Purchase Line" temporary): Text
    var
        Resource: Record Resource;
        Procesos: Codeunit "Controlprocesos";
    begin
        If Procesos.CompruebaPermisos(UserSecurityId(), 'SUPER', PurchaseLine."Empresa") then Exit('');
        If PurchaseLine.Empresa <> '' then
            Resource.ChangeCompany(PurchaseLine."Empresa");
        If Resource.Get(PurchaseLine."No.") then
            exit(Resource.Name)
        else
            exit(PurchaseLine.Description);
    end;
}