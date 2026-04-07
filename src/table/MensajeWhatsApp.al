table 7001236 "Mensaje WhatsApp"
{
    Caption = 'Mensaje WhatsApp';
    DataClassification = CustomerContent;
    LookupPageId = "Mensajes WhatsApp";
    DrillDownPageId = "Mensaje WhatsApp Card";

    fields
    {
        field(1; "Id Mensaje WA"; Text[200])
        {
            Caption = 'ID mensaje WhatsApp';
            DataClassification = CustomerContent;
        }
        field(2; "Id Mensaje Original"; Text[200])
        {
            Caption = 'ID mensaje original';
            DataClassification = CustomerContent;
        }
        field(3; "Id Usuario"; Guid)
        {
            Caption = 'Usuario';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Security ID";
        }
        field(10; "Origen Tabla ID"; Integer)
        {
            Caption = 'Origen tabla ID';
            DataClassification = SystemMetadata;
        }
        field(11; "Origen Registro ID"; RecordId)
        {
            Caption = 'Origen registro';
            DataClassification = SystemMetadata;
        }
        field(12; "Texto mensaje"; Text[2048])
        {
            Caption = 'Texto del mensaje';
            DataClassification = CustomerContent;
        }
        field(14; "Nº registro adjuntos"; Integer)
        {
            Caption = 'Nº registro adjuntos';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(15; "No. doc. adjuntos"; Code[20])
        {
            Caption = 'Nº enlace documentos adjuntos';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Respuesta JSON"; Blob)
        {
            Caption = 'Respuesta / cuerpo completo';
            DataClassification = CustomerContent;
        }
        field(30; "Fecha creación"; DateTime)
        {
            Caption = 'Fecha creación';
            DataClassification = SystemMetadata;
        }
        field(40; "Teléfono"; Text[20])
        {
            Caption = 'Teléfono';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
            UserG: Record UsuariosGtask;
            begin
                UserG.Reset();
                UserG.SetRange("Teléfono", CopyStr("Teléfono", 1, MaxStrLen(UserG."Teléfono")));
                if UserG.FindFirst() then
                    "Id Usuario" := UserG."Id Usuario"
                    else begin
                        If CopyStr("Teléfono",1,1)='+' then
                            "Teléfono" := CopyStr("Teléfono",2,MaxStrLen("Teléfono"));
                        if CopyStr("Teléfono",1,2)='34' then
                        begin
                            UserG.Reset();
                            UserG.SetRange("Teléfono", CopyStr("Teléfono",1,10));
                            if UserG.FindFirst() then
                                "Id Usuario" := UserG."Id Usuario"
                                else begin
                                    UserG.Reset();
                                    UserG.SetRange("Teléfono", CopyStr("Teléfono",1,10));
                                end;
                        end;
                    end;

            end;
        }
       
    }

    keys
    {
        key(PK; "Id Mensaje WA")
        {
            Clustered = true;
        }
        key(KeyOrigen; "Origen Tabla ID", "Origen Registro ID")
        {
        }
        key(KeyAdjuntos; "Nº registro adjuntos")
        {
        }
    }

    trigger OnInsert()
    var
        Msg: Record "Mensaje WhatsApp";
        NextN: Integer;
    begin
        if "Nº registro adjuntos" <> 0 then
            exit;
        Msg.LockTable();
        Msg.SetCurrentKey("Nº registro adjuntos");
        Msg.SetFilter("Nº registro adjuntos", '>%1', 0);
        if Msg.FindLast() then
            NextN := Msg."Nº registro adjuntos" + 1
        else
            NextN := 1;
        "Nº registro adjuntos" := NextN;
        SincronizarNoDocAdjuntos();
    end;

    /// <summary>
    /// Asigna Nº registro adjuntos a registros antiguos (0) para enlazar documentos adjuntos.
    /// </summary>
    procedure AssignNroRegistroAdjuntos()
    var
        Msg: Record "Mensaje WhatsApp";
        NextN: Integer;
    begin
        if "Nº registro adjuntos" <> 0 then begin
            if "No. doc. adjuntos" = '' then begin
                SincronizarNoDocAdjuntos();
                Modify(false);
            end;
            exit;
        end;
        Msg.LockTable();
        Msg.SetCurrentKey("Nº registro adjuntos");
        Msg.SetFilter("Nº registro adjuntos", '>%1', 0);
        if Msg.FindLast() then
            NextN := Msg."Nº registro adjuntos" + 1
        else
            NextN := 1;
        "Nº registro adjuntos" := NextN;
        SincronizarNoDocAdjuntos();
        Modify(false);
    end;

    local procedure SincronizarNoDocAdjuntos()
    begin
        if "Nº registro adjuntos" <> 0 then
            "No. doc. adjuntos" := CopyStr(Format("Nº registro adjuntos"), 1, MaxStrLen("No. doc. adjuntos"))
        else
            Clear("No. doc. adjuntos");
    end;
}
