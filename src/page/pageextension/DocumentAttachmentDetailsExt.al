pageextension 92168 "DocumentAttachmentDetailsExt" extends "Document Attachment Details"
{
    layout
    {
        addlast(Group)
        {
            field(RecursoNo; GetRecursoNo())
            {
                ApplicationArea = All;
                Caption = 'Número de Recurso';
                ToolTip = 'Muestra el número de recurso asociado a este archivo adjunto';
                Visible = IsRecursoVisible;
            }
        }
    }

    var
        IsRecursoVisible: Boolean;

    local procedure GetRecursoNo(): Text
    var
        DocumentAttachment: Record "Document Attachment";
        Reserva: Record Reserva;
    begin
        If Rec."Table ID" in [Database::"User Task", Database::job] then begin
            DocumentAttachment.SetRange("Table ID", Database::"Orden fijación");
            //DocumentAttachment.SetRange("No.", Rec."No.");
            DocumentAttachment.SetRange("ID_Doc", Rec."ID_Doc");
            DocumentAttachment.SetRange("File Name", Rec."File Name");
            if DocumentAttachment.FindFirst() then begin
                if Reserva.Get(DocumentAttachment."Line No.") then
                    exit(Reserva."Nº Recurso");
            end;

        end;
        exit('');

    end;

    trigger OnAfterGetRecord()
    begin
        IsRecursoVisible := ((Rec."Table ID" = Database::Job) or (Rec."Table ID" = Database::"User Task"));
    end;
}