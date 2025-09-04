pageextension 92168 "DocumentAttachmentDetailsExt" extends "Document Attachment Details"
{
    layout
    {
        modify("Attached Date")
        {
            Visible = false;
        }
        addlast(Group)
        {
            field(AttachedDate; Rec."Attached Date")
            {
                ApplicationArea = All;
                Caption = 'Fecha de Adjunto';
                ToolTip = 'Muestra la fecha de adjunto de este archivo';
            }
            field("Recurso No"; RecursoNo)
            {
                ApplicationArea = All;
                Caption = 'Número de Recurso';
                ToolTip = 'Muestra el número de recurso asociado a este archivo adjunto';
                Visible = IsRecursoVisible;
                trigger OnValidate()
                begin
                    SetRecursoNo(RecursoNo);
                end;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        if IsRecursoVisible then
            RecursoNo := GetRecursoNo();
    end;

    var
        IsRecursoVisible: Boolean;
        RecursoNo: Text;

    local procedure GetRecursoNo(): Text
    var
        DocumentAttachment: Record "Document Attachment";
        Reserva: Record Reserva;
        FileManager: Codeunit "File Management";
    begin
        If Rec."Table ID" in [Database::"User Task", Database::job] then begin
            DocumentAttachment.SetRange("Table ID", Database::"Orden fijación");
            //DocumentAttachment.SetRange("No.", Rec."No.");
            if Rec.ID_Doc <> 0 Then
                DocumentAttachment.SetRange("ID_Doc", Rec."ID_Doc")
            else
                DocumentAttachment.SetFilter("Line No.", '>%1', 10000);
            DocumentAttachment.SetRange("File Name", Rec."File Name");
            if DocumentAttachment.FindFirst() then begin
                if (Rec."File Extension" = '') or (Rec."Attached Date" = 0DT) Then Begin
                    if Rec."Attached Date" = 0DT Then Rec."Attached Date" := Rec.SystemCreatedAt;
                    Rec."File Extension" := FileManager.GetExtension(Rec."File Name");
                    Rec.Modify();
                end;
                if Reserva.Get(DocumentAttachment."Line No.") then
                    exit(Reserva."Nº Recurso");
            end;


        end;
        exit('');

    end;

    local procedure SetRecursoNo(RecursoNo: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachment2: Record "Document Attachment";
        Reserva: Record Reserva;
    begin
        if Rec."Table ID" in [Database::"User Task", Database::job] then begin
            Reserva.SetRange("Nº Recurso", RecursoNo);
            Reserva.SetRange("Nº Proyecto", Rec."No.");
            if Reserva.FindFirst() then begin
                DocumentAttachment.SetRange("Table ID", Database::"Orden fijación");
                if Rec.ID_Doc <> 0 Then
                    DocumentAttachment.SetRange("ID_Doc", Rec.ID_Doc);
                DocumentAttachment.SetRange("Line No.", Reserva."Nº Reserva");
                DocumentAttachment.SetRange("File Name", Rec."File Name");
                if Not DocumentAttachment.FindFirst() then begin
                    DocumentAttachment2 := Rec;
                    DocumentAttachment2."Line No." := Reserva."Nº Reserva";
                    DocumentAttachment2."Table ID" := Database::"Orden fijación";

                    DocumentAttachment2.Insert();
                end;
            end;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        IsRecursoVisible := ((Rec."Table ID" = Database::Job) or (Rec."Table ID" = Database::"User Task"));
        If IsRecursoVisible then
            RecursoNo := GetRecursoNo();
    end;
}