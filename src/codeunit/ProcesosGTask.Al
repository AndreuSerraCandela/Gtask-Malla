
/// <summary>
/// Codeunit GTask (ID 80110).
/// </summary>
codeunit 7001149 Procesos_GTask
{
    var
        Qwark: Option Ocr,Qwark;
        LToken: Text;
        Gtask: Codeunit Gtask;


    #region eventos
    [EventSubscriber(ObjectType::Table, Database::"Time Sheet Header", 'OnValidateResourceNoOnBeforeTestFields', '', false, false)]
    local procedure OnValidateResourceNoOnBeforeTestFields(Resource: Record Resource; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Time Sheet Line", 'OnBeforeSetApproverIDFromResource', '', false, false)]
    local procedure OnBeforeSetApproverIDFromResource(Resource: Record Resource; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Task", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEvent(var Rec: Record "User Task"; var xRec: Record "User Task")
    begin
        Rec."Fecha Cambio" := CurrentDateTime;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Crear Visita Emplazamiento", 'OnAfterFinishPage', '', false, false)]
    local procedure OnAfterFinishPage(var Task: Record "To-do")
    var
        gTask: Codeunit Gtask;
        RecRef: RecordRef;
        UserSetups: Record "User Setup";
        Users: record User;
    begin
        If Task.Emplazamiento Then begin
            If Task."Proxima visita" <> 0D Then begin
                RecRef.Gettable(Task);
                UserSetups.SetRange("Salespers./Purch. Code", Task."Salesperson Code");
                UserSetups.FindFirst();
                Users.SetRange("User Name", UserSetups."User ID");
                Users.FindFirst();
                Gtask.CrearTareaVisita(RecRef, Task."Descripción Visita", 'TECNICO', 'TECNICO', Task.Description, 'VISITA', false, '', Task."Proxima visita", Task."Start Time", Users."User Security ID");

            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"To-Do", 'OnCreateTaskFromTaskOnBeforeStartWizard', '', false, false)]
    local procedure OnCreateTaskFromTaskOnBeforeStartWizard(var Task: Record "To-do"; var FromTask: Record "To-do")
    begin
        Task.Id_Tabla := FromTask.Id_Tabla;
        Task.Tabla := FromTask.Tabla;
        If Task.Tabla = Database::"User Task" then begin
            Task."Start Time" := FromTask."Start Time";
            Task.Emplazamiento := true;
            Task.Type := Task.Type::"Phone Call";
            Task.Date := FromTask.Date;
            If Task.date = 0D then Task.Date := WorkDate();
            Task.Duration := 60 * 1000 * 60;
            Task."Ending Date" := Task.Date;
            Task."Ending Time" := DT2Time(CreateDateTime(Task.date, Task."Start Time") + Task.Duration);
        end;

    end;

    [EventSubscriber(ObjectType::Table, Database::"To-Do", 'OnBeforeRunCreateTaskPage', '', false, false)]
    local procedure OnBeforeRunCreateTaskPage(var Task: Record "To-do"; var IsHandled: Boolean)
    begin
        If Task."Tabla" = Database::"User Task" then begin
            IsHandled := true;
            Task.SetRange("Id_Tabla", Task."Id_Tabla");
            if PAGE.RunModal(PAGE::"Create Chat", Task) = ACTION::OK then;
        end else begin
            if Not Task.Emplazamiento Then exit;
            IsHandled := true;
            if PAGE.RunModal(PAGE::"Crear Visita Emplazamiento", Task) = ACTION::OK then;
        end;

    end;

    [EventSubscriber(ObjectType::Report, Report::"Visitas Emplazamientos", 'OnAfterSetDescrtiption', '', false, false)]
    procedure OnAfterSetDescrtiption(var Resource: Record "To-do"; var TCateg: Text; var TProhibiciones: Text)
    var
        UserTask: Record "User Task";
    begin
        If Resource.Tabla = Database::"User Task" then begin
            If Not UserTask.Get(Resource."Id_Tabla") Then exit;
            TCateg := 'Fecha:';
            TProhibiciones := 'Nº emplazamiento:';
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Visitas Emplazamientos", 'OnAfterSetFecha', '', false, false)]
    procedure OnAfterSetFecha(var Resource: Record "To-do"; var TCateg: Text)
    var
        UserTask: Record "User Task";
        Recurso: Record "Resource";
        Emplzazamientos: Record Emplazamientos;
        Pnel: Record "PNEL";
    begin
        If Resource.Tabla = Database::"User Task" then begin
            If Not UserTask.Get(Resource."Id_Tabla") Then exit;
            Case UserTask."Object ID" of
                Page::"Resource Card":
                    begin
                        If Recurso.Get(UserTask.Id_record) Then TCateg := Recurso."Nº Emplazamiento";

                    end;
                Page::"Ficha emplazamiento":
                    begin
                        If Emplzazamientos.Get(UserTask.Id_record) Then TCateg := Emplzazamientos."Nº Emplazamiento";
                    end;
                Page::"PNEL Emplazamientos":
                    begin
                        If Pnel.Get(UserTask.Id_record) Then TCateg := Pnel."Nº Emplazamiento";
                    end;

            End;
            TCateg := 'Fecha:';
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Visitas Emplazamientos", 'OnAfterSetTitulo', '', false, false)]
    procedure OnAfterSetTitulo(var Resource: Record "To-do"; var TCateg: Text)
    begin
        If Resource.Tabla = Database::"User Task" then begin
            TCateg := 'Chat tareas';
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Imagenes Orden fijacion", 'OnBeforeImportWithFilter', '', false, false)]

    local procedure OnBeforeImportWithFilter(var Rec: Record "Imagenes Orden fijación"; Esincidencia: Boolean; var VallaFijada: Boolean; var IsHandled: Boolean)
    var
        Files: JsonArray;
        FileObject: JsonObject;
        JsonToken: JsonToken;
        i: Integer;
        FileContent: Text;
        MultibleUpload: Page Upload;
        filesJson: Text;
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        DocStream: InStream;
        Norden: Integer;
        NImagen: Integer;
        DocumentAttachment: Record "Imagenes Orden fijación";
        Control: Codeunit "ControlProcesos";
    begin
        IsHandled := true;
        MultibleUpload.RunModal();
        filesJson := MultibleUpload.filestoBc();
        if Files.ReadFrom(filesJson) then begin
            for i := 0 to Files.Count - 1 do begin
                Files.Get(i, JsonToken);
                FileObject := JsonToken.AsObject();

                FileObject.Get('name', JsonToken);
                FileName := JsonToken.AsValue().AsText();
                FileObject.Get('content', JsonToken);
                FileContent := JsonToken.AsValue().AsText();
                TempBlob.CreateOutStream(OutStream);
                Base64Convert.FromBase64(FileContent, OutStream);
                if FileName <> '' then BEGIN
                    iF Rec."Nº Imagen" = 0 then begin
                        Rec."Nº Imagen" := -1;
                        Rec.Insert();
                        Norden := Rec."Nº Orden";
                        DocumentAttachment.SetRange("Nº Orden", Rec."Nº Orden");
                        Rec.Delete();
                        If DocumentAttachment.FindSet() then
                            NImagen := DocumentAttachment."Nº Imagen"
                        else
                            NImagen := 0;
                    end;
                    If Norden = 0 Then Norden := Rec."Nº Orden";
                    Rec.Init();
                    NImagen := NImagen + 1;
                    Rec."Nº Orden" := Norden;
                    Rec."Nº Imagen" := NImagen;
                    Rec."Nombre" := FileName;
                    If Rec.Nombre = '' Then Rec.Nombre := Format(NImagen);
                    Rec."Valla Fijada" := VallaFijada;
                    Rec."Es Incidencia" := EsIncidencia;
                    TempBlob.CreateInStream(DocStream);
#If CLEAN27
                    Control.InsertAttachment(Rec, DocStream, FileName, true);
#else
                    Rec.InsertAttachment(DocStream, FileName, true);
#endif
                end;
                Clear(TempBlob);
                Clear(OutStream);
            end;
        end;
        FileName := '';

    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnAfterSendVendor', '', false, false)]
    local procedure OnAfterSendVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer; DocumentSendingProfile: Record "Document Sending Profile")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        Contratos: Record "Sales Header";
        LineCount: Integer;
        RecRef: RecordRef;
        Control: Codeunit "Controlprocesos";
    begin
        RecRef.GetTable(RecordVariant);
        If RecRef.Number <> Database::"Purchase Header" then exit;
        If Not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocNo) then exit;
        //Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Enviado a Taller", false);
        PurchaseLine.SetRange("Validado PB", false);

        if PurchaseLine.FindSet() then begin
            repeat
                if Not PurchaseLine."Enviado a Taller" then begin
                    LineCount += 1;
                    PurchaseLine."Enviado a Taller" := true;
                    PurchaseLine."Empresa" := CompanyName;
                    PurchaseLine.Modify();
                end;
            until PurchaseLine.Next() = 0;
        end;
        If not Job.Get(PurchaseHeader."Nº Proyecto") then exit;
        Contratos.SetRange("Nº Proyecto", Job."No.");
        if Not Contratos.FindFirst() then exit;

        // Enviar correo al comercial
        EnviaCorreoComercial('Cambio de estado del contrato', Contratos, Contratos."Salesperson Code", true, 'Pedido Enviado al Proveedor', '');

    end;

    [EventSubscriber(ObjectType::Page, Page::"Doc. Attachment List FactBox", 'OnAfterGetRecRefFail', '', false, false)]
    local procedure OnAfterGetRecRefFail(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        "Task": Record "User Task";
        TimeSheetLine: Record "Time Sheet Line";

    begin

        If DocumentAttachment."Table ID" = Database::"User Task" then begin
            RecRef.Open(Database::"User Task");
            Task.SetRange("No.", DocumentAttachment."No.");
            If Task.FindFirst() then
                RecRef.GetTable("Task");
        end;
        If DocumentAttachment."Table ID" = Database::"Time Sheet Line" then begin
            RecRef.Open(Database::"Time Sheet Line");
            TimeSheetLine.SetRange("Job No.", DocumentAttachment."No.");
            if DocumentAttachment."Line No." <> 0 then
                TimeSheetLine.SetRange("Job Line No.", DocumentAttachment."Line No.");
            If TimeSheetLine.FindFirst() then
                RecRef.GetTable(TimeSheetLine);
        end;


    end;

    [EventSubscriber(ObjectType::Page, Page::"Doc. Attachment List Factbox", 'OnBeforeDrillDown2', '', false, false)]
    local procedure OnBeforeDrillDown2(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        "Task": Record "User Task";
        TimeSheetLine: Record "Time Sheet Line";

    begin

        If DocumentAttachment."Table ID" = Database::"User Task" then begin
            RecRef.Open(Database::"User Task");
            Task.SetRange("No.", DocumentAttachment."No.");
            If Task.FindFirst() then
                RecRef.GetTable("Task");
        end;
        If DocumentAttachment."Table ID" = Database::"Time Sheet Line" then begin
            RecRef.Open(Database::"Time Sheet Line");
            TimeSheetLine.SetRange("Job No.", DocumentAttachment."No.");
            If DocumentAttachment."Line No." <> 0 then
                TimeSheetLine.SetRange("Job Line No.", DocumentAttachment."Line No.");
            If TimeSheetLine.FindFirst() then
                RecRef.GetTable(TimeSheetLine);
        end;


    end;

    [EventSubscriber(ObjectType::Table, Database::"User Task", 'OnAfterValidateEvent', 'Id', false, false)]
    local procedure OnAffterValidate(var Rec: Record "User Task")
    begin
        Rec."No." := Format(Rec.ID);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", 'OnAfterOpenForRecRef', '', false, false)]
    local procedure OnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FlowFieldsEditable: Boolean)
    var
        "Task": Record "User Task";
        TimeSheetLine: Record "Time Sheet Line";

    begin
        If DocumentAttachment."Table ID" = Database::"User Task" then begin
            Task.SetRange("No.", DocumentAttachment."No.");
            If Task.FindFirst() then
                RecRef.GetTable("Task");
        end;
        If DocumentAttachment."Table ID" = Database::"Time Sheet Line" then begin
            RecRef.Open(Database::"Time Sheet Line");
            TimeSheetLine.SetRange("Job No.", DocumentAttachment."No.");
            If DocumentAttachment."Line No." <> 0 then
                TimeSheetLine.SetRange("Job Line No.", DocumentAttachment."Line No.");
            If TimeSheetLine.FindFirst() then
                RecRef.GetTable(TimeSheetLine);
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterSetDocumentAttachmentFiltersForRecRefInternal', '', false, false)]
    local procedure OnAfterSetDocumentAttachmentFiltersForRecRefInternal(var DocumentAttachment: Record "Document Attachment"; RecordRef: RecordRef; GetRelatedAttachments: Boolean)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        LineNo: Integer;
        UserTask: Record "User Task";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        If RecordRef.Number = Database::"User Task" then begin
            FieldRef := RecordRef.Field(UserTask.FieldNo("No."));
            RecNo := FieldRef.Value();
            DocumentAttachment.SetRange("No.", RecNo);
        end;
        If DocumentAttachment."Table ID" = Database::"Time Sheet Line" then begin
            FieldRef := RecordRef.Field(TimeSheetLine.FieldNo("Job No."));
            RecNo := FieldRef.Value();
            DocumentAttachment.SetRange("No.", RecNo);
            FieldRef := RecordRef.Field(TimeSheetLine.FieldNo("Job Line No."));
            LineNo := FieldRef.Value();
            if LineNo > 0 then
                DocumentAttachment.SetRange("Line No.", LineNo);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        UserTask: Record "User Task";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        If TableNo = Database::"User Task" then begin
            Result := true;
            FieldNo := UserTask.FieldNo("No.");
        end;
        If TableNo = Database::"Time Sheet Line" then begin
            Result := true;
            FieldNo := TimeSheetLine.FieldNo("Job No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Task Group Member", 'OnAfterValidateEvent', 'User Security Id', false, false)]
    local procedure OnAfterValidateEvent(var Rec: Record "User Task Group Member")
    var
        UserGtaskMalla: Record UsuariosGtask;

    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        If not IsNullGuid(Rec."User Security ID") then begin
            UserGtaskMalla.SetRange("Id Usuario", Rec."User Security ID");
            If UserGtaskMalla.FindSet() then begin
                Rec.Departamento := UserGtaskMalla.Departamento;
                Rec.Supervisor := UserGtaskMalla.Supervisor;
                Rec.Responsable := UserGtaskMalla.Responsable;
            end;
        END;
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Task", 'OnAfterModifyEvent', '', false, false)]
    procedure UserTaskOnAfterModifyEvent(var Rec: Record "User Task"; var xRec: Record "User Task"; RunTrigger: Boolean)
    var
        Ficheros: Record Ficheros;
        OrdenFijacion: Record "Orden fijación";
    begin
        Ficheros.SetRange(Procesado, true);
        Ficheros.SetRange("Nombre fichero", Rec.Id_Tarea);
        Ficheros.SetRange(Proceso, 'UPDATEGTASK');
        If Ficheros.FindFirst() then begin
            Ficheros.Delete(false);
            Commit();
            exit;
        end;
        if Rec.Id_Tarea <> '' Then begin
            //where(OrdenFijacion = field("Nº Orden"), Reserva = field("Nº Reserva"))
            if OrdenFijacion.Get(Rec.OrdenFijacion, Rec.Reserva) then begin
                OrdenFijacion."Tiene Task" := true;
                OrdenFijacion."Estado Tarea" := Rec.Estado;
                OrdenFijacion.Modify();
            end;
        end;
        If (Rec."Id_Tarea" <> '') and (RunTrigger) then begin
            rec."Fecha Comunicado Cambio" := CurrentDateTime;
            Rec."Fecha Cambio" := CurrentDateTime;
            Rec.Modify();
            UpdateTaskGtaskBak(Rec.Id_Tarea, Rec.ID);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterModifyEvent', '', false, false)]
    procedure DocumentAttachmentOnAfterModifyEvent(var Rec: Record "Document Attachment"; var xRec: Record "Document Attachment"; RunTrigger: Boolean)
    var
        Tareas: Record "User Task";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        If Rec.IsTemporary() then exit;
        If Rec."Document Flow Service" Then exit;
        If Rec."Table ID" = Database::"User Task" then begin
            Tareas.SetRange("No.", Rec."No.");
            If Tareas.FindFirst() then
                if Tareas."Id_Tarea" <> '' then
                    Gtask.GetSetDocattchment(Tareas, Tareas.Id_Tarea);
        end;
        If Rec."Table ID" = Database::"Time Sheet Line" then begin
            TimeSheetLine.SetRange("Job No.", Rec."No.");
            If TimeSheetLine."Job Line No." > 0 then
                TimeSheetLine.SetRange("Job Line No.", Rec."Line No.");
            If TimeSheetLine.FindFirst() then
                GetSetDocattchmentParteTrabajo(TimeSheetLine, TimeSheetLine."Job No.");
        end;

    end;
    //IsertAttachment
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInsertEvent', '', false, false)]
    procedure DocumentAttachmentOnAfterInsertEvent(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    var
        Tareas: Record "User Task";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        If Rec.IsTemporary() then exit;
        If Rec."Document Flow Service" Then exit;
        If Rec."Table ID" = Database::"User Task" then begin
            Tareas.SetRange("No.", Rec."No.");
            If Tareas.FindFirst() then
                if Tareas."Id_Tarea" <> '' then
                    if Rec."Url" <> '' then
                        If Rec."File Name" <> '' then
                            Gtask.GetSetDocattchment(Tareas, Tareas.Id_Tarea);
        end;
        If Rec."Table ID" = Database::"Time Sheet Line" then begin
            TimeSheetLine.SetRange("Job No.", Rec."No.");
            If TimeSheetLine."Job Line No." > 0 then
                TimeSheetLine.SetRange("Job Line No.", Rec."Line No.");
            If TimeSheetLine.FindFirst() then
                GetSetDocattchmentParteTrabajo(TimeSheetLine, TimeSheetLine."Job No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"To-Do", 'OnAfterModifyEvent', '', false, false)]
    procedure ToDoOnAfterModifyEvent(var Rec: Record "To-Do"; var xRec: Record "To-Do"; RunTrigger: Boolean)
    var
        Tareas: Record "User Task";

    begin
        If Rec.IsTemporary() then exit;
        If Rec."All Day Event" Then exit;
        If Rec."Tabla" = Database::"User Task" Then begin
            Tareas.SetRange("No.", Rec."No.");
            If Tareas.Get(Rec.Id_Tabla) then
                if Tareas."Id_Tarea" <> '' then
                    Gtask.GetSetChat(Tareas, Tareas.Id_Tarea);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"To-Do", 'OnAfterInsertEvent', '', false, false)]
    procedure ToDoOnAfterInsertEvent(var Rec: Record "To-Do"; RunTrigger: Boolean)
    var
        Tareas: Record "User Task";

    begin
        If Rec.IsTemporary() then exit;
        If Rec."All Day Event" Then exit;
        If Rec."Tabla" = Database::"User Task" Then begin
            Tareas.SetRange("No.", Rec."No.");
            If Tareas.Get(Rec.Id_Tabla) then
                if Tareas."Id_Tarea" <> '' then
                    If Rec."Descripción Visita" <> '' then
                        Gtask.GetSetChat(Tareas, Tareas.Id_Tarea);

        end;
    end;


    #endregion eventos




    procedure UpdateTasksPriority(var Tareas: Record "User Task")
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Link: Record "Data Migration Error";
        IdLink: Integer;
        UserMalla: Record UsuariosGtask;
        Desde: DateTime;
        JsonObjt: JsonObject;
        responsable: Text;
        Supervisor: Text;
        departament: Text;
        service: Text;
        DesdeF: Date;
        Hastaf: Date;
        Dias: Integer;
    begin
        CompanyInfo.Get();
        //If Tareas.FindFirst() then
        //repeat
        Clear(JsonObjt);
        JsonObjt.Add('type', 'NORMAL');
        JsonObjt.WriteTo(Json);
        Clear(RestApi);
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Gtask.Token(), RequestType::put, Json);


        //  until Tareas.Next() = 0;


    end;


    procedure UpdateTaskGtask(idTarea: Text; IdKey: Integer)
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Link: Record "Data Migration Error";
        IdLink: Integer;
        Tareas: Record "User Task";
        UserMalla: Record UsuariosGtask;
        Desde: DateTime;
        JsonObjt: JsonObject;
        responsable: Text;
        Supervisor: Text;
        departament: Text;
        service: Text;
        DesdeF: Date;
        Hastaf: Date;
        Dias: Integer;
        rIncidencia: Record Incidencias;
    begin
        CompanyInfo.Get();
        If Tareas.Get(IdKey) then Begin
            Clear(JsonObjt);
            Case Tareas.Estado Of
                Tareas.Estado::Pendiente:
                    begin
                        JsonObjt.Add('state', 'PENDING');
                    end;
                Tareas.Estado::"En Proceso":
                    begin
                        JsonObjt.Add('state', 'INPROCESS');
                    end;
                Tareas.Estado::Finalizado:
                    begin
                        JsonObjt.Add('state', 'FINISHED');
                    end;
            end;
            JsonObjt.Add('description', Tareas.Title);
            JsonObjt.Add('observation', Tareas.GetDescription);
            UserMalla.ChangeCompany('Malla Publicidad');
            UserMalla.Setrange("Id Usuario", Tareas."Assigned To");
            If UserMalla.FindFirst() then
                responsable := UserMalla."Id Gtask";
            UserMalla.Setrange("Id Usuario", Tareas."Supervisor");
            If UserMalla.FindFirst() then
                Supervisor := UserMalla."Id Gtask";
            JsonObjt.Add('user', responsable);
            JsonObjt.Add('supervisor', "Supervisor");
            departament := Tareas.Departamento;
            service := Tareas.Servicio;
            If (departament <> '') and (service <> '') then begin
                Gtask.CrearDepartamnetoyServicio(departament, service);
                JsonObjt.Add('department', Departament);
                JsonObjt.Add('service', service);
                JsonObjt.Add('date', Gtask.Hora(Tareas."Start DateTime"));
            end;
            DesdeF := Variant2Date(Tareas."Start DateTime");
            if DesdeF = 0D then begin
                DesdeF := Variant2Date(CurrentDateTime);
            end;
            Hastaf := Variant2Date(TareaS."Due DateTime");
            //LO MISMO PARA HASTA
            if HastaF = 0D then begin
                HastaF := Variant2Date(CurrentDateTime);
            end;
            Dias := HastaF - DesdeF;
            JsonObjt.Add('daysToPerform', Dias + 1);
            JsonObjt.Add('bc', true);

            JsonObjt.WriteTo(Json);
            Clear(RestApi);

            Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Gtask.Token(), RequestType::put, Json);
            if Tareas.Estado in [Tareas.Estado::Finalizado, Tareas.Estado::"En Proceso"] then begin
                rIncidencia.SetRange("Id Tarea Gtask", Tareas.Id_Tarea);
                if rIncidencia.FindFirst() then begin
                    if rIncidencia."Comunicado por EMT" then
                        If rIncidencia."Fecha Actuacion" = 0DT Then
                            rIncidencia."Fecha Actuacion" := CurrentDateTime();
                    if rIncidencia."Fecha Actuacion" > CurrentDateTime() then
                        rIncidencia."Fecha Actuacion" := CurrentDateTime();
                    rIncidencia.Modify();
                end else begin
                    rIncidencia."Fecha Actuacion" := CurrentDateTime();
                    rIncidencia.Modify();
                end;
            end;
        End;
    end;

    procedure BusCaUsuario(Id: Text; var UserGtaskMalla: Record UsuariosGtask)
    var
        SalesPerson: Record "Salesperson/Purchaser";
        User: Record User;
        UserSetup: Record "User Setup";
        IdUser: Text;
    begin
        UserGtaskMalla.SetRange("Id Gtask", Id);
        If not UserGtaskMalla.FindFirst() Then begin
            UserGtaskMalla.Init();
            UserGtaskMalla."Id Gtask" := Id;
            UserGtaskMalla."Id Usuario" := CreateGuid();
            UserGtaskMalla.Insert(true);
            SalesPerson.SetFilter(Code, '%1', '7*');
            If SalesPerson.FindLast() then begin
                UserGtaskMalla.Tecnico := IncStr(SalesPerson.Code);
                UserGtaskMalla.Modify();
                SalesPerson.Init();
                SalesPerson.Code := UserGtaskMalla.Tecnico;
                SalesPerson.Name := 'Técnico Gtask';
                SalesPerson.Insert(true);
            end else begin
                UserGtaskMalla.Tecnico := '7000';
                UserGtaskMalla.Modify();
                SalesPerson.Init();
                SalesPerson.Code := '7000';
                SalesPerson.Name := 'Técnico Gtask';
                SalesPerson.Insert(true);
            end;
            UserGtaskMalla.FindFirst();
            exit;
        end;
        If UserGtaskMalla.Tecnico = '' Then begin
            If User.Get(UserGtaskMalla."Id Usuario") Then begin
                If Not UserSetup.Get(user."User Name") then begin
                    UserSetup.Init();
                    UserSetup."User Id" := User."User Name";
                    UserSetup.Insert(true);
                end;
                If UserSetup."Salespers./Purch. Code" = '' Then begin
                    SalesPerson.SetFilter(Code, '%1', '5*');
                    If SalesPerson.FindLast() then begin
                        UserGtaskMalla.Tecnico := IncStr(SalesPerson.Code);
                        UserGtaskMalla.Modify();
                        SalesPerson.Init();
                        SalesPerson.Code := UserGtaskMalla.Tecnico;
                        SalesPerson.Name := 'Técnico Gtask';
                        SalesPerson.Insert(true);
                    end else begin
                        UserGtaskMalla.Tecnico := '5000';
                        UserGtaskMalla.Modify();
                        SalesPerson.Init();
                        SalesPerson.Code := '5000';
                        SalesPerson.Name := 'Técnico Gtask';
                        SalesPerson.Insert(true);
                    end;
                    UserGtaskMalla.FindFirst();
                    exit;
                end;
                UserGtaskMalla.Tecnico := SalesPerson.Code;
                UserGtaskMalla.Modify();
                UserGtaskMalla.FindFirst();
                UserGtaskMalla.Get(UserGtaskMalla."Id Usuario");
                exit;
            end;
        end;
        exit;
    end;

    procedure CambiaEmpresa(CodeEmpresa: Text): Text;
    var
        Empresas: Record "Company";
        CompanyInfo: Record "Company Information";
    begin
        If CodeEmpresa = '' then
            exit('');
        If Empresas.FindFirst() then
            repeat
                CompanyInfo.ChangeCompany(Empresas.Name);
                CompanyInfo.Get();
                if CompanyInfo."Clave Recursos" = CodeEmpresa then
                    exit(Empresas.Name);
            until Empresas.Next() = 0;
        exit('');
    end;

    local procedure ConstruirObservationDesdePartes(Frequency: Text; Departament: Text; Zone: Text; StopName: Text): Text
    var
        Partes: List of [Text];
        Parte: Text;
        Resultado: Text;
    begin
        if Frequency <> '' then
            Partes.Add('Frecuencia: ' + Frequency);
        if Departament <> '' then
            Partes.Add('Departamento: ' + Departament);
        if Zone <> '' then
            Partes.Add('Zona: ' + Zone);
        if StopName <> '' then
            Partes.Add('Parada: ' + StopName);
        foreach Parte in Partes do
            if Resultado = '' then
                Resultado := Parte
            else
                Resultado += ' | ' + Parte;
        exit(Resultado);
    end;

    /// <summary>
    /// Calcula Fecha Actuacion a partir del texto de frecuencia: número + unidad (h=horas, d=días, w=semanas).
    /// Puede haber espacio opcional entre número y letra (ej. "72h", "72 h", "3 d", "1w").
    /// </summary>
    internal procedure CalcularFechaActuacionDesdeFrecuencia(var rDet: Record Incidencias; Frequency: Text)
    var
        FrecuenciaLimpia: Text;
        Len: Integer;
        Unidad: Text[1];
        NumTexto: Text;
        Num: Decimal;
        Ms: Integer;
    begin
        if Frequency = '' then begin
            //fehca actuancion + 2 semanas
            rDet."Fecha Actuacion" := CurrentDateTime() + 2 * 7 * 24 * 3600 * 1000;
            exit;
        end;
        FrecuenciaLimpia := DelChr(Frequency.Trim(), '=', ' ');
        Len := StrLen(FrecuenciaLimpia);
        if Len < 2 then
            exit;
        Unidad := UpperCase(CopyStr(FrecuenciaLimpia, Len, 1));
        NumTexto := CopyStr(FrecuenciaLimpia, 1, Len - 1);
        if not Evaluate(Num, NumTexto) then
            exit;
        case Unidad of
            'H':
                Ms := Num * 3600 * 1000;
            'D':
                Ms := Num * 24 * 3600 * 1000;
            'W':
                Ms := Num * 7 * 24 * 3600 * 1000;
            else
                exit;
        end;
        rDet."Fecha Actuacion" := CurrentDateTime() + Ms;
    end;


    internal procedure ProcesarUnaTareaPost(JsonTarea: JsonObject; var Tareas: Record "User Task"; var ErrorMsg: Text): Boolean
    var
        JsonCampo: JsonToken;
        UserTaskGroup: Record "User Task Group";
        ResponsabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        UserGtaskMalla: Record UsuariosGtask;
        RecordiD: RecordId;
        RecordRef: RecordRef;
        Empresas: Record "Company";
        Resources: Record Resource;
        Gtask: Codeunit Gtask;
        Id: Integer;
        IdTareaGtask: Text[30];
        UsuarioGtask: Text;
        Description: Text;
        Category: Text;
        Resource: Text;
        FechaHora: DateTime;
        Departamento: Text;
        Servicio: Text;
        Empresa: Text;
        Encontrado: Boolean;
        EsParada: Boolean;
        Emplazamientos: Record "Emplazamientos";
        Categoria: Record "User Task Group";
        Responsable: Guid;
        Supervisor: Guid;
        EmailResponsable: Text;
        EmailSupervisor: Text;
        User: Record User;
        UserTask: Text;
        ListadeCorreos: Text;
    begin
        ErrorMsg := '';

        If Not JsonTarea.Get('usuariogtask', JsonCampo) then begin
            ErrorMsg := 'Falta usuariogtask';
            exit(false);
        end;
        UsuarioGtask := JsonCampo.AsValue().AsText();
        UserGtaskMalla.SetRange("Id Gtask", UsuarioGtask);
        If Not UserGtaskMalla.FindFirst() then begin
            ErrorMsg := 'usuariogtask no encontrado: ' + UsuarioGtask;
            exit(false);
        end else begin
            Responsable := UserGtaskMalla."Id Usuario";
            Supervisor := UserGtaskMalla."Id Usuario";
            User.Get(UserGtaskMalla."Id Usuario");
        end;

        If Not JsonTarea.Get('description', JsonCampo) then begin
            ErrorMsg := 'Falta description';
            exit(false);
        end;
        Description := CopyStr(JsonCampo.AsValue().AsText(), 1, 250);

        If Not JsonTarea.Get('category', JsonCampo) then begin
            ErrorMsg := 'Falta category';
            exit(false);

        end;
        Category := JsonCampo.AsValue().AsText();

        If JsonTarea.Get('resource', JsonCampo) then
            Resource := JsonCampo.AsValue().AsText()
        else begin
            ErrorMsg := 'Falta resource';
            exit(false);
        end;
        if JsonTarea.Get('esparada', JsonCampo) then
            EsParada := JsonCampo.AsValue().AsBoolean()
        else
            EsParada := false;
        //PARADA_
        If copystr(Resource, 1, 7) = 'PARADA_' then
            EsParada := true;


        If JsonTarea.Get('fechahora', JsonCampo) Then
            FechaHora := JsonCampo.AsValue().AsDateTime()
        else if JsonTarea.Get('fecha', JsonCampo) Then
            FechaHora := ParseFechaFromJson(JsonCampo.AsValue().AsText())
        else
            FechaHora := CurrentDateTime();

        Departamento := 'TECNICO';
        Servicio := 'TECNICO';
        If JsonTarea.Get('department', JsonCampo) then
            Departamento := JsonCampo.AsValue().AsText();
        If JsonTarea.Get('service', JsonCampo) then
            Servicio := JsonCampo.AsValue().AsText();

        Clear(RecordiD);
        RecordiD := Gtask.RecuperaId(Category, Database::"User Task Group", CompanyName);
        If RecordiD.TableNo = 0 then begin
            If Category = '69807bab6823020012e97858' then begin
                Categoria.Get('REVISION');
                Gtask.InsertLink(Categoria.RecordId, Database::"User Task Group", Category, CompanyName);
                RecordiD := Categoria.RecordId;
            end else begin
                ErrorMsg := 'category no encontrada: ' + Category;
                exit(false);
            end;
        end;
        RecordRef := RecordiD.GetRecord();
        Categoria.get(RecordiD);
        Tareas."User Task Group Assigned To" := RecordRef.Field(UserTaskGroup.FieldNo(Code)).Value;
        Tareas."Categoría" := Tareas."User Task Group Assigned To";

        Encontrado := false;
        Empresa := CompanyName;
        If not EsParada then begin
            If Resources.Get(Resource) then
                Encontrado := true
            else begin
                Empresas.FindFirst();
                repeat
                    Resources.ChangeCompany(Empresas.Name);
                    Resources.Reset();
                    If Resources.Get(Resource) then begin
                        Encontrado := true;
                        Empresa := Empresas.Name;
                        break;
                    end;
                until Empresas.Next() = 0;
            end;
        end;
        If EsParada then begin
            If CopyStr(Resource, 1, 7) = 'PARADA_' then
                Resource := CopyStr(Resource, 8);
            If not Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, CopyStr(Resource, 1, 20)) then begin
                ErrorMsg := 'Emplazamiento no encontrado: ' + Resource;
                exit(false);
            end;
        end;

        Tareas.Reset();
        If Tareas.FindLast() Then
            Id := Tareas."Id" + 1
        else
            Id := 1;
        Tareas.Init();
        Tareas."Id" := Id;
        Tareas."Assigned To" := UserGtaskMalla."Id Usuario";
        Tareas.Supervisor := UserGtaskMalla."Id Usuario";
        Tareas."Created By" := UserGtaskMalla."Id Usuario";
        Tareas.Title := Description;
        Tareas.SetDescription(Description);
        Tareas."Start DateTime" := FechaHora;
        Tareas."Due DateTime" := FechaHora;
        Tareas.Estado := Tareas.Estado::Pendiente;
        Tareas.Validate("Created DateTime", CurrentDateTime);
        Tareas.Validate(Priority, Tareas.Priority::High);

        Clear(RecordiD);
        RecordiD := Gtask.RecuperaId(Departamento, Database::"Responsibility Center", CompanyName);
        If RecordiD.TableNo <> 0 then begin
            RecordRef := RecordiD.GetRecord();
            Tareas.Departamento := RecordRef.Field(ResponsabilitiCenter.FieldNo(Code)).Value;
        end else
            Tareas.Departamento := CopyStr(Gtask.InsertarDepartamentoOservicio(Departamento, CompanyName, false), 1, 20);
        Clear(RecordiD);
        RecordiD := Gtask.RecuperaId(Servicio, Database::"Work Center", CompanyName);
        If RecordiD.TableNo <> 0 then begin
            RecordRef := RecordiD.GetRecord();
            Tareas.Servicio := RecordRef.Field(WorkCenter.FieldNo("No.")).Value;
        end else
            Tareas.Servicio := CopyStr(Gtask.InsertarDepartamentoOservicio(Servicio, CompanyName, true), 1, 20);

        If (Resource <> '') and Encontrado then begin
            Tareas.Resource := CopyStr(Resource, 1, 20);
            Tareas.Validate("Object ID", Page::"Resource Card");
            Tareas.Id_record := Resources.RecordId;

        end;
        If EsParada then begin
            //Tareas.Validate("Object ID", Page::"Ficha Parada Bus");
            Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, Resource);
            Tareas.Id_record := Emplazamientos.RecordId;
        end;
        Tareas.Insert(true);
        Tareas."No." := Format(Tareas.ID);
        Tareas."Categoría" := Categoria.Code;
        Tareas."User Task Group Assigned To" := Categoria.Code;
        Tareas.IdQr := 'P_' + Resource;
        Tareas.Modify();
        Commit();

        If (Resource <> '') and Encontrado then begin
            Resources.Reset();
            If not Resources.Get(Resource) then begin
                Resources.ChangeCompany(Empresa);
                Resources.Get(Resource);
            end;
        end;
        if (Tareas.Departamento = '') Or (Tareas.Servicio = '') then begin
            DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, Categoria.Code, EmailResponsable, EmailSupervisor, User, Tareas, ListadeCorreos);
        end;
        IdTareaGtask := Gtask.CrearTareaTecnico(Resource, Tareas, Tareas.Departamento, Tareas.Servicio, true);
        If IdTareaGtask <> '' then begin
            Tareas.Get(Tareas.ID);
            Tareas.Id_Tarea := IdTareaGtask;
            Tareas.Modify();
            Commit();
        end;


        exit(true);
    end;


    internal procedure EscribirIncidenciaHistorial(var Incidencias: Record Incidencias; var JsonFormater: Codeunit "Json Text Reader/Writer")
    var
        NombreParada: Text;
    begin
        NombreParada := CopyStr(Format(Incidencias.NombreElemento()), 1, 100);
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('no', Incidencias."No.");
        JsonFormater.WriteStringProperty('idGtask', Incidencias.Id_Gtask);
        JsonFormater.WriteStringProperty('descripcion', Incidencias.Descripción);
        JsonFormater.WriteStringProperty('estado', Format(Incidencias.Estado));
        if Incidencias.Estado = Incidencias.Estado::Cerrada then
            if Incidencias."Fecha Actuacion" = 0DT Then Incidencias."Fecha Actuacion" := CreateDateTime(Incidencias.fecha, 0T);

        if Incidencias.Estado = Incidencias.Estado::Cerrada then
            JsonFormater.WriteStringProperty('fechaResolucion', Format(Incidencias."Fecha Actuacion", 0, '<Year4>-<Month,2>-<Day,2>'))
        else
            JsonFormater.WriteStringProperty('fechaResolucion', '');
        JsonFormater.WriteStringProperty('parada', NombreParada);
        JsonFormater.WriteStringProperty('recurso', Incidencias.Recurso);
        if Incidencias."Fecha Actuacion" <> 0DT then
            JsonFormater.WriteStringProperty('fechaActuacion', Format(Incidencias."Fecha Actuacion", 0, '<Year4>-<Month,2>-<Day,2>T<Hour,2>:<Minute,2>:<Second,2>Z'))
        else
            JsonFormater.WriteStringProperty('fechaActuacion', '');
        JsonFormater.WriteBooleanProperty('comunicadoPorEMT', Incidencias."Comunicado por EMT");
        JsonFormater.WriteBooleanProperty('resuelta', Incidencias.Estado = Incidencias.Estado::Cerrada);
        //peticion
        JsonFormater.WriteBooleanProperty('peticion', Incidencias."Es Peticion");
        JsonFormater.WriteEndObject();
    end;


    internal procedure OperarioNombre(ZonaLimpieza: Integer): Text
    var

        ZonasLimpieza: Record "Zonas Limpieza";
        User: Record User;
    begin
        ZonasLimpieza.ChangeCompany('Malla Publicidad');
        ZonasLimpieza.SetRange("Id", ZonaLimpieza);
        if ZonasLimpieza.FindFirst() then
            if not IsNullGuid(ZonasLimpieza.Responsable) then begin
                if User.Get(ZonasLimpieza.Responsable) then
                    exit(User."Full Name");
            end;
        exit('equipoTI');
    end;

    /// <summary>
    /// Procedimiento auxiliar para agregar una tarea al JSON array de resultados
    /// </summary>
    internal procedure AgregarTareaAlJson(var UserTask: Record "User Task"; var Emplazamientos: Record Emplazamientos; var JsonArray: JsonArray)
    var
        JsonTarea: JsonObject;
        User: Record User;
        UserGtask: Record UsuariosGtask;
        FechaInicio: Date;
        HoraInicio: Time;

    begin
        Clear(JsonTarea);
        JsonTarea.Add('id', UserTask.ID);
        JsonTarea.Add('idTarea', UserTask.Id_Tarea);
        JsonTarea.Add('no', UserTask."No.");
        JsonTarea.Add('title', UserTask.Title);
        JsonTarea.Add('description', UserTask.GetDescription());
        JsonTarea.Add('codigoEmplazamiento', Emplazamientos."Nº Emplazamiento");
        JsonTarea.Add('descripcionEmplazamiento', Emplazamientos."Descripción");
        JsonTarea.Add('zonaLimpieza', Emplazamientos."Zona Limpieza");
        JsonTarea.Add('categoria', UserTask."User Task Group Assigned To");
        JsonTarea.Add('departamento', UserTask.Departamento);
        //qr
        JsonTarea.Add('idQr', UserTask.IdQr);
        JsonTarea.Add('servicio', UserTask.Servicio);
        JsonTarea.Add('estado', Format(UserTask.Estado));
        JsonTarea.Add('puntoX', Emplazamientos.PuntoX);
        JsonTarea.Add('puntoY', Emplazamientos.PuntoY);
        JsonTarea.Add('emplazamiento', Emplazamientos."Nº Emplazamiento");
        JsonTarea.Add('emplazamientoDescripcion', Emplazamientos."Descripción");

        case UserTask.Priority of
            UserTask.Priority::Low:
                JsonTarea.Add('prioridad', 'Baja');
            UserTask.Priority::Normal:
                JsonTarea.Add('prioridad', 'Normal');
            UserTask.Priority::High:
                JsonTarea.Add('prioridad', 'Alta');
        end;


        // Fechas
        if UserTask."Start DateTime" <> 0DT then begin
            FechaInicio := DT2Date(UserTask."Start DateTime");
            HoraInicio := DT2Time(UserTask."Start DateTime");
            JsonTarea.Add('fechaInicio', Format(FechaInicio, 0, '<Year4>-<Month,2>-<Day,2>'));
            JsonTarea.Add('horaInicio', Format(HoraInicio, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        end;

        if UserTask."Due DateTime" <> 0DT then begin
            JsonTarea.Add('fechaVencimiento', Format(DT2Date(UserTask."Due DateTime"), 0, '<Year4>-<Month,2>-<Day,2>'));
        end;

        // Usuarios
        if not IsNullGuid(UserTask."Assigned To") then begin
            User.SetRange("User Security ID", UserTask."Assigned To");
            if User.FindFirst() then begin
                if User."Full Name" <> '' then
                    JsonTarea.Add('responsable', User."Full Name")
                else
                    JsonTarea.Add('responsable', User."User Name");
            end;
            UserGtask.SetRange("Id Usuario", UserTask."Assigned To");
            if UserGtask.FindFirst() then
                JsonTarea.Add('responsableIdGtask', UserGtask."Id Gtask");
        end;

        if not IsNullGuid(UserTask.Supervisor) then begin
            User.SetRange("User Security ID", UserTask.Supervisor);
            if User.FindFirst() then begin
                if User."Full Name" <> '' then
                    JsonTarea.Add('supervisor', User."Full Name")
                else
                    JsonTarea.Add('supervisor', User."User Name");
            end;
            UserGtask.SetRange("Id Usuario", UserTask.Supervisor);
            if UserGtask.FindFirst() then
                JsonTarea.Add('supervisorIdGtask', UserGtask."Id Gtask");
        end;

        JsonArray.Add(JsonTarea);
    end;


    /// <summary>
    /// Añade una tarea al array JSON de resultados incluyendo puntoX y puntoY del recurso/emplazamiento.
    /// </summary>
    internal procedure AgregarTareaUsuarioAlJson(var UserTask: Record "User Task"; var JsonArray: JsonArray)
    var
        JsonTarea: JsonObject;
        User: Record User;
        UserGtask: Record UsuariosGtask;
        Resource: Record Resource;
        Emplazamientos: Record Emplazamientos;
        FechaInicio: Date;
        HoraInicio: Time;
        Reserva: Record Reserva;
    begin
        Clear(JsonTarea);
        JsonTarea.Add('id', UserTask.ID);
        JsonTarea.Add('idQr', UserTask.IdQr);
        JsonTarea.Add('no', UserTask."No.");
        JsonTarea.Add('title', UserTask.Title);
        JsonTarea.Add('description', UserTask.GetDescription());
        JsonTarea.Add('categoria', UserTask."User Task Group Assigned To");
        JsonTarea.Add('departamento', UserTask.Departamento);
        JsonTarea.Add('servicio', UserTask.Servicio);
        JsonTarea.Add('estado', Format(UserTask.Estado));
        JsonTarea.Add('crearParte', UserTask.CrearParte);
        case UserTask.Priority of
            UserTask.Priority::Low:
                JsonTarea.Add('prioridad', 'Baja');
            UserTask.Priority::Normal:
                JsonTarea.Add('prioridad', 'Normal');
            UserTask.Priority::High:
                JsonTarea.Add('prioridad', 'Alta');
        end;

        if UserTask."Start DateTime" <> 0DT then begin
            FechaInicio := DT2Date(UserTask."Start DateTime");
            HoraInicio := DT2Time(UserTask."Start DateTime");
            JsonTarea.Add('fechaInicio', Format(FechaInicio, 0, '<Year4>-<Month,2>-<Day,2>'));
            JsonTarea.Add('horaInicio', Format(HoraInicio, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        end;
        if UserTask."Due DateTime" <> 0DT then
            JsonTarea.Add('fechaVencimiento', Format(DT2Date(UserTask."Due DateTime"), 0, '<Year4>-<Month,2>-<Day,2>'));

        if not IsNullGuid(UserTask."Assigned To") then begin
            User.SetRange("User Security ID", UserTask."Assigned To");
            if User.FindFirst() then begin
                if User."Full Name" <> '' then
                    JsonTarea.Add('responsable', User."Full Name")
                else
                    JsonTarea.Add('responsable', User."User Name");
            end;
            UserGtask.ChangeCompany('Malla Publicidad');
            UserGtask.SetRange("Id Usuario", UserTask."Assigned To");
            if UserGtask.FindFirst() then
                JsonTarea.Add('responsableIdGtask', UserGtask."Id Gtask");
        end;
        if UserTask.Resource <> '' then begin
            if Resource.Get(UserTask.Resource) then begin
                JsonTarea.Add('puntoX', Resource.PuntoX);
                JsonTarea.Add('puntoY', Resource.PuntoY);
                JsonTarea.Add('recurso', Resource."No.");
                JsonTarea.Add('recursoNombre', Resource.Name);
            end;
        end;

        // Coordenadas del recurso/emplazamiento (puntoX, puntoY)
        if UserTask.Id_record.TableNo = Database::Resource then begin
            if Resource.Get(UserTask.Id_record) then begin
                JsonTarea.Add('puntoX', Resource.PuntoX);
                JsonTarea.Add('puntoY', Resource.PuntoY);
                JsonTarea.Add('recurso', Resource."No.");
                JsonTarea.Add('recursoNombre', Resource.Name);
            end;
        end;
        if UserTask.Id_record.TableNo = Database::Emplazamientos then begin
            Emplazamientos.Get(UserTask.Id_record);
            JsonTarea.Add('puntoX', Emplazamientos.PuntoX);
            JsonTarea.Add('puntoY', Emplazamientos.PuntoY);
            JsonTarea.Add('emplazamiento', Emplazamientos."Nº Emplazamiento");
            JsonTarea.Add('emplazamientoDescripcion', Emplazamientos."Descripción");
            JsonTarea.Add('recurso', Emplazamientos."Nº Emplazamiento");
            JsonTarea.Add('recursoNombre', Emplazamientos."Descripción");

        end;
        // si no es emplazamiento ni recurso, pero tiene reserrva, desde la reserva se puede obtener el recurso
        if UserTask.Id_record.TableNo = Database::Reserva then begin
            if Reserva.Get(UserTask.Reserva) then begin
                if Resource.Get(Reserva."Nº Recurso") then begin
                    JsonTarea.Add('puntoX', Resource.PuntoX);
                    JsonTarea.Add('puntoY', Resource.PuntoY);
                    JsonTarea.Add('recurso', Resource."No.");
                    JsonTarea.Add('recursoNombre', Resource.Name);
                end;
            end;
        end;


        JsonArray.Add(JsonTarea);
    end;



    internal procedure EnviaCorreo(
      "No.": Text;
      Descrpcion: Text;
      Adjunto: Boolean;
      Motivo: Text;
      Notificacion: Boolean;
      Asunto: Text;
      SendTo: Text;
      CC: Text;
      Lista: Text;
      BCC: Text; Nombre: Text; Eliminada: Boolean; IdTarea: Text; Incidencia: Boolean)


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
        Incidencias: Record Incidencias;
        Imagenes: Record "Imagenes Orden fijación";
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
            if Eliminada then
                BigText := BigText + ('Se ha eliminado la Tarea: <b>' + Descrpcion + ' </b> ')
            else begin
                if Incidencia then
                    BigText := BigText + ('Se ha creado la Incidencia: <b>' + Descrpcion + ' </b> ')
                else
                    BigText := BigText + ('Se ha creado la Tarea: <b>' + Descrpcion + ' </b> ');
            end;
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
        If Lista <> '' then begin
            //Eliminar ; final
            If CopyStr(Lista, StrLen(Lista), 1) = ';' then
                Lista := CopyStr(Lista, 1, StrLen(Lista) - 1);
            If CC <> '' then
                CC := Lista + ';' + CC
            else
                CC := Lista;
        end;

        if CC <> '' then
            REmail."Send CC" := CC;
        if BCC <> '' then
            REmail."Send BCC" := BCC;
        REmail.SetBodyText(BigText);
        REmail."From Name" := UserId;
        If Adjunto then begin

            // If Contratostemp.FindFirst() then
            //     repeat
            if Incidencia then begin
                If not Incidencias.Get("No.") Then Incidencias.init();
                Imagenes.SetRange("Nº Orden", Incidencias."Nº Orden");
                Imagenes.SetRange("Es Incidencia", true);
                If Imagenes.FindSet() Then begin
                    repeat
                        base64 := ficheros.ToBase64StringOcr(Imagenes.Url);
                        Clear(Cbase64);
                        Tempblob.CreateOutStream(OutStream);
                        Cbase64.FromBase64(base64, OutStream);
                        Tempblob.CreateInStream(AttachmentStream);
                        REmail.AddAttachment(AttachmentStream, Imagenes.nombre);
                    until Imagenes.Next() = 0;
                end;
            end else begin
                ficheros.SetRange("Table ID", Database::"User Task");
                ficheros.SetRange("No.", "No.");
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
        end;
        if REmail.Send(true, emilesc::Gtasks) then begin

        end;
    end;



    local procedure GetSetDocattchmentParteTrabajo(TimeSheetLine: Record "Time Sheet Line"; JobNo: Code[20])
    begin
        //TODO: Implementar
    end;


    internal procedure DevuelveSupervisoryResponsable(
       Var Responsable: Guid;
       var Supervisor: Guid;
       Departamento: Text;
       Servicio: Text;
       Categoria: Text;
       var EmailResponsabe: Text;
       var EmailSupervisor: Text;
       VAR User: Record "User";
       Var UserTask: Record "User Task"; var ListaCorreo: Text)
    var
        UserGtaskMalla: Record UsuariosGtask;
        UserxbyCategory: Record "User Task Group Member";
        UserTaskGroup: Record "User Task Group";

    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        If not IsNullGuid(Responsable) then begin
            UserGtaskMalla.SetRange("Id Usuario", Responsable);
            If not UserGtaskMalla.FindFirst() then Error('Usuario %1 no encontrado en Gtask', Responsable);
        end;
        UserGtaskMalla.SetRange("Id Usuario", User."User Security Id");
        If not UserGtaskMalla.FindFirst() then Error('Usuario %1 no encontrado en Gtask', User."User Name");
        If IsnullGuid(Responsable) then begin
            UserGtaskMalla.Reset();
            UserxbyCategory.ChangeCompany('Malla Publicidad');
            UserxbyCategory.SetRange(Departamento, Departamento);
            UserxbyCategory.SetRange("User Task Group Code", Categoria);
            UserxbyCategory.SetRange(Responsable, true);
            UserxbyCategory.SetRange("Copiado en Mail", false);
            If UserxbyCategory.FindFirst() then begin
                Responsable := UserxbyCategory."User Security ID";

            end else begin
                UserxbyCategory.SetRange("Copiado en Mail");
                If UserxbyCategory.FindFirst() then begin
                    Responsable := UserxbyCategory."User Security ID";
                end else begin
                    UserGtaskMalla.SetRange(Departamento);
                    UserGtaskMalla.SetRange(Responsable, true);
                    If UserGtaskMalla.FindFirst() then
                        Responsable := UserGtaskMalla."Id Usuario";
                end;
            end;
        end;
        UserxbyCategory.ChangeCompany('Malla Publicidad');
        UserxbyCategory.SetRange(Departamento, Servicio);
        UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange(Supervisor, true);
        UserxbyCategory.SetRange("Copiado en Mail", false);
        UserxbyCategory.SetRange(Responsable);
        If UserxbyCategory.FindFirst() then begin
            Supervisor := UserxbyCategory."User Security ID";

        end else begin
            UserxbyCategory.SetRange("Copiado en Mail");
            If UserxbyCategory.FindFirst() then begin
                Supervisor := UserxbyCategory."User Security ID";
            end else begin
                UserGtaskMalla.SetRange(Departamento);
                UserGtaskMalla.SetRange(Supervisor, true);
                UserGtaskMalla.SetRange(Responsable);
                If UserGtaskMalla.FindFirst() then
                    Supervisor := UserGtaskMalla."Id Usuario";
            end;
        end;
        User.SetRange("User Security ID", Supervisor);
        If User.FindFirst() then begin
            EmailSupervisor := User."Contact Email";
        end;
        User.SetRange("User Security ID", Responsable);
        If User.FindFirst() then begin
            EmailResponsabe := User."Contact Email";
        end;
        UserTASK.Validate(Servicio, Servicio);
        UserTASK.Validate(Departamento, Departamento);
        If not UserTaskGroup.Get(Categoria) then
            Error('No se ha encontrado la categoría %1 en Gtask', Categoria);
        UserxbyCategory.Reset();
        UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange(Departamento, Departamento);
        UserxbyCategory.SetRange(Responsable, true);
        If not UserxbyCategory.FindFirst() then
            If IsNullGuid(Responsable) then
                Message('No se ha encontrado el usuario responsable ( el que se encarga de hacer la tarea ) para la categoría %1 en el Departamento %2', Categoria, Departamento);
        UserTask.Validate("Categoría", Categoria);
        UserTask."Assigned To" := Responsable;
        UserxbyCategory.Reset();
        UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange(Supervisor, true);
        If not UserxbyCategory.FindFirst() then
            If IsNullGuid(Supervisor) then
                Message('No se ha encontrado el usuario supervisor  para la categoría %1 en el Departamento %2', Categoria, Servicio);
        UserTask."Supervisor" := Supervisor;
        // If not IsNullGuid(UserTask.Supervisor) then
        //     UserTask."Created By" := Supervisor
        // else
        UserTask.Validate("Created By", User."User Security Id");
        // UserxbyCategory.Reset();
        // UserxbyCategory.SetRange(Departamento, Servicio);
        // UserxbyCategory.SetRange("User Task Group Code", Categoria);
        // UserxbyCategory.SetRange(Supervisor);
        // UserxbyCategory.SetRange(Responsable);
        // UserxbyCategory.SetRange("Copiado en Mail", true);
        // User.Reset();
        // If UserxbyCategory.FindFirst() then
        //     repeat
        //         User.SetRange("User Security ID", UserxbyCategory."User Security ID");
        //         if User.FindFirst() then
        //             if (User."Contact Email" <> '') And (User."Contact Email" <> EmailSupervisor) and (User."Contact Email" <> EmailResponsabe) then
        //                 ListaCorreo := ListaCorreo + User."Contact Email" + ';';
        //     until UserxbyCategory.Next() = 0;
        // UserxbyCategory.Reset();
        UserxbyCategory.SetRange(Departamento);
        UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange(Responsable);
        UserxbyCategory.SetRange(Supervisor);
        UserxbyCategory.SetRange("Copiado en Mail", true);
        User.Reset();
        If UserxbyCategory.FindFirst() then
            repeat
                User.SetRange("User Security ID", UserxbyCategory."User Security ID");
                if User.FindFirst() then
                    if (User."Contact Email" <> '') and (User."Contact Email" <> EmailResponsabe) and (User."Contact Email" <> EmailSupervisor) then
                        ListaCorreo := ListaCorreo + User."Contact Email" + ';';
            until UserxbyCategory.Next() = 0;

    end;

    internal procedure DevuelveCategoriaSupervisorResponsablePorZona(
       TipoTarea: Text;
       ZonaLimpieza: Integer;
       Var Responsable: Guid;
       var Supervisor: Guid;
       var Categoria: Text;
       var Departamento: Text;
       var Servicio: Text;
       var EmailResponsabe: Text;
       var EmailSupervisor: Text;
       VAR User: Record "User";
       Var UserTask: Record "User Task";
       var ListaCorreo: Text)
    var
        ZonasLimpieza: Record "Zonas Limpieza";
    begin
        if ZonaLimpieza = 0 then
            Error('Indique la zona de limpieza.');
        if not ZonasLimpieza.Get(ZonaLimpieza) then
            Error('Zona de limpieza %1 no encontrada.', ZonaLimpieza);
        If TipoTarea <> ZonasLimpieza."Tipo Tarea" then
            Error('El tipo de tarea %1 no coincide con el tipo de tarea de la zona de limpieza %2.', TipoTarea, ZonasLimpieza."Tipo Tarea");

        // Recoger todos los datos de la zona de limpieza
        Categoria := ZonasLimpieza.Categoria;
        Departamento := ZonasLimpieza.Departamento;
        Servicio := ZonasLimpieza.Servicio;
        Responsable := ZonasLimpieza.Responsable;
        Supervisor := ZonasLimpieza.Supervisor;

        if Categoria = '' then
            Error('No está definida la categoría en la zona de limpieza %1.', ZonasLimpieza.Descripción);
        if Departamento = '' then
            Error('No está definido el departamento en la zona de limpieza %1.', ZonasLimpieza.Descripción);
        if IsNullGuid(Responsable) then
            Error('No está definido el responsable en la zona de limpieza %1.', ZonasLimpieza.Descripción);
        if IsNullGuid(Supervisor) then
            Error('No está definido el supervisor en la zona de limpieza %1.', ZonasLimpieza.Descripción);

        // Obtener emails de responsable y supervisor
        User.SetRange("User Security ID", Supervisor);
        if User.FindFirst() then
            EmailSupervisor := User."Contact Email";
        User.SetRange("User Security ID", Responsable);
        if User.FindFirst() then
            EmailResponsabe := User."Contact Email";

        // Lista de correos en copia desde la zona
        ListaCorreo := ZonasLimpieza."Correos Copia";

        // Asignar valores al UserTask
        UserTask.Validate(Servicio, Servicio);
        UserTask.Validate(Departamento, Departamento);
        UserTask.Validate("Categoría", Categoria);
        UserTask."Assigned To" := Responsable;
        UserTask."Supervisor" := Supervisor;
        UserTask.Validate("Created By", UserSecurityId());
    end;

    internal procedure Email(
       UserTask: Record "User Task"; var EmailResponsable: Text; var EmailSupervisor: Text)
    var
        UserGtaskMalla: Record UsuariosGtask;
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        UserGtaskMalla.SetRange("Id Usuario", UserTask."Assigned To");
        If UserGtaskMalla.FindFirst() then begin
            EmailResponsable := UserGtaskMalla.Email;
        end;
        UserGtaskMalla.SetRange("Id Usuario", UserTask.Supervisor);
        If UserGtaskMalla.FindFirst() then begin
            EmailSupervisor := UserGtaskMalla.Email;
        end;

    end;


    procedure EnviaCorreoComercial(Asunto: Text; Var Contrato: Record "Sales Header"; SalesPersonCode: Code[20]; Adjunto: Boolean; Estado: Text; Base64Data: Text)
    var
        Mail: Codeunit Mail;
        Salesperson2: Record 13;
        Body: Text;
        Customer: Record 18;
        Empleados: Record Employee;
        BigText: Text;
        REmail: Record "Email Item" temporary;
        emilesc: Enum "Email Scenario";
        rInf: Record "Company Information";
        Funciones: Codeunit "Funciones Correo PDF";
        AttachmentStream: InStream;
        out: OutStream;
        Secuencia: Integer;
        ficheros: Record Ficheros;
        SalesHeader: Record "Sales Header";
        Recref: RecordRef;
        Base64Convert: Codeunit "Base64 Convert";
        Base64: Text;
        DocAtch: Record "Imagenes Orden fijación";
        Id: Integer;
        Url: Text;
        TempBlob: Codeunit "Temp Blob";
        Control: Codeunit "ControlProcesos";
    begin
        SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SETRANGE("No.", Contrato."No.");
        If Not SalesHeader.FINDFIRST Then SalesHeader.init;
        Salesperson2.Get(SalesPersonCode);
        Salesperson2.TestField("E-Mail");
        Empleados.ChangeCompany('Malla Publicidad');
        Empleados.SetRange("Salespers./Purch. Code", SalesPersonCode);
        if not Empleados.FindFirst then begin
            Empleados.Name := CopyStr(Salesperson2.Name, 1, StrPos(Salesperson2.Name, ' ') - 1);
        end;
        rInf.Get();

        if Time < 140000T then
            BigText := ('Buenos días, ')
        else if Time < 200000T then
            BigText := ('Buenas tardes, ')
        else
            BigText := ('Buenas noches, ');
        BigText += Empleados.Name + ':';
        BigText := BigText + '<br> </br>';
        Clear(TempBlob);
        If Adjunto then begin
            If Base64Data = '' Then begin
                Recref.GetTable(SalesHeader);
                TempBlob.CreateOutStream(Out);
                REPORT.SaveAs(Report::"Contrato", '', ReportFormat::Pdf, out, Recref);
                TempBlob.CreateInStream(AttachmentStream);
                Base64Data := Base64Convert.ToBase64(AttachmentStream);
#If CLEAN27
                Url := Control.FormBase64ToUrl(Base64Data, Contrato."No." + '.pdf', Id);
#else
                Url := DocAtch.FormBase64ToUrl(Base64Data, Contrato."No." + '.pdf', Id);
#endif

            end else
#If CLEAN27
                Url := Control.FormBase64ToUrl(Base64Data, Contrato."No." + '.pdf', Id);
#else
                Url := DocAtch.FormBase64ToUrl(Base64Data, Contrato."No." + '.pdf', Id);
#endif
            BigText := BigText + '<br> </br>';
            BigText := BigText + ('El Contrato nº. <b><a href="' + url + '">' + Contrato."No." + '</a></b>');
            BigText := BigText + (', ha cambiado de estado a: <b>' + (Estado) + ' .</b>');

        end else begin
            BigText := BigText + '<br> </br>';
            BigText := BigText + ('El Contrato nº. <b>' + Contrato."No." + '</b>');
            BigText := BigText + (', ha cambiado de estado a: <b>' + (Estado) + ' .</b>');
        end;
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Cliente: <b>' + Contrato."Sell-to Customer Name" + ' </b>');
        BigText := BigText + ('(' + Contrato."Posting Description" + ')');
        BigText := BigText + '<br> </br>';

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
        Funciones.CargaPie(Base64);
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
        BigText := BigText + '</font>';
        REmail.Subject := Asunto;
        REmail."Send To" := Salesperson2."E-Mail";
        if REmail."Send to" = 'croldan@malla.es' then begin
            if REmail."Send CC" = '' then
                REmail."Send CC" := 'rserra@malla.es'
            else
                REmail."Send CC" := REmail."Send CC" + ';rserra@malla.es';
        end;
        REmail."Send BCC" := 'andreuserra@malla.es';
        REmail.SetBodyText(BigText);
        REmail."From Name" := UserId;

        if REmail.Send(true, emilesc::Comercial) then begin

        end;
    end;

    /// <summary>
    /// Procesa imagen con LM Studio para extraer número de parada e incidencia
    /// LM Studio debe estar corriendo en http://192.168.10.253:1234
    /// </summary>
    /// <param name="ImageBase64">Imagen en formato base64</param>
    /// <returns>JSON con stop_number y description, o error</returns>
    procedure ProcessImageWithLMStudio(ImageBase64: Text): Text
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        RequestBody: Text;
        ResponseText: Text;
        JsonPayload: JsonObject;
        JsonMessages: JsonArray;
        JsonMessage: JsonObject;
        JsonContent: JsonArray;
        JsonTextContent: JsonObject;
        JsonImageContent: JsonObject;
        JsonImageUrl: JsonObject;
        JsonResponse: JsonObject;
        JsonChoices: JsonArray;
        JsonChoice: JsonObject;
        JsonMessageResponse: JsonObject;
        JsonCampo: JsonToken;
        StopNumber: Text;
        Description: Text;
        CleanBase64: Text;
        ImageFormat: Text;
        ResultJson: JsonObject;
        LMStudioUrl: Text;
        Prompt: Text;
        CommaPos: Integer;
    begin
        // Limpiar el base64 si viene como data URL
        CleanBase64 := ImageBase64;
        if CopyStr(CleanBase64, 1, 10) = 'data:image' then begin
            // Extraer el base64 puro
            CommaPos := StrPos(CleanBase64, ',');
            if CommaPos > 0 then
                CleanBase64 := CopyStr(CleanBase64, CommaPos + 1);
        end;

        // Detectar formato de imagen
        ImageFormat := 'jpeg';
        if CopyStr(ImageBase64, 1, 15) = 'data:image/png' then
            ImageFormat := 'png'
        else if CopyStr(ImageBase64, 1, 15) = 'data:image/jpg' then
            ImageFormat := 'jpeg'
        else if CopyStr(ImageBase64, 1, 16) = 'data:image/jpeg' then
            ImageFormat := 'jpeg';

        // URL de LM Studio
        LMStudioUrl := 'http://192.168.10.253:1234/v1/chat/completions';

        // Prompt para el modelo
        Prompt := 'En esta parada de autobús, me puedes indicar el número de parada que empieza por la letra P seguida de números , busca en toda la imagen, no confundir con el numero de linea que está en un cartel del color de la linea , y la descripción de la incidencia o pintada que ves en la imagen?. Devuelve un json, con Numero de parada, descripción de la incidencia, pasos seguidos y conclusión';

        // Construir el payload JSON
        Clear(JsonPayload);
        Clear(JsonMessages);
        Clear(JsonMessage);
        Clear(JsonContent);
        Clear(JsonTextContent);
        Clear(JsonImageContent);
        Clear(JsonImageUrl);

        // Crear el objeto de contenido de texto
        JsonTextContent.Add('type', 'text');
        JsonTextContent.Add('text', Prompt);
        JsonContent.Add(JsonTextContent);

        // Crear el objeto de contenido de imagen
        JsonImageUrl.Add('url', 'data:image/' + ImageFormat + ';base64,' + CleanBase64);
        JsonImageContent.Add('type', 'image_url');
        JsonImageContent.Add('image_url', JsonImageUrl);
        JsonContent.Add(JsonImageContent);

        // Crear el mensaje
        JsonMessage.Add('role', 'user');
        JsonMessage.Add('content', JsonContent);
        JsonMessages.Add(JsonMessage);

        // Crear el payload completo
        JsonPayload.Add('model', 'google/gemma-3-27b');
        JsonPayload.Add('messages', JsonMessages);
        JsonPayload.Add('temperature', 0.2);
        JsonPayload.Add('max_tokens', 800);

        // Convertir a texto
        JsonPayload.WriteTo(RequestBody);

        // Configurar el contenido HTTP
        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        // Configurar la petición
        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(LMStudioUrl);
        HttpRequestMessage.Content(HttpContent);

        // Configurar timeout
        HttpClient.Timeout(180000); // 180 segundos en milisegundos

        // Enviar la petición
        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResultJson.Add('success', false);
            ResultJson.Add('error', 'No se puede conectar a LM Studio. Asegúrate de que LM Studio esté corriendo en http://192.168.10.253:1234');
            ResultJson.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        // Leer la respuesta
        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            HttpResponseMessage.Content().ReadAs(ResponseText);
            ResultJson.Add('success', false);
            if HttpResponseMessage.HttpStatusCode() = 404 then
                ResultJson.Add('error', 'LM Studio no tiene un modelo cargado. Por favor carga un modelo en LM Studio.')
            else
                ResultJson.Add('error', 'LM Studio respondió con código ' + Format(HttpResponseMessage.HttpStatusCode()) + ': ' + ResponseText);
            ResultJson.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);

        // Procesar la respuesta
        Clear(JsonResponse);
        if not JsonResponse.ReadFrom(ResponseText) then begin
            ResultJson.Add('success', false);
            ResultJson.Add('error', 'Error al parsear la respuesta de LM Studio');
            ResultJson.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        // Extraer el contenido de la respuesta
        if JsonResponse.Get('choices', JsonCampo) then begin
            JsonChoices := JsonCampo.AsArray();
            if JsonChoices.Count() > 0 then begin
                JsonChoices.Get(0, JsonCampo);
                JsonChoice := JsonCampo.AsObject();
                if JsonChoice.Get('message', JsonCampo) then begin
                    JsonMessageResponse := JsonCampo.AsObject();
                    if JsonMessageResponse.Get('content', JsonCampo) then begin
                        ResponseText := JsonCampo.AsValue().AsText();
                    end;
                end;
            end;
        end;

        // Extraer JSON del bloque de código markdown si existe
        ResponseText := ExtractJsonFromMarkdown(ResponseText);

        // Extraer información de la respuesta
        StopNumber := ExtractStopNumber(ResponseText);
        Description := ExtractDescription(ResponseText);

        // Construir resultado
        Clear(ResultJson);
        ResultJson.Add('success', true);
        if StopNumber <> '' then
            ResultJson.Add('stop_number', StopNumber)
        else
            ResultJson.Add('stop_number', '');
        ResultJson.Add('description', Description);
        ResultJson.Add('raw_response', ResponseText);

        ResultJson.WriteTo(ResponseText);
        exit(ResponseText);
    end;

    local procedure ExtractJsonFromMarkdown(Content: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
        JsonStart: Integer;
        JsonEnd: Integer;
    begin
        // Buscar bloque de código markdown con JSON
        StartPos := StrPos(Content, '```json');
        if StartPos = 0 then
            StartPos := StrPos(Content, '```');

        if StartPos > 0 then begin
            // Buscar el inicio del JSON (después de ```json o ```)
            JsonStart := StartPos;
            if CopyStr(Content, StartPos, 7) = '```json' then
                JsonStart := StartPos + 7
            else if CopyStr(Content, StartPos, 3) = '```' then
                JsonStart := StartPos + 3;

            // Buscar el inicio real del JSON (primer '{')
            while (JsonStart <= StrLen(Content)) and (Content[JsonStart] <> '{') do
                JsonStart += 1;

            if JsonStart > StrLen(Content) then
                exit(Content);

            // Buscar el final del bloque (```)
            EndPos := StrPos(CopyStr(Content, JsonStart), '```');
            if EndPos > 0 then begin
                // Buscar el último '}' antes del ```
                JsonEnd := JsonStart + EndPos - 2;
                while (JsonEnd >= JsonStart) and (Content[JsonEnd] <> '}') do
                    JsonEnd -= 1;
                JsonEnd += 1;
            end else
                JsonEnd := StrLen(Content);

            // Extraer el JSON
            if JsonEnd > JsonStart then
                exit(CopyStr(Content, JsonStart, JsonEnd - JsonStart + 1));
        end;

        // Si no hay bloque de código, devolver el contenido original
        exit(Content);
    end;

    local procedure ExtractStopNumber(ResponseText: Text): Text
    var
        JsonResponse: JsonObject;
        JsonCampo: JsonToken;
        StopNumber: Text;
        PCodeMatch: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        // Primero intentar extraer del JSON si existe
        if JsonResponse.ReadFrom(ResponseText) then begin
            if JsonResponse.Get('stop_number', JsonCampo) then begin
                StopNumber := JsonCampo.AsValue().AsText();
                if (StopNumber <> '') and (StopNumber <> 'null') and (StopNumber <> 'None') then
                    exit(StopNumber);
            end;
            if JsonResponse.Get('Numero de parada', JsonCampo) then begin
                StopNumber := JsonCampo.AsValue().AsText();
                if (StopNumber <> '') and (StopNumber <> 'null') and (StopNumber <> 'None') then
                    exit(StopNumber);
            end;
        end;

        // Buscar código P seguido de números en el texto
        StartPos := StrPos(ResponseText, 'P');
        if StartPos > 0 then begin
            // Buscar el número después de la P
            EndPos := StartPos + 1;
            while (EndPos <= StrLen(ResponseText)) and (ResponseText[EndPos] in ['0' .. '9']) do
                EndPos += 1;
            if EndPos > StartPos + 1 then begin
                PCodeMatch := CopyStr(ResponseText, StartPos, EndPos - StartPos);
                if StrLen(PCodeMatch) >= 4 then // P + al menos 3 dígitos
                    exit(PCodeMatch);
            end;
        end;

        exit('');
    end;

    local procedure ExtractDescription(ResponseText: Text): Text
    var
        JsonResponse: JsonObject;
        JsonCampo: JsonToken;
        Description: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        // Primero intentar extraer del JSON si existe
        if JsonResponse.ReadFrom(ResponseText) then begin
            // Buscar diferentes variantes del campo de descripción
            // Prioridad: "descripción de la incidencia" > "descripcion de la incidencia" > "description" > "descripción" > "descripcion"
            if JsonResponse.Get('descripción de la incidencia', JsonCampo) then begin
                Description := JsonCampo.AsValue().AsText();
                if (Description <> '') and (Description <> 'null') and (Description <> 'None') and (Description <> 'Sin incidencia visible') then
                    exit(Description);
            end;
            if JsonResponse.Get('descripcion de la incidencia', JsonCampo) then begin
                Description := JsonCampo.AsValue().AsText();
                if (Description <> '') and (Description <> 'null') and (Description <> 'None') and (Description <> 'Sin incidencia visible') then
                    exit(Description);
            end;
            if JsonResponse.Get('description', JsonCampo) then begin
                Description := JsonCampo.AsValue().AsText();
                if (Description <> '') and (Description <> 'null') and (Description <> 'None') and (Description <> 'Sin incidencia visible') then
                    exit(Description);
            end;
            if JsonResponse.Get('descripción', JsonCampo) then begin
                Description := JsonCampo.AsValue().AsText();
                if (Description <> '') and (Description <> 'null') and (Description <> 'None') and (Description <> 'Sin incidencia visible') then
                    exit(Description);
            end;
            if JsonResponse.Get('descripcion', JsonCampo) then begin
                Description := JsonCampo.AsValue().AsText();
                if (Description <> '') and (Description <> 'null') and (Description <> 'None') and (Description <> 'Sin incidencia visible') then
                    exit(Description);
            end;
        end;

        // Buscar descripción en el texto (buscar después de "descripción")
        StartPos := StrPos(ResponseText, 'descripción');
        if StartPos = 0 then
            StartPos := StrPos(ResponseText, 'description');
        if StartPos > 0 then begin
            // Buscar el valor después de los dos puntos (buscar desde StartPos)
            StartPos := StrPos(CopyStr(ResponseText, StartPos), ':');
            if StartPos > 0 then
                StartPos := StartPos + StrPos(ResponseText, 'descripción') - 1;
            if StartPos = 0 then begin
                StartPos := StrPos(ResponseText, 'description');
                if StartPos > 0 then begin
                    StartPos := StrPos(CopyStr(ResponseText, StartPos), ':');
                    if StartPos > 0 then
                        StartPos := StartPos + StrPos(ResponseText, 'description') - 1;
                end;
            end;
            if StartPos > 0 then begin
                StartPos += 1;
                // Saltar espacios
                while (StartPos <= StrLen(ResponseText)) and (ResponseText[StartPos] = ' ') do
                    StartPos += 1;
                // Buscar hasta el final o hasta una comilla
                EndPos := StartPos;
                while (EndPos <= StrLen(ResponseText)) and (ResponseText[EndPos] <> '"') and (ResponseText[EndPos] <> '}') do
                    EndPos += 1;
                if EndPos > StartPos then begin
                    Description := CopyStr(ResponseText, StartPos, EndPos - StartPos);
                    Description := DelChr(Description, '<>', ' "');
                    if Description <> '' then
                        exit(Description);
                end;
            end;
        end;

        exit('Sin incidencia visible');
    end;

    internal procedure ParseFechaFromJson(FechaTexto: Text): DateTime
    var
        Anio: Integer;
        Mes: Integer;
        Dia: Integer;
        Hora: Integer;
        Minuto: Integer;
        Segundo: Integer;
        FechaDate: Date;
        FechaTime: Time;
        PosGuion1: Integer;
        PosGuion2: Integer;
        PosT: Integer;
        PosDosPuntos1: Integer;
        PosDosPuntos2: Integer;
        FechaPart: Text;
        HoraPart: Text;
        TimeString: Text;
        DateTime: DateTime;
    begin
        If Evaluate(DateTime, FechaTexto) then
            exit(DateTime);
        // Formato puede ser: "2025-11-11" o "2025-11-11T23:00:00Z"
        FechaTexto := DelChr(FechaTexto, '<>', ' "');

        // Buscar si tiene hora (formato ISO con T)
        PosT := StrPos(FechaTexto, 'T');
        if PosT > 0 then begin
            // Tiene hora: "2025-11-11T23:00:00Z"
            FechaPart := CopyStr(FechaTexto, 1, PosT - 1);
            HoraPart := CopyStr(FechaTexto, PosT + 1);
            // Quitar la Z del final si existe
            if CopyStr(HoraPart, StrLen(HoraPart)) = 'Z' then
                HoraPart := CopyStr(HoraPart, 1, StrLen(HoraPart) - 1);
        end else begin
            // Solo fecha: "2025-11-11"
            FechaPart := FechaTexto;
            HoraPart := '';
        end;

        // Parsear la fecha (formato: AAAA-MM-DD)
        PosGuion1 := StrPos(FechaPart, '-');
        if PosGuion1 = 0 then
            exit(CurrentDateTime());

        // Extraer año
        if not Evaluate(Anio, CopyStr(FechaPart, 1, PosGuion1 - 1)) then
            exit(CurrentDateTime());

        PosGuion2 := StrPos(CopyStr(FechaPart, PosGuion1 + 1), '-');
        if PosGuion2 = 0 then
            exit(CurrentDateTime());

        // Extraer mes
        if not Evaluate(Mes, CopyStr(FechaPart, PosGuion1 + 1, PosGuion2 - 1)) then
            exit(CurrentDateTime());

        // Extraer día
        if not Evaluate(Dia, CopyStr(FechaPart, PosGuion1 + PosGuion2 + 1)) then
            exit(CurrentDateTime());

        // Crear la fecha
        FechaDate := DMY2Date(Dia, Mes, Anio);

        // Parsear la hora si existe (formato: HH:MM:SS)
        if HoraPart <> '' then begin
            // Dividir la hora por los dos puntos
            // Formato esperado: HH:MM:SS o HH:MM
            PosDosPuntos1 := StrPos(HoraPart, ':');
            if PosDosPuntos1 > 0 then begin
                // Extraer hora (antes del primer :)
                // Parsear manualmente para evitar problemas con "08"
                TimeString := CopyStr(HoraPart, 1, PosDosPuntos1 - 1);
                TimeString := DelChr(TimeString, '<>', ' ');
                // Convertir manualmente para evitar problemas con números que empiezan con 0
                if StrLen(TimeString) = 2 then begin
                    // Formato HH, parsear cada dígito
                    if (TimeString[1] >= '0') and (TimeString[1] <= '9') and
                       (TimeString[2] >= '0') and (TimeString[2] <= '9') then
                        Hora := (TimeString[1] - '0') * 10 + (TimeString[2] - '0')
                    else
                        if not Evaluate(Hora, TimeString) then
                            Hora := 0;
                end else
                    if not Evaluate(Hora, TimeString) then
                        Hora := 0;

                // Buscar el segundo dos puntos (después del primer :)
                PosDosPuntos2 := StrPos(CopyStr(HoraPart, PosDosPuntos1 + 1), ':');
                if PosDosPuntos2 > 0 then begin
                    // Hay segundo dos puntos, extraer minuto y segundo
                    // Minuto está entre PosDosPuntos1+1 y PosDosPuntos1+PosDosPuntos2
                    TimeString := CopyStr(HoraPart, PosDosPuntos1 + 1, PosDosPuntos2 - 1);
                    TimeString := DelChr(TimeString, '<>', ' ');
                    if not Evaluate(Minuto, TimeString) then
                        Minuto := 0;

                    // Segundo está después de PosDosPuntos1+PosDosPuntos2+1
                    TimeString := CopyStr(HoraPart, PosDosPuntos1 + PosDosPuntos2 + 1);
                    TimeString := DelChr(TimeString, '<>', ' ');
                    if not Evaluate(Segundo, TimeString) then
                        Segundo := 0;
                end else begin
                    // Solo hay un dos puntos, solo hora y minuto
                    TimeString := CopyStr(HoraPart, PosDosPuntos1 + 1);
                    TimeString := DelChr(TimeString, '<>', ' ');
                    if not Evaluate(Minuto, TimeString) then
                        Minuto := 0;
                    Segundo := 0;
                end;
            end else begin
                Hora := 0;
                Minuto := 0;
                Segundo := 0;
            end;

            // Crear Time usando formato HHMMSST (ej: 080000T)
            // Formatear como string HHMMSST con padding de ceros
            if Hora < 10 then
                TimeString := '0' + Format(Hora)
            else
                TimeString := Format(Hora);

            if Minuto < 10 then
                TimeString := TimeString + '0' + Format(Minuto)
            else
                TimeString := TimeString + Format(Minuto);

            if Segundo < 10 then
                TimeString := TimeString + '0' + Format(Segundo)
            else
                TimeString := TimeString + Format(Segundo);

            //TimeString := TimeString + 'T';

            Evaluate(FechaTime, TimeString);
            //    FechaTime := 0T;
        end else
            FechaTime := 0T;

        exit(CreateDateTime(FechaDate, FechaTime));
    end;

    internal procedure UpdateTaskGtaskBak(Id_Tarea: Text[250]; ID: Integer)
    var
        Ficheros: Record Ficheros;
        Secuencia: Integer;
    begin
        ficheros.Reset();
        if ficheros.FindLast() then Secuencia := ficheros.Secuencia + 1 else Secuencia := 1;
        ficheros.Secuencia := Secuencia;
        ficheros."Nombre fichero" := Id_Tarea;
        ficheros."Incoming Entry No." := ID;
        ficheros.Proceso := 'UPDATEGTASK';
        repeat
            ficheros.Secuencia := Secuencia;
            Secuencia += 1;
        Until ficheros.Insert();
    end;

    internal procedure ProcesarZonaLimpiezaParada(var JsonTarea: JsonObject; var Emplazamientos: Record "Emplazamientos"; var JsonErrores: JsonArray): Boolean
    var
        JsonCampo: JsonToken;
        JsonError: JsonObject;
        IdParada: Code[20];
        ZonaLimpieza: Text;
        ZonasLimpieza: Record "Zonas Limpieza";
        Id: Integer;
    begin
        if not JsonTarea.Get('id', JsonCampo) then begin
            Clear(JsonError);
            JsonError.Add('mensaje', 'Falta el campo id');
            JsonErrores.Add(JsonError);
            exit(false);
        end;
        IdParada := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(IdParada));
        if IdParada = '' then begin
            Clear(JsonError);
            JsonError.Add('mensaje', 'El campo id está vacío');
            JsonErrores.Add(JsonError);
            exit(false);
        end;

        if not JsonTarea.Get('zonaLimpieza', JsonCampo) then begin
            Clear(JsonError);
            JsonError.Add('id', IdParada);
            JsonError.Add('mensaje', 'Falta el campo zonaLimpieza');
            JsonErrores.Add(JsonError);
            exit(false);
        end;
        // if not Evaluate(ZonaLimpieza, JsonCampo.AsValue().AsText()) then begin
        //     Clear(JsonError);
        //     JsonError.Add('id', IdParada);
        //     JsonError.Add('mensaje', 'zonaLimpieza debe ser un número entero');
        //     JsonErrores.Add(JsonError);
        //     exit(false);
        // end;

        if not Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, IdParada) then begin
            Clear(JsonError);
            JsonError.Add('id', IdParada);
            JsonError.Add('mensaje', 'Parada no encontrada');
            JsonErrores.Add(JsonError);
            exit(false);
        end;
        ZonasLimpieza.SetRange("Descripción", ZonaLimpieza);
        if not ZonasLimpieza.FindFirst() then begin
            ZonasLimpieza.reset;
            If ZonasLimpieza.findlast then Id := ZonasLimpieza.Id;
            ZonasLimpieza.Init;
            ZonasLimpieza.Id := Id + 1;
            ZonasLimpieza.Validate("Descripción", ZonaLimpieza);
            ZonasLimpieza.Insert;
        end;
        Emplazamientos.Validate("Zona Limpieza", ZonasLimpieza.Id);
        Emplazamientos.Modify(true);
        exit(true);
    end;

    internal procedure GetRecursoNo(var Doc: Record "Document Attachment"; Empresa: Text): Text
    var
        DocumentAttachment: Record "Document Attachment";
        Reserva: Record Reserva;
    begin
        If Doc."Table ID" in [Database::"User Task", Database::job] then begin
            if Empresa <> '' then
                DocumentAttachment.ChangeCompany(Empresa);
            DocumentAttachment.SetRange("Table ID", Database::"Orden fijación");
            DocumentAttachment.SetRange("No.", Doc."No.");
            DocumentAttachment.SetRange("File Name", Doc."File Name");
            if DocumentAttachment.FindFirst() then begin
                if Empresa <> '' then
                    Reserva.ChangeCompany(Empresa);
                if Reserva.Get(DocumentAttachment."Line No.") then
                    exit(Reserva."Nº Recurso");
            end;

        end;
        exit('');

    end;


}