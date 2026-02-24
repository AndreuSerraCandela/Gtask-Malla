pageextension 92159 SolicitudesExt extends "Ficha Solicitudes"
{
    actions
    {
        addfirst(Processing)
        {
            action("Crear Tarea")
            {
                ApplicationArea = All;
                Image = TaskPage;
                trigger OnAction()
                var
                    Gtask: Codeunit GTask;
                    Procesos_GTask: Codeunit Procesos_GTask;
                    UserTask: Record "User Task";
                    User: Record User;
                    EmailResponsable: Text[250];
                    EmailSupervisor: Text[250];
                    TipoIncidencia: Record "User Task Group";
                    Resource: Record "Resource";
                    RecRef: RecordRef;
                    DoccAttach: Record "Document Attachment";
                    InStr: Instream;
                    DoccAttach2: Record "Document Attachment";
                    Responsable: Guid;
                    Supervisor: Guid;
                    ListaCorreos: Text;
                begin
                    Gtask.CrearCategorias(CompanyName);
                    Commit();
                    UserTask.Init();
                    UserTask.Validate(Title, Rec.Observaciones);
                    UserTask.SetDescription(Rec.GetWorkDescription());
                    UserTask."Created By" := UserSecurityId();
                    UserTask.Validate("Created DateTime", CurrentDateTime);
                    If Date2DWY(WorkDate(), 1) = 5 then begin
                        Usertask."Start DateTime" := CreateDateTime(CalcDate('3D', WorkDate()), 080000T);
                        Usertask."Due DateTime" := CreateDateTime(CalcDate('3D', WorkDate()), 130000T);
                    end else begin
                        Usertask."Start DateTime" := CreateDateTime(CalcDate('1D', WorkDate()), 080000T);
                        Usertask."Due DateTime" := CreateDateTime(CalcDate('1D', WorkDate()), 130000T);
                    end;
                    User.Get(UserSecurityId());
                    Procesos_GTask.DevuelveSupervisoryResponsable(Responsable, Supervisor, 'JURIDICO', 'JURIDICO', 'Solicitud', EmailResponsable, EmailSupervisor, User, UserTask, ListaCorreos);
                    UserTask.Validate(Priority, Usertask.Priority::High);
                    UserTask.Validate("Object Type", Usertask."Object Type"::Page);
                    UserTask.Validate("Object ID", Page::"Ficha Solicitudes");
                    Usertask."Id_Record" := Rec.RecordId;
                    UserTask.Insert(true);
                    Usertask."No." := Format(Usertask.ID);
                    // If not IsNullGuid(UserTask.Supervisor) then
                    //     UserTask."Created By" := Usertask.Supervisor;
                    UserTask.Modify();
                    Commit();
                    Page.RunModal(Page::"User Task Card", UserTask);
                    iF UserTask.Estado = UserTask.Estado::Cancelado then begin
                        UserTask.Get(UserTask.ID);
                        Commit();
                        If Confirm('¿Desea borrar la tarea?') then begin
                            UserTask.Delete();
                            exit;
                        end;
                    end;
                    Commit();
                    UserTask.Get(UserTask.ID);
                    If IsNullGuid(UserTask."Supervisor") or IsNullGuid(UserTask."Assigned To")
                    or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
                    or (UserTask.Servicio = '') Then begin
                        If Confirm('No ha completado los campos Supervisor, Responsable, Categoría, Departamento y Servicio, ¿Desea continuar?') then begin
                            Commit();
                            UserTask.Get(UserTask.ID);
                            Page.RunModal(Page::"User Task Card", UserTask);
                            iF UserTask.Estado = UserTask.Estado::Cancelado then begin
                                UserTask.Get(UserTask.ID);
                                Commit();
                                If Confirm('¿Desea borrar la tarea?') then begin
                                    UserTask.Delete();
                                    exit;
                                end;
                            end;
                            Commit();
                            UserTask.Get(UserTask.ID);
                        end else begin
                            UserTask.Delete();
                            exit;
                        end;
                        If IsNullGuid(UserTask."Supervisor") or IsNullGuid(UserTask."Assigned To")
                        or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
                        or (UserTask.Servicio = '') Then begin
                            Message('No ha completado los campos Supervisor, Responsable, Categoría, Departamento y Servicio, Proceso cancelado');
                            UserTask.Delete();
                            exit;
                        end;
                    end;
                    Clear(Gtask);
                    Clear(RecRef);
                    DoccAttach.SetRange("Table ID", Database::Reclamaciones);
                    DoccAttach.SetRange("Line No.", Rec."Nº Solicitud");
                    If DoccAttach.FindFirst() then
                        repeat
                            DoccAttach2 := DoccAttach;
                            DoccAttach2."Table ID" := Database::"User Task";
                            DoccAttach2."No." := UserTask."No.";
                            DoccAttach2."Line No." := 0;
                            DoccAttach2.Insert();
                        until DoccAttach.Next() = 0;


                    Gtask.CrearTareaTecnico('', UserTask, UserTask.Departamento, UserTask.Servicio, false);
                    Procesos_Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
                    EnviaCorreo(Usertask, true, '', false, 'Solicitud ' + Format(Rec."Nº Autorización"), EmailResponsable, EmailSupervisor, '', User."Full Name");

                end;
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
                    Usertask.SetRange(Id_Record, Rec.RecordId);
                    If Not Usertask.FindFirst() then
                        Error('No existe una tarea para esta Solicitud')
                    else
                        Page.RunModal(1170, Usertask);

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

}