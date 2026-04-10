table 7001250 "Incidencias"
{
    DataClassification = ToBeClassified;
    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Descripción"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Fecha"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(4; "Estado"; Option)
        {
            OptionMembers = Abierta,EnProgreso,Cerrada;
            DataClassification = CustomerContent;
        }
        field(5; "Nº Orden"; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(6; "No. Series"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(7; Id_Gtask; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(8; "Tipo Incidencia"; Enum "Tipo Incidencia")
        {

        }
        field(26; "SubTipo Incidencia"; Enum "SubTipo Incidencia")
        {

            DataClassification = CustomerContent;
        }
        field(9; Recurso; Code[20])
        {
            TableRelation = if ("Tipo Elemento" = const(Recurso)) Resource else if ("Tipo Elemento" = const(Parada)) "Emplazamientos"."Nº Emplazamiento" where("Tipo Emplazamiento" = const(Opis));
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                Resource: Record Resource;
                ParadasBus: Record Emplazamientos;
            begin
                if "Tipo Elemento" = "Tipo Elemento"::Recurso then begin
                    If Page.RunModal(Page::"Resource List", Resource) = Action::LookupOK then
                        Recurso := Resource."No.";

                end else begin
                    If Page.RunModal(Page::"Paradas Bus", ParadasBus) = Action::LookupOK then begin
                        Recurso := ParadasBus."Nº Emplazamiento";
                    end;
                end;
            end;
        }
        field(10; "Tipo Elemento"; Option)
        {
            OptionMembers = Recurso,Parada;
            DataClassification = CustomerContent;
        }
        //FechaHora
        field(11; "FechaHora"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(12; "Work Description"; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(14; Usuario; Guid)
        {
            TableRelation = UsuariosGtask."Id Usuario";
            DataClassification = CustomerContent;
        }
        field(15; "ID Tarea Gtask"; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(16; Empresa; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(17; Id_Tarea; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(18; "Enviar Correo"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        //Fecuencia tipo Text
        field(19; "Frecuencia"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        //Es Peticion
        field(20; "Es Peticion"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        //Comunicado por EMT
        field(21; "Comunicado por EMT"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        //fecha de actuacion
        field(22; "Fecha Actuacion"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(23; "Usuario Asignado"; Guid)
        {
            TableRelation = UsuariosGtask."Id Usuario";
            DataClassification = CustomerContent;
        }
        //Userr Task Group
        field(24; "User Task Group"; Code[20])
        {
            TableRelation = "User Task Group";
            DataClassification = CustomerContent;
        }
        field(25; "Id Mensaje WA"; Text[200])
        {
            Caption = 'ID último mensaje WhatsApp';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Nº Orden")
        {
        }
    }
    trigger OnInsert()
    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Codeunit "No. Series";
        rSelf: Record "Incidencias";
        Orden: Integer;

    begin
        // Nº Orden único en toda la tabla (incidencias y peticiones): las imágenes se enlazan por este valor.
        rSelf.SetCurrentKey("Nº Orden");
        if rSelf.FindLast() then
            Orden := rSelf."Nº Orden" + 1
        else
            Orden := 1;
        "Nº Orden" := Orden;
        if "No." = '' then begin
            JobsSetup.Get();
            if "Es Peticion" then begin
                if JobsSetup."Peticiones Nos." <> '' then
                    "No. Series" := JobsSetup."Peticiones Nos."
                else
                    "No. Series" := JobsSetup."Incidencias Nos.";
            end else
                "No. Series" := JobsSetup."Incidencias Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnDelete()
    var
        UserTask: Record "User Task";
        Imagenes: Record "Imagenes Orden fijación";
        Gtask: Codeunit Gtask;
    begin


        Gtask.DeleteTarea("ID Tarea Gtask");
        If UserTask.Get(Id_Tarea) then
            UserTask.Delete();
        Imagenes.SetRange("Nº Orden", "Nº Orden");
        Imagenes.SetRange("Es Incidencia", true);
        Imagenes.Deleteall(true);
        Gtask.DeleteIncidencia(Id_Gtask);//Falta Delete incidencias
    end;

    procedure SetWorkDescription(WorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        CalcFields("Work Description");
        Clear("Work Description");
        "Work Description".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(WorkDescription);
        Modify();
    end;

    // procedure SetWorkTextDescription(WorkDescription: Text)
    // var
    //     OutStream: OutStream;
    // begin
    //     Clear("Work Description");
    //     "Work Description".CreateOutStream(OutStream);
    //     OutStream.WriteText(WorkDescription);
    //     Modify();
    // end;

    [TryFunction]
    local procedure TryGetWorkDescription(var workDescription: Text)
    var
        InStream: InStream;
        WorkDescriptionText: Text;
        TypeHelper: Codeunit "Type Helper";
    begin
        Clear(WorkDescriptionText);
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(WorkDescriptionText);
        workDescription := WorkDescriptionText;

    end;

    procedure GetWorkDescription(): Text
    var
        InStream: InStream;
        WorkDescriptionText: Text;
        TypeHelper: Codeunit "Type Helper";
    begin
        if TryGetWorkDescription(WorkDescriptionText) then
            exit(WorkDescriptionText);
        exit('');
    end;

    procedure ID_UsuarioGtask(pUsuario: Guid): Text
    var
        UsuarioGtask: Record UsuariosGtask;
    begin
        If not IsNullGuid(pUsuario) then begin
            UsuarioGtask.SetRange("Id Usuario", pUsuario);
            If UsuarioGtask.FindFirst() then begin
                Exit(UsuarioGtask."Id Gtask");
            end;
        end;
        Exit('');
    end;

    internal procedure NombreUsuario(pUsuario: Guid): Text
    var
        UsuarioGtask: Record UsuariosGtask;
    begin
        If not IsNullGuid(pUsuario) then begin
            UsuarioGtask.SetRange("Id Usuario", pUsuario);
            If UsuarioGtask.FindFirst() then begin
                Exit(UsuarioGtask.Nombre);
            end;
        end;
        Exit('');
    end;



    internal procedure NombreElemento(): Text
    var
        Emplazamientos: Record "Emplazamientos";
        Resource: Record Resource;
        Empresas: Record "Company";
    begin
        if "Tipo Elemento" = "Tipo Elemento"::Recurso then begin
            if Resource.Get(Rec.Recurso) then
                exit(Resource.Name);
            If Empresas.FindFirst() then begin
                repeat
                    Resource.ChangeCompany(Empresas.Name);
                    if Resource.Get(Rec.Recurso) then
                        exit(Resource.Name);
                until Empresas.Next() = 0;
            end;
        end;
        If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, Recurso) then
            exit(Emplazamientos."Descripción");
        Exit('Elemento erroneo');
    end;

    internal procedure PuntoX(): Decimal
    var
        Emplazamientos: Record "Emplazamientos";
        Resource: Record Resource;
    begin
        if "Tipo Elemento" = "Tipo Elemento"::Recurso then begin
            if Resource.Get(Rec.Recurso) then
                exit(Resource.PuntoX);
        end;
        If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, Rec.Recurso) then
            exit(Emplazamientos.PuntoX);
        Exit(0);
    end;

    internal procedure PuntoY(): Decimal
    var
        Emplazamientos: Record "Emplazamientos";
        Resource: Record Resource;
    begin
        if "Tipo Elemento" = "Tipo Elemento"::Recurso then begin
            if Resource.Get(Rec.Recurso) then
                exit(Resource.PuntoY);
        end;
        If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, Rec.Recurso) then
            exit(Emplazamientos.PuntoY);
        Exit(0);
    end;

    internal procedure Dirección(): Text
    var
        Emplazamientos: Record "Emplazamientos";
        Resource: Record Resource;
    begin
        if "Tipo Elemento" = "Tipo Elemento"::Recurso then begin
            if Resource.Get(Rec.Recurso) then
                exit(Resource.Name);
        end;
        If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, Rec.Recurso) then
            exit(Emplazamientos."Ubicación");
        Exit('');
    end;
}