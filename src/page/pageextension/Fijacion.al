pageextension 92155 Fijacion extends "Ficha Orden Fijacion"
{
    actions
    {
        addlast(Processing)
        {
            action("Crear Tarea")
            {
                Image = TaskPage;
                ApplicationArea = All;
                Caption = 'Crear Tarea';
                trigger OnAction()
                var
                    TipoOrden: Label 'Vallas,Opis,Otros';
                    rDet: Record "Orden fijación";
                    Cab: Record "Cab Orden fijación";
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
                    EmailResponsable: Text;
                    EmailSupervisor: Text;
                    UserSetups: Record UsuariosGtask;
                begin
                    DoccAttach.SetRange("Table ID", Database::"User Task");
                    DoccAttach.SetRange("No.", Format(Rec."Nº Orden"));
                    DoccAttach.DeleteAll();
                    Usertask.SetRange(OrdenFijacion, Rec."Nº Orden");
                    If Usertask.FindFirst() then
                        Error('Ya existe una tarea para esta orden');
                    UserSetups.SetRange(Departamento, 'TALLER');
                    UserSetups.FindFirst();
                    rDet.Setrange("Nº Orden", Rec."Nº Orden");
                    Opcion := 0;
                    if Rec."Tipo soporte" = Rec."Tipo soporte"::Valla then Opcion := 1;
                    if Rec."Tipo soporte" = Rec."Tipo soporte"::OPI then Opcion := 2;
                    if Rec."Tipo soporte" = Rec."Tipo soporte"::Otros then Opcion := 3;
                    If (rDet.FindFirst()) and (Opcion = 0) then begin
                        Resource.Get(rDet."Nº Recurso");
                        Opcion := 0;
                        If Resource."Tipo Recurso" in ['VALLA', 'VALLAS', 'P.PEATOAL'] then
                            Opcion := 1;
                        if Resource."Tipo Recurso" in ['OPI', 'OPIS', 'LUM1,5X1,1', 'OPI ROT.', 'PLANIMETRO', 'RELOJ'] then
                            Opcion := 2;
                        if Resource."Tipo Recurso" in ['INDICADOR', 'VPEATON', 'MEDIANERA'] then
                            Opcion := 3;
                    end;
                    if Opcion = 0 then
                        Opcion := StrMenu(TipoOrden, Opcion, 'Seleccione el tipo de tarea a crear');
                    Usertask.Init();
                    Proyecto.Get(rDet."Nº proyecto");
                    if Proyecto."Nombre Comercial" = Proyecto."Bill-to Name" then Proyecto."Nombre Comercial" := '';
                    UserTask.Validate(Title, Proyecto.Description);
                    UserTask.SetDescription('Fijación soportes ' + Rec."Nº proyecto" + ' del cliente ' + Proyecto."Bill-to Name" + ' ' + Proyecto."Nombre Comercial");
                    UserTask."Created By" := UserSecurityId();
                    UserTask.Validate("Created DateTime", CurrentDateTime);
                    Usertask."Start DateTime" := CreateDateTime(Rec."Fecha fijación", 080000T);
                    Usertask."Due DateTime" := CreateDateTime(Rec."Fecha fijación", 130000T);
                    UserSetups.SetRange(Departamento, 'TALLER');
                    UserSetups.SetRange(Responsable, true);
                    UserSetups.FindFirst();
                    User.Get(userSetups."Id Usuario");
                    EmailResponsable := User."Contact Email";
                    UserTask.Validate("Assigned To", User."User Security ID");
                    UserSetups.SetRange(Responsable);
                    UserSetups.SetRange(Supervisor, true);
                    UserSetups.FindFirst();
                    User.Get(userSetups."Id Usuario");
                    EmailSupervisor := User."Contact Email";
                    UserTask.Validate("Supervisor", User."User Security ID");
                    if not TipoIncidencia.Get('FIJACION') then begin
                        TipoIncidencia.Init();
                        TipoIncidencia."Code" := 'FIJACION';
                        TipoIncidencia."Description" := 'Fijación';
                        TipoIncidencia.Insert();

                    end;
                    UserSetups.Reset();
                    UserTask.Validate("User Task Group Assigned To", 'FIJACION');
                    UserTask.Validate(Priority, Usertask.Priority::High);
                    UserTask.Validate("Object Type", Usertask."Object Type"::Page);
                    UserTask.Validate("Object ID", Page::"Ficha Orden Fijacion");
                    UserTask.Validate("Due DateTime", CreateDateTime(Rec."Fecha fijación", 080000T));
                    Usertask."Start DateTime" := CreateDateTime(Rec."Fecha fijación", 080000T);
                    Usertask."Due DateTime" := CreateDateTime(Rec."Fecha fijación", 130000T);
                    Usertask."No." := Format(Rec."Nº Orden");
                    Usertask.OrdenFijacion := Rec."Nº Orden";
                    UserTask.Insert(true);
                    UserSetups.SetRange(Responsable, true);
                    UserSetups.FindFirst();
                    User.Get(userSetups."Id Usuario");
                    UserTask.Validate("Assigned To", User."User Security ID");
                    UserSetups.SetRange(Responsable);
                    UserSetups.SetRange(Supervisor, true);
                    UserSetups.FindFirst();
                    User.Get(userSetups."Id Usuario");
                    UserTask.Validate("Supervisor", User."User Security ID");
                    UserTask."User Task Group Assigned To" := 'FIJACION';
                    Usertask.OrdenFijacion := Rec."Nº Orden";
                    Usertask.Departamento := 'Taller';
                    Usertask.Servicio := 'Medios';
                    Usertask."Job No." := Rec."Nº Proyecto";
                    Usertask.Modify();
                    //Inserto los report
                    If Opcion = 1 then begin
                        DoccAttach.Init();
                        DoccAttach."Table ID" := Database::"User Task";
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
                        Cab.SetRange("Nº Orden", Rec."Nº Orden");
                        RecRef.GetTable(Cab);
                        Report.SaveAs(Report::"Etiqueta orden fijacion Vallas", '', ReportFormat::Pdf, Outstr, RecRef);
                        RecRef.Close();
                        Clear(RecRef);
                        RecRef.GetTable(Usertask);
                        RecRef.Get(Usertask.RecordId);
                        TM.Insert();
                        tm.CalcFields(Content);
                        Tm.Content.CreateInStream(InStr);
                        DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                        //DoccAttach.Insert();
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
                                DoccAttach."Table ID" := Database::"User Task";
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
                                Clear(RecRef);
                                RecRef.GetTable(Imagenes);
                                Rep.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                                TM.Insert();
                                tm.CalcFields(Content);
                                Tm.Content.CreateInStream(InStr);
                                Clear(RecRef);
                                RecRef.GetTable(Usertask);
                                RecRef.Get(Usertask.RecordId);
                                DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                                //DoccAttach.Insert();
                                RecRef.Close();
                                tm.Delete();
                            until Imagenes.NEXT = 0;
                    end;
                    if Opcion = 3 then begin
                        DoccAttach.Init();
                        DoccAttach."Table ID" := Database::"User Task";
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
                        Clear(RecRef);
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
                        Clear(RecRef);
                        RecRef.GetTable(Usertask);
                        RecRef.Get(Usertask.RecordId);
                        DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                        RecRef.Close();
                        //DoccAttach.Insert();
                        tm.Delete();
                    end;

                    Clear(Gtask);
                    Gtask.CrearTareaFijacion(Rec, Usertask);
                    UserSetups.SetRange(Responsable, true);
                    UserSetups.SetRange(Supervisor);
                    UserSetups.FindFirst();
                    User.Get(userSetups."Id Usuario");
                    User.FindFirst();
                    EnviaCorreo(Usertask, true, '', false, 'Tarea Fijación', EmailResponsable, EmailSupervisor, '', User."Full Name");
                end;
            }
            action("Ver Tarea")
            {
                Image = "Task";
                ApplicationArea = All;
                Caption = 'Ver Tarea';
                trigger OnAction()
                var

                    Usertask: Record "User Task";

                begin
                    Usertask.SetRange(OrdenFijacion, Rec."Nº Orden");
                    If Not Usertask.FindFirst() then
                        Error('No existe una tarea para esta orden')
                    else
                        Page.RunModal(Page::"User Task Card", Usertask);

                end;
            }
            action("Borrar Tarea")
            {
                Image = "Delete";
                ApplicationArea = All;
                Caption = 'Borrar Tarea';
                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    Usertask: Record "User Task";
                begin
                    Usertask.SetRange(OrdenFijacion, Rec."Nº Orden");
                    If Usertask.FindFirst() then begin
                        Gtask.DeleteTarea(Usertask);
                        Usertask.Delete();

                    end;
                end;
            }
        }
        addafter(AsignarImagenaLineas)
        {
            actionref(CreartareaRef; "Crear Tarea") { }
            actionref(VertareaRef; "Ver Tarea") { }
        }
    }
    procedure EnviaCorreo(
       Var UserTask: Record "User Task";
       Adjunto: Boolean;
       Motivo: Text;
       Notificacion: Boolean;
       Asunto: Text;
       SendTo: Text;
       CC: Text;
       BCC: Text; Nombre: Text)


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
            //Andres Serra Candela
            If StrPos(Nombre, ' ') > 0 then
                Nombre := CopyStr(Nombre, 1, Strpos(Nombre, ' ') - 1);
            if Time < 140000T then
                BigText := ('Buenos días ' + Nombre + ':')
            else if Time < 200000T then
                BigText := ('Buenas tardes ' + Nombre + ':')
            else
                BigText := ('Buenas noches ' + Nombre + ':');
            //BigText := ('Estimado:');
            BigText := BigText + '<br> </br>';
            BigText := BigText + '<br> </br>';
            BigText := BigText + ('Se ha generado la Tarea: <b>' + UserTask.GetDescription() + ' </b> ');
            //BigText := BigText + (', ha cambiado de estado a: <b>' + Format(Estado) + ' .</b>');
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
            ficheros.SetRange("Table ID", Database::"User Task");
            ficheros.SetRange("No.", UserTask."No.");
            If ficheros.FindLast() then
                repeat
                    base64 := ficheros.ToBase64StringOcr(ficheros.url);
                    Clear(Cbase64);
                    Tempblob.CreateOutStream(OutStream);
                    Cbase64.FromBase64(base64, OutStream);
                    Tempblob.CreateInStream(AttachmentStream);
                    REmail.AddAttachment(AttachmentStream, ficheros."File Name" + '.' + ficheros."File Extension");
                until ficheros.Next() = 0;
        end;
        if REmail.Send(true, emilesc::Gtasks) then begin

        end;
    end;

}