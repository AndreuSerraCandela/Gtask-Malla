page 50126 "Mensajes WhatsApp"
{
    Caption = 'Mensajes WhatsApp';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Mensaje WhatsApp";
    CardPageId = "Mensaje WhatsApp Card";
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Rep)
            {
                field("Fecha creación"; Rec."Fecha creación") { ApplicationArea = All; }
                field("Teléfono"; Rec."Teléfono") { ApplicationArea = All; }
                field("Texto mensaje"; Rec."Texto mensaje")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field("Id Mensaje WA"; Rec."Id Mensaje WA") { ApplicationArea = All; }
                field("Id Mensaje Original"; Rec."Id Mensaje Original") { ApplicationArea = All; }
                //field("Origen Tabla ID"; Rec."Origen Tabla ID") { ApplicationArea = All; }
                field("Usuario"; NombreUsuario(Rec."Id Usuario"))
                {
                    ApplicationArea = All;
                    Caption = 'Usuario';
                    ToolTip = 'ID del usuario que creó el mensaje';

                }
            }
        }
        area(factboxes)
        {
            part(Adjuntos; "Doc. Attachment List FactBox")
            {
                ApplicationArea = All;
                Caption = 'Documentos adjuntos';
                SubPageLink = "No." = field("No. doc. adjuntos"), "Table ID" = const(Database::"Mensaje WhatsApp");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DescargarMedioMensajeOriginal)
            {
                ApplicationArea = All;
                Caption = 'Descargar imagen del mensaje original';
                Image = Import;
                ToolTip = 'Copia documentos adjuntos del mensaje WhatsApp citado (Id mensaje original) si ese registro ya existe en BC con adjuntos.';
                Enabled = Rec."Id Mensaje Original" <> '';

                trigger OnAction()
                var
                    Procesos_GTask: Codeunit Procesos_GTask;
                begin
                    CurrPage.SaveRecord();
                    Procesos_GTask.DescargarMediosMensajeOrigen(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
    local procedure NombreUsuario(IdUsuario: Guid): Text
    var
        Usuario: Record UsuariosGtask;
    begin
        Usuario.Reset();
        Usuario.SetRange("Id Usuario", IdUsuario);
        if Usuario.FindFirst() then
            exit(Usuario.Nombre);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if (Rec."Nº registro adjuntos" = 0) and (Rec."Id Mensaje WA" <> '') then
            Rec.AssignNroRegistroAdjuntos();

    end;
}
