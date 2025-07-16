/// <summary>
/// PageExtension Purchase Order (ID 930) extends Record "Purchase Order".
/// </summary>
pageextension 92170 "Purchase Order Ext" extends "Purchase Order"
{
    actions
    {
        addafter("&Print")
        {
            action("Enviar Líneas a Taller")
            {
                ApplicationArea = All;
                Caption = 'Enviar Líneas a Taller';
                Image = SendTo;
                ToolTip = 'Marca las líneas seleccionadas como enviadas al taller';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                begin
                    Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName);

                    if not Confirm('¿Está seguro de que desea marcar las líneas seleccionadas como enviadas al taller?') then
                        exit;

                    PurchaseLine.SetRange("Document Type", Rec."Document Type");
                    PurchaseLine.SetRange("Document No.", Rec."No.");
                    PurchaseLine.SetRange("Enviado a Taller", false);
                    PurchaseLine.SetRange("Validado PB", false);

                    if PurchaseLine.FindSet() then begin
                        repeat
                            if Not PurchaseLine."Enviado a Taller" then begin
                                LineCount += 1;
                                PurchaseLine."Enviado a Taller" := true;
                                PurchaseLine.Modify();
                            end;
                        until PurchaseLine.Next() = 0;

                        if LineCount > 0 then
                            Message('Se han marcado %1 líneas como enviadas al taller.', LineCount)
                        else
                            Message('No se encontraron líneas para marcar como enviadas al taller.');
                    end;
                end;
            }

            action("Validar Líneas PB")
            {
                ApplicationArea = All;
                Caption = 'Validar Líneas PB';
                Image = Approve;
                ToolTip = 'Marca las líneas seleccionadas como validadas por PB';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                    Gtask: Codeunit GTask;
                    Job: Record Job;
                    EmailSubject: Text;
                    EmailBody: Text;
                    ComercialEmail: Text;
                    ComercialName: Text;
                    Contrato: Record "Sales Header";
                begin
                    If not Control.CompruebaPermisos(UserSecurityId(), 'VALIDARPB', CompanyName) then
                        exit;

                    if not Confirm('¿Está seguro de que desea marcar las líneas seleccionadas como validadas por PB?') then
                        exit;

                    PurchaseLine.SetRange("Document Type", Rec."Document Type");
                    PurchaseLine.SetRange("Document No.", Rec."No.");
                    PurchaseLine.SetFilter("Line No.", '<>0');

                    if PurchaseLine.FindSet() then begin
                        repeat
                            if not PurchaseLine."Validado PB" then begin
                                LineCount += 1;
                                PurchaseLine."Validado PB" := true;

                                PurchaseLine.Modify();
                            end;
                        until PurchaseLine.Next() = 0;

                        if LineCount > 0 then begin
                            // Enviar correo al comercial solo si es la primera vez
                            if not Rec."Correo Comercial Enviado" then begin
                                if Rec."Nº Proyecto" <> '' then begin
                                    Contrato.SetRange("Nº Proyecto", Rec."Nº Proyecto");
                                    if Contrato.FindFirst() then begin
                                        Gtask.EnviaCorreoComercial('Mercancía Recibida', Contrato, Contrato."Salesperson Code", true, 'Mercancía Recibida', '');
                                    end;
                                end;
                                // Marcar como enviado
                                Rec."Correo Comercial Enviado" := true;
                                Rec.Modify();
                            end;
                        end;

                        Message('Se han marcado %1 líneas como validadas por PB.', LineCount);
                    end else
                        Message('Todas las líneas ya están validadas por PB.');
                end;
            }

            action("Crear Tarea envio Taller")
            {
                ApplicationArea = All;
                Caption = 'Crear Tarea envio Taller';
                Image = SendToMultiple;
                ToolTip = 'Crea una tarea para el envío de las líneas al taller';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                    Gtask: Codeunit GTask;
                    FileName: Text;
                begin
                    If not Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName) then
                        exit;

                    if not Confirm('¿Está seguro de que desea enviar las líneas al taller y crear una tarea?') then
                        exit;

                    PurchaseLine.SetRange("Enviado a Taller", true);
                    PurchaseLine.SetRange("Validado PB", false);
                    LineCount := PurchaseLine.Count();

                    if LineCount > 0 then begin
                        FileName := GenerarExcelLineasTaller(PurchaseLine);
                        CrearTareaTaller(PurchaseLine, LineCount, FileName);

                        // Generar Excel y enviar correo


                        Message('Se han enviado %1 líneas al taller. Se ha creado una tarea y enviado el correo.', LineCount);
                    end else
                        Message('No se encontraron líneas para enviar al taller.');
                end;
            }

            action("Líneas Enviadas Taller")
            {
                ApplicationArea = All;
                Caption = 'Líneas Enviadas al Taller';
                Image = List;
                ToolTip = 'Abre la página de líneas enviadas al taller para entrada de mercancía';
                RunObject = Page "Lineas Enviadas Taller";
            }




        }
        addafter("&Print_Promoted")
        {
            actionref(EnviarLíneasATaller; "Enviar Líneas a Taller")
            {
            }
            actionref(ValidarLíneasPB; "Validar Líneas PB")
            {
            }
            actionref(LíneasEnviadasTaller; "Líneas Enviadas Taller")
            {
            }
            actionref(CrearTareaEnvioTaller; "Crear Tarea envio Taller")
            {
            }
        }
    }

    local procedure CrearTareaTaller(PurchaseLine: Record "Purchase Line"; LineCount: Integer; FileName: Text)
    var
        Gtask: Codeunit GTask;
        RecRef: RecordRef;


    begin
        // Contar líneas enviadas al taller

        if LineCount > 0 then begin
            RecRef.GetTable(PurchaseLine);
            Gtask.CrearTarea(RecRef,
                'Seguimiento Recepciones ' + Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>'),
                'TALLER', 'COMPRAS',
                'Seguimiento Recepciones',
                'RECEPCIONES', true, FileName, '.xlsx');
        end;
    end;

    local procedure GenerarExcelLineasTaller(var PurchaseLine: Record "Purchase Line"): Text
    var
        ExcelBuffer: Record "Excel Buffer";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
        Base64Content: Text;
        RowNo: Integer;
        Base64: Codeunit "Base64 Convert";
    begin
        FileName := 'Lineas_Taller_' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>') + '.xlsx';

        // Limpiar ExcelBuffer
        ExcelBuffer.DeleteAll();

        // Crear encabezados
        RowNo := 1;
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Tipo Documento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Nº Documento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Nº Línea', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Tipo', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Nº Artículo', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Descripción', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Cantidad', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('U.M.', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Proveedor', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Enviado a Taller', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Validado PB', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);


        if PurchaseLine.FindSet() then begin
            repeat
                RowNo += 1;
                ExcelBuffer.NewRow();
                ExcelBuffer.AddColumn(Format(PurchaseLine."Document Type"), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(PurchaseLine."Document No.", false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Line No."), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Type"), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(PurchaseLine."No.", false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(PurchaseLine.Description, false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(PurchaseLine.Quantity), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(PurchaseLine."Unit of Measure Code", false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(PurchaseLine."Buy-from Vendor No.", false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Enviado a Taller"), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(PurchaseLine."Validado PB"), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
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


}