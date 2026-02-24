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

        field(9; Recurso; Code[20])
        {
            TableRelation = if ("Tipo Elemento" = const(Recurso)) Resource else if ("Tipo Elemento" = const(Parada)) "Emplazamientos"."Nº Emplazamiento" where("Tipo Emplazamiento" = const(Opis));
            ValidateTableRelation = false;
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
        rSelf.SetCurrentKey("Nº Orden");
        if rSelf.FindLast() then
            Orden := rSelf."Nº Orden" + 1
        else
            Orden := 1;
        "Nº Orden" := Orden;
        if "No." = '' then begin
            JobsSetup.Get();
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

    procedure ID_UsuarioGtask(Usuario: Guid): Text
    var
        UsuarioGtask: Record UsuariosGtask;
    begin
        If not IsNullGuid(Rec.Usuario) then begin
            UsuarioGtask.SetRange("Id Usuario", Rec.Usuario);
            If UsuarioGtask.FindFirst() then begin
                Exit(UsuarioGtask."Id Gtask");
            end;
        end;
        Exit('');
    end;

    internal procedure NombreUsuario(): Text
    var
        UsuarioGtask: Record UsuariosGtask;
    begin
        If not IsNullGuid(Rec.Usuario) then begin
            UsuarioGtask.SetRange("Id Usuario", Rec.Usuario);
            If UsuarioGtask.FindFirst() then begin
                Exit(UsuarioGtask.Nombre);
            end;
        end;
        Exit('');
    end;

    internal procedure NombreElemento(): Variant
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
        If Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, Rec.Recurso) then
            exit(Emplazamientos."Descripción");
        Exit('Elemento erroneo');
    end;
}