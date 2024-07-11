pageextension 90120 Fijacion extends "Ficha Orden Fijacion"
{
    actions
    {
        addafter("Imprimir Orden Otros")
        {
            action("Crear Tarea")
            {
                Image = "Task";
                ApplicationArea = All;
                Caption = 'Crear Tarea';
                trigger OnAction()
                var
                    TipoOrden: Label 'Vallas,Opis,Otros';
                    rDet: Record "Orden fijación";
                    Resource: Record "Resource";
                    Opcion: Integer;
                    Usertask: Record "User Task";
                    Proyecto: Record "Job";
                    TipoIncidencia: Record "User Task Group";
                    Gtask: Codeunit "Gtask";
                    TM: Record "Tenant Media";
                    DoccAttach: Record "Document Attachment";
                    Outstr: OutStream;
                    RecRef: RecordRef;
                    InStr: InStream;
                    Imagenes: Record "Imagenes Orden fijación";
                    im: Record "Imagenes Orden fijación";
                    Rep: Report "Etiqueta orden fijacion Opis";
                    Rep2: Report "Etiqueta fijacion soportes";
                    User: Record User;
                begin
                    rDet.Setrange("Nº Orden", Rec."Nº Orden");
                    If rDet.FindFirst() then begin
                        Resource.Get(rDet."Nº Recurso");
                        Opcion := 3;
                        If Resource."Tipo Recurso" in ['VALLA', 'VALLAS'] then
                            Opcion := 1;
                        if Resource."Tipo Recurso" in ['OPI', 'OPIS'] then
                            Opcion := 2;
                        Opcion := StrMenu(TipoOrden, 1, 'Seleccione el tipo de tarea a crear');
                    end;
                    Opcion := StrMenu(TipoOrden, Opcion, 'Seleccione el tipo de tarea a crear');
                    Usertask.Init();
                    Proyecto.Get(rDet."Nº proyecto");
                    if Proyecto."Nombre Comercial" = Proyecto."Bill-to Name" then Proyecto."Nombre Comercial" := '';
                    UserTask.Validate(Title, Proyecto.Description);
                    UserTask.SetDescription('Fijación soportes ' + Rec."Nº proyecto" + ' del cliente ' + Proyecto."Bill-to Name" + ' ' + Proyecto."Nombre Comercial");
                    UserTask."Created By" := UserSecurityId();
                    UserTask.Validate("Created DateTime", CurrentDateTime);
                    User.SetRange("Contact Email", 'juangarau@malla.es');
                    User.FindFirst();
                    UserTask.Validate("Assigned To", User."User Security ID");
                    User.SetRange("Contact Email", 'villena@malla.es');
                    User.FindFirst();
                    UserTask.Validate("Supervisor", User."User Security ID");
                    if not TipoIncidencia.Get('FIJACION') then begin
                        TipoIncidencia.Init();
                        TipoIncidencia."Code" := 'FIJACION';
                        TipoIncidencia."Description" := 'Fijación';
                        TipoIncidencia.Insert();

                    end;
                    UserTask.Validate("User Task Group Assigned To", 'FIJACION');
                    UserTask.Validate(Priority, Usertask.Priority::High);
                    UserTask.Validate("Object Type", Usertask."Object Type"::Page);
                    UserTask.Validate("Object ID", Page::"Ficha Orden Fijacion");
                    UserTask.Validate("Due DateTime", CreateDateTime(Rec."Fecha fijación", 080000T));
                    Usertask."No." := Format(Rec."Nº Orden");
                    UserTask.Insert(true);
                    //Inserto los report
                    If Opcion = 1 then begin
                        DoccAttach.Init();
                        DoccAttach."Table ID" := Database::"Cab Orden fijación";
                        DoccAttach."No." := Format(Rec."Nº Orden");


                        TM.Init();
                        TM.ID := CreateGuid();
                        TM.Description := StrSubstNo('Signature %1', format(CurrentDateTime));
                        TM."Mime Type" := 'Pdf/pdf';
                        TM."Company Name" := COMPANYNAME;
                        TM."File Name" := TM.Description + '.pdf';
                        TM.Height := 250;
                        TM.Width := 250;
                        TM.CalcFields(Content);
                        TM.Content.CreateOutStream(Outstr);
                        RecRef.GetTable(Rec);
                        ;
                        Report.SaveAs(Report::"Etiqueta orden fijacion Vallas", '', ReportFormat::Pdf, Outstr, RecRef);
                        TM.Insert();
                        tm.CalcFields(Content);
                        Tm.Content.CreateInStream(InStr);
                        DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                        DoccAttach.Insert();
                        tm.Delete();
                    end;
                    if Opcion = 2 then begin
                        Imagenes.SETRANGE("Nº Orden", Rec."Nº Orden");
                        If Imagenes.FINDSET THEN
                            repeat
                                im.SetRange("Nº Orden", Imagenes."Nº Orden");
                                im.SetRange("Nº Imagen", Imagenes."Nº Imagen");
                                clear(rep);
                                Rep.Filtra(Imagenes."Nº Orden", Imagenes."Nº Imagen");
                                rep.SetTableView(im);


                                DoccAttach.Init();
                                DoccAttach."Table ID" := Database::"Cab Orden fijación";
                                DoccAttach."No." := Format(Rec."Nº Orden");
                                DoccAttach."Line No." := Imagenes."Nº Imagen";
                                Clear(TM);

                                TM.Init();
                                TM.ID := CreateGuid();
                                TM.Description := StrSubstNo('Signature %1', format(CurrentDateTime));
                                TM."Mime Type" := 'Pdf/pdf';
                                TM."Company Name" := COMPANYNAME;
                                TM."File Name" := TM.Description + '.pdf';
                                TM.Height := 250;
                                TM.Width := 250;
                                TM.CalcFields(Content);
                                TM.Content.CreateOutStream(Outstr);
                                RecRef.GetTable(Rec);
                                Rep.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                                TM.Insert();
                                tm.CalcFields(Content);
                                Tm.Content.CreateInStream(InStr);
                                DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                                DoccAttach.Insert();
                                tm.Delete();
                            until Imagenes.NEXT = 0;
                    end;
                    if Opcion = 3 then begin
                        DoccAttach.Init();
                        DoccAttach."Table ID" := Database::"Cab Orden fijación";
                        DoccAttach."No." := Format(Rec."Nº Orden");
                        DoccAttach."Line No." := 0;
                        Clear(TM);
                        TM.Init();
                        TM.ID := CreateGuid();
                        TM.Description := StrSubstNo('Signature %1', format(CurrentDateTime));
                        TM."Mime Type" := 'Pdf/pdf';
                        TM."Company Name" := COMPANYNAME;
                        TM."File Name" := TM.Description + '.pdf';
                        TM.Height := 250;
                        TM.Width := 250;
                        TM.CalcFields(Content);
                        TM.Content.CreateOutStream(Outstr);
                        RecRef.GetTable(Rec);
                        Proyecto.GET(Rec."Nº Proyecto");
                        rDet.SETRANGE("Nº Orden", Rec."Nº Orden");
                        rDet.FindFirst();
                        Resource.GET(rDet."Nº Recurso");
                        Rep2.CargaObservaciones(Proyecto.Description, Resource.Medidas);
                        Rep2.SetTableView(Rec);
                        Rep2.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                        TM.Insert();
                        tm.CalcFields(Content);
                        Tm.Content.CreateInStream(InStr);
                        DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                        DoccAttach.Insert();
                        tm.Delete();
                    end;

                    Clear(Gtask);
                    Gtask.CrearTareaMedios(Rec, Usertask);
                end;
            }
        }
    }
    procedure EnviaCorreoComercial(
       Var UserTask: Record "User Task";
       Adjunto: Boolean;
       Estado: Enum "Estado Firma Electrónica";
       Motivo: Text;
       Notificacion: Boolean;
       Asunto: Text;
       SendTo: Text;
       CC: Text;
       BCC: Text)


    var
        Mail: Codeunit Mail;
        Body: Text;
        Customer: Record 18;
        BigText: Text;
        REmail: Record "Email Item" temporary;
        emilesc: Enum "Email Scenario";
        rInf: Record "Company Information";
        Funciones: Codeunit "Funciones Correo PDF";
        AttachmentStream: InStream;
        out: OutStream;
        Secuencia: Integer;
        ficheros: Record "Document Attachment";
        SalesHeader: Record "Sales Header";
        Recref: RecordRef;
        base64: Text;
        Cbase64: Codeunit "Base64 Convert";
        OutStream: OutStream;
        Tempblob: Codeunit "Temp Blob";
    begin
        rInf.Get();

        If Notificacion Then begin
            BigText := Motivo;
        end else begin
            BigText := ('Estimado:');
            BigText := BigText + '<br> </br>';
            BigText := BigText + '<br> </br>';
            BigText := BigText + ('Se ha generado la Tarea: <b>' + UserTask.GetDescription() + ' </b> ');
            BigText := BigText + (', ha cambiado de estado a: <b>' + Format(Estado) + ' .</b>');
            if Motivo <> '' then
                BigText := BigText + ('<br> </br>' + 'Motivo: ' + Motivo);

            BigText := BigText + '<br> </br>';
        end;

        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Aprovechamos la ocasión para enviarte un cordial saludo');
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Atentamente');
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Dpto. Medios');
        BigText := BigText + '<br> </br>';

        BigText := BigText + (rInf.Name);
        //"Plaintext Formatted":=TRUE;
        // SendMsg.AppendBody(BigText);
        // CLEAR(BigText);
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<img src="emailFoot.png" />';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" sice=2 color=Blue>';
        BigText := BigText + ('<b>SI NO DESEA RECIBIR MAS INFORMACION, CONTESTE ESTE E-MAIL INDICANDOLO EXPRESAMENTE</b>');
        BigText := BigText + '</font>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" size=1 color=Blue>';
        BigText := BigText + ('Según la LOPD 15/199, su dirección de correo electrónico junto a los demás datos personales');
        BigText := BigText + (' que Ud. nos ha facilitado, constan en un fichero titularidad de ');
        BigText := BigText + (rInf.Name + ', cuyas finalidades son mantener la');
        BigText := BigText + (' gestión de las comunicaciones con sus clientes y con aquellas personas que solicitan');
        BigText := BigText + (' información, así como la gestión y atención de los correos entrantes o sugerencias que');
        BigText := BigText + (' se formulen a través de esta cuenta derivados de su actividad. Podrá ejercitar los derechos');
        BigText := BigText + (' de acceso, cancelación, rectificación y oposición,  dirigiéndose, por escrito a ');
        BigText := BigText + (rInf.Name + ' . ' + rInf.Address + '. ' + rInf."Post Code" + '. ' + rInf.City + '. España');

        BigText := BigText + '<br> </br>';
        //SendMsg.AppendBody(BigText);
        //CLEAR(BigText);
        BigText := BigText + ('Este correo y sus archivos asociados son privados y confidenciales y va');
        BigText := BigText + (' dirigido exclusivamente a su destinatario. Si recibe este correo sin ser');
        BigText := BigText + (' el destinatario del mismo, le rogamos proceda a su eliminación y lo ponga');
        BigText := BigText + (' en conocimiento del emisor. La difusión por cualquier medio del contenido de este');
        BigText := BigText + (' correo podría ser sancionada conforme a lo previsto en las leyes españolas. ');
        BigText := BigText + ('No se autoriza la utilización con fines comerciales o para su incorporación a ficheros');
        BigText := BigText + (' automatizados de las direcciones del emisor o del destinatario.');
        BigText := BigText + '</font>';
        //REmail.Subject := 'Pago contrato ' + NContrato;
        REmail.AddAttachment(Funciones.CargaPie(), 'emailfoot.png');
        REmail.Subject := Asunto;
        REmail."Send To" := SendTo;
        if CC <> '' then
            REmail."Send CC" := CC;
        if BCC <> '' then
            REmail."Send BCC" := BCC;
        REmail.SetBodyText(BigText);
        REmail."From Name" := UserId;
        If Adjunto then begin

            // If Contratostemp.FindFirst() then
            //     repeat
            ficheros.SetRange("Table ID", Database::"Cab Orden fijación");
            ficheros.SetRange("No.", UserTask."No.");
            If ficheros.FindLast() then
                repeat
                    base64 := ficheros.ToBase64StringOcr(ficheros.url);
                    Clear(Cbase64);
                    Tempblob.CreateOutStream(OutStream);
                    Cbase64.FromBase64(base64, OutStream);
                    Tempblob.CreateInStream(AttachmentStream);
                    REmail.AddAttachment(AttachmentStream, ficheros."File Name");
                until ficheros.Next() = 0;
        end;
        if REmail.Send(true, emilesc::Notification) then begin

        end;
    end;

}