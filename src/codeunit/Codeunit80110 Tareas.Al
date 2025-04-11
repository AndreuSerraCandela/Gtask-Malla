/// <summary>
/// Codeunit GTask (ID 80110).
/// </summary>
codeunit 7001148 GTask
{
    var
        Qwark: Option Ocr,Qwark;
        LToken: Text;

    trigger OnRun()
    begin
        //UpdateTasks();
        GetTareas();

    end;

    procedure Token(): Text;
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Link: Record "Data Migration Error";
        IdLink: Integer;
    begin
        CompanyInfo.Get();
        If LToken = '' Then
            RestApi.RecuperarToken(CompanyInfo."Url Task", CompanyInfo."Usuario Task", CompanyInfo."PassWord Task", Ltoken, Qwark::Ocr);

        exit(LToken);
    end;

    procedure UpdateTasks()
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
    begin
        CompanyInfo.Get();
        Desde := CreateDateTime(CalcDate('-1D', Today), 0T);
        Tareas.SetRange("Fecha Cambio", Desde, CurrentDateTime);
        Tareas.SetFilter(Id_Tarea, '<>%1', '');
        If Tareas.FindFirst() then
            repeat
                if Tareas."Fecha Comunicado Cambio" = 0DT Then Tareas."Fecha Comunicado Cambio" := CreateDateTime(CalcDate('-2D', Today), 0T);
                If Tareas."Fecha Comunicado Cambio" <= Tareas."Fecha Cambio" then begin
                    Tareas."Fecha Comunicado Cambio" := CurrentDateTime;
                    Tareas.Modify();
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
                    //TODO: Add code to update the task
                    //JsonObjt.Add('user', responsable);
                    JsonObjt.Add('supervisor', "Supervisor");
                    departament := Tareas.Departamento;
                    service := Tareas.Servicio;
                    If (departament <> '') and (service <> '') then begin
                        CrearDepartamnetoyServicio(departament, service);
                        JsonObjt.Add('department', departament);
                        JsonObjt.Add('service', service);
                        JsonObjt.Add('date', Hora(Tareas."Start DateTime"));
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
                    JsonObjt.WriteTo(Json);
                    Clear(RestApi);
                    Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Token(), RequestType::put, Json);

                end;
                GetSetDocattchment(Tareas, Tareas.Id_Tarea);
                GetSetChat(Tareas, Tareas.Id_Tarea);
            until Tareas.Next() = 0;


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
                CrearDepartamnetoyServicio(departament, service);
                JsonObjt.Add('department', Departament);
                JsonObjt.Add('service', service);
                JsonObjt.Add('date', Hora(Tareas."Start DateTime"));
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
            JsonObjt.WriteTo(Json);
            Clear(RestApi);

            Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Token(), RequestType::put, Json);
            // GetSetChat(Tareas, Tareas.Id_Tarea);
        End;


    end;

    Procedure GetSetDocattchment(var Tarea: Record "User Task"; Id_Tarea: Text);
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        JsonCampo: JsonToken;
        JSonObjt: JsonObject;
        JSonDocuments: JsonArray;
        JsonDocument: JsonObject;
        JsonDocumentInf: JsonObject;
        JsonDocumentToken: JsonToken;
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentTMP: Record "Document Attachment" temporary;
        Line: Integer;
        CompanyInfo: Record "Company Information";
        Json: Text;
        Restapi: Codeunit "Control Ocr";
        Base64Data: Text;
        Int: InStream;
        DocumentStream: Outstream;
        TempBlob: Codeunit "Temp Blob";
        Bs64: Codeunit "Base64 Convert";
        Ordenfijacion: Record "Cab Orden fijación";
        RequestType: Option Get,patch,put,post,delete;
        DocUrl: Text;
        DocName: Text;
        a: Integer;
    begin
        //Get https://gtasks-api.deploy.malla.es/task/67ac9479d035cb001379b780
        CompanyInfo.Get();
        if Tarea."No." = '' then
            exit;
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Id_Tarea, Token(), RequestType::Get, '');
        // "document": [
        //     {
        //         "_id": "67ac947ad035cb001379b795",
        //         "establishment": "6581485f67b6630011d83caf",
        //         "name": "184720-1051780.pdf",
        //         "document": {
        //             "_id": 39290,
        //             "name": "184720-1051780.pdf",
        //             "hash": "184720_1051780_d5ff60e4fd",
        //             "size": 279.36,
        //             "url": "https://storage-core.deploy.malla.es/uploads/184720_1051780_d5ff60e4fd.pdf"
        //         },
        //         "createdAt": "2025-02-12T12:30:50.398Z",
        //         "updatedAt": "2025-02-12T12:30:50.398Z",
        //         "__v": 0
        //     }
        // ],
        JSonObjt.ReadFrom(Json);
        JSonObjt.Get('document', JsonCampo);
        JSonDocuments := JsonCampo.AsArray();
        foreach JSonDocumentToken in JSonDocuments do begin
            JsonDocument := JSonDocumentToken.AsObject();

            If JsonDocument.Get('name', JsonCampo) then begin
                DocName := JsonCampo.AsValue().AsText();
                If JsonDocument.Get('document', JsonCampo) then begin
                    JsonDocumentinf := JsonCampo.AsObject();
                    Clear(JsonCampo);
                    JsonDocumentInf.Get('url', JsonCampo);
                    DocUrl := JsonCampo.AsValue().AsText();
                    DocumentAttachment.Reset();
                    DocumentAttachment.SetRange("Table ID", Database::"User Task");
                    DocumentAttachment.SetRange("No.", Tarea."No.");
                    DocumentAttachment.SetRange("File Name", DocName);
                    If Not DocumentAttachment.Findfirst() then begin
                        DocumentAttachment.SetRange("File name");
                        if DocumentAttachment.FindLast() then
                            Line := DocumentAttachment.Id + 1
                        else
                            Line := 1;
                        DocumentAttachment.Init();
                        DocumentAttachment.Id := Line;
                        DocumentAttachment."Table ID" := Database::"User Task";
                        DocumentAttachment."No." := Tarea."No.";
                        DocumentAttachment."File Name" := DocName;
                        DocumentAttachment."URL" := DocUrl;
                        DocumentAttachment."Document Flow Service" := true;
                        DocumentAttachment.Insert();
                        If Tarea.OrdenFijacion <> 0 Then begin
                            If Ordenfijacion.Get(Tarea.OrdenFijacion) then
                                DocumentAttachment."Table ID" := Database::Job;
                            DocumentAttachment."No." := Ordenfijacion."Nº Proyecto";
                            repeat
                                DocumentAttachment."Line No." := a;
                                DocumentAttachment."Document Flow Service" := true;
                                a += 1;
                            until DocumentAttachment.Insert();
                            DocumentAttachment."Table ID" := Database::"Orden fijación";
                            DocumentAttachment."No." := Ordenfijacion."Nº Proyecto";
                            DocumentAttachment."Line No." := Tarea."Reserva";
                            repeat
                                DocumentAttachment."Line No." := a;
                                DocumentAttachment."Document Flow Service" := true;
                                a += 1;
                            until DocumentAttachment.Insert();
                        end;
                    end;
                    DocumentAttachmentTMP := DocumentAttachment;
                    If DocumentAttachmentTMP.Insert() Then;
                end;
            end;
        end;
        DocumentAttachmentTMP.reset;
        DocumentAttachment.SetRange("Table ID", Database::"User Task");
        DocumentAttachment.SetRange("No.", Tarea."No.");

        If DocumentAttachment.FindFirst() then
            repeat
                DocumentAttachmentTMP.SetRange("File Name", DocumentAttachment."File Name");
                If Not DocumentAttachmentTMP.FindLast() then begin
                    Clear(JsonFormater);
                    JsonFormater.WriteStartObject('');
                    Base64Data := '';
                    JsonFormater.WriteStringProperty('establishment', '6581485f67b6630011d83caf');
                    If DocumentAttachment."Document Reference ID".HasValue then begin
                        DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                        TempBlob.CreateInStream(Int);
                        Base64Data := Bs64.ToBase64(Int);
                    end else begin
                        if DocumentAttachment."Url" <> '' then begin
                            Base64Data := DocumentAttachment.ToBase64StringOcr(DocumentAttachment.Url);

                        end;
                    end;
                    JsonFormater.WriteStringProperty('document', Base64Data);
                    JsonFormater.WriteStringProperty('name', DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension");
                    JsonFormater.WriteEndObject();
                    Clear(RestApi);
                    Json := JsonFormater.GetJSonAsText();
                    CompanyInfo.Get();
                    Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/document/' + Id_Tarea, Token(), RequestType::put, jSon);
                end;
            until DocumentAttachment.Next() = 0;
        //GetSetChat(Tarea, Id_Tarea);
    end;

    procedure BusCaUsuario(Id: Text; var UserGtaskMalla: Record UsuariosGtask)
    var
        SalesPerson: Record "Salesperson/Purchaser";
        User: Record User;
        UserSetup: Record "User Setup";
    begin
        UserGtaskMalla.SetRange("Id Gtask", UserId);
        If not UserGtaskMalla.FindFirst() Then begin
            UserGtaskMalla.Init();
            UserGtaskMalla."Id Gtask" := UserId;
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

    Procedure GetSetChat(var Tarea: Record "User Task"; Id_Tarea: Text);
    var
        JsonTask: JsonObject;
        JsonCampo: JsonToken;
        JSonObjt: JsonObject;
        JSonChats: JsonArray;
        JsonChat: JsonObject;
        JsonChatToken: JsonToken;
        Chat: Record "To-Do";
        ChatTMP: Record "To-Do" temporary;
        Line: Integer;
        CompanyInfo: Record "Company Information";
        Json: Text;
        Restapi: Codeunit "Control Ocr";
        Base64Data: Text;
        Int: InStream;
        DocumentStream: Outstream;
        TempBlob: Codeunit "Temp Blob";
        Bs64: Codeunit "Base64 Convert";
        RequestType: Option Get,patch,put,post,delete;
        Texto: Text;
        UserId: Text;
        FechaHora: DateTime;
        UserGtaskMalla: Record UsuariosGtask;
        Resource: Record "Resource";
        Pnel: Record "PNEL";
        Emplazamiento: Record "Emplazamientos";
        ConfUser: Record "User Setup";
        User: Record User;
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        //Get https://gtasks-api.deploy.malla.es/task/67ac9479d035cb001379b780
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Id_Tarea, Token(), RequestType::Get, '');
        // "chat": [
        //     {
        //         "date": "2025-02-12T15:08:34.753Z",
        //         "text": "Prueba Put",
        //         "user": "65265e10e9202900197d6013"
        //     },
        //     {
        //         "date": "2025-02-12T15:08:34.753Z",
        //         "text": "Prueba Put2",
        //         "user": "65265e10e9202900197d6013"
        //     }
        // ]
        If Not JSonObjt.ReadFrom(Json) Then exit;
        JSonObjt.Get('chat', JsonCampo);
        JSonChats := JsonCampo.AsArray();
        foreach JSonChatToken in JSonChats do begin
            JsonChat := JsonChatToken.AsObject();
            If JsonChat.Get('user', JsonCampo) then begin
                UserId := JsonCampo.AsValue().AsText();
                JsonChat.Get('text', JsonCampo);
                Texto := JsonCampo.AsValue().AsText();
                JsonChat.Get('date', JsonCampo);
                FechaHora := JsonCampo.AsValue().AsDateTime();
                Chat.Reset();
                Chat.SetRange("Tabla", Database::"User Task");
                Chat.SetRange("ID_TABLA", Tarea.RecordId);
                Chat.SetRange("Descripción Visita", Texto);
                BusCaUsuario(UserId, UserGtaskMalla);
                Chat.SetRange("Salesperson Code", UserGtaskMalla.Tecnico);
                If Not Chat.Findfirst() then begin
                    Chat.Reset;
                    Chat.Init();
                    Chat."No." := '';
                    Chat.Emplazamiento := true;
                    Chat.Tabla := Database::"User Task";
                    Chat.Id_Tabla := Tarea.RecordId;
                    Case Tarea."Object ID" of
                        Page::"Resource Card":
                            begin
                                If Resource.Get(Tarea.Id_record) then
                                    Chat."Contact No." := Resource."Nº Emplazamiento";
                            end;
                        Page::"PNEL Emplazamientos":
                            begin
                                If Pnel.Get(Tarea.Id_record) then
                                    Chat."Contact No." := Pnel."Nº Emplazamiento";
                            end;
                        Page::"Ficha emplazamiento":
                            begin
                                If Emplazamiento.Get(Tarea.Id_record) then
                                    Chat."Contact No." := Emplazamiento."Nº Emplazamiento";
                            end;
                    End;
                    If Emplazamiento.Get(Chat."Contact No.") then
                        Chat."Wizard Contact Name" := Emplazamiento."Descripción";
                    Chat."Wizard Step" := Chat."Wizard Step"::"6";
                    Chat.Duration := 1440 * 1000 * 60;
                    Chat.Date := DT2Date(FechaHora);
                    Chat."Start Time" := DT2Time(FechaHora);
                    Chat."Ending Date" := DT2Date(FechaHora);
                    Chat."Ending Time" := Chat."Start Time" + Chat.Duration;
                    Chat."Descripción Visita" := Copystr(Texto, 1, MaxStrLen(Chat."Descripción Visita"));
                    Chat."All Day Event" := true;
                    Chat.Insert(true);
                end;

            end;

        end;
        Chat.Reset();
        Chat.SetRange("Tabla", Database::"User Task");
        Chat.SetRange("ID_TABLA", Tarea.RecordId);
        If Chat.FindFirst() then begin
            // {
            //     "chat":
            //     [  
            //         {
            //         "date": "2025-02-12T15:08:34.753Z",
            //         "text": "Prueba Put",
            //         "user": "65265e10e9202900197d6013"
            //         },
            //         {
            //         "date": "2025-02-12T15:08:34.753Z",
            //         "text": "Prueba Put2",
            //         "user": "65265e10e9202900197d6013"
            //         }
            //     ]
            // }
            Clear(JsonTask);
            Clear(JSonChats);
            repeat
                Clear(JsonChat);
                JsonChat.Add('date', Format(Chat.Date, 0, '<Year4>-<Month,2>-<Day,2>') + Format(Chat."Start Time", 0, 'T<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>.000Z'));
                JsonChat.Add('text', Chat."Descripción Visita");
                UserGtaskMalla.Reset();
                UserGtaskMalla.SetRange(Tecnico, Chat."Salesperson Code");
                If UserGtaskMalla.FindFirst() then
                    JsonChat.Add('user', UserGtaskMalla."Id Gtask");
                JsonChats.Add(JsonChat);
            until Chat.Next() = 0;
            JsonTask.Add('chat', JsonChats);
            JsonTask.WriteTo(Json);
            Clear(RestApi);
            Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Id_Tarea, Token(), RequestType::put, Json);
        end;
    end;


    procedure UpdateTask(idTarea: Text; IdNavision: Text)
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Json: Text;
        Id: Text;
        Link: Record "Data Migration Error";
        IdLink: Integer;
        Tareas: Record "User Task";
        Desde: DateTime;
        JsonObjt: JsonObject;
        responsable: Guid;

    begin
        CompanyInfo.Get();
        If Tareas.Get(IdNavision) then begin
            CompanyInfo.Get();
            IdNavision := CompanyInfo."Clave Recursos" + IdNavision;
            JsonObjt.Add('Id_Navision', IdNavision);
            JsonObjt.WriteTo(Json);
            Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Token(), RequestType::put, Json);
            Commit();
            GetSetDocattchment(Tareas, Tareas.Id_Tarea);
            GetSetChat(Tareas, Tareas.Id_Tarea);
        end;


    end;

    procedure CambiaEmpresa(CodeEmpresa: Text): Text;
    var
        Empresas: Record "Company";
        CompanyInfo: Record "Company Information";
    begin
        If Empresas.FindFirst() then
            repeat
                CompanyInfo.ChangeCompany(Empresas.Name);
                CompanyInfo.Get();
                if CompanyInfo."Clave Recursos" = CodeEmpresa then
                    exit(Empresas.Name);
            until Empresas.Next() = 0;
        exit('');
    end;

    procedure GetTarea(IdTarea: Text): Text
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        JsonObjt: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonCampo: JsonToken;
        JsonTarea: JsonObject;
        JsonDetalleCampo: JsonObject;
        Json: Text;
        Id: Integer;
        Tareas: Record "User Task";
        UserTaskGroup: Record "User Task Group";
        ResponsabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        UserGtaskMalla: Record UsuariosGtask;
        RecordiD: RecordId;
        RecordRef: RecordRef;
        Job: Record Job;
        CodEmpresa: Text[2];
        Texto: Text;
        JSonDocument: JsonObject;
        DocumentAtt: Record "Document Attachment";
        Line: Integer;
        DocUrl: Text;
        DocuName: Text;
    begin
        if IdTarea = '' then
            exit;

        CompanyInfo.Get();
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        // Obtener una tarea específica
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + IdTarea, Token(), RequestType::Get, '');

        if Json = '' then
            exit;

        JsonTarea.ReadFrom(Json);

        // Procesar la tarea
        If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
            Texto := JsonCampo.AsValue().AsText();
            If Not Evaluate(Id, Texto) then begin
                CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                Tareas.ChangeCompany(CambiaEmpresa(CodEmpresa));
                Texto := CopyStr(JsonCampo.AsValue().AsText(), 3, StrLen(JsonCampo.AsValue().AsText()));
            end;
            if Evaluate(Id, Texto) then begin
                if Tareas.Get(Id) then begin
                    // Actualizar estado
                    JsonTarea.Get('state', JsonCampo);
                    case JsonCampo.AsValue().AsText() of
                        'PENDING':
                            Tareas.Estado := Tareas.Estado::Pendiente;
                        'INPROCESS':
                            Tareas.Estado := Tareas.Estado::"En Proceso";
                        'FINISHED':
                            Tareas.Estado := Tareas.Estado::Finalizado;
                    end;
                    Tareas.Modify();
                    Tareas.Get(Id);
                    // Actualizar descripción
                    if JsonTarea.Get('observation', JsonCampo) then
                        if not JsonCampo.AsValue().IsNull then begin
                            Tareas.SetDescription(JsonCampo.AsValue().AsText());
                            Tareas.Get(Id);
                        end;
                    //Actualizar Responsable
                    if JsonTarea.Get('user', JsonCampo) then begin
                        UserGtaskMalla.SetRange("Id Gtask", JsonCampo.AsValue().AsText());
                        if UserGtaskMalla.FindFirst() then
                            Tareas."Assigned To" := UserGtaskMalla."Id Usuario";
                    end;
                    Tareas.Modify();
                end;
            end;
        end;
        if JsonTarea.Get('document', JsonCampo) then begin
            //Actualizar documentos
            JsonArray := JsonCampo.AsArray();
            If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
                Texto := JsonCampo.AsValue().AsText();
                If Not Evaluate(Id, Texto) then begin
                    CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                    Tareas.ChangeCompany(CambiaEmpresa(CodEmpresa));
                    Texto := CopyStr(JsonCampo.AsValue().AsText(), 3, StrLen(JsonCampo.AsValue().AsText()));
                end;
                if Evaluate(Id, Texto) then
                    if Tareas.Get(Id) then begin

                        If Tareas."No." = '' then begin
                            Tareas."No." := Format(Id);
                            Tareas.Modify();
                        end;

                        foreach JsonToken in JsonArray do begin
                            JsonDetalleCampo := JsonToken.AsObject();
                            If JsonDetalleCampo.Get('document', JsonCampo) then begin
                                JSonDocument := JsonCampo.AsObject();
                                If jSonDocument.Get('url', JsonCampo) then begin
                                    DocUrl := JsonCampo.AsValue().AsText();
                                    If jSonDocument.get('name', JsonCampo) then
                                        DocuName := JsonCampo.AsValue().AsText();
                                    DocumentAtt.Reset();
                                    DocumentAtt.SetRange("Table ID", Database::"User Task");
                                    DocumentAtt.SetRange("No.", Tareas."No.");
                                    DocumentAtt.SetRange("File Name", DocuName);
                                    If Not DocumentAtt.Findfirst() then begin
                                        DocumentAtt.SetRange("File Name");
                                        if DocumentAtt.FindLast() then
                                            Line := DocumentAtt.Id + 1
                                        else
                                            Line := 1;
                                        DocumentAtt.Init();
                                        DocumentAtt.Id := Line;
                                        DocumentAtt."Table ID" := Database::"User Task";
                                        DocumentAtt."No." := Tareas."No.";
                                        DocumentAtt."File Name" := DocuName;
                                        DocumentAtt."URL" := DocUrl;
                                        DocumentAtt.Insert();
                                    end;
                                end;
                            end;
                        end;
                    end;
            END;
        end;

    end;

    procedure GetTareas(): Text;
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        JsonObjt: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonCampo: JsonToken;
        JsonTarea: JsonObject;
        JsonDetalleCampo: JsonObject;
        Json: Text;
        Id: Integer;
        Tareas: Record "User Task";
        UserTaskGroup: Record "User Task Group";
        ResponsabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        UserGtaskMalla: Record UsuariosGtask;
        "TO-Do": Record "To-Do";
        IdTarea: Text;
        RecordiD: RecordId;
        RecordRef: RecordRef;
        Job: Record Job;
        Desde: Date;
        Hasta: Date;
        DaystoPerform: Text;
        jSonDocument: JsonObject;
        DocumentAtt: Record "Document Attachment";
        Line: Integer;
        DocUrl: Text;
        Num: Integer;
        CodEmpresa: Text[2];
        Empresas: Record "Company";
        Texto: Text;
        DocuName: Text;
    begin
        CompanyInfo.Get();
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task', Token(), RequestType::Get, '');
        JsonArray.ReadFrom(Json);
        foreach JsonToken in JsonArray do begin
            JsonTarea := JsonToken.AsObject();
            If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
                Texto := JsonCampo.AsValue().AsText();
                If Not Evaluate(Id, Texto) then begin
                    CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                    Tareas.ChangeCompany(CambiaEmpresa(CodEmpresa));
                    Texto := CopyStr(JsonCampo.AsValue().AsText(), 3, StrLen(JsonCampo.AsValue().AsText()));
                end;
                if Evaluate(Id, Texto) then begin
                    JsonTarea.Get('_id', JsonCampo);
                    IdTarea := JsonCampo.AsValue().AsText();
                    If Tareas.Get(Id) then begin
                        If Tareas."Fecha Cambio" = 0DT Then Tareas."Fecha Cambio" := CurrentDateTime;
                        If Tareas."Fecha Comunicado Cambio" = 0DT Then Tareas."Fecha Comunicado Cambio" := CurrentDateTime;
                        If Tareas."Fecha Comunicado Cambio" >= Tareas."Fecha Cambio" then begin
                            JsonTarea.Get('state', JsonCampo);
                            case JsonCampo.AsValue().AsText() of
                                'PENDING':
                                    begin
                                        Tareas.Estado := Tareas.Estado::Pendiente;
                                    end;
                                'INPROCESS':
                                    Tareas.Estado := Tareas.Estado::"En Proceso";
                                'FINISHED':
                                    Tareas.Estado := Tareas.Estado::Finalizado
                            end;
                            JsonTarea.Get('description', JsonCampo);
                            Tareas.Title := CopyStr(JsonCampo.AsValue().AsText(), 1, 250);
                            JsonTarea.Get('observation', JsonCampo);
                            if not JsonCampo.AsValue().IsNull then begin
                                Tareas.SetDescription(JsonCampo.AsValue().AsText());
                                Tareas.Get(Id);
                            end;
                            // "expirationDate": {
                            //     "date": "2023-11-02T10:31:04",
                            //     "rule": null,
                            //     "custom": false
                            // },
                            If JsonTarea.Get('expirationDate', JsonCampo)
                            then begin
                                JsonDetalleCampo := JsonCampo.AsObject();
                                JsonDetalleCampo.Get('date', JsonCampo);
                                Tareas."Due DateTime" := JsonCampo.AsValue().AsDateTime();
                            end;
                            //"daysToPerform": 0,
                            If JsonTarea.Get('daysToPerform', JsonCampo) then begin
                                Hasta := Variant2Date(Tareas."Due DateTime");
                                DaystoPerform := JsonCampo.AsValue().AsText();
                                If CopyStr(DaystoPerform, 1, 1) = '-' then
                                    Desde := CalcDate('0D', Hasta)
                                else
                                    Desde := CalcDate('-' + JsonCampo.AsValue().AsText() + 'D', Hasta);
                                Tareas."Start DateTime" := DaTi2Variant(Desde, Variant2Time(Tareas."Due DateTime"));
                            end;
                            //Actualizar supervisor
                            if JsonTarea.Get('supervisor', JsonCampo) then begin
                                UserGtaskMalla.SetRange("Id Gtask", JsonCampo.AsValue().AsText());
                                if UserGtaskMalla.FindFirst() then
                                    Tareas.Supervisor := UserGtaskMalla."Id Usuario";
                            end;
                            //Actulizar responsable
                            if JsonTarea.Get('user', JsonCampo) then begin
                                UserGtaskMalla.SetRange("Id Gtask", JsonCampo.AsValue().AsText());
                                if UserGtaskMalla.FindFirst() then
                                    Tareas."Assigned To" := UserGtaskMalla."Id Usuario";
                            end;

                            Tareas.Modify();

                        end;
                    end; //else
                         //If Id <> 0 Then DeleteTarea(IdTarea);
                end else begin
                    //crear tarea
                    Tareas.Reset();
                    If Tareas.FindLast() Then Id := Tareas."Id" + 1;
                    Tareas.Init();
                    Tareas."Id" := Id;
                    JsonTarea.Get('user', JsonCampo);
                    UserGtaskMalla.SetRange("Id Gtask", JsonCampo.AsValue().AsText());
                    If UserGtaskMalla.FindFirst() then
                        Tareas."Assigned To" := UserGtaskMalla."Id Usuario";
                    JsonTarea.Get('supervisor', JsonCampo);
                    UserGtaskMalla.SetRange("Id Gtask", JsonCampo.AsValue().AsText());
                    If UserGtaskMalla.FindFirst() then
                        Tareas."Supervisor" := UserGtaskMalla."Id Usuario";
                    If JsonTarea.Get('department', JsonCampo) Then begin
                        Clear(RecordiD);
                        RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::"Responsibility Center", CompanyName);
                        If RecordiD.TableNo <> 0 then begin
                            RecordRef := RecordiD.GetRecord();
                            Tareas.Departamento := RecordRef.Field(ResponsabilitiCenter.FieldNo(Code)).Value;
                        end else begin
                            Tareas.Departamento := InsertarDepartamentoOservicio(JsonCampo.AsValue().AsText(), CompanyName, false);
                        end;
                    end;
                    If JsonTarea.Get('service', JsonCampo) Then begin
                        If JsonCampo.AsValue().IsNull = false then begin
                            Clear(RecordiD);
                            RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::"Work Center", CompanyName);
                            If RecordiD.TableNo <> 0 then begin
                                RecordRef := RecordiD.GetRecord();
                                Tareas.Servicio := RecordRef.Field(WorkCenter.FieldNo("No.")).Value;
                            end else begin
                                Tareas.Servicio := InsertarDepartamentoOservicio(JsonCampo.AsValue().AsText(), CompanyName, true);
                            end;
                        END;
                    end;
                    If JsonTarea.Get('category', JsonCampo) Then begin
                        Clear(RecordiD);
                        If JsonCampo.AsValue().IsNull = false then begin
                            RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::"User Task Group", CompanyName);
                            If RecordiD.TableNo <> 0 then begin
                                RecordRef := RecordiD.GetRecord();
                                Tareas."User Task Group Assigned To" := RecordRef.Field(UserTaskGroup.FieldNo(Code)).Value;
                                Tareas."Categoría" := Tareas."User Task Group Assigned To";
                            end;
                        end;
                    end;
                    If JsonTarea.Get('project', JsonCampo) then begin
                        Clear(RecordiD);
                        If JsonCampo.AsValue().IsNull = false then begin
                            RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::Job, CompanyName);
                            If RecordiD.TableNo <> 0 then begin
                                RecordRef := RecordiD.GetRecord();
                                Tareas."Job No." := RecordRef.Field(Job.FieldNo("No.")).Value;
                            end;
                        end;
                    end;
                    JsonTarea.Get('owner', JsonCampo);
                    UserGtaskMalla.SetRange("Id Gtask", JsonCampo.AsValue().AsText());
                    If UserGtaskMalla.FindFirst() then
                        Tareas."Created By" := UserGtaskMalla."Id Usuario";
                    Clear(RecordiD);
                    JsonTarea.Get('_id', JsonCampo);
                    Tareas."Id_Tarea" := JsonCampo.AsValue().AsText();
                    JsonTarea.Get('state', JsonCampo);
                    case JsonCampo.AsValue().AsText() of
                        'PENDING':
                            begin
                                Tareas.Estado := Tareas.Estado::Pendiente;
                            end;
                        'INPROCESS':
                            Tareas.Estado := Tareas.Estado::"En Proceso";
                        'FINISHED':
                            Tareas.Estado := Tareas.Estado::Finalizado
                    end;
                    Tareas.Modify();
                    Tareas.Get(Id);
                    JsonTarea.Get('description', JsonCampo);
                    Tareas.Title := CopyStr(JsonCampo.AsValue().AsText(), 1, 250);
                    if JsonTarea.Get('observation', JsonCampo) Then
                        Tareas.SetDescription(JsonCampo.AsValue().AsText());
                    Tareas.Insert(true);

                    UpdateTask(Tareas.Id_Tarea, Format(Tareas.ID));

                end;
            end;

            if JsonTarea.Get('document', JsonCampo) then begin
                JsonArray := JsonCampo.AsArray();
                If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
                    Texto := JsonCampo.AsValue().AsText();
                    If Not Evaluate(Id, Texto) then begin
                        CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                        Tareas.ChangeCompany(CambiaEmpresa(CodEmpresa));
                        Texto := CopyStr(JsonCampo.AsValue().AsText(), 3, StrLen(JsonCampo.AsValue().AsText()));
                    end;
                    if Evaluate(Id, Texto) then
                        if Tareas.Get(Id) then begin

                            If Tareas."No." = '' then begin
                                Tareas."No." := Format(Id);
                                Tareas.Modify();
                            end;

                            foreach JsonToken in JsonArray do begin
                                JsonDetalleCampo := JsonToken.AsObject();
                                If JsonDetalleCampo.Get('document', JsonCampo) then begin
                                    JSonDocument := JsonCampo.AsObject();
                                    If jSonDocument.Get('url', JsonCampo) then begin
                                        DocUrl := JsonCampo.AsValue().AsText();
                                        If jSonDocument.get('name', JsonCampo) then
                                            DocuName := JsonCampo.AsValue().AsText();
                                        DocumentAtt.Reset();
                                        DocumentAtt.SetRange("Table ID", Database::"User Task");
                                        DocumentAtt.SetRange("No.", Tareas."No.");
                                        DocumentAtt.SetRange("File Name", DocuName);
                                        If Not DocumentAtt.Findfirst() then begin
                                            DocumentAtt.SetRange("File Name");
                                            if DocumentAtt.FindLast() then
                                                Line := DocumentAtt.Id + 1
                                            else
                                                Line := 1;
                                            DocumentAtt.Init();
                                            DocumentAtt.Id := Line;
                                            DocumentAtt."Table ID" := Database::"User Task";
                                            DocumentAtt."No." := Tareas."No.";
                                            DocumentAtt."File Name" := DocuName;
                                            DocumentAtt."URL" := DocUrl;
                                            DocumentAtt.Insert();
                                        end;
                                    end;
                                end;
                            end;
                        end;
                END;
            end;
        end;

    end;

    [EventSubscriber(ObjectType::Table, Database::"User Task", 'OnAfterModifyEvent', '', false, false)]
    procedure UserTaskOnAfterModifyEvent(var Rec: Record "User Task"; var xRec: Record "User Task"; RunTrigger: Boolean)
    var
    begin
        If Rec."Id_Tarea" <> '' then begin
            rec."Fecha Comunicado Cambio" := CurrentDateTime;
            Rec."Fecha Cambio" := CurrentDateTime;
            UpdateTaskGtask(Rec.Id_Tarea, Rec.ID);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterModifyEvent', '', false, false)]
    procedure DocumentAttachmentOnAfterModifyEvent(var Rec: Record "Document Attachment"; var xRec: Record "Document Attachment"; RunTrigger: Boolean)
    var
        Tareas: Record "User Task";
    begin
        If Rec.IsTemporary() then exit;
        If Rec."Document Flow Service" Then exit;
        If Rec."Table ID" = Database::"User Task" then begin
            Tareas.SetRange("No.", Rec."No.");
            If Tareas.FindFirst() then
                if Tareas."Id_Tarea" <> '' then
                    GetSetDocattchment(Tareas, Tareas.Id_Tarea);
        end;

    end;
    //IsertAttachment
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInsertEvent', '', false, false)]
    procedure DocumentAttachmentOnAfterInsertEvent(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    var
        Tareas: Record "User Task";
    begin
        If Rec.IsTemporary() then exit;
        If Rec."Document Flow Service" Then exit;
        If Rec."Table ID" = Database::"User Task" then begin
            Tareas.SetRange("No.", Rec."No.");
            If Tareas.FindFirst() then
                if Tareas."Id_Tarea" <> '' then
                    if Rec."Url" <> '' then
                        If Rec."File Name" <> '' then
                            GetSetDocattchment(Tareas, Tareas.Id_Tarea);
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
                    GetSetChat(Tareas, Tareas.Id_Tarea);
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
                        GetSetChat(Tareas, Tareas.Id_Tarea);

        end;
    end;

    procedure CrearTareaFijacion(var OrdenFijacion: Record "Cab Orden fijación"; Tarea: Record "User Task")
    var
        JsoonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonFormater: Codeunit "Json Text Reader/Writer";
        jSon: Text;
        category: Text;
        usuario: Text;
        GlSetup: Record "Company Information";
        UserGtaskMalla: Record UsuariosGtask;
        Name: Text;
        Value1: Text;
        Id: Text;
        a: Integer;
        i: Integer;
        Desde: Date;
        Hasta: Date;
        Dias: Integer;
        Url: Text;
        link: Text;
        TipoIncidencia: Record "User Task Group";
        wRecordRef: RecordRef;
        Recurso: Record Resource;
        resource: text;
        responsable: Text;
        Supervisor: Text;
        Categoria: Text;
        DetOrdenFijacion: Record "Orden fijación";
        DocumentAttachment: Record "Document Attachment";
        Bs64: Codeunit "Base64 Convert";
        Base64Data: Text;
        int: InStream;
        DocumentStream: Outstream;
        TempBlob: Codeunit "Temp Blob";
        departament: Text;
        service: Text;
        Job: Record Job;
        JobNo: Text;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JDatoDetalleToken: JsonToken;
        JsonTask: JsonObject;
        idNium: Integer;
        JobsSetup: Record "Jobs Setup";
        Customer: Record Customer;
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        departament := Tarea.Departamento;
        service := Tarea.Servicio;
        CrearDepartamnetoyServicio(departament, service);
        DetOrdenFijacion.SetRange("Nº Orden", OrdenFijacion."Nº Orden");
        If DetOrdenFijacion.FindFirst() then
            repeat
                If Recurso.Get(DetOrdenFijacion."Nº Recurso") then begin
                    wRecordRef.Close();
                    wRecordRef.Open(Database::Resource, false, CompanyName);
                    wRecordRef.Get(Recurso.RecordId);
                    resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                    if resource = 'Error' then begin
                        CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                        resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                    end;
                end;
            until DetOrdenFijacion.Next() = 0;
        Categoria := Tarea."User Task Group Assigned To";
        if not TipoIncidencia.Get(Categoria) then begin
            TipoIncidencia.Init();
            TipoIncidencia."Code" := Categoria;
            TipoIncidencia."Description" := Categoria;
            TipoIncidencia.Insert();
            Commit();
        end;
        wRecordRef.Close();
        wRecordRef.Open(Database::"User Task Group", false, CompanyName);
        wRecordRef.Get(TipoIncidencia.RecordId);
        category := GetMaestro('category', Categoria, 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        if category = 'Error' then begin
            CreaCategoria(Categoria, TipoIncidencia.RecordId, Database::"User Task Group", 'Malla Publicidad');
            category := GetMaestro('category', 'Intervencion', 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        end;
        wRecordRef.Close();
        Tarea.CalcFields("Assigned To User Name");
        UserGtaskMalla.Setrange("Id Usuario", Tarea."Assigned To");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario responsable %1 no existe en Gtask o, no está enlazado', Tarea."Assigned To User Name");
        responsable := UserGtaskMalla."Id Gtask";
        Tarea.CalcFields("Supervisor User Name");
        UserGtaskMalla.Setrange("Id Usuario", Tarea."Supervisor");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario  supervisor %1 no existe en Gtask o, no está enlazado', Tarea."Supervisor User Name");
        Supervisor := UserGtaskMalla."Id Gtask";
        //owner
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Created By");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario %1 no existe en Gtask o, no está enlazado', Tarea."Created By User Name");
        usuario := UserGtaskMalla."Id Gtask";
        wRecordRef.Close();
        Job.Get(Tarea."Job No.");
        wRecordRef.Open(Database::Job);
        wRecordRef.Get(Job.RecordId);
        JobNo := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        if JobNo = 'Error' then begin
            CreaProyecto(Job, Job.RecordId, Database::Job);
            JobNo := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        end;
        //     {
        // "department": "604767e49fea4e001874b283",
        // "expirationDate": {
        //     "date": "2021-10-26T10:42:02",
        //     "rule": null,
        //     "custom": false
        // },
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('department', departament);
        JsonFormater.WriteStartObject('expirationDate');
        JsonFormater.WriteStringProperty('date', Hora(Tarea."Start DateTime"));
        JsonFormater.WriteNullProperty('rule');
        JsonFormater.WriteBooleanProperty('custom', false);
        JsonFormater.WriteEndObject();
        Desde := Variant2Date(Tarea."Start DateTime");
        if Desde = 0D then begin
            Tarea."Start DateTime" := CurrentDateTime;
            Desde := Variant2Date(Tarea."Start DateTime");
        end;
        Hasta := Variant2Date(Tarea."Due DateTime");
        //LO MISMO PARA HASTA
        if Hasta = 0D then begin
            Tarea."Due DateTime" := CurrentDateTime;
            Hasta := Variant2Date(Tarea."Due DateTime");
        end;
        Dias := Hasta - Desde;
        JsonFormater.WriteStringProperty('daysToPerform', Dias + 1);
        JsonFormater.WriteStringProperty('description', Tarea.Title);
        JsonFormater.WriteStringProperty('observation', Tarea.GetDescription);
        JsonFormater.WriteStringProperty('service', service);
        JsonFormater.WriteStringProperty('category', category);
        JsonFormater.WriteStringProperty('project', JobNo);
        JsonFormater.WriteStringProperty('user', responsable);
        CompanyInfo.Get();
        JsonFormater.WriteStringProperty('Id_Navision', CompanyInfo."Clave Recursos" + Format(Tarea.ID));
        JsonFormater.WriteStringProperty('supervisor', supervisor);
        //owner
        JsonFormater.WriteStringProperty('owner', usuario);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        //Cambiar NAV-MALLA01:48900 por bc240.malla.es
        if StrPos(Url, 'http://NAV-MALLA01:48900') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        if StrPos(Url, 'http://nav-malla01:48900/') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        JsonFormater.WriteStringProperty('link', Url);
        JsonFormater.WriteStringProperty('IdQr', Format(Tarea.OrdenFijacion) + '-' + Format(Tarea.Reserva));
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url task" + 'task', Token(), RequestType::post, jSon);
        IF Json <> '' THEN BEGIN

            JsonArray.ReadFrom(Json);
            foreach JsonToken in JsonArray do begin
                JsonTask := JsonToken.AsObject();
                Clear(JDatoDetalleToken);
                If JsonTask.Get('Id_Navision', JDatoDetalleToken) Then begin
                    if not Evaluate(idNium, JDatoDetalleToken.AsValue().AsText()) then begin
                        If StrLen(JDatoDetalleToken.AsValue().AsText()) < 2 then
                            idNium := 0
                        else
                            Evaluate(idNium, CopyStr(JDatoDetalleToken.AsValue().AsText(), 3, StrLen(JDatoDetalleToken.AsValue().AsText())));
                    end;
                    If idNium = Tarea.ID then begin
                        Clear(JDatoDetalleToken);
                        JsonTask.Get('_id', JDatoDetalleToken);
                        Id := JDatoDetalleToken.AsValue().AsText();
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            Tarea.Id_Tarea := Id;
            Tarea.Modify();
        end;
        DocumentAttachment.SetRange("Table ID", Database::"User Task");
        DocumentAttachment.SetRange("No.", Tarea."No.");
        Clear(JsonFormater);
        //https://gtasks-api.deploy.malla.es/task/document/:id
        //Id es el _id de la tarea.
        //Tienes que pasar esta información:
        //{
        //establishment: "Id del establecimiento de malla"
        //document: "base64"
        //name: "nombre del documento"

        If DocumentAttachment.FindFirst() then
            repeat
                Clear(JsonFormater);
                JsonFormater.WriteStartObject('');
                Base64Data := '';
                JsonFormater.WriteStringProperty('establishment', '6581485f67b6630011d83caf');
                If DocumentAttachment."Document Reference ID".HasValue then begin
                    DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                    TempBlob.CreateInStream(Int);
                    Base64Data := Bs64.ToBase64(Int);
                end else begin
                    if DocumentAttachment."Url" <> '' then begin
                        Base64Data := DocumentAttachment.ToBase64StringOcr(DocumentAttachment.Url);

                    end;
                end;
                JsonFormater.WriteStringProperty('document', Base64Data);
                JsonFormater.WriteStringProperty('name', DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension");
                JsonFormater.WriteEndObject();
                Clear(RestApi);
                Json := JsonFormater.GetJSonAsText();
                CompanyInfo.Get();
                Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/document/' + Id, Token(), RequestType::put, jSon);
            until DocumentAttachment.Next() = 0;
        GetSetChat(Tarea, Id);
        JobsSetup.Get();
        If JobsSetup."Crear subtareas" then
            CrearSubTareaFijacion(OrdenFijacion, Tarea)
        else begin
            If not Job.Get(Tarea."Job No.") then Job.Init;
            //crear cliente
            If Customer.Get(Job."Bill-to Customer No.") Then
                CreateParte(Tarea);
        end;


        // "daysToPerform": 1,
        // "description": "Tarea prueba",
        // "observation": "Observaciones",
        // "service": "60589ab346c40b00195cc993",
        // "category": "6047b4ad8163a70018d3a2dd",
        // "project": "604bf21602913a001899c173",
        // "user": "60d31d7d0c6fff00183fe616",
        // "supervisor": "60d348afd3c595001917760a",
        // "priority": "HIGH",
        // "commandOrder": [
        //     "60d34a51d3c5950019177675",
        //     "60d3485fd3c5950019177601",
        //     "60d34a0dd3c5950019177665"
        // ],
        // "mentions": ["60d31d7d0c6fff00183fe616"]
    end;

    procedure CrearSubTareaFijacion(var OrdenFijacion: Record "Cab Orden fijación"; MTarea: Record "User Task")
    var
        Tarea: Record "User Task";
        JsoonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonFormater: Codeunit "Json Text Reader/Writer";
        jSon: Text;
        category: Text;
        usuario: Text;
        GlSetup: Record "Company Information";
        UserGtaskMalla: Record UsuariosGtask;
        Name: Text;
        Value1: Text;
        Id: Text;
        a: Integer;
        i: Integer;
        Desde: Date;
        Hasta: Date;
        Dias: Integer;
        Url: Text;
        link: Text;
        TipoIncidencia: Record "User Task Group";
        wRecordRef: RecordRef;
        Recurso: Record Resource;
        resource: text;
        responsable: Text;
        Supervisor: Text;
        Categoria: Text;
        DetOrdenFijacion: Record "Orden fijación";
        DocumentAttachment: Record "Document Attachment";
        Bs64: Codeunit "Base64 Convert";
        Base64Data: Text;
        int: InStream;
        DocumentStream: Outstream;
        TempBlob: Codeunit "Temp Blob";
        departament: Text;
        service: Text;
        UsuaariosxTarea: Record "User Task Group Member";
        Job: Record Job;
        JobNo: Text;
        Customer: Record Customer;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JDatoDetalleToken: JsonToken;
        JsonTask: JsonObject;
        idNium: Integer;
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        if Tarea.FindLast() Then a := Tarea."Id" + 1;
        Tarea := MTarea;
        Tarea."Id" := a;
        Tarea."Parent Id" := MTarea."Id";
        Tarea.Supervisor := MTarea."Assigned To";
        UsuaariosxTarea.SetRange("User Task Group Code", MTarea."User Task Group Assigned To");
        UsuaariosxTarea.SetRange(Responsable, false);
        UsuaariosxTarea.SetRange(Supervisor, false);
        UsuaariosxTarea.FindFirst();
        Tarea."Assigned To" := UsuaariosxTarea."User Security ID";
        Tarea.Insert();
        departament := Tarea.Departamento;
        service := Tarea.Servicio;
        CrearDepartamnetoyServicio(departament, service);
        DetOrdenFijacion.SetRange("Nº Orden", OrdenFijacion."Nº Orden");
        If DetOrdenFijacion.FindFirst() then
            repeat
                If Recurso.Get(DetOrdenFijacion."Nº Recurso") then begin
                    wRecordRef.Close();
                    wRecordRef.Open(Database::Resource, false, CompanyName);
                    wRecordRef.Get(Recurso.RecordId);
                    resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                    if resource = 'Error' then begin
                        CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                        resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                    end;
                end;
            until DetOrdenFijacion.Next() = 0;
        Categoria := Tarea."User Task Group Assigned To";
        if not TipoIncidencia.Get(Categoria) then begin
            TipoIncidencia.Init();
            TipoIncidencia."Code" := Categoria;
            TipoIncidencia."Description" := Categoria;
            TipoIncidencia.Insert();
            Commit();
        end;
        wRecordRef.Close();
        wRecordRef.Open(Database::"User Task Group", false, CompanyName);
        wRecordRef.Get(TipoIncidencia.RecordId);
        category := GetMaestro('category', Categoria, 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        if category = 'Error' then begin
            CreaCategoria(Categoria, TipoIncidencia.RecordId, Database::"User Task Group", 'Malla Publicidad');
            category := GetMaestro('category', 'Intervencion', 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        end;
        wRecordRef.Close();
        Tarea.CalcFields("Assigned To User Name");
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Assigned To");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario responsable %1 no existe en Gtask o, no está enlazado', Tarea."Assigned To User Name");
        responsable := UserGtaskMalla."Id Gtask";
        UserGtaskMalla.SetRange("Id Usuario", Tarea.Supervisor);
        If Not UserGtaskMalla.FindFirst() then Error('El usuario supervisor %1 no existe en Gtask o, no está enlazado', Tarea."Supervisor User Name");
        supervisor := UserGtaskMalla."Id Gtask";
        UserGtaskMalla.SetRange("Id Usuario", MTarea."Created By");
        MTarea.CalcFields("Created by User Name");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario %1 no existe en Gtask o, no está enlazado', MTarea."Created By User Name");
        usuario := UserGtaskMalla."Id Gtask";
        Job.Get(Tarea."Job No.");
        wRecordRef.Open(Database::Job);
        wRecordRef.Get(Job.RecordId);
        JobNo := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        if JobNo = 'Error' then begin
            CreaProyecto(Job, Job.RecordId, Database::Job);
            JobNo := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        end;
        //     {
        // "department": "604767e49fea4e001874b283",
        // "expirationDate": {
        //     "date": "2021-10-26T10:42:02",
        //     "rule": null,
        //     "custom": false
        // },
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('department', departament);
        JsonFormater.WriteStartObject('expirationDate');
        JsonFormater.WriteStringProperty('date', Hora(Tarea."Start DateTime"));
        JsonFormater.WriteNullProperty('rule');
        JsonFormater.WriteBooleanProperty('custom', false);
        JsonFormater.WriteEndObject();
        Desde := Variant2Date(Tarea."Start DateTime");
        if Desde = 0D then begin
            Tarea."Start DateTime" := CurrentDateTime;
            Desde := Variant2Date(Tarea."Start DateTime");
        end;
        Hasta := Variant2Date(Tarea."Due DateTime");
        //LO MISMO PARA HASTA
        if Hasta = 0D then begin
            Tarea."Due DateTime" := CurrentDateTime;
            Hasta := Variant2Date(Tarea."Due DateTime");
        end;
        Dias := Hasta - Desde;
        JsonFormater.WriteStringProperty('taskMother', MTarea."Id_tarea");
        JsonFormater.WriteStringProperty('daysToPerform', Dias + 1);
        JsonFormater.WriteStringProperty('description', Tarea.Title);
        JsonFormater.WriteStringProperty('observation', Tarea.GetDescription);
        JsonFormater.WriteStringProperty('service', service);
        JsonFormater.WriteStringProperty('category', category);
        JsonFormater.WriteStringProperty('user', responsable);
        CompanyInfo.Get();
        JsonFormater.WriteStringProperty('Id_Navision', CompanyInfo."Clave Recursos" + Format(Tarea.ID));
        JsonFormater.WriteStringProperty('supervisor', supervisor);
        //owner
        JsonFormater.WriteStringProperty('owner', usuario);
        JsonFormater.WriteStringProperty('project', JobNo);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        if StrPos(Url, 'http://NAV-MALLA01:48900') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        if StrPos(Url, 'http://nav-malla01:48900/') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        JsonFormater.WriteStringProperty('link', Url);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url task" + 'task', Token(), RequestType::post, jSon);
        IF Json <> '' THEN BEGIN

            JsonArray.ReadFrom(Json);
            foreach JsonToken in JsonArray do begin
                JsonTask := JsonToken.AsObject();
                Clear(JDatoDetalleToken);
                If JsonTask.Get('Id_Navision', JDatoDetalleToken) Then begin
                    if not Evaluate(idNium, JDatoDetalleToken.AsValue().AsText()) then begin
                        If StrLen(JDatoDetalleToken.AsValue().AsText()) < 2 then
                            idNium := 0
                        else
                            Evaluate(idNium, CopyStr(JDatoDetalleToken.AsValue().AsText(), 3, StrLen(JDatoDetalleToken.AsValue().AsText())));
                    end;
                    If idNium = Tarea.ID then begin
                        Clear(JDatoDetalleToken);
                        JsonTask.Get('_id', JDatoDetalleToken);
                        Id := JDatoDetalleToken.AsValue().AsText();
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            Tarea.Id_Tarea := Id;
            Tarea.Modify();
        end;

        DocumentAttachment.SetRange("Table ID", Database::"User Task");
        DocumentAttachment.SetRange("No.", MTarea."No.");
        Clear(JsonFormater);
        //https://gtasks-api.deploy.malla.es/task/document/:id
        //Id es el _id de la tarea.
        //Tienes que pasar esta información:
        //{
        //establishment: "Id del establecimiento de malla"
        //document: "base64"
        //name: "nombre del documento"

        If DocumentAttachment.FindFirst() then
            repeat
                Clear(JsonFormater);
                JsonFormater.WriteStartObject('');
                Base64Data := '';
                JsonFormater.WriteStringProperty('establishment', '6581485f67b6630011d83caf');
                If DocumentAttachment."Document Reference ID".HasValue then begin
                    DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                    TempBlob.CreateInStream(Int);
                    Base64Data := Bs64.ToBase64(Int);
                end else begin
                    if DocumentAttachment."Url" <> '' then begin
                        Base64Data := DocumentAttachment.ToBase64StringOcr(DocumentAttachment.Url);

                    end;
                end;
                JsonFormater.WriteStringProperty('document', Base64Data);
                JsonFormater.WriteStringProperty('name', DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension");
                JsonFormater.WriteEndObject();
                Clear(RestApi);
                Json := JsonFormater.GetJSonAsText();
                CompanyInfo.Get();
                Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/document/' + Id, Token(), RequestType::put, jSon);
            until DocumentAttachment.Next() = 0;
        GetSetChat(Tarea, Id);
        If not Job.Get(Tarea."Job No.") then Job.Init;
        If Customer.Get(Job."Bill-to Customer No.") Then
            CreateParte(Tarea);

        // "daysToPerform": 1,
        // "description": "Tarea prueba",
        // "observation": "Observaciones",
        // "service": "60589ab346c40b00195cc993",
        // "category": "6047b4ad8163a70018d3a2dd",
        // "project": "604bf21602913a001899c173",
        // "user": "60d31d7d0c6fff00183fe616",
        // "supervisor": "60d348afd3c595001917760a",
        // "priority": "HIGH",
        // "commandOrder": [
        //     "60d34a51d3c5950019177675",
        //     "60d3485fd3c5950019177601",
        //     "60d34a0dd3c5950019177665"
        // ],
        // "mentions": ["60d31d7d0c6fff00183fe616"]
    end;

    procedure GetResource(var Buffer: Record Resource temporary): Text
    var
        Resource: Record Resource;
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Nombre: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        No: Text;
    begin
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'resource', Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;
        If a = 0 Then exit('Error');
        WHILE i < a DO BEGIN
            Clear(No);
            Clear(Nombre);
            Clear(Id);
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            Id := Value1;
                        'name':
                            Nombre := Value1;
                        'No':
                            No := Value1;
                    end;
                end;
            end;
            Buffer.Init();
            If (No = '') and (Id <> '') and (Nombre <> '') then begin
                Resource.SetRange(Name, Nombre);
                If Resource.FindFirst() then begin
                    Buffer."No." := Resource."No.";
                    Buffer.Name := Resource.Name;
                    Buffer."Search Name" := Id;
                    Buffer.Insert();
                end;
            end;

            i += 1;
        end;
    end;
    /// <summary>
    /// GetMaestro.
    /// </summary>
    /// <param name="Maestro">Text.</param>
    /// <param name="Descripcion">Text.</param>
    /// <param name="Campo">Text.</param>
    /// <param name="wRecordRef">VAR RecordRef.</param>
    /// <param name="Tabla">Integer.</param>
    /// <param name="Company">Text.</param>
    /// <returns>Return value of type Text.</returns>
    procedure GetMaestro(Maestro: Text; Descripcion: Text; Campo: Text; var wRecordRef: RecordRef; Tabla: Integer; Company: Text): Text
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Link: Record "Data Migration Error";
        IdLink: Integer;
    begin
        If Company <> '' then begin
            link.ChangeCompany(Company);
        end;
        Link.SetRange("Source Staging Table Record ID", wRecordRef.RecordId);
        Link.SetRange("Destination Table ID", Tabla);
        if Link.FindFirst() Then begin
            if UpperCase(Link."Migration Type") <> 'ERROR' then
                exit(Link."Migration Type");
            link.Delete();
        end;
        CompanyInfo.ChangeCompany(Company);
        CompanyInfo.Get();


        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + Maestro, Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;
        If a = 0 Then exit('Error');
        WHILE i < a DO BEGIN
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            Id := Value1;
                        campo:
                            begin
                                if Value1 = Descripcion then begin
                                    If InsertLink(wRecordRef.RecordId, Tabla, Id, Company) then
                                        exit(Id);
                                end;
                            end;
                        'username':
                            begin
                                if Value1 = Descripcion then begin
                                    if InsertLink(wRecordRef.RecordId, Tabla, Id, Company) then
                                        exit(Id)
                                end;
                            end;
                        'email':
                            begin
                                if Value1 = Descripcion then begin
                                    if InsertLink(wRecordRef.RecordId, Tabla, Id, Company) then
                                        exit(Id)
                                end;
                            end;
                    end;
                end;
            end;
            i += 1;
        end;
        Exit('Error');
    end;

    /// <summary>
    /// GetNombreMaestro.
    /// </summary>
    /// <param name="Maestro">Text.</param>
    /// <param name="Id">Text.</param>
    /// <param name="Campo">Text.</param>
    /// <param name="Tabla">Integer.</param>
    /// <param name="NCampo">Integer.</param>
    /// <param name="tRecorId">VAR RecordId.</param>
    /// <param name="Company">Text.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetNombreMaestro(Maestro: Text; Id: Text; Campo: Text; Tabla: Integer; NCampo: Integer; var tRecorId: RecordId; Company: Text): Boolean
    var
        Link: Record "Data Migration Error";
        RestApi: Codeunit "Control Ocr";
        Token: Text;
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        b: Integer;
        RecordIDT: RecordId;
        RecordRefT: RecordRef;
        FieldRefT: FieldRef;
    begin
        Link.SetRange("Destination table Id", Tabla);
        Link.SetRange("Migration Type", Id);
        If Link.FindFirst() then begin
            tRecorId := Link."Source Staging Table Record ID";
            exit(true);
        end;
        b := -1;
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url task" + Maestro, Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;

        If a = 0 Then exit(false);
        WHILE i < a DO BEGIN
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            if Id = Value1 then begin
                                b := i;
                                i := a;
                            end;

                    end;
                end;
            end;
            i += 1;
        end;
        if b = -1 then exit(false);
        JSONMgt.GetObjectFromCollectionByIndex(Json, b);
        JSONMgt.InitializeObject(Json);
        IF Json <> '' THEN BEGIN
            JSONMgt.InitializeObject(Json);
            JSONMgt.ReadProperties();
            WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                CASE Name OF
                    campo:
                        begin
                            RecordRefT.Open(Tabla, false, CompanyName);
                            FieldRefT := RecordRefT.Field(NCampo);
                            FieldRefT.SetRange(Value1);
                            If RecordRefT.FindFirst() then begin
                                tRecorId := RecordRefT.RecordId;
                                Exit(not InsertLink(tRecorId, Tabla, Id, Company));

                            end else
                                exit(false);
                        end;
                end;
            end;
        end;
        Exit(false);
    end;


    /// GetMaestro.
    /// <param name="Maestro">Text.</param>
    /// <param name="Descripcion">Text.</param>
    /// <param name="Campo">Text.</param>
    /// <param name="wRecordRef">VAR RecordRef.</param>
    /// <param name="Tabla">Integer.</param>
    /// <param name="Company">Text.</param>
    /// <returns>Return value of type Text.</returns>
    procedure CrearCategorias(Company: Text): Text
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Categorias: Record "User Task Group";
        Link: Record "Data Migration Error";
        IdLink: Integer;
    begin
        If Company <> '' then begin
            link.ChangeCompany(Company);
        end;
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'category', Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;
        If a = 0 Then exit('Error');
        WHILE i < a DO BEGIN
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            Id := Value1;
                        'name':
                            begin
                                Categorias.SetRange(Description, Value1);
                                If Categorias.FindFirst() then begin
                                    Link.SetRange("Source Staging Table Record ID", Categorias.RecordId);
                                    Link.SetRange("Destination Table ID", Database::"User Task Group");
                                    If Not Link.FindSet() Then
                                        InsertLink(Categorias.RecordId, Database::"User Task Group", Id, Company);

                                end else begin
                                    Categorias.Init();
                                    Categorias."Code" := CopyStr(Value1, 1, MaxStrLen(Categorias."Code"));
                                    Categorias."Description" := CopyStr(Value1, 1, MaxStrLen(Categorias."Description"));
                                    If Categorias.Insert() Then
                                        InsertLink(Categorias.RecordId, Database::"User Task Group", Id, Company);
                                end;
                            end;

                    end;
                end;
            end;
            i += 1;
        end;
        Exit('');
    end;

    /// <summary>
    /// CrearTarea.
    /// </summary>
    /// <param name="Emplazamiento">VAR Record Resource.</param>
    /// <param name="Tarea">Record "User Task".</param>

    procedure CrearTareaTecnico(
        NoRecurso: Code[20];
        Tarea: Record "User Task";
        Departament: Text; Service: Text; CreaParte: Boolean)
    var
        Recurso: Record Resource;
        Category: Text;
        JsoonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonFormater: Codeunit "Json Text Reader/Writer";
        jSon: Text;
        usuario: Text;
        GlSetup: Record "Company Information";
        UserGtaskMalla: Record UsuariosGtask;
        Name: Text;
        Value1: Text;
        Id: Text;
        a: Integer;
        i: Integer;
        Desde: Date;
        Hasta: Date;
        Dias: Integer;
        Url: Text;
        link: Text;
        TipoIncidencia: Record "User Task Group";
        wRecordRef: RecordRef;
        resource: text;
        responsable: Text;
        Supervisor: Text;
        Categoria: Text;
        DocumentAttachment: Record "Document Attachment";
        Base64Data: Text;
        DocumentStream: Outstream;
        TempBlob: Codeunit "Temp Blob";
        Int: InStream;
        Bs64: Codeunit "Base64 Convert";
        Job: Record Job;
        Customer: Record Customer;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JDatoDetalleToken: JsonToken;
        JsonTask: JsonObject;
        idNium: Integer;
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        if Not Recurso.Get(NoRecurso) then Recurso.Init();
        CrearDepartamnetoyServicio(departament, service);
        If Recurso."No." <> '' Then Begin
            wRecordRef.Close();
            wRecordRef.Open(Database::Resource, false, CompanyName);
            wRecordRef.Get(Recurso.RecordId);
            resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
            if resource = 'Error' then begin
                CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
            end;
        end;
        Categoria := Tarea."User Task Group Assigned To";
        if not TipoIncidencia.Get(Categoria) then begin
            TipoIncidencia.Init();
            TipoIncidencia."Code" := Categoria;
            TipoIncidencia."Description" := Categoria;
            TipoIncidencia.Insert();
            Commit();
        end;
        wRecordRef.Close();
        wRecordRef.Open(Database::"User Task Group", false, CompanyName);
        wRecordRef.Get(TipoIncidencia.RecordId);
        category := GetMaestro('category', Categoria, 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        if category = 'Error' then begin
            CreaCategoria(Categoria, TipoIncidencia.RecordId, Database::"User Task Group", 'Malla Publicidad');
            category := GetMaestro('category', Categoria, 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        end;
        wRecordRef.Close();
        Tarea.CalcFields("Assigned To User Name");
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Assigned To");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario responsable %1 no existe en Gtask o, no está enlazado', Tarea."Assigned To User Name");
        responsable := UserGtaskMalla."Id Gtask";
        UserGtaskMalla.SetRange("Id Usuario", Tarea.Supervisor);
        If Not UserGtaskMalla.FindFirst() then Error('El usuario supervisor %1 no existe en Gtask o, no está enlazado', Tarea."Supervisor User Name");
        supervisor := UserGtaskMalla."Id Gtask";
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Created By");
        Tarea.CalcFields("Created by User Name");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario %1 no existe en Gtask o, no está enlazado', Tarea."Created by User Name");
        usuario := UserGtaskMalla."Id Gtask";
        //     {
        // "department": "604767e49fea4e001874b283",
        // "expirationDate": {
        //     "date": "2021-10-26T10:42:02",
        //     "rule": null,
        //     "custom": false
        // },
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('department', departament);
        JsonFormater.WriteStartObject('expirationDate');
        JsonFormater.WriteStringProperty('date', Hora(Tarea."Due DateTime"));
        JsonFormater.WriteNullProperty('rule');
        JsonFormater.WriteBooleanProperty('custom', false);
        JsonFormater.WriteEndObject();
        Desde := Variant2Date(Tarea."Start DateTime");
        Hasta := Variant2Date(Tarea."Due DateTime");
        Dias := Hasta - Desde;
        JsonFormater.WriteStringProperty('daysToPerform', Dias + 1);
        JsonFormater.WriteStringProperty('description', Tarea.Title);
        JsonFormater.WriteStringProperty('observation', Tarea.GetDescription);
        JsonFormater.WriteStringProperty('service', service);
        JsonFormater.WriteStringProperty('category', category);
        JsonFormater.WriteStringProperty('user', responsable);
        JsonFormater.WriteStringProperty('supervisor', supervisor);
        CompanyInfo.Get();
        JsonFormater.WriteStringProperty('Id_Navision', CompanyInfo."Clave Recursos" + Format(Tarea.ID));
        //owner
        JsonFormater.WriteStringProperty('owner', usuario);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        if StrPos(Url, 'http://NAV-MALLA01:48900') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        if StrPos(Url, 'http://nav-malla01:48900/') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        JsonFormater.WriteStringProperty('link', Url);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task', Token(), RequestType::post, jSon);
        IF Json <> '' THEN BEGIN

            JsonArray.ReadFrom(Json);
            foreach JsonToken in JsonArray do begin
                JsonTask := JsonToken.AsObject();
                Clear(JDatoDetalleToken);
                If JsonTask.Get('Id_Navision', JDatoDetalleToken) Then begin
                    if not Evaluate(idNium, JDatoDetalleToken.AsValue().AsText()) then begin
                        If StrLen(JDatoDetalleToken.AsValue().AsText()) < 2 then
                            idNium := 0
                        else
                            Evaluate(idNium, CopyStr(JDatoDetalleToken.AsValue().AsText(), 3, StrLen(JDatoDetalleToken.AsValue().AsText())));
                    end;
                    If idNium = Tarea.ID then begin
                        Clear(JDatoDetalleToken);
                        JsonTask.Get('_id', JDatoDetalleToken);
                        Id := JDatoDetalleToken.AsValue().AsText();
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            Tarea.Id_Tarea := Id;
            Tarea.Modify();
        end;
        DocumentAttachment.SetRange("Table ID", Database::"User Task");
        DocumentAttachment.SetRange("No.", Tarea."No.");
        Clear(JsonFormater);
        //https://gtasks-api.deploy.malla.es/task/document/:id
        //Id es el _id de la tarea.
        //Tienes que pasar esta información:
        //{
        //establishment: "Id del establecimiento de malla"
        //document: "base64"
        //name: "nombre del documento"

        If DocumentAttachment.FindFirst() then
            repeat
                Clear(JsonFormater);
                JsonFormater.WriteStartObject('');
                Base64Data := '';
                JsonFormater.WriteStringProperty('establishment', '6581485f67b6630011d83caf');
                If DocumentAttachment."Document Reference ID".HasValue then begin
                    DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                    TempBlob.CreateInStream(Int);
                    Base64Data := Bs64.ToBase64(Int);
                end else begin
                    if DocumentAttachment."Url" <> '' then begin
                        Base64Data := DocumentAttachment.ToBase64StringOcr(DocumentAttachment.Url);

                    end;
                end;
                JsonFormater.WriteStringProperty('document', Base64Data);
                JsonFormater.WriteStringProperty('name', DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension");
                JsonFormater.WriteEndObject();
                Clear(RestApi);
                Json := JsonFormater.GetJSonAsText();
                CompanyInfo.Get();
                Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/document/' + Id, Token(), RequestType::put, jSon);
            until DocumentAttachment.Next() = 0;
        GetSetChat(Tarea, Id);
        If not Job.Get(Tarea."Job No.") then Job.Init;
        //crear cliente
        If Customer.Get(Job."Bill-to Customer No.") Then
            CreateParte(Tarea);
        // "daysToPerform": 1,
        // "description": "Tarea prueba",
        // "observation": "Observaciones",
        // "service": "60589ab346c40b00195cc993",
        // "category": "6047b4ad8163a70018d3a2dd",
        // "project": "604bf21602913a001899c173",
        // "user": "60d31d7d0c6fff00183fe616",
        // "supervisor": "60d348afd3c595001917760a",
        // "priority": "HIGH",
        // "commandOrder": [
        //     "60d34a51d3c5950019177675",
        //     "60d3485fd3c5950019177601",
        //     "60d34a0dd3c5950019177665"
        // ],
        // "mentions": ["60d31d7d0c6fff00183fe616"]
    end;

    /// <summary>
    /// CrearTareaServiceItem.
    /// </summary>
    // /// <param name="Tarea">Record "Service Header".</param>
    // procedure CrearTareaServiceItem(var ProductoServicio: Record "Service Item"; Tarea: Record "Service Header")
    // var
    //     JsoonFormater: Codeunit "Json Text Reader/Writer";
    //     RestApi: Codeunit "Control Ocr";
    //     CompanyInfo: Record "Company Information";
    //     RequestType: Option Get,patch,put,post,delete;
    //     Pregunta: Text;
    //     JSONMgt: Codeunit "JSON Management";
    //     JsonFormater: Codeunit "Json Text Reader/Writer";
    //     jSon: Text;
    //     departament: Text;
    //     service: Text;
    //     category: Text;
    //     usuario: Text;
    //     GlSetup: Record "Company Information";
    //     supervisor: Text;
    //     User: Record UsuariosGtask;
    //     Name: Text;
    //     Value1: Text;
    //     Id: Text;
    //     a: Integer;
    //     i: Integer;
    //     Desde: Date;
    //     Hasta: Date;
    //     Dias: Integer;
    //     Url: Text;
    //     link: Text;
    //     Company: Record "Company Information";
    //     TipoIncidencia: Record "Service Order Type";
    //     wRecordRef: RecordRef;
    //     Recurso: Record Resource;
    //     ConfUser: Record "User Setup";
    //     resource: Text;

    // begin
    //     GlSetup.Get();
    //     Company.Get;
    //     wRecordRef.Open(Database::"Company Information", false, CompanyName);
    //     wRecordRef.Get(Company.RecordId);
    //     departament := GetMaestro('department', 'Sat', 'name', wRecordRef, Database::"Company Information");
    //     If departament = 'Error' then begin
    //         CreaDepartamento('Sat', Company.RecordId, Database::Company);
    //         departament := GetMaestro('department', 'Sat', 'name', wRecordRef, Database::"Company Information");
    //     end;
    //     wRecordRef.Close();
    //     wRecordRef.Open(Database::Resource, false, CompanyName);
    //     wRecordRef.Get(ProductoServicio.RecordId);
    //     service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::"Service Item");
    //     if service = 'Error' then begin
    //         CreaServicioServiceItem(ProductoServicio, ProductoServicio.RecordId, Database::Resource);
    //         service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::"Service Item");
    //     end;
    //     if Tarea."Service Order Type" = '' Then Tarea."Service Order Type" := 'INTERVENCION';
    //     if not TipoIncidencia.Get('INTERVENCION') then begin
    //         TipoIncidencia.Init();
    //         TipoIncidencia."Code" := 'INTERVENCION';
    //         TipoIncidencia."Description" := 'Intervencion';
    //         TipoIncidencia.Insert();
    //         Commit();
    //     end;
    //     wRecordRef.Close();
    //     wRecordRef.Open(Database::"Service Order Type", false, CompanyName);
    //     wRecordRef.Get(TipoIncidencia.RecordId);
    //     category := GetMaestro('category', TipoIncidencia.Description, 'name', wRecordRef, Database::"Service Order Type");
    //     if category = 'Error' then begin
    //         CreaCategoria('Intervencion', TipoIncidencia.RecordId, Database::"Service Order Type");
    //         category := GetMaestro('category', 'Intervencion', 'name', wRecordRef, Database::"Service Order Type");
    //     end;
    //     wRecordRef.Close();
    //     ConfUser.Get(Tarea."Assigned User ID");
    //     User.Get(ConfUser."User ID");
    //     Tarea.TestField("Preferred Resource");
    //     //if Tarea."Preferred Resource"<>'' Then User."Full Name":=ProductoServicio."Preferred Resource";
    //     resource := GetMaestro('resource', Tarea."Preferred Resource", 'name', wRecordRef, Database::Resource);
    //     if resource = 'Error' then begin
    //         Recurso.Get(Tarea."Preferred Resource");
    //         CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);

    //     end;
    //     wRecordRef.Open(Database::User);
    //     wRecordRef.Get(User.RecordId);
    //     usuario := GetMaestro('users', resource, 'name', wRecordRef, Database::User);
    //     if usuario = 'Error' then Error('Usuario %1 no existe', resource);
    //     wRecordRef.Close();
    //     wRecordRef.Open(Database::"Company Information", false, CompanyName);
    //     wRecordRef.Get(GlSetup.RecordId);
    //     supervisor := GetMaestro('users', GlSetup."Usuario Task", 'username', wRecordRef, Database::"Company Information");
    //     wRecordRef.Close();
    //     //     {
    //     // "department": "604767e49fea4e001874b283",
    //     // "expirationDate": {
    //     //     "date": "2021-10-26T10:42:02",
    //     //     "rule": null,
    //     //     "custom": false
    //     // },
    //     JsonFormater.WriteStartObject('');
    //     JsonFormater.WriteStringProperty('department', departament);
    //     JsonFormater.WriteStartObject('expirationDate');

    //     JsonFormater.WriteStringProperty('date', Format(CreateDateTime(Tarea."Due Date", Tarea."Finishing Time"), 0, '<Year4>-<Month,2>-<Day,2>T00:00:00'));
    //     JsonFormater.WriteNullProperty('rule');
    //     JsonFormater.WriteBooleanProperty('custom', false);
    //     JsonFormater.WriteEndObject();
    //     Desde := Tarea."Order Date";
    //     Hasta := Tarea."Finishing Date";
    //     Dias := Hasta - Desde;
    //     JsonFormater.WriteStringProperty('daysToPerform', Dias + 1);
    //     JsonFormater.WriteStringProperty('description', Tarea.Description);
    //     JsonFormater.WriteStringProperty('observation', Tarea.GetWorkDescription);
    //     JsonFormater.WriteStringProperty('service', service);
    //     JsonFormater.WriteStringProperty('category', category);
    //     JsonFormater.WriteStringProperty('user', usuario);
    //     JsonFormater.WriteStringProperty('supervisor', supervisor);
    //     JsonFormater.WriteStringProperty('priority', 'HIGH');
    //     Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
    //     if StrPos(Url, 'NAV-MALLA01:48900') > 0 then
    //       Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
    //     JsonFormater.WriteStringProperty('link', Url);
    //     JsonFormater.WriteEndObject();
    //     Json := JsonFormater.GetJSonAsText();
    //     Json := RestApi.RestApiToken(CompanyInfo."Url Gtask"+'task', RequestType::post, jSon,Qwark::Ocr);
    //     IF Json <> '' THEN BEGIN
    //         JSONMgt.InitializeCollection(Json);
    //         a := JSONMgt.GetCollectionCount;
    //         WHILE i < a DO BEGIN
    //             JSONMgt.GetObjectFromCollectionByIndex(Json, i);
    //             JSONMgt.InitializeObject(Json);
    //             JSONMgt.ReadProperties();
    //             WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
    //                 CASE Name OF
    //                     '_id':
    //                         Id := Value1;
    //                     'link':
    //                         link := Value1;
    //                 end;
    //             end;
    //             i += 1;
    //             if link = Url then i := a;
    //         end;
    //     end;
    //     if Id <> '' then begin
    //         Tarea.Id_Tarea := Id;
    //         Tarea.Modify();
    //     end;
    //     // "daysToPerform": 1,
    //     // "description": "Tarea prueba",
    //     // "observation": "Observaciones",
    //     // "service": "60589ab346c40b00195cc993",
    //     // "category": "6047b4ad8163a70018d3a2dd",
    //     // "project": "604bf21602913a001899c173",
    //     // "user": "60d31d7d0c6fff00183fe616",
    //     // "supervisor": "60d348afd3c595001917760a",
    //     // "priority": "HIGH",
    //     // "commandOrder": [
    //     //     "60d34a51d3c5950019177675",
    //     //     "60d3485fd3c5950019177601",
    //     //     "60d34a0dd3c5950019177665"
    //     // ],
    //     // "mentions": ["60d31d7d0c6fff00183fe616"]
    // end;

    /// <summary>
    /// CrearTareaTodo.
    /// </summary>
    /// <param name="Tarea">VAR Record "To-do".</param>
    procedure CrearTareaTodo(var Tarea: Record "To-do")
    var
        JsoonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonFormater: Codeunit "Json Text Reader/Writer";
        jSon: Text;
        departament: Text;
        service: Text;
        category: Text;
        usuario: Text;
        GlSetup: Record "Company Information";
        supervisor: Text;
        UserGtaskMalla: Record UsuariosGtask;
        Users: Record "User";
        Name: Text;
        Value1: Text;
        Id: Text;
        a: Integer;
        i: Integer;
        Desde: Date;
        Hasta: Date;
        Dias: Integer;
        Url: Text;
        link: Text;
        Company: Record "Sales & Receivables Setup";
        TipoIncidencia: Record "User Task Group";
        wRecordRef: RecordRef;
        Recurso: Record Resource;
        SalesPerson: Record "Salesperson/Purchaser";
        ConfUser: Record "User Setup";
        Customer: Record Contact;
        Client: Text;
        Responsable: Text;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JDatoDetalleToken: JsonToken;
        JsonTask: JsonObject;
        idNium: Integer;
    begin
        exit;
        //de momento no se usa
        GlSetup.Get();
        if GlSetup."Url Task" = '' Then Exit;
        Company.Get;
        departament := tarea.Departamento;
        service := 'Comercial';
        CrearDepartamnetoyServicio(departament, service);

        wRecordRef.Close();
        wRecordRef.Open(Database::Contact, false, CompanyName);
        Customer.Get(Tarea."Contact No.");
        wRecordRef.Get(Customer.RecordId);
        // service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::Resource);
        // if service = 'Error' then begin
        //     CreaServicio(ProductoServicio, ProductoServicio.RecordId, Database::Resource);
        //     service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::Resource);
        // end;
        Client := GetMaestro('client', Tarea."Contact No.", 'name', wRecordRef, Database::Contact, '');
        if Client = 'Error' then begin
            CreaContacto(Customer, Customer.RecordId, Database::Contact);
            Client := GetMaestro('client', Tarea."Contact No.", 'name', wRecordRef, Database::Contact, '');
        end;
        wRecordRef.Close();
        if not TipoIncidencia.Get(Tarea.Categoria) then begin
            TipoIncidencia.Init();
            TipoIncidencia."Code" := Tarea.Categoria;
            TipoIncidencia."Description" := Tarea.Categoria;
            TipoIncidencia.Insert();
            Commit();
        end;
        wRecordRef.Close();
        wRecordRef.Open(Database::"User Task Group", false, CompanyName);
        wRecordRef.Get(TipoIncidencia.RecordId);

        category := GetMaestro('category', Tarea.Categoria, 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        if category = 'Error' then begin
            CreaCategoria(Tarea.Categoria, TipoIncidencia.RecordId, Database::"User Task Group", 'Malla Publicidad');
            category := GetMaestro('category', Tarea.Categoria, 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        end;
        wRecordRef.Close();
        SalesPerson.Get(Tarea."Salesperson Code");
        ConfUser.SetRange("Salespers./Purch. Code", Tarea."Salesperson Code");
        If Not ConfUser.FindFirst() Then exit;
        ConfUser.FindFirst();
        Users.SetRange(Users."User Name", ConfUser."User ID");
        Users.FindFirst();
        UserGtaskMalla.SetRange("Id Usuario", Users."User Security ID");
        If Not UserGtaskMalla.FindFirst() Then exit;
        // if not Recurso.Get(User."Full Name") then begin
        //     Recurso.Init();
        //     Recurso."No." := User."Full Name";
        //     Recurso.Type := Recurso.Type::Person;
        //     Recurso.Name := User."Full Name";
        //     Recurso.Insert();
        //     Commit();
        //     CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);

        // end;
        supervisor := UserGtaskMalla."Id Gtask";
        UserGtaskMalla.SetRange("Id Usuario", Tarea.responsable);
        If Not UserGtaskMalla.FindFirst() then Error('El usuario responsable %1 no existe en Gtask o, no está enlazado', Tarea.Responsable);
        responsable := UserGtaskMalla."Id Gtask";

        usuario := Supervisor;
        //     {
        // "department": "604767e49fea4e001874b283",
        // "expirationDate": {
        //     "date": "2021-10-26T10:42:02",
        //     "rule": null,
        //     "custom": false
        // },
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('department', departament);
        JsonFormater.WriteStartObject('expirationDate');
        JsonFormater.WriteStringProperty('date', Hora(CreateDateTime(Tarea.Date, Tarea."Start Time")));
        JsonFormater.WriteNullProperty('rule');
        JsonFormater.WriteBooleanProperty('custom', false);
        JsonFormater.WriteEndObject();
        Dias := Tarea.Duration div (60 * 60 * 1000);
        JsonFormater.WriteStringProperty('daysToPerform', Dias + 1);
        JsonFormater.WriteStringProperty('description', Tarea.Description);
        JsonFormater.WriteStringProperty('observation', '');
        //JsonFormater.WriteStringProperty('service', service);
        JsonFormater.WriteStringProperty('client', Client);
        JsonFormater.WriteStringProperty('category', category);
        JsonFormater.WriteStringProperty('user', responsable);
        CompanyInfo.Get();
        JsonFormater.WriteStringProperty('Id_Navision', CompanyInfo."Clave Recursos" + Tarea."No.");
        JsonFormater.WriteStringProperty('supervisor', supervisor);
        //owner
        JsonFormater.WriteStringProperty('owner', usuario);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"Task Card", Tarea);
        if StrPos(Url, 'http://NAV-MALLA01:48900') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        if StrPos(Url, 'http://nav-malla01:48900/') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        JsonFormater.WriteStringProperty('link', Url);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task', Token(), RequestType::post, jSon);
        IF Json <> '' THEN BEGIN

            JsonArray.ReadFrom(Json);
            foreach JsonToken in JsonArray do begin
                JsonTask := JsonToken.AsObject();
                Clear(JDatoDetalleToken);
                If JsonTask.Get('Id_Navision', JDatoDetalleToken) Then begin
                    if Copystr(JDatoDetalleToken.AsValue().AsText(), 3, StrLen(JDatoDetalleToken.AsValue().AsText())) = Tarea."No." then begin
                        Clear(JDatoDetalleToken);
                        JsonTask.Get('_id', JDatoDetalleToken);
                        Id := JDatoDetalleToken.AsValue().AsText();
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            Tarea.Id_Tarea := Id;
            Tarea.Modify();
        end;
        // "daysToPerform": 1,
        // "description": "Tarea prueba",
        // "observation": "Observaciones",
        // "service": "60589ab346c40b00195cc993",
        // "category": "6047b4ad8163a70018d3a2dd",
        // "project": "604bf21602913a001899c173",
        // "user": "60d31d7d0c6fff00183fe616",
        // "supervisor": "60d348afd3c595001917760a",
        // "priority": "HIGH",
        // "commandOrder": [
        //     "60d34a51d3c5950019177675",
        //     "60d3485fd3c5950019177601",
        //     "60d34a0dd3c5950019177665"
        // ],
        // "mentions": ["60d31d7d0c6fff00183fe616"]
    end;

    /// <summary>
    /// CrearTareaJob.
    /// </summary>
    /// <param name="Job">VAR Record job.</param>
    /// <param name="Tarea">Record "User Task".</param>
    procedure CrearTareaJob(var Job: Record job; Tarea: Record "User Task")
    var
        JsoonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonFormater: Codeunit "Json Text Reader/Writer";
        jSon: Text;
        departament: Text;
        service: Text;
        category: Text;
        usuario: Text;
        GlSetup: Record "Company Information";
        supervisor: Text;
        UserGtaskMalla: Record UsuariosGtask;
        Name: Text;
        Value1: Text;
        Id: Text;
        a: Integer;
        i: Integer;
        Desde: Date;
        Hasta: Date;
        Dias: Integer;
        Url: Text;
        link: Text;
        Company: Record "Sales & Receivables Setup";
        TipoIncidencia: Record "User Task Group";
        wRecordRef: RecordRef;
        Recurso: Record Resource;
        SalesPerson: Record "Salesperson/Purchaser";
        Customer: Record Customer;
        Client: Text;
        Proyect: Text;
        Departamentos: Record "Responsibility Center";
        Servicios: Record "Work Center";
        JobSetup: Record "Jobs Setup";
        responsable: Text;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JDatoDetalleToken: JsonToken;
        JsonTask: JsonObject;
        idNium: Integer;
    begin
        GlSetup.Get();
        JobSetup.Get();
        If Not Departamentos.Get('TALLER') then begin
            Departamentos.Init();
            Departamentos."Code" := 'TALLER';
            Departamentos."Name" := 'TALLER';
            Departamentos.Insert();
            Commit();
        end;
        wRecordRef.Open(Database::"Responsibility Center", false, 'Malla Publicidad');
        wRecordRef.Get(departamentos.RecordId);
        departament := GetMaestro('department', 'TALLER', 'name', wRecordRef, Database::"Responsibility Center", 'Malla Publicidad');
        If departament = 'Error' then begin
            CreaDepartamento('TALLER', departamentos.RecordId, Database::"Responsibility Center", 'Malla Publicidad');
            departament := GetMaestro('department', 'TALLER', 'name', wRecordRef, Database::"Company Information", 'Malla Publicidad');
        end;
        If Not Servicios.Get('Medios') then begin
            Servicios.Init();
            Servicios."No." := 'Medios';
            Servicios."Name" := 'Medios';
            Servicios.Insert();
            Commit();
        end;
        service := GetMaestro('service', 'Medios', 'name', wRecordRef, Database::"Work Center", 'Malla Publicidad');

        wRecordRef.Close();
        wRecordRef.Open(Database::Contact, false, CompanyName);
        Customer.Get(Job."Bill-to Customer No.");
        wRecordRef.Get(Customer.RecordId);
        // service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::Resource);
        // if service = 'Error' then begin
        //     CreaServicio(ProductoServicio, ProductoServicio.RecordId, Database::Resource);
        //     service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::Resource);
        // end;
        Client := GetMaestro('client', Job."Bill-to Customer No.", 'name', wRecordRef, Database::Customer, '');
        if Client = 'Error' then begin
            CreaCliente(Customer, Customer.RecordId, Database::Customer);
            Client := GetMaestro('client', Job."Bill-to Customer No.", 'name', wRecordRef, Database::Customer, '');
        end;
        wRecordRef.Close();

        wRecordRef.Open(Database::Job, false, CompanyName);
        wRecordRef.Get(Job.RecordId);
        // service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::Resource);
        // if service = 'Error' then begin
        //     CreaServicio(ProductoServicio, ProductoServicio.RecordId, Database::Resource);
        //     service := GetMaestro('service', ProductoServicio.Description, 'name', wRecordRef, Database::Resource);
        // end;
        Proyect := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        if Proyect = 'Error' then begin
            CreaProyecto(Job, Job.RecordId, Database::Job);
            Proyect := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        end;
        wRecordRef.Close();

        if not TipoIncidencia.Get(Tarea."User Task Group Assigned To") then begin
            TipoIncidencia.Init();
            TipoIncidencia."Code" := Tarea."User Task Group Assigned To";
            TipoIncidencia."Description" := Tarea."User Task Group Assigned To";
            TipoIncidencia.Insert();
            Commit();
        end;
        wRecordRef.Close();
        wRecordRef.Open(Database::"User Task Group", false, CompanyName);
        wRecordRef.Get(TipoIncidencia.RecordId);
        category := GetMaestro('category', 'Navision', 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        if category = 'Error' then begin
            CreaCategoria('Navision', TipoIncidencia.RecordId, Database::"User Task Group", 'Malla Publicidad');
            category := GetMaestro('category', 'Navision', 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        end;
        wRecordRef.Close();
        // if not Recurso.Get(User."Full Name") then begin
        //     Recurso.Init();
        //     Recurso."No." := User."Full Name";
        //     Recurso.Type := Recurso.Type::Person;
        //     Recurso.Name := User."Full Name";
        //     Recurso.Insert();
        //     Commit();
        //     CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);

        // end;
        Tarea.CalcFields("Assigned To User Name");
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Assigned To");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario responsable %1 no existe en Gtask o, no está enlazado', Tarea."Assigned To User Name");
        responsable := UserGtaskMalla."Id Gtask";
        UserGtaskMalla.SetRange("Id Usuario", Tarea.Supervisor);
        If Not UserGtaskMalla.FindFirst() then Error('El usuario supervisor %1 no existe en Gtask o, no está enlazado', Tarea."Supervisor User Name");
        supervisor := UserGtaskMalla."Id Gtask";
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Created By");
        Tarea.CalcFields("Created by User Name");
        If Not UserGtaskMalla.FindFirst() then Error('El usuario %1 no existe en Gtask o, no está enlazado', Tarea."Created by User Name");
        usuario := UserGtaskMalla."Id Gtask";
        //     {
        // "department": "604767e49fea4e001874b283",
        // "expirationDate": {
        //     "date": "2021-10-26T10:42:02",
        //     "rule": null,
        //     "custom": false
        // },
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('department', departament);
        JsonFormater.WriteStartObject('expirationDate');
        JsonFormater.WriteStringProperty('date', Hora(Tarea."Created DateTime"));
        JsonFormater.WriteNullProperty('rule');
        JsonFormater.WriteBooleanProperty('custom', false);
        JsonFormater.WriteEndObject();
        Dias := 0;
        JsonFormater.WriteStringProperty('daysToPerform', Dias + 1);
        JsonFormater.WriteStringProperty('description', Tarea.Description);
        JsonFormater.WriteStringProperty('observation', '');
        JsonFormater.WriteStringProperty('project', Proyect);
        JsonFormater.WriteStringProperty('client', Client);
        JsonFormater.WriteStringProperty('category', category);
        JsonFormater.WriteStringProperty('user', responsable);
        CompanyInfo.Get();
        JsonFormater.WriteStringProperty('Id_Navision', CompanyInfo."Clave Recursos" + Format(Tarea.ID));
        JsonFormater.WriteStringProperty('supervisor', supervisor);
        //owner
        JsonFormater.WriteStringProperty('owner', usuario);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"Task Card", Tarea);
        if StrPos(Url, 'http://NAV-MALLA01:48900') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        if StrPos(Url, 'http://nav-malla01:48900/') > 0 then
            Url := 'https://bc220.malla.es/' + CopyStr(Url, 26);
        JsonFormater.WriteStringProperty('link', Url);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url task" + 'task', Token(), RequestType::post, jSon);
        IF Json <> '' THEN BEGIN

            JsonArray.ReadFrom(Json);
            foreach JsonToken in JsonArray do begin
                JsonTask := JsonToken.AsObject();
                Clear(JDatoDetalleToken);
                If JsonTask.Get('Id_Navision', JDatoDetalleToken) Then begin
                    if not Evaluate(idNium, JDatoDetalleToken.AsValue().AsText()) then begin
                        If StrLen(JDatoDetalleToken.AsValue().AsText()) < 2 then
                            idNium := 0
                        else
                            Evaluate(idNium, CopyStr(JDatoDetalleToken.AsValue().AsText(), 3, StrLen(JDatoDetalleToken.AsValue().AsText())));
                    end;
                    If idNium = Tarea.ID then begin
                        Clear(JDatoDetalleToken);
                        JsonTask.Get('_id', JDatoDetalleToken);
                        Id := JDatoDetalleToken.AsValue().AsText();
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            Tarea.Id_Tarea := Id;
            Tarea.Modify();
        end;
        // "daysToPerform": 1,
        // "description": "Tarea prueba",
        // "observation": "Observaciones",
        // "service": "60589ab346c40b00195cc993",
        // "category": "6047b4ad8163a70018d3a2dd",
        // "project": "604bf21602913a001899c173",
        // "user": "60d31d7d0c6fff00183fe616",
        // "supervisor": "60d348afd3c595001917760a",
        // "priority": "HIGH",
        // "commandOrder": [
        //     "60d34a51d3c5950019177675",
        //     "60d3485fd3c5950019177601",
        //     "60d34a0dd3c5950019177665"
        // ],
        // "mentions": ["60d31d7d0c6fff00183fe616"]
    end;

    /// <summary>
    /// CreaDepartamento.
    /// </summary>
    /// <param name="Valor">Text.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    /// <param name="Company">Text.</param>
    procedure CreaDepartamento(Valor: Text; tRecordId: RecordId; Tabla: Integer; Company: Text)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Valor);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'department', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, Company);
                    end;

            end;
        end;
    end;

    procedure InsertarDepartamentoOservicio(Valor: Text; Company: Text; Servicio: Boolean): Text
    var
        tRecordId: RecordId;
        Tabla: Integer;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonCampo: JsonToken;
        JsonDepartment: JsonObject;
        ResposabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        CompayInfo: Record "Company Information";
        RestApi: Codeunit "Control Ocr";
        id: Integer;

    begin
        //  [
        //     {
        //         "_id": "65608a4bdbb75c00181ae83c",
        //         "establishment": "6581485f67b6630011d83caf",
        //         "name": "Dirección General",
        //         "createdAt": "2023-11-24T11:34:35.046Z",
        //         "updatedAt": "2023-11-24T11:34:35.046Z",
        //         "__v": 0
        //     }
        //  ]
        If not Servicio then begin
            CompayInfo.Get();
            Json := Restapi.RestApiToken(CompayInfo."Url Task" + 'department', Token(), RequestType::get, '');
            JsonArray.ReadFrom(Json);
            foreach JsonToken in JsonArray do begin
                JsonDepartment := JsonToken.AsObject();
                if JsonDepartment.Get('_id', JsonCampo) then begin
                    if JsonCampo.AsValue().AsText() = Valor then begin
                        ResposabilitiCenter.ChangeCompany(Company);
                        ResposabilitiCenter.Init();
                        JsonDepartment.Get('name', JsonCampo);
                        ResposabilitiCenter."Code" := Copystr(JsonCampo.AsValue().AsText(), 1, 10);
                        ResposabilitiCenter.Name := JsonCampo.AsValue().AsText();
                        ResposabilitiCenter.Insert();
                        InsertLink(ResposabilitiCenter.RecordId, Database::"Responsibility Center", Valor, Company);
                        exit(ResposabilitiCenter.Code);
                        break;
                    end;
                end;
            end;
        end else begin
            CompayInfo.Get();
            Json := Restapi.RestApiToken(CompayInfo."Url Task" + 'service', Token(), RequestType::get, '');
            JsonArray.ReadFrom(Json);
            foreach JsonToken in JsonArray do begin
                JsonDepartment := JsonToken.AsObject();
                if JsonDepartment.Get('_id', JsonCampo) then begin
                    if JsonCampo.AsValue().AsText() = Valor then begin
                        WorkCenter.ChangeCompany(Company);
                        WorkCenter.Init();
                        JsonDepartment.Get('name', JsonCampo);
                        WorkCenter."No." := Copystr(JsonCampo.AsValue().AsText(), 1, 20);
                        WorkCenter.Name := JsonCampo.AsValue().AsText();
                        WorkCenter.Insert();
                        InsertLink(ResposabilitiCenter.RecordId, Database::"Work Center", Valor, Company);
                        exit(WorkCenter."No.");
                        break;
                    end;
                end;
            end;
        end;
    end;


    /// <summary>
    /// CreaDServicio.
    /// </summary>
    /// <param name="Valor">Text.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    /// <param name="Company">Text.</param>
    procedure CreaServicio(Valor: Text; tRecordId: RecordId; Tabla: Integer; Company: Text)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Valor);
        JsonFormater.WriteStringProperty('description', Valor);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'service', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, Company);
                    end;

            end;
        end;
    end;


    /// <summary>
    /// CreaCategoria.
    /// </summary>
    /// <param name="Valor">Text.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    /// <param name="Company">Text.</param>
    procedure CreaCategoria(Valor: Text; tRecordId: RecordId; Tabla: Integer; Company: Text)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Valor);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'category', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, Company);
                    end;
            end;
        end;

    end;

    procedure RecuperaId(Id: Text; Tabla: Integer; Company: Text): RecordId;
    var
        Link: Record "Data Migration Error";
    begin
        If Company <> Company then Link.ChangeCompany(Company);
        Link.SetRange("Migration Type", Id);
        Link.SetRange("Destination Table ID", Tabla);
        //Link.Reset();
        if Link.FindFirst() then exit(Link."Source Staging Table Record ID");

    end;

    /// <summary>
    /// CreaProveedor.
    /// </summary>
    /// <param name="Proveedor">Record Vendor.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    procedure CreaProveedor(Proveedor: Record Vendor; tRecordId: RecordId; Tabla: Integer)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Proveedor.Name);
        JsonFormater.WriteStringProperty('street', Proveedor.Address);
        JsonFormater.WriteStringProperty('vatRegisterNO', Proveedor."VAT Registration No.");
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'provider', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, '');
                    end;
            end;
        end;
    end;

    /// <summary>
    /// CreaCliente.
    /// </summary>
    /// <param name="Customer">Record Customer.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer,''.</param>
    procedure CreaCliente(Customer: Record Customer; tRecordId: RecordId; Tabla: Integer)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Customer.Name);
        JsonFormater.WriteStringProperty('street', Customer.Address);
        JsonFormater.WriteStringProperty('vatRegisterNO', Customer."VAT Registration No.");
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'client', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin

                        InsertLink(tRecordId, Tabla, Value1, '');
                    end;
            end;
        end;
    end;

    /// <summary>
    /// CreaContacto.
    /// </summary>
    /// <param name="Customer">Record Contact.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    procedure CreaContacto(Customer: Record Contact; tRecordId: RecordId; Tabla: Integer)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Customer.Name);
        JsonFormater.WriteStringProperty('street', Customer.Address);
        JsonFormater.WriteStringProperty('vatRegisterNO', Customer."VAT Registration No.");
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'client', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, '');
                    end;
            end;
        end;
    end;

    /// <summary>
    /// CreaProducto.
    /// </summary>
    /// <param name="Item">Record Item.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    procedure CreaProducto(Item: Record Item; tRecordId: RecordId; Tabla: Integer)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', item.Description);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'product', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, '');
                    end;
            end;
        end;
    end;

    procedure UpdateRecurso(Recurso: Record Resource; tRecordId: RecordId; Tabla: Integer; IdKuara: Text)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Recurso.Name);
        JsonFormater.WriteStringProperty('No', Recurso."No.");
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'resource\' + IdKuara, Token(), RequestType::put, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, '');
                    end;
            end;
        end;
    end;


    /// <summary>
    /// CreaRecurso.
    /// </summary>
    /// <param name="Recurso">Record Resource.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    procedure CreaRecurso(Recurso: Record Resource; tRecordId: RecordId; Tabla: Integer)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
    begin
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Recurso.Name);
        JsonFormater.WriteStringProperty('No', Recurso."No.");
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'resource', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, '');
                    end;
            end;
        end;
    end;

    /// <summary>
    /// CreaServicio.
    /// </summary>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    // procedure CreaProductoServicio(ProductoServicio: Record Resource; tRecordId: RecordId; Tabla: Integer; Company: Text)
    // var
    //     JsonFormater: Codeunit "Json Text Reader/Writer";
    //     RestApi: Codeunit "Control Ocr";
    //     jSon: Text;
    //     RequestType: Option Get,patch,put,post,delete;
    //     Client: Text;
    //     Proveedor: Text;
    //     Customer: Record Customer;
    //     Vendor: Record Vendor;
    //     Producto: Text;
    //     Item: Record Item;
    //     Link: Record "Data Migration Error";
    //     Name: Text;
    //     Value1: Text;
    //     JSONMgt: Codeunit "JSON Management";
    //     wRecordRef: RecordRef;
    // begin
    //     //       "_id": "60589ab346c40b00195cc993",
    //     //     "establishment": "604754af75efa40018027f62",
    //     //     "name": "BBB",
    //     //     "createdAt": "2021-03-22T13:25:07.999Z",
    //     //     "updatedAt": "2021-10-25T08:10:42.373Z",
    //     //     "__v": 0,
    //     //     "provider": "61711bcbe7a94c289c94fcc3",
    //     //     "client": "60ed44c26a580923c877cc43",
    //     //     "componentWarranty": 100,
    //     //     "componentWork": 13,
    //     //     "endDate": "2021-10-24T12:05:04.361Z",
    //     //     "product": "6172a8e7d86b5066a0c8710c",
    //     //     "resource": "6172a453d86b5066a0c8710a",
    //     //     "startDate": "2021-10-22T12:05:01.580Z"
    //     // },
    //     If Customer.Get(ProductoServicio."Customer No.") then begin
    //         wRecordRef.Open(Database::Customer, false, CompanyName);
    //         wRecordRef.Get(Customer.RecordId);
    //         Client := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer);
    //         If Client = 'Error' then begin
    //             CreaCliente(Customer, Customer.RecordId, Database::Customer);
    //             Client := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer);
    //         end;
    //         wRecordRef.Close();
    //     end;
    //     If Vendor.Get(ProductoServicio."Vendor No.") then begin
    //         wRecordRef.Open(Database::Vendor, false, CompanyName);
    //         wRecordRef.Get(Vendor.RecordId);
    //         Proveedor := GetMaestro('provider', Vendor."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Vendor);
    //         if Proveedor = 'Error' Then begin
    //             CreaProveedor(Vendor, Vendor.RecordId, Database::Vendor);
    //             Proveedor := GetMaestro('provider', Vendor."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Vendor);
    //         end;
    //         wRecordRef.Close();
    //     end;
    //     If Item.Get(ProductoServicio."Item No.") then begin
    //         wRecordRef.Open(Database::Item, false, CompanyName);
    //         wRecordRef.Get(Item.RecordId);
    //         Producto := GetMaestro('product', Item.Description, 'name', wRecordRef, Database::Item);
    //         if Producto = 'Error' Then begin
    //             CreaProducto(Item, Item.RecordId, Database::Item);
    //             Producto := GetMaestro('product', Item.Description, 'name', wRecordRef, Database::Item);
    //         end;
    //         wRecordRef.Close();
    //     end;
    //     JsonFormater.WriteStartObject('');
    //     JsonFormater.WriteStringProperty('name', ProductoServicio.Name);
    //     if Proveedor <> '' Then
    //         JsonFormater.WriteStringProperty('provider', Proveedor);
    //     if Client <> '' then
    //         JsonFormater.WriteStringProperty('client', Client);
    //     JsonFormater.WriteStringProperty('componentWarranty', Format(ProductoServicio."Warranty % (Parts)"));
    //     JsonFormater.WriteStringProperty('componentWork', Format(ProductoServicio."Warranty % (Labor)"));
    //     JsonFormater.WriteStringProperty('endDate', Format(ProductoServicio."Warranty Ending Date (Parts)", 0, '<Year4>-<Month,2>-<Day,2>T00:00:00'));
    //     if Producto <> '' Then
    //         JsonFormater.WriteStringProperty('product', Producto);
    //     JsonFormater.WriteStringProperty('startDate', Format(ProductoServicio."Warranty Starting Date (Parts)", 0, '<Year4>-<Month,2>-<Day,2>T00:00:00'));
    //     JsonFormater.WriteEndObject();
    //     Json := JsonFormater.GetJSonAsText();
    //     CompanyInfo.Get();
    //     Json := RestApi.RestApiToken(CompanyInfo."Url Task"+'/service', RequestType::post, jSon,Qwark::Ocr);
    //     JSONMgt.InitializeObject(Json);
    //     JSONMgt.ReadProperties();
    //     WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
    //         CASE Name OF
    //             '_id':
    //                 begin
    //                     InsertLink(tRecordId, Tabla, Value1);
    //                 end;
    //         end;
    //     end;
    // end;

    /// <summary>
    /// CreaProyecto.
    /// </summary>
    /// <param name="Job">Record Job.</param>
    /// <param name="tRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    procedure CreaProyecto(Job: Record Job; tRecordId: RecordId; Tabla: Integer)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Client: Text;
        Proveedor: Text;
        Customer: Record Customer;
        Vendor: Record Vendor;
        Producto: Text;
        Item: Record Item;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        wRecordRef: RecordRef;
        CompanyInfo: Record "Company Information";
    begin
        //       "_id": "60589ab346c40b00195cc993",
        //     "establishment": "604754af75efa40018027f62",
        //     "name": "BBB",
        //     "createdAt": "2021-03-22T13:25:07.999Z",
        //     "updatedAt": "2021-10-25T08:10:42.373Z",
        //     "__v": 0,
        //     "provider": "61711bcbe7a94c289c94fcc3",
        //     "client": "60ed44c26a580923c877cc43",
        //     "componentWarranty": 100,
        //     "componentWork": 13,
        //     "endDate": "2021-10-24T12:05:04.361Z",
        //     "product": "6172a8e7d86b5066a0c8710c",
        //     "resource": "6172a453d86b5066a0c8710a",
        //     "startDate": "2021-10-22T12:05:01.580Z"
        // },
        If Customer.Get(Job."Bill-to Customer No.") then begin
            wRecordRef.Open(Database::Customer, false, CompanyName);
            wRecordRef.Get(Customer.RecordId);
            Client := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer, '');
            If Client = 'Error' then begin
                CreaCliente(Customer, Customer.RecordId, Database::Customer);
                Client := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer, '');
            end;
            wRecordRef.Close();
        end;
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('name', Job.Description);
        // if Proveedor <> '' Then
        //     JsonFormater.WriteStringProperty('provider', Proveedor);
        // if Client <> '' then
        //     JsonFormater.WriteStringProperty('client', Client);
        // JsonFormater.WriteStringProperty('componentWarranty', Format(ProductoServicio."Warranty % (Parts)"));
        // JsonFormater.WriteStringProperty('componentWork', Format(ProductoServicio."Warranty % (Labor)"));
        // JsonFormater.WriteStringProperty('endDate', Format(ProductoServicio."Warranty Ending Date (Parts)", 0, '<Year4>-<Month,2>-<Day,2>T00:00:00'));
        // if Producto <> '' Then
        //     JsonFormater.WriteStringProperty('product', Producto);
        // JsonFormater.WriteStringProperty('startDate', Format(ProductoServicio."Warranty Starting Date (Parts)", 0, '<Year4>-<Month,2>-<Day,2>T00:00:00'));
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'project', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
            CASE Name OF
                '_id':
                    begin
                        InsertLink(tRecordId, Tabla, Value1, '');
                    end;
            end;
        end;
    end;

    // procedure CreaServicioServiceItem(ProductoServicio: Record "Service Item"; tRecordId: RecordId; Tabla: Integer)
    // var
    //     JsonFormater: Codeunit "Json Text Reader/Writer";
    //     RestApi: Codeunit "Control Ocr";
    //     jSon: Text;
    //     RequestType: Option Get,patch,put,post,delete;
    //     Client: Text;
    //     Proveedor: Text;
    //     Customer: Record Customer;
    //     Vendor: Record Vendor;
    //     Producto: Text;
    //     Item: Record Item;
    //     Link: Record "Data Migration Error";
    //     Name: Text;
    //     Value1: Text;
    //     JSONMgt: Codeunit "JSON Management";
    //     wRecordRef: RecordRef;
    // begin
    //     //       "_id": "60589ab346c40b00195cc993",
    //     //     "establishment": "604754af75efa40018027f62",
    //     //     "name": "BBB",
    //     //     "createdAt": "2021-03-22T13:25:07.999Z",
    //     //     "updatedAt": "2021-10-25T08:10:42.373Z",
    //     //     "__v": 0,
    //     //     "provider": "61711bcbe7a94c289c94fcc3",
    //     //     "client": "60ed44c26a580923c877cc43",
    //     //     "componentWarranty": 100,
    //     //     "componentWork": 13,
    //     //     "endDate": "2021-10-24T12:05:04.361Z",
    //     //     "product": "6172a8e7d86b5066a0c8710c",
    //     //     "resource": "6172a453d86b5066a0c8710a",
    //     //     "startDate": "2021-10-22T12:05:01.580Z"
    //     // },
    //     If Customer.Get(ProductoServicio."Customer No.") then begin
    //         wRecordRef.Open(Database::Customer, false, CompanyName);
    //         wRecordRef.Get(Customer.RecordId);
    //         Client := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer);
    //         If Client = 'Error' then begin
    //             CreaCliente(Customer, Customer.RecordId, Database::Customer);
    //             Client := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer);
    //         end;
    //         wRecordRef.Close();
    //     end;
    //     If Vendor.Get(ProductoServicio."Vendor No.") then begin
    //         wRecordRef.Open(Database::Vendor, false, CompanyName);
    //         wRecordRef.Get(Vendor.RecordId);
    //         Proveedor := GetMaestro('provider', Vendor."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Vendor);
    //         if Proveedor = 'Error' Then begin
    //             CreaProveedor(Vendor, Vendor.RecordId, Database::Vendor);
    //             Proveedor := GetMaestro('provider', Vendor."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Vendor);
    //         end;
    //         wRecordRef.Close();
    //     end;
    //     If Item.Get(ProductoServicio."Item No.") then begin
    //         wRecordRef.Open(Database::Item, false, CompanyName);
    //         wRecordRef.Get(Item.RecordId);
    //         Producto := GetMaestro('product', Item.Description, 'name', wRecordRef, Database::Item);
    //         if Producto = 'Error' Then begin
    //             CreaProducto(Item, Item.RecordId, Database::Item);
    //             Producto := GetMaestro('product', Item.Description, 'name', wRecordRef, Database::Item);
    //         end;
    //         wRecordRef.Close();
    //     end;
    //     JsonFormater.WriteStartObject('');
    //     JsonFormater.WriteStringProperty('name', ProductoServicio.Description);
    //     if Proveedor <> '' Then
    //         JsonFormater.WriteStringProperty('provider', Proveedor);
    //     if Client <> '' then
    //         JsonFormater.WriteStringProperty('client', Client);
    //     JsonFormater.WriteStringProperty('componentWarranty', Format(ProductoServicio."Warranty % (Parts)"));
    //     JsonFormater.WriteStringProperty('componentWork', Format(ProductoServicio."Warranty % (Labor)"));
    //     JsonFormater.WriteStringProperty('endDate', Format(ProductoServicio."Warranty Ending Date (Parts)", 0, '<Year4>-<Month,2>-<Day,2>T00:00:00'));
    //     if Producto <> '' Then
    //         JsonFormater.WriteStringProperty('product', Producto);
    //     JsonFormater.WriteStringProperty('startDate', Format(ProductoServicio."Warranty Starting Date (Parts)", 0, '<Year4>-<Month,2>-<Day,2>T00:00:00'));
    //     JsonFormater.WriteEndObject();
    //     Json := JsonFormater.GetJSonAsText();
    //     CompanyInfo.Get();
    //     Json := RestApi.RestApiToken(CompanyInfo."Url Task"+'service', RequestType::post, jSon,Qwark::Ocr);
    //     JSONMgt.InitializeObject(Json);
    //     JSONMgt.ReadProperties();
    //     WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
    //         CASE Name OF
    //             '_id':
    //                 begin
    //                     InsertLink(tRecordId, Tabla, Value1);
    //                 end;
    //         end;
    //     end;
    // end;

    /// <summary>
    /// GetPartes.
    /// </summary>
    procedure GetPartes()
    var
        RestApi: Codeunit "Control Ocr";
        Token: Text;
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JSONMgt2: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        Name2: Text;
        Value2: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        PartesTrabajot: Record "Time Sheet Header" temporary;
        Lineast: Record "Time Sheet Line" temporary;
        PartesTrabajo: Record "Time Sheet Header";
        Lineas: Record "Time Sheet Line";
        Customer: Record Customer;
        Tareas: Record "User Task";
        ProductoServicio: Record Resource;
        ProductooRecurso: Text;
        Recurso: Record Resource;
        Producto: Record Item;
        Unidades: Record "Unit of Measure";
        d: Integer;
        e: Integer;
        wRecorId: RecordId;
        wRecordRef: recordref;
    begin
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'workorder', Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;
        If a = 0 Then exit;
        WHILE i < a DO BEGIN
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                PartesTrabajot.Init();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            PartesTrabajot."No." := Value1;

                        'client':
                            begin
                                //"61784d02a6d775001ad55f32",
                                if Value1 <> '' then begin
                                    If GetNombreMaestro('client', Value1, 'name', Database::Customer, Customer.FieldNo(Name), wRecorId, '') Then begin
                                        wRecordRef := wRecorId.GetRecord();
                                        PartesTrabajot.Validate(Cliente, wRecordRef.Field(Customer.FieldNo("No.")).Value);
                                        wRecordRef.Close();
                                    end;
                                end;
                            end;
                        'task':
                            begin
                                // "6178544da6d775001ad5600d",
                                Tareas.SetRange(Id_Tarea, Value1);
                                if not Tareas.FindFirst() then begin
                                    Tareas.Reset();
                                    Tareas.FindFirst();
                                end;
                                PartesTrabajot.Validate(Tarea, tareas.ID);
                            end;
                        'service':
                            begin
                                // "617851eda6d775001ad55fc7",
                                Clear(wRecorId);
                                If GetNombreMaestro('service', Value1, 'name', Database::Resource, ProductoServicio.FieldNo(Name), wRecorId, '') Then begin
                                    wRecordRef := wRecorId.GetRecord();
                                    PartesTrabajot.Validate("Producto Servicio", wRecordRef.Field(ProductoServicio.FieldNo("No.")).Value);
                                    wRecordRef.Close();
                                end;
                            end;
                        //'project': "617863aba6d775001ad561dc",
                        'startDate':
                            If Evaluate(PartesTrabajot."Fecha Inicio", Value1) then
                                ;// "2021-10-26T20:23:42.491Z",
                        'endDate':
                            If Evaluate(PartesTrabajot."Fecha fin", Value1) then
                                ;//"2021-10-27T20:23:49.939Z
                        'lines':
                            begin
                                JSONMgt2.InitializeCollection(Value1);
                                d := JSONMgt2.GetCollectionCount;
                                e := 0;
                                WHILE e < d DO BEGIN
                                    JSONMgt2.GetObjectFromCollectionByIndex(Value1, e);
                                    JSONMgt2.InitializeObject(Value1);
                                    JSONMgt2.ReadProperties();
                                    Lineast.Init();
                                    Lineast.No := 'temp';
                                    WHILE JSONMgt2.GetNextProperty(Name2, Value2) DO BEGIN
                                        CASE Name2 OF
                                            'resourceOrProduct':
                                                begin
                                                    //"61786418a6d775001ad561e6",
                                                    Clear(wRecorId);
                                                    If GetNombreMaestro('product', Value2, 'name', Database::Item, Producto.FieldNo(Description), wRecorId, '') then begin
                                                        wRecordRef := wRecorId.GetRecord();
                                                        Producto.SetRange(Description, ProductooRecurso);
                                                        Lineast.Tipo := Lineast.Tipo::Producto;
                                                        Lineast.Validate("Time Sheet No.", wRecordRef.Field(Producto.FieldNo("No.")).Value);
                                                        wRecordRef.Close();

                                                    end else begin
                                                        Clear(wRecorId);
                                                        If GetNombreMaestro('resource', Value2, 'name', Database::Resource, Recurso.FieldNo(Name), wRecorId, '') then begin
                                                            wRecordRef := wRecorId.GetRecord();
                                                            Lineast.Tipo := Lineast.Tipo::Recurso;
                                                            Lineast.Validate("Time Sheet No.", wRecordRef.Field(Recurso.FieldNo("No.")).Value);
                                                            wRecordRef.Close();
                                                        end else begin
                                                            Lineast.Tipo := Lineast.Tipo::" ";
                                                            Lineast.No := '';
                                                        end;
                                                    end;
                                                end;
                                            'unit':
                                                begin
                                                    If Unidades.Get(Value2) then Lineast.Unidad := Value2;
                                                end;
                                            'quantity':
                                                if Evaluate(Lineast.Cantidad, Value2) then
                                                    ;
                                            'description':
                                                Lineast.Descripcion := Value2; //"Piza repuesto A-120"
                                        end;
                                    end;
                                    Lineast."Line No." := e;
                                    Lineast.Insert(true);
                                    e += 1;
                                end;
                            end;
                    end;
                end;
                i += 1;
                if not PartesTrabajo.Get(PartesTrabajot."No.") Then begin
                    PartesTrabajo := PartesTrabajot;
                    PartesTrabajo.Insert(true);
                    if Lineast.FindFirst() then
                        repeat
                            Lineas := Lineast;
                            Lineas.No := PartesTrabajo."No.";
                            Lineas.Insert(true);
                        until Lineast.Next() = 0;

                end;
                Lineast.DeleteAll();
            end;
        end;

    end;

    procedure CreateParte(Var Task: Record "User Task")
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
        Job: Record Job;
        Proyecto: Text;
        wRecordRef: RecordRef;
        Customer: Record Customer;
        Cliente: Text;
        service: Text;
        workService: Record "Work Center";
        OrdenFijajon: Record "Orden fijación";
        NOrden: Integer;
        Resource: Record Resource;
        Recursos: Text;
    begin
        //      {
        //     "lines": [
        //         {
        //             "resourceOrProduct": "6697a6bcbee4b30014a0007a",
        //             "unit": "1",
        //             "quantity": 1,
        //             "description": "Fijar"
        //         }
        //     ],
        //     "_id": "6698e8eebee4b30014a025ac",
        //     "client": "6698e8a7bee4b30014a025a5",
        //     "task": "6698c57dbee4b30014a016c3",
        //     "service": "65437c1cdbb75c00181787aa",
        //     "project": "665843febee4b300149dabe9",
        //     "startDate": "2024-07-18T10:05:10.073Z",
        //     "endDate": "2024-07-18T10:05:14.474Z",
        //     "establishment": "6581485f67b6630011d83caf",
        //     "createdAt": "2024-07-18T10:05:34.616Z",
        //     "updatedAt": "2024-07-18T10:05:34.616Z",
        //     "__v": 0
        // }
        JsonFormater.WriteStartObject('');
        If not Job.Get(Task."Job No.") then Job.Init;
        //crear cliente
        Customer.Get(Job."Bill-to Customer No.");
        wRecordRef.Get(Customer.RecordId);
        Cliente := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer, '');
        if Cliente = 'Error' then begin
            CreaCliente(Customer, Customer.RecordId, Database::Customer);
            Cliente := GetMaestro('client', Customer."VAT Registration No.", 'vatRegisterNO', wRecordRef, Database::Customer, '');
        end;
        JsonFormater.WriteStringProperty('client', Cliente);
        wRecordRef.Close();
        Clear(wRecordRef);
        wRecordRef.Get(Job.RecordId);
        Proyecto := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        if Proyecto = 'Error' then begin
            CreaProyecto(Job, Job.RecordId, Database::Job);
            Proyecto := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
        end;
        wRecordRef.Close();
        JsonFormater.WriteStringProperty('task', Task.Id_Tarea);
        Clear(wRecordRef);
        workService.Get(Task.Servicio);
        wRecordRef.Get(workService.RecordId);
        service := GetMaestro('service', Task.Servicio, 'name', wRecordRef, Database::"Work Center", 'Malla Publicidad');
        if service = 'Error' then begin
            CreaServicio(Task.Servicio, workService.RecordId, Database::"Work Center", 'Malla Publicidad');
            service := GetMaestro('service', Task.Servicio, 'name', wRecordRef, Database::"Work Center", 'Malla Publicidad');
        end;
        JsonFormater.WriteStringProperty('service', service);
        JsonFormater.WriteStringProperty('project', Proyecto);
        JsonFormater.WriteStringProperty('startDate', Hora(Task."Start DateTime"));
        JsonFormater.WriteStringProperty('endDate', Hora(Task."Start DateTime"));
        JsonFormater.WriteStartArray('lines');
        NOrden := Task.OrdenFijacion;
        OrdenFijajon.SetRange("Nº Orden", NOrden);
        If OrdenFijajon.FindFirst() then
            repeat
                JsonFormater.WriteStartObject('');
                //Crear OrdenFijajon."Nº Recurso"
                Clear(wRecordRef);
                Resource.Get(OrdenFijajon."Nº Recurso");
                wRecordRef.Get(Resource.RecordId);
                Recursos := GetMaestro('resource', Resource.Name, 'name', wRecordRef, Database::Resource, '');
                if Recursos = 'Error' then begin
                    CreaRecurso(Resource, Resource.RecordId, Database::Resource);
                    Recursos := GetMaestro('resource', Resource.Name, 'name', wRecordRef, Database::Resource, '');
                end;
                JsonFormater.WriteStringProperty('resourceOrProduct', Recursos);
                JsonFormater.WriteStringProperty('unit', '--');
                JsonFormater.WriteNumberProperty('quantity', 1);
                JsonFormater.WriteStringProperty('description', 'Fijación');
                JsonFormater.WriteEndObject();
            until ordenFijajon.Next() = 0;
        JsonFormater.WriteEndArray();
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'workorder', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        JSONMgt.ReadProperties();
        // WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
        //     CASE Name OF
        //         '_id':
        //             begin
        //                 InsertLink(Task.RecordId, Database::"User Task", Value1, '');
        //             end;
        //     end;
        // end;
    end;

    /// <summary>
    /// InsertLink.
    /// </summary>
    /// <param name="wRecordId">RecordId.</param>
    /// <param name="Tabla">Integer.</param>
    /// <param name="Id">Text.</param>
    /// <param name="Company">Text.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure InsertLink(wRecordId: RecordId; Tabla: Integer; Id: Text; Company: Text): Boolean
    var
        IdLink: Integer;
        Link: Record "Data Migration Error";
    begin
        If Company <> Company then Link.ChangeCompany(Company);
        Link.SetRange("Migration Type", Id);
        Link.SetRange("Destination Table ID", Tabla);
        if Link.FindFirst() then exit(true);
        Link.Reset();
        If Link.FindLast() Then IdLink := Link.Id;
        If Company <> Company then Link.ChangeCompany(Company);
        Link.Init();
        Link.Id := IdLink + 1;
        Link."Source Staging Table Record ID" := wRecordId;
        Link."Destination Table ID" := Tabla;
        Link."Migration Type" := Id;
        If Link.Insert() then;
        exit(true);
    end;

    procedure GetLink(wRecordId: RecordId; Tabla: Integer; Company: Text): Text
    var
        IdLink: Integer;
        Link: Record "Data Migration Error";
    begin
        If Company <> Company then Link.ChangeCompany(Company);
        Link.SetRange("Source Staging Table Record ID", wRecordId);
        Link.SetRange("Destination Table ID", Tabla);
        if Link.FindFirst() then exit(Link."Migration Type");

    end;

    procedure DeleteLink(wRecordId: RecordId; Tabla: Integer; Id: Text; Company: Text): Boolean
    var
        IdLink: Integer;
        Link: Record "Data Migration Error";
    begin
        If Company <> Company then Link.ChangeCompany(Company);
        Link.SetRange("Source Staging Table Record ID", wRecordId);
        Link.SetRange("Destination Table ID", Tabla);
        if Link.FindFirst() then Link.Delete();

        exit(true);
    end;

    internal procedure DeleteTarea(Id_Tarea: Text)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        Link: Record "Data Migration Error";
        Name: Text;
        Value1: Text;
        JSONMgt: Codeunit "JSON Management";
        CompanyInfo: Record "Company Information";
        UserSetups: Record "User Setup";
        User: Record User;
        EmailResponsable: Text;
        EmailSupervisor: Text;
        Rec: Record "User Task";
    begin
        // Delete /task/id
        Rec.SetRange("Id_Tarea", Id_Tarea);
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Id_Tarea, Token(), RequestType::delete, '');
        If not Rec.FindFirst() Then begin
            exit;
        end;

        User.SetRange("User Security ID", Rec."Assigned To");
        If User.FindFirst() Then
            EmailResponsable := User."Contact Email";
        User.SetRange("User Security ID", Rec.Supervisor);
        If User.FindFirst() Then
            EmailSupervisor := User."Contact Email";
        User.SetRange("User Security ID", Rec."Assigned To");
        If User.FindFirst() Then begin
            User.FindFirst();
            EnviaCorreo(Rec."No.", Rec.GetDescription(), true, '', false, 'Tarea Eliminada', EmailResponsable, EmailSupervisor, '', '', User."Full Name", true, Rec.Id_Tarea);
        end;
        //Rec.Delete();
    end;

    internal procedure CreateUsers(var UserGtaskMalla: Record UsuariosGtask)
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Username: Text;
        Email: Text;
        Link: Record "Data Migration Error";
        IdLink: Integer;
        UsuariosGtaskTemp: Record UsuariosGtask temporary;
    begin
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'users', Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;
        If a = 0 Then exit;
        WHILE i < a DO BEGIN
            UsuariosGtaskTemp.Init();
            UsuariosGtaskTemp."Id Gtask" := Format(i);
            UsuariosGtaskTemp.Insert();
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            begin
                                Id := Value1;
                                UsuariosGtaskTemp."Id Gtask Providsional" := ID;
                            end;
                        'username':
                            begin
                                UsuariosGtaskTemp.Nombre := Value1;
                            end;
                        'email':
                            begin
                                UsuariosGtaskTemp.Email := Value1;
                            end;
                    end;
                end;
            end;
            If Not UserGtaskMalla.Get(UsuariosGtaskTemp."Id Gtask Providsional") Then begin
                UserGtaskMalla."Id Gtask" := UsuariosGtaskTemp."Id Gtask Providsional";
                UserGtaskMalla.Nombre := UsuariosGtaskTemp.Nombre;
                UserGtaskMalla.Email := UsuariosGtaskTemp.Email;
                UserGtaskMalla.Insert();
            end;
            i += 1;
        end;
        Exit;
    end;

    internal procedure SincronizarDepartamentos(Company: Text): Text
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Departamentos: Record "Responsibility Center";
        Link: Record "Data Migration Error";
        IdLink: Integer;
    begin
        If Company <> '' then begin
            link.ChangeCompany(Company);
        end;
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'department', Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;
        If a = 0 Then exit('Error');
        WHILE i < a DO BEGIN
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            Id := Value1;
                        'name':
                            begin
                                Departamentos.SetRange(Name, Value1);
                                If Departamentos.FindFirst() then begin
                                    Link.SetRange("Source Staging Table Record ID", Departamentos.RecordId);
                                    Link.SetRange("Destination Table ID", Database::"Responsibility Center");
                                    If Not Link.FindSet() Then
                                        InsertLink(Departamentos.RecordId, Database::"Responsibility Center", Id, Company);

                                end else begin
                                    Departamentos.Init();
                                    Departamentos."Code" := CopyStr(Value1, 1, MaxStrLen(Departamentos."Code"));
                                    Departamentos."Name" := CopyStr(Value1, 1, MaxStrLen(Departamentos.Name));
                                    If Departamentos.Insert() Then
                                        InsertLink(Departamentos.RecordId, Database::"Responsibility Center", Id, Company);
                                end;
                            end;

                    end;
                end;
            end;
            i += 1;
        end;
        Exit('');
    end;

    internal procedure SincronizarServicios(Company: Text): Text
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Pregunta: Text;
        JSONMgt: Codeunit "JSON Management";
        JsonObjt: Codeunit "Json Text Reader/Writer";
        Name: Text;
        Value1: Text;
        i: Integer;
        a: Integer;
        Json: Text;
        Id: Text;
        Servicios: Record "work Center";
        Link: Record "Data Migration Error";
        IdLink: Integer;
    begin
        If Company <> '' then begin
            link.ChangeCompany(Company);
        end;
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'service', Token(), RequestType::Get, '');
        JSONMgt.InitializeCollection(Json);
        a := JSONMgt.GetCollectionCount;
        If a = 0 Then exit('Error');
        WHILE i < a DO BEGIN
            JSONMgt.GetObjectFromCollectionByIndex(Json, i);
            JSONMgt.InitializeObject(Json);
            IF Json <> '' THEN BEGIN
                JSONMgt.InitializeObject(Json);
                JSONMgt.ReadProperties();
                WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                    CASE Name OF
                        '_id':
                            Id := Value1;
                        'name':
                            begin
                                Servicios.SetRange(Name, Value1);
                                If Servicios.FindFirst() then begin
                                    Link.SetRange("Source Staging Table Record ID", Servicios.RecordId);
                                    Link.SetRange("Destination Table ID", Database::"Work Center");
                                    If Not Link.FindSet() Then
                                        InsertLink(Servicios.RecordId, Database::"Work Center", Id, Company);

                                end else begin
                                    Servicios.Init();
                                    Servicios."No." := CopyStr(Value1, 1, MaxStrLen(Servicios."No."));
                                    Servicios."Name" := CopyStr(Value1, 1, MaxStrLen(Servicios.Name));
                                    If Servicios.Insert() Then
                                        InsertLink(Servicios.RecordId, Database::"Work Center", Id, Company);
                                end;
                            end;

                    end;
                end;
            end;
            i += 1;
        end;
        Exit('');
    end;

    internal procedure CrearTarea(
        RecRef: RecordRef;
        Descripcion: Text;
        Departamento: Text;
        Servicio: Text;
        Title: Text;
        Categoria: Text;
        Adjuntar: Boolean;
        Adjunto: Text)
    var
        UserTask: Record "User Task";
        User: Record User;
        Gtask: Codeunit Gtask;
        EmailResponsable: Text[250];
        EmailSupervisor: Text[250];
        TipoIncidencia: Record "User Task Group";
        Resource: Record "Resource";
        Emplazamientos: Record Emplazamientos;
        Pnel: Record "PNEL";
        Responsable: Guid;
        Supervisor: Guid;
        TM: Record "Tenant Media";
        InStr: Instream;
        DoccAttach: Record "Document Attachment";
        DoccAttachNew: Record "Document Attachment";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ListadeCorreos: Text;
        LineNo: Integer;
        FieldRef: FieldRef;
    begin
        Gtask.CrearCategorias(CompanyName);
        Commit();
        UserTask.Init();
        UserTask.Validate(Title, Title);

        UserTask.SetDescription(Descripcion);
        // If not IsNullGuid(UserTask.Supervisor) then
        //     UserTask."Created By" := UserTask.Supervisor
        // else
        UserTask."Created By" := UserSecurityId();
        UserTask.Validate("Created DateTime", CurrentDateTime);
        If Date2DWY(WorkDate(), 1) = 5 then begin
            Usertask."Start DateTime" := CreateDateTime(CalcDate('3D', WorkDate()), 080000T);
            Usertask."Due DateTime" := CreateDateTime(CalcDate('3D', WorkDate()), 130000T);
        end else begin
            Usertask."Start DateTime" := CreateDateTime(CalcDate('1D', WorkDate()), 080000T);
            Usertask."Due DateTime" := CreateDateTime(CalcDate('1D', WorkDate()), 130000T);
        end;
        Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, Categoria, EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos);
        UserTask.Validate(Priority, Usertask.Priority::High);
        UserTask.Validate("Object Type", Usertask."Object Type"::Page);
        case RecRef.Number Of
            Database::Resource:
                begin
                    UserTask.Validate("Object ID", Page::"Resource Card");
                    UserTask.Id_record := RecRef.RecordId;
                    Resource.SetRange("No.", RecRef.Field(Resource.FieldNo("No.")).Value);
                end;
            Database::Emplazamientos:
                begin
                    if Categoria = 'PNEL' then
                        UserTask.Validate("Object ID", Page::"PNEL Emplazamientos")
                    else
                        UserTask.Validate("Object ID", Page::"Ficha emplazamiento");
                    UserTask.Id_record := RecRef.RecordId;
                    Resource.SetRange("Nº Emplazamiento", RecRef.Field(Emplazamientos.FieldNo("Nº Emplazamiento")).Value);
                end;
            Database::"PNEL":
                begin
                    UserTask.Validate("Object ID", Page::"PNEL Emplazamientos");
                    UserTask.Id_record := RecRef.RecordId;
                    Resource.SetRange("Nº Emplazamiento", RecRef.Field(Emplazamientos.FieldNo("Nº Emplazamiento")).Value);
                    DoccAttach.SetRange("Table ID", Database::"PNEL");
                    DoccAttach.SetRange("No.", RecRef.Field(Pnel.FieldNo("Nº Emplazamiento")).Value);
                    FieldRef := RecRef.Field(Pnel.FieldNo(Solicitud));
                    LineNo := FieldRef.Value;
                    if LineNo <> 0 then
                        DoccAttach.SetRange("Line No.", LineNo);
                    if DoccAttach.FindFirst() then
                        repeat
                            DoccAttachNew := DoccAttach;
                            DoccAttachnew."Table ID" := Database::"User Task";
                            DoccAttachnew."No." := UserTask."No.";
                            DoccAttachNew.Insert(true);
                        until DoccAttach.Next() = 0;
                    DoccAttach.Reset();

                end;

        end;
        UserTask.Insert(true);
        // if not IsNullGuid(UserTask.Supervisor) then begin
        //     UserTask."Created By" := Supervisor;
        UserTask."No." := Format(UserTask.ID);
        UserTask.Modify();

        //end;
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
        If (IsNullGuid(UserTask."Supervisor")) or (IsNullGuid(UserTask."Assigned To"))
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
            If (IsNullGuid(UserTask."Supervisor")) or (IsNullGuid(UserTask."Assigned To"))
            or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
            or (UserTask.Servicio = '') Then begin
                Message('No ha completado los campos Supervisor, Responsable, Categoría, Departamento y Servicio, Proceso cancelado');
                UserTask.Delete();
                exit;
            end;
        end;
        Clear(Gtask);

        If Not Resource.FindSet() then
            Resource.Init();
        RecRef.Close();
        Clear(RecRef);
        If Adjuntar then begin
            RecRef.GetTable(Usertask);
            RecRef.Get(Usertask.RecordId);

            FileMgt.BLOBImport(TempBlob, Adjunto);
            TempBlob.CreateInStream(InStr);
            DoccAttach.SaveAttachmentFromStream(InStr, RecRef, UserTask."No." + '.pdf');
            //DoccAttach.Insert();
            tm.Delete();
        end;
        Gtask.CrearTareaTecnico(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
        Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea);
    end;



    internal procedure CrearTareaEmpazamiento(
       RecRef: RecordRef;
       Title: Text;
       Responsable: Guid;
       Supervisor: Guid;
       Depatamento: code[20];
       Servicio: code[20];
       Adjuntar: Boolean;
       Adjunto: Text)
    var
        UserTask: Record "User Task";
        User: Record User;
        Gtask: Codeunit Gtask;
        EmailResponsable: Text[250];
        EmailSupervisor: Text[250];
        TipoIncidencia: Record "User Task Group";
        Resource: Record "Resource";
        Emplazamientos: Record Emplazamientos;
        TM: Record "Tenant Media";
        InStr: Instream;
        DoccAttach: Record "Document Attachment";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ListadeCorreos: Text;
        UserTaskCard: Page "User Task Card";
        Categoria: code[20];
    begin
        Gtask.CrearCategorias(CompanyName);
        Commit();
        UserTask.Init();
        UserTask.Validate(Title, Title);

        // If not IsNullGuid(UserTask.Supervisor) then
        //     UserTask."Created By" := UserTask.Supervisor
        // else
        UserTask."Created By" := UserSecurityId();
        UserTask."Assigned To" := Responsable;
        UserTask."Supervisor" := Supervisor;
        UserTask.Departamento := Depatamento;
        UserTask.Servicio := Servicio;
        UserTask.Validate("Created DateTime", CurrentDateTime);
        If Date2DWY(WorkDate(), 1) = 5 then begin
            Usertask."Start DateTime" := CreateDateTime(CalcDate('3D', WorkDate()), 080000T);
            Usertask."Due DateTime" := CreateDateTime(CalcDate('3D', WorkDate()), 130000T);
        end else begin
            Usertask."Start DateTime" := CreateDateTime(CalcDate('1D', WorkDate()), 080000T);
            Usertask."Due DateTime" := CreateDateTime(CalcDate('1D', WorkDate()), 130000T);
        end;
        UserTask.Validate(Priority, Usertask.Priority::High);
        UserTask.Validate("Object Type", Usertask."Object Type"::Page);
        case RecRef.Number Of
            Database::Resource:
                begin
                    UserTask.Validate("Object ID", Page::"Resource Card");
                    UserTask.Id_record := RecRef.RecordId;
                    Resource.SetRange("No.", RecRef.Field(Resource.FieldNo("No.")).Value);
                end;
            Database::Emplazamientos:
                begin
                    UserTask.Validate("Object ID", Page::"Ficha emplazamiento");
                    UserTask.Id_record := RecRef.RecordId;
                    Resource.SetRange("Nº Emplazamiento", RecRef.Field(Emplazamientos.FieldNo("Nº Emplazamiento")).Value);
                end;
            7001225:
                begin
                    UserTask.Validate("Object ID", Page::"PNEL Emplazamientos");
                    UserTask.Id_record := RecRef.RecordId;
                    Resource.SetRange("Nº Emplazamiento", RecRef.Field(Emplazamientos.FieldNo("Nº Emplazamiento")).Value);
                end;
        end;

        UserTask.Insert(true);
        // if not IsNullGuid(UserTask.Supervisor) then begin
        //     UserTask."Created By" := Supervisor;
        UserTask."No." := Format(UserTask.ID);
        UserTask.Modify();
        //end;
        Commit();
        UserTaskCard.SetRecord(UserTask);
        UserTaskCard.RunModal();
        iF UserTask.Estado = UserTask.Estado::Cancelado then begin
            UserTask.Get(UserTask.ID);
            Commit();
            If Confirm('¿Desea borrar la tarea?') then begin
                UserTask.Delete();
                exit;
            end;
        end;
        Commit();
        //Page.RunModal(Page::"User Task Card", UserTask);
        UserTaskCard.DevuelveSupervisoryResponsable(Responsable, Supervisor, Depatamento, Servicio, Categoria, EmailResponsable,
        EmailSupervisor, ListadeCorreos);
        Commit();
        UserTask.Get(UserTask.ID);
        If (IsNullGuid(UserTask."Supervisor")) or (IsNullGuid(UserTask."Assigned To"))
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
            If (IsNullGuid(UserTask."Supervisor")) or (IsNullGuid(UserTask."Assigned To"))
            or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
            or (UserTask.Servicio = '') Then begin
                Message('No ha completado los campos Supervisor, Responsable, Categoría, Departamento y Servicio, Proceso cancelado');
                UserTask.Delete();
                exit;
            end;
        end;
        Clear(Gtask);

        If Not Resource.FindSet() then
            Resource.Init();
        RecRef.Close();
        Clear(RecRef);
        If Adjuntar then begin
            RecRef.GetTable(Usertask);
            RecRef.Get(Usertask.RecordId);

            FileMgt.BLOBImport(TempBlob, Adjunto);
            TempBlob.CreateInStream(InStr);
            DoccAttach.SaveAttachmentFromStream(InStr, RecRef, UserTask."No." + '.pdf');
            //DoccAttach.Insert();
            tm.Delete();
        end;
        Gtask.CrearTareaTecnico(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
        Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea);
    end;



    internal procedure CrearTareaVisita(RecRef: RecordRef; Descripcion: Text;
    Departamento: Text; Servicio: Text; Title: Text;
    Categoria: Text; Adjuntar: Boolean; Adjunto: Text;
    Fecha: Date; Hora: Time; Responsable: Guid)
    var
        UserTask: Record "User Task";
        User: Record User;
        Gtask: Codeunit Gtask;
        EmailResponsable: Text[250];
        EmailSupervisor: Text[250];
        TipoIncidencia: Record "User Task Group";
        Todo: Record "To-Do";
        Emplazamientos: Record Emplazamientos;
        Supervisor: Guid;
        TM: Record "Tenant Media";
        InStr: Instream;
        DoccAttach: Record "Document Attachment";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ListaCorreos: Text;
    begin
        Gtask.CrearCategorias(CompanyName);
        Commit();
        UserTask.Init();
        UserTask.Validate(Title, Title);


        // If not IsNullGuid(UserTask.Supervisor) then
        //     UserTask."Created By" := UserTask.Supervisor
        // else
        UserTask."Created By" := UserSecurityId();
        UserTask.Validate("Created DateTime", CurrentDateTime);
        Usertask."Start DateTime" := CreateDateTime(Fecha, Hora);
        Usertask."Due DateTime" := CreateDateTime(Fecha, Hora);
        Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, Categoria, EmailResponsable, EmailSupervisor, User, UserTask, ListaCorreos);
        UserTask.Validate(Priority, Usertask.Priority::High);
        UserTask.Validate("Object Type", Usertask."Object Type"::Page);
        UserTask.Validate("Object ID", Page::"Visitas Emplazamiento");

        UserTask.Id_record := RecRef.RecordId;
        UserTask.Insert(true);

        UserTask."No." := Format(UserTask.ID);
        // if not IsNullGuid(UserTask.Supervisor) then
        //     UserTask."Created By" := Supervisor;
        UserTask.Modify();
        UserTask.SetDescription(Descripcion);
        If IsNullGuid(UserTask."Supervisor") or IsnullGuid(UserTask."Assigned To")
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
            If IsnullGuid(UserTask."Supervisor") or IsnullGuid(UserTask."Assigned To")
            or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
            or (UserTask.Servicio = '') Then begin
                Message('No ha completado los campos Supervisor, Responsable, Categoría, Departamento y Servicio, Proceso cancelado');
                UserTask.Delete();
                exit;
            end;
        end;
        Clear(Gtask);

        RecRef.Close();
        Clear(RecRef);
        If Adjuntar then begin
            RecRef.GetTable(Usertask);
            RecRef.Get(Usertask.RecordId);

            FileMgt.BLOBImport(TempBlob, Adjunto);
            TempBlob.CreateInStream(InStr);
            DoccAttach.SaveAttachmentFromStream(InStr, RecRef, UserTask."No." + '.pdf');
            //DoccAttach.Insert();
            tm.Delete();
        end;
        Gtask.CrearTareaTecnico('', UserTask, UserTask.Departamento, UserTask.Servicio, false);
        Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListaCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea);
    end;

    procedure EnviaCorreo(
      "No.": Text;
      Descrpcion: Text;
      Adjunto: Boolean;
      Motivo: Text;
      Notificacion: Boolean;
      Asunto: Text;
      SendTo: Text;
      CC: Text;
      Lista: Text;
      BCC: Text; Nombre: Text; Eliminada: Boolean; IdTarea: Text)


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
            if Eliminada then
                BigText := BigText + ('Se ha eliminado la Tarea: <b>' + Descrpcion + ' </b> ')
            else
                BigText := BigText + ('Se ha creado la Tarea: <b>' + Descrpcion + ' </b> ');
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
        if REmail.Send(true, emilesc::Gtasks) then begin

        end;
    end;


    local procedure CrearDepartamnetoyServicio(var departament: Text; var service: Text)
    var
        Departamentos: Record "Responsibility Center";
        Servicios: Record "Work Center";
        DepartamentosEmp: Record "Responsibility Center";
        ServiciosEmp: Record "Work Center";
        wRecordRef: RecordRef;
    begin

        If Not Departamentos.Get(departament) then begin
            Departamentos.Init();
            Departamentos."Code" := departament;
            Departamentos."Name" := departament;
            If departament <> '' then
                Departamentos.Insert();
            Commit();
        end;
        wRecordRef.Open(Database::"Responsibility Center", false, 'Malla Publicidad');
        wRecordRef.Get(departamentos.RecordId);
        departament := GetMaestro('department', departament, 'name', wRecordRef, Database::"Responsibility Center", 'Malla Publicidad');
        If departament = 'Error' then begin
            CreaDepartamento(Departamentos.Name, departamentos.RecordId, Database::"Responsibility Center", 'Malla Publicidad');
            departament := GetMaestro('department', Departamentos.Name, 'name', wRecordRef, Database::"Responsibility Center", 'Malla Publicidad');
        end;
        If Not Servicios.Get(service) then begin
            Servicios.Init();
            Servicios."No." := service;
            Servicios."Name" := service;
            Servicios.Insert();
            Commit();
        end;
        wRecordRef.Close();
        wRecordRef.Open(Database::"Work Center", false, 'Malla Publicidad');
        wRecordRef.Get(Servicios.RecordId);
        service := GetMaestro('service', service, 'name', wRecordRef, Database::"Work Center", 'Malla Publicidad');
        If service = 'Error' then begin
            CreaServicio(Servicios.Name, Servicios.RecordId, Database::"Work Center", 'Malla Publicidad');
            service := GetMaestro('service', Servicios.Name, 'name', wRecordRef, Database::"Work Center", 'Malla Publicidad');
        end;
        wRecordRef.Close();
    end;

    procedure Hora(Datetime: DateTime): Text
    var
        Hora: Time;
    begin
        Hora := DT2Time(Datetime);
        if hora < 095959T then
            exit(Format("DateTime", 0, '<Year4>-<Month,2>-<Day,2>T0<Hours24>:<Minutes,2>:<Seconds,2>'))
        else
            exit(Format("DateTime", 0, '<Year4>-<Month,2>-<Day,2>T<Hours24>:<Minutes,2>:<Seconds,2>'));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment FactBox", 'OnBeforeDrillDown', '', false, false)]
    local procedure OnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        "Task": Record "User Task";

    begin

        If DocumentAttachment."Table ID" = Database::"User Task" then begin
            RecRef.Open(Database::"User Task");
            Task.SetRange("No.", DocumentAttachment."No.");
            If Task.FindFirst() then
                RecRef.GetTable("Task");
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

    begin
        If DocumentAttachment."Table ID" = Database::"User Task" then begin
            Task.SetRange("No.", DocumentAttachment."No.");
            If Task.FindFirst() then
                RecRef.GetTable("Task");
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterSetDocumentAttachmentFiltersForRecRefInternal', '', false, false)]
    local procedure OnAfterSetDocumentAttachmentFiltersForRecRefInternal(var DocumentAttachment: Record "Document Attachment"; RecordRef: RecordRef; GetRelatedAttachments: Boolean)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        UserTask: Record "User Task";
    begin
        If RecordRef.Number = Database::"User Task" then begin
            FieldRef := RecordRef.Field(UserTask.FieldNo("No."));
            RecNo := FieldRef.Value();
            DocumentAttachment.SetRange("No.", RecNo);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    var
        UserTask: Record "User Task";
    begin
        If TableNo = Database::"User Task" then begin
            Result := true;
            FieldNo := UserTask.FieldNo("No.");
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

    procedure DevuelveSupervisoryResponsable(
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
        UserGtaskMalla.SetRange("Id Usuario", UserSecurityId());
        If not UserGtaskMalla.FindFirst() then Error('Usuario %1 no encontrado en Gtask', UserId());
        If IsnullGuid(Responsable) then begin
            UserGtaskMalla.Reset();
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
                    UserGtaskMalla.SetRange(Departamento, Departamento);
                    UserGtaskMalla.SetRange(Responsable, true);
                    If UserGtaskMalla.FindFirst() then
                        Responsable := UserGtaskMalla."Id Usuario";
                end;
            end;
        end;
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
                UserGtaskMalla.SetRange(Departamento, Servicio);
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
        UserTask.Validate("Created By", UserSecurityId());
        UserxbyCategory.Reset();
        UserxbyCategory.SetRange(Departamento, Servicio);
        UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange(Supervisor, true);
        UserxbyCategory.SetRange("Copiado en Mail", true);
        User.Reset();
        If UserxbyCategory.FindFirst() then
            repeat
                User.SetRange("User Security ID", UserxbyCategory."User Security ID");
                if User.FindFirst() then
                    if (User."Contact Email" <> '') And (User."Contact Email" <> EmailSupervisor) then
                        ListaCorreo := ListaCorreo + User."Contact Email" + ';';
            until UserxbyCategory.Next() = 0;
        UserxbyCategory.Reset();
        UserxbyCategory.SetRange(Departamento, Departamento);
        UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange(Responsable, true);
        UserxbyCategory.SetRange("Copiado en Mail", true);
        User.Reset();
        If UserxbyCategory.FindFirst() then
            repeat
                User.SetRange("User Security ID", UserxbyCategory."User Security ID");
                if User.FindFirst() then
                    if (User."Contact Email" <> '') and (User."Contact Email" <> EmailResponsabe) then
                        ListaCorreo := ListaCorreo + User."Contact Email" + ';';
            until UserxbyCategory.Next() = 0;

    end;

    procedure Email(
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


}