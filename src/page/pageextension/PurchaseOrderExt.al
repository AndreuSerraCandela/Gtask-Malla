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
                Caption = 'Preparar Líneas para Taller';
                Image = SendTo;
                ToolTip = 'Marca las líneas seleccionadas como enviadas al taller';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    PurchaseHeader: Record "Purchase Header";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                begin
                    Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName);

                    if not Confirm('¿Está seguro de que desea marcar las líneas seleccionadas como enviadas al taller?') then
                        exit;

                    PurchaseLine.SetRange("Document Type", Rec."Document Type");
                    PurchaseLine.SetRange("Document No.", Rec."No.");
                    PurchaseLine.SetRange("Enviado a Taller", false);
                    PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
                    PurchaseLine.SetRange("Validado PB", false);

                    if PurchaseLine.FindSet() then begin
                        repeat
                            if Not PurchaseLine."Enviado a Taller" then begin
                                LineCount += 1;
                                PurchaseLine."Enviado a Taller" := true;
                                PurchaseHeader.ChangeCompany(CompanyName);
                                if PurchaseHeader.Get(Rec."Document Type", Rec."No.") then
                                    PurchaseLine."Fecha Inclusión" := PurchaseHeader."Order Date";
                                PurchaseLine."Empresa" := CompanyName;
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
                    Procesos_GTask: Codeunit Procesos_GTask;
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
                    PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
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
                                        Procesos_GTask.EnviaCorreoComercial('Mercancía Recibida', Contrato, Contrato."Salesperson Code", true, 'Mercancía Recibida', '');
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


            // action("Crear Tarea Taller")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Crear Tarea Taller';
            //     Image = SendToMultiple;
            //     ToolTip = 'Crea una tarea para el taller';

            //     trigger OnAction()
            //     var
            //         PurchaseLine: Record "Purchase Line";
            //         LineCount: Integer;
            //         Control: Codeunit "Controlprocesos";
            //         Gtask: Codeunit GTask;
            //         FileName: Text;
            //     begin
            //         If not Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName) then
            //             exit;

            //         CrearTareaTaller(PurchaseLine, LineCount, FileName, false);

            //     end;
            // }
            action("Líneas Enviadas Taller")
            {
                ApplicationArea = All;
                Caption = 'Líneas Enviadas al Taller';
                Image = List;
                ToolTip = 'Abre la página de líneas enviadas al taller para entrada de mercancía';
                RunObject = Page "Lineas Enviadas Taller";
            }
            action("Crear Envio a Terceros")
            {
                ApplicationArea = All;
                Caption = 'Crear Envio a terceros';
                Image = SendTo;
                ToolTip = 'Crea una tarea para el proveedor';

                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                    Gtask: Codeunit GTask;
                    FileName: Text;
                    PurchaseHeader: Record "Purchase Header";
                begin

                    If not Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName) then
                        exit;

                    CrearTareaEnvio(PurchaseLine);
                    PurchaseHeader := Rec;
                    CurrPage.SetSelectionFilter(PurchaseHeader);
                    PurchaseHeader.SendRecords();

                end;
            }
            action("Comprobar Estado Contrato")
            {
                ApplicationArea = All;
                Caption = 'Comprobar Estado Contrato';
                Image = CheckList;
                ToolTip = 'Comprueba el estado del contrato';
                trigger OnAction()
                var
                    Contrato: Record "Sales Header";
                    SalesInvoice: Record "Sales Invoice Header";
                    MovCliente: Record "Cust. Ledger Entry";
                    Pagada: Text;
                    TextoMensaje: Text;

                begin
                    Contrato.SetRange("Nº Proyecto", Rec."Nº Proyecto");
                    If Contrato.FindFirst() then begin
                        TextoMensaje := 'El contrato está ' + Format(Contrato."Estado");
                        SalesInvoice.SetRange("Nº Proyecto", Rec."Nº Proyecto");
                        SalesInvoice.SetRange("Prepayment Invoice", true);
                        if SalesInvoice.FindFirst() then begin
                            MovCliente.SetRange("Document No.", SalesInvoice."No.");
                            if MovCliente.FindFirst() then begin
                                if MovCliente.Open Then Pagada := 'Pendiente' else Pagada := 'Pagada';
                                TextoMensaje += ' Se ha creado la factura de prepago y su estado es ' + Pagada;
                            end;
                        end;
                    end;
                    Message(TextoMensaje);
                end;
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

            // actionref(CrearTareaTaller; "Crear Tarea Taller")
            // {
            // }
            actionref(CrearTareaEnvioRef; "Crear Envio a Terceros")
            { }
        }
    }



    local procedure CrearTareaEnvio(PurchaseLine: Record "Purchase Line")
    var
        Gtask: Codeunit GTask;
        RecRef: RecordRef;
        PurcChaseHeader: Record "Purchase Header";
        Tempblob: Codeunit "Temp Blob";
        Out: OutStream;
        Base64Data: Text;
        AttachmentStream: InStream;
        Base64Convert: Codeunit "Base64 Convert";
        Selecction: Record "Report Selections";
    begin
        // Contar líneas enviadas al taller
        Selecction.SetRange(Usage, Selecction.Usage::"P.Order");
        If not Selecction.FindFirst() then exit;
        Recref.GetTable(PurcChaseHeader);
        TempBlob.CreateOutStream(Out);
        REPORT.SaveAs(Selecction."Report ID", '', ReportFormat::Pdf, out, Recref);
        TempBlob.CreateInStream(AttachmentStream);
        Base64Data := Base64Convert.ToBase64(AttachmentStream);
        RecRef.GetTable(PurchaseLine);
        Gtask.CrearTarea(RecRef,
            'Seguimiento Recepciones ' + Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>'),
            'COMPRAS', 'COMPRAS',
            'Seguimiento Recepciones',
            'TERCEROS', true, Base64Data, '.pdf');
        ;
    end;




}