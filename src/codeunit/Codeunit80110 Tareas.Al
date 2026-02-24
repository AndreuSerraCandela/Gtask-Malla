
/// <summary>
/// Codeunit GTask (ID 80110).
/// </summary>
codeunit 7001148 GTask
{
    var
        Qwark: Option Ocr,Qwark;
        LToken: Text;
        Procesos_GTask: Codeunit Procesos_GTask;

    trigger OnRun()
    begin
        UpdateTasksFicheros();
        EnviarCorreoFicheros();
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
                            if JsonDocumentInf.Get('_id', JsonCampo) then
                                DocumentAttachment.ID_Url := JsonCampo.AsValue().AsInteger()
                            else
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
                                        if JsonDetalleCampo.Get('_id', JsonCampo) then
                                            DocumentAtt.ID_Url := JsonCampo.AsValue().AsInteger()
                                        else
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
        Docuname2: Text;
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
                                                if JsonDetalleCampo.Get('_id', JsonCampo) then
                                                    DocumentAtt.ID_Url := JsonCampo.AsValue().AsInteger()
                                                else
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
        JsonFormater.WriteBooleanProperty('bc', true);
        if Tarea.fastPhoto then
            JsonFormater.WriteStringProperty('fastPhoto', 'true');
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
            Procesos_GTask.EnviaCorreo(Rec."No.", Rec.GetDescription(), true, '', false, 'Tarea Eliminada', EmailResponsable, EmailSupervisor, '', '', User."Full Name", true, Rec.Id_Tarea, false);
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
                        UserTask.Validate("Object ID", Page::"Partes de Trabajo")
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
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
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
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
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
        Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
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
        UserTask."Created By" := UserSecurityId();
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
        Servicio, EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos);
        UserTask."Assigned To" := Responsable;
        UserTask."Supervisor" := Supervisor;
        UserTask.Departamento := Departamento;
        UserTask.Servicio := Servicio;
        UserTask."User Task Group Assigned To" := Categoria;
        UserTask.EsPeriodica := EsPeriodica;
        UserTask.ZonaLimpieza := ZonaLimpieza;
        UserTask.TipoTarea := TipoTarea;
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
            Gtask.CrearTareaTecnico(Resource."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
            Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
            Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
        end;
        exit(True);
    end;

    /// <param name="CodigoEmplazamiento">Código del emplazamiento</param>
    /// <param name="CodigoCategoria">Código de la categoría de tarea</param>
    /// <param name="Fecha">Fecha para la tarea (opcional, por defecto WorkDate)</param>
    /// <returns>True si la tarea se creó correctamente, False si ya existía</returns>
    procedure CrearTareaPuestaApunto(CodigoEmplazamiento: Code[20]; CodigoCategoria: Code[20]; Fecha: Date): Boolean
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

        // Crear la tarea usando el procedimiento interno para puesta a punto
        CrearTareaLimpieza('PuestaApunto', RecRef,
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

        // If not IsNullGuid(UserTask.Supervisor) then
        //     UserTask."Created By" := UserTask.Supervisor
        // else
        //No puede ser UserSecurityId(), porque es el usuario que crea la tarea,
        // y no es el usuario de Odata por defecto, vamos a suponer que es el mismo que el supervisor

        //UserTask."Created By" := UserSecurityId();
        UserTask."Assigned To" := rDet.Usuario;
        //Supervisor será de la Categoría MTO, el supervidor
        UserTaskGroup.SetRange("User Task Group Code", 'MTO');
        UserTaskGroup.SetRange(Supervisor, true);
        UserTask.Servicio := 'TALLER';
        If UserTaskGroup.FindFirst() then begin
            UserTask."Supervisor" := UserTaskGroup."User Security ID";
            UserTask.Departamento := UserTaskGroup.Departamento;

        end;
        UserTask."Created By" := UserTask."Supervisor";
        UserTask.Validate("Created DateTime", CurrentDateTime);
        Usertask."Start DateTime" := rDet.FechaHora;
        Usertask."Due DateTime" := rDet.FechaHora;
        UserTask.Validate(Priority, Usertask.Priority::High);
        UserTask.Validate("Object Type", Usertask."Object Type"::Page);
        If rDet."Tipo Elemento" = rDet."Tipo Elemento"::Recurso then begin
            If Resource.Get(rDet.Recurso) then begin
                UserTask.Validate("Object ID", Page::"Resource Card");
                UserTask.Id_record := Resource.RecordId;
                Resource.SetRange("No.", Resource."No.");
                RecRef.GetTable(Resource);
                RecRef.Get(Resource.RecordId);
            end;

        end else begin
            If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, rDet.Recurso) then begin
                UserTask.Validate("Object ID", Page::"Ficha Parada Bus");
                UserTask.Id_record := Emplazamientos.RecordId;
                Resource.SetRange("Nº Emplazamiento", Emplazamientos."Nº Emplazamiento");
                RecRef.GetTable(Emplazamientos);
                RecRef.Get(Emplazamientos.RecordId);

            end;
        end;



        UserTask.Insert(true);
        UserTask.Get(UserTask.ID);
        // if not IsNullGuid(UserTask.Supervisor) then begin
        //     UserTask."Created By" := Supervisor;
        UserTask."No." := Format(UserTask.ID);

        UserTask.IdQr := rDet.Id_Gtask;
        UserTask.TestField(IdQr);
        UserTask."Created By" := UserTask."Supervisor";
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
        UserTask."User Task Group Assigned To" := 'MTO';
        Empleado := rDet.Usuario;
        UserTask."Assigned To" := Empleado;

        UserTask.Modify();
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
        EnviarCorreoBak(UserTask, rDet."Descripción");
        If Strlen(Id_Task) > 30 then exit(Id_Task);
        rDet."Id_Tarea" := UserTask.ID;
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





    local procedure ModifyTareaIncidencia(rDet: Record Incidencias)
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
            UserTask.Validate("Object Type", Usertask."Object Type"::Page);
            If rDet."Tipo Elemento" = rDet."Tipo Elemento"::Recurso then begin
                If rDet.Empresa <> '' Then Resource.ChangeCompany(rDet.Empresa) else Resource.ChangeCompany(CompanyName);
                Resource.Get(rDet.Recurso);
                UserTask.Validate("Object ID", Page::"Resource Card");
                UserTask.Id_record := Resource.RecordId;
                Resource.SetRange("No.", Resource."No.");
                RecRef.GetTable(Resource);
                RecRef.Get(Resource.RecordId);
            end else begin
                Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, rDet.Recurso);
                UserTask.Validate("Object ID", Page::"Ficha Parada Bus");
                UserTask.Id_record := Emplazamientos.RecordId;
                Resource.SetRange("Nº Emplazamiento", Emplazamientos."Nº Emplazamiento");
                RecRef.GetTable(Emplazamientos);
                RecRef.Get(Emplazamientos.RecordId);
            end;
            UserTask."No." := Format(UserTask.ID);
            UserTask.IdQr := rDet.Id_Gtask;
            UserTask.TestField(IdQr);
            UserTask."Created By" := UserTask."Supervisor";
            if rdet.Estado = rdet.Estado::Cerrada then
                UserTask.Estado := UserTask.Estado::Finalizado;
            UserTask.Modify();
        end;
        Procesos_GTask.UpdateTaskGtask(UserTask.Id_Tarea, UserTask.ID);
    end;



    local procedure UpdateTasksFicheros()
    var
        Ficheros: Record Ficheros;

    begin
        Ficheros.SetRange(Proceso, 'UPDATEGTASK');
        Ficheros.SetRange(Procesado, false);
        If Ficheros.FindSet() then begin
            repeat
                Procesos_GTask.UpdateTaskGtask(Ficheros."Nombre fichero", Ficheros."Incoming Entry No.");

            until Ficheros.Next() = 0;

            Ficheros.ModifyAll(Procesado, true);
            Commit();

        end;
    end;

    local procedure EnviarCorreoBak(UserTask: Record "User Task"; Descripcion: Text)
    var
        Ficheros: Record Ficheros;
        Secuencia: Integer;
    begin
        ficheros.Reset();
        if ficheros.FindLast() then Secuencia := ficheros.Secuencia + 1 else Secuencia := 1;
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
                    Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Ficheros."Nombre fichero", EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
                end;

            until Ficheros.Next() = 0;
            Ficheros.Deleteall;
        end;
        Incidencias.SetRange("Enviar Correo", true);
        If Incidencias.FindSet() then begin
            repeat
                //Gtask.Email(Incidencias, EmailResponsable, EmailSupervisor);
                EmailResponsable := 'villena@malla.es';
                ListadeCorreos := 'javier@malla.es;lllompart@malla.es;andreuserra@malla.es';
                If Incidencias."Tipo Incidencia" = Incidencias."Tipo Incidencia"::"Incidencias EMT" then
                    ListadeCorreos += ';aitorrodriguez@malla.es;juamecuart@malla.es';
                If Incidencias."Tipo Elemento" = Incidencias."Tipo Elemento"::Recurso then begin
                    If Recurso.Get(Incidencias.Recurso) Then
                        Desc := Recurso.Name else
                        Desc := Incidencias.Recurso;
                end else begin
                    Desc := 'Parada nº ' + Incidencias.Recurso;
                end;
                Procesos_GTask.EnviaCorreo(Incidencias."No.", Desc + ' - ' + Incidencias.GetWorkDescription(), true, '', false, Incidencias."Descripción",
                EmailResponsable, ListadeCorreos, EmailSupervisor, '', Incidencias.NombreUsuario(), false, '', true);
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
                            RecursoNo := Procesos_GTask.GetRecursoNo(DocumentAttachment, JobsOtrasEmpresas."Empresa Origen");
                            If RecursoNo <> '' then begin
                                DocumentJson.Add('recurso', RecursoNo);
                                if JobsOtrasEmpresas."Empresa Origen" <> '' then
                                    Resource.changecompany(JobsOtrasEmpresas."Empresa Origen")
                                else
                                    Resource.changecompany(CompanyName);
                                if Resource.Get(RecursoNo) then begin
                                    DocumentJson.Add('resource', Resource.Name);
                                    DocumentJson.add('puntox', Resource.PuntoX);
                                    DocumentJson.add('puntoy', Resource.PuntoY);
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

    /// <summary>
    /// Recupera un parte de trabajo existente desde BC por numero_tarea y opcionalmente fecha.
    /// Entrada: {"numero_tarea": "123" (ID User Task), "fecha": "YYYY-MM-DD" (opcional)}
    /// Salida: JSON del parte (numero_tarea, parada_emplazamiento, fecha, descripcion, cliente, lineas) o "{}" si no existe.
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
        NumeroTarea: Text;
        FechaTexto: Text;
        Fecha: Date;
        LineNo: Integer;
        ResultText: Text;
    begin
        Clear(JsonOut);
        if (JsonText = '') or not JsonIn.ReadFrom(JsonText) then begin
            JsonOut.WriteTo(ResultText);
            exit(ResultText);
        end;

        NumeroTarea := '';
        Fecha := 0D;
        if JsonIn.Get('numero_tarea', JsonToken) then NumeroTarea := JsonToken.AsValue().AsText();
        if JsonIn.Get('fecha', JsonToken) then begin
            FechaTexto := JsonToken.AsValue().AsText();
            Evaluate(Fecha, FechaTexto);
        end;

        if (NumeroTarea = '') or not Evaluate(LineNo, NumeroTarea) or not UserTask.Get(LineNo) then begin
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

        JsonOut.Add('numero_tarea', NumeroTarea);
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

    [ServiceEnabled]
    procedure CerrarParteTrabajo(JsonText: Text): Text
    var
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonLine: JsonObject;
        TimeSheetHeader: Record "Time Sheet Header";
        NoParte: Text;
    begin
        if (JsonText = '') or not JsonObj.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');


        if JsonObj.Get('no_parte', JsonToken) then NoParte := JsonToken.AsValue().AsText();
        if TimeSheetHeader.Get(NoParte) then begin
            TimeSheetHeader.Estado := TimeSheetHeader.Estado::Cerrado;
            TimeSheetHeader.Modify();
        end;
    end;

    /// <summary>
    /// Recibe un parte de trabajo desde Rutas (JSON) y crea/actualiza Time Sheet Header + Time Sheet Line.
    /// JSON esperado: {"numero_tarea":"...","parada_emplazamiento":"...","fecha":"YYYY-MM-DD","operario":"...","descripcion":"...","cliente":"...","lineas":[{"tipo":"producto"|"recurso","codigo":"...","nombre":"...","cantidad":1,"precio":0}]}
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
        NumeroTarea: Text;
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
    begin
        if (JsonText = '') or not JsonObj.ReadFrom(JsonText) then
            Error('JSON inválido o vacío');

        NumeroTarea := '';
        ParadaEmplazamiento := '';
        Fecha := 0D;
        Operario := '';
        Descripcion := '';
        Cliente := '';

        if JsonObj.Get('numero_tarea', JsonToken) then NumeroTarea := JsonToken.AsValue().AsText();
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
        // Buscar o crear cabecera por Tarea (User Task) y fecha
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange(Tipo, TimeSheetHeader.Tipo::Trabajo);
        TimeSheetHeader.SetRange("Fecha Inicio", Fecha);
        if NumeroTarea <> '' then begin
            if Evaluate(LineNo, NumeroTarea) then begin
                UserTask.Get(LineNo);
                TimeSheetHeader.SetRange(Tarea, UserTask.ID);
            end else begin
                UserTask.SetRange(Id_Tarea, NumeroTarea);
                if UserTask.FindFirst() then
                    TimeSheetHeader.SetRange(Tarea, UserTask.ID);
            end;
        end;

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
            if (NumeroTarea <> '') and (Evaluate(LineNo, NumeroTarea)) then begin
                if UserTask.Get(LineNo) then
                    TimeSheetHeader.Tarea := UserTask.ID;
            end;
            TimeSheetHeader.Cliente := Cliente;
            TimeSheetHeader.Description := CopyStr(ParadaEmplazamiento, 1, MaxStrLen(TimeSheetHeader.Description));
            // La tabla estándar Time Sheet Header/Line exige "Resource No." válido (OnInsert llama GetTimeSheetResource)
            if TimeSheetHeader."Resource No." = '' then
                TimeSheetHeader.Insert()
            else
                TimeSheetHeader.Insert(true);
        end;

        // Si la cabecera (nueva o existente) tiene Resource No. vacío, el OnInsert de las líneas estándar falla; rellenar con el primer recurso
        // if TimeSheetHeader."Resource No." = '' then begin
        //     Resource.Reset();
        //     if Resource.FindFirst() then begin
        //         TimeSheetHeader."Resource No." := Resource."No.";
        //         TimeSheetHeader.Modify(true);
        //     end;
        // end;

        // Líneas: borrar las actuales si se envían nuevas (opcional: podríamos fusionar)
        if JsonObj.Get('lineas', JsonToken) and JsonToken.IsArray() then begin
            JsonArray := JsonToken.AsArray();
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

        // Enlazar con CreateParte: enviar parte a la API externa (workorder) si la cabecera tiene tarea asociada
        if TimeSheetHeader.Tarea <> 0 then
            if UserTask.Get(TimeSheetHeader.Tarea) then begin
                JsonResult.Add('value', TimeSheetHeader."No.");
                JsonResult.Add('workorder_id', CopyStr(CreateParte(UserTask), 1, 250));
            end else
                JsonResult.Add('value', TimeSheetHeader."No.")
        else
            JsonResult.Add('value', TimeSheetHeader."No.");

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
                    Tareas.Insert(false);
                    Id := Tareas.ID;
                    commit;
                    Tareas.Get(Id);
                    JsonTarea.Get('description', JsonCampo);
                    Tareas.Title := CopyStr(JsonCampo.AsValue().AsText(), 1, 250);
                    if JsonTarea.Get('observation', JsonCampo) Then
                        Tareas.SetDescription(JsonCampo.AsValue().AsText());
                    Tareas.Modify(false);
                    commit;
                    //UpdateTask(Tareas.Id_Tarea, Format(Tareas.ID));

                end;
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
                            If jSonDocument.Get('url', JsonCampo) then begin
                                DocBase64 := JsonCampo.AsValue().AsText();
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
                                        if JsonDetalleCampo.Get('_id', JsonCampo) then
                                            DocumentAtt.ID_Url := JsonCampo.AsValue().AsInteger()
                                        else
                                            DocumentAtt.ID_Url := 0;
                                        DocumentAtt."URL" := DocumentAtt.FormBase64ToUrl(DocBase64, DocuName2, Id);
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
                    UserGtaskMalla.SetRange("Id Gtask", userGtask);
                    If UserGtaskMalla.FindFirst() then begin
                        Tareas.Estado := Tareas.Estado::"En Proceso";
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
        IdIncidencia: Text;
        NuevaIncidencia: Boolean;
        Fecha: DateTime;
        Empresa: Text;
        IdImagen: Integer;
        IdTarea: Text;
        RecursoOriginal: Text;
        Response: HttpResponseMessage;

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
        If JsonIncidencia.Get('incidenceType', JsonCampo) Then
            IncidenceType := JsonCampo.AsValue().AsText();
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
                        FileBase64 := JsonCampo.AsValue().AsText();
                        If CopyStr(FileBase64, 1, 4) = 'http' then begin
                            ImpagenesTemp.Url := FileBase64;
                        end else begin
                            //Si empieza por data:image/jpeg;base64, entonces es una imagen jpeg y hay 
                            if CopyStr(FileBase64, 1, 23) = 'data:image/jpeg;base64,' then
                                FileBase64 := CopyStr(FileBase64, 24, StrLen(FileBase64));
