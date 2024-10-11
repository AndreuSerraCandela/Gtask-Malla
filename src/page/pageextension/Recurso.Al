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
                            'MEDIOS', 'TECNICO', 'Medidas Cautelares ' + Resource.Name, 'TMC', false, '');

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
                            'TALLER', 'TECNICO', 'Desmontar recurso ' + Resource.Name, 'DESMONTAJE', false, '');

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
                            'TALLER', 'MEDIOS', 'Fijacion en blanco ' + Resource.Name, 'TMC', Adjuntar, Fichero);

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
                            'TECNICO', 'JURIDICO', 'Medidas Cautelares ' + Resource.Name, 'TMC', false, '');

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
                            'TECNICO', 'JURIDICO', 'Desmontar recurso ' + Resource.Name, 'DESMONTAJE', false, '');

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
                    Usertask.SetRange("No.", Rec."Nº Emplazamiento");
                    If Not Usertask.FindFirst() then
                        Error('No existe una tarea para esta emplazamiento')
                    else
                        Page.RunModal(0, Usertask);

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