
/// <summary>
/// Codeunit GTask (ID 80110).
/// </summary>
codeunit 7001148 GTask
{
    var
        Qwark: Option Ocr,Qwark;
        LToken: Text;
        Procesos_GTask: Codeunit Procesos_GTask;
        UserTaskTemp: Record "User Task" temporary;
        FijacionBatchInitialized: Boolean;
        FijacionBatchOrdenNo: Integer;
        FijacionBatchDepartament: Text;
        FijacionBatchService: Text;
        FijacionBatchCategory: Text;
        FijacionBatchRecursoCache: Dictionary of [Text, Text];
        FijacionBatchProyectoCache: Dictionary of [Text, Text];
        TareasEncoladasEnEstaEjecucion: List of [Integer];
        IdGtaskCreadorOrden: Text[50];
        IdUsuarioCreadorOrden: Guid;

    trigger OnRun()
    var
        ColaGtaskEstado: Codeunit ColaGtaskEstado;
    begin
        ColaGtaskEstado.SetSuprimirEncolado(false);
        UpdateTasksFicheros();
        MarcarTareasComunicadas();
        EnviarCorreoFicheros();
        CrearTareasSinId();
        ProcesarMantenimientosVencidos();
        Procesos_GTask.EnviarAvisosTareasProgramadas();
        // GetTareas();
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



    procedure UpdateTaskGtaskUserandStatus(idTarea: Text; IdKey: Integer; Responsable: Text)
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
            JsonObjt.Add('user', responsable);
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
        ExisteDoc: Boolean;
        Int: InStream;
        DocumentStream: Outstream;
        TempBlob: Codeunit "Temp Blob";
        Bs64: Codeunit "Base64 Convert";
        DetOrdenFijcion: Record "Orden fijación";
        RequestType: Option Get,patch,put,post,delete;
        DocUrl: Text;
        DocName: Text;
        a: Integer;
        Docuname2: Text;
        id: Integer;


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
        If not JSonObjt.Get('document', JsonCampo) then
            exit;
        JSonDocuments := JsonCampo.AsArray();
        foreach JSonDocumentToken in JSonDocuments do begin
            JsonDocument := JSonDocumentToken.AsObject();

            If JsonDocument.Get('name', JsonCampo) then begin
                DocName := JsonCampo.AsValue().AsText();
                If JsonDocument.Get('document', JsonCampo) then begin
                    JsonDocumentinf := JsonCampo.AsObject();
                    Clear(JsonCampo);
                    If JsonDocumentInf.Get('url', JsonCampo) then begin
                        DocUrl := JsonCampo.AsValue().AsText();
                        DocumentAttachment.Reset();
                        DocumentAttachment.SetRange("Table ID", Database::"User Task");
                        DocumentAttachment.SetRange("No.", Tarea."No.");
                        Docuname2 := DocName;
                        If DocName.Contains('.pdf') then
                            ExisteDoc := ComprobarSiExisteDocumento(Docurl)
                        else
                            ExisteDoc := true;
                        If DocName.Contains('.jpg') then
                            DocName := CopyStr(DocName, 1, StrLen(DocName) - 4);
                        DocumentAttachment.SetFilter("File Name", '%1', DocName + '*');
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
                            If Docuname2 = '' Then Docuname2 := DocName;
                            DocumentAttachment."File Name" := Docuname2;
                            DocumentAttachment."URL" := DocUrl;
                            DocumentAttachment.ID_Url := 0;
                            if JsonDocumentInf.Get('_id', JsonCampo) then
                                if JsonCampo.IsValue and not JsonCampo.AsValue().IsNull then
                                    if not Evaluate(DocumentAttachment.ID_Url, JsonCampo.AsValue().AsText()) then
                                        DocumentAttachment.ID_Url := 0;
                            DocumentAttachment."Document Flow Service" := true;
                            DocumentAttachment.Insert();
                            If (Tarea.OrdenFijacion <> 0) Then begin
                                DetOrdenFijcion.SetRange("Nº Orden", Tarea.OrdenFijacion);
                                If Tarea.Reserva <> 0 Then
                                    DetOrdenFijcion.SetRange("Nº Reserva", Tarea.Reserva);
                                If DetOrdenfijcion.FindFirst() then begin
                                    DocumentAttachment."Table ID" := Database::Job;
                                    DocumentAttachment."No." := DetOrdenfijcion."Nº Proyecto";
                                    repeat
                                        DocumentAttachment."Line No." := a;
                                        DocumentAttachment."Document Flow Service" := true;
                                        a += 1;
                                    until DocumentAttachment.Insert();
                                end;
                                DocumentAttachment."Table ID" := Database::"Orden fijación";
                                DocumentAttachment."ID_Doc" := DetOrdenFijcion."Nº Orden";
                                DocumentAttachment."No." := DetOrdenfijcion."Nº Proyecto";
                                DocumentAttachment."Line No." := Tarea."Reserva";
                                //Actualizar el estado de la orden fijación
                                DetOrdenFijcion."Tiene Fotos" := true;
                                DetOrdenFijcion.Modify();
                                // Buscar el registro en "Imagenes Orden fijación" para la valla correspondiente.

                                If DocumentAttachment.Insert() then
                                    AdImagenValla(DocumentAttachment, '');
                            end;
                        end;
                        DocumentAttachmentTMP := DocumentAttachment;
                        If DocumentAttachmentTMP.Insert() Then;
                    end;
                end;
            end;
        end;
        DocumentAttachmentTMP.reset;
        DocumentAttachment.SetRange("Table ID", Database::"User Task");
        DocumentAttachment.SetRange("No.", Tarea."No.");

        If DocumentAttachment.FindFirst() then
            repeat
                Docuname2 := DocumentAttachment."File Name";
                If DocumentAttachment."File Name".Contains('.jpg') then
                    DocumentAttachment."File Name" := CopyStr(DocumentAttachment."File Name", 1, StrLen(DocumentAttachment."File Name") - 4);
                DocumentAttachmentTMP.Setfilter("File Name", '%1', DocumentAttachment."File Name" + '*');
                If Not DocumentAttachmentTMP.FindLast() then begin
                    DocumentAttachment."File Name" := Docuname2;
                    SetDocAttachment(DocumentAttachment, Id_Tarea);
                end;
            until DocumentAttachment.Next() = 0;
        //GetSetChat(Tarea, Id_Tarea);
    end;

    procedure ResetTaskPriorityNormal(Id_Tarea: Text)
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Json: Text;
        JsonObjt: JsonObject;
    begin
        if Id_Tarea = '' then
            exit;

        CompanyInfo.Get();
        Clear(JsonObjt);
        JsonObjt.Add('type', 'NORMAL');
        JsonObjt.WriteTo(Json);
        RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Id_Tarea, Token(), RequestType::put, Json);
    end;

    procedure SetDocAttachment(var DocumentAttachment: Record "Document Attachment"; Id_Tarea: Text)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        Base64Data: Text;
        DocumentStream: OutStream;
        Int: InStream;
        TempBlob: Codeunit "Temp Blob";
        Bs64: Codeunit "Base64 Convert";
        RestApi: Codeunit "RestApi";
        Json: Text;
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        FileManager: Codeunit "File Management";

    begin
        Clear(JsonFormater);
        JsonFormater.WriteStartObject('');
        Base64Data := '';
        JsonFormater.WriteStringProperty('establishment', '6581485f67b6630011d83caf');
        If DocumentAttachment."Document Reference ID".HasValue then begin
            DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
            TempBlob.CreateInStream(Int);
            Base64Data := Bs64.ToBase64(Int);
            JsonFormater.WriteStringProperty('document', Base64Data);
        end else begin

            If DocumentAttachment.ID_Url = 0 Then begin
                Base64Data := DocumentAttachment.ToBase64StringOcr(DocumentAttachment.Url);
                JsonFormater.WriteStringProperty('document', Base64Data);
            end else begin
                JsonFormater.WriteStartObject('document');
                JsonFormater.WriteStringProperty('_id', DocumentAttachment.ID_Url);
                JsonFormater.WriteStringProperty('url', DocumentAttachment.Url);
                JsonFormater.WriteEndObject();
            end;
        end;

        if DocumentAttachment."File Extension" = '' then begin
            DocumentAttachment."File Extension" := FileManager.GetExtension(DocumentAttachment."File Name");
            if DocumentAttachment."File Extension" = '' then DocumentAttachment."File Extension" := 'jpg';
        end;
        JsonFormater.WriteStringProperty('name', DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension");
        JsonFormater.WriteBooleanProperty('bc', true);
        JsonFormater.WriteEndObject();
        Clear(RestApi);
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/document/' + Id_Tarea, Token(), RequestType::put, jSon);
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
        UserIdUs: Text;
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
                UserIdUs := JsonCampo.AsValue().AsText();
                JsonChat.Get('text', JsonCampo);
                Texto := JsonCampo.AsValue().AsText();
                JsonChat.Get('date', JsonCampo);
                FechaHora := JsonCampo.AsValue().AsDateTime();
                Chat.Reset();
                Chat.SetRange("Tabla", Database::"User Task");
                Chat.SetRange("ID_TABLA", Tarea.RecordId);
                Chat.SetRange("Descripción Visita", Texto);
                Procesos_GTask.BusCaUsuario(UserIdus, UserGtaskMalla);
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



    procedure GetTarea(IdTarea: Text): Text
    var
        ColaGtaskEstado: Codeunit ColaGtaskEstado;
    begin
        ColaGtaskEstado.SetSuprimirEncolado(true);
        GetTareaImpl(IdTarea);
        ColaGtaskEstado.SetSuprimirEncolado(false);
    end;

    local procedure GetTareaImpl(IdTarea: Text): Text
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
        Docuname2: Text;
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
                Tareas.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
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
                    Tareas.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
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
                                    Docuname2 := DocuName;
                                    If DocuName.Contains('.jpg') then
                                        DocuName := CopyStr(DocuName, 1, StrLen(DocuName) - 4);
                                    DocumentAtt.Setfilter("File Name", '%1', DocuName + '*');
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
                                        If Docuname2 = '' Then Docuname2 := DocuName;
                                        DocumentAtt."File Name" := DocuName2;
                                        DocumentAtt."URL" := DocUrl;
                                        if JsonDetalleCampo.Get('_id', JsonCampo) then begin
                                            if JsonCampo.IsValue and not JsonCampo.AsValue().IsNull then
                                                if not Evaluate(DocumentAtt.ID_Url, JsonCampo.AsValue().AsText()) then
                                                    DocumentAtt.ID_Url := 0;
                                        end else
                                            DocumentAtt.ID_Url := 0;
                                        DocumentAtt.Insert();
                                    end;
                                end;
                            end;
                        end;
                    end;
            END;
        end;

    end;

    procedure DevuelveDatoTarea(IdTarea: Text; Dato: Text): Text
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
        If JsonTarea.Get(dato, JsonCampo) Then begin
            Texto := JsonCampo.AsValue().AsText();
            exit(texto);
        end;

    end;

    procedure GetTareas(): Text
    var
        ColaGtaskEstado: Codeunit ColaGtaskEstado;
    begin
        ColaGtaskEstado.SetSuprimirEncolado(true);
        GetTareasImpl();
        ColaGtaskEstado.SetSuprimirEncolado(false);
    end;

    local procedure GetTareasImpl(): Text
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
        Docuname2: Text;
        JsonDocumentos: JsonArray;
        JsonTokenDoc: JsonToken;
        SaltarTareaAlineada: Boolean;
    begin
        CompanyInfo.Get();
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task', Token(), RequestType::Get, '');
        JsonArray.ReadFrom(Json);
        foreach JsonToken in JsonArray do begin
            SaltarTareaAlineada := false;
            JsonTarea := JsonToken.AsObject();
            If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
                Texto := JsonCampo.AsValue().AsText();
                if DelChr(Texto, '=', ' ') = '' then
                    CrearTareaDesdeGtaskSinNavision(JsonTarea)
                else begin
                    If Not Evaluate(Id, Texto) then begin
                        CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                        Tareas.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
                        Texto := CopyStr(JsonCampo.AsValue().AsText(), 3, StrLen(JsonCampo.AsValue().AsText()));
                    end;
                    if Evaluate(Id, Texto) then begin
                        JsonTarea.Get('_id', JsonCampo);
                        IdTarea := JsonCampo.AsValue().AsText();
                        If Tareas.Get(Id) then begin
                            if (Tareas."Fecha Comunicado Cambio" <> 0DT) and (Tareas."Fecha Cambio" <> 0DT) and (Tareas."Fecha Comunicado Cambio" >= Tareas."Fecha Cambio") then
                                SaltarTareaAlineada := true
                            else begin
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
                                    AplicarFechasDesdeGtaskJson(Tareas, JsonTarea);
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
                            end;
                        end; //else
                             //If Id <> 0 Then DeleteTarea(IdTarea);
                    end;
                end;
            end else
                CrearTareaDesdeGtaskSinNavision(JsonTarea);

            if (not SaltarTareaAlineada) and JsonTarea.Get('document', JsonCampo) then begin
                JsonDocumentos := JsonCampo.AsArray();
                If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
                    Texto := JsonCampo.AsValue().AsText();
                    If Not Evaluate(Id, Texto) then begin
                        CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                        Tareas.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
                        Texto := CopyStr(JsonCampo.AsValue().AsText(), 3, StrLen(JsonCampo.AsValue().AsText()));
                    end;
                    if Evaluate(Id, Texto) then
                        if Tareas.Get(Id) then begin

                            If Tareas."No." = '' then begin
                                Tareas."No." := Format(Id);
                                Tareas.Modify();
                            end;

                            foreach JsonTokenDoc in JsonDocumentos do begin
                                JsonDetalleCampo := JsonTokenDoc.AsObject();
                                If JsonDetalleCampo.Get('document', JsonCampo) then begin
                                    JSonDocument := JsonCampo.AsObject();
                                    If jSonDocument.Get('url', JsonCampo) then begin
                                        DocUrl := JsonCampo.AsValue().AsText();
                                        DocuName := '';
                                        If jSonDocument.get('name', JsonCampo) then
                                            DocuName := JsonCampo.AsValue().AsText();
                                        if DocuName <> '' then begin
                                            DocumentAtt.Reset();
                                            DocumentAtt.SetRange("Table ID", Database::"User Task");
                                            DocumentAtt.SetRange("No.", Tareas."No.");
                                            Docuname2 := DocuName;
                                            If DocuName.Contains('.jpg') then
                                                DocuName := CopyStr(DocuName, 1, StrLen(DocuName) - 4);
                                            DocumentAtt.Setfilter("File Name", '%1', DocuName + '*');
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
                                                If Docuname2 = '' Then Docuname2 := DocuName;
                                                DocumentAtt."File Name" := DocuName2;
                                                DocumentAtt."URL" := DocUrl;
                                                DocumentAtt.ID_Url := 0;
                                                if JsonDetalleCampo.Get('_id', JsonCampo) then
                                                    if JsonCampo.IsValue and not JsonCampo.AsValue().IsNull then
                                                        if not Evaluate(DocumentAtt.ID_Url, JsonCampo.AsValue().AsText()) then
                                                            DocumentAtt.ID_Url := 0;
                                                DocumentAtt.Insert();
                                            end;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                END;
            end;
        end;

    end;

    /// <summary>
    /// Alta en BC de una tarea creada en GTask sin Id_Navision, y PUT del id a GTask.
    /// </summary>
    local procedure CrearTareaDesdeGtaskSinNavision(JsonTarea: JsonObject)
    var
        Tareas: Record "User Task";
        UserGtaskMalla: Record UsuariosGtask;
        UserTaskGroup: Record "User Task Group";
        ResponsabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        Job: Record Job;
        JsonCampo: JsonToken;
        RecordiD: RecordId;
        RecordRef: RecordRef;
        IdGtask: Text;
        IdGtaskUser: Text;
        StateTxt: Text;
    begin
        if not JsonTarea.Get('_id', JsonCampo) then
            exit;
        if JsonCampo.AsValue().IsNull then
            exit;
        IdGtask := JsonCampo.AsValue().AsText();
        if IdGtask = '' then
            exit;

        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        Tareas.Reset();
        Tareas.SetRange(Id_Tarea, CopyStr(IdGtask, 1, MaxStrLen(Tareas.Id_Tarea)));
        if Tareas.FindFirst() then begin
            UpdateTask(Tareas.Id_Tarea, Format(Tareas.ID));
            exit;
        end;

        Tareas.Init();
        Tareas.Id_Tarea := CopyStr(IdGtask, 1, MaxStrLen(Tareas.Id_Tarea));

        if JsonTarea.Get('user', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                IdGtaskUser := JsonCampo.AsValue().AsText();
                UserGtaskMalla.Reset();
                UserGtaskMalla.SetRange("Id Gtask", CopyStr(IdGtaskUser, 1, MaxStrLen(UserGtaskMalla."Id Gtask")));
                if UserGtaskMalla.FindFirst() then begin
                    Tareas."Assigned To" := UserGtaskMalla."Id Usuario";
                    Tareas.Grupo := UserGtaskMalla.Grupo;
                end;
            end;

        if JsonTarea.Get('supervisor', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                UserGtaskMalla.Reset();
                UserGtaskMalla.SetRange("Id Gtask", CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(UserGtaskMalla."Id Gtask")));
                if UserGtaskMalla.FindFirst() then
                    Tareas.Supervisor := UserGtaskMalla."Id Usuario";
            end;

        if JsonTarea.Get('owner', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                UserGtaskMalla.Reset();
                UserGtaskMalla.SetRange("Id Gtask", CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(UserGtaskMalla."Id Gtask")));
                if UserGtaskMalla.FindFirst() then
                    Tareas."Created By" := UserGtaskMalla."Id Usuario";
            end;

        if JsonTarea.Get('department', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                Clear(RecordiD);
                RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::"Responsibility Center", CompanyName);
                if RecordiD.TableNo <> 0 then begin
                    RecordRef := RecordiD.GetRecord();
                    Tareas.Departamento := RecordRef.Field(ResponsabilitiCenter.FieldNo(Code)).Value;
                end else
                    Tareas.Departamento := InsertarDepartamentoOservicio(JsonCampo.AsValue().AsText(), CompanyName, false);
            end;

        if JsonTarea.Get('service', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                Clear(RecordiD);
                RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::"Work Center", CompanyName);
                if RecordiD.TableNo <> 0 then begin
                    RecordRef := RecordiD.GetRecord();
                    Tareas.Servicio := RecordRef.Field(WorkCenter.FieldNo("No.")).Value;
                end else
                    Tareas.Servicio := InsertarDepartamentoOservicio(JsonCampo.AsValue().AsText(), CompanyName, true);
            end;

        if JsonTarea.Get('category', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                Clear(RecordiD);
                RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::"User Task Group", CompanyName);
                if RecordiD.TableNo <> 0 then begin
                    RecordRef := RecordiD.GetRecord();
                    Tareas."User Task Group Assigned To" := RecordRef.Field(UserTaskGroup.FieldNo(Code)).Value;
                    Tareas."Categoría" := Tareas."User Task Group Assigned To";
                end;
            end;

        if JsonTarea.Get('project', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                Clear(RecordiD);
                RecordiD := RecuperaId(JsonCampo.AsValue().AsText(), Database::Job, CompanyName);
                if RecordiD.TableNo <> 0 then begin
                    RecordRef := RecordiD.GetRecord();
                    Tareas."Job No." := RecordRef.Field(Job.FieldNo("No.")).Value;
                end;
            end;

        if JsonTarea.Get('state', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then begin
                StateTxt := JsonCampo.AsValue().AsText();
                case StateTxt of
                    'PENDING':
                        Tareas.Estado := Tareas.Estado::Pendiente;
                    'INPROCESS':
                        Tareas.Estado := Tareas.Estado::"En Proceso";
                    'FINISHED':
                        Tareas.Estado := Tareas.Estado::Finalizado;
                end;
            end;

        if JsonTarea.Get('description', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then
                Tareas.Title := CopyStr(JsonCampo.AsValue().AsText(), 1, 250);
        if JsonTarea.Get('observation', JsonCampo) then
            if not JsonCampo.AsValue().IsNull then
                Tareas.SetDescription(JsonCampo.AsValue().AsText());

        AplicarFechasDesdeGtaskJson(Tareas, JsonTarea);
        Tareas.Insert(true);
        UpdateTask(Tareas.Id_Tarea, Format(Tareas.ID));
    end;

    procedure CrearTareaFijacion(var OrdenFijacion: Record "Cab Orden fijación"; Tarea: Record "User Task"; Opcion: Option " ",Valla,Opi,Otros; Retirada: Boolean)
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
        if Tarea.EmpresaTarea <> '' then
            Job.ChangeCompany(Tarea.EmpresaTarea);
        Job.Get(Tarea."Job No.");
        If Tarea.EmpresaTarea <> '' then
            wRecordRef.Open(Database::Job, false, Tarea.EmpresaTarea)
        else
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
        JsonFormater.WriteBooleanProperty('bc', true);
        if Tarea.fastPhoto then
            JsonFormater.WriteStringProperty('fastPhoto', 'true');
        //owner
        JsonFormater.WriteStringProperty('owner', usuario);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        Url := UrlCorrecta(Url);
        JsonFormater.WriteStringProperty('link', Url);
        if Opcion = Opcion::Opi then begin
            JsonFormater.WriteStringProperty('IdQr', Tarea.Resource);
            Tarea.IdQr := Tarea.Resource;
        end else begin
            if Retirada then
                JsonFormater.WriteStringProperty('IdQr', Format(Tarea.OrdenFijacion) + '-R' + Format(Tarea.Reserva))
            else
                JsonFormater.WriteStringProperty('IdQr', Format(Tarea.OrdenFijacion) + '-' + Format(Tarea.Reserva));
            Tarea.IdQr := Format(Tarea.OrdenFijacion) + '-' + Format(Tarea.Reserva);
        end;
        AgregarChecklistTareaAJson(JsonFormater, Tarea);
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Tarea.Modify(false);
        Commit();
        Tarea.Get(Tarea.ID);
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
                        break;
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            Commit();
            SelectLatestVersion();
            Tarea.Get(Tarea.ID);
            Tarea.Id_Tarea := Id;
            Tarea.Modify(false);
        end;
        EnviarDocumentos(Tarea, Id);
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

    procedure AddTareaFijacion(var OrdenFijacion: Record "Cab Orden fijación"; var Tarea: Record "User Task"; Opcion: Option " ",Valla,Opi,Otros; Retirada: Boolean; var ArrayTareas: JsonArray)
    var
        JsonTask: JsonObject;
    begin
        InicializarMaestrosFijacionOrden(OrdenFijacion, Tarea);
        ConstruirJsonTareaFijacion(OrdenFijacion, Tarea, Opcion, Retirada, JsonTask);
        Tarea.Modify(false);
        ArrayTareas.Add(JsonTask);
    end;

    procedure CrearTareaFijacionArray(var OrdenFijacion: Record "Cab Orden fijación"; var ArrayTareas: JsonArray)
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        JsonText: Text;
        JsonResp: Text;
        UserTask: Record "User Task";
    begin
        if ArrayTareas.Count() = 0 then begin
            ResetFijacionBatchCache();
            exit;
        end;

        ArrayTareas.WriteTo(JsonText);
        CompanyInfo.Get();
        JsonResp := RestApi.RestApiToken(CompanyInfo."Url task" + 'taskarray', Token(), RequestType::post, JsonText);
        if JsonResp <> '' then
            ActualizarTareasFijacionDesdeRespuesta(JsonResp);

        Commit();
        UserTask.SetRange(OrdenFijacion, OrdenFijacion."Nº Orden");
        UserTask.SetFilter(Reserva, '<>%1', 0);
        if UserTask.FindSet() then
            repeat
                if UserTask.Id_Tarea <> '' then
                    ProcesarTareaFijacionPostEnvio(OrdenFijacion, UserTask);
            until UserTask.Next() = 0;

        ResetFijacionBatchCache();
    end;

    local procedure ResetFijacionBatchCache()
    begin
        FijacionBatchInitialized := false;
        FijacionBatchOrdenNo := 0;
        Clear(FijacionBatchDepartament);
        Clear(FijacionBatchService);
        Clear(FijacionBatchCategory);
        Clear(FijacionBatchRecursoCache);
        Clear(FijacionBatchProyectoCache);
    end;

    local procedure FijacionBatchIsInitializedForOrder(NOrden: Integer): Boolean
    begin
        exit(FijacionBatchInitialized and (FijacionBatchOrdenNo = NOrden));
    end;

    local procedure SetFijacionBatchRecurso(RecursoNo: Code[20]; IdGtask: Text)
    begin
        if RecursoNo = '' then
            exit;
        if FijacionBatchRecursoCache.ContainsKey(RecursoNo) then
            FijacionBatchRecursoCache.Set(RecursoNo, IdGtask)
        else
            FijacionBatchRecursoCache.Add(RecursoNo, IdGtask);
    end;

    local procedure SetFijacionBatchProyecto(CacheKey: Text; IdGtask: Text)
    begin
        if CacheKey = '' then
            exit;
        if FijacionBatchProyectoCache.ContainsKey(CacheKey) then
            FijacionBatchProyectoCache.Set(CacheKey, IdGtask)
        else
            FijacionBatchProyectoCache.Add(CacheKey, IdGtask);
    end;

    local procedure InicializarMaestrosFijacionOrden(var OrdenFijacion: Record "Cab Orden fijación"; var Tarea: Record "User Task")
    var
        DetOrdenFijacion: Record "Orden fijación";
        TipoIncidencia: Record "User Task Group";
        Recurso: Record Resource;
        wRecordRef: RecordRef;
        Categoria: Text;
        departament: Text;
        service: Text;
        category: Text;
        resource: Text;
    begin
        if FijacionBatchIsInitializedForOrder(OrdenFijacion."Nº Orden") then
            exit;

        ResetFijacionBatchCache();
        departament := Tarea.Departamento;
        service := Tarea.Servicio;
        CrearDepartamnetoyServicio(departament, service);

        Categoria := Tarea."User Task Group Assigned To";
        if not TipoIncidencia.Get(Categoria) then begin
            TipoIncidencia.Init();
            TipoIncidencia."Code" := Categoria;
            TipoIncidencia."Description" := Categoria;
            TipoIncidencia.Insert();
            Commit();
        end;
        wRecordRef.Open(Database::"User Task Group", false, CompanyName);
        wRecordRef.Get(TipoIncidencia.RecordId);
        category := GetMaestro('category', Categoria, 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        if category = 'Error' then begin
            CreaCategoria(Categoria, TipoIncidencia.RecordId, Database::"User Task Group", 'Malla Publicidad');
            category := GetMaestro('category', 'Intervencion', 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        end;
        wRecordRef.Close();

        DetOrdenFijacion.SetRange("Nº Orden", OrdenFijacion."Nº Orden");
        if DetOrdenFijacion.FindSet() then
            repeat
                if Recurso.Get(DetOrdenFijacion."Nº Recurso") then begin
                    if not FijacionBatchRecursoCache.Get(Recurso."No.", resource) then begin
                        wRecordRef.Close();
                        wRecordRef.Open(Database::Resource, false, CompanyName);
                        wRecordRef.Get(Recurso.RecordId);
                        resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                        if resource = 'Error' then begin
                            CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                            resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                        end;
                        SetFijacionBatchRecurso(Recurso."No.", resource);
                    end;
                end;
            until DetOrdenFijacion.Next() = 0;
        wRecordRef.Close();

        FijacionBatchInitialized := true;
        FijacionBatchOrdenNo := OrdenFijacion."Nº Orden";
        FijacionBatchDepartament := departament;
        FijacionBatchService := service;
        FijacionBatchCategory := category;
    end;

    local procedure ConstruirJsonTareaFijacion(var OrdenFijacion: Record "Cab Orden fijación"; var Tarea: Record "User Task"; Opcion: Option " ",Valla,Opi,Otros; Retirada: Boolean; var JsonTask: JsonObject)
    var
        UserGtaskMalla: Record UsuariosGtask;
        CompanyInfo: Record "Company Information";
        Job: Record Job;
        wRecordRef: RecordRef;
        responsable: Text;
        Supervisor: Text;
        usuario: Text;
        JobNo: Text;
        Desde: Date;
        Hasta: Date;
        Dias: Integer;
        Url: Text;
        ExpirationDate: JsonObject;
        ProyectoCacheKey: Text;
        JsonNullRule: JsonToken;
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        Clear(JsonTask);

        Tarea.CalcFields("Assigned To User Name");
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Assigned To");
        if not UserGtaskMalla.FindFirst() then
            Error('El usuario responsable %1 no existe en Gtask o, no está enlazado', Tarea."Assigned To User Name");
        responsable := UserGtaskMalla."Id Gtask";

        Tarea.CalcFields("Supervisor User Name");
        UserGtaskMalla.SetRange("Id Usuario", Tarea."Supervisor");
        if not UserGtaskMalla.FindFirst() then
            Error('El usuario  supervisor %1 no existe en Gtask o, no está enlazado', Tarea."Supervisor User Name");
        Supervisor := UserGtaskMalla."Id Gtask";

        UserGtaskMalla.SetRange("Id Usuario", Tarea."Created By");
        if not UserGtaskMalla.FindFirst() then
            Error('El usuario %1 no existe en Gtask o, no está enlazado', Tarea."Created By User Name");
        usuario := UserGtaskMalla."Id Gtask";

        if Tarea.EmpresaTarea <> '' then
            Job.ChangeCompany(Tarea.EmpresaTarea);
        Job.Get(Tarea."Job No.");
        ProyectoCacheKey := ClaveProyectoFijacionCache(Tarea.EmpresaTarea, Tarea."Job No.");
        if not FijacionBatchProyectoCache.Get(ProyectoCacheKey, JobNo) then begin
            if Tarea.EmpresaTarea <> '' then
                wRecordRef.Open(Database::Job, false, Tarea.EmpresaTarea)
            else
                wRecordRef.Open(Database::Job);
            wRecordRef.Get(Job.RecordId);
            JobNo := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
            if JobNo = 'Error' then begin
                CreaProyecto(Job, Job.RecordId, Database::Job);
                JobNo := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
            end;
            wRecordRef.Close();
            SetFijacionBatchProyecto(ProyectoCacheKey, JobNo);
        end;

        Clear(ExpirationDate);
        ExpirationDate.Add('date', Hora(Tarea."Start DateTime"));
        JsonNullRule.ReadFrom('null');
        ExpirationDate.Add('rule', JsonNullRule);
        ExpirationDate.Add('custom', false);

        Desde := Variant2Date(Tarea."Start DateTime");
        if Desde = 0D then begin
            Tarea."Start DateTime" := CurrentDateTime;
            Desde := Variant2Date(Tarea."Start DateTime");
        end;
        Hasta := Variant2Date(Tarea."Due DateTime");
        if Hasta = 0D then begin
            Tarea."Due DateTime" := CurrentDateTime;
            Hasta := Variant2Date(Tarea."Due DateTime");
        end;
        Dias := Hasta - Desde;

        CompanyInfo.Get();
        JsonTask.Add('department', FijacionBatchDepartament);
        JsonTask.Add('expirationDate', ExpirationDate);
        JsonTask.Add('daysToPerform', Dias + 1);
        JsonTask.Add('description', Tarea.Title);
        JsonTask.Add('observation', Tarea.GetDescription());
        JsonTask.Add('service', FijacionBatchService);
        JsonTask.Add('category', FijacionBatchCategory);
        JsonTask.Add('project', JobNo);
        JsonTask.Add('user', responsable);
        JsonTask.Add('Id_Navision', CompanyInfo."Clave Recursos" + Format(Tarea.ID));
        JsonTask.Add('supervisor', Supervisor);
        JsonTask.Add('bc', true);
        if Tarea.fastPhoto then
            JsonTask.Add('fastPhoto', 'true');
        JsonTask.Add('owner', usuario);
        JsonTask.Add('priority', 'HIGH');

        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        Url := UrlCorrecta(Url);
        JsonTask.Add('link', Url);

        if Opcion = Opcion::Opi then begin
            JsonTask.Add('IdQr', Tarea.Resource);
            Tarea.IdQr := Tarea.Resource;
        end else begin
            if Retirada then begin
                JsonTask.Add('IdQr', Format(Tarea.OrdenFijacion) + '-R' + Format(Tarea.Reserva));
                Tarea.IdQr := Format(Tarea.OrdenFijacion) + '-' + Format(Tarea.Reserva);
            end else begin
                JsonTask.Add('IdQr', Format(Tarea.OrdenFijacion) + '-' + Format(Tarea.Reserva));
                Tarea.IdQr := Format(Tarea.OrdenFijacion) + '-' + Format(Tarea.Reserva);
            end;
        end;

        AgregarChecklistTareaAJsonObject(JsonTask, Tarea);
    end;

    local procedure ActualizarTareasFijacionDesdeRespuesta(JsonResp: Text)
    var
        JsonArrayResp: JsonArray;
        JsonToken: JsonToken;
        JsonTask: JsonObject;
        JDatoDetalleToken: JsonToken;
        UserTask: Record "User Task";
        Id: Text;
        idNium: Integer;
    begin
        if not JsonArrayResp.ReadFrom(JsonResp) then
            exit;

        foreach JsonToken in JsonArrayResp do begin
            JsonTask := JsonToken.AsObject();
            Clear(JDatoDetalleToken);
            if not JsonTask.Get('Id_Navision', JDatoDetalleToken) then
                continue;

            if not Evaluate(idNium, JDatoDetalleToken.AsValue().AsText()) then begin
                if StrLen(JDatoDetalleToken.AsValue().AsText()) < 2 then
                    idNium := 0
                else
                    Evaluate(idNium, CopyStr(JDatoDetalleToken.AsValue().AsText(), 3, StrLen(JDatoDetalleToken.AsValue().AsText())));
            end;

            Clear(JDatoDetalleToken);
            if not JsonTask.Get('_id', JDatoDetalleToken) then
                continue;
            Id := JDatoDetalleToken.AsValue().AsText();
            if (Id = '') or (idNium = 0) then
                continue;

            if UserTask.Get(idNium) then begin
                UserTask.Id_Tarea := Id;
                UserTask.Modify(false);
            end;
        end;
    end;

    local procedure ProcesarTareaFijacionPostEnvio(var OrdenFijacion: Record "Cab Orden fijación"; var Tarea: Record "User Task")
    var
        JobsSetup: Record "Jobs Setup";
        Job: Record Job;
        Customer: Record Customer;
    begin
        EnviarDocumentos(Tarea, Tarea.Id_Tarea);
        GetSetChat(Tarea, Tarea.Id_Tarea);
        JobsSetup.Get();
        if JobsSetup."Crear subtareas" then
            CrearSubTareaFijacion(OrdenFijacion, Tarea)
        else begin
            if not Job.Get(Tarea."Job No.") then
                Job.Init();
            if Customer.Get(Job."Bill-to Customer No.") then
                CreateParte(Tarea);
        end;
    end;

    local procedure ClaveProyectoFijacionCache(EmpresaTarea: Text; JobNo: Code[20]): Text
    begin
        exit(EmpresaTarea + '|' + JobNo);
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
        Url := UrlCorrecta(Url);
        JsonFormater.WriteStringProperty('link', Url);
        AgregarChecklistTareaAJson(JsonFormater, Tarea);
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
                        break;
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            Tarea.Id_Tarea := Id;
            Tarea.Modify();
        end;

        EnviarDocumentos(Tarea, Id);
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
                                if UpperCase(Value1) = UpperCase(Descripcion) then begin
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

    local procedure ObtenerLineasChecklistTarea(Tarea: Record "User Task"; var ChecklistTareaUsuario: Record "Checklist Tarea Usuario"): Boolean
    var
        Categoria: Code[20];
        ChecklistTareaUsuarioAux: Record "Checklist Tarea Usuario";
    begin
        if Tarea.ID = 0 then
            exit(false);

        Categoria := Tarea."User Task Group Assigned To";
        if Categoria = '' then
            Categoria := Tarea."Categoría";
        if Categoria = '' then
            exit(false);

        if not ChecklistTareaUsuarioAux.TieneChecklistTarea(Tarea.ID, Categoria) then
            exit(false);

        ChecklistTareaUsuario.Reset();
        ChecklistTareaUsuario.SetRange(Id, Tarea.ID);
        ChecklistTareaUsuario.SetRange("Categoría", Categoria);
        exit(ChecklistTareaUsuario.FindSet());
    end;

    procedure AgregarChecklistTareaAJson(var JsonFormater: Codeunit "Json Text Reader/Writer"; Tarea: Record "User Task")
    var
        ChecklistTareaUsuario: Record "Checklist Tarea Usuario";
    begin
        if not ObtenerLineasChecklistTarea(Tarea, ChecklistTareaUsuario) then
            exit;

        JsonFormater.WriteStartArray('checklist');
        repeat
            JsonFormater.WriteStartObject('');
            JsonFormater.WriteStringProperty('text', ChecklistTareaUsuario."Descripción");
            JsonFormater.WriteEndObject();
        until ChecklistTareaUsuario.Next() = 0;
        JsonFormater.WriteEndArray();
    end;

    procedure AgregarChecklistTareaAJsonObject(var JsonObjt: JsonObject; Tarea: Record "User Task")
    var
        ChecklistTareaUsuario: Record "Checklist Tarea Usuario";
        ChecklistArray: JsonArray;
        ChecklistItem: JsonObject;
    begin
        if not ObtenerLineasChecklistTarea(Tarea, ChecklistTareaUsuario) then
            exit;

        Clear(ChecklistArray);
        repeat
            Clear(ChecklistItem);
            ChecklistItem.Add('text', ChecklistTareaUsuario."Descripción");
            ChecklistArray.Add(ChecklistItem);
        until ChecklistTareaUsuario.Next() = 0;
        JsonObjt.Add('checklist', ChecklistArray);
    end;

    /// <summary>
    /// CrearTarea.
    /// </summary>
    /// <param name="Emplazamiento">VAR Record Resource.</param>
    /// <param name="Tarea">Record "User Task".</param>

    procedure CrearTareaTecnico(
        NoRecurso: Code[20];
        var Tarea: Record "User Task";
        Departament: Text; Service: Text; CreaParte: Boolean): Text[30]
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
        Emplazamientos: Record Emplazamientos;
        FileName: Text;
        TareaID: Integer;
        TareaTemp: Record "User Task";
        TareaNo: Code[20];
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        if Not Recurso.Get(NoRecurso) then Recurso.Init();
        CrearDepartamnetoyServicio(departament, service);
        If Recurso."No." <> '' Then Begin

            wRecordRef.Close();
            wRecordRef.Open(Database::Resource, false, CompanyName);
            If wRecordRef.Get(Recurso.RecordId) Then begin
                resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                if resource = 'Error' then begin
                    CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                    resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');

                end;

            end else begin
                //Creará la parada en Gtask
                //TODO
                // Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, NoRecurso);
                // wRecordRef.Close();
                // wRecordRef.Open(Database::"Emplazamientos", false, CompanyName);
                // wRecordRef.Get(Emplazamientos.RecordId);
                // resource := GetMaestro('emplazamiento', Emplazamientos."Descripción", 'name', wRecordRef, Database::"Emplazamientos", '');
                // if resource = 'Error' then begin
                //     CreaEmplazamiento(Emplazamientos, Emplazamientos.RecordId, Database::"Emplazamientos");
                //     resource := GetMaestro('emplazamiento', Emplazamientos."Descripción", 'name', wRecordRef, Database::"Emplazamientos", '');
                //end;


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
        If Not UserGtaskMalla.FindFirst() then begin
            UserGtaskMalla.SetRange("Id Usuario");
            IF NOT UserGtaskMalla.FindFirst() THEN
                Error('El usuario %1 no existe en Gtask o, no está enlazado', Tarea."Created by User Name");
        end;
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
        if Tarea.IdQr <> '' then
            JsonFormater.WriteStringProperty('IdQr', Tarea.IdQr);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        Url := UrlCorrecta(Url);
        JsonFormater.WriteStringProperty('link', Url);
        AgregarChecklistTareaAJson(JsonFormater, Tarea);
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
                        break;
                    end;
                end;
            end;
        end;
        if Id <> '' then begin
            TareaID := Tarea.ID;
            TareaNo := Tarea."No.";
            if TareaID <> 0 then begin
                TareaTemp.LockTable();
                TareaTemp.Reset();
                if TareaTemp.Get(TareaID) then begin
                    TareaTemp.Id_Tarea := Id;
                    TareaTemp.Modify(true);
                    Commit();
                end;
            end;
        end;
        EnviarDocumentos(Tarea, Id);
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
        exit(Id);
    end;

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
        Url := UrlCorrecta(Url);
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
                        break;
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
        Url := UrlCorrecta(Url);
        JsonFormater.WriteStringProperty('link', Url);
        AgregarChecklistTareaAJson(JsonFormater, Tarea);
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
                        break;
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

    internal procedure RecuperaId(Id: Text; Tabla: Integer; Company: Text): RecordId;
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
        If Recurso.Name = '' Then Recurso.Name := 'Sin Recurso';
        JsonFormater.WriteStringProperty('name', Recurso.Name);
        JsonFormater.WriteStringProperty('No', Recurso."No.");
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'resource', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        If Json = '' Then Exit;
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
    //https://gtasks-api.deploy.malla.es/INCIDENCE
    internal procedure DeleteIncidencia(Id_Incidencia: Text)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        jSon: Text;
        RequestType: Option Get,patch,put,post,delete;
        CompanyInfo: Record "Company Information";

    begin
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'incidence/' + Id_Incidencia, Token(), RequestType::delete, '');

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
        DocumentAttachment: Record "Document Attachment";
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
            Procesos_GTask.EnviaCorreo(Rec."No.", Rec.GetDescription(), true, '', false, 'Tarea Eliminada', EmailResponsable, EmailSupervisor, '', '', User."Full Name", true, Rec.Id_Tarea, false, true);
        end;
        DocumentAttachment.SetRange("Table ID", Database::"User Task");
        DocumentAttachment.SetRange("No.", Rec."No.");
        DocumentAttachment.Deleteall(true);
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

    internal procedure CloseTarea(Id: Integer

    )
    var
        UserTask: Record "User Task";
    begin
        if UserTask.Get(Id) then begin
            UserTask.Estado := UserTask.Estado::Finalizado;
            UserTask.Modify(true);
        end;
    end;

    internal procedure CrearTarea(
        RecRef: RecordRef;
        Descripcion: Text;
        Departamento: Text;
        Servicio: Text;
        Title: Text;
        Categoria: Text;
        Adjuntar: Boolean;
        Adjunto: Text;
        Extension: Text)
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
        Tipo: Integer;
        OutStream: OutStream;
        Base64: Codeunit "Base64 Convert";
        TimeSheetLine: Record "Time Sheet Line";
        DoccAttach2: Record "Document Attachment";
        Docuname2: Text;
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
        User.Get(UserSecurityId());
        Procesos_Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, Categoria, EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos);
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
                    FieldRef := RecRef.Field(Emplazamientos.FieldNo("Tipo Emplazamiento"));
                    Tipo := FieldRef.Value;
                    if Tipo = 1 then UserTask.Validate("Object ID", Page::"Ficha Parada Bus");
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
            Database::"Purchase Line":
                begin
                    UserTask.Validate("Object ID", Page::"Lineas Enviadas Taller");
                    UserTask.Id_record := RecRef.RecordId;



                end;
            Database::"Time Sheet Line":
                begin
                    TimeSheetLine.SetRange("Time Sheet No.", RecRef.Field(TimeSheetLine.FieldNo("Time Sheet No.")).Value);
                    TimeSheetLine.SetRange(Finalizada, false);
                    TimeSheetLine.SetRange(Enviada, false);
                    If TimeSheetLine.FindSet() then
                        repeat
                            DoccAttach.SetRange("Table ID", Database::"Time Sheet Line");
                            DoccAttach.SetRange("No.", TimeSheetLine."Job No.");
                            DoccAttach.SetRange("Line No.", TimeSheetLine."Job Line No.");
                            If DoccAttach.FindFirst() then
                                repeat
                                    DoccAttach2.SetRange("Table ID", Database::"User Task");
                                    DoccAttach2.SetRange("No.", Format(UserTask.Id));
                                    DoccAttach2.SetRange("Line No.", TimeSheetLine."Job Line No.");
                                    Docuname2 := DoccAttach."File Name";
                                    If DoccAttach."File Name".Contains('.jpg') then
                                        DoccAttach."File Name" := CopyStr(DoccAttach."File Name", 1, StrLen(DoccAttach."File Name") - 4);
                                    DoccAttach2.Setfilter("File Name", '%1', DoccAttach."File Name" + '*');
                                    If Not DoccAttach2.FindFirst() then begin
                                        DoccAttachNew := DoccAttach;
                                        If Docuname2 = '' Then Docuname2 := DoccAttach."File Name";
                                        DoccAttachnew."File Name" := Docuname2;
                                        DoccAttachnew."Table ID" := Database::"User Task";
                                        DoccAttachnew."No." := Format(UserTask.Id);
                                        DoccAttachNew.Insert(true);
                                    end;
                                until DoccAttach.Next() = 0;
                            DoccAttach.Reset();
                        until TimeSheetLine.Next() = 0;

                    If Categoria = 'TRABAJO' then
                        UserTask.Validate("Object ID", Page::"Partes de Trabajo Cart")
                    else
                        UserTask.Validate("Object ID", Page::"Cartelería Nacional");

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
        iF UserTask.EliminarTarea then begin
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
                iF UserTask.EliminarTarea then begin
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

        If Resource."No." = '' then
            Resource.Init();
        RecRef.Close();
        Clear(RecRef);
        If Adjuntar then begin
            RecRef.GetTable(Usertask);
            RecRef.Get(Usertask.RecordId);
            if StrLen(Adjunto) > 100 then begin
                TempBlob.CreateOutStream(OutStream);
                Base64.FromBase64(Adjunto, OutStream);
            end else
                FileMgt.BLOBImport(TempBlob, Adjunto);
            TempBlob.CreateInStream(InStr);
            DoccAttach.SaveAttachmentFromStream(InStr, RecRef, UserTask."No." + Extension);
            //DoccAttach.Insert();
            If tm.Delete() then;
        end;
        Gtask.CrearTareaTecnico(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
        Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false, true);
    end;

    internal procedure DupliCarTarea(
           Descripcion: Text;
           Departamento: Text;
           Servicio: Text;
           Title: Text;
           Categoria: Text;
           Adjuntar: Boolean;
           Adjunto: Text;
           Extension: Text;
           UserTaskOld: Record "User Task")
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
        Tipo: Integer;
        OutStream: OutStream;
        Base64: Codeunit "Base64 Convert";
        TimeSheetLine: Record "Time Sheet Line";
        DoccAttach2: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        Gtask.CrearCategorias(CompanyName);
        Commit();
        UserTask.Init();
        UserTask.Validate(Title, UserTaskOld.Title);

        UserTask.SetDescription(UserTaskOld.GetDescription());
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
        User.Get(UserSecurityId());
        Procesos_Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, Categoria, EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos);
        UserTask.Validate(Priority, Usertask.Priority::High);
        UserTask.Validate("Object Type", Usertask."Object Type"::Page);
        UserTask.Validate("Object ID", UserTaskOld."Object ID");
        UserTask.Id_record := UserTaskOld.Id_record;


        UserTask.Insert(true);
        // if not IsNullGuid(UserTask.Supervisor) then begin
        //     UserTask."Created By" := Supervisor;
        UserTask."No." := Format(UserTask.ID);
        UserTask.Modify();
        DoccAttach.SetRange("Table ID", Database::"User Task");
        DoccAttach.SetRange("No.", UserTaskOld."No.");
        if DoccAttach.FindFirst() then
            repeat
                DoccAttachNew := DoccAttach;
                DoccAttachnew."Table ID" := Database::"User Task";
                DoccAttachnew."No." := UserTask."No.";
                DoccAttachNew.Insert(true);
            until DoccAttach.Next() = 0;
        DoccAttach.Reset();

        //end;
        Commit();
        Page.RunModal(Page::"User Task Card", UserTask);
        iF UserTask.EliminarTarea then begin
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
                iF UserTask.EliminarTarea then begin
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

        If Resource."No." = '' then
            Resource.Init();
        If Adjuntar then begin
            RecRef.GetTable(Usertask);
            RecRef.Get(Usertask.RecordId);
            if StrLen(Adjunto) > 100 then begin
                TempBlob.CreateOutStream(OutStream);
                Base64.FromBase64(Adjunto, OutStream);
            end else
                FileMgt.BLOBImport(TempBlob, Adjunto);
            TempBlob.CreateInStream(InStr);
            DoccAttach.SaveAttachmentFromStream(InStr, RecRef, UserTask."No." + Extension);
            //DoccAttach.Insert();
            If tm.Delete() then;
        end;
        Gtask.CrearTareaTecnico(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
        Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false, true);
    end;


    procedure ActualizarVencimientoTarea(Tarea: Record "User Task")
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Json: Text;
    begin
        if (Tarea.Id_Tarea = '') or (Tarea."Due DateTime" = 0DT) then
            exit;
        CompanyInfo.Get();
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStartObject('expirationDate');
        JsonFormater.WriteStringProperty('date', Hora(Tarea."Due DateTime"));
        JsonFormater.WriteNullProperty('rule');
        JsonFormater.WriteBooleanProperty('custom', false);
        JsonFormater.WriteEndObject();
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tarea.Id_Tarea, Token(), RequestType::put, Json);
    end;

    internal procedure CrearTareaEmpazamiento(
       RecRef: RecordRef;
       Title: Text;
       Responsable: Guid;
       Supervisor: Guid;
       Depatamento: code[20];
       Servicio: code[20];
       Adjuntar: Boolean;
       Adjunto: Text; Categoria: code[20])
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
        If Categoria <> '' then
            UserTask."User Task Group Assigned To" := Categoria;
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
        If Categoria <> '' then
            UserTask."User Task Group Assigned To" := Categoria;
        if Categoria <> '' then
            UserTask."Categoría" := Categoria;
        UserTask.Estado := UserTask.Estado::Pendiente;
        UserTask."No." := Format(UserTask.ID);
        UserTask.Modify();
        //end;
        Commit();
        UserTaskCard.SetRecord(UserTask);
        UserTaskCard.RunModal();
        iF UserTask.EliminarTarea then begin
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
                iF UserTask.EliminarTarea then begin
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
        Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false, true);
    end;


    internal procedure CrearTareaLimpieza(
           TipoTarea: Text;
           RecRef: RecordRef;
           Title: Text;
           ZonaLimpieza: Integer;
           Descripcion: Text;
           Adjuntar: Boolean;
           Adjunto: Text; Fecha: Date; EsPeriodica: Boolean; TareaAnterior: Integer): Boolean
    var

        Responsable: Guid;
        Supervisor: Guid;
        ResponsableOld: Guid;
        SupervisorOld: Guid;
        DepartamentoOld: Text;
        ServicioOld: Text;
        CategoriaOld: Text;
        EmailResponsableOld: Text[250];
        EmailSupervisorOld: Text[250];
        Servicio: Text;
        Categoria: Text;
        Departamento: Text;
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
        JobSetup: Record "Jobs Setup";
        UserTaskOld: Record "User Task";
        FechaTarea: Date;
        HoraInicio: Time;
        HoraFin: Time;

    //Operario: Guid;
    begin

        Gtask.CrearCategorias(CompanyName);
        Commit();
        JobSetup.Get();
        if TareaAnterior <> 0 then begin
            UserTaskOld.Get(TareaAnterior);
            // Al crear dependencia desde tarea finalizada, reutilizar responsable/supervisor/categoría de la tarea anterior
            // para no depender de DevuelveCategoriaSupervisorResponsablePorZona (puede hacer Error si la zona no tiene categoría configurada)
            ResponsableOld := UserTaskOld."Assigned To";
            SupervisorOld := UserTaskOld.Supervisor;
            DepartamentoOld := UserTaskOld.Departamento;
            ServicioOld := UserTaskOld.Servicio;
            CategoriaOld := UserTaskOld."User Task Group Assigned To";
            if not IsNullGuid(ResponsableOld) then begin
                User.SetRange("User Security ID", ResponsableOld);
                if User.FindFirst() then
                    EmailResponsableOld := User."Contact Email";
            end;
            if not IsNullGuid(SupervisorOld) then begin
                User.SetRange("User Security ID", SupervisorOld);
                if User.FindFirst() then
                    EmailSupervisorOld := User."Contact Email";
            end;
        end;
        UserTask.Init();
        UserTask.Validate(Title, Title);
        UserTask.SetDescription(Descripcion);

        // If not IsNullGuid(UserTask.Supervisor) then
        //     UserTask."Created By" := UserTask.Supervisor
        // else
        UserTask."Created By" := ResponsableOld;
        if TareaAnterior <> 0 then begin
            // Dependencia: usar responsable/supervisor/categoría de la tarea anterior (evita Error si la zona no tiene categoría en Gtask)
            Responsable := ResponsableOld;
            Supervisor := SupervisorOld;
            Categoria := CategoriaOld;
            Departamento := DepartamentoOld;
            Servicio := ServicioOld;
            EmailResponsable := EmailResponsableOld;
            EmailSupervisor := EmailSupervisorOld;
        end else
            Procesos_GTask.DevuelveCategoriaSupervisorResponsablePorZona(TipoTarea, ZonaLimpieza, Responsable, Supervisor, Categoria, Departamento,
        Servicio, EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos, RecRef);
        UserTask."Assigned To" := Responsable;
        UserTask."Supervisor" := Supervisor;
        UserTask.Departamento := Departamento;
        UserTask.Servicio := Servicio;
        UserTask."User Task Group Assigned To" := Categoria;
        UserTask.EsPeriodica := EsPeriodica;
        UserTask.ZonaLimpieza := ZonaLimpieza;
        UserTask.TipoTarea := TipoTarea;
        AsignarObjetivoDesdeRegistro(UserTask, ZonaLimpieza, RecRef);
        UserTask.Validate("Created DateTime", CurrentDateTime);
        Usertask."Start DateTime" := CreateDateTime(Fecha, 080000T);
        Usertask."Due DateTime" := CreateDateTime(Fecha, 130000T);
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
                    UserTask.Validate("Object ID", Page::"Ficha Parada Bus");
                    UserTask.Id_record := RecRef.RecordId;
                    Resource.SetRange("Nº Emplazamiento", RecRef.Field(Emplazamientos.FieldNo("Nº Emplazamiento")).Value);
                end;

        end;

        UserTask.Insert(true);
        // if not IsNullGuid(UserTask.Supervisor) then begin
        //     UserTask."Created By" := Supervisor;
        UserTask."No." := Format(UserTask.ID);
        UserTask.IdQr := 'L_' + UserTask."No.";
        UserTask.Modify();
        Commit();

        UserTask.Get(UserTask.ID);
        //UserTask."Assigned To" := Operario;
        If (IsNullGuid(UserTask."Supervisor")) or (IsNullGuid(UserTask."Assigned To"))
        or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
        or (UserTask.Servicio = '') Then begin
            if TareaAnterior <> 0 then begin
                UserTask.Supervisor := SupervisorOld;
                UserTask."Assigned To" := ResponsableOld;
                UserTask.Departamento := DepartamentoOld;
                UserTask.Servicio := ServicioOld;
                UserTask."User Task Group Assigned To" := CategoriaOld;
                UserTask.Modify();
            end else begin
                UserTask.Delete();
                exit(False);
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
        if Not JobSetup."Es Debug" then begin
            FechaTarea := DT2Date(UserTask."Start DateTime");
            HoraInicio := DT2Time(UserTask."Start DateTime");
            HoraFin := DT2Time(UserTask."Due DateTime");
            Gtask.CrearTareaTecnico(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
            UserTask.Get(UserTask.ID);
            UserTask."Start DateTime" := CreateDateTime(FechaTarea, HoraInicio);
            UserTask."Due DateTime" := CreateDateTime(FechaTarea, HoraFin);
            UserTask.Modify(true);
            Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
            Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false, true);
        end;
        exit(True);
    end;

    local procedure AsignarObjetivoDesdeRegistro(var UserTask: Record "User Task"; IdZona: Integer; RecRef: RecordRef)
    var
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
    begin
        if IdZona = 0 then
            exit;
        case RecRef.Number of
            Database::Emplazamientos:
                begin
                    RecRef.SetTable(Emplaz);
                    AsignarObjetivoEmplazamiento(UserTask, Emplaz, IdZona);
                end;
            Database::Resource:
                begin
                    RecRef.SetTable(Resource);
                    AsignarObjetivoRecurso(UserTask, Resource, IdZona);
                end;
        end;
    end;

    local procedure AsignarObjetivoEmplazamiento(var UserTask: Record "User Task"; Emplaz: Record Emplazamientos; IdZona: Integer)
    begin
        if Emplaz."Zona Limpieza a Presión" = IdZona then
            FijarObjetivoTarea(UserTask, 5, Emplaz."Veces Limpieza a Presión", Emplaz."Periodo Limpieza a Presión")
        else if Emplaz."Zona Techos" = IdZona then
            FijarObjetivoTarea(UserTask, 4, Emplaz."Veces Techos", Emplaz."Periodo Techos")
        else if Emplaz."Zona Mantenimiento" = IdZona then
            FijarObjetivoTarea(UserTask, 3, Emplaz."Veces Mantenimiento", Emplaz."Periodo Mantenimiento")
        else if Emplaz."Zona Revisión" = IdZona then
            FijarObjetivoTarea(UserTask, 2, Emplaz."Veces Revisión", Emplaz."Periodo Revisión")
        else if Emplaz."Zona Limpieza" = IdZona then
            FijarObjetivoTarea(UserTask, 1, Emplaz."Veces Limpieza", Emplaz."Periodo Limpieza");
    end;

    local procedure AsignarObjetivoRecurso(var UserTask: Record "User Task"; Resource: Record Resource; IdZona: Integer)
    begin
        if Resource."Zona Limpieza a Presión" = IdZona then
            FijarObjetivoTarea(UserTask, 5, Resource."Veces Limpieza a Presión", Resource."Periodo Limpieza a Presión")
        else if Resource."Zona Techos" = IdZona then
            FijarObjetivoTarea(UserTask, 4, Resource."Veces Techos", Resource."Periodo Techos")
        else if Resource."Zona Mantenimiento" = IdZona then
            FijarObjetivoTarea(UserTask, 3, Resource."Veces Mantenimiento", Resource."Periodo Mantenimiento")
        else if Resource."Zona Revisión" = IdZona then
            FijarObjetivoTarea(UserTask, 2, Resource."Veces Revisión", Resource."Periodo Revisión")
        else if Resource."Zona Limpieza" = IdZona then
            FijarObjetivoTarea(UserTask, 1, Resource."Veces Limpieza", Resource."Periodo Limpieza");
    end;

    local procedure FijarObjetivoTarea(var UserTask: Record "User Task"; Tipo: Integer; Veces: Integer; Periodo: Integer)
    begin
        UserTask."Veces objetivo" := Veces;
        case Tipo of
            1:
                UserTask."Tipo objetivo" := UserTask."Tipo objetivo"::Limpieza;
            2:
                UserTask."Tipo objetivo" := UserTask."Tipo objetivo"::"Revisión";
            3:
                UserTask."Tipo objetivo" := UserTask."Tipo objetivo"::Mantenimiento;
            4:
                UserTask."Tipo objetivo" := UserTask."Tipo objetivo"::"Limpieza techos";
            5:
                UserTask."Tipo objetivo" := UserTask."Tipo objetivo"::"Limpieza a presión";
        end;
        case Periodo of
            1:
                UserTask."Periodo objetivo" := UserTask."Periodo objetivo"::Semana;
            2:
                UserTask."Periodo objetivo" := UserTask."Periodo objetivo"::Mes;
            3:
                UserTask."Periodo objetivo" := UserTask."Periodo objetivo"::Año;
            else
                UserTask."Periodo objetivo" := UserTask."Periodo objetivo"::" ";
        end;
    end;

    /// <param name="CodigoEmplazamiento">Código del emplazamiento</param>
    /// <param name="CodigoCategoria">Código de la categoría de tarea</param>
    /// <param name="Fecha">Fecha para la tarea (opcional, por defecto WorkDate)</param>
    /// <returns>True si la tarea se creó correctamente, False si ya existía</returns>
    procedure CrearTareaRevision(CodigoEmplazamiento: Code[20]; CodigoCategoria: Code[20]; Fecha: Date): Boolean
    var
        Emplazamientos: Record Emplazamientos;
        UserTask: Record "User Task";
        Categorias: Record "User Task Group";
        RecRef: RecordRef;
        Gtask: Codeunit Gtask;
        ZonasLimpieza: Record "Zonas Limpieza";
        FechaTarea: Date;
        Periodicidad: DateFormula;
    begin
        // Validar que la categoría existe
        If not Categorias.Get(CodigoCategoria) then
            Error('No se ha encontrado la categoría %1', CodigoCategoria);

        // Validar que el emplazamiento existe
        If not Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, CodigoEmplazamiento) then
            Error('No se ha encontrado el emplazamiento %1', CodigoEmplazamiento);

        // Verificar que no exista ya una tarea para este emplazamiento y categoría
        UserTask.SetRange(Id_record, Emplazamientos.RecordId);
        UserTask.SetRange("User Task Group Assigned To", CodigoCategoria);
        If UserTask.FindFirst() then
            exit(false); // Ya existe la tarea

        // Obtener fecha, si no se proporciona usar WorkDate
        If Fecha = 0D then
            FechaTarea := WorkDate()
        else
            FechaTarea := Fecha;

        // Obtener información de zona de limpieza si existe
        RecRef.GetTable(Emplazamientos);

        // Crear la tarea usando el procedimiento interno para revisión
        CrearTareaLimpieza('REVISION', RecRef,
            Categorias.Description + ' ' + CodigoEmplazamiento,
            Emplazamientos."Zona Limpieza",
            'Tarea de ' + Categorias.Description + ' para el emplazamiento OPI ' + CodigoEmplazamiento +
            ' - ' + Emplazamientos."Descripción",
            false,
            '',
            FechaTarea,
            true, 0);

        exit(true);
    end;



    procedure GetTipoIncidencia(Tipo: Text): Text
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
        IdCategoria: Text;
        wRecordRef: RecordRef;
        Categoria: record "User Task Group";
    begin
        CompanyInfo.Get();
        Clear(RestApi);
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'incidenceType', Token(), RequestType::Get, '');
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
                                If Value1 = Tipo Then Exit(Id);



                            end;
                    end;

                end;
            end;
            i += 1;
        end;

        wRecordRef.Close();
        wRecordRef.Open(Database::"User Task Group", false, CompanyName);
        Categoria.Get('MTO');
        wRecordRef.GetTable(Categoria);
        IdCategoria := GetMaestro('category', 'MTO', 'name', wRecordRef, Database::"User Task Group", 'Malla Publicidad');
        //     {
        // "category": "65a1b2c3d4e5f6789012346",
        // "description": "Descripción del tipo de incidencia",
        // "name": "Nombre del tipo"
        //     }
        Clear(JsonObjt);
        clear(RestApi);
        JsonObjt.WriteStartObject('');
        JsonObjt.WriteStringProperty('category', IdCategoria);
        JsonObjt.WriteStringProperty('description', Tipo);
        JsonObjt.WriteStringProperty('name', Tipo);
        JsonObjt.WriteEndObject();
        Json := JsonObjt.GetJSonAsText();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'incidenceType', Token(), RequestType::post, Json);
        If Json <> '' then begin
            JSONMgt.InitializeObject(Json);
            JSONMgt.ReadProperties();
            while JSONMgt.GetNextProperty(Name, Value1) do begin
                if Name = '_id' then
                    exit(Value1);
            end;
        end;
        Exit('');
    end;

    internal procedure CreateIncidencia(var rDet: Record Incidencias)
    var
        JsonFormater: Codeunit "Json Text Reader/Writer";
        Json: Text;
        CompanyInfo: Record "Company Information";
        RestApi: Codeunit "Control Ocr";
        RequestType: Option Get,patch,put,post,delete;
        JSONMgt: Codeunit "JSON Management";
        Name: Text;
        Value1: Text;
        Id: Text;
        Imagenes: Record "Imagenes Orden fijación";
        Recurso: Record Resource;
        wRecordRef: RecordRef;
        resource: Text;
        Control: Codeunit "ControlProcesos";
    begin
        //{
        // "state": "PENDING",
        // "incidenceType": "65a1b2c3d4e5f6789012345",
        // "observation": "Observación adicional",
        // "description": "Descripción de la incidencia",
        // "resource": "65a1b2c3d4e5f6789012348",
        // "image": [
        // {
        // "file": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
        // "name": "imagen1.jpg"
        // },
        // {
        // "file": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgA...",
        // "name": "imagen2.png"
        // }
        // ]
        // }
        CompanyInfo.Get();
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStringProperty('state', 'PENDING');
        JsonFormater.WriteStringProperty('incidenceType', GetTipoIncidencia(Format(rDet."Tipo Incidencia")));
        JsonFormater.WriteStringProperty('observation', '');
        JsonFormater.WriteStringProperty('description', rDet."Descripción");
        If Recurso.Get(rDet."Recurso") then begin
            wRecordRef.Close();
            wRecordRef.Open(Database::Resource, false, CompanyName);
            wRecordRef.Get(Recurso.RecordId);
            resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
            if resource = 'Error' then begin
                CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
            end;
        end;
        if resource <> '' then
            JsonFormater.WriteStringProperty('resource', resource);
        Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
        Imagenes.SetRange("Es Incidencia", true);
        If Imagenes.FindSet() Then begin
            JsonFormater.WriteStartArray('image');
            repeat
                JsonFormater.WriteStartObject('');

                if Imagenes.Id <> 0 then begin
                    JsonFormater.WriteStringProperty('_id', Imagenes.Id);
                    JsonFormater.WriteStringProperty('url', Imagenes.Url);
                end else
#If CLEAN27
                JsonFormater.WriteStringProperty('file', Control.ToBase64StringOcr(Imagenes.Url));
#else
                JsonFormater.WriteStringProperty('file', Imagenes.ToBase64StringOcr(Imagenes.Url));
#endif
                JsonFormater.WriteStringProperty('name', Imagenes.Nombre);
                JsonFormater.WriteEndObject();
            until Imagenes.Next() = 0;
            JsonFormater.WriteEndArray();
        end;
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        Clear(RestApi);
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'incidence', Token(), RequestType::post, Json);
        If Json <> '' then begin
            JSONMgt.InitializeObject(Json);
            JSONMgt.ReadProperties();
            while JSONMgt.GetNextProperty(Name, Value1) do begin
                if Name = '_id' then
                    Id := Value1;
            end;
        end;
        if Id <> '' then
            rDet.Id_Gtask := Id;
        rDet.Modify();

    end;

    internal procedure CrearDepartamnetoyServicio(var departament: Text; var service: Text)
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


    procedure AdImagenValla(var DocumentAttachment: Record "Document Attachment"; Empresa: Text)
    var
        ImagenValla: Record "Imagenes Orden fijación";
        DetOrden: Record "Orden fijación";
        LineNo: Integer;
    begin
        If Strpos(DocumentAttachment."File Name", '.pdf') <> 0 Then exit;
        If DocumentAttachment."File Extension" = 'PDF' then exit;
        //si las 4 ultimas letras de la url son .pdf then exit
        If CopyStr(DocumentAttachment.Url, StrLen(DocumentAttachment.Url) - 3, 4) = '.pdf' then exit;
        If Empresa <> '' then
            DetOrden.ChangeCompany(Empresa);
        If DetOrden.Get(DocumentAttachment.ID_Doc, DocumentAttachment."Line No.")
        then begin
            LineNo := 0;
            If DetOrden."Imagen Valla Fijada" = 0 Then begin
                If Empresa <> '' then
                    ImagenValla.ChangeCompany(Empresa);
                ImagenValla.SetRange("Nº Orden", DetOrden."Nº Orden");
                If ImagenValla.FindLast() Then LineNo := ImagenValla."Nº Imagen";
                LineNo += 1;
                ImagenValla.Init();
                ImagenValla."Es Incidencia" := false;
                ImagenValla."Valla Fijada" := true;
                ImagenValla."Nº Imagen" := LineNo;
                DetOrden."Imagen Valla Fijada" := LineNo;
                ImagenValla."Nº Orden" := DetOrden."Nº Orden";
                ImagenValla."Es Qr" := false;
                ImagenValla.Nombre := DocumentAttachment."File Name";
                ImagenValla.Url := DocumentAttachment.Url;
                ImagenValla.Id := DocumentAttachment.ID_Url;
                If ImagenValla.Nombre <> '' then
                    ImagenValla.Insert();
                DetOrden.Modify;
            end;
        end;
    end;

    internal procedure Hora(Datetime: DateTime): Text
    var
        Hora: Time;
    begin
        Hora := DT2Time(Datetime);
        if hora < 095959T then
            exit(Format("DateTime", 0, '<Year4>-<Month,2>-<Day,2>T0<Hours24>:<Minutes,2>:<Seconds,2>'))
        else
            exit(Format("DateTime", 0, '<Year4>-<Month,2>-<Day,2>T<Hours24>:<Minutes,2>:<Seconds,2>'));
    end;

    procedure UrlCorrecta(Url: Text): Text
    begin
        if StrPos(Url, 'http://NAV-MALLA01:48900') > 0 then
            exit('https://bc270.malla.es/' + CopyStr(Url, 26));
        if StrPos(Url, 'http://nav-malla01:48900/') > 0 then
            exit('https://bc270.malla.es/' + CopyStr(Url, 26));
        exit(Url);
    end;

    /// <summary>
    /// Aplica expirationDate y daysToPerform devueltos por GTask sin desplazar un día la fecha de inicio
    /// ni sobrescribir la hora de inicio (p. ej. limpieza 08:00–13:00 el mismo día).
    /// BC envía daysToPerform = (Due - Start) + 1; 1 = mismo día calendario.
    /// </summary>
    local procedure AplicarFechasDesdeGtaskJson(var Tareas: Record "User Task"; var JsonTarea: JsonObject)
    var
        JsonCampo: JsonToken;
        JsonDetalleCampo: JsonObject;
    begin
        if JsonTarea.Get('expirationDate', JsonCampo) then begin
            JsonDetalleCampo := JsonCampo.AsObject();
            if JsonDetalleCampo.Get('date', JsonCampo) then
                AplicarExpirationDateDesdeGtask(Tareas, JsonCampo);
        end;
        if JsonTarea.Get('daysToPerform', JsonCampo) then
            AplicarDaysToPerformDesdeGtask(Tareas, JsonCampo.AsValue().AsText());
    end;

    local procedure AplicarExpirationDateDesdeGtask(var Tareas: Record "User Task"; JsonFecha: JsonToken)
    var
        NuevaDue: DateTime;
        HoraDue: Time;
        FechaDue: Date;
    begin
        NuevaDue := JsonFecha.AsValue().AsDateTime();
        FechaDue := DT2Date(NuevaDue);
        if FechaDue = 0D then
            exit;
        HoraDue := DT2Time(Tareas."Due DateTime");
        if HoraDue = 0T then
            HoraDue := DT2Time(NuevaDue);
        Tareas."Due DateTime" := CreateDateTime(FechaDue, HoraDue);
    end;

    local procedure AplicarDaysToPerformDesdeGtask(var Tareas: Record "User Task"; DaysToPerformTxt: Text)
    var
        Hasta: Date;
        Desde: Date;
        DiasPerform: Integer;
        HoraInicio: Time;
    begin
        if CopyStr(DaysToPerformTxt, 1, 1) = '-' then begin
            Hasta := DT2Date(Tareas."Due DateTime");
            if Hasta = 0D then
                exit;
            Desde := CalcDate('0D', Hasta);
        end else begin
            if not Evaluate(DiasPerform, DaysToPerformTxt) then
                exit;
            if DiasPerform <= 0 then
                exit;
            Hasta := DT2Date(Tareas."Due DateTime");
            if Hasta = 0D then
                exit;
            if DiasPerform = 1 then
                Desde := Hasta
            else
                Desde := CalcDate(StrSubstNo('<-%1D>', DiasPerform - 1), Hasta);
        end;
        HoraInicio := DT2Time(Tareas."Start DateTime");
        if HoraInicio = 0T then
            HoraInicio := 080000T;
        Tareas."Start DateTime" := CreateDateTime(Desde, HoraInicio);
    end;


    local procedure CrearTareaIncidencia(var rDet: Record Incidencias): Text
    var
        UserTask: Record "User Task";
        User: Record User;
        Gtask: Codeunit Gtask;
        EmailResponsable: Text[250];
        EmailSupervisor: Text[250];
        TipoIncidencia: Record "User Task Group";
        TM: Record "Tenant Media";
        InStr: Instream;
        DoccAttach: Record "Document Attachment";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ListadeCorreos: Text;
        UserTaskCard: Page "User Task Card";
        Empleado: Guid;
        UserTaskGroup: Record "User Task Group Member";
        RecRef: RecordRef;
        Resource: Record Resource;
        Emplazamientos: Record Emplazamientos;
        Imagenes: Record "Imagenes Orden fijación";
        Id_Task: Text;
        IdDoc: Integer;
    begin
        Gtask.CrearCategorias(CompanyName);
        Commit();
        UserTask.Init();
        UserTask.Validate(Title, rDet."Descripción");
        UserTask.SetDescription(rDet.GetWorkDescription());
        // Object Type antes que Object ID; asignación directa (Validate fuerza AllObj).
        UserTask."Object Type" := UserTask."Object Type"::Page;

        If rDet."Tipo Elemento" = rDet."Tipo Elemento"::Recurso then begin
            If Resource.Get(rDet.Recurso) then begin
                UserTask."Object ID" := Page::"Resource Card";
                UserTask.Id_record := Resource.RecordId;
                Resource.SetRange("No.", Resource."No.");
                RecRef.GetTable(Resource);
                RecRef.Get(Resource.RecordId);
            end;

        end else begin
            If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, rDet.Recurso) then begin
                UserTask."Object ID" := Page::"Ficha Parada Bus";
                UserTask.Id_record := Emplazamientos.RecordId;
                Resource.SetRange("Nº Emplazamiento", Emplazamientos."Nº Emplazamiento");
                RecRef.GetTable(Emplazamientos);
                RecRef.Get(Emplazamientos.RecordId);

            end;
            If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Vallas, rDet.Recurso) then begin
                UserTask."Object ID" := Page::"Ficha emplazamiento";
                UserTask.Id_record := Emplazamientos.RecordId;
                Resource.SetRange("Nº Emplazamiento", Emplazamientos."Nº Emplazamiento");
                RecRef.GetTable(Emplazamientos);
                RecRef.Get(Emplazamientos.RecordId);

            end;
        end;

        if rDet."SubTipo Incidencia" = rDet."SubTipo Incidencia"::Mantenimiento then begin
            AsegurarFechaProximoMantenimientoDesdeZona(Emplazamientos, Resource);
            if not AsignarResponsablesTareaMantenimiento(rDet, UserTask, RecRef, EmailResponsable, EmailSupervisor, ListadeCorreos) then begin
                if IsNullGuid(rDet."Usuario Asignado") = false then
                    UserTask."Assigned To" := rDet."Usuario Asignado"
                else
                    UserTask."Assigned To" := rDet.Usuario;
                If rDet."User Task Group" <> '' then
                    UserTask."User Task Group Assigned To" := rDet."User Task Group"
                else
                    UserTask."User Task Group Assigned To" := 'MTO';

                UserTaskGroup.SetRange("User Task Group Code", UserTask."User Task Group Assigned To");
                UserTaskGroup.SetRange(Supervisor, true);
                UserTask.Servicio := 'TALLER';
                If UserTaskGroup.FindFirst() then begin
                    UserTask."Supervisor" := UserTaskGroup."User Security ID";
                    UserTask.Departamento := UserTaskGroup.Departamento;

                end else
                    UserTask."Supervisor" := rDet."Usuario";
            end;
        end else begin
            if IsNullGuid(rDet."Usuario Asignado") = false then
                UserTask."Assigned To" := rDet."Usuario Asignado"
            else
                UserTask."Assigned To" := rDet.Usuario;
            If rDet."User Task Group" <> '' then
                UserTask."User Task Group Assigned To" := rDet."User Task Group"
            else
                UserTask."User Task Group Assigned To" := 'MTO';

            UserTaskGroup.SetRange("User Task Group Code", UserTask."User Task Group Assigned To");
            UserTaskGroup.SetRange(Supervisor, true);
            UserTask.Servicio := 'TALLER';
            If UserTaskGroup.FindFirst() then begin
                UserTask."Supervisor" := UserTaskGroup."User Security ID";
                UserTask.Departamento := UserTaskGroup.Departamento;

            end else
                UserTask."Supervisor" := rDet."Usuario";
        end;
        AsignarCreadorTareaMantenimiento(UserTask);
        UserTask.Validate("Created DateTime", CurrentDateTime);
        Usertask."Start DateTime" := rDet.FechaHora;
        Usertask."Due DateTime" := rDet.FechaHora;
        UserTask.Validate(Priority, Usertask.Priority::High);
        // Insert(false): evita revalidar Object ID contra AllObj (ya asignado arriba).
        UserTask.Insert(false);
        UserTask.Get(UserTask.ID);
        // if not IsNullGuid(UserTask.Supervisor) then begin
        //     UserTask."Created By" := Supervisor;
        UserTask."No." := Format(UserTask.ID);

        if IdQrOrdenTrabajo(rDet) <> '' then
            UserTask.IdQr := IdQrOrdenTrabajo(rDet)
        else
            UserTask.IdQr := rDet.Id_Gtask;
        UserTask.TestField(IdQr);
        AsignarCreadorTareaMantenimiento(UserTask);
        //Traspasa las fotos
        Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
        Imagenes.SetRange("Es Incidencia", true);
        DoccAttach.SetRange("Table ID", Database::"User Task");
        DoccAttach.SetRange("No.", UserTask."No.");
        If DoccAttach.FindLast() then
            IdDoc := DoccAttach.Id
        else
            IdDoc := 0;
        If Imagenes.FindSet() then begin
            repeat
                //Creamos Document Attachment i copiamos url
                IdDoc += 1;
                DoccAttach.Init();
                DoccAttach.Id := IdDoc;
                DoccAttach."Table ID" := Database::"User Task";
                DoccAttach."No." := UserTask."No.";
                DoccAttach."Line No." := 0;
                DoccAttach."File Name" := Imagenes.Nombre;
                DoccAttach."URL" := Imagenes.Url;
                DoccAttach.ID_Url := Imagenes.Id;
                If DoccAttach."File Name" <> '' Then
                    If DoccAttach.Insert() Then;
            until Imagenes.Next() = 0;
            Imagenes.SetRange(Nombre, '');
            Imagenes.DeleteAll();

        end;
        if rDet."SubTipo Incidencia" <> rDet."SubTipo Incidencia"::Mantenimiento then begin
            If rDet."User Task Group" <> '' then
                UserTask."User Task Group Assigned To" := rDet."User Task Group"
            else
                UserTask."User Task Group Assigned To" := 'MTO';

            if IsNullGuid(rDet."Usuario Asignado") = false then
                Empleado := rDet."Usuario Asignado"
            else
                Empleado := rDet.Usuario;
            if not IsNullGuid(Empleado) then
                UserTask."Assigned To" := Empleado;
        end;
        if IsNullGuid(UserTask."Assigned To") then
            UserTask."Assigned To" := UserTask.Supervisor;

        // Modify(false): coherente con Insert(false); no revalida Object ID/AllObj.
        UserTask.Modify(false);
        //end;
        Commit();
        UserTask.Get(UserTask.ID);
        //TODO: Cambiar a la categoría de la incidencia
        If (IsNullGuid(UserTask."Supervisor")) or (IsNullGuid(UserTask."Assigned To"))
        or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
        or (UserTask.Servicio = '') or (UserTask.IdQr = '') Then begin

            UserTask.Delete();
            Commit();
            Exit('Error: No ha completado los campos');
        end;
        If rDet."Tipo Elemento" = rDet."Tipo Elemento"::Parada then begin
            Id_Task := CrearTareaIncidencia(Emplazamientos."Nº Emplazamiento", UserTask, UserTask.Departamento, UserTask.Servicio, true);
        end else begin
            Id_Task := CrearTareaIncidencia(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
        end;
        rDet."Id_Tarea" := UserTask.ID;
        if rDet."Fecha Actuacion" = 0DT then
            rDet."Fecha Actuacion" := CurrentDateTime();
        rDet.Modify();
        Commit();
        EnviarCorreoBak(UserTask, rDet."Descripción");
        If Strlen(Id_Task) > 30 then exit(Id_Task);
        rDet.Get(rDet."No.");
        rDet."Id Tarea Gtask" := Id_Task;
        if rDet."Fecha Actuacion" = 0DT Then rDet."Fecha Actuacion" := CurrentDateTime();
        rDet.Modify();
        exit(Id_Task);
    end;

    procedure CrearTareaIncidencia(
    NoRecurso: Code[20];
    var Tarea: Record "User Task";
    Departament: Text; Service: Text; CreaParte: Boolean): Text
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
        Emplazamientos: Record Emplazamientos;
        FileName: Text;
        TareaID: Integer;
        TareaTemp: Record "User Task";
        TareaNo: Code[20];
        Empresa: Text;
    begin
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        If Empresa = '' Then Empresa := CompanyName;
        Recurso.ChangeCompany(Empresa);
        if Not Recurso.Get(NoRecurso) then Recurso.Init();
        CrearDepartamnetoyServicio(departament, service);
        If Recurso."No." <> '' Then Begin

            wRecordRef.Close();
            wRecordRef.Open(Database::Resource, false, Empresa);
            If wRecordRef.Get(Recurso.RecordId) Then begin
                resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');
                if resource = 'Error' then begin
                    CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                    resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, '');

                end;

            end else begin
                //Creará la parada en Gtask
                //TODO
                // Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, NoRecurso);
                // wRecordRef.Close();
                // wRecordRef.Open(Database::"Emplazamientos", false, CompanyName);
                // wRecordRef.Get(Emplazamientos.RecordId);
                // resource := GetMaestro('emplazamiento', Emplazamientos."Descripción", 'name', wRecordRef, Database::"Emplazamientos", '');
                // if resource = 'Error' then begin
                //     CreaEmplazamiento(Emplazamientos, Emplazamientos.RecordId, Database::"Emplazamientos");
                //     resource := GetMaestro('emplazamiento', Emplazamientos."Descripción", 'name', wRecordRef, Database::"Emplazamientos", '');
                //end;


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
        if Tarea.IdQr <> '' then
            JsonFormater.WriteStringProperty('IdQr', Tarea.IdQr);
        JsonFormater.WriteStringProperty('priority', 'HIGH');
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        Url := UrlCorrecta(Url);
        JsonFormater.WriteStringProperty('link', Url);
        AgregarChecklistTareaAJson(JsonFormater, Tarea);
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
                        break;
                    end;
                end;
            end;
        end;
        if StrLen(Id) > 30 then Error(Id);
        if Id <> '' then begin
            TareaID := Tarea.ID;
            TareaNo := Tarea."No.";
            if TareaID <> 0 then begin
                TareaTemp.LockTable();
                TareaTemp.Reset();
                if TareaTemp.Get(TareaID) then begin
                    TareaTemp.Id_Tarea := Id;
                    TareaTemp.Modify(true);
                    Commit();
                end;
            end;
        end;

        EnviarDocumentos(Tarea, Id);
        If not Job.Get(Tarea."Job No.") then Job.Init;
        exit(Id);
    end;





    procedure ModifyTareaIncidencia(rDet: Record Incidencias)
    var
        UserTask: Record "User Task";
        Gtask: Codeunit Gtask;
        EmailResponsable: Text[250];
        EmailSupervisor: Text[250];
        ListadeCorreos: Text;
        UserTaskCard: Page "User Task Card";
        Operario: Guid;
        UserTaskGroup: Record "User Task Group Member";
        RecRef: RecordRef;
        Resource: Record Resource;
        Emplazamientos: Record Emplazamientos;
        Imagenes: Record "Imagenes Orden fijación";
        Id_Task: Text[30];
        IdDoc: Integer;
    begin
        If rDet."Id_Tarea" = 0 then begin
            UserTask.SetRange(Id_Tarea, rDet."Id Tarea Gtask");
            If UserTask.FindFirst() then begin
                rDet."Id_Tarea" := UserTask.ID;
                If rDet.Id_Gtask = '' then rDet.Id_Gtask := UserTask.IdQr;
                rDet.Modify();
            end;
        end;

        If UserTask.Get(rDet."Id_Tarea") then begin
            UserTask.Validate(Title, rDet."Descripción");
            UserTask.SetDescription(rDet.GetWorkDescription());
            UserTask."Assigned To" := rDet.Usuario;
            UserTask.Validate("Created DateTime", CurrentDateTime);
            UserTask."Start DateTime" := rDet.FechaHora;
            UserTask."Due DateTime" := rDet.FechaHora;
            UserTask.Validate(Priority, Usertask.Priority::High);
            // No revalidar Object Type/ID: Modify() comprueba AllObj igual que Validate y
            // la tarea ya tiene la page correcta. Solo actualizamos Id_record.
            If rDet."Tipo Elemento" = rDet."Tipo Elemento"::Recurso then begin
                If rDet.Empresa <> '' Then Resource.ChangeCompany(rDet.Empresa) else Resource.ChangeCompany(CompanyName);
                Resource.Get(rDet.Recurso);
                UserTask.Id_record := Resource.RecordId;
                Resource.SetRange("No.", Resource."No.");
                RecRef.GetTable(Resource);
                RecRef.Get(Resource.RecordId);
            end else begin
                Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, rDet.Recurso);
                UserTask.Id_record := Emplazamientos.RecordId;
                Resource.SetRange("Nº Emplazamiento", Emplazamientos."Nº Emplazamiento");
                RecRef.GetTable(Emplazamientos);
                RecRef.Get(Emplazamientos.RecordId);
            end;
            UserTask."No." := Format(UserTask.ID);
            if IdQrOrdenTrabajo(rDet) <> '' then
                UserTask.IdQr := IdQrOrdenTrabajo(rDet)
            else
                if rDet.Id_Gtask <> '' then
                    UserTask.IdQr := rDet.Id_Gtask;
            UserTask.TestField(IdQr);
            UserTask."Created By" := UserTask."Supervisor";
            if IsNullGuid(rDet."Usuario Asignado") = false then
                UserTask."Assigned To" := rDet."Usuario Asignado"
            else
                UserTask."Assigned To" := rDet.Usuario;
            if rdet.Estado = rdet.Estado::Cerrada then
                UserTask.Estado := UserTask.Estado::Finalizado;
            // Modify(false): no revalida Object ID/AllObj (Validate y Modify(true) fallaban igual).
            UserTask.Modify(false);
        end;
        Procesos_GTask.UpdateTaskGtask(UserTask.Id_Tarea, UserTask.ID);
    end;



    local procedure UpdateTasksFicheros()
    var
        Ficheros: Record Ficheros;
        FicheroProcesado: Record Ficheros;
        Pendientes: List of [Integer];
        Secuencia: Integer;
    begin
        Ficheros.ReadIsolation := IsolationLevel::ReadUncommitted;
        Ficheros.SetRange(Proceso, 'UPDATEGTASK');
        Ficheros.SetRange(Procesado, false);
        if Ficheros.FindSet(false) then
            repeat
                Pendientes.Add(Ficheros.Secuencia);
            until Ficheros.Next() = 0;

        foreach Secuencia in Pendientes do begin
            if FicheroProcesado.Get(Secuencia) then
                if not FicheroProcesado.Procesado then
                    if Procesos_GTask.UpdateTaskGtask(FicheroProcesado."Nombre fichero", FicheroProcesado."Incoming Entry No.") then begin
                        FicheroProcesado.Procesado := true;
                        FicheroProcesado.Modify();
                        if not TareasEncoladasEnEstaEjecucion.Contains(FicheroProcesado."Incoming Entry No.") then
                            TareasEncoladasEnEstaEjecucion.Add(FicheroProcesado."Incoming Entry No.");
                    end;
            Commit();
        end;
    end;

    local procedure MarcarTareasComunicadas()
    var
        Tareas: Record "User Task";
        IdTarea: Integer;
    begin
        foreach IdTarea in TareasEncoladasEnEstaEjecucion do
            if Tareas.Get(IdTarea) then begin
                if Tareas."Fecha Cambio" = 0DT then
                    Tareas."Fecha Cambio" := CurrentDateTime;
                Tareas."Fecha Comunicado Cambio" := Tareas."Fecha Cambio";
                Tareas.Modify(false);
            end;
        Clear(TareasEncoladasEnEstaEjecucion);
        Commit();
    end;

    local procedure EnviarCorreoBak(UserTask: Record "User Task"; Descripcion: Text)
    var
        Ficheros: Record Ficheros;
        Secuencia: Integer;
    begin
        ficheros.Reset();
        if ficheros.FindLast() then Secuencia := ficheros.Secuencia + 1 else Secuencia := 1;
        ficheros.Init();
        ficheros.Secuencia := Secuencia;
        ficheros."Nombre fichero" := Descripcion;
        ficheros."Incoming Entry No." := UserTask.ID;
        ficheros.Proceso := 'ENVIARCORREOTAREA';
        repeat
            ficheros.Secuencia := Secuencia;
            Secuencia += 1;
        Until ficheros.Insert();


    end;

    local procedure EnviarCorreoFicheros()
    var
        Ficheros: Record Ficheros;
        Gtask: Codeunit Gtask;
        UserTask: Record "User Task";
        EmailResponsable: Text[250];
        EmailSupervisor: Text[250];
        ListadeCorreos: Text;
        User: Record User;
        Incidencias: Record Incidencias;
        Desc: Text;
        Recurso: Record Resource;
    begin
        Ficheros.SetRange(Proceso, 'ENVIARCORREOTAREA');
        If Ficheros.FindSet() then begin
            repeat
                If UserTask.Get(Ficheros."Incoming Entry No.") then begin
                    User.Get(UserTask."Assigned To");
                    Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
                    Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Ficheros."Nombre fichero", EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false, true);
                end;

            until Ficheros.Next() = 0;
            Ficheros.Deleteall;
        end;
        Incidencias.SetRange("Enviar Correo", true);
        If Incidencias.FindSet() then begin
            repeat
                //Gtask.Email(Incidencias, EmailResponsable, EmailSupervisor);
                EmailResponsable := 'villena@malla.es';
                ListadeCorreos := 'javi@malla.es;lllompart@malla.es;andreuserra@malla.es';
                If Incidencias."Tipo Incidencia" = Incidencias."Tipo Incidencia"::"Incidencias EMT" then
                    ListadeCorreos += ';aitorrodriguez@malla.es;jaumecuart@malla.es';
                If Incidencias."Tipo Elemento" = Incidencias."Tipo Elemento"::Recurso then begin
                    If Recurso.Get(Incidencias.Recurso) Then
                        Desc := Recurso.Name else
                        Desc := Incidencias.Recurso;
                end else begin
                    Desc := 'Parada nº ' + Incidencias.Recurso;
                end;
                Procesos_GTask.EnviaCorreo(Incidencias."No.", Desc + ' - ' + Incidencias.GetWorkDescription(), true, '', false, Incidencias."Descripción",
                EmailResponsable, ListadeCorreos, EmailSupervisor, '', Incidencias.NombreUsuario(Incidencias.Usuario), false, '', true, true);
            until Incidencias.Next() = 0;
            Incidencias.ModifyAll("Enviar Correo", false);
        end;
    end;

    local procedure EnviarDocumentos(var Tarea: Record "User Task"; ID: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachment2: Record "Document Attachment";
        JsonFormater: Codeunit "Json Text Reader/Writer";
        Base64Data: Text;
        DocumentStream: Outstream;
        TempBlob: Codeunit "Temp Blob";
        Int: InStream;
        Bs64: Codeunit "Base64 Convert";
        RestApi: Codeunit "RestApi";
        Json: Text;
        Filename: Text;
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;

    begin
        DocumentAttachment.SetRange("Table ID", Database::"User Task");
        DocumentAttachment.SetRange("No.", Tarea."No.");
        DocumentAttachment.SetRange("File Name", '');
        DocumentAttachment.SetRange(Id_Url, 0);
        DocumentAttachment.deleteall;
        DocumentAttachment.SetRange("File Name");
        DocumentAttachment.SetRange(Id_Url);
        if DocumentAttachment.FindFirst then
            repeat
                DocumentAttachment2.SetRange("Table ID", Database::"User Task");
                DocumentAttachment2.SetRange("No.", Tarea."No.");
                DocumentAttachment2.SetRange(Url, DocumentAttachment.Url);
                DocumentAttachment2.SetFilter(Id, '>%1', DocumentAttachment.Id);
                If DocumentAttachment2.FindFirst() then begin
                    DocumentAttachment2.Delete();
                end;
            Until DocumentAttachment.Next() = 0;
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
                    JsonFormater.WriteStringProperty('document', Base64Data);
                end else begin
                    if DocumentAttachment."Url" <> '' then begin
                        If DocumentAttachment.ID_Url = 0 Then begin
                            Base64Data := DocumentAttachment.ToBase64StringOcr(DocumentAttachment.Url);
                            JsonFormater.WriteStringProperty('document', Base64Data);
                            //JsonFormater.WriteEndObject();

                        end else begin
                            JsonFormater.WriteStartObject('document');
                            JsonFormater.WriteStringProperty('_id', DocumentAttachment.ID_Url);
                            JsonFormater.WriteStringProperty('url', DocumentAttachment.Url);
                            JsonFormater.WriteEndObject();
                        end;
                    end;
                end;

                FileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";
                //el nomnre no puede acabar en "."
                If CopyStr(Filename, StrLen(Filename), 1) = '.' then
                    FileName := CopyStr(Filename, 1, StrLen(Filename) - 1);
                JsonFormater.WriteStringProperty('name', Filename);
                //bc true
                JsonFormater.WriteBooleanProperty('bc', true);
                JsonFormater.WriteEndObject();
                Clear(RestApi);
                Json := JsonFormater.GetJSonAsText();
                CompanyInfo.Get();
                Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/document/' + Id, Token(), RequestType::put, jSon);
            until DocumentAttachment.Next() = 0;
    end;

    procedure ComprobarSiExisteDocumento(Docurl: Text): Boolean
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
    begin
        if not Client.Get(Docurl, ResponseMessage) then
            exit(false);
        exit(ResponseMessage.IsSuccessStatusCode());
    end;

    #region Services

    /// <summary>
    /// Devuelve peticiones (incidencias) abiertas o en progreso con parte de trabajo, con adjuntos en Base64
    /// y, si existe Id Factura en la orden EMT, la factura impresa en PDF en Base64.
    /// </summary>
    [ServiceEnabled]
    procedure GetOrdenesTrabajo(): Text
    var
        Incidencias: Record Incidencias;
        JsonRoot: JsonObject;
        JsonArray: JsonArray;
        JsonLinea: JsonObject;
        Txt: Text;
    begin
        Clear(JsonArray);
        Incidencias.SetRange("Es Peticion", true);
        Incidencias.SetFilter("Parte Trabajo", '<>%1', '');
        Incidencias.SetFilter(Estado, '<>%1', Incidencias.Estado::Cerrada);
        if Incidencias.FindSet() then
            repeat
                Clear(JsonLinea);
                JsonLinea.Add('no', Incidencias."No.");
                JsonLinea.Add('descripcion', Incidencias."Descripción");
                JsonLinea.Add('parteTrabajo', Incidencias."Parte Trabajo");
                JsonLinea.Add('estado', Format(Incidencias.Estado));
                JsonLinea.Add('fechaHora', Incidencias."FechaHora");
                JsonLinea.Add('workDescription', Incidencias.GetWorkDescription());
                AgregarAdjuntosYFacturaOrdenJson(Incidencias."Parte Trabajo", JsonLinea);
                JsonArray.Add(JsonLinea);
            until Incidencias.Next() = 0;

        Clear(JsonRoot);
        JsonRoot.Add('value', JsonArray.AsToken());
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    /// <summary>
    /// Listado para ordenes.malla.es. Entrada: {"idGtask":"...","vista":"mias"|"supervisar"}.
    /// Salida: {"success":true,"esSupervisor":...,"ordenes":[{no,descripcion,recurso,direccion,estado,idQr,firmaFirmada}]}.
    /// </summary>
    [ServiceEnabled]
    procedure ListarOrdenesUsuario(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonOut: JsonObject;
        JsonOrden: JsonObject;
        JsonOrdenes: JsonArray;
        JsonToken: JsonToken;
        Usuario: Record UsuariosGtask;
        TimeSheetHeader: Record "Time Sheet Header";
        UserTask: Record "User Task";
        IdGtask: Text;
        Vista: Text;
        EsAsignado: Boolean;
        EsSupervisorOrden: Boolean;
        Incluir: Boolean;
        ResultText: Text;
    begin
        if (JsonText = '') or not JsonIn.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        IdGtask := '';
        if JsonIn.Get('idGtask', JsonToken) then
            IdGtask := JsonToken.AsValue().AsText();
        if IdGtask = '' then
            Error('No se ha indicado idGtask.');

        Vista := 'mias';
        if JsonIn.Get('vista', JsonToken) then
            Vista := LowerCase(DelChr(JsonToken.AsValue().AsText(), '<>', ' '));

        if not BuscarUsuarioGtaskOperario(IdGtask, Usuario) then
            Error('No se ha encontrado el usuario GTask %1.', IdGtask);

        Clear(JsonOrdenes);
        TimeSheetHeader.SetRange(Estado, TimeSheetHeader.Estado::Abierto);
        TimeSheetHeader.SetFilter(Tarea, '<>%1', 0);
        if TimeSheetHeader.FindSet() then
            repeat
                if UserTask.Get(TimeSheetHeader.Tarea) then begin
                    EsAsignado := UserTask."Assigned To" = Usuario."Id Usuario";
                    EsSupervisorOrden := Usuario.Supervisor and (UserTask.Supervisor = Usuario."Id Usuario");
                    Incluir := false;
                    if Vista = 'supervisar' then
                        Incluir := EsSupervisorOrden
                    else
                        Incluir := EsAsignado;
                    if Incluir then begin
                        Clear(JsonOrden);
                        AgregarOrdenListadoJson(TimeSheetHeader, JsonOrden);
                        JsonOrdenes.Add(JsonOrden);
                    end;
                end;
            until TimeSheetHeader.Next() = 0;

        Clear(JsonOut);
        JsonOut.Add('success', true);
        JsonOut.Add('esSupervisor', Usuario.Supervisor);
        JsonOut.Add('ordenes', JsonOrdenes.AsToken());
        JsonOut.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure AgregarOrdenListadoJson(TimeSheetHeader: Record "Time Sheet Header"; var JsonOrden: JsonObject)
    var
        Incidencias: Record Incidencias;
        RecursoTxt: Text;
    begin
        JsonOrden.Add('no', TimeSheetHeader."No.");
        JsonOrden.Add('idQr', 'OT-' + TimeSheetHeader."No.");
        JsonOrden.Add('descripcion', TimeSheetHeader.Description);
        JsonOrden.Add('direccion', TimeSheetHeader."Dirección");
        JsonOrden.Add('estado', Format(TimeSheetHeader.Estado));
        JsonOrden.Add('firmaFirmada', FirmaTecnicoTiene(TimeSheetHeader));

        RecursoTxt := '';
        Incidencias.SetRange("Parte Trabajo", TimeSheetHeader."No.");
        Incidencias.SetRange("Es Peticion", true);
        if not Incidencias.FindFirst() then begin
            Incidencias.SetRange("Es Peticion");
            Incidencias.FindFirst();
        end;
        if Incidencias."No." <> '' then
            RecursoTxt := Incidencias.Recurso;
        JsonOrden.Add('recurso', RecursoTxt);
    end;

    /// <summary>
    /// Detalle para ordenes.malla.es. Entrada: {"idGtask":"...","no":"...","vista":"mias"|"supervisar"}.
    /// </summary>
    [ServiceEnabled]
    procedure DetalleOrdenTrabajo(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonOut: JsonObject;
        JsonOrden: JsonObject;
        JsonLineasOut: JsonArray;
        JsonLineaFull: JsonObject;
        JsonToken: JsonToken;
        JsonLineasToken: JsonToken;
        JsonLineasIn: JsonArray;
        JsonLineIn: JsonObject;
        JsonLineOut: JsonObject;
        Usuario: Record UsuariosGtask;
        TimeSheetHeader: Record "Time Sheet Header";
        UserTask: Record "User Task";
        IdGtask: Text;
        Vista: Text;
        NoParte: Code[20];
        EsAsignado: Boolean;
        EsSupervisorOrden: Boolean;
        PuedeVer: Boolean;
        i: Integer;
        ResultText: Text;
        NombreLinea: Text;
        CantidadLinea: Decimal;
    begin
        if (JsonText = '') or not JsonIn.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        IdGtask := '';
        if JsonIn.Get('idGtask', JsonToken) then
            IdGtask := JsonToken.AsValue().AsText();
        if JsonIn.Get('no', JsonToken) then
            NoParte := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoParte));
        Vista := 'mias';
        if JsonIn.Get('vista', JsonToken) then
            Vista := LowerCase(DelChr(JsonToken.AsValue().AsText(), '<>', ' '));

        if (IdGtask = '') or (NoParte = '') then
            Error('Faltan idGtask o no de la orden.');
        if not BuscarUsuarioGtaskOperario(IdGtask, Usuario) then
            Error('No se ha encontrado el usuario GTask %1.', IdGtask);
        if not TimeSheetHeader.Get(NoParte) then
            Error('No existe el parte de trabajo %1.', NoParte);
        if not UserTask.Get(TimeSheetHeader.Tarea) then
            Error('La orden no tiene tarea vinculada.');

        EsAsignado := UserTask."Assigned To" = Usuario."Id Usuario";
        EsSupervisorOrden := Usuario.Supervisor and (UserTask.Supervisor = Usuario."Id Usuario");
        PuedeVer := false;
        if Vista = 'supervisar' then
            PuedeVer := EsSupervisorOrden
        else
            PuedeVer := EsAsignado;
        if not PuedeVer then
            Error('No tiene permiso para ver esta orden.');

        Clear(JsonLineaFull);
        AgregarOrdenOperarioJson(TimeSheetHeader, UserTask, EsAsignado, EsSupervisorOrden, JsonLineaFull);

        Clear(JsonOrden);
        JsonOrden.Add('no', TimeSheetHeader."No.");
        JsonOrden.Add('idQr', 'OT-' + TimeSheetHeader."No.");
        JsonOrden.Add('descripcion', TimeSheetHeader.Description);
        JsonOrden.Add('direccion', TimeSheetHeader."Dirección");
        JsonOrden.Add('estado', Format(TimeSheetHeader.Estado));
        JsonOrden.Add('tipo', Format(TimeSheetHeader.Tipo));
        JsonOrden.Add('cliente', TimeSheetHeader.Cliente);
        JsonOrden.Add('nombreCliente', TimeSheetHeader."Nombre Cliente");
        JsonOrden.Add('firmaFirmada', FirmaTecnicoTiene(TimeSheetHeader));
        if TimeSheetHeader."Fecha Firma Tecnico" <> 0DT then
            JsonOrden.Add('fechaFirmaTecnico', Format(TimeSheetHeader."Fecha Firma Tecnico", 0, 9));

        if JsonLineaFull.Get('recurso', JsonToken) then
            JsonOrden.Add('recurso', JsonToken.AsValue().AsText());
        if JsonLineaFull.Get('descripcionPeticion', JsonToken) then
            JsonOrden.Add('descripcionPeticion', JsonToken.AsValue().AsText());
        if JsonLineaFull.Get('importe', JsonToken) then
            JsonOrden.Add('importe', JsonToken.AsValue().AsDecimal());

        Clear(JsonLineasOut);
        if JsonLineaFull.Get('lineas', JsonLineasToken) then begin
            JsonLineasIn := JsonLineasToken.AsArray();
            for i := 0 to JsonLineasIn.Count() - 1 do begin
                JsonLineasIn.Get(i, JsonToken);
                JsonLineIn := JsonToken.AsObject();
                Clear(JsonLineOut);
                NombreLinea := '';
                CantidadLinea := 0;
                if JsonLineIn.Get('codigo', JsonToken) then
                    JsonLineOut.Add('codigo', JsonToken.AsValue().AsText());
                if JsonLineIn.Get('nombre', JsonToken) then begin
                    NombreLinea := JsonToken.AsValue().AsText();
                    JsonLineOut.Add('descripcion', NombreLinea);
                    JsonLineOut.Add('nombre', NombreLinea);
                end;
                if JsonLineIn.Get('cantidad', JsonToken) then begin
                    CantidadLinea := JsonToken.AsValue().AsDecimal();
                    JsonLineOut.Add('cantidad', CantidadLinea);
                end;
                if JsonLineIn.Get('precio', JsonToken) then
                    JsonLineOut.Add('precio', JsonToken.AsValue().AsDecimal());
                if JsonLineIn.Get('importe', JsonToken) then
                    JsonLineOut.Add('importe', JsonToken.AsValue().AsDecimal());
                JsonLineasOut.Add(JsonLineOut);
            end;
        end;

        Clear(JsonOut);
        JsonOut.Add('success', true);
        JsonOut.Add('puedeValorar', EsSupervisorOrden and (TimeSheetHeader.Estado = TimeSheetHeader.Estado::Abierto));
        JsonOut.Add('puedeFirmar', EsAsignado and (TimeSheetHeader.Estado = TimeSheetHeader.Estado::Abierto) and not FirmaTecnicoTiene(TimeSheetHeader));
        JsonOut.Add('esSupervisor', EsSupervisorOrden);
        JsonOut.Add('orden', JsonOrden.AsToken());
        JsonOut.Add('lineas', JsonLineasOut.AsToken());
        JsonOut.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Guarda la firma PNG (base64) del técnico asignado. JSON: {"idGtask":"...","no_parte":"...","firma":"..."}.
    /// </summary>
    [ServiceEnabled]
    procedure FirmarOrdenTrabajo(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonOut: JsonObject;
        JsonToken: JsonToken;
        Usuario: Record UsuariosGtask;
        TimeSheetHeader: Record "Time Sheet Header";
        UserTask: Record "User Task";
        IdGtask: Text;
        NoParte: Code[20];
        FirmaBase64: Text;
        ResultText: Text;
    begin
        if (JsonText = '') or not JsonIn.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        IdGtask := '';
        if JsonIn.Get('idGtask', JsonToken) then
            IdGtask := JsonToken.AsValue().AsText();
        if JsonIn.Get('no_parte', JsonToken) then
            NoParte := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoParte));
        if (NoParte = '') and JsonIn.Get('no', JsonToken) then
            NoParte := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoParte));
        if JsonIn.Get('firma', JsonToken) then
            FirmaBase64 := JsonToken.AsValue().AsText();

        if (IdGtask = '') or (NoParte = '') then
            Error('Faltan idGtask o número de parte.');
        if FirmaBase64 = '' then
            Error('No se ha recibido la firma.');

        if not BuscarUsuarioGtaskOperario(IdGtask, Usuario) then
            Error('No se ha encontrado el usuario GTask %1.', IdGtask);
        if not TimeSheetHeader.Get(NoParte) then
            Error('No existe el parte de trabajo %1.', NoParte);
        if TimeSheetHeader.Estado <> TimeSheetHeader.Estado::Abierto then
            Error('Solo se puede firmar una orden abierta.');
        if not UserTask.Get(TimeSheetHeader.Tarea) then
            Error('La orden no tiene tarea vinculada.');
        if UserTask."Assigned To" <> Usuario."Id Usuario" then
            Error('Solo el técnico asignado puede firmar la orden.');
        if FirmaTecnicoTiene(TimeSheetHeader) then
            Error('La orden ya está firmada.');

        GuardarFirmaTecnicoBase64(TimeSheetHeader, FirmaBase64);

        Clear(JsonOut);
        JsonOut.Add('success', true);
        JsonOut.Add('ok', true);
        JsonOut.Add('no_parte', TimeSheetHeader."No.");
        JsonOut.Add('firmaFirmada', true);
        JsonOut.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure FirmaTecnicoTiene(TimeSheetHeader: Record "Time Sheet Header"): Boolean
    begin
        TimeSheetHeader.CalcFields("Firma Técnico");
        exit(TimeSheetHeader."Firma Técnico".HasValue);
    end;

    local procedure GuardarFirmaTecnicoBase64(var TimeSheetHeader: Record "Time Sheet Header"; Base64Txt: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        Payload: Text;
    begin
        Payload := ExtraerPayloadBase64Imagen(Base64Txt);
        if Payload = '' then
            Error('La firma no es válida.');

        TimeSheetHeader.LockTable();
        if not TimeSheetHeader.Get(TimeSheetHeader."No.") then
            Error('No existe el parte de trabajo.');

        Clear(TimeSheetHeader."Firma Técnico");
        TimeSheetHeader."Firma Técnico".CreateOutStream(OutStream);
        Base64Convert.FromBase64(Payload, OutStream);
        TimeSheetHeader."Fecha Firma Tecnico" := CurrentDateTime;
        TimeSheetHeader.Modify(true);
    end;

    local procedure ExtraerPayloadBase64Imagen(Base64Txt: Text): Text
    var
        Separador: Integer;
        Prefijo: Text;
    begin
        Base64Txt := DelChr(Base64Txt, '=', ' ');
        if Base64Txt = '' then
            exit('');

        Prefijo := 'base64,';
        Separador := StrPos(LowerCase(Base64Txt), Prefijo);
        if Separador > 0 then
            exit(CopyStr(Base64Txt, Separador + StrLen(Prefijo)));

        exit(Base64Txt);
    end;

    /// <summary>
    /// Órdenes abiertas del operario: parte en Abierto cuya tarea está asignada a él.
    /// Si UsuariosGtask.Supervisor está marcado, también las abiertas en las que él es el supervisor de la tarea.
    /// Los importes solo van en las que ve como supervisor. UsuarioGtask: Id Gtask, email o Usuario EMT.
    /// </summary>
    [ServiceEnabled]
    procedure GetOrdenesOperario(UsuarioGtask: Text): Text
    var
        Usuario: Record UsuariosGtask;
        TimeSheetHeader: Record "Time Sheet Header";
        UserTask: Record "User Task";
        JsonRoot: JsonObject;
        JsonArray: JsonArray;
        JsonLinea: JsonObject;
        Txt: Text;
        EsAsignado: Boolean;
        EsSupervisorOrden: Boolean;
        Contador: Integer;
    begin
        if not BuscarUsuarioGtaskOperario(UsuarioGtask, Usuario) then
            Error('No se ha encontrado el usuario GTask %1.', UsuarioGtask);

        Clear(JsonArray);
        Contador := 0;
        TimeSheetHeader.SetRange(Estado, TimeSheetHeader.Estado::Abierto);
        TimeSheetHeader.SetFilter(Tarea, '<>%1', 0);
        if TimeSheetHeader.FindSet() then
            repeat
                if UserTask.Get(TimeSheetHeader.Tarea) then begin
                    EsAsignado := UserTask."Assigned To" = Usuario."Id Usuario";
                    EsSupervisorOrden := Usuario.Supervisor and (UserTask.Supervisor = Usuario."Id Usuario");
                    if EsAsignado or EsSupervisorOrden then begin
                        Clear(JsonLinea);
                        AgregarOrdenOperarioJson(TimeSheetHeader, UserTask, EsAsignado, EsSupervisorOrden, JsonLinea);
                        JsonArray.Add(JsonLinea);
                        Contador += 1;
                    end;
                end;
            until TimeSheetHeader.Next() = 0;

        Clear(JsonRoot);
        JsonRoot.Add('value', JsonArray.AsToken());
        JsonRoot.Add('usuarioGtask', Usuario."Id Gtask");
        JsonRoot.Add('supervisor', Usuario.Supervisor);
        JsonRoot.Add('count', Contador);
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure BuscarUsuarioGtaskOperario(UsuarioGtask: Text; var Usuario: Record UsuariosGtask): Boolean
    begin
        UsuarioGtask := DelChr(UsuarioGtask, '=', ' ');
        if UsuarioGtask = '' then
            exit(false);

        Usuario.Reset();
        Usuario.SetRange("Id Gtask", CopyStr(UsuarioGtask, 1, MaxStrLen(Usuario."Id Gtask")));
        if Usuario.FindFirst() then
            exit(true);

        Usuario.Reset();
        Usuario.SetRange(Email, CopyStr(UsuarioGtask, 1, MaxStrLen(Usuario.Email)));
        if Usuario.FindFirst() then
            exit(true);

        Usuario.Reset();
        Usuario.SetRange("Usuario EMT", CopyStr(UsuarioGtask, 1, MaxStrLen(Usuario."Usuario EMT")));
        exit(Usuario.FindFirst());
    end;

    local procedure AgregarOrdenOperarioJson(TimeSheetHeader: Record "Time Sheet Header"; UserTask: Record "User Task"; EsAsignado: Boolean; EsSupervisorOrden: Boolean; var JsonLinea: JsonObject)
    var
        Incidencias: Record Incidencias;
        JsonLineas: JsonArray;
        ImporteTotal: Decimal;
    begin
        UserTask.CalcFields("Assigned To User Name", "Supervisor User Name");
        JsonLinea.Add('no', TimeSheetHeader."No.");
        JsonLinea.Add('idQr', 'OT-' + TimeSheetHeader."No.");
        JsonLinea.Add('descripcion', TimeSheetHeader.Description);
        JsonLinea.Add('cliente', TimeSheetHeader.Cliente);
        JsonLinea.Add('nombreCliente', TimeSheetHeader."Nombre Cliente");
        JsonLinea.Add('direccion', TimeSheetHeader."Dirección");
        JsonLinea.Add('fechaInicio', Format(TimeSheetHeader."Fecha Inicio", 0, 9));
        JsonLinea.Add('fechaFin', Format(TimeSheetHeader."Fecha Fin", 0, 9));
        JsonLinea.Add('estado', Format(TimeSheetHeader.Estado));
        JsonLinea.Add('tipo', Format(TimeSheetHeader.Tipo));
        JsonLinea.Add('tarea', UserTask.ID);
        JsonLinea.Add('titulo', UserTask.Title);
        JsonLinea.Add('idTareaGtask', UserTask.Id_Tarea);
        JsonLinea.Add('asignadoA', UserTask."Assigned To User Name");
        JsonLinea.Add('supervisorNombre', UserTask."Supervisor User Name");
        JsonLinea.Add('asignado', EsAsignado);
        JsonLinea.Add('esSupervisor', EsSupervisorOrden);
        JsonLinea.Add('puedeValorar', EsSupervisorOrden);
        JsonLinea.Add('firmaFirmada', FirmaTecnicoTiene(TimeSheetHeader));
        if TimeSheetHeader."Fecha Firma Tecnico" <> 0DT then
            JsonLinea.Add('fechaFirmaTecnico', Format(TimeSheetHeader."Fecha Firma Tecnico", 0, 9));

        Incidencias.SetRange("Parte Trabajo", TimeSheetHeader."No.");
        Incidencias.SetRange("Es Peticion", true);
        if not Incidencias.FindFirst() then begin
            Incidencias.SetRange("Es Peticion");
            if not Incidencias.FindFirst() then
                Clear(Incidencias);
        end;
        if Incidencias."No." <> '' then begin
            JsonLinea.Add('peticion', Incidencias."No.");
            JsonLinea.Add('descripcionPeticion', Incidencias."Descripción");
            JsonLinea.Add('recurso', Incidencias.Recurso);
            JsonLinea.Add('tipoElemento', Format(Incidencias."Tipo Elemento"));
            JsonLinea.Add('workDescription', Incidencias.GetWorkDescription());
        end else begin
            JsonLinea.Add('peticion', '');
            JsonLinea.Add('descripcionPeticion', '');
            JsonLinea.Add('recurso', '');
            JsonLinea.Add('tipoElemento', '');
            JsonLinea.Add('workDescription', '');
        end;

        AgregarLineasOrdenOperarioJson(TimeSheetHeader."No.", EsSupervisorOrden, JsonLineas, ImporteTotal);
        JsonLinea.Add('lineas', JsonLineas.AsToken());
        if EsSupervisorOrden then
            JsonLinea.Add('importe', ImporteTotal);
    end;

    local procedure AgregarLineasOrdenOperarioJson(ParteNo: Code[20]; IncluirImportes: Boolean; var JsonLineas: JsonArray; var ImporteTotal: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
        JsonLine: JsonObject;
        TipoLinea: Text;
    begin
        Clear(JsonLineas);
        ImporteTotal := 0;
        TimeSheetLine.SetRange("Time Sheet No.", ParteNo);
        if TimeSheetLine.FindSet() then
            repeat
                Clear(JsonLine);
                case TimeSheetLine.Tipo of
                    TimeSheetLine.Tipo::Producto:
                        TipoLinea := 'producto';
                    TimeSheetLine.Tipo::Recurso:
                        TipoLinea := 'recurso';
                    TimeSheetLine.Tipo::Trabajo:
                        TipoLinea := 'trabajo';
                    TimeSheetLine.Tipo::Nacional:
                        TipoLinea := 'nacional';
                    else
                        TipoLinea := '';
                end;
                JsonLine.Add('linea', TimeSheetLine."Line No.");
                JsonLine.Add('tipo', TipoLinea);
                JsonLine.Add('codigo', TimeSheetLine.No);
                JsonLine.Add('nombre', TimeSheetLine.Descripcion);
                JsonLine.Add('cantidad', TimeSheetLine.Cantidad);
                JsonLine.Add('unidad', TimeSheetLine.Unidad);
                if IncluirImportes then begin
                    JsonLine.Add('precio', TimeSheetLine.Precio);
                    JsonLine.Add('dto', TimeSheetLine.Dto);
                    JsonLine.Add('importe', TimeSheetLine.Importe);
                    ImporteTotal += TimeSheetLine.Importe;
                end;
                JsonLineas.Add(JsonLine);
            until TimeSheetLine.Next() = 0;
    end;

    /// <summary>
    /// Devuelve las tareas para el calendario compartido desde hoy hasta los meses indicados.
    /// Incluye tareas del grupo (por campo Grupo) y tareas supervisadas por miembros del grupo
    /// aunque el responsable esté fuera. Sin duplicar por ID.
    /// Si Meses es 0, usa 3 meses por defecto.
    /// </summary>
    [ServiceEnabled]
    procedure GetTareasCalendario(Meses: Integer; UsuarioGtask: Text): Text
    var
        Tareas: Record "User Task";
        TareasTemp: Record "User Task" temporary;
        Usuario: Record UsuariosGtask;
        JsonRoot: JsonObject;
        JsonArray: JsonArray;
        JsonLinea: JsonObject;
        DesdeDT: DateTime;
        HastaDT: DateTime;
        HastaFecha: Date;
        Txt: Text;
        GrupoUsuario: Code[20];
    begin
        if Meses <= 0 then
            Meses := 3;

        if not BuscarGrupoUsuarioCalendario(UsuarioGtask, GrupoUsuario) then
            Error('No se ha encontrado grupo para el usuario GTask %1.', UsuarioGtask);

        DesdeDT := CreateDateTime(Calcdate('<CM+1D-1M>', Today), 000000T);
        HastaFecha := CalcDate(StrSubstNo('<+%1M>', Meses), Today);
        HastaDT := CreateDateTime(HastaFecha, 235959T);

        Clear(TareasTemp);
        Tareas.Reset();
        Tareas.SetRange("Start DateTime", DesdeDT, HastaDT);
        Tareas.SetRange(Grupo, GrupoUsuario);
        if Tareas.FindSet() then
            repeat
                TareasTemp := Tareas;
                if TareasTemp.Insert() then;
            until Tareas.Next() = 0;

        Usuario.Reset();
        Usuario.SetRange(Grupo, GrupoUsuario);
        if Usuario.FindSet() then
            repeat
                if not IsNullGuid(Usuario."Id Usuario") then begin
                    Tareas.Reset();
                    Tareas.SetRange("Start DateTime", DesdeDT, HastaDT);
                    Tareas.SetRange(Supervisor, Usuario."Id Usuario");
                    if Tareas.FindSet() then
                        repeat
                            if not TareasTemp.Get(Tareas.ID) then begin
                                TareasTemp := Tareas;
                                if TareasTemp.Insert() then;
                            end;
                        until Tareas.Next() = 0;
                end;
            until Usuario.Next() = 0;

        Clear(JsonArray);
        if TareasTemp.FindSet() then
            repeat
                Clear(JsonLinea);
                AgregarTareaCalendarioJson(TareasTemp, JsonLinea);
                JsonArray.Add(JsonLinea);
            until TareasTemp.Next() = 0;

        Clear(JsonRoot);
        JsonRoot.Add('value', JsonArray.AsToken());
        JsonRoot.Add('from', Format(DesdeDT, 0, 9));
        JsonRoot.Add('to', Format(HastaDT, 0, 9));
        JsonRoot.Add('months', Meses);
        JsonRoot.Add('usuarioGtask', UsuarioGtask);
        JsonRoot.Add('grupo', GrupoUsuario);
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;


    /// <summary>
    /// Devuelve todos los usuarios GTask del mismo grupo que el usuario indicado.
    /// Salida: { "value": [ { "id", "nombre", "empleado", "email" } ], "grupo", "usuarioGtask", "count" }
    /// </summary>
    [ServiceEnabled]
    procedure GetUsuariosGrupo(UsuarioGtask: Text): Text
    var
        Usuario: Record UsuariosGtask;
        JsonRoot: JsonObject;
        JsonArray: JsonArray;
        JsonLinea: JsonObject;
        Txt: Text;
        GrupoUsuario: Code[20];
        NombreCompleto: Text;
        Contador: Integer;
    begin
        Clear(JsonArray);
        Contador := 0;

        if not BuscarGrupoUsuarioCalendario(UsuarioGtask, GrupoUsuario) then
            Error('No se ha encontrado grupo para el usuario GTask %1.', UsuarioGtask);

        Usuario.Reset();
        Usuario.SetRange(Grupo, GrupoUsuario);
        if Usuario.FindSet() then
            repeat
                if Usuario."Id Gtask" <> '' then begin
                    Clear(JsonLinea);
                    NombreCompleto := DelChr(Usuario.Nombre + ' ' + Usuario.Apellido, '<>', ' ');
                    if NombreCompleto = '' then
                        NombreCompleto := Usuario.Email;
                    if NombreCompleto = '' then
                        NombreCompleto := Usuario."Id Gtask";

                    JsonLinea.Add('id', Usuario."Id Gtask");
                    JsonLinea.Add('nombre', NombreCompleto);
                    JsonLinea.Add('empleado', Format(Usuario.Empleado));
                    JsonLinea.Add('email', Usuario.Email);
                    JsonArray.Add(JsonLinea);
                    Contador += 1;
                end;
            until Usuario.Next() = 0;

        Clear(JsonRoot);
        JsonRoot.Add('value', JsonArray.AsToken());
        JsonRoot.Add('grupo', GrupoUsuario);
        JsonRoot.Add('usuarioGtask', UsuarioGtask);
        JsonRoot.Add('count', Contador);
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    procedure BuscarGrupoUsuarioCalendario(UsuarioGtask: Text; var GrupoUsuario: Code[20]): Boolean
    var
        Usuario: Record UsuariosGtask;
    begin
        Clear(GrupoUsuario);
        UsuarioGtask := DelChr(UsuarioGtask, '=', ' ');
        if UsuarioGtask = '' then
            exit(false);

        Usuario.Reset();
        Usuario.SetRange("Id Gtask", CopyStr(UsuarioGtask, 1, MaxStrLen(Usuario."Id Gtask")));
        if not Usuario.FindFirst() then begin
            Usuario.Reset();
            Usuario.SetRange(Email, CopyStr(UsuarioGtask, 1, MaxStrLen(Usuario.Email)));
            if not Usuario.FindFirst() then begin
                Usuario.Reset();
                Usuario.SetRange("Usuario EMT", CopyStr(UsuarioGtask, 1, MaxStrLen(Usuario."Usuario EMT")));
                if not Usuario.FindFirst() then
                    exit(false);
            end;
        end;

        GrupoUsuario := Usuario.Grupo;
        exit(GrupoUsuario <> '');
    end;

    local procedure ObtenerLinkFichaTarea(Tarea: Record "User Task"): Text
    var
        Url: Text;
    begin
        Url := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"User Task Card", Tarea);
        Url := UrlCorrecta(Url);
        exit(Url);
    end;

    /// <summary>
    /// Mueve una tarea de calendario a una nueva fecha. Conserva la duración (inicio↔vencimiento).
    /// JSON: {"id":123,"fecha":"2026-06-15","scheduleByDue":false}
    /// scheduleByDue=true mueve el vencimiento; false mueve el inicio.
    /// </summary>
    [ServiceEnabled]
    procedure PostMoverTareaCalendario(JsonText: Text): Text
    var
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JsonResult: JsonObject;
        JsonLinea: JsonObject;
        Tarea: Record "User Task";
        IdTarea: Integer;
        FechaTexto: Text;
        NuevaFecha: Date;
        FechaInicio: Date;
        FechaDue: Date;
        HoraInicio: Time;
        HoraDue: Time;
        Dias: Integer;
        ScheduleByDue: Boolean;
        Txt: Text;
    begin
        if (JsonText = '') or not JsonObj.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        if not JsonObj.Get('id', JsonToken) then
            Error('No se ha indicado id de tarea');
        if not Evaluate(IdTarea, JsonToken.AsValue().AsText()) then
            Error('Id de tarea inválido: %1', JsonToken.AsValue().AsText());

        if not JsonObj.Get('fecha', JsonToken) then
            Error('No se ha indicado nueva fecha');
        FechaTexto := JsonToken.AsValue().AsText();
        if not Evaluate(NuevaFecha, FechaTexto) then
            Error('Fecha inválida: %1', FechaTexto);

        ScheduleByDue := false;
        if JsonObj.Get('scheduleByDue', JsonToken) then
            ScheduleByDue := JsonToken.AsValue().AsBoolean();

        if not Tarea.Get(IdTarea) then
            Error('No se ha encontrado la tarea %1', IdTarea);

        FechaInicio := DT2Date(Tarea."Start DateTime");
        FechaDue := DT2Date(Tarea."Due DateTime");
        HoraInicio := DT2Time(Tarea."Start DateTime");
        HoraDue := DT2Time(Tarea."Due DateTime");
        if HoraInicio = 0T then
            HoraInicio := 080000T;
        if HoraDue = 0T then
            HoraDue := HoraInicio;

        if FechaInicio = 0D then
            FechaInicio := NuevaFecha;
        if FechaDue = 0D then
            FechaDue := FechaInicio;
        Dias := FechaDue - FechaInicio;
        if Dias < 0 then
            Dias := 0;

        if ScheduleByDue then begin
            FechaDue := NuevaFecha;
            FechaInicio := NuevaFecha - Dias;
        end else begin
            FechaInicio := NuevaFecha;
            FechaDue := NuevaFecha + Dias;
        end;

        Tarea."Start DateTime" := CreateDateTime(FechaInicio, HoraInicio);
        Tarea."Due DateTime" := CreateDateTime(FechaDue, HoraDue);
        Tarea.Modify(true);

        Clear(JsonLinea);
        AgregarTareaCalendarioJson(Tarea, JsonLinea);

        Clear(JsonResult);
        JsonResult.Add('success', true);
        JsonResult.Add('task', JsonLinea.AsToken());
        JsonResult.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure AgregarTareaCalendarioJson(var Tarea: Record "User Task"; var JsonLinea: JsonObject)
    var
        UsuarioGtask: Record UsuariosGtask;
        AssignedGtaskId: Text;
        SupervisorGtaskId: Text;
        EmpleadoTxt: Text;
        EmpleadoSupervisorTxt: Text;
    begin
        Tarea.CalcFields("Assigned To User Name", "Supervisor User Name");

        AssignedGtaskId := '';
        EmpleadoTxt := '';
        UsuarioGtask.Reset();
        UsuarioGtask.SetRange("Id Usuario", Tarea."Assigned To");
        if UsuarioGtask.FindFirst() then begin
            AssignedGtaskId := UsuarioGtask."Id Gtask";
            EmpleadoTxt := Format(UsuarioGtask.Empleado);
        end;
        if AssignedGtaskId = '' then
            AssignedGtaskId := Format(Tarea."Assigned To");

        SupervisorGtaskId := '';
        EmpleadoSupervisorTxt := '';
        if not IsNullGuid(Tarea.Supervisor) then begin
            UsuarioGtask.Reset();
            UsuarioGtask.SetRange("Id Usuario", Tarea.Supervisor);
            if UsuarioGtask.FindFirst() then begin
                SupervisorGtaskId := UsuarioGtask."Id Gtask";
                EmpleadoSupervisorTxt := Format(UsuarioGtask.Empleado);
            end;
            if SupervisorGtaskId = '' then
                SupervisorGtaskId := Format(Tarea.Supervisor);
        end;

        JsonLinea.Add('id', Tarea.ID);
        JsonLinea.Add('no', Tarea."No.");
        JsonLinea.Add('title', Tarea.Title);
        JsonLinea.Add('description', Tarea.GetDescription());
        JsonLinea.Add('assignedTo', AssignedGtaskId);
        JsonLinea.Add('assignedToName', Tarea."Assigned To User Name");
        JsonLinea.Add('empleado', EmpleadoTxt);
        JsonLinea.Add('supervisor', SupervisorGtaskId);
        JsonLinea.Add('supervisorName', Tarea."Supervisor User Name");
        JsonLinea.Add('empleadosupervisor', EmpleadoSupervisorTxt);
        JsonLinea.Add('grupo', Tarea.Grupo);
        JsonLinea.Add('categoria', Tarea."Categoría");
        JsonLinea.Add('userTaskGroupAssignedTo', Tarea."User Task Group Assigned To");
        JsonLinea.Add('start', Format(Tarea."Start DateTime", 0, 9));
        JsonLinea.Add('due', Format(Tarea."Due DateTime", 0, 9));
        JsonLinea.Add('estado', Format(Tarea.Estado));
        JsonLinea.Add('percentComplete', Tarea."Percent Complete");
        JsonLinea.Add('priority', Format(Tarea.Priority));
        JsonLinea.Add('idTareaGtask', Tarea.Id_Tarea);
        JsonLinea.Add('link', ObtenerLinkFichaTarea(Tarea));
    end;

    /// <summary>
    /// Recibe una orden de trabajo con el PDF del parte y lo guarda como documento adjunto del parte EMT.
    /// JSON: no, parteTrabajo, document (Base64 o URL), url, idUrl/_id, fileName opcional.
    /// </summary>
    [ServiceEnabled]
    procedure PostOrdenTrabajo(JsonText: Text): Text
    var
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JsonResult: JsonObject;
        ResultText: Text;
        ParteTrabajoNo: Code[20];
        IncidenciaNo: Code[20];
        DocUrl: Text;
        Base64Txt: Text;
        NombreArchivo: Text;
        IdUrl: Integer;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Incidencias: Record Incidencias;
    begin
        if (JsonText = '') or not JsonObj.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        ResolverParteTrabajoOrdenJson(JsonObj, ParteTrabajoNo, IncidenciaNo);
        if ParteTrabajoNo = '' then
            Error('No se ha indicado el parte de trabajo de la orden.');

        ResolverDocumentoOrdenJson(JsonObj, DocUrl, Base64Txt);
        if (DocUrl = '') and (Base64Txt = '') then
            Error('No se ha recibido el PDF del parte de trabajo.');

        NombreArchivo := ExtraerNombreArchivoOrdenJson(JsonObj, ParteTrabajoNo, DocUrl);
        if DocUrl <> '' then begin
            IdUrl := ExtraerIdUrlOrdenJson(JsonObj);
            AdjuntarUrlParteTrabajo(ParteTrabajoNo, DocUrl, IdUrl, NombreArchivo);
        end else begin
            CargarPdfOrdenDesdeBase64(Base64Txt, TempBlob);
            TempBlob.CreateInStream(InS);
            AdjuntarPdfParteTrabajo(ParteTrabajoNo, InS, NombreArchivo);
        end;
        If Incidencias.Get(ParteTrabajoNo) then begin
            Incidencias.Estado := Incidencias.Estado::"Presupuesto Aprobado";
            Incidencias.Modify();
        end;

        Clear(JsonResult);
        JsonResult.Add('ok', true);
        JsonResult.Add('parteTrabajo', ParteTrabajoNo);
        if IncidenciaNo <> '' then
            JsonResult.Add('no', IncidenciaNo);
        JsonResult.Add('fileName', NombreArchivo);
        if DocUrl <> '' then begin
            JsonResult.Add('url', DocUrl);
            if IdUrl <> 0 then
                JsonResult.Add('idUrl', IdUrl);
        end;
        JsonResult.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure ResolverParteTrabajoOrdenJson(var JsonObj: JsonObject; var ParteTrabajoNo: Code[20]; var IncidenciaNo: Code[20])
    var
        JsonToken: JsonToken;
        Incidencias: Record Incidencias;
    begin
        Clear(ParteTrabajoNo);
        Clear(IncidenciaNo);

        if JsonObj.Get('parteTrabajo', JsonToken) then
            ParteTrabajoNo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(ParteTrabajoNo));
        if (ParteTrabajoNo = '') and JsonObj.Get('parte_trabajo', JsonToken) then
            ParteTrabajoNo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(ParteTrabajoNo));

        if JsonObj.Get('no', JsonToken) then
            IncidenciaNo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(IncidenciaNo));

        if (ParteTrabajoNo = '') and (IncidenciaNo <> '') then begin
            Incidencias.SetRange("No.", IncidenciaNo);
            if Incidencias.FindFirst() then
                ParteTrabajoNo := Incidencias."Parte Trabajo";
        end;

        if (IncidenciaNo = '') and (ParteTrabajoNo <> '') then begin
            Incidencias.SetRange("Parte Trabajo", ParteTrabajoNo);
            Incidencias.SetRange("Es Peticion", true);
            if Incidencias.FindFirst() then
                IncidenciaNo := Incidencias."No.";
        end;
    end;

    local procedure ResolverDocumentoOrdenJson(var JsonObj: JsonObject; var DocUrl: Text; var Base64Txt: Text)
    var
        JsonToken: JsonToken;
        JsonDocument: JsonObject;
        JsonDocumentNested: JsonObject;
        TextoDocumento: Text;
    begin
        Clear(DocUrl);
        Clear(Base64Txt);

        if JsonObj.Get('url', JsonToken) then
            DocUrl := CopyStr(JsonToken.AsValue().AsText(), 1, 2048);
        if (DocUrl = '') and JsonObj.Get('document_url', JsonToken) then
            DocUrl := CopyStr(JsonToken.AsValue().AsText(), 1, 2048);

        if JsonObj.Get('document', JsonToken) then begin
            if JsonToken.IsObject() then begin
                JsonDocument := JsonToken.AsObject();
                if (DocUrl = '') and JsonDocument.Get('url', JsonToken) then
                    DocUrl := CopyStr(JsonToken.AsValue().AsText(), 1, 2048);
                if (DocUrl = '') and JsonDocument.Get('document_url', JsonToken) then
                    DocUrl := CopyStr(JsonToken.AsValue().AsText(), 1, 2048);
                if (DocUrl = '') and JsonDocument.Get('document', JsonToken) and JsonToken.IsObject() then begin
                    JsonDocumentNested := JsonToken.AsObject();
                    if JsonDocumentNested.Get('url', JsonToken) then
                        DocUrl := CopyStr(JsonToken.AsValue().AsText(), 1, 2048);
                    if (DocUrl = '') and JsonDocumentNested.Get('document_url', JsonToken) then
                        DocUrl := CopyStr(JsonToken.AsValue().AsText(), 1, 2048);
                end;
            end else begin
                TextoDocumento := CopyStr(JsonToken.AsValue().AsText(), 1, 2500000);
                if EsUrlDocumentoOrden(TextoDocumento) then
                    DocUrl := CopyStr(TextoDocumento, 1, 2048)
                else
                    Base64Txt := TextoDocumento;
            end;
        end;

        if Base64Txt = '' then begin
            if JsonObj.Get('pdf', JsonToken) and JsonToken.IsValue() then begin
                TextoDocumento := CopyStr(JsonToken.AsValue().AsText(), 1, 2500000);
                if EsUrlDocumentoOrden(TextoDocumento) then
                    DocUrl := CopyStr(TextoDocumento, 1, 2048)
                else
                    Base64Txt := TextoDocumento;
            end;
            if (Base64Txt = '') and (DocUrl = '') and JsonObj.Get('adjunto', JsonToken) and JsonToken.IsValue() then begin
                TextoDocumento := CopyStr(JsonToken.AsValue().AsText(), 1, 2500000);
                if EsUrlDocumentoOrden(TextoDocumento) then
                    DocUrl := CopyStr(TextoDocumento, 1, 2048)
                else
                    Base64Txt := TextoDocumento;
            end;
        end;

        if (DocUrl = '') and (Base64Txt <> '') and EsUrlDocumentoOrden(Base64Txt) then begin
            DocUrl := CopyStr(Base64Txt, 1, 2048);
            Clear(Base64Txt);
        end;
    end;

    local procedure EsUrlDocumentoOrden(Texto: Text): Boolean
    begin
        exit((StrPos(LowerCase(Texto), 'https://') = 1) or (StrPos(LowerCase(Texto), 'http://') = 1));
    end;

    local procedure CargarPdfOrdenDesdeBase64(Base64Txt: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
        InS: InStream;
        Base64: Codeunit "Base64 Convert";
    begin
        QuitarPrefijoDataUrlBase64Orden(Base64Txt);
        if Base64Txt = '' then
            Error('El PDF del parte de trabajo está vacío.');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(Base64Txt, OutS);
        TempBlob.CreateInStream(InS);
        if InS.Length = 0 then
            Error('No se pudo decodificar el PDF del parte de trabajo.');
    end;

    local procedure ExtraerIdUrlOrdenJson(var JsonObj: JsonObject): Integer
    var
        JsonToken: JsonToken;
        JsonDocument: JsonObject;
        JsonDocumentNested: JsonObject;
        IdTexto: Text;
        IdUrl: Integer;
    begin
        if JsonObj.Get('idUrl', JsonToken) then
            exit(JsonToken.AsValue().AsInteger());
        if JsonObj.Get('id_url', JsonToken) then
            exit(JsonToken.AsValue().AsInteger());
        if JsonObj.Get('_id', JsonToken) then
            exit(JsonToken.AsValue().AsInteger());
        if JsonObj.Get('id', JsonToken) then begin
            if JsonToken.IsValue() then begin
                IdTexto := JsonToken.AsValue().AsText();
                if Evaluate(IdUrl, IdTexto) then
                    exit(IdUrl);
                exit(JsonToken.AsValue().AsInteger());
            end;
        end;

        if JsonObj.Get('document', JsonToken) and JsonToken.IsObject() then begin
            JsonDocument := JsonToken.AsObject();
            if JsonDocument.Get('_id', JsonToken) then
                exit(JsonToken.AsValue().AsInteger());
            if JsonDocument.Get('id', JsonToken) then begin
                IdTexto := JsonToken.AsValue().AsText();
                if Evaluate(IdUrl, IdTexto) then
                    exit(IdUrl);
                exit(JsonToken.AsValue().AsInteger());
            end;
            if JsonDocument.Get('idUrl', JsonToken) then
                exit(JsonToken.AsValue().AsInteger());
            if JsonDocument.Get('id_url', JsonToken) then
                exit(JsonToken.AsValue().AsInteger());
            if JsonDocument.Get('document', JsonToken) and JsonToken.IsObject() then begin
                JsonDocumentNested := JsonToken.AsObject();
                if JsonDocumentNested.Get('_id', JsonToken) then
                    exit(JsonToken.AsValue().AsInteger());
                if JsonDocumentNested.Get('id', JsonToken) then begin
                    IdTexto := JsonToken.AsValue().AsText();
                    if Evaluate(IdUrl, IdTexto) then
                        exit(IdUrl);
                    exit(JsonToken.AsValue().AsInteger());
                end;
                if JsonDocumentNested.Get('idUrl', JsonToken) then
                    exit(JsonToken.AsValue().AsInteger());
                if JsonDocumentNested.Get('id_url', JsonToken) then
                    exit(JsonToken.AsValue().AsInteger());
            end;
        end;

        exit(0);
    end;

    local procedure AdjuntarUrlParteTrabajo(ParteTrabajoNo: Code[20]; DocUrl: Text; IdUrl: Integer; NombreArchivo: Text)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        Doc: Record "Document Attachment";
        FileMgt: Codeunit "File Management";
        Line: Integer;
        NombreFiltro: Text;
    begin
        if not TimeSheetHeader.Get(ParteTrabajoNo) then
            Error('No existe el parte de trabajo %1.', ParteTrabajoNo);
        if DocUrl = '' then
            Error('No se ha indicado la URL del PDF del parte de trabajo.');

        Doc.SetRange("Table ID", Database::"Time Sheet Header");
        Doc.SetRange("No.", TimeSheetHeader."No.");
        Doc.SetRange("URL", DocUrl);
        if not Doc.FindFirst() then begin
            Doc.SetRange("URL");
            NombreFiltro := FileMgt.GetFileNameWithoutExtension(NombreArchivo);
            if NombreFiltro <> '' then
                Doc.SetFilter("File Name", '%1', NombreFiltro + '*')
            else
                Doc.SetRange("File Name");
            if not Doc.FindFirst() then begin
                Doc.SetRange("File Name");
                if Doc.FindLast() then
                    Line := Doc.Id + 1
                else
                    Line := 1;
                Doc.Init();
                Doc.Id := Line;
                Doc."Table ID" := Database::"Time Sheet Header";
                Doc."No." := TimeSheetHeader."No.";
                Doc."File Name" := CopyStr(NombreArchivo, 1, MaxStrLen(Doc."File Name"));
                Doc."File Extension" := CopyStr(DelChr(FileMgt.GetExtension(NombreArchivo), '<>', '.'), 1, MaxStrLen(Doc."File Extension"));
                Doc."URL" := CopyStr(DocUrl, 1, MaxStrLen(Doc."URL"));
                if IdUrl <> 0 then
                    Doc.ID_Url := IdUrl;
                Doc."Attached Date" := CurrentDateTime;
                Doc.Insert(true);
                exit;
            end;
        end;

        Doc."File Name" := CopyStr(NombreArchivo, 1, MaxStrLen(Doc."File Name"));
        Doc."File Extension" := CopyStr(DelChr(FileMgt.GetExtension(NombreArchivo), '<>', '.'), 1, MaxStrLen(Doc."File Extension"));
        Doc."URL" := CopyStr(DocUrl, 1, MaxStrLen(Doc."URL"));
        if IdUrl <> 0 then
            Doc.ID_Url := IdUrl;
        Doc."Attached Date" := CurrentDateTime;
        Doc.Modify(true);
    end;

    local procedure ExtraerNombreArchivoOrdenJson(var JsonObj: JsonObject; ParteTrabajoNo: Code[20]; DocUrl: Text): Text
    var
        JsonToken: JsonToken;
        JsonDocument: JsonObject;
        NombreArchivo: Text;
    begin
        if JsonObj.Get('fileName', JsonToken) then
            NombreArchivo := CopyStr(JsonToken.AsValue().AsText(), 1, 250);
        if (NombreArchivo = '') and JsonObj.Get('file_name', JsonToken) then
            NombreArchivo := CopyStr(JsonToken.AsValue().AsText(), 1, 250);
        if (NombreArchivo = '') and JsonObj.Get('document', JsonToken) and JsonToken.IsObject() then begin
            JsonDocument := JsonToken.AsObject();
            if JsonDocument.Get('name', JsonToken) then
                NombreArchivo := CopyStr(JsonToken.AsValue().AsText(), 1, 250);
        end;
        if (NombreArchivo = '') and (DocUrl <> '') then
            NombreArchivo := ExtraerNombreArchivoDesdeUrlOrden(DocUrl);
        if NombreArchivo = '' then
            NombreArchivo := StrSubstNo('OrdenTrabajo_%1.pdf', ParteTrabajoNo);
        if StrPos(LowerCase(NombreArchivo), '.pdf') = 0 then
            NombreArchivo += '.pdf';
        exit(NombreArchivo);
    end;

    local procedure ExtraerNombreArchivoDesdeUrlOrden(Url: Text): Text
    var
        Pos: Integer;
        NombreArchivo: Text;
    begin
        Pos := StrLen(Url);
        while (Pos > 0) and (CopyStr(Url, Pos, 1) <> '/') do
            Pos -= 1;
        if Pos = 0 then
            exit('');
        NombreArchivo := CopyStr(Url, Pos + 1, StrLen(Url) - Pos);
        if StrPos(NombreArchivo, '?') > 0 then
            NombreArchivo := CopyStr(NombreArchivo, 1, StrPos(NombreArchivo, '?') - 1);
        exit(CopyStr(NombreArchivo, 1, 250));
    end;

    local procedure AdjuntarPdfParteTrabajo(ParteTrabajoNo: Code[20]; var InS: InStream; NombreArchivo: Text)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        RecRef: RecordRef;
        Doc: Record "Document Attachment";
        FileMgt: Codeunit "File Management";
        NombreSinExtension: Text;
        Extension: Text;
    begin
        if not TimeSheetHeader.Get(ParteTrabajoNo) then
            Error('No existe el parte de trabajo %1.', ParteTrabajoNo);

        if InS.Length = 0 then
            Error('El PDF del parte de trabajo está vacío.');

        NombreSinExtension := FileMgt.GetFileNameWithoutExtension(NombreArchivo);
        Extension := FileMgt.GetExtension(NombreArchivo);
        if Extension = '' then
            Extension := '.pdf';

        Doc.SetRange("Table ID", Database::"Time Sheet Header");
        Doc.SetRange("No.", TimeSheetHeader."No.");
        Doc.SetRange("File Name", CopyStr(NombreSinExtension, 1, MaxStrLen(Doc."File Name")));
        Doc.SetRange("File Extension", CopyStr(DelChr(Extension, '<>', '.'), 1, MaxStrLen(Doc."File Extension")));
        if Doc.FindSet() then
            Doc.DeleteAll(true);

        RecRef.GetTable(TimeSheetHeader);
        Doc.SaveAttachmentFromStream(InS, RecRef, NombreArchivo);
    end;

    local procedure QuitarPrefijoDataUrlBase64Orden(var Base64Txt: Text)
    var
        Pos: Integer;
    begin
        Pos := StrPos(Base64Txt, ';base64,');
        if Pos > 0 then
            Base64Txt := CopyStr(Base64Txt, Pos + 8, StrLen(Base64Txt));
    end;

    local procedure AgregarAdjuntosYFacturaOrdenJson(ParteTrabajoNo: Code[20]; var JsonLinea: JsonObject)
    var
        JsonAdjuntos: JsonArray;
        JsonFactura: JsonObject;
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        Clear(JsonAdjuntos);
        RecopilarAdjuntosParteTrabajo(ParteTrabajoNo, JsonAdjuntos);
        JsonLinea.Add('adjuntos', JsonAdjuntos.AsToken());

        Clear(JsonFactura);
        if TimeSheetHeader.Get(ParteTrabajoNo) and (TimeSheetHeader."Id Factura" <> '') and RellenarFacturaPdfJson(TimeSheetHeader, JsonFactura) then
            JsonLinea.Add('factura', JsonFactura.AsToken())
        else begin
            Clear(JsonFactura);
            JsonFactura.Add('disponible', false);
            JsonLinea.Add('factura', JsonFactura.AsToken());
        end;
    end;

    local procedure RecopilarAdjuntosParteTrabajo(ParteTrabajoNo: Code[20]; var JsonAdjuntos: JsonArray)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        Doc: Record "Document Attachment";
        JsonAdj: JsonObject;
        Base64Txt: Text;
        ClavesProcesadas: Text;
        Clave: Text;
    begin
        if not TimeSheetHeader.Get(ParteTrabajoNo) then
            exit;
        //repeat
        //if TimeSheetLine."Job No." <> '' then begin
        Doc.Reset();
        Doc.SetRange("Table ID", Database::"Time Sheet Header");
        Doc.SetRange("No.", TimeSheetHeader."No.");
        if Doc.FindSet() then
            repeat
                Clave := Format(Doc.SystemId);
                if StrPos('|' + ClavesProcesadas + '|', '|' + Clave + '|') = 0 then begin
                    ClavesProcesadas += Clave + '|';
                    Base64Txt := DocumentAttachmentToBase64Local(Doc);
                    if Base64Txt <> '' then begin
                        Clear(JsonAdj);
                        JsonAdj.Add('fileName', Doc."File Name");
                        JsonAdj.Add('fileExtension', Doc."File Extension");
                        JsonAdj.Add('document', Base64Txt);
                        JsonAdjuntos.Add(JsonAdj);
                    end;
                end;
            until Doc.Next() = 0;
        // end;
        //until TimeSheetLine.Next() = 0;
    end;

    local procedure DocumentAttachmentToBase64Local(var DocumentAttachment: Record "Document Attachment"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Int: InStream;
        DocOut: OutStream;
        Bs64: Codeunit "Base64 Convert";
    begin
        if DocumentAttachment."Document Reference ID".HasValue then begin
            TempBlob.CreateOutStream(DocOut);
            DocumentAttachment."Document Reference ID".ExportStream(DocOut);
            TempBlob.CreateInStream(Int);
            exit(Bs64.ToBase64(Int));
        end;
        if DocumentAttachment.Url <> '' then
            exit(DocumentAttachment.ToBase64StringOcr(DocumentAttachment.Url));
        exit('');
    end;

    local procedure RellenarFacturaPdfJson(var TimeSheetHeader: Record "Time Sheet Header"; var JsonFactura: JsonObject): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Bs64: Codeunit "Base64 Convert";
        RecRef: RecordRef;
        PdfBase64: Text;
    begin
        Clear(JsonFactura);
        if TimeSheetHeader."Id Factura" = '' then
            exit(false);
        SalesInvHeader.SetRange("Pre-Assigned No.", TimeSheetHeader."Id Factura");
        if not SalesInvHeader.FindFirst() then
            exit(false);

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        if not ReportSelections.FindFirst() then
            exit(false);

        RecRef.GetTable(SalesInvHeader);
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ReportSelections."Report ID", '', ReportFormat::Pdf, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        PdfBase64 := Bs64.ToBase64(InStr);
        if PdfBase64 = '' then
            exit(false);
        JsonFactura.Add('disponible', true);
        JsonFactura.Add('no', SalesInvHeader."No.");
        JsonFactura.Add('fileName', StrSubstNo('Factura_%1.pdf', SalesInvHeader."No."));
        JsonFactura.Add('document', PdfBase64);
        exit(true);
    end;

    [ServiceEnabled]
    procedure UpdateParadaBus(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        Emplazamientos: Record "Emplazamientos";
        IdParada: Text;
    begin
        //{"id": "codigoparada", "description": "nueva descripcion","Direccion": "nueva direccion","Tipo Parada": "nueva tipo parada","Tipo Banco": "nueva tipo banco","Sae": "nuevo sae","puntoX": "xxx", "puntoY": "yyy"}
        if JsonObject.ReadFrom(JsonText) then begin
            if JsonObject.Get('id', JsonToken) then
                IdParada := JsonToken.AsValue().AsText();

            if Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, IdParada) then begin
                if JsonObject.Get('description', JsonToken) then
                    Emplazamientos.Validate("Descripción", CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Emplazamientos."Descripción")));

                if JsonObject.Get('Direccion', JsonToken) then
                    Emplazamientos.Validate("Ubicación", CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Emplazamientos."Ubicación")));

                if JsonObject.Get('Tipo Parada', JsonToken) then begin
                    case JsonToken.AsValue().AsText() of
                        ' ':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::" ");
                        '2xMa-4':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"2xMa-4");
                        'Ma-10':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Ma-10");
                        'Ma-10 (modelo nuevo)':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Ma-10 (modelo nuevo)");
                        'Ma-2':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Ma-2");
                        'Ma-2 (modelo nuevo)':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Ma-2 (modelo nuevo)");
                        'Ma-4':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Ma-4");
                        'Ma-4 (modelo nuevo)':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Ma-4 (modelo nuevo)");
                        'Ma-6':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Ma-6");
                        '10':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::PA);
                        'Pal·li*':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"Pal·li*");
                        'PI':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::PI);
                        'PI/CEL':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"PI/CEL");
                        'PI/MACO':
                            Emplazamientos.Validate("Tipo Parada", Emplazamientos."Tipo Parada"::"PI/MACO");
                    end;
                end;


                If JsonObject.Get('Tipo Banco', JsonToken) then
                    case JsonToken.AsValue().AsText() of
                        'No':
                            Emplazamientos.Validate("Tipo Banco", Emplazamientos."Tipo Banco"::No);
                        '(2) Modelo 3 listones':
                            Emplazamientos.Validate("Tipo Banco", Emplazamientos."Tipo Banco"::"(2) Modelo 3 listones");
                        '(2) Modelo 6 listones':
                            Emplazamientos.Validate("Tipo Banco", Emplazamientos."Tipo Banco"::"(2) Modelo 6 listones");
                        'Modelo 18 listones':
                            Emplazamientos.Validate("Tipo Banco", Emplazamientos."Tipo Banco"::"Modelo 18 listones");
                        'Modelo 3 listones':
                            Emplazamientos.Validate("Tipo Banco", Emplazamientos."Tipo Banco"::"Modelo 3 listones");
                        'Modelo 6 listones':
                            Emplazamientos.Validate("Tipo Banco", Emplazamientos."Tipo Banco"::"Modelo 6 listones");
                    end;


                If JsonObject.Get('Sae', JsonToken) then begin
                    Emplazamientos.Validate(Sae, false);
                    If JsonToken.AsValue().AsText() = 'true' then
                        Emplazamientos.Validate(Sae, true);
                    If JsonToken.AsValue().AsText() = '1' then
                        Emplazamientos.Validate(Sae, true);
                    If UpperCase(JsonToken.AsValue().AsText()) = 'SI' then
                        Emplazamientos.Validate(Sae, true);


                end;

                if JsonObject.Get('puntoX', JsonToken) then
                    Emplazamientos.Validate(PuntoX, JsonToken.AsValue().AsDecimal());

                if JsonObject.Get('puntoY', JsonToken) then
                    Emplazamientos.Validate(PuntoY, JsonToken.AsValue().AsDecimal());

                Emplazamientos.Modify(true);
                exit('OK');
            end else begin
                Error('404: Parada no encontrada: %1', IdParada);
            end;
        end else
            Error('JSON inválido');
    end;

    /// <summary>
    /// Endpoint para asignar (impostar) la zona de limpieza a emplazamientos paradas bus.
    /// Acepta un objeto con una parada o un array de paradas.
    /// Formato objeto: {"id": "P123", "zonaLimpieza": 1}
    /// Formato array: [{"id": "P1", "zonaLimpieza": 1}, {"id": "P2", "zonaLimpieza": 2}]
    /// </summary>
    /// <param name="JsonText">JSON con id (código parada) y zonaLimpieza (entero)</param>
    /// <returns>JSON con actualizados y errores: {"actualizados": 2, "errores": [{"id": "P99", "mensaje": "Parada no encontrada"}]}</returns>
    [ServiceEnabled]
    procedure ImportarZonaLimpiezaParadasBus(JsonText: Text): Text
    var
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonTarea: JsonObject;
        JsonResult: JsonObject;
        JsonErrores: JsonArray;
        Emplazamientos: Record "Emplazamientos";
        Actualizados: Integer;
        ResponseText: Text;
    begin
        Actualizados := 0;
        Clear(JsonResult);
        Clear(JsonErrores);

        // Puede ser un objeto único o un array
        if JsonArray.ReadFrom(JsonText) then begin
            // Es un array: [{"id": "P1", "zonaLimpieza": 1}, ...]
            foreach JsonToken in JsonArray do begin
                JsonTarea := JsonToken.AsObject();
                if Procesos_GTask.ProcesarZonaLimpiezaParada(JsonTarea, Emplazamientos, JsonErrores) then
                    Actualizados += 1;
            end;
        end else
            if JsonObject.ReadFrom(JsonText) then begin
                // Es un objeto único: {"id": "P123", "zonaLimpieza": "plaza españa"}
                if Procesos_GTask.ProcesarZonaLimpiezaParada(JsonObject, Emplazamientos, JsonErrores) then
                    Actualizados += 1;
            end else
                Error('JSON inválido. Se espera un objeto {"id": "...", "zonaLimpieza": n} o un array de objetos.');

        JsonResult.Add('actualizados', Actualizados);
        JsonResult.Add('errores', JsonErrores);
        JsonResult.WriteTo(ResponseText);
        exit(ResponseText);
    end;

    /// <summary>
    /// Devuelve todos los documentos adjuntos de imagen de un proyecto
    /// </summary>
    /// <param name="JsonText">JSON con el campo "numero_proyecto" o "proyecto"</param>
    /// <returns>JSON array con objetos que contienen "nombre" y "url" de cada imagen</returns>
    [ServiceEnabled]
    procedure GetImagenesProyecto(JsonText: Text): Text
    var
        JsonObj: JsonObject;
        JsonCampo: JsonToken;
        DocumentAttachment: Record "Document Attachment";
        Job: Record Job;
        JobS: Record Job;
        ResultArray: JsonArray;
        DocumentJson: JsonObject;
        NumeroProyecto: Code[20];
        FileExtension: Text;
        FileName: Text;
        ResponseText: Text;
        ExtensionesImagen: List of [Text];
        ExtensionLower: Text;
        IsImage: Boolean;
        FileManager: Codeunit "File Management";
        RecursoNo: Text;
        Empresa: Text;
        JobsOtrasEmpresas: Record Job temporary;
        Empresas: Record "Company";
        Resource: Record Resource;
        DocOrdenFijacion: Record "Document Attachment";
        OrdenFijacion: Record "Orden fijación";
        FechaCapturaDT: DateTime;
        FechaFijacion: Date;
        EmpresaDoc: Text;
    begin
        // Inicializar lista de extensiones de imagen
        ExtensionesImagen.Add('jpg');
        ExtensionesImagen.Add('jpeg');
        ExtensionesImagen.Add('png');
        ExtensionesImagen.Add('gif');
        ExtensionesImagen.Add('bmp');
        ExtensionesImagen.Add('webp');
        ExtensionesImagen.Add('svg');
        ExtensionesImagen.Add('tiff');
        ExtensionesImagen.Add('tif');

        // Leer el JSON de entrada
        if not JsonObj.ReadFrom(JsonText) then begin
            Clear(ResultArray);
            ResultArray.WriteTo(ResponseText);
            exit(ResponseText);
        end;
        if JsonObj.Get('empresa', JsonCampo) then
            Empresa := JsonCampo.AsValue().AsText();
        if Empresa <> '' then
            Job.ChangeCompany(Empresa);

        // Obtener el número del proyecto
        NumeroProyecto := '';
        if JsonObj.Get('numero_proyecto', JsonCampo) then
            NumeroProyecto := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(NumeroProyecto))
        else
            if JsonObj.Get('proyecto', JsonCampo) then
                NumeroProyecto := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(NumeroProyecto));

        if NumeroProyecto = '' then begin
            Clear(ResultArray);
            ResultArray.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        // Verificar que el proyecto existe
        if not Job.Get(NumeroProyecto) then begin
            Clear(ResultArray);
            ResultArray.WriteTo(ResponseText);
            exit(ResponseText);
        end;
        JobsOtrasEmpresas."No." := Job."No.";
        JobsOtrasEmpresas."Empresa Origen" := Empresa;
        JobsOtrasEmpresas.Insert();
        Empresas.FindSet;
        Repeat
            Jobs.ChangeCompany(Empresas.Name);
            Jobs.SetRange("Proyecto en empresa Origen", Job."No.");
            If Empresa = '' then
                JobS.SetRange("Empresa Origen", CompanyName)
            else
                Jobs.SetRange("Empresa Origen", Empresa);
            If Jobs.FindSet() then begin
                JobsOtrasEmpresas."No." := Jobs."No.";
                JobsOtrasEmpresas."Empresa Origen" := Empresas.Name;
                JobsOtrasEmpresas.Insert();
            end;
        Until Empresas.Next = 0;
        if JobsOtrasEmpresas.FindSet() then begin
            // Buscar documentos adjuntos del proyecto
            Clear(ResultArray);
            repeat

                DocumentAttachment.Reset();
                if JobsOtrasEmpresas."Empresa Origen" <> '' then
                    DocumentAttachment.ChangeCompany(JobsOtrasEmpresas."Empresa Origen")
                else
                    DocumentAttachment.ChangeCompany(CompanyName);
                DocumentAttachment.SetRange("Table ID", Database::Job);
                DocumentAttachment.SetRange("No.", NumeroProyecto);

                if DocumentAttachment.FindSet() then begin
                    repeat
                        // Obtener extensión del archivo
                        FileExtension := LowerCase(DocumentAttachment."File Extension");
                        FileName := DocumentAttachment."File Name";

                        // Verificar si la extensión es de imagen
                        IsImage := false;
                        foreach ExtensionLower in ExtensionesImagen do begin
                            if FileExtension = ExtensionLower then begin
                                IsImage := true;
                                break;
                            end;
                        end;

                        // Si no tiene extensión, verificar si el nombre termina en extensión de imagen
                        if (not IsImage) and (FileExtension = '') then begin
                            FileName := LowerCase(FileName);
                            foreach ExtensionLower in ExtensionesImagen do begin
                                if FileName.EndsWith('.' + ExtensionLower) then begin
                                    IsImage := true;
                                    break;
                                end;
                            end;
                        end;

                        // Si es imagen, agregar al resultado
                        if IsImage then begin
                            Clear(DocumentJson);
                            DocumentJson.Add('nombre', DocumentAttachment."File Name");
                            DocumentJson.Add('url', DocumentAttachment."URL");

                            // Fecha de captura / adjunto de la foto
                            FechaCapturaDT := DocumentAttachment."Attached Date";
                            if FechaCapturaDT = 0DT then
                                FechaCapturaDT := DocumentAttachment.SystemCreatedAt;
                            if FechaCapturaDT <> 0DT then
                                DocumentJson.Add('fecha_captura', Format(DT2Date(FechaCapturaDT), 0, 9));

                            // Fecha de fijación y tipo de soporte vía orden / recurso
                            FechaFijacion := 0D;
                            EmpresaDoc := JobsOtrasEmpresas."Empresa Origen";
                            if EmpresaDoc = '' then
                                EmpresaDoc := CompanyName;

                            DocOrdenFijacion.Reset();
                            DocOrdenFijacion.ChangeCompany(EmpresaDoc);
                            DocOrdenFijacion.SetRange("Table ID", Database::"Orden fijación");
                            DocOrdenFijacion.SetRange("No.", DocumentAttachment."No.");
                            DocOrdenFijacion.SetRange("File Name", DocumentAttachment."File Name");
                            if DocOrdenFijacion.FindFirst() then begin
                                OrdenFijacion.Reset();
                                OrdenFijacion.ChangeCompany(EmpresaDoc);
                                OrdenFijacion.SetRange("Nº Reserva", DocOrdenFijacion."Line No.");
                                if OrdenFijacion.FindFirst() then
                                    FechaFijacion := OrdenFijacion."Fecha fijación";
                            end;
                            if FechaFijacion <> 0D then
                                DocumentJson.Add('fecha_fijacion', Format(FechaFijacion, 0, 9));

                            RecursoNo := Procesos_GTask.GetRecursoNo(DocumentAttachment, JobsOtrasEmpresas."Empresa Origen");
                            If RecursoNo <> '' then begin
                                DocumentJson.Add('recurso', RecursoNo);
                                Resource.ChangeCompany(EmpresaDoc);
                                if Resource.Get(RecursoNo) then begin
                                    DocumentJson.Add('resource', Resource.Name);
                                    DocumentJson.Add('puntox', Resource.PuntoX);
                                    DocumentJson.Add('puntoy', Resource.PuntoY);
                                    DocumentJson.Add('tipo_soporte', Resource."Tipo Recurso");
                                end;
                            end;
                            if DocumentAttachment.Url <> '' then
                                ResultArray.Add(DocumentJson);
                        end;
                    until DocumentAttachment.Next() = 0;
                end;
            until JobsOtrasEmpresas.Next() = 0;

            // Convertir a texto JSON
            ResultArray.WriteTo(ResponseText);
        end;
        exit(ResponseText);
    end;

    local procedure LeerTextoJsonParte(JsonObj: JsonObject; Campo: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if not JsonObj.Get(Campo, JsonToken) then
            exit('');
        if not JsonToken.IsValue() then
            exit('');
        if JsonToken.AsValue().IsNull() then
            exit('');
        exit(DelChr(JsonToken.AsValue().AsText(), '<>', ' '));
    end;

    local procedure BuscarUserTaskPorClave(Clave: Text; var UserTask: Record "User Task"): Boolean
    var
        IdEntero: Integer;
    begin
        Clave := DelChr(Clave, '<>', ' ');
        if Clave = '' then
            exit(false);
        UserTask.Reset();
        if Evaluate(IdEntero, Clave) then
            if UserTask.Get(IdEntero) then
                exit(true);
        UserTask.Reset();
        UserTask.SetRange(Id_Tarea, CopyStr(Clave, 1, MaxStrLen(UserTask.Id_Tarea)));
        exit(UserTask.FindFirst());
    end;

    local procedure EsOrigenCatalogoParte(Origen: Text): Boolean
    begin
        Origen := LowerCase(DelChr(Origen, '<>', ' '));
        exit(
            (Origen = 'mobiliario') or (Origen = 'recurso') or (Origen = 'emplazamiento') or
            (Origen = 'emplazamientos') or (Origen = 'mantenimiento'));
    end;

    local procedure BuscarMantenimientoAbiertoParte(CodigoEmplaz: Code[20]; NoRecurso: Code[20]; var Incidencia: Record Incidencias): Boolean
    var
        Emplaz: Record Emplazamientos;
        NoInc: Code[20];
    begin
        NoInc := '';
        if NoRecurso <> '' then
            NoInc := BuscarNoIncidenciaMantenimientoRecursoAbierta(NoRecurso);
        if (NoInc = '') and (CodigoEmplaz <> '') then
            if BuscarEmplazamientoPorTipoONo('', CodigoEmplaz, Emplaz) then
                NoInc := BuscarNoIncidenciaMantenimientoAbierta(Emplaz);
        if NoInc = '' then
            exit(false);
        exit(Incidencia.Get(NoInc));
    end;

    local procedure CrearMantenimientoSiNoExisteParte(CodigoEmplaz: Code[20]; NoRecurso: Code[20]; Descripcion: Text; var Incidencia: Record Incidencias): Boolean
    var
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        NoInc: Code[20];
    begin
        NoInc := '';
        if NoRecurso <> '' then begin
            if not Resource.Get(NoRecurso) then
                exit(false);
            NoInc := CrearIncidenciaMantenimientoRecurso(Resource, Descripcion, false);
        end else begin
            if CodigoEmplaz = '' then
                exit(false);
            if not BuscarEmplazamientoPorTipoONo('', CodigoEmplaz, Emplaz) then
                exit(false);
            NoInc := CrearIncidenciaMantenimientoEmplazamiento(Emplaz);
        end;
        if NoInc = '' then
            exit(false);
        exit(Incidencia.Get(NoInc));
    end;

    /// <summary>
    /// Si la incidencia ya tiene tarea, la devuelve. Si CrearTarea y falta, publica la tarea GTask.
    /// NoParte queda con el parte ya ligado a la incidencia, si existe.
    /// </summary>
    local procedure ParteDeIncidencia(var Incidencia: Record Incidencias; var UserTask: Record "User Task"; var NoParte: Code[20]; CrearTarea: Boolean): Boolean
    var
        IdTarea: Text;
    begin
        Incidencia.Get(Incidencia."No.");
        NoParte := Incidencia."Parte Trabajo";
        if BuscarTareaDeIncidencia(Incidencia, UserTask) then
            exit(true);
        if not CrearTarea then
            exit(NoParte <> '');

        if Incidencia."Parte Trabajo" = '' then
            AsegurarParteMantenimiento(Incidencia);
        Incidencia.Get(Incidencia."No.");
        NoParte := Incidencia."Parte Trabajo";
        if BuscarTareaDeIncidencia(Incidencia, UserTask) then
            exit(true);

        if Incidencia."Parte Trabajo" <> '' then
            LigarTareaConOrden(Incidencia)
        else begin
            IdTarea := AsegurarTareaGtaskIncidencia(Incidencia);
            if (IdTarea = '') or (CopyStr(IdTarea, 1, 5) = 'Error') or (StrLen(IdTarea) > 30) then
                exit(false);
        end;
        Incidencia.Get(Incidencia."No.");
        NoParte := Incidencia."Parte Trabajo";
        exit(BuscarTareaDeIncidencia(Incidencia, UserTask) or (NoParte <> ''));
    end;

    /// <summary>
    /// Localiza la User Task del parte. Si CrearSiNoExiste y el origen es catálogo SQL o calendario
    /// sin tarea, reutiliza el mantenimiento abierto o lo crea (incidencia + tarea + parte).
    /// </summary>
    local procedure ResolverTareaParteJson(JsonObj: JsonObject; CrearSiNoExiste: Boolean; var UserTask: Record "User Task"; var NoParte: Code[20]): Boolean
    var
        IdTareaTxt: Text;
        NumeroTarea: Text;
        NoIncidencia: Text;
        Origen: Text;
        CodigoEmplaz: Code[20];
        NoRecurso: Code[20];
        Descripcion: Text;
        Incidencia: Record Incidencias;
    begin
        Clear(UserTask);
        NoParte := '';
        IdTareaTxt := LeerTextoJsonParte(JsonObj, 'id_tarea');
        if IdTareaTxt = '' then
            IdTareaTxt := LeerTextoJsonParte(JsonObj, 'idTarea');
        NumeroTarea := LeerTextoJsonParte(JsonObj, 'numero_tarea');
        NoIncidencia := LeerTextoJsonParte(JsonObj, 'no_incidencia');
        if NoIncidencia = '' then
            NoIncidencia := LeerTextoJsonParte(JsonObj, 'noIncidencia');
        Origen := LowerCase(LeerTextoJsonParte(JsonObj, 'origen'));
        CodigoEmplaz := CopyStr(LeerTextoJsonParte(JsonObj, 'codigo_emplazamiento'), 1, MaxStrLen(CodigoEmplaz));
        if CodigoEmplaz = '' then
            CodigoEmplaz := CopyStr(LeerTextoJsonParte(JsonObj, 'codigoEmplazamiento'), 1, MaxStrLen(CodigoEmplaz));
        NoRecurso := CopyStr(LeerTextoJsonParte(JsonObj, 'no_recurso'), 1, MaxStrLen(NoRecurso));
        if NoRecurso = '' then
            NoRecurso := CopyStr(LeerTextoJsonParte(JsonObj, 'noRecurso'), 1, MaxStrLen(NoRecurso));
        Descripcion := LeerTextoJsonParte(JsonObj, 'descripcion');

        if (IdTareaTxt <> '') and BuscarUserTaskPorClave(IdTareaTxt, UserTask) then begin
            Incidencia.Reset();
            Incidencia.SetRange("ID Tarea Gtask", CopyStr(IdTareaTxt, 1, MaxStrLen(Incidencia."ID Tarea Gtask")));
            if not Incidencia.FindFirst() then begin
                Incidencia.Reset();
                Incidencia.SetRange(Id_Tarea, UserTask.ID);
                if not Incidencia.FindFirst() then
                    Clear(Incidencia);
            end;
            if Incidencia."No." <> '' then
                NoParte := Incidencia."Parte Trabajo";
            exit(true);
        end;

        if (NumeroTarea <> '') and BuscarUserTaskPorClave(NumeroTarea, UserTask) then begin
            Incidencia.Reset();
            Incidencia.SetRange(Id_Tarea, UserTask.ID);
            if Incidencia.FindFirst() then
                NoParte := Incidencia."Parte Trabajo"
            else
                if (UserTask.Id_Tarea <> '') then begin
                    Incidencia.Reset();
                    Incidencia.SetRange("ID Tarea Gtask", CopyStr(UserTask.Id_Tarea, 1, MaxStrLen(Incidencia."ID Tarea Gtask")));
                    if Incidencia.FindFirst() then
                        NoParte := Incidencia."Parte Trabajo";
                end;
            exit(true);
        end;

        if (NoIncidencia <> '') and Incidencia.Get(CopyStr(NoIncidencia, 1, MaxStrLen(Incidencia."No."))) then
            exit(ParteDeIncidencia(Incidencia, UserTask, NoParte, CrearSiNoExiste));

        if EsOrigenCatalogoParte(Origen) then
            if BuscarMantenimientoAbiertoParte(CodigoEmplaz, NoRecurso, Incidencia) then
                exit(ParteDeIncidencia(Incidencia, UserTask, NoParte, CrearSiNoExiste));

        if not CrearSiNoExiste then
            exit(false);
        if not EsOrigenCatalogoParte(Origen) then
            exit(false);
        if not CrearMantenimientoSiNoExisteParte(CodigoEmplaz, NoRecurso, Descripcion, Incidencia) then
            Error('No se ha podido crear la tarea de mantenimiento para %1.', CodigoEmplaz + NoRecurso);
        exit(ParteDeIncidencia(Incidencia, UserTask, NoParte, true));
    end;

    /// <summary>
    /// Recupera un parte de trabajo existente desde BC por tarea GTask, incidencia o código de catálogo.
    /// Entrada: numero_tarea, id_tarea, no_incidencia, origen, codigo_emplazamiento, no_recurso y fecha opcional.
    /// Salida: JSON del parte o "{}" si no existe. No crea tarea ni parte.
    /// </summary>
    [ServiceEnabled]
    procedure GetParteTrabajo(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonOut: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonLine: JsonObject;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        UserTask: Record "User Task";
        Item: Record Item;
        Resource: Record Resource;
        FechaTexto: Text;
        Fecha: Date;
        NoParteExistente: Code[20];
        ResultText: Text;
    begin
        Clear(JsonOut);
        if (JsonText = '') or not JsonIn.ReadFrom(JsonText) then begin
            JsonOut.WriteTo(ResultText);
            exit(ResultText);
        end;

        Fecha := 0D;
        if JsonIn.Get('fecha', JsonToken) then begin
            FechaTexto := JsonToken.AsValue().AsText();
            if not Evaluate(Fecha, FechaTexto) then
                Fecha := 0D;
        end;

        if not ResolverTareaParteJson(JsonIn, false, UserTask, NoParteExistente) then begin
            JsonOut.WriteTo(ResultText);
            exit(ResultText);
        end;

        TimeSheetHeader.Reset();
        if (NoParteExistente <> '') and TimeSheetHeader.Get(NoParteExistente) then begin
            // Parte ya ligado a la incidencia. No se filtra por fecha.
        end else begin
            if UserTask.ID = 0 then begin
                JsonOut.WriteTo(ResultText);
                exit(ResultText);
            end;
            TimeSheetHeader.Reset();
            TimeSheetHeader.SetRange(Tipo, TimeSheetHeader.Tipo::Trabajo);
            TimeSheetHeader.SetRange(Estado, TimeSheetHeader.Estado::Abierto);
            TimeSheetHeader.SetRange(Tarea, UserTask.ID);
            if Fecha <> 0D then
                TimeSheetHeader.SetRange("Fecha Inicio", Fecha);
            if not TimeSheetHeader.FindFirst() then begin
                JsonOut.WriteTo(ResultText);
                exit(ResultText);
            end;
        end;

        if TimeSheetHeader."No." = '' then begin
            JsonOut.WriteTo(ResultText);
            exit(ResultText);
        end;

        if UserTask.ID <> 0 then
            JsonOut.Add('numero_tarea', Format(UserTask.ID))
        else
            JsonOut.Add('numero_tarea', '');
        if UserTask.Id_Tarea <> '' then
            JsonOut.Add('id_tarea', UserTask.Id_Tarea);
        JsonOut.Add('parada_emplazamiento', TimeSheetHeader.Description);
        JsonOut.Add('fecha', Format(TimeSheetHeader."Fecha Inicio", 0, 9));
        JsonOut.Add('descripcion', TimeSheetHeader.Description);
        JsonOut.Add('cliente', TimeSheetHeader.Cliente);
        JsonOut.Add('no_parte', TimeSheetHeader."No.");

        Clear(JsonArray);
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        if TimeSheetLine.FindSet() then
            repeat
                Clear(JsonLine);
                if TimeSheetLine.Tipo = TimeSheetLine.Tipo::Producto then
                    JsonLine.Add('tipo', 'producto')
                else
                    if TimeSheetLine.Tipo = TimeSheetLine.Tipo::Recurso then
                        JsonLine.Add('tipo', 'recurso')
                    else
                        JsonLine.Add('tipo', 'producto');
                JsonLine.Add('codigo', TimeSheetLine.No);
                JsonLine.Add('nombre', TimeSheetLine.Descripcion);
                JsonLine.Add('cantidad', TimeSheetLine.Cantidad);
                if Item.Get(TimeSheetLine.No) then
                    JsonLine.Add('precio', Item."Unit Price")
                else
                    if Resource.Get(TimeSheetLine.No) then
                        JsonLine.Add('precio', Resource."Unit Price")
                    else
                        JsonLine.Add('precio', 0);
                JsonArray.Add(JsonLine);
            until TimeSheetLine.Next() = 0;
        JsonOut.Add('lineas', JsonArray.AsToken());
        JsonOut.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Ok de la orden: el parte pasa a Cerrado. Si ya está Facturado, no se modifica.
    /// JSON: {"no_parte":"..."} o {"parteTrabajo":"..."}.
    /// </summary>
    [ServiceEnabled]
    procedure CerrarParteTrabajo(JsonText: Text): Text
    var
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JsonResult: JsonObject;
        TimeSheetHeader: Record "Time Sheet Header";
        NoParte: Code[20];
        ResultText: Text;
    begin
        if (JsonText = '') or not JsonObj.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        if JsonObj.Get('no_parte', JsonToken) then
            NoParte := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoParte));
        if (NoParte = '') and JsonObj.Get('parteTrabajo', JsonToken) then
            NoParte := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoParte));
        if NoParte = '' then
            Error('No se ha indicado el parte de trabajo.');
        if not TimeSheetHeader.Get(NoParte) then
            Error('No existe el parte de trabajo %1.', NoParte);

        Clear(JsonResult);
        JsonResult.Add('no_parte', TimeSheetHeader."No.");
        if TimeSheetHeader.Estado = TimeSheetHeader.Estado::Facturado then begin
            JsonResult.Add('ok', false);
            JsonResult.Add('estado', Format(TimeSheetHeader.Estado));
            JsonResult.Add('mensaje', 'La orden está facturada y no se modifica.');
        end else begin
            if TimeSheetHeader.Estado <> TimeSheetHeader.Estado::Cerrado then begin
                TimeSheetHeader.Estado := TimeSheetHeader.Estado::Cerrado;
                TimeSheetHeader.Modify();
            end;
            JsonResult.Add('ok', true);
            JsonResult.Add('success', true);
            JsonResult.Add('estado', Format(TimeSheetHeader.Estado));
        end;
        JsonResult.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure AdjuntarImagenesParteDesdeJson(ParteNo: Code[20]; JsonObj: JsonObject)
    var
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonLine: JsonObject;
        i: Integer;
        Url: Text;
        Nombre: Text;
        IdTxt: Text;
        IdUrl: Integer;
    begin
        if ParteNo = '' then
            exit;
        if not JsonObj.Get('imagenes', JsonToken) then
            exit;
        if not JsonToken.IsArray() then
            exit;
        JsonArray := JsonToken.AsArray();
        for i := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(i, JsonToken);
            if JsonToken.IsObject() then begin
                JsonLine := JsonToken.AsObject();
                Url := '';
                Nombre := '';
                IdUrl := 0;
                if JsonLine.Get('url', JsonToken) and JsonToken.IsValue() and not JsonToken.AsValue().IsNull() then
                    Url := DelChr(JsonToken.AsValue().AsText(), '<>', ' ');
                if JsonLine.Get('nombre', JsonToken) and JsonToken.IsValue() and not JsonToken.AsValue().IsNull() then
                    Nombre := DelChr(JsonToken.AsValue().AsText(), '<>', ' ');
                if Nombre = '' then
                    Nombre := 'foto.jpg';
                if JsonLine.Get('id', JsonToken) and JsonToken.IsValue() and not JsonToken.AsValue().IsNull() then begin
                    IdTxt := JsonToken.AsValue().AsText();
                    if not Evaluate(IdUrl, IdTxt) then
                        IdUrl := 0;
                end;
                if Url <> '' then
                    AdjuntarUrlParteTrabajo(ParteNo, Url, IdUrl, Nombre);
            end;
        end;
    end;

    /// <summary>
    /// Recibe un parte de trabajo desde Rutas (JSON) y crea/actualiza Time Sheet Header + Time Sheet Line.
    /// JSON esperado: numero_tarea y/o id_tarea, no_incidencia, origen, codigo_emplazamiento, no_recurso,
    /// parada_emplazamiento, fecha, operario, descripcion, cliente y lineas.
    /// Si el origen es catálogo SQL o calendario y no hay tarea, crea el mantenimiento (tarea incluida) antes del parte.
    /// </summary>
    [ServiceEnabled]
    procedure PostParteTrabajo(JsonText: Text): Text
    var
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonLine: JsonObject;
        TimeSheetHeader: Record "Time Sheet Header";
        LastHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        UserTask: Record "User Task";
        Item: Record Item;
        Resource: Record Resource;
        ParadaEmplazamiento: Text;
        FechaTexto: Text;
        Fecha: Date;
        Operario: Text;
        UserId: Guid;
        UserGtask: Record UsuariosGtask;
        Descripcion: Text;
        Cliente: Code[20];
        LineNo: Integer;
        i: Integer;
        TipoLinea: Text;
        Codigo: Code[20];
        Cantidad: Decimal;
        Precio: Decimal;
        JsonResult: JsonObject;
        ResultText: Text;
        NoParteExistente: Code[20];
        ParteYaExistia: Boolean;
        TareaResuelta: Boolean;
    begin
        if (JsonText = '') or not JsonObj.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        ParadaEmplazamiento := '';
        Fecha := 0D;
        Operario := '';
        Descripcion := '';
        Cliente := '';

        if JsonObj.Get('parada_emplazamiento', JsonToken) then ParadaEmplazamiento := CopyStr(JsonToken.AsValue().AsText(), 1, 250);
        if JsonObj.Get('parada_bus', JsonToken) then ParadaEmplazamiento := CopyStr(JsonToken.AsValue().AsText(), 1, 250);
        if JsonObj.Get('fecha', JsonToken) then begin
            FechaTexto := JsonToken.AsValue().AsText();
            if not Evaluate(Fecha, FechaTexto) then Fecha := Today();
        end else
            Fecha := Today();
        if JsonObj.Get('operario', JsonToken) then Operario := JsonToken.AsValue().AsText();
        if Operario <> '' then begin
            UserGtask.SetRange("Id Gtask", Operario);
            if UserGtask.FindFirst() then
                UserId := UserGtask."Id Usuario";
        end;

        if JsonObj.Get('descripcion', JsonToken) then Descripcion := CopyStr(JsonToken.AsValue().AsText(), 1, 250);
        if JsonObj.Get('cliente', JsonToken) then Cliente := CopyStr(JsonToken.AsValue().AsText(), 1, 20);
        if Cliente = '' Then Cliente := '426'; // emt, hay que ponerlo en un configurador'
        // Buscar tarea existente o crearla si el origen es catálogo SQL / calendario sin tarea.
        ParteYaExistia := false;
        TareaResuelta := ResolverTareaParteJson(JsonObj, true, UserTask, NoParteExistente);

        TimeSheetHeader.Reset();
        if (NoParteExistente <> '') and TimeSheetHeader.Get(NoParteExistente) then
            ParteYaExistia := true
        else begin
            TimeSheetHeader.Reset();
            TimeSheetHeader.SetRange(Tipo, TimeSheetHeader.Tipo::Trabajo);
            TimeSheetHeader.SetRange("Fecha Inicio", Fecha);
            if TareaResuelta and (UserTask.ID <> 0) then
                TimeSheetHeader.SetRange(Tarea, UserTask.ID);

            if not TimeSheetHeader.FindFirst() then begin
                LastHeader.Reset();
                TimeSheetHeader.Init();
                TimeSheetHeader.Tipo := TimeSheetHeader.Tipo::Trabajo;
                TimeSheetHeader."Owner User ID" := UserId;
                TimeSheetHeader."No." := '';
                LastHeader.SetFilter("No.", '%1', 'PT' + Format(Date2DMY(Fecha, 3)) + '*');
                if LastHeader.FindLast() then
                    TimeSheetHeader."No." := IncStr(LastHeader."No.")
                else
                    TimeSheetHeader."No." := 'PT' + Format(Date2DMY(Fecha, 3)) + '-00001';
                TimeSheetHeader."Fecha Inicio" := Fecha;
                TimeSheetHeader."Fecha Fin" := Fecha;
                TimeSheetHeader."Starting Date" := Fecha;
                TimeSheetHeader."Ending Date" := Fecha;
                if TareaResuelta and (UserTask.ID <> 0) then
                    TimeSheetHeader.Tarea := UserTask.ID;
                TimeSheetHeader.Cliente := Cliente;
                TimeSheetHeader.Description := CopyStr(ParadaEmplazamiento, 1, MaxStrLen(TimeSheetHeader.Description));
                // La tabla estándar Time Sheet Header/Line exige "Resource No." válido (OnInsert llama GetTimeSheetResource)
                if TimeSheetHeader."Resource No." = '' then
                    TimeSheetHeader.Insert()
                else
                    TimeSheetHeader.Insert(true);
            end;
        end;

        if TareaResuelta and (UserTask.ID <> 0) and (TimeSheetHeader.Tarea <> UserTask.ID) then begin
            TimeSheetHeader.Tarea := UserTask.ID;
            TimeSheetHeader.Modify(true);
        end;

        // Si la cabecera (nueva o existente) tiene Resource No. vacío, el OnInsert de las líneas estándar falla; rellenar con el primer recurso
        // if TimeSheetHeader."Resource No." = '' then begin
        //     Resource.Reset();
        //     if Resource.FindFirst() then begin
        //         TimeSheetHeader."Resource No." := Resource."No.";
        //         TimeSheetHeader.Modify(true);
        //     end;
        // end;

        // Líneas: sustituir las actuales solo si el JSON trae alguna. Un array vacío no borra la plantilla.
        if JsonObj.Get('lineas', JsonToken) and JsonToken.IsArray() then begin
            JsonArray := JsonToken.AsArray();
            if JsonArray.Count() > 0 then begin
                TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                TimeSheetLine.DeleteAll();

                for i := 0 to JsonArray.Count - 1 do begin
                    JsonArray.Get(i, JsonToken);
                    if not JsonToken.IsObject() then continue;
                    JsonLine := JsonToken.AsObject();
                    TipoLinea := 'producto';
                    Codigo := '';
                    Cantidad := 0;
                    Precio := 0;
                    if JsonLine.Get('tipo', JsonToken) then TipoLinea := LowerCase(JsonToken.AsValue().AsText());
                    if JsonLine.Get('codigo', JsonToken) then Codigo := CopyStr(JsonToken.AsValue().AsText(), 1, 20);

                    if JsonLine.Get('cantidad', JsonToken) then Evaluate(Cantidad, JsonToken.AsValue().AsText());
                    if JsonLine.Get('precio', JsonToken) then Evaluate(Precio, JsonToken.AsValue().AsText());

                    TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                    if TimeSheetLine.FindLast() then
                        LineNo := TimeSheetLine."Line No." + 10000
                    else
                        LineNo := 10000;

                    TimeSheetLine.Init();
                    TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
                    TimeSheetLine."Line No." := LineNo;
                    TimeSheetLine."Job No." := TimeSheetHeader."No.";
                    TimeSheetLine."Job Line No." := -1;
                    if TipoLinea = 'recurso' then
                        TimeSheetLine.Tipo := TimeSheetLine.Tipo::Recurso
                    else
                        TimeSheetLine.Tipo := TimeSheetLine.Tipo::Producto;
                    TimeSheetLine.No := Codigo;
                    if Codigo <> '' then
                        if Item.Get(Codigo) then
                            TimeSheetLine.Descripcion := Item.Description
                        else
                            if Resource.Get(Codigo) then
                                TimeSheetLine.Descripcion := Resource.Name;
                    if JsonLine.Get('nombre', JsonToken) then TimeSheetLine.Descripcion := CopyStr(JsonToken.AsValue().AsText(), 1, 80);
                    TimeSheetLine.Cantidad := Cantidad;
                    TimeSheetLine.Insert(true);
                end;
            end;
        end;

        AdjuntarImagenesParteDesdeJson(TimeSheetHeader."No.", JsonObj);

        // El mantenimiento recién creado ya publica la tarea. CreateParte solo si el parte es nuevo.
        Clear(JsonResult);
        JsonResult.Add('value', TimeSheetHeader."No.");
        if (TimeSheetHeader.Tarea <> 0) and UserTask.Get(TimeSheetHeader.Tarea) then begin
            if UserTask.Id_Tarea <> '' then
                JsonResult.Add('id_tarea', UserTask.Id_Tarea);
            JsonResult.Add('numero_tarea', Format(UserTask.ID));
            if not ParteYaExistia then
                JsonResult.Add('workorder_id', CopyStr(CreateParte(UserTask), 1, 250));
        end;

        JsonResult.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Devuelve lista de productos (Item) para partes de trabajo. JSON de entrada puede ser "{}".
    /// </summary>
    [ServiceEnabled]
    procedure GetProductosParte(): Text
    var
        Item: Record Item;
        JsonArray: JsonArray;
        JsonObj: JsonObject;
        JsonItem: JsonObject;
        ResultText: Text;
    begin
        Clear(JsonArray);
        Item.SetRange(Blocked, false);
        if Item.FindSet() then
            repeat
                Clear(JsonItem);
                JsonItem.Add('no', Item."No.");
                JsonItem.Add('description', Item.Description);
                JsonItem.Add('unitPrice', Item."Unit Price");
                JsonArray.Add(JsonItem);
            until Item.Next() = 0;
        JsonObj.Add('value', JsonArray.AsToken());
        JsonObj.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Devuelve lista de recursos para partes de trabajo. JSON de entrada puede ser "{}".
    /// </summary>
    [ServiceEnabled]
    procedure GetRecursosParte(): Text
    var
        Resource: Record Resource;
        JsonArray: JsonArray;
        JsonObj: JsonObject;
        JsonItem: JsonObject;
        ResultText: Text;
    begin
        Clear(JsonArray);
        if Resource.FindSet() then
            repeat
                Clear(JsonItem);
                JsonItem.Add('no', Resource."No.");
                JsonItem.Add('name', Resource.Name);
                JsonItem.Add('unitPrice', Resource."Unit Price");
                JsonArray.Add(JsonItem);
            until Resource.Next() = 0;
        JsonObj.Add('value', JsonArray.AsToken());
        JsonObj.WriteTo(ResultText);
        exit(ResultText);
    end;

    [ServiceEnabled]
    procedure PostTareas(JsonText: Text): Text;
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
        DocumentAttachment2: Record "Document Attachment";
        DocumentAttachment3: Record "Document Attachment";
        OrdenFijacion: Record "Orden fijación";
        FileManager: Codeunit "File Management";
        Docuname2: Text;

    begin
        JsonArray.ReadFrom(JsonText);
        foreach JsonToken in JsonArray do begin
            JsonTarea := JsonToken.AsObject();
            If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
                Texto := JsonCampo.AsValue().AsText();
                If Not Evaluate(Id, Texto) then begin
                    CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                    Tareas.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
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
                                // If Tareas.Modify(false) then
                                //     Commit();
                                // Tareas.Get(Id);
                                // Tareas.SetDescription(JsonCampo.AsValue().AsText());
                                // Tareas.Get(Id);
                            end;
                            AplicarFechasDesdeGtaskJson(Tareas, JsonTarea);
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

                            Tareas.Modify(false);
                            Commit();
                            Tareas.Get(Id);
                            If Tareas.EsPeriodica then begin
                                if (Tareas.DependenciaCreada = false) and (Tareas.Estado = Tareas.Estado::Finalizado) then begin

                                    Tareas.CrearDependencia();
                                    Commit();
                                end;

                            end;
                            commit;

                        end;
                    end; //else
                         //If Id <> 0 Then DeleteTarea(IdTarea);
                end else
                    // Id_Navision no numerico: no insertar otra copia del mismo _id.
                    CrearTareaDesdeGtaskSinNavision(JsonTarea);
            end;
            CodEmpresa := '';

            if JsonTarea.Get('document', JsonCampo) then begin
                JsonArray := JsonCampo.AsArray();
                If JsonTarea.Get('Id_Navision', JsonCampo) Then begin
                    Texto := JsonCampo.AsValue().AsText();
                    If Not Evaluate(Id, Texto) then begin
                        CodEmpresa := CopyStr(JsonCampo.AsValue().AsText(), 1, 2);
                        Tareas.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
                        Texto := CopyStr(JsonCampo.AsValue().AsText(), 3, StrLen(JsonCampo.AsValue().AsText()));
                    end;
                    if Evaluate(Id, Texto) then
                        if Tareas.Get(Id) then begin

                            If Tareas."No." = '' then begin
                                Tareas."No." := Format(Id);
                                Tareas.Modify(false);
                            end;

                            foreach JsonToken in JsonArray do begin
                                JsonDetalleCampo := JsonToken.AsObject();
                                If JsonDetalleCampo.Get('document', JsonCampo) then begin
                                    JSonDocument := JsonCampo.AsObject();
                                    If JsonDocument.get('name', JsonCampo) then
                                        DocuName := JsonCampo.AsValue().AsText()
                                    else
                                        DocuName := '';
                                    If (DocuName <> '') and (jSonDocument.Get('url', JsonCampo)) then begin
                                        DocUrl := JsonCampo.AsValue().AsText();


                                        DocumentAtt.Reset();
                                        If CodEmpresa <> '' then
                                            DocumentAtt.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
                                        DocumentAtt.SetRange("Table ID", Database::"User Task");
                                        DocumentAtt.SetRange("No.", Format(Tareas.Id));
                                        Docuname2 := DocuName;
                                        If DocuName.Contains('.jpg') then
                                            DocuName := CopyStr(DocuName, 1, StrLen(DocuName) - 4);
                                        If DocUrl <> '' then
                                            DocumentAtt.SetRange("URL", DocUrl)
                                        else
                                            DocumentAtt.Setfilter("File Name", '%1', DocuName + '*');
                                        If Not DocumentAtt.Findfirst() then begin

                                            If DocUrl <> '' then
                                                DocumentAtt.SetRange("URL")
                                            else
                                                DocumentAtt.SetRange("File Name");
                                            if DocumentAtt.FindLast() then
                                                Line := DocumentAtt.Id + 1
                                            else
                                                Line := 1;
                                            DocumentAtt.Init();
                                            DocumentAtt.Id := Line;
                                            DocumentAtt."Table ID" := Database::"User Task";
                                            DocumentAtt."No." := Format(Tareas.Id);
                                            If Docuname2 = '' Then Docuname2 := DocuName;
                                            DocumentAtt."File Name" := DocuName2;
                                            DocumentAtt."File Extension" := FileManager.GetExtension(DocuName);
                                            DocumentAtt."URL" := DocUrl;
                                            if JsonDocument.Get('_id', JsonCampo) then
                                                DocumentAtt.ID_Url := JsonCampo.AsValue().AsInteger()
                                            else
                                                DocumentAtt.ID_Url := 0;
                                            DocumentAtt."Attached Date" := CurrentDateTime;
                                            DocumentAtt.Insert();
                                            if CodEmpresa <> '' then
                                                DocumentAttachment2.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
                                            If Tareas.OrdenFijacion <> 0 then begin
                                                DocumentAttachment2 := DocumentAtt;
                                                DocumentAttachment2."Table ID" := Database::"Orden fijación";
                                                DocumentAttachment2."No." := Tareas."Job No.";
                                                DocumentAttachment2."Line No." := Tareas.Reserva;
                                                DocumentAttachment2."ID_Doc" := Tareas.OrdenFijacion;
                                                DocumentAttachment2."Document Flow Service" := true;
                                                If DocumentAttachment2.Insert() Then
                                                    AdImagenValla(DocumentAttachment2, Procesos_GTask.CambiaEmpresa(CodEmpresa));
                                                if CodEmpresa <> '' then
                                                    DocumentAttachment3.ChangeCompany(Procesos_GTask.CambiaEmpresa(CodEmpresa));
                                                DocumentAttachment3.SetRange("Table ID", Database::Job);
                                                DocumentAttachment3.SetRange("No.", Tareas."Job No.");
                                                Docuname2 := DocumentAtt."File Name";
                                                If DocumentAtt."File Name".Contains('.jpg') then
                                                    DocumentAtt."File Name" := CopyStr(DocumentAtt."File Name", 1, StrLen(DocumentAtt."File Name") - 4);
                                                If DocUrl <> '' then
                                                    DocumentAttachment3.SetRange("URL", DocUrl)
                                                else
                                                    DocumentAttachment3.Setfilter("File Name", '%1', DocumentAtt."File Name" + '*');
                                                if not DocumentAttachment3.FindSet() then begin
                                                    DocumentAttachment2 := DocumentAtt;
                                                    repeat
                                                        DocumentAttachment2."Line No." := Line;
                                                        If Docuname2 = '' Then Docuname2 := DocuName;
                                                        DocumentAttachment2."File Name" := Docuname2;
                                                        DocumentAttachment2."Table ID" := Database::Job;
                                                        If OrdenFijacion.Get(Tareas.OrdenFijacion, Tareas.Reserva) then
                                                            DocumentAttachment2."No." := OrdenFijacion."Nº Proyecto"
                                                        else
                                                            DocumentAttachment2."No." := Tareas."Job No.";
                                                        DocumentAttachment2."Document Flow Service" := true;
                                                        Line += 1;
                                                    until DocumentAttachment2.Insert();
                                                end;
                                            end;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                END;
            end;
        end;
        exit('OK');
    end;

    [ServiceEnabled]
    procedure ProyectosComercial(JsonText: Text): Text;
    var
        JsonObj: JsonObject;
        JsonCampo: JsonToken;
        Usuario: Text;
        User: Record User;
        UserSetup: Record "User Setup";
        Company: Record Company;
        Job: Record Job;
        Customer: Record Customer;
        ResultJson: JsonObject;
        ProyectosArray: JsonArray;
        ProyectoJson: JsonObject;
        ResponseText: Text;
        CodigoComercial: Code[20];
        FechaDesde: Date;
        FechaHasta: Date;
        FechaInicial: Date;
        FechaFinal: Date;
        TipoProyecto: Text;
        EstadoContrato: Text;
        Contact: Record Contact;
        ContactRelation: Record "Contact Business Relation";
        FiltrosTxt: Text;
    begin
        // Inicializar el objeto JSON de respuesta
        Clear(ResultJson);
        Clear(ProyectosArray);
        ResultJson.Add('success', false);
        ResultJson.Add('message', '');
        ResultJson.Add('proyectos', ProyectosArray);

        // Leer el JSON de entrada
        if not JsonObj.ReadFrom(JsonText) then begin
            ResultJson.Replace('message', 'Error al leer el JSON de entrada');
            ResultJson.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        // Obtener el usuario
        if not JsonObj.Get('usuario', JsonCampo) then begin
            if not JsonObj.Get('username', JsonCampo) then begin
                if not JsonObj.Get('user', JsonCampo) then begin
                    ResultJson.Replace('message', 'El campo "usuario", "username" o "user" es requerido');
                    ResultJson.WriteTo(ResponseText);
                    exit(ResponseText);
                end;
            end;
        end;
        Usuario := JsonCampo.AsValue().AsText();

        if Usuario = '' then begin
            ResultJson.Replace('message', 'El usuario no puede estar vacío');
            ResultJson.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        // Buscar el usuario
        User.SetRange("User Name", Usuario);
        if not User.FindFirst() then begin
            // Intentar buscar por email
            User.Reset();
            User.SetRange("Contact Email", Usuario);
            if not User.FindFirst() then begin
                ResultJson.Replace('message', 'Usuario no encontrado');
                ResultJson.WriteTo(ResponseText);
                exit(ResponseText);
            end;
        end;

        // Calcular fechas (desde hace 2 años hasta hoy)
        FechaDesde := CalcDate('-<2Y>', Today);
        FechaHasta := Today;

        // Recorrer todas las empresas
        Company.Reset();
        if Company.FindSet() then begin
            repeat
                // Cambiar de empresa
                Job.ChangeCompany(Company.Name);
                Customer.ChangeCompany(Company.Name);
                UserSetup.ChangeCompany(Company.Name);

                // Buscar el código del comercial en esta empresa
                // El código puede ser diferente en cada empresa, así que buscamos por el usuario
                UserSetup.Reset();
                UserSetup.SetRange("User ID", User."User Name");
                if UserSetup.FindFirst() then begin
                    CodigoComercial := UserSetup."Salespers./Purch. Code";

                    if CodigoComercial <> '' then begin
                        // Buscar proyectos (Job) directamente por código comercial
                        // IMPORTANTE: Los campos "Cod. Comercial", "Tipo" y "Estado Contrato" son personalizados
                        // Verificar los nombres exactos en la extensión de tabla de Job
                        // Si los nombres son diferentes, ajustar las siguientes líneas
                        Job.Reset();
                        // Filtrar por fecha de creación (desde hace 2 años)
                        Job.SetFilter("Creation Date", '>=%1&<=%2', FechaDesde, FechaHasta);

                        Job.SetRange(Job."Cód. vendedor", CodigoComercial);  // Campo personalizado - ajustar nombre si es necesario
                        Job.SetRange(status, Job.Status::Open);     // Campo personalizado - ajustar nombre si es necesario
                        FiltrosTxt += Job.GetFilters();
                        if Job.FindSet() then begin
                            repeat
                                // Verificar código comercial (si el campo está disponible)
                                if Job."Cód. vendedor" <> CodigoComercial then
                                    continue;

                                // Verificar estado contrato (si el campo está disponible)
                                if Job.status <> Job.status::Open then
                                    continue;

                                // Obtener información del cliente
                                if Customer.Get(Job."Bill-to Customer No.") then begin
                                    // Obtener fechas del proyecto
                                    FechaInicial := Job."Starting Date";
                                    FechaFinal := Job."Ending Date";

                                    // Obtener tipo de proyecto (campo personalizado)
                                    TipoProyecto := Format(Job.Tipo);

                                    // Obtener estado del contrato (campo personalizado)
                                    Job.CalcFields("Estado Contrato");
                                    EstadoContrato := Format(Job."Estado Contrato");

                                    // Crear objeto JSON para este proyecto
                                    Clear(ProyectoJson);
                                    ProyectoJson.Add('empresa', Company.Name);
                                    ProyectoJson.Add('numero_proyecto', Job."No.");
                                    ProyectoJson.Add('descripcion', Job.Description);
                                    ProyectoJson.Add('numero_cliente', Job."Bill-to Customer No.");
                                    ProyectoJson.Add('nombre_cliente', Customer.Name);
                                    // Buscar el contacto del cliente
                                    Contact.Reset();
                                    ContactRelation.SetCurrentKey("Link to Table", "No.");

                                    ContactRelation.Reset();
                                    ContactRelation.SetRange("No.", Job."Bill-to Customer No.");
                                    ContactRelation.SetRange("Link to Table", ContactRelation."Link to Table"::Customer);
                                    if ContactRelation.FindFirst() then
                                        Repeat
                                            Contact.SetRange("Company No.", ContactRelation."Contact No.");
                                            Contact.SetRange(Type, Contact.Type::Person);
                                            if Contact.FindSet() then begin
                                                ProyectoJson.Add('nombre_contacto', Contact.Name);
                                                // Agregar el email del contacto
                                                ProyectoJson.Add('email_contacto', Contact."E-Mail");
                                            end;
                                        until ContactRelation.Next() = 0;

                                    if FechaInicial <> 0D then
                                        ProyectoJson.Add('fecha_inicial', Format(FechaInicial, 0, '<Year4>-<Month,2>-<Day,2>'))
                                    else
                                        ProyectoJson.Add('fecha_inicial', '');

                                    if FechaFinal <> 0D then
                                        ProyectoJson.Add('fecha_final', Format(FechaFinal, 0, '<Year4>-<Month,2>-<Day,2>'))
                                    else
                                        ProyectoJson.Add('fecha_final', '');

                                    ProyectoJson.Add('tipo', TipoProyecto);
                                    ProyectoJson.Add('estado_contrato', EstadoContrato);

                                    // Agregar a la lista
                                    ProyectosArray.Add(ProyectoJson);
                                end;
                            until Job.Next() = 0;
                        end;
                    end;
                end;
            until Company.Next() = 0;
        end;

        // Preparar respuesta exitosa
        ResultJson.Replace('success', true);
        ResultJson.Replace('message', 'Proyectos obtenidos correctamente con estos filtros: ' + FiltrosTxt);
        ResultJson.Replace('proyectos', ProyectosArray);
        ResultJson.Add('total', ProyectosArray.Count());

        ResultJson.WriteTo(ResponseText);
        exit(ResponseText);
    end;

    [ServiceEnabled]
    procedure Proyecto(JsonText: Text): Text;
    var
        JsonObj: JsonObject;
        JsonCampo: JsonToken;
        Job: Record Job;
        Customer: Record Customer;
        empresa: Text;
        numero_proyecto: Text;
        ResultJson: JsonObject;
        ProyectosArray: JsonArray;
        ProyectoJson: JsonObject;
        ResponseText: Text;
        FechaInicial: Date;
        FechaFinal: Date;
        TipoProyecto: Text;
        EstadoContrato: Text;
        Contact: Record Contact;
        ContactRelation: Record "Contact Business Relation";

    begin
        // Inicializar el objeto JSON de respuesta
        Clear(ResultJson);
        Clear(ProyectosArray);
        ResultJson.Add('success', false);
        ResultJson.Add('message', '');
        ResultJson.Add('proyectos', ProyectosArray);

        // Leer el JSON de entrada
        if not JsonObj.ReadFrom(JsonText) then begin
            ResultJson.Replace('message', 'Error al leer el JSON de entrada');
            ResultJson.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        // Obtener el número de proyecto
        if not JsonObj.Get('numero_proyecto', JsonCampo) then begin
            ResultJson.Replace('message', 'El campo "numero_proyecto" es requerido');
            ResultJson.WriteTo(ResponseText);
        end;
        numero_proyecto := JsonCampo.AsValue().AsText();
        // Obtener la empresa
        if not JsonObj.Get('empresa', JsonCampo) then begin
            ResultJson.Replace('message', 'El campo "empresa" es requerido');
            ResultJson.WriteTo(ResponseText);
            exit(ResponseText);
        end;

        empresa := JsonCampo.AsValue().AsText();

        // Cambiar de empresa
        Job.ChangeCompany(empresa);
        if Job.Get(numero_proyecto) then begin
            // Obtener fechas del proyecto
            FechaInicial := Job."Starting Date";
            FechaFinal := Job."Ending Date";

            // Obtener tipo de proyecto (campo personalizado)
            TipoProyecto := Format(Job.Tipo);

            // Obtener estado del contrato (campo personalizado)
            Job.CalcFields("Estado Contrato");
            EstadoContrato := Format(Job."Estado Contrato");

            // Crear objeto JSON para este proyecto
            Clear(ProyectoJson);
            ProyectoJson.Add('empresa', empresa);
            ProyectoJson.Add('numero_proyecto', Job."No.");
            ProyectoJson.Add('descripcion', Job.Description);
            ProyectoJson.Add('numero_cliente', Job."Bill-to Customer No.");
            ProyectoJson.Add('nombre_cliente', Customer.Name);
            // Buscar el contacto del cliente
            Contact.Reset();
            ContactRelation.SetCurrentKey("Link to Table", "No.");

            ContactRelation.Reset();
            ContactRelation.SetRange("No.", Job."Bill-to Customer No.");
            ContactRelation.SetRange("Link to Table", ContactRelation."Link to Table"::Customer);
            if ContactRelation.FindFirst() then
                Repeat
                    Contact.SetRange("Company No.", ContactRelation."Contact No.");
                    Contact.SetRange(Type, Contact.Type::Person);
                    if Contact.FindSet() then begin
                        ProyectoJson.Add('nombre_contacto', Contact.Name);
                        // Agregar el email del contacto
                        ProyectoJson.Add('email_contacto', Contact."E-Mail");
                    end;
                until ContactRelation.Next() = 0;

            if FechaInicial <> 0D then
                ProyectoJson.Add('fecha_inicial', Format(FechaInicial, 0, '<Year4>-<Month,2>-<Day,2>'))
            else
                ProyectoJson.Add('fecha_inicial', '');

            if FechaFinal <> 0D then
                ProyectoJson.Add('fecha_final', Format(FechaFinal, 0, '<Year4>-<Month,2>-<Day,2>'))
            else
                ProyectoJson.Add('fecha_final', '');

            ProyectoJson.Add('tipo', TipoProyecto);
            ProyectoJson.Add('estado_contrato', EstadoContrato);

            // Agregar a la lista
            ProyectosArray.Add(ProyectoJson);
        end;




        // Preparar respuesta exitosa
        ResultJson.Replace('success', true);
        ResultJson.Replace('message', 'Proyecto obtenido correctamente');
        ResultJson.Replace('proyectos', ProyectosArray);
        ResultJson.Add('total', ProyectosArray.Count());

        ResultJson.WriteTo(ResponseText);
        exit(ResponseText);
    end;

    [ServiceEnabled]
    procedure PostFijacion(JsonText: Text): Text;
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
        Tareas: Record "User Task";
        UserTaskGroup: Record "User Task Group";
        ResponsabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        UserGtaskMalla: Record UsuariosGtask;
        "TO-Do": Record "To-Do";
        RecordiD: RecordId;
        RecordRef: RecordRef;
        Job: Record Job;
        jSonDocument: JsonObject;
        DocumentAtt: Record "Document Attachment";
        Line: Integer;
        DocBase64: Text;
        Num: Integer;
        CodEmpresa: Text[2];
        Empresas: Record "Company";
        Texto: Text;
        DocuName: Text;
        DocumentAttachment2: Record "Document Attachment";
        DocumentAttachment3: Record "Document Attachment";
        OrdenFijacion: Record "Orden fijación";
        FileManager: Codeunit "File Management";
        Encontrada: Boolean;
        Company: Record Company;
        Id: Integer;
        userGtask: Text;
        Empresa: Text;
        Docuname2: Text;
        Url: Text;
        idUrl: Integer;
    begin
        JsonArray.ReadFrom(JsonText);
        foreach JsonToken in JsonArray do begin
            JsonTarea := JsonToken.AsObject();
            If JsonTarea.Get('qrtarea', JsonCampo) Then begin
                if JsonTarea.get('idnavision', JsonCampo) Then If evaluate(Id, JsonCampo.AsValue().AsText()) then;
                if JsonTarea.Get('empresa', JsonCampo) Then begin
                    If not Company.Get(JsonCampo.AsValue().AsText()) then
                        Company.Get(CompanyName);
                end
                else
                    Company.Get(CompanyName);
                Texto := JsonCampo.AsValue().AsText();
                Tareas.SetRange(IdQr, Texto);
                Encontrada := false;
                if Id <> 0 then begin
                    Tareas.ChangeCompany(Company.Name);
                    Tareas.SetRange(IdQr);
                    Encontrada := Tareas.Get(Id);
                end;
                If Not Encontrada then begin
                    If Not Tareas.Findlast() Then begin
                        Company.FindFirst();
                        Encontrada := false;
                        repeat
                            Tareas.ChangeCompany(Company.Name);
                            Tareas.SetRange(IdQr, Texto);
                            Encontrada := Tareas.FindLast();
                            Empresa := Company.Name;
                        Until (Company.Next() = 0) or Encontrada
                    end;
                end;
                If Empresa = CompanyName then Empresa := '';
                if not Encontrada then Error('Tarea con IdQR %1, no encontrada', Texto);
                userGtask := '';
                if JsonTarea.Get('user', JsonCampo) then begin
                    userGtask := JsonCampo.AsValue().AsText();
                end;
                if JsonTarea.Get('document', JsonCampo) then begin
                    JsonArray := JsonCampo.AsArray();
                    foreach JsonToken in JsonArray do begin
                        JsonDetalleCampo := JsonToken.AsObject();
                        If JsonDetalleCampo.Get('document', JsonCampo) then begin
                            JSonDocument := JsonCampo.AsObject();
                            if jSonDocument.Get('url', JsonCampo) then begin
                                DocBase64 := JsonCampo.AsValue().AsText();
                            end;
                            if jSonDocument.Get('document_url', JsonCampo) then begin
                                Url := JsonCampo.AsValue().AsText();
                            end;
                            //id
                            if jSonDocument.Get('_id', JsonCampo) then begin
                                idUrl := JsonCampo.AsValue().AsInteger();
                            end;
                            If (Url <> '') or (DocBase64 <> '') then begin
                                DocuName := '';
                                If jSonDocument.get('name', JsonCampo) then
                                    DocuName := JsonCampo.AsValue().AsText();
                                if DocuName <> '' then begin
                                    DocumentAtt.Reset();
                                    if Empresa <> '' then
                                        DocumentAtt.ChangeCompany(Empresa);
                                    DocumentAtt.SetRange("Table ID", Database::"User Task");
                                    DocumentAtt.SetRange("No.", Tareas."No.");
                                    Docuname2 := DocuName;
                                    If DocuName.Contains('.jpg') then
                                        DocuName := CopyStr(DocuName, 1, StrLen(DocuName) - 4);
                                    DocumentAtt.Setfilter("File Name", '%1', DocuName + '*');
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
                                        If Docuname2 = '' Then Docuname2 := DocuName;
                                        DocumentAtt."File Name" := DocuName2;
                                        DocumentAtt."File Extension" := FileManager.GetExtension(DocuName);
                                        DocumentAtt."Document Flow Service" := true;
                                        // idUrl ya viene de _id; JsonCampo apunta al último Get ('name'), no usar AsInteger aquí.
                                        if idUrl <> 0 then
                                            DocumentAtt.ID_Url := idUrl
                                        else
                                            DocumentAtt.ID_Url := 0;
                                        if Url <> '' then
                                            DocumentAtt."URL" := Url
                                        else
                                            DocumentAtt."URL" := DocumentAtt.FormBase64ToUrl(DocBase64, DocuName2, IdUrl);
                                        If DocumentAtt.ID_Url = 0 then DocumentAtt.ID_Url := IdUrl;
                                        DocumentAtt."Attached Date" := CurrentDateTime;
                                        Repeat
                                            DocumentAtt.Id := Line;
                                            Line += 1;
                                        until DocumentAtt.Insert();
                                        If Empresa <> '' then
                                            DocumentAttachment2.ChangeCompany(Empresa);
                                        DocumentAttachment2 := DocumentAtt;
                                        DocumentAttachment2."Table ID" := Database::"Orden fijación";
                                        DocumentAttachment2."No." := Tareas."Job No.";
                                        DocumentAttachment2."Line No." := Tareas.Reserva;
                                        DocumentAttachment2."ID_Doc" := Tareas.OrdenFijacion;
                                        DocumentAttachment2."Document Flow Service" := true;
                                        If DocumentAttachment2.Insert() Then
                                            AdImagenValla(DocumentAttachment2, Empresa);
                                        if Empresa <> '' then
                                            DocumentAttachment3.ChangeCompany(Empresa);
                                        DocumentAttachment3.SetRange("Table ID", Database::Job);
                                        DocumentAttachment3.SetRange("No.", Tareas."Job No.");
                                        Docuname2 := DocumentAtt."File Name";
                                        If DocumentAtt."File Name".Contains('.jpg') then
                                            DocumentAtt."File Name" := CopyStr(DocumentAtt."File Name", 1, StrLen(DocumentAtt."File Name") - 4);
                                        DocumentAttachment3.Setfilter("File Name", '%1', DocumentAtt."File Name" + '*');
                                        if not DocumentAttachment3.FindSet() then begin
                                            DocumentAttachment2 := DocumentAtt;
                                            repeat
                                                DocumentAttachment2."Line No." := Line;
                                                If Docuname2 = '' Then Docuname2 := DocuName;
                                                DocumentAttachment2."File Name" := Docuname2;
                                                DocumentAttachment2."Table ID" := Database::Job;
                                                If OrdenFijacion.Get(Tareas.OrdenFijacion, Tareas.Reserva) then
                                                    DocumentAttachment2."No." := OrdenFijacion."Nº Proyecto"
                                                else
                                                    DocumentAttachment2."No." := Tareas."Job No.";
                                                DocumentAttachment2."Document Flow Service" := true;
                                                Line += 1;
                                            until DocumentAttachment2.Insert();
                                        end;
                                        SetDocAttachment(DocumentAtt, Tareas.Id_Tarea);
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
                If userGtask <> '' then begin
                    UserGtaskMalla.ChangeCompany('Malla Publicidad');
                    UserGtaskMalla.SetRange("Id Gtask", userGtask);
                    If UserGtaskMalla.FindFirst() then begin
                        Tareas.Estado := Tareas.Estado::Finalizado;
                        Tareas."Assigned To" := UserGtaskMalla."Id Usuario";
                        Tareas."Fecha Comunicado Cambio" := CurrentDateTime;
                        Tareas."Fecha Cambio" := DaTi2Variant(Calcdate('-1D', Today), Time);
                        Tareas.Modify(false);
                    end;
                    UpdateTaskGtaskUserandStatus(Tareas.Id_Tarea, Tareas.ID, userGtask);
                end;
            end;
        end;

        exit('OK');
    end;

    [ServiceEnabled]
    procedure devuelveidqr(JsonText: Text): Text;
    var
        JsonArray: JsonArray;
        JsonOutPutArray: JsonArray;
        JsonOutPutArrayItem: JsonArray;
        JsonTareaOutPut: JsonObject;
        JsonOutPutItem: JsonObject;
        JsonToken: JsonToken;
        JsonCampo: JsonToken;
        JsonTarea: JsonObject;
        // Salida
        OutArray: JsonArray;
        OutItem: JsonObject;
        IdsArray: JsonArray;
        // Auxiliares
        IdQrTxt: Text;
        UniqueIdqrs: List of [Text];
        TaskIds: List of [Text];
        TaskId: Text;
        Empresas: Record Company;
        Tareas: Record "User Task";
        JsonVal: JsonValue;
        Json: Text;
        CuentaTareas: Integer;
    begin
        if JsonText = '' then
            exit('[]');

        // Recoger todos los idqr existentes en el JSON de entrada (admite items objeto con 'idqr' o 'qrtarea' y items string)
        JsonArray.ReadFrom(JsonText);
        foreach JsonToken in JsonArray do begin
            IdQrTxt := '';
            JsonTarea := JsonToken.AsObject();
            If JsonTarea.Get('qrtarea', JsonCampo) Then begin
                IdQrTxt := JsonCampo.AsValue().AsText();
                clear(JsonOutPutItem);
                clear(JsonOutPutArrayItem);
                JsonOutPutItem.Add('idqr', IdQrTxt);
                Empresas.FindFirst();
                repeat
                    Tareas.ChangeCompany(Empresas.Name);
                    Tareas.Reset();
                    Tareas.SetRange(IdQr, IdQrTxt);
                    if Tareas.FindLast() then begin
                        //repeat

                        clear(JsonTareaOutPut);
                        JsonTareaOutPut.Add('idnavision', Tareas.Id);
                        JsonTareaOutPut.Add('empresa', Empresas.Name);
                        JsonTareaOutPut.Add('descripcion', Tareas.Title);
                        JsonTareaOutPut.Add('fecha', Format(Tareas."Start DateTime", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonOutPutArrayItem.Add(JsonTareaOutPut);
                        CuentaTareas += 1;

                        // Tareas.SetFilter(ID, '<>%1', Tareas.ID);
                        // Tareas.SetFilter(Estado, '<>%1', Tareas.Estado::Finalizado);
                        // if Tareas.FindLast() then begin
                        //     clear(JsonTareaOutPut);
                        //     JsonTareaOutPut.Add('idnavision', Tareas.Id);
                        //     JsonTareaOutPut.Add('empresa', Empresas.Name);
                        //     JsonTareaOutPut.Add('descripcion', Tareas.Title);
                        //     JsonOutPutArrayItem.Add(JsonTareaOutPut);
                        //     CuentaTareas += 1;
                        // end;

                    end;
                until Empresas.Next() = 0;

                JsonOutPutItem.Add('tareas', JsonOutPutArrayItem);
                JsonOutPutArray.Add(JsonOutPutItem);
            end;

        end;
        JsonOutPutArray.WriteTo(Json);
        exit(Json);
    end;


    [ServiceEnabled]
    procedure postIncidencia(JsonText: Text): Text;
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonCampo: JsonToken;
        JsonTarea: JsonObject;
        JsonDetalleCampo: JsonObject;
        Json: Text;
        Tareas: Record "User Task";
        UserTaskGroup: Record "User Task Group";
        ResponsabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        UserGtaskMalla: Record UsuariosGtask;
        rDet: Record Incidencias;
        RecordiD: RecordId;
        RecordRef: RecordRef;
        Job: Record Job;
        jSonDocument: JsonObject;
        DocumentAtt: Record "Document Attachment";
        Line: Integer;
        DocBase64: Text;
        Num: Integer;
        CodEmpresa: Text[2];
        Empresas: Record "Company";
        Texto: Text;
        DocuName: Text;
        DocumentAttachment2: Record "Document Attachment";
        DocumentAttachment3: Record "Document Attachment";
        CabOrdenFijacion: Record "Cab Orden fijación";
        FileManager: Codeunit "File Management";
        Encontrada: Boolean;
        Company: Record Company;
        Id: text;
        JsonFormater: Codeunit "Json Text Reader/Writer";
        CompanyInfo: Record "Company Information";
        RestApi: Codeunit "Control Ocr";
        RequestType: Option Get,patch,put,post,delete;
        JSONMgt: Codeunit "JSON Management";
        Name: Text;
        Value1: Text;
        Imagenes: Record "Imagenes Orden fijación";
        ImpagenesTemp: Record "Imagenes Orden fijación" temporary;
        Recurso: Record Resource;
        wRecordRef: RecordRef;
        State: Text;
        JsonIncidencia: JsonObject;
        IncidenceType: Text;
        Observation: Text;
        Description: Text;
        Resource: Text;
        FileBase64: Text;
        Imagen: Integer;
        Resources: Record Resource;
        Encontrado: Boolean;
        Control: Codeunit "ControlProcesos";
        Parada: Boolean;
        ParadasBus: Record "Emplazamientos";
        document: JsonObject;
        Usuario: Record UsuariosGtask;
        UsuarioId: Guid;
        UsuarioAsignadoId: Guid;
        UsuarioSeguimientoId: Guid;
        UsuarioSeguimientoInformado: Boolean;
        TextoSeguimiento: Text;
        IdIncidencia: Text;
        NuevaIncidencia: Boolean;
        Fecha: DateTime;
        Empresa: Text;
        IdImagen: Integer;
        IdTarea: Text;
        RecursoOriginal: Text;
        Response: HttpResponseMessage;
        MensajeMeta: Text;
        UsuariosGtaskxCatego: Record "User Task Group Member";
        GuidEmt: Guid;
        SubTipoIncidencia: Text;
        EnviadoASC: Boolean;
        NotificarWhatsApp: Boolean;
    begin
        //{
        //"id":"65b5c4c3d4e5f6789012335"
        // "state": "PENDING",
        // "incidenceType": "65a1b2c3d4e5f6789012345",
        // "observation": "Observación adicional",
        // "description": "Descripción de la incidencia",
        // "resource": "65a1b2c3d4e5f6789012348",
        // "image": [
        // "document":{
        // "file": "https://..............",
        // "name": "imagen1.jpg"
        // },
        // {
        // "file": "https://..............",
        // "name": "imagen2.png"
        // }
        // ]
        // }
        JsonIncidencia.ReadFrom(JsonText);
        if JsonIncidencia.Get('_id', JsonCampo) Then IdIncidencia := JsonCampo.AsValue().AsText();
        if JsonIncidencia.Get('id_gtask', JsonCampo) Then IdIncidencia := JsonCampo.AsValue().AsText();

        If JsonIncidencia.Get('state', JsonCampo) Then
            State := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('user', JsonCampo) Then
            If Usuario.Get(JsonCampo.AsValue().AsText()) then
                UsuarioId := Usuario."Id Usuario";
        If JsonIncidencia.Get('user_assigned', JsonCampo) Then
            If Usuario.Get(JsonCampo.AsValue().AsText()) then
                UsuarioAsignadoId := Usuario."Id Usuario";
        if JsonIncidencia.Get('user_follow', JsonCampo) then begin
            UsuarioSeguimientoInformado := true;
            TextoSeguimiento := JsonCampo.AsValue().AsText();
            if TextoSeguimiento = '' then
                Clear(UsuarioSeguimientoId)
            else
                if Usuario.Get(TextoSeguimiento) then
                    UsuarioSeguimientoId := Usuario."Id Usuario"
                else
                    UsuarioSeguimientoInformado := false;
        end;
        If JsonIncidencia.Get('incidenceType', JsonCampo) Then
            IncidenceType := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('subIncidenceType', JsonCampo) Then
            SubTipoIncidencia := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('observation', JsonCampo) Then
            Observation := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('description', JsonCampo) Then
            Description := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('resource', JsonCampo) Then
            Resource := JsonCampo.AsValue().AsText();
        RecursoOriginal := Resource;
        //Fecha AAAA-MM-DD 2025-11-13 o formato ISO 2025-11-11T23:00:00Z
        // Priorizar fechaHora si existe, sino usar fecha
        If JsonIncidencia.Get('fechahora', JsonCampo) Then begin
            Fecha := JsonCampo.AsValue().AsDateTime() - 1 * 3600 * 1000; // restar 1 hora;
        end else if JsonIncidencia.Get('fecha', JsonCampo) Then begin
            Fecha := Procesos_GTask.ParseFechaFromJson(JsonCampo.AsValue().AsText());
        end else
            Fecha := CurrentDateTime();
        If JsonIncidencia.Get('image', JsonCampo) Then begin
            JsonArray := JsonCampo.AsArray();
            foreach JsonToken in JsonArray do begin
                document := JsonToken.AsObject();
                // El JSON tiene la estructura: {"document": {"file": "...", "name": "..."}}
                if document.Get('document', JsonCampo) then begin
                    document := JsonCampo.AsObject();
                    if document.Get('file', JsonCampo) then begin
                        Imagen += 1;
                        DocuName := 'Imagen' + Format(Imagen) + '_' + Format(CurrentDateTime, 0, 9) + '.jpg';
                        FileBase64 := JsonCampo.AsValue().AsText();
                        If CopyStr(FileBase64, 1, 4) = 'http' then begin
                            ImpagenesTemp.Url := FileBase64;
                        end else begin
                            if CopyStr(FileBase64, 1, 5) = 'data:' then
                                if StrPos(FileBase64, ',') > 0 then
                                    FileBase64 := CopyStr(FileBase64, StrPos(FileBase64, ',') + 1);
#If CLEAN27
                            ImpagenesTemp.Url := Control.FormBase64ToUrl(FileBase64, DocuName, IdImagen);
#else
                            ImpagenesTemp.Url := ImpagenesTemp.FormBase64ToUrl(FileBase64, DocuName, IdImagen);
#endif
                            ImpagenesTemp.Id := IdImagen;
                        end;
                        ImpagenesTemp."Nº Imagen" := Imagen;
                        if document.Get('name', JsonCampo) then
                            ImpagenesTemp.Nombre := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(ImpagenesTemp.Nombre))
                        else
                            ImpagenesTemp.Nombre := DocuName;
                        if document.Get('file_id', JsonCampo) then
                            If evaluate(ImpagenesTemp.Id, JsonCampo.AsValue().AsText()) Then;
                        If ImpagenesTemp.Id = 0 then ImpagenesTemp.Id := IdImagen;
                        if ImpagenesTemp.Id = 0 then Error('Imagen no encontrada');
                        If ImpagenesTemp.Insert() Then;

                        IdImagen := 0;
                    end;
                end;
            end;
        end;
        Encontrado := true;
        Parada := true;
        If Resource <> '' then begin
            If CopyStr(Resource, 1, 1) <> 'P' then begin
                If Not Resources.Get(Resource) then begin
                    Encontrado := false;
                    Empresas.FindFirst();
                    repeat
                        Resources.ChangeCompany(Empresas.Name);
                        Resources.Reset();
                        If Resources.Get(Resource) then begin
                            Encontrado := true;
                            Parada := false;
                            Empresa := Empresas.Name;
                            break;
                        end;

                    until Empresas.Next() = 0;
                end else
                    Parada := false;
            end else
                Encontrado := False;
            If Not Encontrado Then begin
                If CopyStr(Resource, 1, 7) = 'PARADA_' then //quita la 'PARADA_'
                    Resource := CopyStr(Resource, 8);
                if CopyStr(Resource, 1, 1) = 'P' then //quita la 'P'
                    Resource := CopyStr(Resource, 2);
                If ParadasBus.Get(ParadasBus."Tipo Emplazamiento"::Opis, Resource) then begin
                    Encontrado := true;
                    Parada := true;
                    Empresa := CompanyName;
                end;
            end;

            // If not Encontrado then Exit(Resource + ' no encontrado');
        End;
        NuevaIncidencia := true;
        If IdIncidencia = '' then
            rDet.Init()
        else begin
            if not rDet.Get(Copystr(IdIncidencia, 1, 20)) then begin
                rDet.SetRange("Id_Gtask", IdIncidencia);
                if not rDet.FindFirst() then Error('Incidencia no encontrada');
            end;
            NuevaIncidencia := false;

            if rDet.Id_Gtask = '' Then NuevaIncidencia := true
        end;
        rDet.Recurso := Resource;
        if Parada then
            rDet."Tipo Elemento" := rDet."Tipo Elemento"::Parada
        else
            rDet."Tipo Elemento" := rDet."Tipo Elemento"::Recurso;
        rDet.Fecha := DT2Date(Fecha);
        rDet.FechaHora := Fecha;
        if not (not NuevaIncidencia and DebePreservarDescripcionIncidencia(Description, rDet."No.")) then
            if Description <> '' then
                rDet.Descripción := CopyStr(Description, 1, MaxStrLen(rDet."Descripción"));
        // Si la incidenciia no es nueva, y el usuario no existe, el usuario será equipoti
        if not NuevaIncidencia and IsNullGuid(UsuarioId) then
            If Usuario.Get('67a4a441f8a4bb001960c4d6') then
                UsuarioId := Usuario."Id Usuario";
        //rDet. := Observation;
        if IsNullGuid(UsuarioId) = false then
            rDet.Usuario := UsuarioId;
        if IsNullGuid(UsuarioAsignadoId) = false then
            rDet."Usuario Asignado" := UsuarioAsignadoId;
        if UsuarioSeguimientoInformado then
            if IsNullGuid(UsuarioSeguimientoId) then
                Clear(rDet."Usuario Seguimiento")
            else
                rDet."Usuario Seguimiento" := UsuarioSeguimientoId;
        if IsNullGuid(rDet."Usuario Seguimiento") then
            rDet."Usuario Seguimiento" := UsuarioId;
        case IncidenceType of

            'EMT', 'Incidencias EMT':
                begin
                    rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias EMT";
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Limpieza;
                    rDet."User Task Group" := 'EMT';
                end;
            'VILLENA', 'VALLAS', 'SOPORTES', 'Vallas', 'Soportes', 'Incidencias Soportes':
                begin
                    rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Soportes";
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Mantenimiento;
                    rDet."User Task Group" := 'MTO';
                end;
            'ELECTRICIDAD', 'Electricidad', 'TALLER', 'Taller', 'Incidencias Mobiliario Urbano':
                begin
                    rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Mobiliario Urbano";
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Electrica;
                    rDet."User Task Group" := 'MTO';
                end;
            'MTO', 'Mobiliario Urbano':
                begin
                    rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Mobiliario Urbano";
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::"Mantenimiento";
                    rDet."User Task Group" := 'MTO';
                end;
            'TAREA TALLER', 'Grupo Taller':
                begin
                    rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Soportes";
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::"Mantenimiento";
                    rDet."User Task Group" := 'MTO';
                end;
            'PODA', 'Poda':
                begin
                    rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Soportes";
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::"Poda";
                    rDet."User Task Group" := 'PODA';
                end;
        end;
        if SubTipoIncidencia <> '' then
            case Uppercase(SubTipoIncidencia) of
                'LIMPIEZA':
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Limpieza;
                'ELECTRICA':
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Electrica;
                'PODA':
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Poda;
                'MANTENIMIENTO':
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Mantenimiento;
                'OTRAS':
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Otras;
                'TIP':
                    rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Electrica
            end;
        case Uppercase(State) of
            'PENDING', 'ABIERTA':
                rDet.Estado := rDet.Estado::Abierta;
            'IN_PROGRESS', 'EN_PROCESO':
                rDet.Estado := rDet.Estado::EnProgreso;
            'COMPLETED', 'CLOSED', 'CERRADA':
                begin
                    NotificarWhatsApp := rdet.Estado <> rDet.Estado::Cerrada;
                    rDet.Estado := rDet.Estado::Cerrada;
                    ActualizarMantenimientoDesdeIncidencia(rDet);
                end;
        end;
        rDet.Empresa := Empresa;

        if NuevaIncidencia then begin
            rDet."Enviar Correo" := true;
            If IdIncidencia = '' Then rDet.Insert(true);
        end;
        If ImpagenesTemp.FindSet() then
            repeat
                Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
                Imagenes.SetRange("Es Incidencia", true);
                Imagenes.SetRange(Url, ImpagenesTemp.Url);
                If not Imagenes.FindFirst() then begin
                    Imagenes.Reset;
                    Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
                    Imagenes.SetRange("Es Incidencia", true);
                    if Imagenes.FindLast() then
                        Imagen := Imagenes."Nº Imagen" + 1
                    else
                        Imagen := 1;
                    Imagenes.Init();
                    Imagenes."Nº Orden" := rDet."Nº Orden";
                    Imagenes."Nº Imagen" := Imagen;
                    Imagenes.Id := ImpagenesTemp.Id;
                    Imagenes."Es Incidencia" := true;
                    Imagenes.Url := ImpagenesTemp.Url;
                    Imagenes.Nombre := ImpagenesTemp.Nombre;
                    If Imagenes.Insert() Then;
                end;
            until ImpagenesTemp.Next() = 0;

        CompanyInfo.Get();
        JsonFormater.WriteStartObject('');
        if rDet.Estado = rDet.Estado::Abierta then
            JsonFormater.WriteStringProperty('state', 'PENDING')
        else if rDet.Estado = rDet.Estado::EnProgreso then
            JsonFormater.WriteStringProperty('state', 'IN_PROGRESS')
        else if rDet.Estado = rDet.Estado::Cerrada then
            JsonFormater.WriteStringProperty('state', 'CLOSED');
        JsonFormater.WriteStringProperty('incidenceType', GetTipoIncidencia(Format(rDet."Tipo Incidencia")));
        JsonFormater.WriteStringProperty('observation', Observation);
        JsonFormater.WriteStringProperty('description', Description);
        If (Not Parada) and (Resource <> '') and (Encontrado) then begin
            wRecordRef.Close();
            if Empresa = '' Then Empresa := CompanyName;
            Recurso.ChangeCompany(Empresa);
            If Recurso.Get(Resource) then begin
                wRecordRef.Open(Database::Resource, false, Empresa);
                wRecordRef.Get(Recurso.RecordId);
                resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, Empresa);
                if resource = 'Error' then begin
                    CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                    resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, Empresa);
                end;
            end else
                resource := '';
        end else begin
            //TODO: Añadir Paradas en Gtask

            //wRecordRef.Close();
            // wRecordRef.Open(Database::"Emplazamientos", false, CompanyName);
            // wRecordRef.Get(ParadasBus.RecordId);
            // resource := GetMaestro('emplazamiento', ParadasBus.Name, 'name', wRecordRef, Database::"Emplazamientos", '');
            // if resource = 'Error' then begin
            //     
            Resource := '';
        end;

        //if resource <> '' then
        //  JsonFormater.WriteStringProperty('resource', resource);
        //else
        //  JsonFormater.WriteStringProperty('resource', '');
        if rDet.Id_Gtask = '' then NuevaIncidencia := true;
        If NuevaIncidencia then begin
            If ImpagenesTemp.FindFirst() Then begin
                JsonFormater.WriteStartArray('image');
                repeat
                    JsonFormater.WriteStartObject('');
                    JsonFormater.WriteStringProperty('_id', ImpagenesTemp.Id);
                    JsonFormater.WriteStringProperty('url', ImpagenesTemp.Url);
                    JsonFormater.WriteStringProperty('name', ImpagenesTemp.Nombre);
                    JsonFormater.WriteEndObject();
                until ImpagenesTemp.Next() = 0;
                JsonFormater.WriteEndArray();
            end;
        end;
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        Clear(RestApi);
        If (NuevaIncidencia) or (rDet.Id_Gtask = '') then
            Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'incidence', Token(), RequestType::post, Json)

        else
            Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'incidence/' + IdIncidencia, Token(), RequestType::put, Json);
        If Json <> '' then begin
            Clear(JsonIncidencia);
            If JsonIncidencia.ReadFrom(Json) then begin
                If JsonIncidencia.Get('_id', JsonCampo) then
                    Id := JsonCampo.AsValue().AsText();
            end;
        end;
        rDet.Modify();
        commit;
        rDet.Get(rDet."No.");
        if not DebePreservarDescripcionIncidencia(Description, rDet."No.") then begin
            rDet.SetWorkDescription(Description + ' ' + Observation);
            if rDet."Descripción" = '' then
                rDet."Descripción" := CopyStr(Observation, 1, MaxStrLen(rDet."Descripción"));
        end else
            if Observation <> '' then
                rDet.SetWorkDescription(rDet.GetWorkDescription() + ' ' + Observation);
        commit;
        rDet.Get(rDet."No.");
        rDet.CalcFields("Work Description"); // Evitar que el Modify siguiente sobrescriba el BLOB
        if Id <> '' then begin
            if StrLen(Id) > 30 then
                exit(DevolverError404('Error al generar Incidencia: el id devuelto excede la longitud permitida (30). Valor: ' + CopyStr(Id, 1, 50)));
            rDet.Id_Gtask := Id;
        end;
        If rDet.Recurso = '' Then rDet.Recurso := RecursoOriginal;
        rDet.Modify();
        Commit();

        If IdIncidencia <> '' then NuevaIncidencia := false;
        rDet.Get(rDet."No.");
        If rDet."Id Tarea Gtask" <> '' then begin
            ModifyTareaIncidencia(rDet);

        end;
        If not NuevaIncidencia then begin

            If rDet.Estado <> rDet.Estado::Cerrada then begin
                If (rDet."Id Tarea Gtask" = '') then begin
                    IdTarea := CrearTareaIncidencia(rDet);
                    If Strlen(IdTarea) <= 30 then
                        rDet."Id Tarea Gtask" := IdTarea
                    else begin

                        exit(DevolverError404('Error al crear la tarea: ' + IdTarea));
                    end;
                end;
            end;
        end;
        If not CabOrdenFijacion.Get(rDet."Nº Orden") then begin
            CabOrdenFijacion.Init();
            CabOrdenFijacion."Nº Orden" := rDet."Nº Orden";
            CabOrdenFijacion.Insert();
        end;
        If NuevaIncidencia Then begin
            EnviadoASC := false;
            Clear(MensajeMeta);
            if rDet."Es Peticion" then
                MensajeMeta := StrSubstNo('Mira Orden de trabajo nº %1: %2', rDet."No.", rDet.Descripción)
            else
                MensajeMeta := StrSubstNo('Mira Incidencia nº %1: %2', rDet."No.", rDet.Descripción);
            if Observation <> '' then
                MensajeMeta += ' | Observación: ' + Observation;
            if rDet.Recurso <> '' then begin
                if rDet."Tipo Elemento" = rDet."Tipo Elemento"::Parada then begin
                    MensajeMeta += ' | Parada: ' + rDet.Recurso;
                    if ParadasBus.Get(ParadasBus."Tipo Emplazamiento"::Opis, rDet.Recurso) then
                        MensajeMeta += ' | Parada: ' + ParadasBus."Descripción";
                end else begin
                    If not Recurso.Get(rDet.Recurso) then
                        Recurso.Init();

                    MensajeMeta += ' | Recurso: ' + rDet.Recurso + ' ' + Recurso.Name;
                end;
            end;
            MensajeMeta += ' — EMTGis https://taller.malla.es/?id=' + CopyStr(rDet."No.", 1, MaxStrLen(rDet."No."));
            Usuario.Reset();
            Usuario.SetRange("Id Usuario", rDet.Usuario);
            If not Usuario.FindSet() then
                Usuario.init;
            //Para el usurio 34651049109 el guid es {6a7fff89-f519-4695-bc0b-4c414b6e0736}
            //Para el usurio 34605264114 el guid es {ce35a5ab-f8f2-4634-8437-f83f4d99c820}

            //Recuperar el detalle de la categoría de todos los usuario de enviar whatsapp
            UsuariosGtaskxCatego.SetRange("User Task Group Code", rDet."User Task Group");
            UsuariosGtaskxCatego.SetRange("Enviar Whatsapp", true);
            if UsuariosGtaskxCatego.FindSet() then
                repeat
                    UserGtaskMalla.Reset();
                    UserGtaskMalla.SetRange("Id Usuario", UsuariosGtaskxCatego."User Security ID");
                    if UserGtaskMalla.FindSet() then
                        Procesos_GTask.EnviarMetaWhatsAppIncidenciaEmt(UserGtaskMalla."Teléfono", MensajeMeta, Usuario.Nombre, 'EMTGis', rDet.RecordId, UserGtaskMalla."Id Usuario", '', UserGtaskMalla.Nombre);
                    if UserGtaskMalla."Teléfono" = '34651049109' then
                        EnviadoASC := true;
                until UsuariosGtaskxCatego.Next() = 0;
            If not EnviadoASC then begin
                GuidEmt := CreateGuid();
                Evaluate(GuidEmt, '{6a7fff89-f519-4695-bc0b-4c414b6e0736}');

                Procesos_GTask.EnviarMetaWhatsAppIncidenciaEmt('34651049109', MensajeMeta, Usuario.Nombre, 'EMTGis', rDet.RecordId, GuidEmt, '', 'Andreu');
            end;
        end;

        if NotificarWhatsApp then begin
            If Procesos_GTask.NotificarUsuariosComunicadosPorWhatsApp(rDet) then;
        end;
        exit('OK:' + Id + ' Id_Gtask:' + rDet."Id Tarea Gtask");
    end;

    /// <summary>
    /// Devuelve un JSON con código HTTP 404 y mensaje de error para que el cliente lo interprete.
    /// El servicio OData sigue devolviendo 200; el cuerpo incluye "httpStatusCode":404 y "error".
    /// </summary>
    local procedure DevolverError404(MensajeError: Text): Text
    var
        JsonError: JsonObject;
        ResultText: Text;
    begin
        JsonError.Add('httpStatusCode', 404);
        JsonError.Add('error', CopyStr(MensajeError, 1, 2048));
        JsonError.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Crea tareas desde un array JSON. Por cada elemento: usuariogtask, description, category, resource, fechaHora.
    /// Responde con un array de tareas usando AgregarTareaUsuarioAlJson (o objeto con "error" si falla una).
    /// </summary>
    /// <param name="JsonText">JSON array: [{"usuariogtask":"...","description":"...","category":"...","resource":"...","fechaHora":"..."}, ...]</param>
    /// <returns>JSON array de tareas (mismo formato que GetTareasUsuario) o elementos {"error": "mensaje"}</returns>
    [ServiceEnabled]
    procedure postTarea(JsonText: Text): Text
    var
        JsonArrayEntrada: JsonArray;
        JsonArrayRespuesta: JsonArray;
        JsonToken: JsonToken;
        JsonTarea: JsonObject;
        JsonError: JsonObject;
        Tareas: Record "User Task";
        ErrorMsg: Text;
    begin
        // Ejemplo JSON entrada: [{"usuariogtask":"...","description":"...","category":"69807bab6823020012e97858","resource":"RECURSO01","fechaHora":"2025-11-13T10:00:00Z"}, ...]
        if not JsonArrayEntrada.ReadFrom(JsonText) then
            Error('JSON inválido. Se espera un array de tareas.');

        foreach JsonToken in JsonArrayEntrada do begin
            JsonTarea := JsonToken.AsObject();
            if Procesos_GTask.ProcesarUnaTareaPost(JsonTarea, Tareas, ErrorMsg) then begin
                Tareas.Get(Tareas.ID);
                Procesos_GTask.AgregarTareaUsuarioAlJson(Tareas, JsonArrayRespuesta);
            end else begin
                Clear(JsonError);
                JsonError.Add('error', CopyStr(ErrorMsg, 1, 250));
                JsonArrayRespuesta.Add(JsonError);
            end;
        end;

        JsonArrayRespuesta.WriteTo(JsonText);
        exit(JsonText);
    end;

    /// <summary>
    /// Crea una tarea (o varias) incluyendo checklist. Cada elemento debe llevar "checklist":[{"text":"..."},...].
    /// Identidad (prioridad): empleado / codigo_empleado → usuariogtask → email.
    /// resource opcional. category: id Gtask, código o descripción BC (p. ej. "Salida Oficina").
    /// Ejemplo: {"empleado":"000000001","description":"Salida Oficina","category":"Salida Oficina","fecha":"2026-08-13","checklist":[{"text":"Cliente A"}]}
    /// </summary>
    [ServiceEnabled]
    procedure postTareaChecklist(JsonText: Text): Text
    var
        JsonArrayEntrada: JsonArray;
        JsonArrayRespuesta: JsonArray;
        JsonObjEntrada: JsonObject;
        JsonToken: JsonToken;
        JsonTarea: JsonObject;
        JsonError: JsonObject;
        Tareas: Record "User Task";
        ErrorMsg: Text;
    begin
        if JsonArrayEntrada.ReadFrom(JsonText) then begin
            foreach JsonToken in JsonArrayEntrada do begin
                JsonTarea := JsonToken.AsObject();
                if Procesos_GTask.ProcesarUnaTareaPostChecklist(JsonTarea, Tareas, ErrorMsg) then begin
                    Tareas.Get(Tareas.ID);
                    Procesos_GTask.AgregarTareaUsuarioAlJson(Tareas, JsonArrayRespuesta);
                end else begin
                    Clear(JsonError);
                    JsonError.Add('error', CopyStr(ErrorMsg, 1, 250));
                    JsonArrayRespuesta.Add(JsonError);
                end;
            end;
        end else if JsonObjEntrada.ReadFrom(JsonText) then begin
            if Procesos_GTask.ProcesarUnaTareaPostChecklist(JsonObjEntrada, Tareas, ErrorMsg) then begin
                Tareas.Get(Tareas.ID);
                Procesos_GTask.AgregarTareaUsuarioAlJson(Tareas, JsonArrayRespuesta);
            end else begin
                Clear(JsonError);
                JsonError.Add('error', CopyStr(ErrorMsg, 1, 250));
                JsonArrayRespuesta.Add(JsonError);
            end;
        end else
            Error('JSON inválido. Se espera un objeto o un array de tareas con checklist.');

        JsonArrayRespuesta.WriteTo(JsonText);
        exit(JsonText);
    end;

    /// <summary>
    /// Recibe respuestas de WhatsApp desde la aplicación intermedia (webhook ya normalizado).
    /// Crea un registro en "Mensaje WhatsApp" y enlaza con incidencia si id_contexto coincide con un envío previo.
    /// Ejemplo: {"id_mensaje":"wamid...","id_contexto":"wamid...","telefono":"34651049109","texto":"Ok recibido"}
    /// </summary>
    [ServiceEnabled]
    procedure postRespuestaWhatsApp(JsonText: Text): Text
    begin
        exit(Procesos_GTask.ProcesarWebhookRespuestaWhatsApp(JsonText));
    end;

    [ServiceEnabled]
    procedure postIncidenciaemt(JsonText: Text): Text;
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonCampo: JsonToken;
        JsonTarea: JsonObject;
        JsonDetalleCampo: JsonObject;
        Json: Text;
        Tareas: Record "User Task";
        UserTaskGroup: Record "User Task Group";
        ResponsabilitiCenter: Record "Responsibility Center";
        WorkCenter: Record "Work Center";
        UserGtaskMalla: Record UsuariosGtask;
        rDet: Record Incidencias;
        RecordiD: RecordId;
        RecordRef: RecordRef;
        Job: Record Job;
        jSonDocument: JsonObject;
        DocumentAtt: Record "Document Attachment";
        Line: Integer;
        DocBase64: Text;
        Num: Integer;
        CodEmpresa: Text[2];
        Empresas: Record "Company";
        Texto: Text;
        DocuName: Text;
        DocumentAttachment2: Record "Document Attachment";
        DocumentAttachment3: Record "Document Attachment";
        CabOrdenFijacion: Record "Cab Orden fijación";
        FileManager: Codeunit "File Management";
        Encontrada: Boolean;
        Company: Record Company;
        Id: text;
        JsonFormater: Codeunit "Json Text Reader/Writer";
        CompanyInfo: Record "Company Information";
        RestApi: Codeunit "Control Ocr";
        RequestType: Option Get,patch,put,post,delete;
        JSONMgt: Codeunit "JSON Management";
        Name: Text;
        Value1: Text;
        Imagenes: Record "Imagenes Orden fijación";
        ImpagenesTemp: Record "Imagenes Orden fijación" temporary;
        wRecordRef: RecordRef;
        State: Text;
        JsonIncidencia: JsonObject;
        IncidenceType: Text;
        Observation: Text;
        Description: Text;
        Stop: Text;
        Frequency: Text;
        Departament: Text;
        Zone: Text;
        FileBase64: Text;
        Imagen: Integer;
        Control: Codeunit "ControlProcesos";
        Parada: Boolean;
        ParadasBus: Record "Emplazamientos";
        document: JsonObject;
        Usuario: Record UsuariosGtask;
        UsuarioId: Guid;
        IdIncidencia: Text;
        Fecha: DateTime;
        Empresa: Text;
        IdImagen: Integer;
        IdTarea: Text;
        Response: HttpResponseMessage;
        Peticion: Boolean;
        UsuarioPost: Text;
        MensajeMeta: Text;
        CodigoParadaStop: Code[20];
        UsuariosGtaskxCatego: Record "User Task Group Member";
        GuidEmt: Guid;
        EnviadoASC: Boolean;
        Label1000: Label 'Desmuntatge de banc de fusta de qualsevol dels models EMT Palma inclosa la reposició i l''acabat del paviment si fos necessari.';
        Label2000: Label 'Desmuntatge de marquesina qualsevol model, inclosa la demolició, la reposició i l''acabat del paviment en la ubicació de la marquesina desmuntada.';
        Label3000: Label 'Desmuntatge de pal de parada de qualsevol dels models EMT Palma inclosa la reposició i l''acabat del paviment si fos necessari.';
        Label4000: Label 'Instal·lació completa de marquesina model Ma2 inclosa l''excavació, execució de la fonamentació de la marquesina i la reposició i l''acabat del paviment.';
        Label5000: Label 'Instal·lació completa de marquesina model Ma4 inclosa l''excavació, execució de la fonamentació de la marquesina i la reposició i l''acabat del paviment.';
        Label6000: Label 'Instal·lació de banc de fusta de qualsevol dels models EMT Palma inclosa la reposició i l''acabat del paviment si fos necessari.';
        Label7000: Label 'Instal·lació de pal de parada de qualsevol dels models EMT Palma inclosa la reposició i l''acabat del paviment si fos necessari.';
        Label8000: Label 'Realitzar connexió elèctrica del mobiliari a la xarxa';
        Label9000: Label 'Trasllat de banc de fusta (qualsevol model) entre ubicació de parada i magatzem o viceversa.';
        Label9500: Label 'Trasllat de pal de parada (qualsevol model) entre ubicació de parada i magatzem o viceversa.';
        Label9600: Label 'Trasllat del conjunt d''elements d''una marquesina desmuntada (qualsevol model) entre ubicació de parada i magatzem o viceversa.';
        plantilla: Text;
    begin
        //        {
        //     "description": "Fijar y sustituir elementos que NO suponen riesgo para usuarios de zona no crítica con una frecuencia de 96h del departamento Técnico",
        //     "zone": "zona no crítica",
        //     observation: "Frecuencia: 96h | Departamento: Técnico | Zona: zona no crítica | Parada: Illetes - ct.Andratx"
        //     "frequency": "96h",
        //     "department": "Técnico",
        //     "stop": {
        //         "number": "145",
        //         "name": "Illetes - ct.Andratx"
        //     },
        // "image": [
        // "document":{
        // "file": "https://..............",
        // "name": "imagen1.jpg"
        // },
        // {
        // "file": "https://..............",
        // "name": "imagen2.png"
        // }
        // ]
        // }
        //100: Limpieza
        //200: Limpieza
        //300: Mantenimiento
        //400: Mantenimiento
        //500: Mantenimiento
        //600: Mantenimiento
        //700: Tip
        //800: Electrica
        //Ejemplo Descripcion 100: Neteja/101: Vicres Bruts
        JsonIncidencia.ReadFrom(JsonText);
        if JsonIncidencia.Get('_id', JsonCampo) Then IdIncidencia := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('state', JsonCampo) Then
            State := JsonCampo.AsValue().AsText();
        ResolverUsuarioPostIncidenciaEmt(JsonIncidencia, Usuario, UsuarioId, UsuarioPost);
        If JsonIncidencia.Get('incidenceType', JsonCampo) Then
            IncidenceType := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('observation', JsonCampo) Then
            Observation := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('description', JsonCampo) Then
            Description := JsonCampo.AsValue().AsText();
        Case Description Of
            Label1000:
                Plantilla := '100';
            Label2000:
                Plantilla := '200';
            Label3000:
                Plantilla := '300';
            Label4000:
                Plantilla := '400';
            Label5000:
                Plantilla := '500';
            Label6000:
                Plantilla := '600';
            Label7000:
                Plantilla := '700';
            Label8000:
                Plantilla := '800';
            Label9000:
                Plantilla := '900';
            Label9500:
                Plantilla := '950';
        End;
        If JsonIncidencia.Get('peticion', JsonCampo) Then
            Peticion := JsonCampo.AsValue().AsBoolean();
        // If JsonIncidencia.Get('resource', JsonCampo) Then
        //     Resource := JsonCampo.AsValue().AsText();
        Clear(Stop);
        Clear(CodigoParadaStop);
        If JsonIncidencia.Get('stop', JsonCampo) Then
            ParsearStopPostIncidenciaEmt(JsonCampo, Stop, CodigoParadaStop);
        //If (Resource = '') and (Stop <> '') Then
        //    Resource := Stop;
        //RecursoOriginal := Resource;
        If JsonIncidencia.Get('frequency', JsonCampo) Then
            Frequency := JsonCampo.AsValue().AsText();
        if Frequency = 'N/A' then Frequency := '';
        If JsonIncidencia.Get('departament', JsonCampo) Then
            Departament := JsonCampo.AsValue().AsText();
        If (Departament = '') and JsonIncidencia.Get('department', JsonCampo) Then
            Departament := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('zone', JsonCampo) Then
            Zone := JsonCampo.AsValue().AsText();
        // Si observation viene vacío y tenemos campos separados, construir como en Python: "Frecuencia: X | Departamento: Y | Zona: Z | Parada: W"
        if (Observation = '') and ((Frequency <> '') or (Departament <> '') or (Zone <> '') or (Stop <> '')) then
            Observation := ConstruirObservationDesdePartes(Observation, Frequency, Departament, Zone, Stop);
        //Fecha AAAA-MM-DD 2025-11-13 o formato ISO 2025-11-11T23:00:00Z
        // Priorizar fechaHora si existe, sino usar fecha
        If JsonIncidencia.Get('fechahora', JsonCampo) Then begin
            Fecha := JsonCampo.AsValue().AsDateTime() - 1 * 3600 * 1000; // restar 1 hora;
        end else if JsonIncidencia.Get('fecha', JsonCampo) Then begin
            Fecha := Procesos_GTask.ParseFechaFromJson(JsonCampo.AsValue().AsText());
        end else
            Fecha := CurrentDateTime();
        If JsonIncidencia.Get('image', JsonCampo) Then begin
            JsonArray := JsonCampo.AsArray();
            foreach JsonToken in JsonArray do begin
                document := JsonToken.AsObject();
                // El JSON tiene la estructura: {"document": {"file": "...", "name": "..."}}
                if document.Get('document', JsonCampo) then begin
                    document := JsonCampo.AsObject();
                    if document.Get('file', JsonCampo) then begin
                        Imagen += 1;
                        DocuName := 'Imagen' + Format(Imagen) + '_' + Format(CurrentDateTime, 0, 9) + '.jpg';
                        FileBase64 := JsonCampo.AsValue().AsText();
                        If CopyStr(FileBase64, 1, 4) = 'http' then begin
                            ImpagenesTemp.Url := FileBase64;
                        end else begin
                            if CopyStr(FileBase64, 1, 5) = 'data:' then
                                if StrPos(FileBase64, ',') > 0 then
                                    FileBase64 := CopyStr(FileBase64, StrPos(FileBase64, ',') + 1);
                            ImpagenesTemp.Url := Control.FormBase64ToUrl(FileBase64, DocuName, IdImagen);
                            ImpagenesTemp.Id := IdImagen;
                        end;
                        ImpagenesTemp."Nº Imagen" := Imagen;
                        if document.Get('name', JsonCampo) then
                            ImpagenesTemp.Nombre := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(ImpagenesTemp.Nombre))
                        else
                            ImpagenesTemp.Nombre := DocuName;
                        if document.Get('file_id', JsonCampo) then
                            If evaluate(ImpagenesTemp.Id, JsonCampo.AsValue().AsText()) Then;
                        If ImpagenesTemp.Id = 0 then ImpagenesTemp.Id := IdImagen;
                        if ImpagenesTemp.Id = 0 then Error('Imagen no encontrada');
                        ImpagenesTemp.Insert();
                        IdImagen := 0;
                    end;
                end;
            end;
        end;
        Parada := true;
        rDet.Init();
        rDet."Tipo Elemento" := rDet."Tipo Elemento"::Parada;
        rDet.Fecha := DT2Date(Fecha);
        rDet.Plantilla := Format(Plantilla);
        rDet.FechaHora := Fecha;
        rDet.Descripción := CopyStr(Description, 1, MaxStrLen(rDet.Descripción));
        rDet."Frecuencia" := CopyStr(Frequency, 1, MaxStrLen(rDet."Frecuencia"));
        if CodigoParadaStop <> '' then
            rDet.Recurso := CodigoParadaStop
        else if Stop <> '' then
            rDet.Recurso := CopyStr(Stop, 1, MaxStrLen(rDet.Recurso));
        if IsNullGuid(UsuarioId) = false then
            rDet.Usuario := UsuarioId;
        if IsNullGuid(rDet."Usuario Seguimiento") then
            if IsNullGuid(UsuarioId) = false then
                rDet."Usuario Seguimiento" := UsuarioId;
        // case IncidenceType of

        //     'EMT':
        //         begin
        //             rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias EMT";
        //             rDet."User Task Group" := 'EMT';
        //         end;
        //     'VILLENA':
        //         begin
        //             rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Villena";
        //             rDet."User Task Group" := 'MTO';
        //         end;
        //     'ELECTRICIDAD', 'Electricidad', 'TALLER', 'Taller':
        //         begin
        //             rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Electricas";
        //             rDet."User Task Group" := 'MTO';
        //         end;
        //     'MTO', 'Mobiliario Urbano':
        //         begin
        //             rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Mobiliario Urbano";
        //             rDet."User Task Group" := 'MTO';
        //         end;
        //     'TAREA TALLER', 'Grupo Taller':
        //         begin
        //             rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Grupo Taller";
        //             rDet."User Task Group" := 'MTO';
        //         end;
        //     'PODA', 'Poda':
        //         begin
        //             rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Poda";
        //             rDet."User Task Group" := 'PODA';
        //         end;
        // end;
        rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias EMT";
        case copystr(Description, 1, 3) of
            '100':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Limpieza;
            '200':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Limpieza;
            '300':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Mantenimiento;
            '400':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Mantenimiento;
            '500':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Mantenimiento;
            '600':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Mantenimiento;
            '700':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Tip;
            '800':
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Electrica;
            else
                rDet."SubTipo Incidencia" := rDet."SubTipo Incidencia"::Otras;
        end;
        case Uppercase(State) of
            'PENDING', 'ABIERTA':
                rDet.Estado := rDet.Estado::Abierta;
            'IN_PROGRESS', 'EN_PROCESO':
                rDet.Estado := rDet.Estado::EnProgreso;
            'COMPLETED', 'CLOSED', 'CERRADA':
                begin
                    rDet.Estado := rDet.Estado::Cerrada;
                    ActualizarMantenimientoDesdeIncidencia(rDet);
                end;
        end;
        rDet.Empresa := Empresa;

        rDet."Enviar Correo" := true;
        rDet."Es Peticion" := Peticion;
        rDet."Comunicado por EMT" := true;
        Procesos_GTask.CalcularFechaActuacionDesdeFrecuencia(rDet, Frequency);
        rDet.Insert(true);
        commit;
        rdet.get(rdet."No.");
        rDet.SetWorkDescription(Description + ' ' + Observation);
        commit;
        If ImpagenesTemp.FindSet() then
            repeat
                Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
                Imagenes.SetRange("Es Incidencia", true);
                Imagenes.SetRange(Url, ImpagenesTemp.Url);
                If not Imagenes.FindFirst() then begin
                    Imagenes.Reset;
                    Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
                    Imagenes.SetRange("Es Incidencia", true);
                    if Imagenes.FindLast() then
                        Imagen := Imagenes."Nº Imagen" + 1
                    else
                        Imagen := 1;
                    Imagenes.Init();
                    Imagenes."Nº Orden" := rDet."Nº Orden";
                    Imagenes."Nº Imagen" := Imagen;
                    Imagenes.Id := ImpagenesTemp.Id;
                    Imagenes."Es Incidencia" := true;
                    Imagenes.Url := ImpagenesTemp.Url;
                    Imagenes.Nombre := ImpagenesTemp.Nombre;
                    Imagenes.Insert();
                end;
            until ImpagenesTemp.Next() = 0;

        CompanyInfo.Get();
        JsonFormater.WriteStartObject('');
        if rDet.Estado = rDet.Estado::Abierta then
            JsonFormater.WriteStringProperty('state', 'PENDING')
        else if rDet.Estado = rDet.Estado::EnProgreso then
            JsonFormater.WriteStringProperty('state', 'IN_PROGRESS')
        else if rDet.Estado = rDet.Estado::Cerrada then
            JsonFormater.WriteStringProperty('state', 'CLOSED');
        JsonFormater.WriteStringProperty('incidenceType', GetTipoIncidencia(Format(rDet."Tipo Incidencia")));
        JsonFormater.WriteStringProperty('observation', Observation);
        JsonFormater.WriteStringProperty('description', Description);
        if CodigoParadaStop <> '' then
            JsonFormater.WriteStringProperty('stop', CodigoParadaStop) else
            if Stop <> '' then
                JsonFormater.WriteStringProperty('stop', Stop);
        if Frequency <> '' then
            JsonFormater.WriteStringProperty('frequency', Frequency);
        if Departament <> '' then
            JsonFormater.WriteStringProperty('departament', Departament);
        if Zone <> '' then
            JsonFormater.WriteStringProperty('zone', Zone);
        If ImpagenesTemp.FindFirst() Then begin
            JsonFormater.WriteStartArray('image');
            repeat
                JsonFormater.WriteStartObject('');
                JsonFormater.WriteStringProperty('_id', ImpagenesTemp.Id);
                JsonFormater.WriteStringProperty('url', ImpagenesTemp.Url);
                JsonFormater.WriteStringProperty('name', ImpagenesTemp.Nombre);
                JsonFormater.WriteEndObject();
            until ImpagenesTemp.Next() = 0;
            JsonFormater.WriteEndArray();
        end;
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        Clear(RestApi);
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'incidence', Token(), RequestType::post, Json);
        If Json <> '' then begin
            Clear(JsonIncidencia);
            If JsonIncidencia.ReadFrom(Json) then begin
                If JsonIncidencia.Get('_id', JsonCampo) then
                    Id := JsonCampo.AsValue().AsText();
            end;
        end;
        rDet.Get(rDet."No.");
        rDet.CalcFields("Work Description"); // Evitar que el Modify siguiente sobrescriba el BLOB
        if Id <> '' then
            rDet.Id_Gtask := Id;
        rDet.Modify();
        Commit();

        rDet.Get(rDet."No.");
        If not CabOrdenFijacion.Get(rDet."Nº Orden") then begin
            CabOrdenFijacion.Init();
            CabOrdenFijacion."Nº Orden" := rDet."Nº Orden";
            CabOrdenFijacion.Insert();
        end;
        // si es peticion, El mensaje no es Incidencia, si no Orden de tabajo
        if Peticion then
            MensajeMeta := StrSubstNo('Mira Orden de trabajo EMT nº %1: %2', rDet."No.", Description)
        else
            MensajeMeta := StrSubstNo('Mira Incidencia EMT nº %1: %2', rDet."No.", Description);

        if Observation <> '' then
            MensajeMeta += ' | Observación: ' + Observation;
        if CodigoParadaStop <> '' then
            MensajeMeta += ' | Parada: ' + CodigoParadaStop
        else
            if Stop <> '' then
                MensajeMeta += ' | Parada: ' + Stop;
        MensajeMeta += ' — EMT https://taller.malla.es/?id=' + CopyStr(rDet."No.", 1, MaxStrLen(rDet."No."));
        //Procesos_GTask.EnviarMetaWhatsAppIncidenciaEmt('34605264114', MensajeMeta, UsuarioPost, 'EMTAlert', rDet.RecordId, GuidEmt2, '', WaNombreOperario);
        //Recuperar el detalle de la categoría de todos los usuario de enviar whatsapp
        EnviadoASC := false;
        UsuariosGtaskxCatego.SetRange("User Task Group Code", 'EMT');
        UsuariosGtaskxCatego.SetRange("Enviar Whatsapp", true);
        if UsuariosGtaskxCatego.FindSet() then
            repeat
                UserGtaskMalla.Reset();
                UserGtaskMalla.SetRange("Id Usuario", UsuariosGtaskxCatego."User Security ID");
                if UserGtaskMalla.FindFirst() then
                    Procesos_GTask.EnviarMetaWhatsAppIncidenciaEmt(UserGtaskMalla."Teléfono", MensajeMeta, UsuarioPost, 'EMTAlert', rDet.RecordId, UserGtaskMalla."Id Usuario", '', UserGtaskMalla.Nombre);
                if UserGtaskMalla."Teléfono" = '34651049109' then
                    EnviadoASC := true;
            until UsuariosGtaskxCatego.Next() = 0;
        If not EnviadoASC then begin
            GuidEmt := CreateGuid();
            Evaluate(GuidEmt, '{6a7fff89-f519-4695-bc0b-4c414b6e0736}');

            Procesos_GTask.EnviarMetaWhatsAppIncidenciaEmt('34651049109', MensajeMeta, UsuarioPost, 'EMTAlert', rDet.RecordId, GuidEmt, '', 'Andreu');
        end;

        exit('OK:' + Id);
    end;

    [ServiceEnabled]
    procedure DetalleIncidencia(JsonText: Text): text
    var
        Incidencias: Record "Incidencias";
        Imagenes: Record "Imagenes Orden fijación";
        JsonFormater: Codeunit "Json Text Reader/Writer";
        Json: Text;
        IdIncidencia: Text;
        JsonObject: JsonObject;
        JsonCampo: JsonToken;
        Descripcion: Text;
        Recurso: Record Resource;
        Emplazamientos: Record "Emplazamientos";
    begin
        //{'jsonText': '{"IdIncidencia": "6915e2dd4506a500111c8360"}'}
        if JsonObject.ReadFrom(JsonText) then begin
            if JsonObject.Get('IdIncidencia', JsonCampo) then
                IdIncidencia := JsonCampo.AsValue().AsText();
        end else
            Error('Error al leer el JSON: %1', JsonText);
        Incidencias.SetRange(Id_Gtask, IdIncidencia);
        //Devulve json en blanco

        if Not Incidencias.FindFirst() then
            If not Incidencias.Get(Copystr(IdIncidencia, 1, 20)) Then
                Error('Incidencia no encontrada: %1', IdIncidencia);

        Imagenes.SetRange("Nº Orden", Incidencias."Nº Orden");
        Imagenes.SetRange("Es Incidencia", true);
        JsonFormater.WriteStartObject('');
        Descripcion := Incidencias."Descripción";
        if EsTextoPlaceholderCierreIncidencia(Descripcion, Incidencias."No.") then
            Descripcion := '';
        if Descripcion = '' then begin
            Descripcion := Incidencias.GetWorkDescription();
            if EsTextoPlaceholderCierreIncidencia(Descripcion, Incidencias."No.") then
                Descripcion := Incidencias."Descripción";
        end;
        JsonFormater.WriteStringProperty('description', Descripcion);
        JsonFormater.WriteStringProperty('state', Incidencias.Estado);
        JsonFormater.WriteStringProperty('incidenceType', Format(Incidencias."Tipo Incidencia"));
        JsonFormater.WriteStringProperty('subIncidenceType', Format(Incidencias."SubTipo Incidencia"));
        JsonFormater.WriteStringProperty('resource', Incidencias.Recurso);
        //tipo elemento
        JsonFormater.WriteStringProperty('type', Format(Incidencias."Tipo Elemento"));
        //Nombre del Recurso
        JsonFormater.WriteStringProperty('resource_name', Incidencias.NombreElemento());
        JsonFormater.WriteStringProperty('fecha', Format(Incidencias.FechaHora, 0, '<Year4>-<Month,2>-<Day,2>T<Hour,2>:<Minute,2>:<Second,2>Z'));
        JsonFormater.WriteStringProperty('user', Incidencias.NombreUsuario(Incidencias.Usuario));
        JsonFormater.WriteStringProperty('user_name', Incidencias.ID_UsuarioGtask(Incidencias.Usuario));
        JsonFormater.WriteStringProperty('user_assigned', Incidencias.ID_UsuarioGtask(Incidencias."Usuario Asignado"));
        JsonFormater.WriteStringProperty('user_assigned_name', Incidencias.NombreUsuario(Incidencias."Usuario Asignado"));
        JsonFormater.WriteStringProperty('user_follow', Incidencias.ID_UsuarioGtask(Incidencias."Usuario Seguimiento"));
        JsonFormater.WriteStringProperty('user_follow_name', Incidencias.NombreUsuario(Incidencias."Usuario Seguimiento"));
        JsonFormater.WriteStringProperty('comunicado_por_emt', Incidencias."Comunicado por EMT");
        //JsonFormater.WriteStringProperty('id_task', Incidencias."ID Tarea Gtask");
        //Añadir geplocañlización PuntoX yPuntoY del emplazamiento o recurso
        If Incidencias."Tipo Elemento" = Incidencias."Tipo Elemento"::Recurso then begin
            If Recurso.Get(Incidencias.Recurso) then begin
                JsonFormater.WriteStringProperty('puntoX', Recurso.PuntoX);
                JsonFormater.WriteStringProperty('puntoY', Recurso.PuntoY);
            end;
        end else begin
            If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, Incidencias.Recurso) then begin
                JsonFormater.WriteStringProperty('puntoX', Emplazamientos.PuntoX);
                JsonFormater.WriteStringProperty('puntoY', Emplazamientos.PuntoY);
            end;
        end;
        If Imagenes.FindSet() then begin
            JsonFormater.WriteStartArray('image');
            repeat
                JsonFormater.WriteStartObject('');
                JsonFormater.WriteStringProperty('_id', Imagenes.Id);
                JsonFormater.WriteStringProperty('url', Imagenes.Url);
                JsonFormater.WriteStringProperty('name', Imagenes.Nombre);
                JsonFormater.WriteEndObject();
            until Imagenes.Next() = 0;
            JsonFormater.WriteEndArray();


        end;
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        exit(Json);
    end;

    /// <summary>
    /// Incidencia abierta más reciente en parada o recurso. Devuelve false si no hay ninguna.
    /// </summary>
    local procedure BuscarIncidenciaAbiertaReciente(Parada: Code[20]; Recurso: Code[20]; var Incidencias: Record Incidencias): Boolean
    var
        IncidenciasBuf: Record Incidencias;
        MejorFecha: DateTime;
        MejorNo: Code[20];
    begin
        IncidenciasBuf.Reset();
        IncidenciasBuf.SetFilter(Estado, '%1|%2', IncidenciasBuf.Estado::Abierta, IncidenciasBuf.Estado::EnProgreso);
        if Parada <> '' then begin
            IncidenciasBuf.SetRange("Tipo Elemento", IncidenciasBuf."Tipo Elemento"::Parada);
            IncidenciasBuf.SetRange(Recurso, Parada);
        end else begin
            IncidenciasBuf.SetRange("Tipo Elemento", IncidenciasBuf."Tipo Elemento"::Recurso);
            IncidenciasBuf.SetRange(Recurso, Recurso);
        end;

        MejorFecha := 0DT;
        MejorNo := '';
        if IncidenciasBuf.FindSet() then
            repeat
                if (IncidenciasBuf."FechaHora" > MejorFecha) or (MejorNo = '') then begin
                    MejorFecha := IncidenciasBuf."FechaHora";
                    MejorNo := IncidenciasBuf."No.";
                end;
            until IncidenciasBuf.Next() = 0;

        if MejorNo = '' then
            exit(false);
        exit(Incidencias.Get(MejorNo));
    end;

    /// <summary>
    /// Devuelve ID Tarea Gtask; si falta y la incidencia está abierta, crea la tarea (misma lógica que postIncidencia).
    /// </summary>
    local procedure AsegurarTareaGtaskIncidencia(var rDet: Record Incidencias): Text
    var
        UserTask: Record "User Task";
        Emplazamientos: Record Emplazamientos;
        IdCreado: Text;
        NoRecurso: Code[20];
    begin
        if rDet."ID Tarea Gtask" <> '' then
            exit(rDet."ID Tarea Gtask");
        if rDet.Estado = rDet.Estado::Cerrada then
            exit('');
        if rDet.Id_Gtask = '' then
            exit('Error: La incidencia no está enlazada con GTask (falta Id_Gtask)');

        // Tarea BC ya existe pero aún no se publicó en GTask: solo POST task (evita duplicar User Task)
        if rDet."Id_Tarea" <> 0 then begin
            if UserTask.Get(rDet."Id_Tarea") then begin
                if (IdQrOrdenTrabajo(rDet) <> '') and (UserTask.IdQr <> IdQrOrdenTrabajo(rDet)) then begin
                    UserTask.IdQr := IdQrOrdenTrabajo(rDet);
                    UserTask.Modify(false);
                    Commit();
                end else
                    if (UserTask.IdQr = '') and (rDet.Id_Gtask <> '') then begin
                        UserTask.IdQr := rDet.Id_Gtask;
                        UserTask.Modify(true);
                        Commit();
                    end;
                if rDet."Tipo Elemento" = rDet."Tipo Elemento"::Parada then begin
                    if Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, rDet.Recurso) then
                        NoRecurso := Emplazamientos."Nº Emplazamiento"
                    else
                        NoRecurso := rDet.Recurso;
                end else
                    NoRecurso := rDet.Recurso;
                IdCreado := CrearTareaIncidencia(NoRecurso, UserTask, UserTask.Departamento, UserTask.Servicio, true);
                if (IdCreado <> '') and (StrLen(IdCreado) <= 30) and (CopyStr(IdCreado, 1, 5) <> 'Error') then begin
                    rDet."Id Tarea Gtask" := IdCreado;
                    rDet.Modify(true);
                    Commit();
                    exit(IdCreado);
                end;
                if IdCreado <> '' then
                    exit(IdCreado);
            end;
        end;

        IdCreado := CrearTareaIncidencia(rDet);
        if IdCreado = '' then
            exit('');
        if (StrLen(IdCreado) > 30) or (CopyStr(IdCreado, 1, 5) = 'Error') then
            exit(IdCreado);
        rDet.Get(rDet."No.");
        exit(rDet."ID Tarea Gtask");
    end;

    /// <summary>
    /// Devuelve el ID Tarea Gtask de la incidencia abierta más reciente en la parada o recurso indicado.
    /// Si la incidencia existe pero aún no tiene tarea GTask, la crea (CrearTareaIncidencia).
    /// Entrada JSON: {"parada":"..."} o {"recurso":"..."} (al menos uno).
    /// Salida JSON: {"encontrado":true,"idTareaGtask":"...","idQr":"...","noIncidencia":"...","tareaCreada":true} o {"encontrado":false}.
    /// </summary>
    [ServiceEnabled]
    procedure GetIncidenciaTareaGtask(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonFormater: Codeunit "Json Text Reader/Writer";
        Incidencias: Record Incidencias;
        Parada: Code[20];
        Recurso: Code[20];
        Json: Text;
        IdTarea: Text;
        TeniaTarea: Boolean;
        TareaCreada: Boolean;
    begin
        Clear(JsonFormater);
        if not JsonObject.ReadFrom(JsonText) then begin
            JsonFormater.WriteStartObject('');
            JsonFormater.WriteBooleanProperty('encontrado', false);
            JsonFormater.WriteStringProperty('error', 'JSON inválido');
            JsonFormater.WriteEndObject();
            exit(JsonFormater.GetJSonAsText());
        end;

        Parada := '';
        Recurso := '';
        if JsonObject.Get('parada', JsonToken) then
            Parada := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Parada));
        if JsonObject.Get('recurso', JsonToken) then
            Recurso := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Recurso));

        if (Parada = '') and (Recurso = '') then begin
            JsonFormater.WriteStartObject('');
            JsonFormater.WriteBooleanProperty('encontrado', false);
            JsonFormater.WriteStringProperty('error', 'Indique parada o recurso');
            JsonFormater.WriteEndObject();
            exit(JsonFormater.GetJSonAsText());
        end;

        JsonFormater.WriteStartObject('');
        if not BuscarIncidenciaAbiertaReciente(Parada, Recurso, Incidencias) then begin
            JsonFormater.WriteBooleanProperty('encontrado', false);
            JsonFormater.WriteEndObject();
            exit(JsonFormater.GetJSonAsText());
        end;

        TeniaTarea := Incidencias."ID Tarea Gtask" <> '';
        IdTarea := AsegurarTareaGtaskIncidencia(Incidencias);
        TareaCreada := (not TeniaTarea) and (Incidencias."ID Tarea Gtask" <> '');

        if (IdTarea <> '') and (CopyStr(IdTarea, 1, 5) <> 'Error') then begin
            JsonFormater.WriteBooleanProperty('encontrado', true);
            JsonFormater.WriteStringProperty('idTareaGtask', IdTarea);
            if Incidencias.Id_Gtask <> '' then
                JsonFormater.WriteStringProperty('idQr', Incidencias.Id_Gtask);
            JsonFormater.WriteStringProperty('noIncidencia', Incidencias."No.");
            if TareaCreada then
                JsonFormater.WriteBooleanProperty('tareaCreada', true);
        end else begin
            JsonFormater.WriteBooleanProperty('encontrado', true);
            JsonFormater.WriteStringProperty('noIncidencia', Incidencias."No.");
            if IdTarea <> '' then
                JsonFormater.WriteStringProperty('error', IdTarea)
            else
                JsonFormater.WriteStringProperty('error', 'No se pudo crear la tarea GTask para la incidencia');
        end;
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        exit(Json);
    end;

    /// <summary>
    /// Devuelve el historial de incidencias para consulta:
    /// - Comunicadas por EMT: todas (pendientes y resueltas); el cliente puede usar "resuelta" para distinto color.
    /// - Generadas por Malla: solo las resueltas.
    /// En todos los registros se incluye fecha de actuación, estado, fecha de resolución (si está cerrada), descripción y parada.
    /// </summary>
    [ServiceEnabled]
    procedure GetHistorialIncidencias(): Text
    var
        Incidencias: Record Incidencias;
        JsonFormater: Codeunit "Json Text Reader/Writer";
        Json: Text;
    begin
        Clear(JsonFormater);
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStartArray('incidencias');

        // 1) Incidencias comunicadas por EMT: todas (pendientes y resueltas)
        Incidencias.SetRange("Comunicado por EMT", true);
        if Incidencias.FindSet() then
            repeat
                Procesos_GTask.EscribirIncidenciaHistorial(Incidencias, JsonFormater);
            until Incidencias.Next() = 0;

        // 2) Incidencias generadas por Malla: solo visibles cuando están resueltas
        Incidencias.Reset();
        Incidencias.SetRange("Comunicado por EMT", false);
        Incidencias.SetRange(Estado, Incidencias.Estado::Cerrada);
        Incidencias.SetRange("Tipo Incidencia", Incidencias."Tipo Incidencia"::"Incidencias EMT");
        if Incidencias.FindSet() then
            repeat
                Procesos_GTask.EscribirIncidenciaHistorial(Incidencias, JsonFormater);
            until Incidencias.Next() = 0;

        JsonFormater.WriteEndArray();
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        exit(Json);
    end;

    /// <summary>
    /// GetPartes.
    /// </summary>
    [ServiceEnabled]
    procedure GetPartes(): Text
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

    [ServiceEnabled]

    procedure CreateParte(Var Task: Record "User Task"): Text
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
        if Job."Bill-to Customer No." = '' then Job."Bill-to Customer No." := '426'; // emt, hay que ponerlo en un configurador'
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
        If Job."No." <> '' Then begin
            wRecordRef.Get(Job.RecordId);
            Proyecto := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
            if Proyecto = 'Error' then begin
                CreaProyecto(Job, Job.RecordId, Database::Job);
                Proyecto := GetMaestro('project', Job.Description, 'name', wRecordRef, Database::Job, '');
            end;
            wRecordRef.Close();
        end else
            Proyecto := '';
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
        if Proyecto <> '' then
            JsonFormater.WriteStringProperty('project', Proyecto);
        JsonFormater.WriteStringProperty('startDate', Hora(Task."Start DateTime"));
        JsonFormater.WriteStringProperty('endDate', Hora(Task."Start DateTime"));
        JsonFormater.WriteStartArray('lines');
        NOrden := Task.OrdenFijacion;
        if NOrden <> 0 then begin
            OrdenFijajon.SetRange("Nº Orden", NOrden);
            If OrdenFijajon.FindFirst() then
                repeat
                    if (OrdenFijajon."Nº Recurso" <> '') and Resource.Get(OrdenFijajon."Nº Recurso") then begin
                        JsonFormater.WriteStartObject('');
                        Clear(wRecordRef);
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
                    end;
                until ordenFijajon.Next() = 0;
        end;
        JsonFormater.WriteEndArray();
        JsonFormater.WriteEndObject();
        Json := JsonFormater.GetJSonAsText();
        CompanyInfo.Get();
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'workorder', Token(), RequestType::post, jSon);
        JSONMgt.InitializeObject(Json);
        If JSONMgt.ReadProperties() then
            WHILE JSONMgt.GetNextProperty(Name, Value1) DO BEGIN
                CASE Name OF
                    '_id':
                        begin
                            exit(Value1);
                        end;
                end;
            end;
    end;

    [ServiceEnabled]
    procedure GetTareasLimpieza(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonTarea: JsonObject;
        UserTask: Record "User Task";
        Emplazamientos: Record Emplazamientos;
        EmplazamientosFiltrados: Record Emplazamientos;
        ZonaLimpieza: Integer;
        CodigoEmplazamiento: Code[20];
        FechaDesdeTexto: Text;
        FechaHastaTexto: Text;
        FechaDesde: Date;
        FechaHasta: Date;
        FechaDesdeDT: DateTime;
        FechaHastaDT: DateTime;
        CategoriasLimpieza: Text;
        JsonResult: Text;
        RecordIdEmplazamiento: RecordId;
        IdResponsabel: Text;
        UserGtask: Record UsuariosGtask;
        ZonasLimpieza: Record "Zonas Limpieza";
        FiltroZonasLimpieza: Text;

    begin
        // Leer JSON de entrada
        if not JsonObject.ReadFrom(JsonText) then
            Error('JSON inválido');

        // Inicializar variables
        ZonaLimpieza := 0;
        CodigoEmplazamiento := '';
        FechaDesde := 0D;
        FechaHasta := 0D;

        // Obtener zona de limpieza (opcional)
        if JsonObject.Get('zonaLimpieza', JsonToken) then begin
            if not Evaluate(ZonaLimpieza, JsonToken.AsValue().AsText()) then
                ZonaLimpieza := 0;
        end;

        // Obtener código de emplazamiento (opcional)
        if JsonObject.Get('codigoEmplazamiento', JsonToken) then
            CodigoEmplazamiento := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(CodigoEmplazamiento));

        // Obtener fecha desde (opcional)
        if JsonObject.Get('fechaDesde', JsonToken) then begin
            FechaDesdeTexto := JsonToken.AsValue().AsText();
            if Evaluate(FechaDesde, FechaDesdeTexto) then
                FechaDesdeDT := CreateDateTime(FechaDesde, 0T)
            else
                FechaDesde := 0D;
        end;

        // Obtener fecha hasta (opcional)
        if JsonObject.Get('fechaHasta', JsonToken) then begin
            FechaHastaTexto := JsonToken.AsValue().AsText();
            if Evaluate(FechaHasta, FechaHastaTexto) then
                FechaHastaDT := CreateDateTime(FechaHasta, 235959T)
            else
                FechaHasta := 0D;
        end;

        // // Obtener categorías de tipo LIMPIEZA
        // UserTaskGroup.ChangeCompany('Malla Publicidad');
        // UserTaskGroup.SetRange("Tipo de Tarea", 'LIMPIEZA');
        // CategoriasLimpieza := '';
        // if UserTaskGroup.FindSet() then begin
        //     repeat
        //         if CategoriasLimpieza <> '' then
        //             CategoriasLimpieza := CategoriasLimpieza + '|';
        //         CategoriasLimpieza := CategoriasLimpieza + UserTaskGroup.Code;
        //     until UserTaskGroup.Next() = 0;
        // end;
        ZonasLimpieza.SetRange("Tipo Tarea", 'LIMPIEZA');
        CategoriasLimpieza := '';
        if ZonasLimpieza.FindSet() then begin
            repeat
                if CategoriasLimpieza <> '' then
                    CategoriasLimpieza := CategoriasLimpieza + '|';
                CategoriasLimpieza := CategoriasLimpieza + ZonasLimpieza.Categoria;
                If FiltroZonasLimpieza <> '' then
                    FiltroZonasLimpieza := FiltroZonasLimpieza + '|';
                FiltroZonasLimpieza := FiltroZonasLimpieza + Format(ZonasLimpieza.Id);
            until ZonasLimpieza.Next() = 0;
        end;

        if JsonObject.Get('Usuario', JsonToken) then
            IdResponsabel := JsonToken.AsValue().AsText();

        // Inicializar array de resultados

        // Si se proporciona código de emplazamiento, buscar directamente por Id_record
        if CodigoEmplazamiento <> '' then begin
            if Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, CodigoEmplazamiento) then begin
                RecordIdEmplazamiento := Emplazamientos.RecordId;
                UserTask.Reset();
                UserTask.SetRange(Id_record, RecordIdEmplazamiento);
                if CategoriasLimpieza <> '' then
                    UserTask.SetFilter("User Task Group Assigned To", CategoriasLimpieza);
                if FiltroZonasLimpieza <> '' then
                    UserTask.SetFilter(ZonaLimpieza, FiltroZonasLimpieza);
                if FechaDesde <> 0D then
                    UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                if IdResponsabel <> '' then begin
                    UserGtask.SetRange("Id Gtask", IdResponsabel);
                    if UserGtask.FindFirst() then
                        UserTask.SetRange("Assigned To", UserGtask."Id Usuario");
                end;
                if UserTask.FindSet() then begin
                    repeat
                        UserTaskTemp := UserTask;
                        If UserTaskTemp.insert Then
                            Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                    until UserTask.Next() = 0;
                end;
                // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                if FechaDesde <> 0D then begin
                    UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                    UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                    if UserTask.FindSet() then begin
                        repeat
                            UserTaskTemp := UserTask;
                            If UserTaskTemp.insert Then
                                Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                        until UserTask.Next() = 0;
                    end;
                end;
            end;
        end else begin
            // Si se proporciona zona, buscar emplazamientos de esa zona
            if ZonaLimpieza <> 0 then begin
                EmplazamientosFiltrados.Reset();
                EmplazamientosFiltrados.SetRange("Zona Limpieza", ZonaLimpieza);
                if EmplazamientosFiltrados.FindSet() then begin
                    repeat
                        UserTask.Reset();
                        UserTask.SetRange(Id_record, EmplazamientosFiltrados.RecordId);
                        if CategoriasLimpieza <> '' then
                            UserTask.SetFilter("User Task Group Assigned To", CategoriasLimpieza);
                        if FechaDesde <> 0D then
                            UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                        // Buscar todas las tareas que cumplan los filtros
                        if UserTask.FindSet() then begin
                            repeat
                                UserTaskTemp := UserTask;
                                If UserTaskTemp.insert Then
                                    Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                            until UserTask.Next() = 0;
                        end;
                        // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                        if FechaDesde <> 0D then begin
                            UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                            UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                            if UserTask.FindSet() then begin
                                repeat
                                    UserTaskTemp := UserTask;
                                    If UserTaskTemp.insert Then
                                        Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                                until UserTask.Next() = 0;
                            end;
                        end;
                    until EmplazamientosFiltrados.Next() = 0;
                end;
            end else begin
                // Si no hay filtro de zona ni emplazamiento, buscar todas las tareas de limpieza
                UserTask.Reset();
                if CategoriasLimpieza <> '' then
                    UserTask.SetFilter("User Task Group Assigned To", CategoriasLimpieza);
                if FiltroZonasLimpieza <> '' then
                    UserTask.SetFilter(ZonaLimpieza, FiltroZonasLimpieza);
                if FechaDesde <> 0D then
                    UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                if UserTask.FindSet() then begin
                    repeat
                        // Intentar obtener el emplazamiento desde Id_record
                        if UserTask.Id_record.TableNo = Database::Emplazamientos then begin
                            if Emplazamientos.Get(UserTask.Id_record) then
                                UserTaskTemp := UserTask;
                            If UserTaskTemp.insert Then
                                Procesos_GTask.AgregarTareaAlJson(UserTask, Emplazamientos.RecordId, JsonArray, UserTaskTemp);
                        end;
                    until UserTask.Next() = 0;
                end;
                // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                if FechaDesde <> 0D then begin
                    UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                    UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                    if UserTask.FindSet() then begin
                        repeat
                            UserTaskTemp := UserTask;
                            If UserTaskTemp.insert Then
                                Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                        until UserTask.Next() = 0;
                    end;
                end;
            end;
        end;

        JsonArray.WriteTo(JsonResult);
        exit(JsonResult);
    end;

    [ServiceEnabled]
    procedure GetTareasRevision(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonTarea: JsonObject;
        UserTask: Record "User Task";
        Emplazamientos: Record Emplazamientos;
        EmplazamientosFiltrados: Record Emplazamientos;
        ZonaLimpieza: Integer;
        CodigoEmplazamiento: Code[20];
        FechaDesdeTexto: Text;
        FechaHastaTexto: Text;
        FechaDesde: Date;
        FechaHasta: Date;
        FechaDesdeDT: DateTime;
        FechaHastaDT: DateTime;
        CategoriasLimpieza: Text;
        JsonResult: Text;
        RecordIdEmplazamiento: RecordId;
        IdResponsabel: Text;
        UserGtask: Record UsuariosGtask;
        ZonasLimpieza: Record "Zonas Limpieza";
        FiltroZonasLimpieza: Text;


    begin
        // Leer JSON de entrada
        if not JsonObject.ReadFrom(JsonText) then
            Error('JSON inválido');

        // Inicializar variables
        ZonaLimpieza := 0;
        CodigoEmplazamiento := '';
        FechaDesde := 0D;
        FechaHasta := 0D;

        // Obtener zona de limpieza (opcional)
        if JsonObject.Get('zonaLimpieza', JsonToken) then begin
            if not Evaluate(ZonaLimpieza, JsonToken.AsValue().AsText()) then
                ZonaLimpieza := 0;
        end;

        // Obtener código de emplazamiento (opcional)
        if JsonObject.Get('codigoEmplazamiento', JsonToken) then
            CodigoEmplazamiento := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(CodigoEmplazamiento));

        // Obtener fecha desde (opcional)
        if JsonObject.Get('fechaDesde', JsonToken) then begin
            FechaDesdeTexto := JsonToken.AsValue().AsText();
            if Evaluate(FechaDesde, FechaDesdeTexto) then
                FechaDesdeDT := CreateDateTime(FechaDesde, 0T)
            else
                FechaDesde := 0D;
        end;

        // Obtener fecha hasta (opcional)
        if JsonObject.Get('fechaHasta', JsonToken) then begin
            FechaHastaTexto := JsonToken.AsValue().AsText();
            if Evaluate(FechaHasta, FechaHastaTexto) then
                FechaHastaDT := CreateDateTime(FechaHasta, 235959T)
            else
                FechaHasta := 0D;
        end;

        // // Obtener categorías de tipo LIMPIEZA
        // UserTaskGroup.ChangeCompany('Malla Publicidad');
        // UserTaskGroup.SetRange("Tipo de Tarea", 'LIMPIEZA');
        // CategoriasLimpieza := '';
        // if UserTaskGroup.FindSet() then begin
        //     repeat
        //         if CategoriasLimpieza <> '' then
        //             CategoriasLimpieza := CategoriasLimpieza + '|';
        //         CategoriasLimpieza := CategoriasLimpieza + UserTaskGroup.Code;
        //     until UserTaskGroup.Next() = 0;
        // end;
        ZonasLimpieza.SetRange("Tipo Tarea", 'REVISION');
        CategoriasLimpieza := '';
        if ZonasLimpieza.FindSet() then begin
            repeat
                if CategoriasLimpieza <> '' then
                    CategoriasLimpieza := CategoriasLimpieza + '|';
                // Debe coincidir con DevuelveCategoriaSupervisorResponsablePorZona: "User Task Group" = Tipo Tarea, no Categoria
                CategoriasLimpieza := CategoriasLimpieza + ZonasLimpieza."Tipo Tarea";
                If FiltroZonasLimpieza <> '' then
                    FiltroZonasLimpieza := FiltroZonasLimpieza + '|';
                FiltroZonasLimpieza := FiltroZonasLimpieza + Format(ZonasLimpieza.Id);
            until ZonasLimpieza.Next() = 0;
        end;

        if JsonObject.Get('Usuario', JsonToken) then
            IdResponsabel := JsonToken.AsValue().AsText();

        // Inicializar array de resultados

        // Si se proporciona código de emplazamiento, buscar directamente por Id_record
        if CodigoEmplazamiento <> '' then begin
            if Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, CodigoEmplazamiento) then begin
                RecordIdEmplazamiento := Emplazamientos.RecordId;
                UserTask.Reset();
                UserTask.SetRange(Id_record, RecordIdEmplazamiento);
                if CategoriasLimpieza <> '' then
                    UserTask.SetFilter("User Task Group Assigned To", CategoriasLimpieza);
                if FiltroZonasLimpieza <> '' then
                    UserTask.SetFilter(ZonaLimpieza, FiltroZonasLimpieza);
                if FechaDesde <> 0D then
                    UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                if IdResponsabel <> '' then begin
                    UserGtask.SetRange("Id Gtask", IdResponsabel);
                    if UserGtask.FindFirst() then
                        UserTask.SetRange("Assigned To", UserGtask."Id Usuario");
                end;
                if UserTask.FindSet() then begin
                    repeat
                        UserTaskTemp := UserTask;
                        If UserTaskTemp.insert Then
                            Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                    until UserTask.Next() = 0;
                end;
                // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                if FechaDesde <> 0D then begin
                    UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                    UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                    if UserTask.FindSet() then begin
                        repeat
                            UserTaskTemp := UserTask;
                            If UserTaskTemp.insert Then
                                Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                        until UserTask.Next() = 0;
                    end;
                end;
            end;
        end else begin
            // Si se proporciona zona, buscar emplazamientos de esa zona
            if ZonaLimpieza <> 0 then begin
                EmplazamientosFiltrados.Reset();
                EmplazamientosFiltrados.SetRange("Zona Limpieza", ZonaLimpieza);
                if EmplazamientosFiltrados.FindSet() then begin
                    repeat
                        UserTask.Reset();
                        UserTask.SetRange(Id_record, EmplazamientosFiltrados.RecordId);
                        if CategoriasLimpieza <> '' then
                            UserTask.SetFilter("User Task Group Assigned To", CategoriasLimpieza);
                        if FechaDesde <> 0D then
                            UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                        // Buscar todas las tareas que cumplan los filtros
                        if UserTask.FindSet() then begin
                            repeat
                                UserTaskTemp := UserTask;
                                If UserTaskTemp.insert Then
                                    Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                            until UserTask.Next() = 0;
                        end;
                        // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                        if FechaDesde <> 0D then begin
                            UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                            UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                            if UserTask.FindSet() then begin
                                repeat
                                    UserTaskTemp := UserTask;
                                    If UserTaskTemp.insert Then
                                        Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                                until UserTask.Next() = 0;
                            end;
                        end;
                    until EmplazamientosFiltrados.Next() = 0;
                end;
            end else begin
                // Si no hay filtro de zona ni emplazamiento, buscar todas las tareas de limpieza
                UserTask.Reset();
                if CategoriasLimpieza <> '' then
                    UserTask.SetFilter("User Task Group Assigned To", CategoriasLimpieza);
                if FiltroZonasLimpieza <> '' then
                    UserTask.SetFilter(ZonaLimpieza, FiltroZonasLimpieza);
                if FechaDesde <> 0D then
                    UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                if UserTask.FindSet() then begin
                    repeat
                        // Intentar obtener el emplazamiento desde Id_record
                        if UserTask.Id_record.TableNo = Database::Emplazamientos then begin
                            if Emplazamientos.Get(UserTask.Id_record) then
                                UserTaskTemp := UserTask;
                            If UserTaskTemp.insert Then
                                Procesos_GTask.AgregarTareaAlJson(UserTask, Emplazamientos.RecordId, JsonArray, UserTaskTemp);
                        end;
                    until UserTask.Next() = 0;
                end;
                // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                if FechaDesde <> 0D then begin
                    UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                    UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                    if UserTask.FindSet() then begin
                        repeat
                            UserTaskTemp := UserTask;
                            If UserTaskTemp.insert Then
                                Procesos_GTask.AgregarTareaAlJson(UserTask, UserTask.Id_record, JsonArray, UserTaskTemp);
                        until UserTask.Next() = 0;
                    end;
                end;
            end;
        end;

        JsonArray.WriteTo(JsonResult);
        exit(JsonResult);
    end;

    [ServiceEnabled]
    procedure GetTareasRevisionRecurso(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        UserTask: Record "User Task";
        ResourceFiltro: Record Resource;
        ZonasLimpieza: Record "Zonas Limpieza";
        CodigoRecurso: Code[20];
        FechaDesdeTexto: Text;
        FechaHastaTexto: Text;
        FechaDesde: Date;
        FechaHasta: Date;
        FechaDesdeDT: DateTime;
        FechaHastaDT: DateTime;
        CategoriasRevision: Text;
        FiltroZonasRevision: Text;
        JsonResult: Text;
    begin
        if not JsonObject.ReadFrom(JsonText) then
            Error('JSON inválido');

        CodigoRecurso := '';
        FechaDesde := 0D;
        FechaHasta := 0D;

        if JsonObject.Get('codigoRecurso', JsonToken) then
            CodigoRecurso := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(CodigoRecurso));

        if JsonObject.Get('fechaDesde', JsonToken) then begin
            FechaDesdeTexto := JsonToken.AsValue().AsText();
            if Evaluate(FechaDesde, FechaDesdeTexto) then
                FechaDesdeDT := CreateDateTime(FechaDesde, 0T)
            else
                FechaDesde := 0D;
        end;

        if JsonObject.Get('fechaHasta', JsonToken) then begin
            FechaHastaTexto := JsonToken.AsValue().AsText();
            if Evaluate(FechaHasta, FechaHastaTexto) then
                FechaHastaDT := CreateDateTime(FechaHasta, 235959T)
            else
                FechaHasta := 0D;
        end;

        ZonasLimpieza.SetRange("Tipo Tarea", 'REVISION');
        if ZonasLimpieza.FindSet() then
            repeat
                if CategoriasRevision <> '' then
                    CategoriasRevision += '|';
                CategoriasRevision += ZonasLimpieza."Tipo Tarea";
                if FiltroZonasRevision <> '' then
                    FiltroZonasRevision += '|';
                FiltroZonasRevision += Format(ZonasLimpieza.Id);
            until ZonasLimpieza.Next() = 0;

        UserTask.Reset();
        if CategoriasRevision <> '' then
            UserTask.SetFilter("User Task Group Assigned To", CategoriasRevision);
        if FiltroZonasRevision <> '' then
            UserTask.SetFilter(ZonaLimpieza, FiltroZonasRevision);
        if CodigoRecurso <> '' then begin
            if not ResourceFiltro.Get(CodigoRecurso) then begin
                JsonArray.WriteTo(JsonResult);
                exit(JsonResult);
            end;
            UserTask.SetRange(Id_record, ResourceFiltro.RecordId);
        end;
        if FechaDesde <> 0D then
            UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
        if UserTask.FindSet() then
            repeat
                if UserTask.Id_record.TableNo = Database::Resource then begin
                    UserTaskTemp := UserTask;
                    if UserTaskTemp.Insert() then
                        Procesos_GTask.AgregarTareaUsuarioAlJson(UserTask, JsonArray);
                end;
            until UserTask.Next() = 0;

        if FechaDesde <> 0D then begin
            UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
            UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
            if UserTask.FindSet() then
                repeat
                    if UserTask.Id_record.TableNo = Database::Resource then begin
                        UserTaskTemp := UserTask;
                        if UserTaskTemp.Insert() then
                            Procesos_GTask.AgregarTareaUsuarioAlJson(UserTask, JsonArray);
                    end;
                until UserTask.Next() = 0;
        end;

        JsonArray.WriteTo(JsonResult);
        exit(JsonResult);
    end;


    /// <summary>
    /// Endpoint que devuelve una lista de tareas de limpieza ficticias asociadas a las paradas bus,
    /// separando entre Zona Crítica y Zona No Crítica. Genera una tarea por cada fecha en el rango
    /// [fechaInicio, fechaFin] según la periodicidad de cada zona.
    /// </summary>
    /// <param name="JsonText">JSON con fechaInicio y fechaFin (formato YYYY-MM-DD). Ej: {"fechaInicio":"2025-02-01","fechaFin":"2025-02-28"}</param>
    /// <returns>JSON array con: numeroParada, numeroTarea, titulo, zona (Crítica/No Crítica), estado (Finalizado/Pendiente), fecha, operario</returns>
    [ServiceEnabled]
    procedure GetTareasLimpiezaEMT(JsonText: Text): Text
    var
        Emplazamientos: Record Emplazamientos;
        JobsSetup: Record "Jobs Setup";
        UserTask: Record "User Task";
        UsuariosGtask: Record UsuariosGtask;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonTarea: JsonObject;
        JsonResult: Text;
        UltimoIdTarea: Integer;
        FechaInicio: Date;
        FechaFin: Date;
        FechaTarea: Date;
        FechaAnterior: Date;
        FechaTexto: Text;
        ZonaTexto: Text[30];
        EstadoTexto: Text[30];
        OperarioNombre: Text[250];
        PeriodicidadCritica: DateFormula;
        PeriodicidadNoCritica: DateFormula;
    begin
        // Leer rango de fechas del JSON
        FechaInicio := 0D;
        FechaFin := 0D;
        if (JsonText <> '') and JsonObject.ReadFrom(JsonText) then begin
            if JsonObject.Get('fechaInicio', JsonToken) then begin
                FechaTexto := JsonToken.AsValue().AsText();
                if not Evaluate(FechaInicio, FechaTexto) then
                    FechaInicio := 0D;
            end;
            if JsonObject.Get('fechaFin', JsonToken) then begin
                FechaTexto := JsonToken.AsValue().AsText();
                if not Evaluate(FechaFin, FechaTexto) then
                    FechaFin := 0D;
            end;
        end;
        if FechaInicio = 0D then
            FechaInicio := WorkDate();
        if FechaFin = 0D then
            FechaFin := WorkDate() + 30;
        if FechaFin < FechaInicio then
            Error('La fecha fin no puede ser anterior a la fecha inicio.');

        JobsSetup.Get();
        PeriodicidadCritica := JobsSetup."Periodicidad Zona Crítica";
        PeriodicidadNoCritica := JobsSetup."Periodicidad Zona No Crítica";

        // Último número de tarea real (User Task)
        if UserTask.FindLast() then
            UltimoIdTarea := UserTask.ID
        else
            UltimoIdTarea := 0;

        Emplazamientos.SetRange("Tipo Emplazamiento", Emplazamientos."Tipo Emplazamiento"::Opis);
        //Emplazamientos.SetFilter("Zona Limpieza", '<>%1', 0);
        if Emplazamientos.FindSet() then
            repeat
                if Emplazamientos."Zona Crítica" then
                    ZonaTexto := 'Crítica'
                else
                    ZonaTexto := 'No Crítica';

                // Operario asociado al emplazamiento (como en Paradas Bus - Crear Tareas Limpieza)
                //OperarioNombre := '';
                // if Emplazamientos.Operario <> 0 then begin
                //     UsuariosGtask.ChangeCompany('Malla Publicidad');
                //     UsuariosGtask.SetRange("Id Usuario Limpieza EMT", Emplazamientos.Operario);
                //     if UsuariosGtask.FindFirst() then
                //         OperarioNombre := UsuariosGtask.Nombre;
                // end;

                // Generar una tarea por cada fecha en el rango según la periodicidad de la zona
                FechaTarea := FechaInicio;
                while FechaTarea <= FechaFin do begin
                    Clear(JsonTarea);
                    UltimoIdTarea += 1;

                    if FechaTarea < WorkDate() then
                        EstadoTexto := 'Finalizado'
                    else
                        EstadoTexto := 'Pendiente';

                    JsonTarea.Add('numeroParada', Emplazamientos."Nº Emplazamiento");
                    JsonTarea.Add('numeroTarea', UltimoIdTarea);
                    JsonTarea.Add('titulo', 'Limpieza parada ' + Emplazamientos."Nº Emplazamiento");
                    JsonTarea.Add('zona', ZonaTexto);
                    JsonTarea.Add('estado', EstadoTexto);
                    JsonTarea.Add('fecha', Format(FechaTarea, 0, '<Year4>-<Month,2>-<Day,2>'));
                    JsonTarea.Add('operario', Procesos_GTask.OperarioNombre(Emplazamientos."Zona Limpieza"));
                    JsonArray.Add(JsonTarea);

                    FechaAnterior := FechaTarea;
                    if Emplazamientos."Zona Crítica" then
                        FechaTarea := CalcDate(PeriodicidadCritica, FechaTarea)
                    else
                        FechaTarea := CalcDate(PeriodicidadNoCritica, FechaTarea);
                    // Evitar bucle infinito si la periodicidad no avanza
                    if FechaTarea <= FechaAnterior then
                        FechaTarea := FechaFin + 1;
                end;
            until Emplazamientos.Next() = 0;

        JsonArray.WriteTo(JsonResult);
        exit(JsonResult);
    end;
    /// <summary>
    /// Endpoint para obtener las tareas de un usuario con coordenadas (puntoX, puntoY) del recurso/emplazamiento.
    /// Filtros opcionales en el JSON de petición:
    /// - usuario: Id Gtask del usuario o GUID (filtra por Assigned To)
    /// - fecha: una fecha "YYYY-MM-DD" o objeto con fechaDesde/fechaHasta (filtra por Start DateTime)
    /// - categoria: código de categoría (User Task Group Assigned To)
    /// Si solo viene usuario, se filtra por usuario; si usuario y fecha, por ambos; si los tres, por usuario, fecha y categoría.
    /// </summary>
    /// <param name="JsonText">JSON con filtros opcionales: {"usuario": "...", "fecha": "2024-01-15", "categoria": "COD"}</param>
    /// <returns>JSON array con tareas que incluyen puntoX y puntoY del recurso/emplazamiento</returns>
    [ServiceEnabled]
    procedure GetTareasUsuario(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonResult: Text;
        UserTask: Record "User Task";
        UserGtask: Record UsuariosGtask;
        UsuarioGuid: Guid;
        UsuarioTexto: Text;
        FechaTexto: Text;
        FechaDesde: Date;
        FechaHasta: Date;
        FechaDesdeDT: DateTime;
        FechaHastaDT: DateTime;
        Categoria: Code[20];
        TieneUsuario: Boolean;
        TieneFecha: Boolean;
        TieneCategoria: Boolean;
    begin
        if not JsonObject.ReadFrom(JsonText) then
            Error('JSON inválido');

        UsuarioGuid := CreateGuid();
        UsuarioTexto := '';
        FechaDesde := 0D;
        FechaHasta := 0D;
        Categoria := '';
        TieneUsuario := false;
        TieneFecha := false;
        TieneCategoria := false;

        // Usuario (opcional): puede ser Id Gtask o GUID en texto
        if JsonObject.Get('usuario', JsonToken) then begin
            UsuarioTexto := JsonToken.AsValue().AsText();
            if UsuarioTexto <> '' then begin
                UserGtask.ChangeCompany('Malla Publicidad');
                UserGtask.SetRange("Id Gtask", CopyStr(UsuarioTexto, 1, MaxStrLen(UserGtask."Id Gtask")));
                if UserGtask.FindFirst() then
                    UsuarioGuid := UserGtask."Id Usuario"
                else
                    if Evaluate(UsuarioGuid, UsuarioTexto) then
                        UsuarioGuid := UsuarioGuid
                    else
                        exit('[]'); // Usuario no encontrado, devolver vacío
                TieneUsuario := true;
            end;
        end;

        // Fecha (opcional): una fecha o objeto con fechaDesde/fechaHasta
        if JsonObject.Get('fecha', JsonToken) then begin
            FechaTexto := JsonToken.AsValue().AsText();
            if (FechaTexto <> '') and Evaluate(FechaDesde, FechaTexto) then begin
                FechaHasta := FechaDesde;
                FechaDesdeDT := 0DT;
                FechaHastaDT := CreateDateTime(FechaHasta, 235959T);
                TieneFecha := true;
            end;
        end;
        if not TieneFecha and JsonObject.Get('fechaDesde', JsonToken) then begin
            FechaTexto := JsonToken.AsValue().AsText();
            if (FechaTexto <> '') and Evaluate(FechaDesde, FechaTexto) then
                FechaDesdeDT := CreateDateTime(FechaDesde, 0T);
        end;
        if JsonObject.Get('fechaHasta', JsonToken) then begin
            FechaTexto := JsonToken.AsValue().AsText();
            if (FechaTexto <> '') and Evaluate(FechaHasta, FechaTexto) then begin
                FechaDesdeDT := 0DT;
                FechaHastaDT := CreateDateTime(FechaHasta, 235959T);
                TieneFecha := true;
            end;
        end;

        // Categoría (opcional)
        if JsonObject.Get('categoria', JsonToken) then begin
            Categoria := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Categoria));
            if Categoria <> '' then
                TieneCategoria := true;
        end;

        // Aplicar filtros y recorrer tareas
        UserTask.Reset();
        if TieneUsuario then
            UserTask.SetRange("Assigned To", UsuarioGuid);
        if TieneFecha then
            UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
        if TieneCategoria then
            UserTask.SetFilter("User Task Group Assigned To", Categoria);
        Usertask.Setfilter(Estado, '%1|%2', UserTask.Estado::Pendiente, UserTask.Estado::"En Proceso");
        if UserTask.FindSet() then
            repeat
                Procesos_GTask.AgregarTareaUsuarioAlJson(UserTask, JsonArray);
            until UserTask.Next() = 0;

        JsonArray.WriteTo(JsonResult);
        exit(JsonResult);
    end;

    /// <summary>
    /// Endpoint para crear tareas de revisión desde JSON
    /// Formato JSON esperado: [{"codigoEmplazamiento": "COD001", "codigoCategoria": "CAT001", "fecha": "2024-01-15"}, ...]
    /// </summary>
    /// <param name="JsonText">JSON array con las tareas a crear</param>
    /// <returns>JSON con el resultado: {"tareasCreadas": 5, "tareasExistentes": 2, "errores": []}</returns>
    [ServiceEnabled]
    procedure CrearTareasPuestaApuntoJson(JsonText: Text): Text

    begin
        exit(CrearTareasRevisionJson(JsonText));
    end;

    [ServiceEnabled]
    procedure CrearTareasRevisionJson(JsonText: Text): Text
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonTarea: JsonObject;
        JsonCampo: JsonToken;
        JsonResult: JsonObject;
        JsonErrores: JsonArray;
        JsonError: JsonObject;
        CodigoEmplazamiento: Code[20];
        CodigoCategoria: Code[20];
        FechaTexto: Text;
        Fecha: Date;
        TareasCreadas: Integer;
        TareasExistentes: Integer;
        ErrorTexto: Text;
    begin
        TareasCreadas := 0;
        TareasExistentes := 0;

        if not JsonArray.ReadFrom(JsonText) then
            Error('JSON inválido. Se espera un array JSON.');

        foreach JsonToken in JsonArray do begin
            JsonTarea := JsonToken.AsObject();
            ErrorTexto := '';
            CodigoEmplazamiento := '';
            CodigoCategoria := '';
            Fecha := 0D;

            // Obtener código de emplazamiento
            if JsonTarea.Get('codigoEmplazamiento', JsonCampo) then
                CodigoEmplazamiento := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(CodigoEmplazamiento))
            else
                ErrorTexto := ErrorTexto + 'Falta campo codigoEmplazamiento. ';

            // Obtener código de categoría
            if JsonTarea.Get('codigoCategoria', JsonCampo) then
                CodigoCategoria := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(CodigoCategoria))
            else
                ErrorTexto := ErrorTexto + 'Falta campo codigoCategoria. ';

            // Obtener fecha (opcional)
            if JsonTarea.Get('fecha', JsonCampo) then begin
                FechaTexto := JsonCampo.AsValue().AsText();
                if not Evaluate(Fecha, FechaTexto) then
                    ErrorTexto := ErrorTexto + 'Fecha inválida. ';
            end;

            // Si hay errores, agregarlos al array de errores
            if ErrorTexto <> '' then begin
                Clear(JsonError);
                JsonError.Add('codigoEmplazamiento', CodigoEmplazamiento);
                JsonError.Add('error', CopyStr(ErrorTexto, 1, 250));
                JsonErrores.Add(JsonError);
            end else begin
                // Intentar crear la tarea
                if CrearTareaRevision(CodigoEmplazamiento, CodigoCategoria, Fecha) then
                    TareasCreadas += 1
                else
                    TareasExistentes += 1;
            end;
        end;

        // Construir respuesta JSON
        Clear(JsonResult);
        JsonResult.Add('tareasCreadas', TareasCreadas);
        JsonResult.Add('tareasExistentes', TareasExistentes);
        JsonResult.Add('errores', JsonErrores);
        JsonResult.WriteTo(JsonText);
        exit(JsonText);
    end;

    /// <summary>
    /// Endpoint para obtener la lista de categorías de revisión
    /// </summary>
    /// <returns>JSON array con las categorías: [{"code": "CAT001", "description": "Descripción 1"}, ...]</returns>
    [ServiceEnabled]
    procedure GetCategoriasRevision(): Text
    var
        ZonasLimpieza: Record "Zonas Limpieza";
        JsonArray: JsonArray;
        JsonCategoria: JsonObject;
        JsonText: Text;
    begin
        ZonasLimpieza.ChangeCompany('Malla Publicidad');
        ZonasLimpieza.SetRange("Tipo Tarea", 'REVISION');

        if ZonasLimpieza.FindSet() then begin
            repeat
                Clear(JsonCategoria);
                JsonCategoria.Add('code', ZonasLimpieza."Tipo Tarea");
                JsonCategoria.Add('description', ZonasLimpieza."Descripción");
                JsonArray.Add(JsonCategoria);
            until ZonasLimpieza.Next() = 0;
        end;

        JsonArray.WriteTo(JsonText);
        exit(JsonText);
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
        User.Get(UserSecurityId());
        Procesos_Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, Categoria, EmailResponsable, EmailSupervisor, User, UserTask, ListaCorreos);
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
                iF UserTask.EliminarTarea then begin
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
        Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListaCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false, true);
    end;

    /// <summary>
    /// Lista partes diarios de un empleado.
    /// Entrada: {"empleado":"...","fecha_desde":"YYYY-MM-DD","fecha_hasta":"YYYY-MM-DD"}
    /// </summary>
    [ServiceEnabled]
    procedure GetPartesDiario(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonOut: JsonObject;
        JsonArray: JsonArray;
        JsonParte: JsonObject;
        Parte: Record "Partes de Trabajo";
        EmpleadoNo: Code[20];
        FechaDesde: Date;
        FechaHasta: Date;
        ResultText: Text;
    begin
        Clear(JsonArray);
        if ParseJsonRequestParteDiario(JsonText, JsonIn) then begin
            EmpleadoNo := ObtenerTextoJsonParteDiario(JsonIn, 'empleado');
            FechaDesde := ObtenerFechaJsonParteDiario(JsonIn, 'fecha_desde', 0D);
            FechaHasta := ObtenerFechaJsonParteDiario(JsonIn, 'fecha_hasta', 99991231D);
            if EmpleadoNo <> '' then begin
                Parte.SetRange(Empleado, EmpleadoNo);
                if (FechaDesde <> 0D) and (FechaHasta <> 99991231D) then
                    Parte.SetRange("Fecha Parte", FechaDesde, FechaHasta)
                else begin
                    if FechaDesde <> 0D then
                        Parte.SetFilter("Fecha Parte", '>=%1', FechaDesde);
                    if FechaHasta <> 99991231D then
                        Parte.SetFilter("Fecha Parte", '<=%1', FechaHasta);
                end;
                if Parte.FindSet() then
                    repeat
                        Clear(JsonParte);
                        AgregarParteDiarioCompletoAJson(Parte, JsonParte);
                        JsonArray.Add(JsonParte);
                    until Parte.Next() = 0;
            end;
        end;
        Clear(JsonOut);
        JsonOut.Add('value', JsonArray.AsToken());
        JsonOut.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Devuelve un parte diario por número.
    /// Entrada: {"no_parte":"..."}
    /// </summary>
    [ServiceEnabled]
    procedure GetParteDiario(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonOut: JsonObject;
        Parte: Record "Partes de Trabajo";
        NoParte: Code[20];
        ResultText: Text;
    begin
        Clear(JsonOut);
        if ParseJsonRequestParteDiario(JsonText, JsonIn) then begin
            NoParte := CopyStr(ObtenerTextoJsonParteDiario(JsonIn, 'no_parte'), 1, MaxStrLen(NoParte));
            if (NoParte <> '') and Parte.Get(NoParte) then
                AgregarParteDiarioCompletoAJson(Parte, JsonOut);
        end;
        JsonOut.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Crea o actualiza un parte diario y su detalle.
    /// Entrada: no_parte (opcional), empleado, fecha_parte, hora_entrada, hora_salida, texto_trabajo, empresa, tareas[], residuos[]
    /// </summary>
    [ServiceEnabled]
    procedure PostParteDiario(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonOut: JsonObject;
        Parte: Record "Partes de Trabajo";
        NoParte: Code[20];
        EmpleadoNo: Code[20];
        FechaParte: Date;
        EsNuevo: Boolean;
        ResultText: Text;
    begin
        if not ParseJsonRequestParteDiario(JsonText, JsonIn) then
            Error('JSON inválido o vacío');

        NoParte := CopyStr(ObtenerTextoJsonParteDiario(JsonIn, 'no_parte'), 1, MaxStrLen(NoParte));
        EmpleadoNo := CopyStr(ObtenerTextoJsonParteDiario(JsonIn, 'empleado'), 1, MaxStrLen(EmpleadoNo));
        FechaParte := ObtenerFechaJsonParteDiario(JsonIn, 'fecha_parte', 0D);

        EsNuevo := (NoParte = '') or not Parte.Get(NoParte);
        if EsNuevo then begin
            Parte.Init();
            Parte.Insert(true);
            NoParte := Parte."Nº Parte";
        end;

        if FechaParte <> 0D then
            Parte.Validate("Fecha Parte", FechaParte);
        if ObtenerTextoJsonParteDiario(JsonIn, 'hora_entrada') <> '' then
            Parte.Validate("Hora Entrada", ParseHoraParteDiario(ObtenerTextoJsonParteDiario(JsonIn, 'hora_entrada')));
        if ObtenerTextoJsonParteDiario(JsonIn, 'hora_salida') <> '' then
            Parte.Validate("Hora Salida", ParseHoraParteDiario(ObtenerTextoJsonParteDiario(JsonIn, 'hora_salida')));
        if ObtenerTextoJsonParteDiario(JsonIn, 'texto_trabajo') <> '' then
            Parte."Texto Trabajo" := CopyStr(ObtenerTextoJsonParteDiario(JsonIn, 'texto_trabajo'), 1, MaxStrLen(Parte."Texto Trabajo"));
        if ObtenerTextoJsonParteDiario(JsonIn, 'empresa') <> '' then
            Parte.Empresa := CopyStr(ObtenerTextoJsonParteDiario(JsonIn, 'empresa'), 1, MaxStrLen(Parte.Empresa));
        if EmpleadoNo <> '' then
            Parte.Validate(Empleado, EmpleadoNo);

        Parte.Modify(true);
        SincronizarDetalleParteDesdeJson(NoParte, JsonIn);

        Parte.Get(NoParte);
        Clear(JsonOut);
        AgregarParteDiarioCompletoAJson(Parte, JsonOut);
        JsonOut.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure ParseJsonRequestParteDiario(JsonText: Text; var JsonIn: JsonObject): Boolean
    var
        Wrapper: JsonObject;
        JsonToken: JsonToken;
        InnerText: Text;
    begin
        Clear(JsonIn);
        if JsonText = '' then
            exit(false);
        if not Wrapper.ReadFrom(JsonText) then
            exit(false);
        if Wrapper.Get('JsonText', JsonToken) or Wrapper.Get('jsonText', JsonToken) then begin
            InnerText := JsonToken.AsValue().AsText();
            if InnerText = '' then
                exit(false);
            exit(JsonIn.ReadFrom(InnerText));
        end;
        JsonIn := Wrapper;
        exit(true);
    end;

    local procedure ObtenerTextoJsonParteDiario(JsonIn: JsonObject; Campo: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonIn.Get(Campo, JsonToken) then
            exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    local procedure ObtenerFechaJsonParteDiario(JsonIn: JsonObject; Campo: Text; ValorDefecto: Date): Date
    var
        FechaTexto: Text;
        Fecha: Date;
    begin
        FechaTexto := ObtenerTextoJsonParteDiario(JsonIn, Campo);
        if FechaTexto = '' then
            exit(ValorDefecto);
        Fecha := ValorDefecto;
        if Evaluate(Fecha, FechaTexto) then
            exit(Fecha);
        exit(ValorDefecto);
    end;

    local procedure ParseHoraParteDiario(HoraTexto: Text): Time
    var
        Hora: Time;
    begin
        if HoraTexto = '' then
            exit(0T);
        if Evaluate(Hora, HoraTexto) then
            exit(Hora);
        if StrLen(HoraTexto) = 5 then
            if Evaluate(Hora, HoraTexto + ':00') then
                exit(Hora);
        exit(0T);
    end;

    local procedure AgregarParteDiarioCompletoAJson(Parte: Record "Partes de Trabajo"; var JsonParte: JsonObject)
    var
        JsonTareas: JsonArray;
        JsonResiduos: JsonArray;
    begin
        JsonParte.Add('no_parte', Parte."Nº Parte");
        JsonParte.Add('fecha_parte', Format(Parte."Fecha Parte", 0, 9));
        JsonParte.Add('hora_entrada', Format(Parte."Hora Entrada"));
        JsonParte.Add('hora_salida', Format(Parte."Hora Salida"));
        JsonParte.Add('horas', Parte.Horas);
        JsonParte.Add('empresa', Parte.Empresa);
        JsonParte.Add('empleado', Parte.Empleado);
        JsonParte.Add('texto_trabajo', Parte."Texto Trabajo");
        AgregarLineasDetalleParteAJson(Parte."Nº Parte", JsonTareas, JsonResiduos);
        JsonParte.Add('tareas', JsonTareas.AsToken());
        JsonParte.Add('residuos', JsonResiduos.AsToken());
    end;

    local procedure AgregarLineasDetalleParteAJson(NoParte: Code[20]; var JsonTareas: JsonArray; var JsonResiduos: JsonArray)
    var
        DetalleParte: Record "Detalle Parte";
        JsonLinea: JsonObject;
    begin
        Clear(JsonTareas);
        Clear(JsonResiduos);
        DetalleParte.SetRange("Nº Parte", NoParte);
        if DetalleParte.FindSet() then
            repeat
                Clear(JsonLinea);
                JsonLinea.Add('no_linea', DetalleParte."Nº Linea");
                case DetalleParte.Tipo of
                    DetalleParte.Tipo::Tarea:
                        begin
                            JsonLinea.Add('no_tarea', DetalleParte."Nº Tarea");
                            JsonLinea.Add('descripcion', DetalleParte.Descripcion);
                            JsonTareas.Add(JsonLinea);
                        end;
                    DetalleParte.Tipo::Residuo:
                        begin
                            JsonLinea.Add('descripcion', DetalleParte.Descripcion);
                            JsonLinea.Add('descripcion_eliminacion', DetalleParte."Descripcion elim. residuos");
                            JsonResiduos.Add(JsonLinea);
                        end;
                end;
            until DetalleParte.Next() = 0;
    end;

    local procedure SincronizarDetalleParteDesdeJson(NoParte: Code[20]; JsonIn: JsonObject)
    var
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonLinea: JsonObject;
        DetalleParte: Record "Detalle Parte";
        LineNo: Integer;
        i: Integer;
        NoTarea: Integer;
        TieneTareas: Boolean;
        TieneResiduos: Boolean;
    begin
        TieneTareas := JsonIn.Get('tareas', JsonToken);
        TieneResiduos := JsonIn.Get('residuos', JsonToken);
        if not TieneTareas and not TieneResiduos then
            exit;

        if TieneTareas then begin
            DetalleParte.SetRange("Nº Parte", NoParte);
            DetalleParte.SetRange(Tipo, DetalleParte.Tipo::Tarea);
            DetalleParte.DeleteAll();
            JsonIn.Get('tareas', JsonToken);
            JsonArray := JsonToken.AsArray();
            LineNo := 10000;
            for i := 0 to JsonArray.Count() - 1 do begin
                JsonArray.Get(i, JsonToken);
                JsonLinea := JsonToken.AsObject();
                DetalleParte.Init();
                DetalleParte."Nº Parte" := NoParte;
                DetalleParte.Tipo := DetalleParte.Tipo::Tarea;
                DetalleParte."Nº Linea" := LineNo;
                if JsonLinea.Get('no_tarea', JsonToken) then begin
                    if Evaluate(NoTarea, JsonToken.AsValue().AsText()) then
                        DetalleParte.Validate("Nº Tarea", NoTarea);
                end;
                if JsonLinea.Get('descripcion', JsonToken) then
                    DetalleParte.Descripcion := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(DetalleParte.Descripcion));
                DetalleParte.Insert(true);
                LineNo += 10000;
            end;
        end;

        if TieneResiduos then begin
            DetalleParte.SetRange("Nº Parte", NoParte);
            DetalleParte.SetRange(Tipo, DetalleParte.Tipo::Residuo);
            DetalleParte.DeleteAll();
            JsonIn.Get('residuos', JsonToken);
            JsonArray := JsonToken.AsArray();
            LineNo := 10000;
            for i := 0 to JsonArray.Count() - 1 do begin
                JsonArray.Get(i, JsonToken);
                JsonLinea := JsonToken.AsObject();
                DetalleParte.Init();
                DetalleParte."Nº Parte" := NoParte;
                DetalleParte.Tipo := DetalleParte.Tipo::Residuo;
                DetalleParte."Nº Linea" := LineNo;
                if JsonLinea.Get('descripcion', JsonToken) then
                    DetalleParte.Descripcion := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(DetalleParte.Descripcion));
                if JsonLinea.Get('descripcion_eliminacion', JsonToken) then
                    DetalleParte."Descripcion elim. residuos" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(DetalleParte."Descripcion elim. residuos"));
                DetalleParte.Insert(true);
                LineNo += 10000;
            end;
        end;
    end;


    #endregion Serivices

    /// <summary>
    /// Resuelve el usuario de la incidencia EMT: prioriza "usuario" (username app EMT)
    /// buscando en UsuariosGtask."Usuario EMT"; si no, usa "user" (Id Gtask u otro identificador).
    /// </summary>
    local procedure ResolverUsuarioPostIncidenciaEmt(JsonIncidencia: JsonObject; var Usuario: Record UsuariosGtask; var UsuarioId: Guid; var UsuarioPost: Text)
    var
        JsonCampo: JsonToken;
        UsuarioEmt: Text;
    begin
        Clear(UsuarioPost);
        Clear(UsuarioId);
        UsuarioEmt := '';
        if JsonIncidencia.Get('usuario', JsonCampo) then
            UsuarioEmt := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(Usuario."Usuario EMT"));
        if (UsuarioEmt = '') and JsonIncidencia.Get('user', JsonCampo) then
            UsuarioEmt := CopyStr(JsonCampo.AsValue().AsText(), 1, MaxStrLen(Usuario."Usuario EMT"));
        if UsuarioEmt = '' then
            exit;
        UsuarioPost := UsuarioEmt;
        Usuario.Reset();
        Usuario.SetRange("Usuario EMT", UsuarioEmt);
        if Usuario.FindFirst() then
            UsuarioId := Usuario."Id Usuario"
        else
            if Usuario.Get(UsuarioEmt) then
                UsuarioId := Usuario."Id Usuario";
    end;

    /// <summary>
    /// stop como texto (legado) o como objeto {"number":"25","name":"Dic de l'Oest"}.
    /// StopText: texto para observaciones/Gtask; CodigoParada: Nº emplazamiento (p. ej. P25).
    /// </summary>
    local procedure ParsearStopPostIncidenciaEmt(StopToken: JsonToken; var StopText: Text; var CodigoParada: Code[20])
    var
        StopObj: JsonObject;
        T: JsonToken;
        NumTxt: Text;
        NomTxt: Text;
        NumTrim: Text;
    begin
        Clear(StopText);
        Clear(CodigoParada);
        if StopToken.IsObject() then begin
            StopObj := StopToken.AsObject();
            Clear(NumTxt);
            Clear(NomTxt);
            if StopObj.Get('number', T) then
                NumTxt := T.AsValue().AsText();
            if StopObj.Get('name', T) then
                NomTxt := T.AsValue().AsText();
            NumTrim := DelChr(NumTxt, '<>', ' ');
            if (NumTrim <> '') and (NomTxt <> '') then
                StopText := NumTrim + ' - ' + NomTxt
            else if NumTrim <> '' then
                StopText := NumTrim
            else
                StopText := NomTxt;
            if NumTrim <> '' then begin
                if (StrLen(NumTrim) < MaxStrLen(CodigoParada)) and (UpperCase(CopyStr(NumTrim, 1, 1)) <> 'P') then
                    CodigoParada := CopyStr('P' + NumTrim, 1, MaxStrLen(CodigoParada))
                else
                    CodigoParada := CopyStr(NumTrim, 1, MaxStrLen(CodigoParada));
            end else
                if NomTxt <> '' then
                    CodigoParada := CopyStr(NomTxt, 1, MaxStrLen(CodigoParada));
        end else
            if StopToken.IsValue() then begin
                StopText := StopToken.AsValue().AsText();
                CodigoParada := CopyStr(StopText, 1, MaxStrLen(CodigoParada));
            end;
    end;

    local procedure ConstruirObservationDesdePartes(Observation: Text; Frequency: Text; Departament: Text; Zone: Text; StopName: Text): Text
    var
        Partes: List of [Text];
        Parte: Text;
        Resultado: Text;
    begin
        Partes.Add(Observation);
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

    procedure ResolverPlantillaParte(TipoRecurso: Code[20]; TipoEmplaz: Enum "Tipo Emplazamiento"): Code[20]
    var
        TipoRec: Record "Tipo Recurso";
        JobsSetup: Record "Jobs Setup";
    begin
        if TipoRecurso <> '' then
            if TipoRec.Get(TipoRecurso) then
                if TipoRec."Nº Parte Plantilla" <> '' then
                    exit(TipoRec."Nº Parte Plantilla");

        JobsSetup.Get();
        case TipoEmplaz of
            TipoEmplaz::Opis:
                exit(JobsSetup."Plantilla Opis");
            TipoEmplaz::Vallas:
                exit(JobsSetup."Plantilla Vallas");
            TipoEmplaz::"Otros":
                exit(JobsSetup."Plantilla Otros");
        end;
    end;

    procedure CopiarLineasPlantillaParte(ParteDestino: Code[20]; PlantillaNo: Code[20])
    var
        LineSrc: Record "Time Sheet Line";
        LineDst: Record "Time Sheet Line";
        NextLineNo: Integer;
        PlantillaHdr: Record "Time Sheet Header";
    begin
        if (ParteDestino = '') or (PlantillaNo = '') then
            exit;
        if not PlantillaHdr.Get(PlantillaNo) then
            exit;
        if not PlantillaHdr."Es Plantilla" then
            exit;

        LineDst.SetRange("Time Sheet No.", ParteDestino);
        LineDst.DeleteAll();
        if LineDst.FindLast() then
            NextLineNo := LineDst."Line No."
        else
            NextLineNo := 0;

        LineSrc.SetRange("Time Sheet No.", PlantillaNo);
        if LineSrc.FindSet() then
            repeat
                NextLineNo += 10000;
                LineDst.Init();
                LineDst.TransferFields(LineSrc, false);
                LineDst."Time Sheet No." := ParteDestino;
                LineDst."Line No." := NextLineNo;
                LineDst.Insert();
            until LineSrc.Next() = 0;
    end;

    procedure AplicarPlantillaParteEMT(var Parte: Record "Time Sheet Header"; Incidencia: Record Incidencias)
    begin
        AplicarPlantillaParte(Parte, Incidencia);
    end;

    procedure AplicarPlantillaParte(var Parte: Record "Time Sheet Header"; Incidencia: Record Incidencias)
    var
        PlantillaNo: Code[20];
        TipoRecurso: Code[20];
        TipoEmplaz: Enum "Tipo Emplazamiento";
        Emplaz: Record Emplazamientos;

    begin
        if Parte."No." = '' then
            exit;
        If Incidencia.Plantilla <> '' Then PlantillaNo := Incidencia.Plantilla;
        If PlantillaNo = '' Then begin
            if not ObtenerEmplazamientoDesdeIncidencia(Incidencia, Emplaz, TipoRecurso) then
                exit;

            PlantillaNo := ResolverPlantillaParte(TipoRecurso, Emplaz."Tipo Emplazamiento");
        End;
        if PlantillaNo = '' then
            exit;
        CopiarLineasPlantillaParte(Parte."No.", PlantillaNo);
    end;

    procedure AsegurarParteMantenimiento(var Incidencia: Record Incidencias): Boolean
    var
        Emplaz: Record Emplazamientos;
        TipoRecurso: Code[20];
        TipoParte: Option " ",Trabajo,Nacional,EMT;
    begin
        if (not Incidencia."Es Peticion") then
            if Incidencia."SubTipo Incidencia" <> Incidencia."SubTipo Incidencia"::Mantenimiento then
                exit(false);
        if not ObtenerEmplazamientoDesdeIncidencia(Incidencia, Emplaz, TipoRecurso) then
            exit(false);

        case Emplaz."Tipo Emplazamiento" of
            Emplaz."Tipo Emplazamiento"::Opis:
                TipoParte := TipoParte::EMT;
            else
                TipoParte := TipoParte::Trabajo;
        end;
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        exit(true);
    end;

    local procedure EstablecerCreadorOrdenGtask(IdGtask: Text)
    var
        UsuariosGtask: Record UsuariosGtask;
        IdTxt: Text[50];
    begin
        Clear(IdUsuarioCreadorOrden);
        IdGtaskCreadorOrden := '';
        IdTxt := CopyStr(DelChr(IdGtask, '<>', ' '), 1, MaxStrLen(IdGtaskCreadorOrden));
        if IdTxt = '' then
            exit;
        UsuariosGtask.ChangeCompany('Malla Publicidad');
        UsuariosGtask.SetRange("Id Gtask", IdTxt);
        if not UsuariosGtask.FindFirst() then
            Error('No se ha encontrado el usuario de GTask %1 en UsuariosGtask. No se usa el usuario de OData como creador.', IdTxt);
        if IsNullGuid(UsuariosGtask."Id Usuario") then
            Error('El usuario de GTask %1 no tiene un usuario de Business Central enlazado.', IdTxt);
        IdGtaskCreadorOrden := IdTxt;
        IdUsuarioCreadorOrden := UsuariosGtask."Id Usuario";
    end;

    local procedure BuscarUsuarioCreadorParte(var UsuariosGtask: Record UsuariosGtask)
    begin
        UsuariosGtask.ChangeCompany('Malla Publicidad');
        UsuariosGtask.Reset();
        if IdGtaskCreadorOrden <> '' then begin
            UsuariosGtask.SetRange("Id Gtask", IdGtaskCreadorOrden);
            if not UsuariosGtask.FindFirst() then
                Error('No se ha encontrado el usuario de GTask %1 en la tabla UsuariosGtask', IdGtaskCreadorOrden);
            exit;
        end;
        UsuariosGtask.SetRange("Id Usuario", UserSecurityId());
        if not UsuariosGtask.FindFirst() then
            Error('No se ha encontrado el usuario %1 en la tabla UsuariosGtask', UserId());
    end;

    local procedure AsignarCreadorTareaMantenimiento(var UserTask: Record "User Task")
    begin
        if not IsNullGuid(IdUsuarioCreadorOrden) then
            UserTask."Created By" := IdUsuarioCreadorOrden
        else
            UserTask."Created By" := UserTask."Supervisor";
    end;

    local procedure CrearParteMantenimiento(var Incidencia: Record Incidencias; Emplaz: Record Emplazamientos; TipoParte: Option " ",Trabajo,Nacional,EMT)
    var
        Parte: Record "Time Sheet Header";
        JobsSetup: Record "Jobs Setup";
        TipoRecurso: Code[20];
        Resource: Record Resource;
        PlantillaNo: Code[20];
        Employee: Record Employee;
        UsuariosGtask: Record UsuariosGtask;
    begin
        if Incidencia."No." = '' then
            exit;

        if Incidencia."Parte Trabajo" <> '' then begin
            if Parte.Get(Incidencia."Parte Trabajo") then
                AplicarPlantillaParte(Parte, Incidencia);
            exit;
        end;
        If Parte.Get(Incidencia."No.") Then Parte.Delete;
        Parte.Init();
        Parte."No." := Incidencia."No.";
        Parte.Validate(Tipo, TipoParte);
        BuscarUsuarioCreadorParte(UsuariosGtask);
        UsuariosGtask.TestField("Empleado");
        Employee.Get(UsuariosGtask."Empleado");
        Employee.TestField("Resource No.");
        Parte."Resource No." := Employee."Resource No.";
        if TipoParte = TipoParte::EMT then begin
            JobsSetup.Get();
            JobsSetup.TestField("Cliente EMT x defecto");
            Parte.Validate(Cliente, JobsSetup."Cliente EMT x defecto");
        end;
        Parte.Insert(true);

        Incidencia."Parte Trabajo" := Parte."No.";
        Incidencia.Modify(true);

        if Emplaz."Nº Emplazamiento" = '' then
            exit;

        if Incidencia."Tipo Elemento" = Incidencia."Tipo Elemento"::Recurso then
            if Resource.Get(Incidencia.Recurso) then
                TipoRecurso := Resource."Tipo Recurso";
        PlantillaNo := ResolverPlantillaParte(TipoRecurso, Emplaz."Tipo Emplazamiento");
        If Incidencia.Plantilla <> '' Then PlantillaNo := Incidencia.Plantilla;
        if PlantillaNo <> '' then
            CopiarLineasPlantillaParte(Parte."No.", PlantillaNo);
    end;

    local procedure ObtenerEmplazamientoDesdeIncidencia(Incidencia: Record Incidencias; var Emplaz: Record Emplazamientos; var TipoRecurso: Code[20]): Boolean
    var
        Resource: Record Resource;
    begin
        TipoRecurso := '';
        if Incidencia."Tipo Elemento" = Incidencia."Tipo Elemento"::Parada then
            exit(Emplaz.Get(Emplaz."Tipo Emplazamiento"::Opis, Incidencia.Recurso));

        if not Resource.Get(Incidencia.Recurso) then
            exit(false);
        TipoRecurso := Resource."Tipo Recurso";
        if Resource."Nº Emplazamiento" = '' then
            exit(false);
        if Emplaz.Get(Emplaz."Tipo Emplazamiento"::Vallas, Resource."Nº Emplazamiento") then
            exit(true);
        if Emplaz.Get(Emplaz."Tipo Emplazamiento"::"Otros", Resource."Nº Emplazamiento") then
            exit(true);
        exit(Emplaz.Get(Emplaz."Tipo Emplazamiento"::Opis, Resource."Nº Emplazamiento"));
    end;

    local procedure ObtenerRecursoPrincipalEmplazamiento(Emplaz: Record Emplazamientos): Code[20]
    var
        Resource: Record Resource;
    begin
        Resource.SetRange("Nº Emplazamiento", Emplaz."Nº Emplazamiento");
        Resource.SetRange(Blocked, false);
        if Resource.FindFirst() then
            exit(Resource."No.");
        exit('');
    end;

    procedure ActualizarMantenimientoDesdeIncidencia(Incidencia: Record Incidencias)
    var
        EmplCu: Codeunit Emplazamientos;
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        TipoRecurso: Code[20];
        Fecha: Date;
    begin
        if Incidencia.Estado <> Incidencia.Estado::Cerrada then
            exit;
        if Incidencia."SubTipo Incidencia" <> Incidencia."SubTipo Incidencia"::Mantenimiento then
            exit;

        Fecha := DT2Date(Incidencia."FechaHora");
        if Fecha = 0D then
            Fecha := WorkDate();

        if not ObtenerEmplazamientoDesdeIncidencia(Incidencia, Emplaz, TipoRecurso) then
            exit;

        if Incidencia."Tipo Elemento" = Incidencia."Tipo Elemento"::Recurso then
            if not Resource.Get(Incidencia.Recurso) then
                Resource.Init();

        if TienePeriodicidadMantenimientoFicha(Emplaz, Resource) then begin
            if Incidencia."Tipo Elemento" = Incidencia."Tipo Elemento"::Recurso then
                ActualizarTrasMantenimiento(Resource, Fecha) else
                EmplCu.ActualizarMantenimientoEmplazamiento(Emplaz."Tipo Emplazamiento", Emplaz."Nº Emplazamiento", Fecha)
        end
        else
            ActualizarProximoMantenimientoDesdeZona(Emplaz, Resource, Fecha);
    end;

    procedure ActualizarTrasMantenimiento(var Resource: Record Resource; FechaActuacion: Date)
    begin
        if FechaActuacion = 0D then
            FechaActuacion := WorkDate();
        Resource."Último Mantenimiento" := FechaActuacion;
        Resource."Bajo Mantenimiento" := false;
        Resource."Fecha Próximo Mantenimiento" := CalcularProximoMantenimiento(Resource, FechaActuacion);
        Resource.Modify();
    end;

    procedure CalcularProximoMantenimiento(Resource: Record Resource; FechaBase: Date): Date
    var
        Periodicidad: DateFormula;
        FechaBusqueda: Date;
    begin
        if FechaBase = 0D then
            FechaBase := WorkDate();
        if Format(Resource."Periodicidad Mantenimiento") = '' then
            exit(CalcularPeriodicidadZona(Resource."Zona Mantenimiento", FechaBase));
        Periodicidad := Resource."Periodicidad Mantenimiento";
        FechaBusqueda := CalcDate(Periodicidad, FechaBase);
        if not EsDiaLaborable(FechaBusqueda) then begin
            while not EsDiaLaborable(FechaBusqueda) do
                FechaBusqueda := FechaBusqueda + 1;
        end;
        exit(FechaBusqueda);
    end;

    procedure CalcularPeriodicidadZona(Zona: Integer; Fecha: Date): Date
    var
        Zonas: Record "Zonas Limpieza";
        PeriodicidadZona: Record "Periodicidad Zona Limpieza";
        FechaBusqueda: Date;
        MaxIteraciones: Integer;
    begin
        // Si hay reglas de periodicidad definidas en la tabla, usarlas (solo días laborables L-V y sin festivos)
        PeriodicidadZona.SetRange("Id Zona Limpieza", Zona);
        if PeriodicidadZona.FindFirst() then begin
            FechaBusqueda := Fecha;
            MaxIteraciones := 366;
            while MaxIteraciones > 0 do begin
                FechaBusqueda := FechaBusqueda + 1;
                if CoincideConPeriodicidadZona(FechaBusqueda, Zona) then
                    exit(FechaBusqueda);
                MaxIteraciones -= 1;
            end;
            if not EsDiaLaborable(FechaBusqueda) then begin
                while not EsDiaLaborable(FechaBusqueda) do
                    FechaBusqueda := FechaBusqueda + 1;
            end;

            exit(0D); // No se encontró próxima fecha en el año
        end;
    end;

    local procedure EsDiaLaborable(Fecha: Date): Boolean
    var
        Calendario: Record "Base Calendar Change";
    begin
        Calendario.ChangeCompany('Malla Publicidad');
        Calendario.SetRange("Date", Fecha);
        If Calendario.FindFirst() then begin
            If Calendario.Nonworking Then exit(false);
            If (Calendario.Day = Calendario.Day::Sunday) or (Calendario.Day = Calendario.Day::Saturday) Then exit(false);
        end;
        exit(true);
    end;

    local procedure CoincideConPeriodicidadZona(Fecha: Date; IdZonaLimpieza: Integer): Boolean
    var
        PeriodicidadZona: Record "Periodicidad Zona Limpieza";
        DiaSemana: Integer;
        DiaDelMes: Integer;
        Mes: Integer;
        DíaSemanaEnum: Enum "Día Semana Limpieza";
    begin
        PeriodicidadZona.SetRange("Id Zona Limpieza", IdZonaLimpieza);
        if not PeriodicidadZona.FindSet() then
            exit(false);
        DiaSemana := Date2DWY(Fecha, 1);
        DiaDelMes := Date2DMY(Fecha, 1);
        Mes := Date2DMY(Fecha, 2); // meses invierno: 11, 12, 1, 2, 3
        repeat
            if not AplicaLineaEnFecha(PeriodicidadZona.Temporada, Mes) then
                continue;
            case PeriodicidadZona."Tipo Periodicidad" of
                PeriodicidadZona."Tipo Periodicidad"::"Día semanal":
                    if (PeriodicidadZona."Día Semana" <> DíaSemanaEnum::Ninguno) and
                       CoincideDiaSemana(DiaSemana, PeriodicidadZona."Día Semana")
                    then
                        exit(true);
                PeriodicidadZona."Tipo Periodicidad"::"Día del mes":
                    if (PeriodicidadZona."Día del mes" >= 1) and (PeriodicidadZona."Día del mes" <= 31) and
                       (DiaDelMes = PeriodicidadZona."Día del mes")
                    then
                        exit(true);
            end;
        until PeriodicidadZona.Next() = 0;
        exit(false);
    end;

    local procedure CoincideDiaSemana(DiaSemanaNum: Integer; DíaSemana: Enum "Día Semana Limpieza"): Boolean
    begin
        case DíaSemana of
            DíaSemana::Lunes:
                exit(DiaSemanaNum = 1);
            DíaSemana::Martes:
                exit(DiaSemanaNum = 2);
            DíaSemana::Miércoles:
                exit(DiaSemanaNum = 3);
            DíaSemana::Jueves:
                exit(DiaSemanaNum = 4);
            DíaSemana::Viernes:
                exit(DiaSemanaNum = 5);
            else
                exit(false);
        end;
    end;

    local procedure AplicaLineaEnFecha(Temporada: Enum "Temporada Limpieza"; Mes: Integer): Boolean
    begin
        case Temporada of
            Temporada::Todas:
                exit(true);
            Temporada::Invierno:
                exit(Mes in [1, 2, 11, 12]); // nov, dic, ene, feb
            Temporada::Verano:
                exit(Mes in [3, 4, 5, 6, 7, 8, 9, 10]); // mar, abr, may, jun, jul, ago, sep, oct
            else
                exit(true);
        end;
    end;

    procedure ProcesarMantenimientosVencidos(): Integer
    var
        Emplaz: Record Emplazamientos;
        Contador: Integer;
        NoIncidencia: Code[20];
        Recursos: Record Resource;
    begin
        Emplaz.SetFilter("Fecha Próximo Mantenimiento", '<=%1&<>%2', WorkDate(), 0D);
        Emplaz.SetRange("Bajo Mantenimiento", false);
        if Emplaz.FindSet() then
            repeat
                if MantenimientoPendienteEmplazamiento(Emplaz) then begin
                    Emplaz."Bajo Mantenimiento" := true;
                    Emplaz.Modify(false);
                end else begin
                    NoIncidencia := CrearIncidenciaMantenimientoEmplazamiento(Emplaz);
                    if NoIncidencia <> '' then
                        Contador += 1;
                end;
            until Emplaz.Next() = 0;
        Recursos.SetFilter("Fecha Próximo Mantenimiento", '<=%1&<>%2', WorkDate(), 0D);
        Recursos.SetRange("Bajo Mantenimiento", false);
        if Recursos.FindSet() then
            repeat
                if MantenimientoPendienteRecurso(Recursos."No.") then begin
                    Emplaz."Bajo Mantenimiento" := true;
                    Emplaz.Modify(false);
                end else begin
                    NoIncidencia := CrearIncidenciaMantenimientoRecurso(Recursos, 'Mantenimiento pendiente de recurso ' + Recursos.Name, false);
                    if NoIncidencia <> '' then
                        Contador += 1;
                end;
            until Recursos.Next() = 0;
        if Contador > 0 then
            Commit();
        exit(Contador);
    end;

    procedure ProcesarMantenimientosVencidosOpis(): Integer
    begin
        exit(ProcesarMantenimientosVencidos());
    end;

    procedure MantenimientoPendienteEmplazamiento(Emplaz: Record Emplazamientos): Boolean
    begin
        case Emplaz."Tipo Emplazamiento" of
            Emplaz."Tipo Emplazamiento"::Opis:
                exit(PeticionMantenimientoPendienteParada(Emplaz."Nº Emplazamiento"));
            else
                exit(MantenimientoPendienteEmplazamientoRecursos(Emplaz."Nº Emplazamiento"));
        end;
    end;

    procedure PeticionMantenimientoPendiente(NParada: Code[20]): Boolean
    begin
        exit(PeticionMantenimientoPendienteParada(NParada));
    end;

    local procedure PeticionMantenimientoPendienteParada(NParada: Code[20]): Boolean
    var
        Incidencia: Record Incidencias;
    begin
        if NParada = '' then
            exit(false);
        Incidencia.SetRange(Recurso, NParada);
        Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Parada);
        Incidencia.SetRange("SubTipo Incidencia", Incidencia."SubTipo Incidencia"::Mantenimiento);
        Incidencia.SetFilter(Estado, '<>%1', Incidencia.Estado::Cerrada);
        exit(not Incidencia.IsEmpty());
    end;

    local procedure MantenimientoPendienteEmplazamientoRecursos(NEmplazamiento: Code[20]): Boolean
    var
        Resource: Record Resource;
        Incidencia: Record Incidencias;
    begin
        if NEmplazamiento = '' then
            exit(false);
        Resource.SetRange("Nº Emplazamiento", NEmplazamiento);
        if Resource.FindSet() then
            repeat
                Incidencia.Reset();
                Incidencia.SetRange(Recurso, Resource."No.");
                Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Recurso);
                Incidencia.SetRange("SubTipo Incidencia", Incidencia."SubTipo Incidencia"::Mantenimiento);
                Incidencia.SetFilter(Estado, '<>%1', Incidencia.Estado::Cerrada);
                if not Incidencia.IsEmpty() then
                    exit(true);
            until Resource.Next() = 0;
        exit(false);
    end;

    procedure CrearIncidenciaMantenimientoEmplazamiento(var Emplaz: Record Emplazamientos): Code[20]
    var
        TipoInc: Enum "Tipo Incidencia";
    begin
        Emplaz.TestField("Nº Emplazamiento");
        if MantenimientoPendienteEmplazamiento(Emplaz) then
            exit(BuscarNoIncidenciaMantenimientoAbierta(Emplaz));

        case Emplaz."Tipo Emplazamiento" of
            Emplaz."Tipo Emplazamiento"::Opis:
                exit(CrearMantenimientoOpis(Emplaz));
            Emplaz."Tipo Emplazamiento"::Vallas:
                exit(CrearMantenimientoRecurso(Emplaz, TipoInc::"Incidencias Soportes"));
            Emplaz."Tipo Emplazamiento"::"Otros":
                exit(CrearMantenimientoRecurso(Emplaz, TipoInc::"Incidencias Mobiliario Urbano"));
        end;
        exit('');
    end;

    procedure CrearPeticionMantenimientoOpis(var Emplaz: Record Emplazamientos): Code[20]
    begin
        exit(CrearIncidenciaMantenimientoEmplazamiento(Emplaz));
    end;

    procedure CrearPeticionEMTParada(var Emplaz: Record Emplazamientos): Code[20]
    var
        Incidencia: Record Incidencias;
        TipoParte: Option " ",Trabajo,Nacional,EMT;
    begin
        Emplaz.TestField("Nº Emplazamiento");
        if Emplaz."Tipo Emplazamiento" <> Emplaz."Tipo Emplazamiento"::Opis then
            Error('La petición EMT solo se crea desde una parada.');

        Incidencia.Init();
        Incidencia."Es Peticion" := true;
        Incidencia."Comunicado por EMT" := true;
        Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Parada;
        Incidencia.Recurso := Emplaz."Nº Emplazamiento";
        Incidencia."Tipo Incidencia" := Incidencia."Tipo Incidencia"::"Incidencias EMT";
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Otras;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Correctivo;
        Incidencia."User Task Group" := 'EMT';
        Incidencia.Estado := Incidencia.Estado::Abierta;
        Incidencia.Fecha := Today;
        Incidencia."FechaHora" := CurrentDateTime();
        Incidencia."Fecha Actuacion" := CurrentDateTime();
        Incidencia.Descripción := CopyStr('Petición EMT ' + Emplaz."Nº Emplazamiento" + ' ' + Emplaz."Descripción", 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);

        TipoParte := TipoParte::EMT;
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        Incidencia.TestField("Parte Trabajo");
        LigarTareaConOrden(Incidencia);
        exit(Incidencia."No.");
    end;

    procedure CrearPeticionInternaEmplazamiento(var Emplaz: Record Emplazamientos): Code[20]
    var
        Incidencia: Record Incidencias;
        NRecurso: Code[20];
        TipoParte: Option " ",Trabajo,Nacional,EMT;
        TipoInc: Enum "Tipo Incidencia";
    begin
        Emplaz.TestField("Nº Emplazamiento");
        Incidencia.Init();
        Incidencia."Es Peticion" := true;
        Incidencia."Comunicado por EMT" := false;
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Otras;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Correctivo;
        RellenarIncidenciaAbierta(Incidencia);
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then begin
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Parada;
            Incidencia.Recurso := Emplaz."Nº Emplazamiento";
            Incidencia."Tipo Incidencia" := Incidencia."Tipo Incidencia"::"Incidencias EMT";
            Incidencia."User Task Group" := 'EMT';
            TipoParte := TipoParte::EMT;
        end else begin
            NRecurso := ObtenerRecursoPrincipalEmplazamiento(Emplaz);
            if NRecurso = '' then
                Error('El emplazamiento %1 no tiene un recurso para la petición.', Emplaz."Nº Emplazamiento");
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Recurso;
            Incidencia.Recurso := NRecurso;
            if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Vallas then
                TipoInc := TipoInc::"Incidencias Soportes"
            else
                TipoInc := TipoInc::"Incidencias Mobiliario Urbano";
            Incidencia."Tipo Incidencia" := TipoInc;
            Incidencia."User Task Group" := 'MTO';
            TipoParte := TipoParte::Trabajo;
        end;
        Incidencia.Descripción := CopyStr('Petición ' + Emplaz."Nº Emplazamiento" + ' ' + Emplaz."Descripción", 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        Incidencia.TestField("Parte Trabajo");
        LigarTareaConOrden(Incidencia);
        exit(Incidencia."No.");
    end;

    procedure CrearPeticionInternaRecurso(var Resource: Record Resource): Code[20]
    var
        Incidencia: Record Incidencias;
        Emplaz: Record Emplazamientos;
        TipoParte: Option " ",Trabajo,Nacional,EMT;
        TipoInc: Enum "Tipo Incidencia";
    begin
        Resource.TestField("No.");
        Incidencia.Init();
        Incidencia."Es Peticion" := true;
        Incidencia."Comunicado por EMT" := false;
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Otras;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Correctivo;
        Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Recurso;
        Incidencia.Recurso := Resource."No.";
        Incidencia."User Task Group" := 'MTO';
        RellenarIncidenciaAbierta(Incidencia);
        TipoInc := TipoInc::"Incidencias Soportes";
        TipoParte := TipoParte::Trabajo;
        if TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then
            case Emplaz."Tipo Emplazamiento" of
                Emplaz."Tipo Emplazamiento"::Opis:
                    begin
                        TipoInc := TipoInc::"Incidencias EMT";
                        Incidencia."User Task Group" := 'EMT';
                        TipoParte := TipoParte::EMT;
                    end;
                Emplaz."Tipo Emplazamiento"::"Otros":
                    TipoInc := TipoInc::"Incidencias Mobiliario Urbano";
            end
        else
            Emplaz.Init();
        Incidencia."Tipo Incidencia" := TipoInc;
        Incidencia.Descripción := CopyStr('Petición ' + Resource."No." + ' ' + Resource.Name, 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        Incidencia.TestField("Parte Trabajo");
        LigarTareaConOrden(Incidencia);
        exit(Incidencia."No.");
    end;

    procedure AltaIncidenciaParada(var Emplaz: Record Emplazamientos; SubTipo: Enum "SubTipo Incidencia"): Code[20]
    var
        Incidencia: Record Incidencias;
    begin
        Emplaz.TestField("Nº Emplazamiento");
        if Emplaz."Tipo Emplazamiento" <> Emplaz."Tipo Emplazamiento"::Opis then
            Error('La incidencia de parada solo se crea desde una parada.');
        Incidencia.Init();
        Incidencia."Es Peticion" := false;
        Incidencia."Comunicado por EMT" := false;
        Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Parada;
        Incidencia.Recurso := Emplaz."Nº Emplazamiento";
        Incidencia."Tipo Incidencia" := Incidencia."Tipo Incidencia"::"Incidencias EMT";
        Incidencia."SubTipo Incidencia" := SubTipo;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Correctivo;
        Incidencia."User Task Group" := 'EMT';
        RellenarIncidenciaAbierta(Incidencia);
        if SubTipo = SubTipo::Tip then
            Incidencia.Descripción := CopyStr('Incidencia TIP ' + Emplaz."Nº Emplazamiento" + ' ' + Emplaz."Descripción", 1, MaxStrLen(Incidencia.Descripción))
        else
            Incidencia.Descripción := CopyStr('Incidencia ' + Emplaz."Nº Emplazamiento" + ' ' + Emplaz."Descripción", 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        exit(Incidencia."No.");
    end;

    procedure AltaIncidenciaEmplazamiento(var Emplaz: Record Emplazamientos; SubTipo: Enum "SubTipo Incidencia"): Code[20]
    var
        Resource: Record Resource;
        NRecurso: Code[20];
    begin
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then
            exit(AltaIncidenciaParada(Emplaz, SubTipo));
        NRecurso := ObtenerRecursoPrincipalEmplazamiento(Emplaz);
        if NRecurso = '' then
            Error('El emplazamiento %1 no tiene un recurso para la incidencia.', Emplaz."Nº Emplazamiento");
        Resource.Get(NRecurso);
        exit(AltaIncidenciaRecurso(Resource, SubTipo));
    end;

    procedure AltaIncidenciaRecurso(var Resource: Record Resource; SubTipo: Enum "SubTipo Incidencia"): Code[20]
    var
        Incidencia: Record Incidencias;
        Emplaz: Record Emplazamientos;
        TipoInc: Enum "Tipo Incidencia";
    begin
        Resource.TestField("No.");
        Incidencia.Init();
        Incidencia."Es Peticion" := false;
        Incidencia."Comunicado por EMT" := false;
        Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Recurso;
        Incidencia.Recurso := Resource."No.";
        Incidencia."SubTipo Incidencia" := SubTipo;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Correctivo;
        Incidencia."User Task Group" := 'MTO';
        RellenarIncidenciaAbierta(Incidencia);
        TipoInc := TipoInc::"Incidencias Soportes";
        if TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then
            case Emplaz."Tipo Emplazamiento" of
                Emplaz."Tipo Emplazamiento"::Opis:
                    begin
                        TipoInc := TipoInc::"Incidencias EMT";
                        Incidencia."User Task Group" := 'EMT';
                    end;
                Emplaz."Tipo Emplazamiento"::"Otros":
                    TipoInc := TipoInc::"Incidencias Mobiliario Urbano";
            end;
        Incidencia."Tipo Incidencia" := TipoInc;
        Incidencia.Descripción := CopyStr('Incidencia ' + Resource."No." + ' ' + Resource.Name, 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        exit(Incidencia."No.");
    end;

    procedure AbrirFichaMovimiento(NoMovimiento: Code[20])
    var
        Incidencia: Record Incidencias;
    begin
        if NoMovimiento = '' then
            exit;
        Incidencia.Get(NoMovimiento);
        if Incidencia."Es Peticion" or (Incidencia."Tipo Intervención" = Incidencia."Tipo Intervención"::Preventivo) then begin
            AsegurarParteMantenimiento(Incidencia);
            Commit();
            Page.RunModal(Page::"Ordenes Trabajo", Incidencia);
        end else
            Page.RunModal(Page::"Incidencias Taller", Incidencia);
    end;

    procedure AbrirHistoricoParada(var Parada: Record Emplazamientos; Clase: Text)
    var
        Incidencia: Record Incidencias;
    begin
        Parada.TestField("Nº Emplazamiento");
        Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Parada);
        Incidencia.SetRange(Recurso, Parada."Nº Emplazamiento");
        AplicarClaseHistorico(Incidencia, Clase);
        Page.Run(Page::"Histórico movimientos", Incidencia);
    end;

    procedure AbrirHistoricoEmplazamiento(var Emplaz: Record Emplazamientos; Clase: Text)
    var
        Incidencia: Record Incidencias;
        Resource: Record Resource;
        FiltroRecursos: Text;
    begin
        Emplaz.TestField("Nº Emplazamiento");
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then begin
            AbrirHistoricoParada(Emplaz, Clase);
            exit;
        end;
        Resource.SetRange("Nº Emplazamiento", Emplaz."Nº Emplazamiento");
        if Resource.FindSet() then
            repeat
                if FiltroRecursos <> '' then
                    FiltroRecursos += '|';
                FiltroRecursos += Resource."No.";
            until Resource.Next() = 0;
        if FiltroRecursos = '' then
            FiltroRecursos := '##NOMATCH##';
        Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Recurso);
        Incidencia.SetFilter(Recurso, FiltroRecursos);
        AplicarClaseHistorico(Incidencia, Clase);
        Page.Run(Page::"Histórico movimientos", Incidencia);
    end;

    procedure AbrirHistoricoRecurso(var Resource: Record Resource; Clase: Text)
    var
        Incidencia: Record Incidencias;
    begin
        Resource.TestField("No.");
        Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Recurso);
        Incidencia.SetRange(Recurso, Resource."No.");
        AplicarClaseHistorico(Incidencia, Clase);
        Page.Run(Page::"Histórico movimientos", Incidencia);
    end;

    local procedure IdQrOrdenTrabajo(Incidencia: Record Incidencias): Text[100]
    begin
        if Incidencia."Parte Trabajo" = '' then
            exit('');
        exit(CopyStr('OT-' + Incidencia."Parte Trabajo", 1, 100));
    end;

    local procedure LigarTareaConOrden(var Incidencia: Record Incidencias)
    var
        UserTask: Record "User Task";
        IdTarea: Text;
        IdQrOrden: Text[100];
    begin
        if Incidencia."Parte Trabajo" = '' then
            exit;
        IdQrOrden := IdQrOrdenTrabajo(Incidencia);
        if (Incidencia."Id_Tarea" <> 0) and UserTask.Get(Incidencia."Id_Tarea") then begin
            if UserTask.IdQr <> IdQrOrden then begin
                UserTask.IdQr := IdQrOrden;
                UserTask.Modify(false);
            end;
            exit;
        end;
        IdTarea := CrearTareaIncidencia(Incidencia);
        Incidencia.Get(Incidencia."No.");
        if (CopyStr(IdTarea, 1, 5) = 'Error') or (StrLen(IdTarea) > 30) then
            Error('La orden %1 está creada, pero la tarea no se ha publicado: %2', Incidencia."Parte Trabajo", IdTarea);
    end;

    procedure CrearOrdenTrabajoIncidencia(var Incidencia: Record Incidencias)
    var
        Emplaz: Record Emplazamientos;
        UserTask: Record "User Task";
        TipoRecurso: Code[20];
        TipoParte: Option " ",Trabajo,Nacional,EMT;
        IdQrOrden: Text[100];
        TieneEmplazamiento: Boolean;
    begin
        Incidencia.TestField("No.");
        TieneEmplazamiento := ObtenerEmplazamientoDesdeIncidencia(Incidencia, Emplaz, TipoRecurso);
        if not TieneEmplazamiento then
            Clear(Emplaz);
        if TieneEmplazamiento and (Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis) then
            TipoParte := TipoParte::EMT
        else
            TipoParte := TipoParte::Trabajo;
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        Incidencia.TestField("Parte Trabajo");
        if not BuscarTareaDeIncidencia(Incidencia, UserTask) then begin
            LigarTareaConOrden(Incidencia);
            Incidencia.Get(Incidencia."No.");
            if not BuscarTareaDeIncidencia(Incidencia, UserTask) then
                Error('La orden %1 se ha creado, pero no se ha podido crear su tarea GTask.', Incidencia."Parte Trabajo");
        end;
        IdQrOrden := IdQrOrdenTrabajo(Incidencia);
        if UserTask.IdQr <> IdQrOrden then begin
            UserTask.IdQr := IdQrOrden;
            UserTask.Modify(false);
        end;
        if Incidencia.Id_Tarea <> UserTask.ID then begin
            Incidencia.Id_Tarea := UserTask.ID;
            Incidencia.Modify(true);
        end;
        Commit();
        PublicarIdQrOrdenEnGtask(UserTask);
    end;

    local procedure BuscarTareaDeIncidencia(Incidencia: Record Incidencias; var UserTask: Record "User Task"): Boolean
    begin
        if (Incidencia.Id_Tarea <> 0) and UserTask.Get(Incidencia.Id_Tarea) then
            exit(true);
        if Incidencia."ID Tarea Gtask" = '' then
            exit(false);
        UserTask.Reset();
        UserTask.SetRange(Id_Tarea, Incidencia."ID Tarea Gtask");
        exit(UserTask.FindFirst());
    end;

    local procedure PublicarIdQrOrdenEnGtask(UserTask: Record "User Task")
    var
        RestApi: Codeunit "Control Ocr";
        CompanyInfo: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        JsonObj: JsonObject;
        Json: Text;
    begin
        if (UserTask.Id_Tarea = '') or (UserTask.IdQr = '') then
            exit;
        CompanyInfo.Get();
        if CompanyInfo."Url Task" = '' then
            exit;
        JsonObj.Add('IdQr', UserTask.IdQr);
        JsonObj.WriteTo(Json);
        RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + UserTask.Id_Tarea, Token(), RequestType::put, Json);
    end;

    local procedure RellenarIncidenciaAbierta(var Incidencia: Record Incidencias)
    begin
        Incidencia.Estado := Incidencia.Estado::Abierta;
        Incidencia.Fecha := Today;
        Incidencia."FechaHora" := CurrentDateTime();
        Incidencia."Fecha Actuacion" := CurrentDateTime();
    end;

    /// <summary>
    /// Texto genérico de cierre (p. ej. app móvil) que no debe sustituir la descripción original en BC.
    /// </summary>
    local procedure EsTextoPlaceholderCierreIncidencia(Texto: Text; NoIncidencia: Code[20]): Boolean
    var
        Txt: Text;
        Prefijo: Text;
    begin
        Txt := DelChr(LowerCase(Texto), '<>', ' ');
        if Txt = '' then
            exit(true);
        Prefijo := 'cierreincidencia';
        if CopyStr(Txt, 1, StrLen(Prefijo)) = Prefijo then
            exit(true);
        Prefijo := 'cierredeincidencia';
        if CopyStr(Txt, 1, StrLen(Prefijo)) = Prefijo then
            exit(true);
        if (NoIncidencia <> '') and (StrPos(Txt, LowerCase(NoIncidencia)) > 0) then
            if (CopyStr(Txt, 1, 14) = 'cierreincidenc') or (CopyStr(Txt, 1, 6) = 'cierre') then
                exit(true);
        exit(false);
    end;

    local procedure DebePreservarDescripcionIncidencia(Description: Text; NoIncidencia: Code[20]): Boolean
    begin
        exit(EsTextoPlaceholderCierreIncidencia(Description, NoIncidencia));
    end;

    local procedure AplicarClaseHistorico(var Incidencia: Record Incidencias; Clase: Text)
    begin
        case LowerCase(Clase) of
            'peticion':
                begin
                    Incidencia.SetRange("Es Peticion", true);
                    Incidencia.SetRange("Tipo Intervención", Incidencia."Tipo Intervención"::Correctivo);
                end;
            'incidencia':
                begin
                    Incidencia.SetRange("Es Peticion", false);
                    Incidencia.SetRange("Tipo Intervención", Incidencia."Tipo Intervención"::Correctivo);
                end;
            'mantenimiento':
                Incidencia.SetRange("Tipo Intervención", Incidencia."Tipo Intervención"::Preventivo);
        end;
    end;

    local procedure BuscarNoIncidenciaMantenimientoAbierta(Emplaz: Record Emplazamientos): Code[20]
    var
        Incidencia: Record Incidencias;
        Resource: Record Resource;
    begin
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then begin
            Incidencia.SetRange(Recurso, Emplaz."Nº Emplazamiento");
            Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Parada);
            Incidencia.SetRange("SubTipo Incidencia", Incidencia."SubTipo Incidencia"::Mantenimiento);
            Incidencia.SetFilter(Estado, '<>%1', Incidencia.Estado::Cerrada);
            if Incidencia.FindFirst() then
                exit(Incidencia."No.");
            exit('');
        end;

        Resource.SetRange("Nº Emplazamiento", Emplaz."Nº Emplazamiento");
        if Resource.FindSet() then
            repeat
                Incidencia.Reset();
                Incidencia.SetRange(Recurso, Resource."No.");
                Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Recurso);
                Incidencia.SetRange("SubTipo Incidencia", Incidencia."SubTipo Incidencia"::Mantenimiento);
                Incidencia.SetFilter(Estado, '<>%1', Incidencia.Estado::Cerrada);
                if Incidencia.FindFirst() then
                    exit(Incidencia."No.");
            until Resource.Next() = 0;
        exit('');
    end;

    local procedure CrearMantenimientoOpis(var Emplaz: Record Emplazamientos): Code[20]
    var
        Incidencia: Record Incidencias;
        TipoParte: Option " ",Trabajo,Nacional,EMT;
        Resource: Record Resource;
    begin
        Resource.Init();
        AsegurarFechaProximoMantenimientoDesdeZona(Emplaz, Resource);
        Incidencia.Init();
        Incidencia."Es Peticion" := true;
        Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Parada;
        Incidencia.Recurso := Emplaz."Nº Emplazamiento";
        Incidencia."Tipo Incidencia" := Incidencia."Tipo Incidencia"::"Incidencias EMT";
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Mantenimiento;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Preventivo;
        Incidencia."User Task Group" := 'EMT';
        Incidencia."FechaHora" := CurrentDateTime();
        Incidencia.Descripción := CopyStr('Mantenimiento programado ' + Emplaz."Descripción", 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        TipoParte := TipoParte::EMT;
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        FinalizarAltaMantenimiento(Emplaz, Incidencia);
        exit(Incidencia."No.");
    end;

    local procedure CrearMantenimientoRecurso(var Emplaz: Record Emplazamientos; TipoIncidencia: Enum "Tipo Incidencia"): Code[20]
    var
        Incidencia: Record Incidencias;
        Resource: Record Resource;
        TipoParte: Option " ",Trabajo,Nacional,EMT;
        NRecurso: Code[20];
    begin
        NRecurso := ObtenerRecursoPrincipalEmplazamiento(Emplaz);
        if NRecurso = '' then
            exit('');

        Resource.Get(NRecurso);
        AsegurarFechaProximoMantenimientoDesdeZona(Emplaz, Resource);

        Incidencia.Init();
        Incidencia."Es Peticion" := true;
        Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Recurso;
        Incidencia.Recurso := NRecurso;
        Incidencia."Tipo Incidencia" := TipoIncidencia;
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Mantenimiento;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Preventivo;
        Incidencia."User Task Group" := 'MTO';
        Incidencia."FechaHora" := CurrentDateTime();
        Incidencia.Descripción := CopyStr('Mantenimiento programado ' + Emplaz."Descripción", 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        TipoParte := TipoParte::Trabajo;
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        FinalizarAltaMantenimiento(Emplaz, Incidencia);
        exit(Incidencia."No.");
    end;

    local procedure FinalizarAltaMantenimiento(var Emplaz: Record Emplazamientos; var Incidencia: Record Incidencias)
    var
        IdTarea: Text;
    begin
        if Incidencia."Id Tarea Gtask" = '' then begin
            IdTarea := CrearTareaIncidencia(Incidencia);
            if StrLen(IdTarea) <= 30 then begin
                Incidencia.Get(Incidencia."No.");
                Incidencia."Id Tarea Gtask" := IdTarea;
                Incidencia.Modify(false);
            end;
        end;
        Emplaz."Bajo Mantenimiento" := true;
        Emplaz.Modify(true);
        EnlazarParteOrdenOperario(Incidencia);
    end;

    /// <summary>
    /// Deja el parte listo para ordenes.malla.es: tarea GTask, IdQr OT-..., cabecera con Tarea y Estado Abierto.
    /// </summary>
    local procedure EnlazarParteOrdenOperario(var Incidencia: Record Incidencias)
    var
        UserTask: Record "User Task";
        TimeSheetHeader: Record "Time Sheet Header";
        Modificado: Boolean;
    begin
        if Incidencia."No." = '' then
            exit;
        Incidencia.Get(Incidencia."No.");
        if Incidencia."Parte Trabajo" = '' then
            exit;

        LigarTareaConOrden(Incidencia);
        Incidencia.Get(Incidencia."No.");
        if not BuscarTareaDeIncidencia(Incidencia, UserTask) then
            exit;
        if not TimeSheetHeader.Get(Incidencia."Parte Trabajo") then
            exit;

        Modificado := false;
        if TimeSheetHeader.Tarea <> UserTask.ID then begin
            TimeSheetHeader.Tarea := UserTask.ID;
            Modificado := true;
        end;
        if TimeSheetHeader.Estado <> TimeSheetHeader.Estado::Abierto then begin
            TimeSheetHeader.Estado := TimeSheetHeader.Estado::Abierto;
            Modificado := true;
        end;
        if Modificado then
            TimeSheetHeader.Modify(true);
    end;

    local procedure AsignarResponsablesTareaMantenimiento(
        Incidencia: Record Incidencias;
        var UserTask: Record "User Task";
        RecRef: RecordRef;
        var EmailResponsable: Text[250];
        var EmailSupervisor: Text[250];
        var ListadeCorreos: Text): Boolean
    var
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        ZonasLimpieza: Record "Zonas Limpieza";
        User: Record User;
        Responsable: Guid;
        Supervisor: Guid;
        Categoria: Text;
        Departamento: Text;
        Servicio: Text;
        TipoTarea: Text;
        TipoRecurso: Code[20];
        ZonaMantenimiento: Integer;
    begin
        if not ObtenerEmplazamientoDesdeIncidencia(Incidencia, Emplaz, TipoRecurso) then
            exit(false);
        if Incidencia."Tipo Elemento" = Incidencia."Tipo Elemento"::Recurso then
            if not Resource.Get(Incidencia.Recurso) then
                Resource.Init();

        ZonaMantenimiento := ResolverZonaMantenimiento(Emplaz, Resource);
        if ZonaMantenimiento = 0 then
            exit(false);
        if not ZonasLimpieza.Get(ZonaMantenimiento) then
            exit(false);

        TipoTarea := Incidencia."User Task Group";
        if TipoTarea = '' then
            if Incidencia."Tipo Elemento" = Incidencia."Tipo Elemento"::Parada then
                TipoTarea := 'EMT'
            else
                TipoTarea := 'MTO';

        Procesos_GTask.DevuelveCategoriaSupervisorResponsablePorZona(
            TipoTarea, ZonaMantenimiento, Responsable, Supervisor, Categoria, Departamento, Servicio,
            EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos, RecRef);

        UserTask."Assigned To" := Responsable;
        UserTask."Supervisor" := Supervisor;
        UserTask."User Task Group Assigned To" := Categoria;
        UserTask.Departamento := Departamento;
        UserTask.Servicio := Servicio;
        UserTask.ZonaLimpieza := ZonaMantenimiento;
        UserTask.TipoTarea := TipoTarea;
        if (Resource."No." <> '') and (Resource."Zona Mantenimiento" = ZonaMantenimiento) then
            AsignarObjetivoRecurso(UserTask, Resource, ZonaMantenimiento)
        else
            AsignarObjetivoEmplazamiento(UserTask, Emplaz, ZonaMantenimiento);
        exit(true);
    end;

    local procedure ResolverZonaMantenimiento(Emplaz: Record Emplazamientos; Resource: Record Resource): Integer
    begin
        if (Resource."No." <> '') and (Resource."Zona Mantenimiento" <> 0) then
            exit(Resource."Zona Mantenimiento");
        exit(Emplaz."Zona Mantenimiento");
    end;

    local procedure TienePeriodicidadMantenimientoFicha(Emplaz: Record Emplazamientos; Resource: Record Resource): Boolean
    begin
        if (Resource."No." <> '') and (Format(Resource."Periodicidad Mantenimiento") <> '') then
            exit(true);
        exit(Format(Emplaz."Periodicidad Mantenimiento") <> '');
    end;

    local procedure CalcularProximoMantenimientoDesdeZona(Emplaz: Record Emplazamientos; Resource: Record Resource; FechaBase: Date): Date
    var
        UserTask: Record "User Task";
        ZonasLimpieza: Record "Zonas Limpieza";
        ZonaId: Integer;
    begin
        if TienePeriodicidadMantenimientoFicha(Emplaz, Resource) then
            exit(0D);

        ZonaId := ResolverZonaMantenimiento(Emplaz, Resource);
        if ZonaId = 0 then
            exit(0D);
        if not ZonasLimpieza.Get(ZonaId) then
            exit(0D);
        if FechaBase = 0D then
            FechaBase := WorkDate();
        exit(UserTask.CalcularProximoDiaLimpieza(ZonasLimpieza, FechaBase));
    end;

    local procedure AsegurarFechaProximoMantenimientoDesdeZona(var Emplaz: Record Emplazamientos; var Resource: Record Resource)
    var
        ProximaFecha: Date;
        FechaBase: Date;
    begin
        if TienePeriodicidadMantenimientoFicha(Emplaz, Resource) then
            exit;

        FechaBase := Emplaz."Último Mantenimiento";
        if FechaBase = 0D then
            FechaBase := WorkDate();

        if Emplaz."Fecha Próximo Mantenimiento" = 0D then begin
            ProximaFecha := CalcularProximoMantenimientoDesdeZona(Emplaz, Resource, FechaBase);
            if ProximaFecha <> 0D then begin
                Emplaz."Fecha Próximo Mantenimiento" := ProximaFecha;
                Emplaz.Modify(true);
            end;
        end;

        if (Resource."No." <> '') and (Resource."Fecha Próximo Mantenimiento" = 0D) then begin
            ProximaFecha := CalcularProximoMantenimientoDesdeZona(Emplaz, Resource, FechaBase);
            if ProximaFecha <> 0D then begin
                Resource."Fecha Próximo Mantenimiento" := ProximaFecha;
                Resource.Modify(true);
            end;
        end;
    end;

    local procedure ActualizarProximoMantenimientoDesdeZona(var Emplaz: Record Emplazamientos; var Resource: Record Resource; FechaUltimo: Date)
    var
        ProximaFecha: Date;
    begin
        ProximaFecha := CalcularProximoMantenimientoDesdeZona(Emplaz, Resource, FechaUltimo);
        if ProximaFecha = 0D then
            exit;

        Emplaz."Último Mantenimiento" := FechaUltimo;
        Emplaz."Fecha Próximo Mantenimiento" := ProximaFecha;
        Emplaz."Bajo Mantenimiento" := false;
        Emplaz.Modify(true);

        if Resource."No." <> '' then begin
            Resource."Último Mantenimiento" := FechaUltimo;
            Resource."Fecha Próximo Mantenimiento" := ProximaFecha;
            Resource."Bajo Mantenimiento" := false;
            Resource.Modify(true);
        end;
    end;

    local procedure ObtenerPeriodicidadMantenimiento(Emplaz: Record Emplazamientos; Resource: Record Resource): DateFormula
    var
        Empty: DateFormula;
    begin
        if (Resource."No." <> '') and (Format(Resource."Periodicidad Mantenimiento") <> '') then
            exit(Resource."Periodicidad Mantenimiento");
        if Format(Emplaz."Periodicidad Mantenimiento") <> '' then
            exit(Emplaz."Periodicidad Mantenimiento");
        exit(Empty);
    end;

    procedure AsignarZonaMantenimientoEmplazamientos(var Emplazamientos: Record Emplazamientos): Integer
    var
        ZonasLimpieza: Record "Zonas Limpieza";
        Emplaz: Record Emplazamientos;
        Actualizados: Integer;
    begin
        if not SeleccionarZonaMantenimiento(ZonasLimpieza) then
            exit(0);

        Emplaz.CopyFilters(Emplazamientos);
        if not Emplaz.FindSet(true) then
            Error('No hay paradas seleccionadas.');

        if not Confirm(StrSubstNo('¿Asignar la zona de mantenimiento "%1" a %2 parada(s)?', ZonasLimpieza.Descripción, Emplaz.Count()), false) then
            exit(0);

        repeat
            Emplaz.Validate("Zona Mantenimiento", ZonasLimpieza.Id);
            Emplaz.Modify(true);
            Actualizados += 1;
        until Emplaz.Next() = 0;

        Message('Zona mantenimiento "%1" asignada a %2 parada(s).', ZonasLimpieza.Descripción, Actualizados);
        exit(Actualizados);
    end;

    procedure AsignarZonaMantenimientoRecursos(var Resource: Record Resource): Integer
    var
        ZonasLimpieza: Record "Zonas Limpieza";
        Recurso: Record Resource;
        Actualizados: Integer;
    begin
        if not SeleccionarZonaMantenimiento(ZonasLimpieza) then
            exit(0);

        Recurso.CopyFilters(Resource);
        if not Recurso.FindSet(true) then
            Error('No hay recursos seleccionados.');

        if not Confirm(StrSubstNo('¿Asignar la zona de mantenimiento "%1" a %2 recurso(s)?', ZonasLimpieza.Descripción, Recurso.Count()), false) then
            exit(0);

        repeat
            Recurso.Validate("Zona Mantenimiento", ZonasLimpieza.Id);
            Recurso.Modify(true);
            Actualizados += 1;
        until Recurso.Next() = 0;

        Message('Zona mantenimiento "%1" asignada a %2 recurso(s).', ZonasLimpieza.Descripción, Actualizados);
        exit(Actualizados);
    end;

    local procedure SeleccionarZonaMantenimiento(var ZonasLimpieza: Record "Zonas Limpieza"): Boolean
    begin
        ZonasLimpieza.Reset();
        exit(Page.RunModal(Page::"Zonas Limpieza", ZonasLimpieza) = Action::LookupOK);
    end;

    /// <summary>
    /// En servicios web OData suele publicarse solo este procedure; accionOData en JSON enruta al resto.
    /// </summary>
    local procedure EnrutarProcedureMantenimientoOData(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        Accion: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            exit('');
        if JsonIn.Get('accionOData', JsonToken) then
            Accion := LowerCase(DelChr(JsonToken.AsValue().AsText(), '<>', ' '));
        case Accion of
            'postcreardosier':
                exit(PostCrearDosier(JsonText));
            'listadodosieres':
                exit(ListadoDosieres(JsonText));
            'detalledosier':
                exit(DetalleDosier(JsonText));
            'postadjuntodosier':
                exit(PostAdjuntoDosier(JsonText));
            'permisosdosier':
                exit(PermisosDosier(JsonText));
            'postcrearordendosier':
                exit(PostCrearOrdenDosier(JsonText));
            'postcrearordenmantenimiento':
                exit(PostCrearOrdenMantenimiento(JsonText));
            'postactualizarmantenimiento':
                exit(PostActualizarMantenimiento(JsonText));
            'detallemantenimientoemplaz':
                exit(DetalleMantenimientoEmplaz(JsonText));
            'detallemantenimientorecurso':
                exit(DetalleMantenimientoRecurso(JsonText));
            'historialmantenimiento':
                exit(HistorialMantenimiento(JsonText));
            'listadomantenimientorecurso':
                exit(ListadoMantenimientoRecurso(JsonText));
        end;
        if JsonIn.Get('puntual', JsonToken) then
            exit(PostCrearOrdenMantenimiento(JsonText));
        if JsonIn.Get('limite', JsonToken) then
            if JsonIn.Get('codigo', JsonToken) then
                exit(HistorialMantenimiento(JsonText));
        if JsonIn.Get('noEmplazamiento', JsonToken) then
            exit(DetalleMantenimientoEmplaz(JsonText));
        if JsonIn.Get('noRecurso', JsonToken) then
            exit(DetalleMantenimientoRecurso(JsonText));
        if JsonIn.Get('fechaProximoMantenimiento', JsonToken) then
            if JsonIn.Get('codigo', JsonToken) then
                exit(PostActualizarMantenimiento(JsonText));
        exit('');
    end;

    /// <summary>
    /// Listado de actuaciones de mantenimiento previstas (emplazamientos) para GMalla.
    /// JSON entrada: { "desde":"YYYY-MM-DD", "hasta":"YYYY-MM-DD", "tipoEmplazamiento":"Opis|Vallas|Otros" (opcional) }
    /// Salida: { "value": [ { "tipo_emplazamiento", "no_emplazamiento", ... } ] }
    /// </summary>
    [ServiceEnabled]
    procedure ListadoMantenimientoEmplaz(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        JsonArray: JsonArray;
        JsonLinea: JsonObject;
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        EmplCu: Codeunit Emplazamientos;
        Desde: Date;
        Hasta: Date;
        TipoEmplazTxt: Text;
        TipoEmplaz: Enum "Tipo Emplazamiento";
        TipoEmplazFiltro: Boolean;
        IncluirSinFecha: Boolean;
        Txt: Text;
        PeriodicidadTxt: Text;
        TiposRecursoTxt: Text;
    begin
        Txt := EnrutarProcedureMantenimientoOData(JsonText);
        if Txt <> '' then
            exit(Txt);

        Desde := 0D;
        Hasta := 99991231D;
        if JsonIn.ReadFrom(JsonText) then begin
            if JsonIn.Get('desde', JsonToken) then
                if not Evaluate(Desde, JsonToken.AsValue().AsText()) then
                    Desde := 0D;
            if JsonIn.Get('hasta', JsonToken) then
                if not Evaluate(Hasta, JsonToken.AsValue().AsText()) then
                    Hasta := 99991231D;
            if JsonIn.Get('tipoEmplazamiento', JsonToken) then
                TipoEmplazTxt := JsonToken.AsValue().AsText();
            if JsonIn.Get('incluirSinFecha', JsonToken) then
                IncluirSinFecha := JsonToken.AsValue().AsBoolean();
            if JsonIn.Get('tipoListado', JsonToken) then
                if LowerCase(JsonToken.AsValue().AsText()) in ['recurso', 'recursos'] then
                    exit(ListadoMantenimientoRecurso(JsonText));
        end;

        Clear(JsonArray);
        if not IncluirSinFecha then
            Emplaz.SetFilter("Fecha Próximo Mantenimiento", '<>%1', 0D);
        if (Desde <> 0D) and (Hasta <> 99991231D) then
            Emplaz.SetRange("Fecha Próximo Mantenimiento", Desde, Hasta)
        else
            if Desde <> 0D then
                Emplaz.SetFilter("Fecha Próximo Mantenimiento", '>=%1', Desde)
            else
                if Hasta <> 99991231D then
                    Emplaz.SetFilter("Fecha Próximo Mantenimiento", '..%1', Hasta);
        TipoEmplazFiltro := TipoEmplazTxt <> '';
        if TipoEmplazFiltro then begin
            case LowerCase(TipoEmplazTxt) of
                'opis':
                    Emplaz.SetRange("Tipo Emplazamiento", Emplaz."Tipo Emplazamiento"::Opis);
                'vallas':
                    Emplaz.SetRange("Tipo Emplazamiento", Emplaz."Tipo Emplazamiento"::Vallas);
                'otros':
                    Emplaz.SetRange("Tipo Emplazamiento", Emplaz."Tipo Emplazamiento"::"Otros");
            end;
        end;

        if Emplaz.FindSet() then
            repeat
                Clear(JsonLinea);
                TipoEmplaz := Emplaz."Tipo Emplazamiento";
                JsonLinea.Add('tipo_emplazamiento', Format(TipoEmplaz));
                JsonLinea.Add('no_emplazamiento', Emplaz."Nº Emplazamiento");
                JsonLinea.Add('descripcion', Emplaz."Descripción");
                JsonLinea.Add('ubicacion', Emplaz."Ubicación");
                JsonLinea.Add('municipio', Emplaz."Municipio emplazamiento");
                JsonLinea.Add('zona', Emplaz.Zona);
                JsonLinea.Add('fecha_proximo_mantenimiento', Emplaz."Fecha Próximo Mantenimiento");
                JsonLinea.Add('bajo_mantenimiento', Emplaz."Bajo Mantenimiento");
                JsonLinea.Add('ultimo_mantenimiento', Emplaz."Último Mantenimiento");
                Resource.Init();
                PeriodicidadTxt := Format(ObtenerPeriodicidadMantenimiento(Emplaz, Resource));
                JsonLinea.Add('periodicidad', PeriodicidadTxt);
                TiposRecursoTxt := EmplCu.ObtenerTiposRecursoEmplazamiento(Emplaz."Nº Emplazamiento");
                JsonLinea.Add('tipos_recurso', TiposRecursoTxt);
                JsonArray.Add(JsonLinea);
            until Emplaz.Next() = 0;

        Clear(JsonRoot);
        JsonRoot.Add('value', JsonArray.AsToken());
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    /// <summary>
    /// Listado de actuaciones de mantenimiento previstas (recursos) para GMalla.
    /// JSON entrada: { "desde":"YYYY-MM-DD", "hasta":"YYYY-MM-DD", "tipoRecurso":"..." (opcional) }
    /// Salida: { "value": [ { "tipo_recurso", "no_recurso", ... } ] }
    /// Publicar en la misma OData que ListadoMantenimientoEmplaz (procedure distinto).
    /// </summary>
    [ServiceEnabled]
    procedure ListadoMantenimientoRecurso(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        JsonArray: JsonArray;
        JsonLinea: JsonObject;
        Resource: Record Resource;
        Emplaz: Record Emplazamientos;
        Desde: Date;
        Hasta: Date;
        TipoRecursoTxt: Text;
        TipoRecursoFiltro: Boolean;
        Txt: Text;
        PeriodicidadTxt: Text;
        FechaProx: Date;
        BajoMto: Boolean;
        UltimoMto: Date;
        IncluirSinFecha: Boolean;
    begin
        Desde := 0D;
        Hasta := 99991231D;
        if JsonIn.ReadFrom(JsonText) then begin
            if JsonIn.Get('desde', JsonToken) then
                if not Evaluate(Desde, JsonToken.AsValue().AsText()) then
                    Desde := 0D;
            if JsonIn.Get('hasta', JsonToken) then
                if not Evaluate(Hasta, JsonToken.AsValue().AsText()) then
                    Hasta := 99991231D;
            if JsonIn.Get('tipoRecurso', JsonToken) then
                TipoRecursoTxt := JsonToken.AsValue().AsText();
            if JsonIn.Get('incluirSinFecha', JsonToken) then
                IncluirSinFecha := JsonToken.AsValue().AsBoolean();
        end;
        TipoRecursoFiltro := TipoRecursoTxt <> '';

        Clear(JsonArray);
        Resource.SetRange(Blocked, false);
        if Resource.FindSet() then
            repeat
                FechaProx := FechaProximoMantenimientoRecurso(Resource, Emplaz);
                if (not IncluirSinFecha) and (FechaProx = 0D) then
                    continue;
                if (Desde <> 0D) and (Hasta <> 99991231D) then begin
                    if (FechaProx < Desde) or (FechaProx > Hasta) then
                        continue;
                end else
                    if Desde <> 0D then begin
                        if FechaProx < Desde then
                            continue;
                    end else
                        if (Hasta <> 99991231D) and (FechaProx > Hasta) then
                            continue;
                if TipoRecursoFiltro and (Resource."Tipo Recurso" <> TipoRecursoTxt) then
                    continue;

                BajoMto := BajoMantenimientoRecurso(Resource, Emplaz);
                UltimoMto := UltimoMantenimientoRecurso(Resource, Emplaz);
                Clear(Emplaz);
                TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz);
                PeriodicidadTxt := Format(ObtenerPeriodicidadMantenimiento(Emplaz, Resource));

                Clear(JsonLinea);
                JsonLinea.Add('tipo_recurso', Resource."Tipo Recurso");
                JsonLinea.Add('no_recurso', Resource."No.");
                JsonLinea.Add('descripcion', Resource.Name);
                JsonLinea.Add('ubicacion', Resource.Ubicación);
                JsonLinea.Add('municipio', Resource.Municipio);
                JsonLinea.Add('zona', Resource.Zona);
                JsonLinea.Add('no_emplazamiento', Resource."Nº Emplazamiento");
                JsonLinea.Add('fecha_proximo_mantenimiento', FechaProx);
                JsonLinea.Add('bajo_mantenimiento', BajoMto);
                JsonLinea.Add('ultimo_mantenimiento', UltimoMto);
                JsonLinea.Add('periodicidad', PeriodicidadTxt);
                JsonArray.Add(JsonLinea);
            until Resource.Next() = 0;

        Clear(JsonRoot);
        JsonRoot.Add('value', JsonArray.AsToken());
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure TryGetEmplazamientoRecurso(NEmplaz: Code[20]; var Emplaz: Record Emplazamientos): Boolean
    begin
        if NEmplaz = '' then
            exit(false);
        Emplaz.Reset();
        Emplaz.SetRange("Nº Emplazamiento", NEmplaz);
        exit(Emplaz.FindFirst());
    end;

    local procedure FechaProximoMantenimientoRecurso(Resource: Record Resource; var Emplaz: Record Emplazamientos): Date
    begin
        if Resource."Fecha Próximo Mantenimiento" <> 0D then
            exit(Resource."Fecha Próximo Mantenimiento");
        if TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then
            exit(Emplaz."Fecha Próximo Mantenimiento");
        exit(0D);
    end;

    local procedure BajoMantenimientoRecurso(Resource: Record Resource; var Emplaz: Record Emplazamientos): Boolean
    begin
        if Resource."Bajo Mantenimiento" then
            exit(true);
        if TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then
            exit(Emplaz."Bajo Mantenimiento");
        exit(false);
    end;

    local procedure UltimoMantenimientoRecurso(Resource: Record Resource; var Emplaz: Record Emplazamientos): Date
    begin
        if Resource."Último Mantenimiento" <> 0D then
            exit(Resource."Último Mantenimiento");
        if TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then
            exit(Emplaz."Último Mantenimiento");
        exit(0D);
    end;

    /// <summary>
    /// Detalle de mantenimiento de un emplazamiento (parada, valla, mobiliario).
    /// JSON: { "tipoEmplazamiento":"Opis|Vallas|Otros", "noEmplazamiento":"..." }
    /// </summary>
    [ServiceEnabled]
    procedure DetalleMantenimientoEmplaz(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        JsonRecursos: JsonArray;
        JsonLinea: JsonObject;
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        EmplCu: Codeunit Emplazamientos;
        TipoEmplazTxt: Text;
        NEmplaz: Code[20];
        Txt: Text;
        PeriodicidadTxt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido');

        if JsonIn.Get('noEmplazamiento', JsonToken) then
            NEmplaz := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NEmplaz));
        if NEmplaz = '' then
            Error('Falta noEmplazamiento');

        if JsonIn.Get('tipoEmplazamiento', JsonToken) then
            TipoEmplazTxt := JsonToken.AsValue().AsText();

        if not BuscarEmplazamientoPorTipoONo(TipoEmplazTxt, NEmplaz, Emplaz) then
            Error('Emplazamiento no encontrado: %1', NEmplaz);

        Clear(JsonRoot);
        JsonRoot.Add('tipo_emplazamiento', Format(Emplaz."Tipo Emplazamiento"));
        JsonRoot.Add('no_emplazamiento', Emplaz."Nº Emplazamiento");
        JsonRoot.Add('descripcion', Emplaz."Descripción");
        JsonRoot.Add('ubicacion', Emplaz."Ubicación");
        JsonRoot.Add('municipio', Emplaz."Municipio emplazamiento");
        JsonRoot.Add('zona', Emplaz.Zona);
        JsonRoot.Add('fecha_proximo_mantenimiento', Emplaz."Fecha Próximo Mantenimiento");
        JsonRoot.Add('ultimo_mantenimiento', Emplaz."Último Mantenimiento");
        JsonRoot.Add('bajo_mantenimiento', Emplaz."Bajo Mantenimiento");
        Resource.Init();
        PeriodicidadTxt := Format(ObtenerPeriodicidadMantenimiento(Emplaz, Resource));
        JsonRoot.Add('periodicidad', PeriodicidadTxt);
        JsonRoot.Add('periodicidad_invierno', Format(Emplaz."Periodicidad Mant. Invierno"));
        JsonRoot.Add('zona_mantenimiento', Emplaz."Zona Mantenimiento");
        JsonRoot.Add('tipos_recurso', EmplCu.ObtenerTiposRecursoEmplazamiento(Emplaz."Nº Emplazamiento"));
        JsonRoot.Add('punto_x', Emplaz.PuntoX);
        JsonRoot.Add('punto_y', Emplaz.PuntoY);

        Clear(JsonRecursos);
        Resource.SetRange("Nº Emplazamiento", Emplaz."Nº Emplazamiento");
        Resource.SetRange(Blocked, false);
        if Resource.FindSet() then
            repeat
                Clear(JsonLinea);
                JsonLinea.Add('no_recurso', Resource."No.");
                JsonLinea.Add('descripcion', Resource.Name);
                JsonLinea.Add('tipo_recurso', Resource."Tipo Recurso");
                JsonLinea.Add('fecha_proximo_mantenimiento', Resource."Fecha Próximo Mantenimiento");
                JsonLinea.Add('ultimo_mantenimiento', Resource."Último Mantenimiento");
                JsonLinea.Add('bajo_mantenimiento', Resource."Bajo Mantenimiento");
                JsonLinea.Add('periodicidad', Format(Resource."Periodicidad Mantenimiento"));
                JsonRecursos.Add(JsonLinea);
            until Resource.Next() = 0;
        JsonRoot.Add('recursos', JsonRecursos.AsToken());

        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    /// <summary>
    /// Detalle de mantenimiento de un recurso.
    /// JSON: { "noRecurso":"..." }
    /// </summary>
    [ServiceEnabled]
    procedure DetalleMantenimientoRecurso(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        JsonEmplaz: JsonObject;
        Resource: Record Resource;
        Emplaz: Record Emplazamientos;
        NRecurso: Code[20];
        Txt: Text;
        PeriodicidadTxt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido');
        if JsonIn.Get('noRecurso', JsonToken) then
            NRecurso := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NRecurso));
        if NRecurso = '' then
            Error('Falta noRecurso');
        if not Resource.Get(NRecurso) then
            Error('Recurso no encontrado: %1', NRecurso);

        Clear(JsonRoot);
        JsonRoot.Add('no_recurso', Resource."No.");
        JsonRoot.Add('descripcion', Resource.Name);
        JsonRoot.Add('tipo_recurso', Resource."Tipo Recurso");
        JsonRoot.Add('ubicacion', Resource.Ubicación);
        JsonRoot.Add('municipio', Resource.Municipio);
        JsonRoot.Add('zona', Resource.Zona);
        JsonRoot.Add('no_emplazamiento', Resource."Nº Emplazamiento");
        JsonRoot.Add('fecha_proximo_mantenimiento', Resource."Fecha Próximo Mantenimiento");
        JsonRoot.Add('ultimo_mantenimiento', Resource."Último Mantenimiento");
        JsonRoot.Add('bajo_mantenimiento', Resource."Bajo Mantenimiento");
        PeriodicidadTxt := Format(Resource."Periodicidad Mantenimiento");
        if PeriodicidadTxt = '' then begin
            Clear(Emplaz);
            if TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then
                PeriodicidadTxt := Format(ObtenerPeriodicidadMantenimiento(Emplaz, Resource));
        end;
        JsonRoot.Add('periodicidad', PeriodicidadTxt);
        JsonRoot.Add('zona_mantenimiento', Resource."Zona Mantenimiento");
        JsonRoot.Add('punto_x', Resource.PuntoX);
        JsonRoot.Add('punto_y', Resource.PuntoY);

        Clear(JsonEmplaz);
        if TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then begin
            JsonEmplaz.Add('tipo_emplazamiento', Format(Emplaz."Tipo Emplazamiento"));
            JsonEmplaz.Add('no_emplazamiento', Emplaz."Nº Emplazamiento");
            JsonEmplaz.Add('descripcion', Emplaz."Descripción");
            JsonEmplaz.Add('ubicacion', Emplaz."Ubicación");
        end;
        JsonRoot.Add('emplazamiento', JsonEmplaz.AsToken());

        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    /// <summary>
    /// Historial de incidencias de mantenimiento para emplazamiento o recurso.
    /// JSON: { "tipo":"emplaz|recurso", "tipoEmplazamiento":"...", "codigo":"...", "limite":50 }
    /// </summary>
    [ServiceEnabled]
    procedure HistorialMantenimiento(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        JsonFormater: Codeunit "Json Text Reader/Writer";
        Incidencias: Record Incidencias;
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        TipoTxt: Text;
        TipoEmplazTxt: Text;
        Codigo: Code[20];
        Limite: Integer;
        Contador: Integer;
        Txt: Text;
    begin
        Limite := 50;
        if JsonIn.ReadFrom(JsonText) then begin
            if JsonIn.Get('tipo', JsonToken) then
                TipoTxt := LowerCase(JsonToken.AsValue().AsText());
            if JsonIn.Get('tipoEmplazamiento', JsonToken) then
                TipoEmplazTxt := JsonToken.AsValue().AsText();
            if JsonIn.Get('codigo', JsonToken) then
                Codigo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Codigo));
            if JsonIn.Get('limite', JsonToken) then
                Limite := JsonToken.AsValue().AsInteger();
        end;
        if Codigo = '' then
            Error('Falta codigo');
        if Limite <= 0 then
            Limite := 50;
        if Limite > 200 then
            Limite := 200;

        Clear(JsonFormater);
        JsonFormater.WriteStartObject('');
        JsonFormater.WriteStartArray('value');

        Incidencias.Reset();
        Incidencias.SetRange("SubTipo Incidencia", Incidencias."SubTipo Incidencia"::Mantenimiento);
        Incidencias.SetRange("Tipo Intervención", Incidencias."Tipo Intervención"::Preventivo);
        Contador := 0;

        if TipoTxt = 'recurso' then begin
            Incidencias.SetRange("Tipo Elemento", Incidencias."Tipo Elemento"::Recurso);
            Incidencias.SetRange(Recurso, Codigo);
            if Incidencias.FindSet() then
                repeat
                    Procesos_GTask.EscribirIncidenciaHistorial(Incidencias, JsonFormater);
                    Contador += 1;
                until (Incidencias.Next() = 0) or (Contador >= Limite);
        end else begin
            if not BuscarEmplazamientoPorTipoONo(TipoEmplazTxt, Codigo, Emplaz) then
                Error('Emplazamiento no encontrado: %1', Codigo);

            if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then begin
                Incidencias.SetRange("Tipo Elemento", Incidencias."Tipo Elemento"::Parada);
                Incidencias.SetRange(Recurso, Emplaz."Nº Emplazamiento");
                if Incidencias.FindSet() then
                    repeat
                        Procesos_GTask.EscribirIncidenciaHistorial(Incidencias, JsonFormater);
                        Contador += 1;
                    until (Incidencias.Next() = 0) or (Contador >= Limite);
            end else begin
                Resource.SetRange("Nº Emplazamiento", Emplaz."Nº Emplazamiento");
                if Resource.FindSet() then
                    repeat
                        Incidencias.Reset();
                        Incidencias.SetRange("SubTipo Incidencia", Incidencias."SubTipo Incidencia"::Mantenimiento);
                        Incidencias.SetRange("Tipo Intervención", Incidencias."Tipo Intervención"::Preventivo);
                        Incidencias.SetRange("Tipo Elemento", Incidencias."Tipo Elemento"::Recurso);
                        Incidencias.SetRange(Recurso, Resource."No.");
                        if Incidencias.FindSet() then
                            repeat
                                Procesos_GTask.EscribirIncidenciaHistorial(Incidencias, JsonFormater);
                                Contador += 1;
                            until (Incidencias.Next() = 0) or (Contador >= Limite);
                    until (Resource.Next() = 0) or (Contador >= Limite);
            end;
        end;

        JsonFormater.WriteEndArray();
        JsonFormater.WriteEndObject();
        Txt := JsonFormater.GetJSonAsText();
        exit(Txt);
    end;

    /// <summary>
    /// Actualiza datos de mantenimiento en emplazamiento o recurso.
    /// JSON: { "tipo":"emplaz|recurso", "tipoEmplazamiento":"...", "codigo":"...",
    ///         "fechaProximoMantenimiento":"YYYY-MM-DD", "periodicidad":"1M", "zonaMantenimiento":0 }
    /// </summary>
    [ServiceEnabled]
    procedure PostActualizarMantenimiento(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        TipoTxt: Text;
        TipoEmplazTxt: Text;
        Codigo: Code[20];
        FechaProx: Date;
        Periodicidad: DateFormula;
        ZonaMto: Integer;
        Txt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido');
        if JsonIn.Get('tipo', JsonToken) then
            TipoTxt := LowerCase(JsonToken.AsValue().AsText());
        if JsonIn.Get('tipoEmplazamiento', JsonToken) then
            TipoEmplazTxt := JsonToken.AsValue().AsText();
        if JsonIn.Get('codigo', JsonToken) then
            Codigo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Codigo));
        if Codigo = '' then
            Error('Falta codigo');

        if JsonIn.Get('fechaProximoMantenimiento', JsonToken) then
            if not Evaluate(FechaProx, JsonToken.AsValue().AsText()) then
                FechaProx := 0D;

        if TipoTxt = 'recurso' then begin
            if not Resource.Get(Codigo) then
                Error('Recurso no encontrado: %1', Codigo);
            if JsonIn.Get('fechaProximoMantenimiento', JsonToken) then
                Resource."Fecha Próximo Mantenimiento" := FechaProx;
            if JsonIn.Get('periodicidad', JsonToken) then begin
                Clear(Periodicidad);
                if JsonToken.AsValue().AsText() <> '' then
                    Evaluate(Periodicidad, JsonToken.AsValue().AsText());
                Resource."Periodicidad Mantenimiento" := Periodicidad;
            end;
            if JsonIn.Get('zonaMantenimiento', JsonToken) then begin
                ZonaMto := JsonToken.AsValue().AsInteger();
                Resource."Zona Mantenimiento" := ZonaMto;
            end;
            Resource.Modify(true);
            Clear(JsonRoot);
            JsonRoot.Add('success', true);
            JsonRoot.Add('tipo', 'recurso');
            JsonRoot.Add('codigo', Resource."No.");
            JsonRoot.Add('fecha_proximo_mantenimiento', Resource."Fecha Próximo Mantenimiento");
            JsonRoot.Add('periodicidad', Format(Resource."Periodicidad Mantenimiento"));
            JsonRoot.WriteTo(Txt);
            exit(Txt);
        end;

        if not BuscarEmplazamientoPorTipoONo(TipoEmplazTxt, Codigo, Emplaz) then
            Error('Emplazamiento no encontrado: %1', Codigo);
        if JsonIn.Get('fechaProximoMantenimiento', JsonToken) then
            Emplaz."Fecha Próximo Mantenimiento" := FechaProx;
        if JsonIn.Get('periodicidad', JsonToken) then begin
            Clear(Periodicidad);
            if JsonToken.AsValue().AsText() <> '' then
                Evaluate(Periodicidad, JsonToken.AsValue().AsText());
            Emplaz."Periodicidad Mantenimiento" := Periodicidad;
        end;
        if JsonIn.Get('periodicidadInvierno', JsonToken) then begin
            Clear(Periodicidad);
            if JsonToken.AsValue().AsText() <> '' then
                Evaluate(Periodicidad, JsonToken.AsValue().AsText());
            Emplaz."Periodicidad Mant. Invierno" := Periodicidad;
        end;
        if JsonIn.Get('zonaMantenimiento', JsonToken) then begin
            ZonaMto := JsonToken.AsValue().AsInteger();
            Emplaz."Zona Mantenimiento" := ZonaMto;
        end;
        Emplaz.Modify(true);
        Clear(JsonRoot);
        JsonRoot.Add('success', true);
        JsonRoot.Add('tipo', 'emplaz');
        JsonRoot.Add('codigo', Emplaz."Nº Emplazamiento");
        JsonRoot.Add('fecha_proximo_mantenimiento', Emplaz."Fecha Próximo Mantenimiento");
        JsonRoot.Add('periodicidad', Format(Emplaz."Periodicidad Mantenimiento"));
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure BuscarUsuarioDosier(IdGtask: Text; var Usuario: Record UsuariosGtask): Boolean
    begin
        // Los dosieres se crean en la empresa del recurso, pero los usuarios GTask solo existen en Malla Publicidad.
        Usuario.ChangeCompany('Malla Publicidad');
        Usuario.Reset();
        Usuario.SetRange("Id Gtask", CopyStr(DelChr(IdGtask, '<>', ' '), 1, MaxStrLen(Usuario."Id Gtask")));
        exit(Usuario.FindFirst());
    end;

    [ServiceEnabled]
    procedure PermisosDosier(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonOut: JsonObject;
        Usuario: Record UsuariosGtask;
        IdGtask: Text;
        Encontrado: Boolean;
        Txt: Text;
    begin
        if JsonIn.ReadFrom(JsonText) then
            if JsonIn.Get('usuarioGtask', JsonToken) then
                IdGtask := JsonToken.AsValue().AsText();
        Encontrado := BuscarUsuarioDosier(IdGtask, Usuario);
        JsonOut.Add('success', true);
        JsonOut.Add('encontrado', Encontrado);
        JsonOut.Add('puede_crear', Encontrado and Usuario."Puede crear dosieres");
        JsonOut.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure TipoIncidenciaDosierEmplazamiento(Emplaz: Record Emplazamientos): Enum "Tipo Incidencia"
    var
        TipoIncidencia: Enum "Tipo Incidencia";
    begin
        case Emplaz."Tipo Emplazamiento" of
            Emplaz."Tipo Emplazamiento"::Opis:
                exit(TipoIncidencia::"Incidencias EMT");
            Emplaz."Tipo Emplazamiento"::Vallas:
                exit(TipoIncidencia::"Incidencias Soportes");
            else
                exit(TipoIncidencia::"Incidencias Mobiliario Urbano");
        end;
    end;

    [ServiceEnabled]
    procedure PostCrearDosier(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonOut: JsonObject;
        Incidencia: Record Incidencias;
        Usuario: Record UsuariosGtask;
        Resource: Record Resource;
        Emplaz: Record Emplazamientos;
        TipoTxt: Text;
        Codigo: Code[20];
        Descripcion: Text;
        IdGtask: Text;
        EmpresaRecurso: Text;
        Txt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido.');
        if JsonIn.Get('tipo', JsonToken) then
            TipoTxt := LowerCase(JsonToken.AsValue().AsText());
        if JsonIn.Get('codigo', JsonToken) then
            Codigo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Codigo));
        if JsonIn.Get('descripcion', JsonToken) then
            Descripcion := JsonToken.AsValue().AsText();
        if JsonIn.Get('usuarioGtask', JsonToken) then
            IdGtask := JsonToken.AsValue().AsText();
        if JsonIn.Get('empresa', JsonToken) then
            EmpresaRecurso := JsonToken.AsValue().AsText();

        if Codigo = '' then
            Error('Falta el recurso o emplazamiento del dosier.');
        if DelChr(Descripcion, '<>', ' ') = '' then
            Error('Falta la descripción del dosier.');
        if not BuscarUsuarioDosier(IdGtask, Usuario) then
            Error('No se ha encontrado el usuario de GTask %1 en UsuariosGtask.', IdGtask);
        if IsNullGuid(Usuario."Id Usuario") then
            Error('El usuario de GTask %1 no tiene usuario de Business Central enlazado.', IdGtask);
        if not Usuario."Puede crear dosieres" then
            Error('El usuario de GTask %1 no tiene permiso para crear dosieres.', IdGtask);

        Incidencia.Init();
        Incidencia."Es Peticion" := false;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Dosier;
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Otras;
        Incidencia.Estado := Incidencia.Estado::Abierta;
        Incidencia.Fecha := Today;
        Incidencia.FechaHora := CurrentDateTime();
        Incidencia."Fecha Actuacion" := CurrentDateTime();
        Incidencia.Usuario := Usuario."Id Usuario";
        Incidencia."Usuario Seguimiento" := Usuario."Id Usuario";
        Incidencia.Descripción := CopyStr(Descripcion, 1, MaxStrLen(Incidencia.Descripción));

        if TipoTxt = 'recurso' then begin
            if not BuscarRecursoDosier(Codigo, EmpresaRecurso, Resource) then
                Error('No existe el recurso %1.', Codigo);
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Recurso;
            Incidencia.Recurso := Resource."No.";
            Incidencia."Tipo Incidencia" := Incidencia."Tipo Incidencia"::"Incidencias Soportes";
            Incidencia."User Task Group" := 'MTO';
            if Resource.CurrentCompany <> CompanyName then
                Incidencia.Empresa := CopyStr(Resource.CurrentCompany, 1, MaxStrLen(Incidencia.Empresa));
        end else begin
            if not BuscarEmplazamientoDosier(Codigo, EmpresaRecurso, Emplaz) then
                Error('No existe el emplazamiento %1.', Codigo);
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Parada;
            Incidencia.Recurso := Emplaz."Nº Emplazamiento";
            Incidencia."Tipo Incidencia" := TipoIncidenciaDosierEmplazamiento(Emplaz);
            if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then
                Incidencia."User Task Group" := 'EMT'
            else
                Incidencia."User Task Group" := 'MTO';
            if Emplaz.CurrentCompany <> CompanyName then
                Incidencia.Empresa := CopyStr(Emplaz.CurrentCompany, 1, MaxStrLen(Incidencia.Empresa));
        end;

        Incidencia.Insert(true);
        Incidencia.SetWorkDescription(Descripcion);
        Incidencia.Get(Incidencia."No.");
        CreateIncidencia(Incidencia);

        Clear(JsonOut);
        JsonOut.Add('success', true);
        JsonOut.Add('no', Incidencia."No.");
        JsonOut.Add('no_dosier', Incidencia."No.");
        if Incidencia.Empresa <> '' then
            JsonOut.Add('empresa', Incidencia.Empresa)
        else
            JsonOut.Add('empresa', CompanyName());
        JsonOut.Add('id_gtask', Incidencia.Id_Gtask);
        JsonOut.Add('mensaje', StrSubstNo('Dosier creado: %1', Incidencia."No."));
        JsonOut.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure ContarMediosDosier(Incidencia: Record Incidencias): Integer
    var
        Imagenes: Record "Imagenes Orden fijación";
        Doc: Record "Document Attachment";
    begin
        Imagenes.SetRange("Nº Orden", Incidencia."Nº Orden");
        Imagenes.SetRange("Es Incidencia", true);
        Doc.SetRange("Table ID", Database::Incidencias);
        Doc.SetRange("No.", Incidencia."No.");
        exit(Imagenes.Count() + Doc.Count());
    end;

    local procedure AgregarDosierJson(Incidencia: Record Incidencias; var JsonLinea: JsonObject)
    var
        Usuario: Record UsuariosGtask;
        NombreUsuario: Text;
    begin
        Clear(JsonLinea);
        if not IsNullGuid(Incidencia.Usuario) then begin
            Usuario.ChangeCompany('Malla Publicidad');
            Usuario.SetRange("Id Usuario", Incidencia.Usuario);
            if Usuario.FindFirst() then
                NombreUsuario := Usuario.Nombre + ' ' + Usuario.Apellido;
        end;
        JsonLinea.Add('no', Incidencia."No.");
        if Incidencia.Empresa <> '' then
            JsonLinea.Add('empresa', Incidencia.Empresa)
        else
            JsonLinea.Add('empresa', CompanyName());
        JsonLinea.Add('descripcion', Incidencia."Descripción");
        JsonLinea.Add('recurso', Incidencia.Recurso);
        JsonLinea.Add('tipo_elemento', Format(Incidencia."Tipo Elemento"));
        JsonLinea.Add('estado', Format(Incidencia.Estado));
        JsonLinea.Add('fecha', Format(Incidencia.Fecha, 0, 9));
        JsonLinea.Add('fecha_hora', Format(Incidencia.FechaHora, 0, 9));
        JsonLinea.Add('usuario', NombreUsuario);
        JsonLinea.Add('usuario_gtask', Incidencia.ID_UsuarioGtask(Incidencia.Usuario));
        JsonLinea.Add('id_gtask', Incidencia.Id_Gtask);
        JsonLinea.Add('medios', ContarMediosDosier(Incidencia));
        JsonLinea.Add('parte_trabajo', Incidencia."Parte Trabajo");
        if Incidencia."Parte Trabajo" <> '' then begin
            JsonLinea.Add('id_qr', IdQrOrdenTrabajo(Incidencia));
            JsonLinea.Add('url_ordenes', StrSubstNo('https://ordenes.malla.es/OT-%1', Incidencia."Parte Trabajo"));
        end;
    end;

    [ServiceEnabled]
    procedure ListadoDosieres(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonOut: JsonObject;
        JsonLista: JsonArray;
        JsonLinea: JsonObject;
        Incidencia: Record Incidencias;
        Usuario: Record UsuariosGtask;
        IdGtask: Text;
        SoloMios: Boolean;
        Txt: Text;
    begin
        if JsonIn.ReadFrom(JsonText) then begin
            if JsonIn.Get('usuarioGtask', JsonToken) then
                IdGtask := JsonToken.AsValue().AsText();
            if JsonIn.Get('soloMios', JsonToken) then
                SoloMios := JsonToken.AsValue().AsBoolean();
        end;
        Incidencia.SetRange("Tipo Intervención", Incidencia."Tipo Intervención"::Dosier);
        if SoloMios then begin
            if not BuscarUsuarioDosier(IdGtask, Usuario) then
                Error('No se ha encontrado el usuario de GTask %1.', IdGtask);
            Incidencia.SetRange(Usuario, Usuario."Id Usuario");
        end else
            BuscarUsuarioDosier(IdGtask, Usuario);
        Incidencia.SetCurrentKey("No.");
        if Incidencia.FindSet() then
            repeat
                AgregarDosierJson(Incidencia, JsonLinea);
                JsonLista.Add(JsonLinea.AsToken());
            until Incidencia.Next() = 0;
        JsonOut.Add('success', true);
        JsonOut.Add('dosieres', JsonLista.AsToken());
        JsonOut.Add('count', JsonLista.Count());
        JsonOut.Add('puede_crear', Usuario."Puede crear dosieres");
        JsonOut.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure AgregarMediosDosierJson(Incidencia: Record Incidencias; var JsonLista: JsonArray)
    var
        Imagenes: Record "Imagenes Orden fijación";
        Doc: Record "Document Attachment";
        JsonMedio: JsonObject;
    begin
        Imagenes.SetRange("Nº Orden", Incidencia."Nº Orden");
        Imagenes.SetRange("Es Incidencia", true);
        if Imagenes.FindSet() then
            repeat
                Clear(JsonMedio);
                JsonMedio.Add('tipo', 'image');
                JsonMedio.Add('nombre', Imagenes.Nombre);
                JsonMedio.Add('url', Imagenes.Url);
                JsonMedio.Add('id', Imagenes.Id);
                JsonLista.Add(JsonMedio.AsToken());
            until Imagenes.Next() = 0;

        Doc.SetRange("Table ID", Database::Incidencias);
        Doc.SetRange("No.", Incidencia."No.");
        if Doc.FindSet() then
            repeat
                Clear(JsonMedio);
                JsonMedio.Add('tipo', 'document');
                JsonMedio.Add('nombre', Doc."File Name");
                JsonMedio.Add('extension', Doc."File Extension");
                JsonMedio.Add('system_id', Format(Doc.SystemId));
                JsonLista.Add(JsonMedio.AsToken());
            until Doc.Next() = 0;
    end;

    [ServiceEnabled]
    procedure DetalleDosier(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonOut: JsonObject;
        JsonMedios: JsonArray;
        Incidencia: Record Incidencias;
        NoDosier: Code[20];
        Txt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido.');
        if JsonIn.Get('no', JsonToken) then
            NoDosier := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoDosier));
        if not Incidencia.Get(NoDosier) then
            Error('No existe el dosier %1.', NoDosier);
        if Incidencia."Tipo Intervención" <> Incidencia."Tipo Intervención"::Dosier then
            Error('%1 no es un dosier.', NoDosier);
        AgregarDosierJson(Incidencia, JsonOut);
        AgregarMediosDosierJson(Incidencia, JsonMedios);
        JsonOut.Add('success', true);
        JsonOut.Add('adjuntos', JsonMedios.AsToken());
        JsonOut.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure GuardarImagenDosier(var Incidencia: Record Incidencias; Contenido: Text; Nombre: Text)
    var
        Imagenes: Record "Imagenes Orden fijación";
        Control: Codeunit ControlProcesos;
        IdImagen: Integer;
        NumeroImagen: Integer;
        Url: Text;
    begin
        Url := Control.FormBase64ToUrl(Contenido, Nombre, IdImagen);
        if (Url = '') or (IdImagen = 0) then
            Error('No se pudo guardar la imagen del dosier.');
        Imagenes.SetRange("Nº Orden", Incidencia."Nº Orden");
        Imagenes.SetRange("Es Incidencia", true);
        if Imagenes.FindLast() then
            NumeroImagen := Imagenes."Nº Imagen" + 1
        else
            NumeroImagen := 1;
        Imagenes.Init();
        Imagenes."Nº Orden" := Incidencia."Nº Orden";
        Imagenes."Nº Imagen" := NumeroImagen;
        Imagenes."Es Incidencia" := true;
        Imagenes.Nombre := CopyStr(Nombre, 1, MaxStrLen(Imagenes.Nombre));
        Imagenes.Url := Url;
        Imagenes.Id := IdImagen;
        Imagenes.Insert(true);
    end;

    local procedure GuardarAdjuntoDosier(var Incidencia: Record Incidencias; Contenido: Text; Nombre: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        RecRef: RecordRef;
        Doc: Record "Document Attachment";
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Base64Convert.FromBase64(Contenido, OutS);
        TempBlob.CreateInStream(InS);
        if InS.Length = 0 then
            Error('El adjunto está vacío.');
        RecRef.GetTable(Incidencia);
        Doc.SaveAttachmentFromStream(InS, RecRef, Nombre);
    end;

    [ServiceEnabled]
    procedure PostAdjuntoDosier(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonOut: JsonObject;
        Incidencia: Record Incidencias;
        Usuario: Record UsuariosGtask;
        NoDosier: Code[20];
        IdGtask: Text;
        Nombre: Text;
        MimeType: Text;
        TipoMedio: Text;
        Contenido: Text;
        Txt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido.');
        if JsonIn.Get('no', JsonToken) then
            NoDosier := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoDosier));
        if JsonIn.Get('usuarioGtask', JsonToken) then
            IdGtask := JsonToken.AsValue().AsText();
        if JsonIn.Get('nombre', JsonToken) then
            Nombre := JsonToken.AsValue().AsText();
        if JsonIn.Get('mimeType', JsonToken) then
            MimeType := LowerCase(JsonToken.AsValue().AsText());
        if JsonIn.Get('tipoMedio', JsonToken) then
            TipoMedio := LowerCase(JsonToken.AsValue().AsText());
        if JsonIn.Get('contenido', JsonToken) then
            Contenido := JsonToken.AsValue().AsText();
        if not BuscarUsuarioDosier(IdGtask, Usuario) then
            Error('No se ha encontrado el usuario de GTask %1.', IdGtask);
        if not Incidencia.Get(NoDosier) then
            Error('No existe el dosier %1.', NoDosier);
        if Incidencia."Tipo Intervención" <> Incidencia."Tipo Intervención"::Dosier then
            Error('%1 no es un dosier.', NoDosier);
        if Nombre = '' then
            Nombre := 'Adjunto_' + Format(CurrentDateTime, 0, 9);
        Contenido := ExtraerPayloadBase64Imagen(Contenido);
        if Contenido = '' then
            Error('El adjunto está vacío.');

        if (TipoMedio = 'image') or (StrPos(MimeType, 'image/') = 1) then
            GuardarImagenDosier(Incidencia, Contenido, Nombre)
        else
            GuardarAdjuntoDosier(Incidencia, Contenido, Nombre);

        JsonOut.Add('success', true);
        JsonOut.Add('no', Incidencia."No.");
        JsonOut.Add('nombre', Nombre);
        JsonOut.Add('mensaje', StrSubstNo('%1 se ha añadido al dosier %2.', Nombre, Incidencia."No."));
        JsonOut.WriteTo(Txt);
        exit(Txt);
    end;

    [ServiceEnabled]
    procedure PostCrearOrdenDosier(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonOut: JsonObject;
        Incidencia: Record Incidencias;
        Usuario: Record UsuariosGtask;
        NoDosier: Code[20];
        IdGtask: Text;
        Txt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido.');
        if JsonIn.Get('no', JsonToken) then
            NoDosier := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(NoDosier));
        if JsonIn.Get('usuarioGtask', JsonToken) then
            IdGtask := JsonToken.AsValue().AsText();
        if not BuscarUsuarioDosier(IdGtask, Usuario) then
            Error('No se ha encontrado el usuario de GTask %1.', IdGtask);
        if not Usuario."Puede crear dosieres" then
            Error('El usuario de GTask %1 no tiene permiso para crear órdenes desde dosieres.', IdGtask);
        if not Incidencia.Get(NoDosier) then
            Error('No existe el dosier %1.', NoDosier);
        if Incidencia."Tipo Intervención" <> Incidencia."Tipo Intervención"::Dosier then
            Error('%1 no es un dosier.', NoDosier);

        EstablecerCreadorOrdenGtask(IdGtask);
        CrearOrdenTrabajoIncidencia(Incidencia);
        Incidencia.Get(NoDosier);
        Incidencia.TestField("Parte Trabajo");

        JsonOut.Add('success', true);
        JsonOut.Add('no', Incidencia."No.");
        JsonOut.Add('parte_trabajo', Incidencia."Parte Trabajo");
        JsonOut.Add('id_qr', IdQrOrdenTrabajo(Incidencia));
        JsonOut.Add('url_ordenes', StrSubstNo('https://ordenes.malla.es/OT-%1', Incidencia."Parte Trabajo"));
        JsonOut.Add('mensaje', StrSubstNo('Orden de trabajo creada: %1', Incidencia."Parte Trabajo"));
        JsonOut.WriteTo(Txt);
        exit(Txt);
    end;

    /// <summary>
    /// Crea mantenimiento programado (puntual=false) o tarea puntual preventiva (puntual=true + descripcion).
    /// JSON: { "tipo":"emplaz|recurso", "tipoEmplazamiento":"...", "codigo":"...",
    ///         "descripcion":"..." (puntual), "puntual":true|false, "usuarioGtask":"Id GTask" }
    /// </summary>
    [ServiceEnabled]
    procedure PostCrearOrdenMantenimiento(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        TipoTxt: Text;
        TipoEmplazTxt: Text;
        Codigo: Code[20];
        Descripcion: Text;
        Puntual: Boolean;
        NoIncidencia: Code[20];
        Txt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido');
        if JsonIn.Get('tipo', JsonToken) then
            TipoTxt := LowerCase(JsonToken.AsValue().AsText());
        if JsonIn.Get('tipoEmplazamiento', JsonToken) then
            TipoEmplazTxt := JsonToken.AsValue().AsText();
        if JsonIn.Get('codigo', JsonToken) then
            Codigo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Codigo));
        if JsonIn.Get('descripcion', JsonToken) then
            Descripcion := JsonToken.AsValue().AsText();
        Puntual := false;
        if JsonIn.Get('puntual', JsonToken) then
            Puntual := JsonToken.AsValue().AsBoolean();
        if JsonIn.Get('usuarioGtask', JsonToken) then
            EstablecerCreadorOrdenGtask(JsonToken.AsValue().AsText())
        else
            EstablecerCreadorOrdenGtask('');
        if Codigo = '' then
            Error('Falta codigo');

        if TipoTxt = 'recurso' then begin
            if not Resource.Get(Codigo) then
                Error('Recurso no encontrado: %1', Codigo);
            NoIncidencia := CrearIncidenciaMantenimientoRecurso(Resource, Descripcion, Puntual);
        end else begin
            if not BuscarEmplazamientoPorTipoONo(TipoEmplazTxt, Codigo, Emplaz) then
                Error('Emplazamiento no encontrado: %1', Codigo);
            if Puntual and (Descripcion <> '') then
                NoIncidencia := CrearIncidenciaMantenimientoEmplazPuntual(Emplaz, Descripcion)
            else
                NoIncidencia := CrearIncidenciaMantenimientoEmplazamiento(Emplaz);
        end;

        Clear(JsonRoot);
        JsonRoot.Add('success', NoIncidencia <> '');
        JsonRoot.Add('no_incidencia', NoIncidencia);
        if NoIncidencia <> '' then begin
            JsonRoot.Add('parte_trabajo', NoIncidencia);
            JsonRoot.Add('id_qr', 'OT-' + NoIncidencia);
            JsonRoot.Add('url_ordenes', StrSubstNo('https://ordenes.malla.es/OT-%1', NoIncidencia));
        end;
        if NoIncidencia = '' then
            JsonRoot.Add('mensaje', 'No se pudo crear la orden (¿ya existe una abierta o falta periodicidad/recursos?)')
        else
            if Puntual and (Descripcion <> '') then
                JsonRoot.Add('mensaje', StrSubstNo('Tarea puntual preventiva creada: %1', NoIncidencia))
            else
                JsonRoot.Add('mensaje', StrSubstNo('Orden de mantenimiento preventivo creada: %1', NoIncidencia));
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    /// <summary>
    /// Crea una petición y su orden de trabajo.
    /// JSON: { "emt": true|false, "codigo":"...", "tipo":"recurso|parada|...", "descripcion":"..." }
    /// </summary>
    [ServiceEnabled]
    procedure PostCrearPeticion(JsonText: Text): Text
    var
        JsonIn: JsonObject;
        JsonToken: JsonToken;
        JsonRoot: JsonObject;
        Emplaz: Record Emplazamientos;
        Resource: Record Resource;
        Incidencia: Record Incidencias;
        Codigo: Code[20];
        TipoTxt: Text;
        Descripcion: Text;
        Emt: Boolean;
        NoIncidencia: Code[20];
        Txt: Text;
    begin
        if not JsonIn.ReadFrom(JsonText) then
            Error('JSON no válido');
        if JsonIn.Get('emt', JsonToken) then
            Emt := JsonToken.AsValue().AsBoolean();
        if JsonIn.Get('codigo', JsonToken) then
            Codigo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Codigo));
        if JsonIn.Get('tipo', JsonToken) then
            TipoTxt := JsonToken.AsValue().AsText();
        if JsonIn.Get('descripcion', JsonToken) then
            Descripcion := JsonToken.AsValue().AsText();
        if Codigo = '' then
            Error('Falta el código de la parada, el emplazamiento o el recurso.');

        if Emt then begin
            if not ResolverParadaPeticionEMT(Codigo, Emplaz) then
                Error('La petición EMT solo se crea sobre una parada. %1 no es una parada.', Codigo);
            NoIncidencia := CrearPeticionEMTParada(Emplaz);
        end else
            if DestinoPeticionEsRecurso(Codigo, TipoTxt, Resource) then
                NoIncidencia := CrearPeticionInternaRecurso(Resource)
            else begin
                if not BuscarEmplazamientoPorTipoONo(TipoEmplazamientoDesdeTexto(TipoTxt), Codigo, Emplaz) then
                    Error('No se ha encontrado el emplazamiento o el recurso %1.', Codigo);
                NoIncidencia := CrearPeticionInternaEmplazamiento(Emplaz);
            end;

        if (NoIncidencia <> '') and (Descripcion <> '') then
            if Incidencia.Get(NoIncidencia) then begin
                Incidencia.Descripción := CopyStr(Descripcion, 1, MaxStrLen(Incidencia.Descripción));
                Incidencia.Modify(true);
            end;

        Clear(JsonRoot);
        JsonRoot.Add('success', NoIncidencia <> '');
        JsonRoot.Add('no_incidencia', NoIncidencia);
        if NoIncidencia = '' then
            JsonRoot.Add('mensaje', 'No se pudo crear la petición.')
        else
            if Emt then
                JsonRoot.Add('mensaje', StrSubstNo('Petición EMT creada: %1', NoIncidencia))
            else
                JsonRoot.Add('mensaje', StrSubstNo('Petición creada: %1', NoIncidencia));
        JsonRoot.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure ResolverParadaPeticionEMT(Codigo: Code[20]; var Emplaz: Record Emplazamientos): Boolean
    var
        Resource: Record Resource;
    begin
        if Emplaz.Get(Emplaz."Tipo Emplazamiento"::Opis, Codigo) then
            exit(true);
        if not Resource.Get(Codigo) then
            exit(false);
        if not TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz) then
            exit(false);
        exit(Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis);
    end;

    local procedure DestinoPeticionEsRecurso(Codigo: Code[20]; TipoTxt: Text; var Resource: Record Resource): Boolean
    var
        TipoLower: Text;
    begin
        TipoLower := LowerCase(TipoTxt);
        if not Resource.Get(Codigo) then
            exit(false);
        if (StrPos(TipoLower, 'emplaz') > 0) or (StrPos(TipoLower, 'parada') > 0) or (TipoLower = 'opis') then
            exit(false);
        if (StrPos(TipoLower, 'recurso') > 0) or (StrPos(TipoLower, 'soporte') > 0) or (TipoLower = '') then
            exit(true);
        exit(true);
    end;

    local procedure TipoEmplazamientoDesdeTexto(TipoTxt: Text): Text
    var
        TipoLower: Text;
    begin
        TipoLower := LowerCase(TipoTxt);
        if (StrPos(TipoLower, 'opis') > 0) or (StrPos(TipoLower, 'parada') > 0) then
            exit('opis');
        if StrPos(TipoLower, 'valla') > 0 then
            exit('vallas');
        if StrPos(TipoLower, 'otro') > 0 then
            exit('otros');
        exit('');
    end;

    local procedure BuscarRecursoDosier(Codigo: Code[20]; Empresa: Text; var Resource: Record Resource): Boolean
    var
        Empresas: Record Company;
    begin
        // El dosier se crea en la empresa de la llamada OData. El recurso puede vivir en otra.
        Resource.Reset();
        if Resource.Get(Codigo) then
            exit(true);
        if (Empresa <> '') and (Empresa <> CompanyName) then begin
            Empresas.SetRange(Name, Empresa);
            if Empresas.FindFirst() then begin
                Resource.ChangeCompany(Empresas.Name);
                Resource.Reset();
                if Resource.Get(Codigo) then
                    exit(true);
            end;
        end;
        Empresas.Reset();
        if Empresas.FindSet() then
            repeat
                if Empresas.Name <> CompanyName then begin
                    Resource.ChangeCompany(Empresas.Name);
                    Resource.Reset();
                    if Resource.Get(Codigo) then
                        exit(true);
                end;
            until Empresas.Next() = 0;
        exit(false);
    end;

    local procedure BuscarEmplazamientoDosier(Codigo: Code[20]; Empresa: Text; var Emplaz: Record Emplazamientos): Boolean
    var
        Empresas: Record Company;
    begin
        if BuscarEmplazamientoPorTipoONo('', Codigo, Emplaz) then
            exit(true);
        if (Empresa <> '') and (Empresa <> CompanyName) then begin
            Empresas.SetRange(Name, Empresa);
            if Empresas.FindFirst() then begin
                Emplaz.ChangeCompany(Empresas.Name);
                if BuscarEmplazamientoPorTipoONo('', Codigo, Emplaz) then
                    exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure BuscarEmplazamientoPorTipoONo(TipoEmplazTxt: Text; NEmplaz: Code[20]; var Emplaz: Record Emplazamientos): Boolean
    begin
        Emplaz.Reset();
        if TipoEmplazTxt <> '' then begin
            case LowerCase(TipoEmplazTxt) of
                'opis':
                    exit(Emplaz.Get(Emplaz."Tipo Emplazamiento"::Opis, NEmplaz));
                'vallas':
                    exit(Emplaz.Get(Emplaz."Tipo Emplazamiento"::Vallas, NEmplaz));
                'otros':
                    exit(Emplaz.Get(Emplaz."Tipo Emplazamiento"::"Otros", NEmplaz));
            end;
        end;
        Emplaz.SetRange("Nº Emplazamiento", NEmplaz);
        exit(Emplaz.FindFirst());
    end;

    procedure CrearIncidenciaMantenimientoRecurso(var Resource: Record Resource; DescripcionCustom: Text; Puntual: Boolean): Code[20]
    var
        Incidencia: Record Incidencias;
        Emplaz: Record Emplazamientos;
        TipoInc: Enum "Tipo Incidencia";
        TipoParte: Option " ",Trabajo,Nacional,EMT;
        DescTxt: Text;
    begin
        Resource.TestField("No.");
        if (not Puntual) and MantenimientoPendienteRecurso(Resource."No.") then
            exit(BuscarNoIncidenciaMantenimientoRecursoAbierta(Resource."No."));

        Clear(Emplaz);
        TryGetEmplazamientoRecurso(Resource."Nº Emplazamiento", Emplaz);
        AsegurarFechaProximoMantenimientoDesdeZona(Emplaz, Resource);

        TipoInc := TipoInc::"Incidencias Soportes";
        if Emplaz."Nº Emplazamiento" <> '' then
            case Emplaz."Tipo Emplazamiento" of
                Emplaz."Tipo Emplazamiento"::"Otros":
                    TipoInc := TipoInc::"Incidencias Mobiliario Urbano";
                Emplaz."Tipo Emplazamiento"::Opis:
                    TipoInc := TipoInc::"Incidencias EMT";
            end;

        Incidencia.Init();
        Incidencia."Es Peticion" := true;
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then begin
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Parada;
            Incidencia.Recurso := Emplaz."Nº Emplazamiento";
        end else begin
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Recurso;
            Incidencia.Recurso := Resource."No.";
        end;
        Incidencia."Tipo Incidencia" := TipoInc;
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Mantenimiento;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Preventivo;
        Incidencia."User Task Group" := 'MTO';
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then
            Incidencia."User Task Group" := 'EMT';
        if Resource."Fecha Próximo Mantenimiento" = 0D then
            Incidencia."FechaHora" := CurrentDateTime() else
            Incidencia."FechaHora" := CreateDateTime(Resource."Fecha Próximo Mantenimiento", Time);
        if DescripcionCustom <> '' then
            DescTxt := DescripcionCustom
        else
            DescTxt := 'Mantenimiento programado ' + Resource.Name;
        Incidencia.Descripción := CopyStr(DescTxt, 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then
            TipoParte := TipoParte::EMT
        else
            TipoParte := TipoParte::Trabajo;
        if Emplaz."Nº Emplazamiento" <> '' then
            CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        if Emplaz."Nº Emplazamiento" <> '' then
            FinalizarAltaMantenimiento(Emplaz, Incidencia)
        else begin
            Resource."Bajo Mantenimiento" := true;
            Resource.Modify(true);
        end;
        exit(Incidencia."No.");
    end;

    local procedure MantenimientoPendienteRecurso(NRecurso: Code[20]): Boolean
    var
        Incidencia: Record Incidencias;
    begin
        Incidencia.SetRange(Recurso, NRecurso);
        Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Recurso);
        Incidencia.SetRange("SubTipo Incidencia", Incidencia."SubTipo Incidencia"::Mantenimiento);
        Incidencia.SetFilter(Estado, '<>%1', Incidencia.Estado::Cerrada);
        exit(not Incidencia.IsEmpty());
    end;

    local procedure BuscarNoIncidenciaMantenimientoRecursoAbierta(NRecurso: Code[20]): Code[20]
    var
        Incidencia: Record Incidencias;
    begin
        Incidencia.SetRange(Recurso, NRecurso);
        Incidencia.SetRange("Tipo Elemento", Incidencia."Tipo Elemento"::Recurso);
        Incidencia.SetRange("SubTipo Incidencia", Incidencia."SubTipo Incidencia"::Mantenimiento);
        Incidencia.SetFilter(Estado, '<>%1', Incidencia.Estado::Cerrada);
        if Incidencia.FindFirst() then
            exit(Incidencia."No.");
        exit('');
    end;

    local procedure CrearIncidenciaMantenimientoEmplazPuntual(var Emplaz: Record Emplazamientos; DescripcionCustom: Text): Code[20]
    var
        Incidencia: Record Incidencias;
        Resource: Record Resource;
        TipoInc: Enum "Tipo Incidencia";
        TipoParte: Option " ",Trabajo,Nacional,EMT;
        NRecurso: Code[20];
    begin
        Resource.Init();
        AsegurarFechaProximoMantenimientoDesdeZona(Emplaz, Resource);
        Incidencia.Init();
        Incidencia."Es Peticion" := true;
        if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Opis then begin
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Parada;
            Incidencia.Recurso := Emplaz."Nº Emplazamiento";
            Incidencia."Tipo Incidencia" := Incidencia."Tipo Incidencia"::"Incidencias EMT";
            Incidencia."User Task Group" := 'EMT';
            TipoParte := TipoParte::EMT;
        end else begin
            NRecurso := ObtenerRecursoPrincipalEmplazamiento(Emplaz);
            if NRecurso = '' then
                exit('');
            Incidencia."Tipo Elemento" := Incidencia."Tipo Elemento"::Recurso;
            Incidencia.Recurso := NRecurso;
            if Emplaz."Tipo Emplazamiento" = Emplaz."Tipo Emplazamiento"::Vallas then
                TipoInc := TipoInc::"Incidencias Soportes"
            else
                TipoInc := TipoInc::"Incidencias Mobiliario Urbano";
            Incidencia."Tipo Incidencia" := TipoInc;
            Incidencia."User Task Group" := 'MTO';
            TipoParte := TipoParte::Trabajo;
        end;
        Incidencia."SubTipo Incidencia" := Incidencia."SubTipo Incidencia"::Mantenimiento;
        Incidencia."Tipo Intervención" := Incidencia."Tipo Intervención"::Preventivo;
        RellenarIncidenciaAbierta(Incidencia);
        Incidencia.Descripción := CopyStr(DescripcionCustom, 1, MaxStrLen(Incidencia.Descripción));
        Incidencia.Insert(true);
        CrearParteMantenimiento(Incidencia, Emplaz, TipoParte);
        FinalizarAltaMantenimiento(Emplaz, Incidencia);
        exit(Incidencia."No.");
    end;

    procedure CrearTareasSinId()
    var
        UserTask: Record "User Task";
        Gtask: Codeunit Gtask;
        Resource: Record "Resource";
        Emplazamientos: Record Emplazamientos;
    begin
        UserTask.SetRange(Id_Tarea, '');
        UserTask.SetRange("User Task Group Assigned To", 'LIMPIEZA');
        if UserTask.FindSet() then
            repeat
                UserTask.Get(UserTask.ID);
                if Emplazamientos.get(UserTask.Id_record) then begin
                    Resource.SetRange("Nº Emplazamiento", Emplazamientos."Nº Emplazamiento");
                    if not Resource.FindFirst() then Resource.init;
                end else
                    Resource.init;
                //UserTask.Id_Tarea := 
                Gtask.CrearTareaTecnico(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
            //UserTask.Modify();
            until UserTask.Next() = 0;

    end;

}