#If CLEAN27
                            ImpagenesTemp.Url := Control.FormBase64ToUrl(FileBase64, 'Imagen' + Format(Imagen) + '.jpg', IdImagen);
#else
                            ImpagenesTemp.Url := ImpagenesTemp.FormBase64ToUrl(FileBase64, 'Imagen' + Format(Imagen) + '.jpg', IdImagen);
#endif
                            ImpagenesTemp.Id := IdImagen;
                        end;
                        ImpagenesTemp."Nº Imagen" := Imagen;
                        // Intentar obtener el nombre del JSON, si no existe usar el nombre por defecto
                        if document.Get('name', JsonCampo) then
                            ImpagenesTemp.Nombre := JsonCampo.AsValue().AsText()
                        else
                            ImpagenesTemp.Nombre := 'Imagen' + Format(Imagen) + '.jpg';
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
        rDet.Descripción := CopyStr(Description, 1, MaxStrLen(rDet.Descripción));
        // Si la incidenciia no es nueva, y el usuario no existe, el usuario será equipoti
        if not NuevaIncidencia and IsNullGuid(UsuarioId) then
            If Usuario.Get('67a4a441f8a4bb001960c4d6') then
                UsuarioId := Usuario."Id Usuario";
        //rDet. := Observation;
        if IsNullGuid(UsuarioId) = false then
            rDet.Usuario := UsuarioId;

        case IncidenceType of

            'EMT':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias EMT";
            'VILLENA':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Villena";
            'TALLER':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Taller";
            'MTO':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Mobiliario Urbano";
            'TAREA TALLER':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Grupo Taller";
            'PODA':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Poda";

        end;
        case Uppercase(State) of
            'PENDING', 'ABIERTA':
                rDet.Estado := rDet.Estado::Abierta;
            'IN_PROGRESS', 'EN_PROCESO':
                rDet.Estado := rDet.Estado::EnProgreso;
            'COMPLETED', 'CLOSED', 'CERRADA':
                rDet.Estado := rDet.Estado::Cerrada;
        end;
        rDet.Empresa := Empresa;

        if NuevaIncidencia then begin
            rDet."Enviar Correo" := true;
            If IdIncidencia = '' Then rDet.Insert(true);
        end;
        If ImpagenesTemp.FindSet() then
            repeat
                // si ya existe la imagen, entonces, le asigno nº de miagen siguiente
                Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
                Imagenes.SetRange("Es Incidencia", true);
                Imagen := ImpagenesTemp."Nº Imagen";
                Imagenes.SetRange("Nº Imagen", ImpagenesTemp."Nº Imagen");
                If Imagenes.FindSet() then
                    repeat
                        Imagen += 1;
                    until Imagenes.Next() = 0;
                Imagenes.Init();
                Imagenes."Nº Orden" := rDet."Nº Orden";
                Imagenes."Nº Imagen" := Imagen;
                Imagenes.Id := ImpagenesTemp.Id;
                Imagenes."Es Incidencia" := true;
                Imagenes.Url := ImpagenesTemp.Url;
                Imagenes.Nombre := ImpagenesTemp.Nombre;
                Imagenes.Insert();
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
        If NuevaIncidencia then
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
        rDet.SetWorkDescription(Description + ' ' + Observation);
        commit;
        rDet.Get(rDet."No.");
        rDet.CalcFields("Work Description"); // Evitar que el Modify siguiente sobrescriba el BLOB
        if StrLen(Id) > 30 then
            exit(DevolverError404('Error al generar Incidencia: el id devuelto excede la longitud permitida (30). Valor: ' + CopyStr(Id, 1, 50)));
        rDet.Id_Gtask := Id;
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
        JsonIncidencia.ReadFrom(JsonText);
        if JsonIncidencia.Get('_id', JsonCampo) Then IdIncidencia := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('state', JsonCampo) Then
            State := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('user', JsonCampo) Then
            If Usuario.Get(JsonCampo.AsValue().AsText()) then
                UsuarioId := Usuario."Id Usuario";
        If JsonIncidencia.Get('incidenceType', JsonCampo) Then
            IncidenceType := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('observation', JsonCampo) Then
            Observation := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('description', JsonCampo) Then
            Description := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('peticion', JsonCampo) Then
            Peticion := JsonCampo.AsValue().AsBoolean();
        // If JsonIncidencia.Get('resource', JsonCampo) Then
        //     Resource := JsonCampo.AsValue().AsText();
        If JsonIncidencia.Get('stop', JsonCampo) Then
            Stop := JsonCampo.AsValue().AsText();
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
            Observation := ConstruirObservationDesdePartes(Frequency, Departament, Zone, Stop);
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
                        FileBase64 := JsonCampo.AsValue().AsText();
                        If CopyStr(FileBase64, 1, 4) = 'http' then begin
                            ImpagenesTemp.Url := FileBase64;
                        end else begin
                            //Si empieza por data:image/jpeg;base64, entonces es una imagen jpeg y hay 
                            if CopyStr(FileBase64, 1, 23) = 'data:image/jpeg;base64,' then
                                FileBase64 := CopyStr(FileBase64, 24, StrLen(FileBase64));
                            ImpagenesTemp.Url := Control.FormBase64ToUrl(FileBase64, 'Imagen' + Format(Imagen) + '.jpg', IdImagen);
                            ImpagenesTemp.Id := IdImagen;
                        end;
                        ImpagenesTemp."Nº Imagen" := Imagen;
                        // Intentar obtener el nombre del JSON, si no existe usar el nombre por defecto
                        if document.Get('name', JsonCampo) then
                            ImpagenesTemp.Nombre := JsonCampo.AsValue().AsText()
                        else
                            ImpagenesTemp.Nombre := 'Imagen' + Format(Imagen) + '.jpg';
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
        rDet.FechaHora := Fecha;
        rDet.Descripción := CopyStr(Description, 1, MaxStrLen(rDet.Descripción));
        rDet."Frecuencia" := CopyStr(Frequency, 1, MaxStrLen(rDet."Frecuencia"));
        if Stop <> '' then
            rDet.Recurso := CopyStr(stop, 1, MaxStrLen(rDet.Recurso));
        if IsNullGuid(UsuarioId) = false then
            rDet.Usuario := UsuarioId;

        case IncidenceType of

            'EMT':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias EMT";
            'VILLENA':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Villena";
            'TALLER':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Taller";
            'MTO':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Mobiliario Urbano";
            'TAREA TALLER':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Grupo Taller";
            'PODA':
                rDet."Tipo Incidencia" := rDet."Tipo Incidencia"::"Incidencias Poda";

        end;
        case Uppercase(State) of
            'PENDING', 'ABIERTA':
                rDet.Estado := rDet.Estado::Abierta;
            'IN_PROGRESS', 'EN_PROCESO':
                rDet.Estado := rDet.Estado::EnProgreso;
            'COMPLETED', 'CLOSED', 'CERRADA':
                rDet.Estado := rDet.Estado::Cerrada;
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
                // si ya existe la imagen, entonces, le asigno nº de miagen siguiente
                Imagenes.SetRange("Nº Orden", rDet."Nº Orden");
                Imagenes.SetRange("Es Incidencia", true);
                Imagen := ImpagenesTemp."Nº Imagen";
                Imagenes.SetRange("Nº Imagen", ImpagenesTemp."Nº Imagen");
                If Imagenes.FindSet() then
                    repeat
                        Imagen += 1;
                    until Imagenes.Next() = 0;
                Imagenes.Init();
                Imagenes."Nº Orden" := rDet."Nº Orden";
                Imagenes."Nº Imagen" := Imagen;
                Imagenes.Id := ImpagenesTemp.Id;
                Imagenes."Es Incidencia" := true;
                Imagenes.Url := ImpagenesTemp.Url;
                Imagenes.Nombre := ImpagenesTemp.Nombre;
                Imagenes.Insert();
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
        rDet.Id_Gtask := Id;
        rDet.Modify();
        Commit();

        rDet.Get(rDet."No.");
        If not CabOrdenFijacion.Get(rDet."Nº Orden") then begin
            CabOrdenFijacion.Init();
            CabOrdenFijacion."Nº Orden" := rDet."Nº Orden";
            CabOrdenFijacion.Insert();
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
        Descripcion := Incidencias.GetWorkDescription();
        if Descripcion = '' then
            Descripcion := Incidencias."Descripción";
        JsonFormater.WriteStringProperty('description', Descripcion);
        JsonFormater.WriteStringProperty('state', Incidencias.Estado);
        JsonFormater.WriteStringProperty('incidenceType', Format(Incidencias."Tipo Incidencia"));
        JsonFormater.WriteStringProperty('resource', Incidencias.Recurso);
        //tipo elemento
        JsonFormater.WriteStringProperty('type', Format(Incidencias."Tipo Elemento"));
        //Nombre del Recurso
        JsonFormater.WriteStringProperty('resource_name', Incidencias.NombreElemento());
        JsonFormater.WriteStringProperty('fecha', Format(Incidencias.FechaHora, 0, '<Year4>-<Month,2>-<Day,2>T<Hour,2>:<Minute,2>:<Second,2>Z'));
        JsonFormater.WriteStringProperty('user', Incidencias.NombreUsuario());
        JsonFormater.WriteStringProperty('user_name', Incidencias.ID_UsuarioGtask(Incidencias.Usuario));
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
                if FechaDesde <> 0D then
                    UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                if IdResponsabel <> '' then begin
                    UserGtask.SetRange("Id Gtask", IdResponsabel);
                    if UserGtask.FindFirst() then
                        UserTask.SetRange("Assigned To", UserGtask."Id Usuario");
                end;
                if UserTask.FindSet() then begin
                    repeat
                        Procesos_GTask.AgregarTareaAlJson(UserTask, Emplazamientos, JsonArray);
                    until UserTask.Next() = 0;
                end;
                // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                if FechaDesde <> 0D then begin
                    UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                    UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                    if UserTask.FindSet() then begin
                        repeat
                            Procesos_GTask.AgregarTareaAlJson(UserTask, Emplazamientos, JsonArray);
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
                                Procesos_GTask.AgregarTareaAlJson(UserTask, EmplazamientosFiltrados, JsonArray);
                            until UserTask.Next() = 0;
                        end;
                        // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                        if FechaDesde <> 0D then begin
                            UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                            UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                            if UserTask.FindSet() then begin
                                repeat
                                    Procesos_GTask.AgregarTareaAlJson(UserTask, Emplazamientos, JsonArray);
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
                if FechaDesde <> 0D then
                    UserTask.SetRange("Start DateTime", FechaDesdeDT, FechaHastaDT);
                if UserTask.FindSet() then begin
                    repeat
                        // Intentar obtener el emplazamiento desde Id_record
                        if UserTask.Id_record.TableNo = Database::Emplazamientos then begin
                            if Emplazamientos.Get(UserTask.Id_record) then
                                Procesos_GTask.AgregarTareaAlJson(UserTask, Emplazamientos, JsonArray);
                        end;
                    until UserTask.Next() = 0;
                end;
                // Si se ha proporcionado Fecha desde, añadir todas las tareas con fecha antgerior a desde y estado pendiente
                if FechaDesde <> 0D then begin
                    UserTask.SetRange("Start DateTime", 0DT, FechaDesdeDT);
                    UserTask.SetRange(Estado, UserTask.Estado::Pendiente);
                    if UserTask.FindSet() then begin
                        repeat
                            Procesos_GTask.AgregarTareaAlJson(UserTask, Emplazamientos, JsonArray);
                        until UserTask.Next() = 0;
                    end;
                end;
            end;
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
                FechaDesdeDT := CreateDateTime(FechaDesde, 0T);
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

        if UserTask.FindSet() then
            repeat
                Procesos_GTask.AgregarTareaUsuarioAlJson(UserTask, JsonArray);
            until UserTask.Next() = 0;

        JsonArray.WriteTo(JsonResult);
        exit(JsonResult);
    end;

    /// <summary>
    /// Endpoint para crear tareas de puesta a punto desde JSON
    /// Formato JSON esperado: [{"codigoEmplazamiento": "COD001", "codigoCategoria": "CAT001", "fecha": "2024-01-15"}, ...]
    /// </summary>
    /// <param name="JsonText">JSON array con las tareas a crear</param>
    /// <returns>JSON con el resultado: {"tareasCreadas": 5, "tareasExistentes": 2, "errores": []}</returns>
    [ServiceEnabled]
    procedure CrearTareasPuestaApuntoJson(JsonText: Text): Text
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
                if CrearTareaPuestaApunto(CodigoEmplazamiento, CodigoCategoria, Fecha) then
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
    /// Endpoint para obtener la lista de categorías de puesta a punto
    /// </summary>
    /// <returns>JSON array con las categorías: [{"code": "CAT001", "description": "Descripción 1"}, ...]</returns>
    [ServiceEnabled]
    procedure GetCategoriasPuestaApunto(): Text
    var
        ZonasLimpieza: Record "Zonas Limpieza";
        JsonArray: JsonArray;
        JsonCategoria: JsonObject;
        JsonText: Text;
    begin
        ZonasLimpieza.ChangeCompany('Malla Publicidad');
        ZonasLimpieza.SetRange("Tipo Tarea", 'PuestaApunto');

        if ZonasLimpieza.FindSet() then begin
            repeat
                Clear(JsonCategoria);
                JsonCategoria.Add('code', ZonasLimpieza.Categoria);
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
        Procesos_GTask.Email(UserTask, EmailResponsable, EmailSupervisor);
        Procesos_GTask.EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListaCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
    end;




    #endregion Serivices
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



}