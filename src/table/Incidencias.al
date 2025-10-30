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
            TableRelation = Resource;
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
}