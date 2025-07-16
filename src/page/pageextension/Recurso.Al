pageextension 92160 RecursoExt extends "Resource Card"
{
    actions
    {
        addafter("Crear Recurso")
        {
            group("TareasMonjaje/Desmontaje Emplazamiento")
            {
                Image = TaskQualityMeasure;
                group(Tecnico)
                {

                    action("Crear Tarea TMC Tecnico")
                    {
                        Caption = 'Crear Tarea TMC-Fijar en Blanco';
                        ApplicationArea = All;
                        Image = TaskPage;
                        trigger OnAction()
                        var
                            Gtask: Codeunit GTask;
                            RecRef: RecordRef;
                            Resource: Record Resource;
                        begin
                            Gtask.CrearCategorias(CompanyName);
                            Commit();
                            Resource.Get(Rec."No.");
                            RecRef.GetTable(Resource);
                            Gtask.CrearTarea(RecRef, 'Fijar en blanco el recurso ' + Resource.name + ' con el número ' + Resource."No." + ', si está en algún contrato, se debe desvincular e informar al cliente y al comercial',
                            'MEDIOS', 'TECNICO', 'Medidas Cautelares ' + Resource.Name, 'TMC', false, '', '');

                        end;
                    }
                    action("Crear Tarea Desmontaje Tec")
                    {
                        Caption = 'Crear Tarea Desmontaje';
                        ApplicationArea = All;
                        Image = TaskPage;
                        trigger OnAction()
                        var
                            Gtask: Codeunit GTask;
                            RecRef: RecordRef;
                            Resource: Record Resource;
                        begin
                            Gtask.CrearCategorias(CompanyName);
                            Commit();
                            Resource.Get(Rec."No.");
                            RecRef.GetTable(Resource);
                            Gtask.CrearTarea(RecRef, 'Proceder a desmontar ' + Resource.name + ' con el número ' + Resource."No.",
                            'TALLER', 'TECNICO', 'Desmontar recurso ' + Resource.Name, 'DESMONTAJE', false, '', '');

                        end;
                    }
                }
                group(Medios)
                {
                    action("Crear Tarea TMC Medios")
                    {
                        Caption = 'Crear Tarea TMC-Fijar Blanco';
                        ApplicationArea = All;
                        Image = TaskPage;
                        trigger OnAction()
                        var
                            Gtask: Codeunit GTask;
                            RecRef: RecordRef;
                            Tipos: Record "Tipo Recurso";
                            Fichero: Text;
                            Adjuntar: Boolean;
                            Resource: Record Resource;
                        begin
                            Gtask.CrearCategorias(CompanyName);
                            Commit();
                            Resource.Get(Rec."No.");
                            RecRef.GetTable(Resource);
                            If Not Tipos.Get(Resource."Tipo Recurso") then
                                Tipos.Init();
                            Fichero := Tipos."Ruta imagenes" + '\' + Resource."No.";
                            //Adjuntar := Exists(Fichero);
                            Adjuntar := true;
                            If Not Adjuntar then
                                Fichero := '';
                            Gtask.CrearTarea(RecRef, 'Fijar en blanco el recurso ' + Resource.name + ' con el número ' + Resource."No." + ', si está en algún contrato, se debe desvincular e informar al cliente y al comercial',
                            'TALLER', 'MEDIOS', 'Fijacion en blanco ' + Resource.Name, 'TMC', Adjuntar, Fichero, '.pdf');

                            // RecRef.Close();
                            // Clear(RecRef);
                            // RecRef.GetTable(Usertask);
                            // RecRef.Get(Usertask.RecordId);
                            // TM.Insert();
                            // tm.CalcFields(Content);
                            // Tm.Content.CreateInStream(InStr);
                            // DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Rec."No." + '.pdf');
                            // //DoccAttach.Insert();
                            // tm.Delete();
                            // Clear(Gtask);
                            // Gtask.CrearTareaTecnico(Rec."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
                            // Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
                            // EnviaCorreo(Usertask, true, '', false, 'TMC ' + Rec."No.", EmailResponsable, EmailSupervisor, '', User."Full Name");

                        end;
                    }
                }
                group(Juridico)
                {
                    action("Crear Tarea TMC- Medidas Cautelares")
                    {
                        ApplicationArea = All;
                        Image = TaskPage;
                        trigger OnAction()
                        var
                            Gtask: Codeunit GTask;
                            RecRef: RecordRef;
                            Resource: Record Resource;
                        begin
                            Gtask.CrearCategorias(CompanyName);
                            Commit();
                            Resource.Get(Rec."No.");
                            RecRef.GetTable(Resource);
                            Gtask.CrearTarea(RecRef, 'Inicio medidas cautelares ' + Resource.name + ' con el número ' + Resource."No.",
                            'TECNICO', 'JURIDICO', 'Medidas Cautelares ' + Resource.Name, 'TMC', false, '', '');

                        end;
                    }
                    action("Crear Tarea Desmontaje")
                    {
                        ApplicationArea = All;
                        Image = TaskPage;
                        trigger OnAction()
                        var
                            Gtask: Codeunit GTask;
                            RecRef: RecordRef;
                            Resource: Record Resource;
                        begin
                            Resource.Get(Rec."No.");
                            Gtask.CrearCategorias(CompanyName);
                            Commit();
                            RecRef.GetTable(Resource);
                            Gtask.CrearTarea(RecRef, 'Proceder a desmontar ' + Resource.name + ' con el número ' + Resource."No.",
                            'TECNICO', 'JURIDICO', 'Desmontar recurso ' + Resource.Name, 'DESMONTAJE', false, '', '');

                        end;
                    }
                }
            }

            action("Ver Tareas")
            {
                Image = "TaskList";
                ApplicationArea = All;
                Caption = 'Ver Tareas';
                trigger OnAction()
                var

                    Usertask: Record "User Task";

                begin
                    Usertask.SetRange(Id_record, Rec.RecordId);
                    If Not Usertask.FindFirst() then
                        Error('No existe una tarea para esta emplazamiento')
                    else
                        Page.RunModal(1170, Usertask);

                end;
            }
            action(Sincronizar)
            {
                Image = ChangeTo;
                ApplicationArea = All;
                Caption = 'Sincronizar';
                trigger OnAction()
                var
                    Gtask: Codeunit GTask;
                    Resource: Record Resource;
                    IdKuara: Text;
                begin
                    If Resource.FindFirst() then
                        repeat
                            IdKuara := Gtask.GetLink(Resource.RecordId, Database::Resource, CompanyName);
                            If IdKuara <> '' then
                                Gtask.UpdateRecurso(Resource, Resource.RecordId, Database::Resource, IdKuara);
                        until Resource.Next() = 0;
                end;

            }
            action("Sincronizar errores")
            {
                Image = ChangeTo;
                ApplicationArea = All;
                Caption = 'Sincronizar errores';
                trigger OnAction()
                var
                    Gtask: Codeunit GTask;
                    Resourcet: Record Resource temporary;
                    Resource: Record Resource;

                begin
                    Gtask.GetResource(Resourcet);
                    If Resourcet.FindFirst() then
                        repeat
                            If Resource.Get(Resourcet."No.") then
                                If Gtask.InsertLink(Resource.RecordId, Database::Resource, Resourcet."Search Name", CompanyName) Then
                                    Gtask.UpdateRecurso(Resource, Resource.RecordId, Database::Resource, Resourcet."Search Name");
                        until Resourcet.Next() = 0;
                end;

            }

        }
        //     addafter(AsignarImagenaLineas)
        //   {
        //     actionref(CreartareaRef;"Crear Tarea"){}
        //     actionref(VertareaRef;"Ver Tarea"){}
        //   }  
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
        BigText := BigText + ('Dpto. ' + UserTask.Servicio);
        BigText := BigText + '<br> </br>';

        BigText := BigText + (rInf.Name);
        //"Plaintext Formatted":=TRUE;
        // SendMsg.AppendBody(BigText);
        // CLEAR(BigText);
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        REmail.AddAttachment(Funciones.CargaPie(Base64), 'emailfoot.png');
        BigText := BigText + '<img src="data:image/png;base64,' + base64 + '" />';//"emailFoot.png" />';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" sice=2 color=#A6A6A6>';
        BigText := BigText + ('<b>SI NO DESEA RECIBIR MAS INFORMACION, CONTESTE ESTE E-MAIL INDICANDOLO EXPRESAMENTE</b>');
        BigText := BigText + '</font>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" size=1 color=#A6A6A6>';
        BigText := BigText + ('En cumplimiento de lo establecido en el REGLAMENTO (UE) 2016/679, de 27 de abril de 2016, con plenos efectos desde el 25 de mayo de 2018, le recordamos que sus datos personales son');
        BigText := BigText + ('objeto de tratamiento por parte de MALLA S.A. Le informamos también que tiene la posibilidad de ejercer los derechos de acceso, rectificación, supresión, oposición, limitación del');
        BigText := BigText + (' tratamiento y portabilidad de sus datos, mediante comunicación escrita a la dirección de correo electrónico <a href="mailto:lopd@malla.es" rel="noreferrer" target="_blank" heap-ignore="true"><span style="color:blue">lopd@malla.es</span></a>, o bien, a nuestra dirección postal (' + rInf.Name + ')');
        BigText := BigText + (rInf.Address + '. ' + rInf."Post Code" + '. ' + rInf.City + '. España');
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Este correo y sus archivos asociados son privados y confidenciales y va dirigido exclusivamente a su destinatario. Si recibe este correo sin ser el destinatario del mismo, le rogamos proceda');
        BigText := BigText + (' a su eliminación y lo ponga en conocimiento del emisor. La difusión por cualquier medio del contenido de este correo podría ser sancionada conforme a lo previsto en las leyes españolas.');
        BigText := BigText + ('No se autoriza la utilización con fines comerciales o para su incorporación a ficheros automatizados de las direcciones del emisor o del destinatario');
        //REmail.Subject := 'Pago contrato ' + NContrato;
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

    var
        Responsable: Guid;
        Supervisor: Guid;

}