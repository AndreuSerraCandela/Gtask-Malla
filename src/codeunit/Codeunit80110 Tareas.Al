
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
                    JsonObjt.Add('bc', true);
                    JsonObjt.WriteTo(Json);
                    Clear(RestApi);
                    Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Token(), RequestType::put, Json);

                end;
                //GetSetDocattchment(Tareas, Tareas.Id_Tarea);
                GetSetChat(Tareas, Tareas.Id_Tarea);
            until Tareas.Next() = 0;


    end;

    procedure UpdateTasksProoriry(var Tareas: Record "User Task")
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
        Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Token(), RequestType::put, Json);


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
            JsonObjt.Add('bc', true);

            JsonObjt.WriteTo(Json);
            Clear(RestApi);

            Json := RestApi.RestApiToken(CompanyInfo."Url Task" + 'task/' + Tareas.Id_Tarea, Token(), RequestType::put, Json);
            // GetSetChat(Tareas, Tareas.Id_Tarea);
        End;


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
                BusCaUsuario(UserIdus, UserGtaskMalla);
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
        Frecuencia: DateFormula;
    begin
        JsonArray.ReadFrom(JsonText);
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
                            If Tareas.Frecuencia <> Frecuencia then begin
                                if Tareas.DependenciaCreada = false then begin
                                    commit;
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
                        Tareas.ChangeCompany(CambiaEmpresa(CodEmpresa));
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
                                            DocumentAtt.ChangeCompany(CambiaEmpresa(CodEmpresa));
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
                                                DocumentAttachment2.ChangeCompany(CambiaEmpresa(CodEmpresa));
                                            DocumentAttachment2 := DocumentAtt;
                                            DocumentAttachment2."Table ID" := Database::"Orden fijación";
                                            DocumentAttachment2."No." := Tareas."Job No.";
                                            DocumentAttachment2."Line No." := Tareas.Reserva;
                                            DocumentAttachment2."ID_Doc" := Tareas.OrdenFijacion;
                                            DocumentAttachment2."Document Flow Service" := true;
                                            If DocumentAttachment2.Insert() Then
                                                AdImagenValla(DocumentAttachment2, CambiaEmpresa(CodEmpresa));
                                            if CodEmpresa <> '' then
                                                DocumentAttachment3.ChangeCompany(CambiaEmpresa(CodEmpresa));
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
                    if Tareas.FindSet() then
                        repeat
                            if Tareas.Estado <> Tareas.Estado::Finalizado then begin
                                clear(JsonTareaOutPut);
                                JsonTareaOutPut.Add('idnavision', Tareas.Id);
                                JsonTareaOutPut.Add('empresa', Empresas.Name);
                                JsonTareaOutPut.Add('descripcion', Tareas.Title);
                                JsonOutPutArrayItem.Add(JsonTareaOutPut);
                                CuentaTareas += 1;
                            end;
                        until Tareas.Next() = 0;
                until Empresas.Next() = 0;
                if CuentaTareas = 0 Then begin
                    Empresas.FindFirst();
                    repeat
                        Tareas.ChangeCompany(Empresas.Name);
                        Tareas.Reset();
                        Tareas.SetRange(IdQr, IdQrTxt);
                        if Tareas.Findlast() then begin

                            clear(JsonTareaOutPut);
                            JsonTareaOutPut.Add('idnavision', Tareas.Id);
                            JsonTareaOutPut.Add('empresa', Empresas.Name);
                            JsonTareaOutPut.Add('descripcion', Tareas.Title);
                            JsonOutPutArrayItem.Add(JsonTareaOutPut);
                            CuentaTareas += 1;

                        end;
                    until Empresas.Next() = 0;
                end;
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
        //Fecha AAAA-MM-DD 2025-11-13 o formato ISO 2025-11-11T23:00:00Z
        // Priorizar fechaHora si existe, sino usar fecha
        If JsonIncidencia.Get('fechahora', JsonCampo) Then begin
            Fecha := JsonCampo.AsValue().AsDateTime() - 1 * 3600 * 1000; // restar 1 hora;
        end else if JsonIncidencia.Get('fecha', JsonCampo) Then begin
            Fecha := ParseFechaFromJson(JsonCampo.AsValue().AsText());
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
            if rDet.Get(Copystr(IdIncidencia, 1, 20)) then
                IdIncidencia := rDet.Id_Gtask;
            rDet.SetRange("Id_Gtask", IdIncidencia);
            if Not rDet.FindFirst() then
                rDet.Init()
            else
                NuevaIncidencia := false;
        end;
        rDet.Recurso := Resource;
        if Parada then
            rDet."Tipo Elemento" := rDet."Tipo Elemento"::Parada
        else
            rDet."Tipo Elemento" := rDet."Tipo Elemento"::Recurso;
        rDet.Fecha := DT2Date(Fecha);
        rDet.FechaHora := Fecha;
        rDet.Descripción := CopyStr(Description, 1, MaxStrLen(rDet.Descripción));
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
        rDet.Empresa := Empresa;

        if NuevaIncidencia then begin
            rDet."Enviar Correo" := true;
            rDet.Insert(true);
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

        JsonFormater.WriteStringProperty('state', 'PENDING');
        JsonFormater.WriteStringProperty('incidenceType', GetTipoIncidencia(Format(rDet."Tipo Incidencia")));
        JsonFormater.WriteStringProperty('observation', Observation);
        JsonFormater.WriteStringProperty('description', Description);
        If (Not Parada) and (Resource <> '') and (Encontrado) then begin
            wRecordRef.Close();
            if Empresa = '' Then Empresa := CompanyName;
            Recurso.ChangeCompany(Empresa);
            If Not Recurso.Get(Resource) then begin
                wRecordRef.Open(Database::Resource, false, Empresa);
                wRecordRef.Get(Recurso.RecordId);
                resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, Empresa);
                if resource = 'Error' then begin
                    CreaRecurso(Recurso, Recurso.RecordId, Database::Resource);
                    resource := GetMaestro('resource', Recurso.Name, 'name', wRecordRef, Database::Resource, Empresa);
                end;
            end;
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

        if resource <> '' then
            JsonFormater.WriteStringProperty('resource', resource);
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
        rDet.SetWorkTextDescription(Description + ' ' + Observation);
        rDet.Get(rDet."No.");
        if NuevaIncidencia then
            rDet.Id_Gtask := Id;
        rDet.Modify();
        rDet.Get(rDet."No.");
        If rDet."Id Tarea Gtask" <> '' then begin
            ModifyTareaIncidencia(rDet);
        end;
        If not NuevaIncidencia then begin
            If (rDet."Id Tarea Gtask" = '') then begin
                IdTarea := CrearTareaIncidencia(rDet);
                If IdTarea <> 'Error: No ha completado los campos' then
                    rDet."Id Tarea Gtask" := IdTarea
                else begin

                    Error('Error al crear la tarea: ' + IdTarea);
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
                    GetSetDocattchment(Tareas, Tareas.Id_Tarea);
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
                            GetSetDocattchment(Tareas, Tareas.Id_Tarea);
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
            EnviaCorreo(Rec."No.", Rec.GetDescription(), true, '', false, 'Tarea Eliminada', EmailResponsable, EmailSupervisor, '', '', User."Full Name", true, Rec.Id_Tarea, false);
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
        Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
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
        Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, Categoria, EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos);
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
        Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
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
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
    end;


    internal procedure CrearTareaLimpieza(
           TipoTarea: Text;
           RecRef: RecordRef;
           Title: Text;
           ZonaLimpieza: Integer;
           Descripcion: Text;
           Adjuntar: Boolean;
           Adjunto: Text; Fecha: Date; Fecuencia: DateFormula): Boolean
    var

        Responsable: Guid;
        Supervisor: Guid;
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
    //Operario: Guid;
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
        Gtask.DevuelveCategoriaSupervisorResponsablePorZona(TipoTarea, ZonaLimpieza, Responsable, Supervisor, Categoria, Departamento,
        Servicio, EmailResponsable, EmailSupervisor, User, UserTask, ListadeCorreos);
        UserTask."Assigned To" := Responsable;
        UserTask."Supervisor" := Supervisor;
        UserTask.Departamento := Departamento;
        UserTask.Servicio := Servicio;
        UserTask.Frecuencia := Fecuencia;
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
        UserTask.Modify();
        //end;
        Commit();
        // UserTaskCard.SetRecord(UserTask);
        // UserTaskCard.RunModal();
        // iF UserTask.Estado = UserTask.Estado::Cancelado then begin
        //     UserTask.Get(UserTask.ID);
        //     Commit();
        //     If Confirm('¿Desea borrar la tarea?') then begin
        //         UserTask.Delete();
        //         exit;
        //     end;
        // end;
        Commit();
        //Operario := Responsable;
        //Page.RunModal(Page::"User Task Card", UserTask);

        UserTask.Modify();
        Commit();

        UserTask.Get(UserTask.ID);
        //UserTask."Assigned To" := Operario;
        UserTask.Modify();
        If (IsNullGuid(UserTask."Supervisor")) or (IsNullGuid(UserTask."Assigned To"))
        or (UserTask."User Task Group Assigned To" = '') Or (UserTask.Departamento = '')
        or (UserTask.Servicio = '') Then begin
            UserTask.Delete();

            exit(False);

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
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
        exit(True);
    end;

    /// <summary>
    /// Endpoint para recuperar tareas de limpieza filtradas por zona, emplazamiento y/o fechas
    /// Formato JSON de entrada: {"zonaLimpieza": 1, "codigoEmplazamiento": "COD001", "fechaDesde": "2024-01-15", "fechaHasta": "2024-01-20"}
    /// Todos los campos son opcionales
    /// </summary>
    /// <param name="JsonText">JSON con los filtros de búsqueda</param>
    /// <returns>JSON array con las tareas encontradas</returns>
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
        UserTaskGroup: Record "User Task Group";
        UserTaskGroupMember: Record "User Task Group Member";
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

        // Obtener categorías de tipo LIMPIEZA
        UserTaskGroup.ChangeCompany('Malla Publicidad');
        UserTaskGroup.SetRange("Tipo de Tarea", 'LIMPIEZA');
        CategoriasLimpieza := '';
        if UserTaskGroup.FindSet() then begin
            repeat
                if CategoriasLimpieza <> '' then
                    CategoriasLimpieza := CategoriasLimpieza + '|';
                CategoriasLimpieza := CategoriasLimpieza + UserTaskGroup.Code;
            until UserTaskGroup.Next() = 0;
        end;

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
                if UserTask.FindSet() then begin
                    repeat
                        AgregarTareaAlJson(UserTask, Emplazamientos, JsonArray);
                    until UserTask.Next() = 0;
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
                                AgregarTareaAlJson(UserTask, EmplazamientosFiltrados, JsonArray);
                            until UserTask.Next() = 0;
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
                                AgregarTareaAlJson(UserTask, Emplazamientos, JsonArray);
                        end;
                    until UserTask.Next() = 0;
                end;
            end;
        end;

        JsonArray.WriteTo(JsonResult);
        exit(JsonResult);
    end;

    /// <summary>
    /// Procedimiento auxiliar para agregar una tarea al JSON array de resultados
    /// </summary>
    local procedure AgregarTareaAlJson(var UserTask: Record "User Task"; var Emplazamientos: Record Emplazamientos; var JsonArray: JsonArray)
    var
        JsonTarea: JsonObject;
        User: Record User;
        UserGtask: Record UsuariosGtask;
        FechaInicio: Date;
        HoraInicio: Time;

    begin
        Clear(JsonTarea);
        JsonTarea.Add('id', UserTask.ID);
        JsonTarea.Add('no', UserTask."No.");
        JsonTarea.Add('title', UserTask.Title);
        JsonTarea.Add('description', UserTask.GetDescription());
        JsonTarea.Add('codigoEmplazamiento', Emplazamientos."Nº Emplazamiento");
        JsonTarea.Add('descripcionEmplazamiento', Emplazamientos."Descripción");
        JsonTarea.Add('zonaLimpieza', Emplazamientos."Zona Limpieza");
        JsonTarea.Add('categoria', UserTask."User Task Group Assigned To");
        JsonTarea.Add('departamento', UserTask.Departamento);
        JsonTarea.Add('servicio', UserTask.Servicio);
        JsonTarea.Add('estado', Format(UserTask.Estado));
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
    /// Crea una tarea de puesta a punto para un emplazamiento específico
    /// </summary>
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
            Periodicidad);

        exit(true);
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
        UserTaskGroup: Record "User Task Group";
        JsonArray: JsonArray;
        JsonCategoria: JsonObject;
        JsonText: Text;
    begin
        UserTaskGroup.ChangeCompany('Malla Publicidad');
        UserTaskGroup.SetRange("Tipo de Tarea", 'PuestaApunto');

        if UserTaskGroup.FindSet() then begin
            repeat
                Clear(JsonCategoria);
                JsonCategoria.Add('code', UserTaskGroup.Code);
                JsonCategoria.Add('description', UserTaskGroup.Description);
                JsonArray.Add(JsonCategoria);
            until UserTaskGroup.Next() = 0;
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
        EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Title, EmailResponsable, ListaCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
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

    local procedure GetSetDocattchmentParteTrabajo(TimeSheetLine: Record "Time Sheet Line"; JobNo: Code[20])
    begin
        //TODO: Implementar
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
        UserTask.Validate("Created By", UserSecurityId());
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

    procedure DevuelveCategoriaSupervisorResponsablePorZona(
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
        UserGtaskMalla: Record UsuariosGtask;
        UserxbyCategory: Record "User Task Group Member";
        UserTaskGroup: Record "User Task Group";
        Categorias: Text;
    begin
        UserTaskGroup.ChangeCompany('Malla Publicidad');
        UserTaskGroup.SetRange("Tipo de Tarea", TipoTarea);
        //Crear FiltroTexto Categorias
        If UserTaskGroup.FindSet() then begin
            repeat
                Categorias := Categorias + UserTaskGroup."Code" + '|';
            until UserTaskGroup.Next() = 0;
            Categorias := CopyStr(Categorias, 1, StrLen(Categorias) - 1);
        end;
        If not UserTaskGroup.FindFirst() then Error('No se ha encontrado el tipo de tarea %1 en Gtask', TipoTarea);
        UserGtaskMalla.ChangeCompany('Malla Publicidad');
        If not IsNullGuid(Responsable) then begin
            UserGtaskMalla.SetRange("Id Usuario", Responsable);
            If not UserGtaskMalla.FindFirst() then Error('Usuario %1 no encontrado en Gtask', Responsable);
        end;
        UserGtaskMalla.SetRange("Id Usuario", UserSecurityId());
        If not UserGtaskMalla.FindFirst() then Error('Usuario %1 no encontrado en Gtask', UserId());

        // Buscar categoría basándose en Departamento, Servicio y Zona de Limpieza
        UserxbyCategory.ChangeCompany('Malla Publicidad');
        UserxbyCategory.Reset();
        if Departamento <> '' then
            UserxbyCategory.SetRange(Departamento, Departamento);
        if ZonaLimpieza <> 0 then
            UserxbyCategory.SetRange("Zona Limpieza", ZonaLimpieza);
        UserxbyCategory.SetFilter("User Task Group Code", Categorias);
        If UserxbyCategory.FindFirst() then begin
            Categoria := UserxbyCategory."User Task Group Code";
        end;
        //Si no encuentro categoría, intento filtrar por departamento
        If (Categoria = '') then begin
            UserxbyCategory.Reset();
            if Departamento <> '' then
                UserxbyCategory.SetRange(Departamento, Departamento);
            UserxbyCategory.SetFilter("User Task Group Code", Categorias);
            If UserxbyCategory.FindFirst() then begin
                Categoria := UserxbyCategory."User Task Group Code";
            end;
        end;

        // Si no se encontró categoría, intentar sin filtrar por zona
        If (Categoria = '') and (ZonaLimpieza <> 0) then begin
            UserxbyCategory.Reset();
            UserxbyCategory.SetRange("Zona Limpieza", ZonaLimpieza);
            UserxbyCategory.SetFilter("User Task Group Code", Categorias);
            If UserxbyCategory.FindFirst() then begin
                Categoria := UserxbyCategory."User Task Group Code";
            end;
        end;


        // Validar que la categoría existe
        If (Categoria <> '') then begin
            If not UserTaskGroup.Get(Categoria) then
                Error('No se ha encontrado la categoría %1 en Gtask', Categoria);
        end;
        If Categoria = '' then Error('No se ha encontrado la categoría en Gtask');

        // Buscar Responsable basándose en Departamento, Categoría y Zona de Limpieza
        If IsnullGuid(Responsable) then begin
            UserGtaskMalla.Reset();
            UserxbyCategory.ChangeCompany('Malla Publicidad');
            UserxbyCategory.Reset();
            if Departamento <> '' then
                UserxbyCategory.SetRange(Departamento, Departamento);
            UserxbyCategory.SetRange("User Task Group Code", Categoria);
            UserxbyCategory.SetRange("Zona Limpieza", ZonaLimpieza);
            UserxbyCategory.SetRange(Responsable, true);
            UserxbyCategory.SetRange("Copiado en Mail", false);
            If UserxbyCategory.FindFirst() then begin
                Responsable := UserxbyCategory."User Security ID";
                If Departamento = '' then Departamento := UserxbyCategory.Departamento;
            end else begin
                UserxbyCategory.SetRange("Copiado en Mail");
                If UserxbyCategory.FindFirst() then begin
                    Responsable := UserxbyCategory."User Security ID";
                    If Departamento = '' then Departamento := UserxbyCategory.Departamento;
                end else begin
                    // Intentar sin filtrar por zona
                    UserxbyCategory.Reset();
                    UserxbyCategory.SetRange(Departamento, Departamento);
                    If Categoria <> '' then
                        UserxbyCategory.SetRange("User Task Group Code", Categoria);
                    UserxbyCategory.SetRange(Responsable, true);
                    UserxbyCategory.SetRange("Copiado en Mail", false);
                    If UserxbyCategory.FindFirst() then begin
                        Responsable := UserxbyCategory."User Security ID";
                        If Departamento = '' then Departamento := UserxbyCategory.Departamento;
                    end else begin
                        UserxbyCategory.SetRange("Copiado en Mail");
                        If UserxbyCategory.FindFirst() then begin
                            Responsable := UserxbyCategory."User Security ID";
                            If Departamento = '' then Departamento := UserxbyCategory.Departamento;
                        end else begin
                            UserGtaskMalla.SetRange(Departamento);
                            UserGtaskMalla.SetRange(Responsable, true);
                            If UserGtaskMalla.FindFirst() then begin
                                Responsable := UserGtaskMalla."Id Usuario";
                                If Departamento = '' then Departamento := UserGtaskMalla.Departamento;
                            end;
                        end;
                    end;
                end;
            end;
        end;
        If Departamento = '' then Error('No se ha encontrado el departamento en Gtask');

        // Buscar Supervisor basándose en Servicio, Categoría y Zona de Limpieza
        UserxbyCategory.ChangeCompany('Malla Publicidad');
        UserxbyCategory.Reset();
        if Servicio <> '' then
            UserxbyCategory.SetRange(Departamento, Servicio);
        UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange("Zona Limpieza", ZonaLimpieza);
        UserxbyCategory.SetRange(Supervisor, true);
        UserxbyCategory.SetRange("Copiado en Mail", false);
        UserxbyCategory.SetRange(Responsable);
        If UserxbyCategory.FindFirst() then begin
            Supervisor := UserxbyCategory."User Security ID";
            If Servicio = '' then Servicio := UserxbyCategory.Departamento;
        end else begin
            UserxbyCategory.SetRange("Copiado en Mail");
            If UserxbyCategory.FindFirst() then begin
                Supervisor := UserxbyCategory."User Security ID";
                If Servicio = '' then Servicio := UserxbyCategory.Departamento;
            end else begin
                // Intentar sin filtrar por zona
                UserxbyCategory.Reset();
                UserxbyCategory.SetRange(Departamento, Servicio);
                UserxbyCategory.SetRange("User Task Group Code", Categoria);
                UserxbyCategory.SetRange(Supervisor, true);
                UserxbyCategory.SetRange("Copiado en Mail", false);
                UserxbyCategory.SetRange(Responsable);
                If UserxbyCategory.FindFirst() then begin
                    Supervisor := UserxbyCategory."User Security ID";
                    If Servicio = '' then Servicio := UserxbyCategory.Departamento;
                end else begin
                    UserxbyCategory.SetRange("Copiado en Mail");
                    If UserxbyCategory.FindFirst() then begin
                        Supervisor := UserxbyCategory."User Security ID";
                        If Servicio = '' then Servicio := UserxbyCategory.Departamento;
                    end else begin
                        UserGtaskMalla.SetRange(Departamento);
                        UserGtaskMalla.SetRange(Supervisor, true);
                        UserGtaskMalla.SetRange(Responsable);
                        If UserGtaskMalla.FindFirst() then begin
                            Supervisor := UserGtaskMalla."Id Usuario";
                            If Servicio = '' then Servicio := UserGtaskMalla.Departamento;
                        end;

                    end;
                end;
            end;
        end;

        // Obtener emails
        User.SetRange("User Security ID", Supervisor);
        If User.FindFirst() then begin
            EmailSupervisor := User."Contact Email";
        end;
        User.SetRange("User Security ID", Responsable);
        If User.FindFirst() then begin
            EmailResponsabe := User."Contact Email";
        end;

        // Validar y asignar valores al UserTask
        UserTASK.Validate(Servicio, Servicio);
        UserTASK.Validate(Departamento, Departamento);
        If Categoria <> '' then begin
            UserTask.Validate("Categoría", Categoria);
        end;
        UserTask."Assigned To" := Responsable;
        UserTask."Supervisor" := Supervisor;
        UserTask.Validate("Created By", UserSecurityId());

        // Validaciones y mensajes
        If Categoria <> '' then begin
            UserxbyCategory.Reset();
            UserxbyCategory.SetRange("User Task Group Code", Categoria);
            UserxbyCategory.SetRange(Departamento, Departamento);
            UserxbyCategory.SetRange(Responsable, true);
            If not UserxbyCategory.FindFirst() then
                If IsNullGuid(Responsable) then
                    Message('No se ha encontrado el usuario responsable ( el que se encarga de hacer la tarea ) para la categoría %1 en el Departamento %2', Categoria, Departamento);

            UserxbyCategory.Reset();
            UserxbyCategory.SetRange("User Task Group Code", Categoria);
            UserxbyCategory.SetRange(Supervisor, true);
            If not UserxbyCategory.FindFirst() then
                If IsNullGuid(Supervisor) then
                    Message('No se ha encontrado el usuario supervisor para la categoría %1 en el Departamento %2', Categoria, Servicio);
        end;

        // Obtener lista de correos para copia
        UserxbyCategory.Reset();
        UserxbyCategory.SetRange(Departamento);
        If Categoria <> '' then
            UserxbyCategory.SetRange("User Task Group Code", Categoria);
        UserxbyCategory.SetRange("Zona Limpieza", ZonaLimpieza);
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

    local procedure ParseFechaFromJson(FechaTexto: Text): DateTime
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

    local procedure CrearTareaIncidencia(var rDet: Record Incidencias): Text[30]
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
        Operario: Guid;
        UserTaskGroup: Record "User Task Group Member";
        RecRef: RecordRef;
        Resource: Record Resource;
        Emplazamientos: Record Emplazamientos;
        Imagenes: Record "Imagenes Orden fijación";
        Id_Task: Text[30];
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
        Operario := rDet.Usuario;
        UserTask."Assigned To" := Operario;

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
        rDet."Id_Tarea" := UserTask.ID;
        rDet."Id Tarea Gtask" := Id_Task;
        rDet.Modify();
        exit(Id_Task);
    end;

    procedure CrearTareaIncidencia(
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
            UserTask.Modify();
        end;
        UpdateTaskGtask(UserTask.Id_Tarea, UserTask.ID);
    end;

    local procedure UpdateTaskGtaskBak(Id_Tarea: Text[250]; ID: Integer)
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

    local procedure UpdateTasksFicheros()
    var
        Ficheros: Record Ficheros;

    begin
        Ficheros.SetRange(Proceso, 'UPDATEGTASK');
        Ficheros.SetRange(Procesado, false);
        If Ficheros.FindSet() then begin
            repeat
                UpdateTaskGtask(Ficheros."Nombre fichero", Ficheros."Incoming Entry No.");

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
                    Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
                    EnviaCorreo(Usertask."No.", UserTask.GetDescription(), true, '', false, Ficheros."Nombre fichero", EmailResponsable, ListadeCorreos, EmailSupervisor, '', User."Full Name", false, UserTask.Id_Tarea, false);
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
                EnviaCorreo(Incidencias."No.", Desc + ' - ' + Incidencias.GetWorkDescription(), true, '', false, Incidencias."Descripción",
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
                            RecursoNo := GetRecursoNo(DocumentAttachment, JobsOtrasEmpresas."Empresa Origen");
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

    local procedure GetRecursoNo(var Doc: Record "Document Attachment"; Empresa: Text): Text
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