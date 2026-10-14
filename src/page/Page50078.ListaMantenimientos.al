page 50078 "Lista Mantenimientos"
{
    PageType = List;
    Caption = 'Lista Mantenimientos';
    SourceTable = "Incidencias";
    ApplicationArea = All;
    UsageCategory = Documents;
    CardPageId = "Ordenes Trabajo";
    SourceTableView = where("SubTipo Incidencia" = const(Mantenimiento), "Tipo Intervención" = const(Preventivo));

    layout
    {
        area(content)
        {
            repeater(Detalle)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        Gtask: Codeunit Gtask;
                    begin
                        Gtask.AsegurarParteMantenimiento(Rec);
                        Commit();
                        Page.RunModal(Page::"Ordenes Trabajo", Rec);
                    end;
                }

                field("Descripción"; Rec."Descripción") { ApplicationArea = All; }
                field(Recurso; Rec.Recurso) { ApplicationArea = All; }
                field("Nombre Recurso"; Rec.NombreElemento()) { ApplicationArea = All; }
                field("Dirección"; Rec.Dirección) { ApplicationArea = All; }
                field("PuntoX"; Rec.PuntoX) { ApplicationArea = All; }
                field("PuntoY"; Rec.PuntoY) { ApplicationArea = All; }
                field("Tipo Incidencia"; Rec."Tipo Incidencia") { ApplicationArea = All; }
                field("SubTipo Incidencia"; Rec."SubTipo Incidencia") { ApplicationArea = All; }
                field("Tipo Intervención"; Rec."Tipo Intervención") { ApplicationArea = All; }
                field("Fecha Hora"; Rec."FechaHora") { ApplicationArea = All; }
                field("Estado"; Rec."Estado") { ApplicationArea = All; }
                field("URL Primera Imagen"; UrlPrimeraImagen)
                {
                    Caption = 'URL Primera Imagen';
                    ApplicationArea = All;
                    ToolTip = 'URL de la primera imagen asociada a esta incidencia';
                    Editable = false;
                }
                field("Usuario"; NombreUsuario)
                {
                    Caption = 'Usuario';
                    ApplicationArea = All;
                    ToolTip = 'ID del usuario que creó la incidencia';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Usuario: Record UsuariosGtask;
                    begin
                        If Page.RunModal(Page::UsuariosGtask, Usuario) = Action::LookupOK then begin
                            NombreUsuario := Usuario.Nombre + ' ' + Usuario.Apellido;
                            Rec.Usuario := Usuario."Id Usuario";
                            Rec.Modify();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        Usuario: Record UsuariosGtask;
                    begin
                        Usuario.SetRange(Nombre, NombreUsuario);
                        If Usuario.FindFirst() then begin
                            NombreUsuario := Usuario.Nombre + ' ' + Usuario.Apellido;
                            Rec.Usuario := Usuario."Id Usuario";
                            Rec.Modify();
                        end;
                    end;
                }
                field(Id_Uduario_Gtask; Rec.ID_UsuarioGtask(Rec.Usuario))
                {
                    Caption = 'ID Usuario Gtask';
                    ApplicationArea = All;
                    ToolTip = 'ID del usuario que creó la incidencia';
                    Editable = false;
                    Enabled = false;
                }
                field("Usuario Asignado"; NombreUsuarioAsignado)
                {
                    Caption = 'Usuario Asignado';
                    ApplicationArea = All;
                    ToolTip = 'ID del usuario que asignó la incidencia';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Usuario: Record UsuariosGtask;
                    begin
                        If Page.RunModal(Page::UsuariosGtask, Usuario) = Action::LookupOK then begin
                            NombreUsuarioAsignado := Usuario.Nombre + ' ' + Usuario.Apellido;
                            Rec."Usuario Asignado" := Usuario."Id Usuario";
                            Rec.Modify();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        Usuario: Record UsuariosGtask;
                    begin
                        Usuario.SetRange(Nombre, NombreUsuario);
                        If Usuario.FindFirst() then begin
                            NombreUsuarioAsignado := Usuario.Nombre + ' ' + Usuario.Apellido;
                            Rec."Usuario Asignado" := Usuario."Id Usuario";
                            Rec.Modify();
                        end;
                    end;
                }
                field(Id_Uduario_Gtask_Asignado; Rec.ID_UsuarioGtask(Rec."Usuario Asignado"))
                {
                    Caption = 'ID Usuario Gtask Asignado';
                    ApplicationArea = All;
                    ToolTip = 'ID del usuario que asignó la incidencia';
                    Editable = false;
                    Enabled = false;
                }
                field(Id_Gtask; Rec.Id_Gtask)
                {
                    Caption = 'ID Gtask';
                    ApplicationArea = All;
                    ToolTip = 'ID de la incidencia en Gtask';
                    Editable = false;
                    Enabled = false;
                }
                field("ID_Tarea_Gtask"; Rec."ID Tarea Gtask")
                {
                    Caption = 'ID Tarea Gtask';
                    ApplicationArea = All;
                    ToolTip = 'ID de la tarea en Gtask';
                    Editable = false;
                    Enabled = false;
                }
                field("Comunicado_por_EMT"; Rec."Comunicado por EMT")
                {
                    Caption = 'Comunicado por EMT';
                    ApplicationArea = All;
                    ToolTip = 'Indica si la incidencia fue comunicada por EMT';
                    Editable = false;
                    Enabled = false;
                }
            }

        }

    }
    actions
    {
        area(Processing)
        {
            action(Editar)
            {
                ApplicationArea = All;
                Caption = 'Editar';
                Image = Edit;
                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.AsegurarParteMantenimiento(Rec);
                    Commit();
                    Page.RunModal(Page::"Ordenes Trabajo", Rec);
                end;
            }

            action(MensajesWhatsAppLista)
            {
                ApplicationArea = All;
                Caption = 'Mensajes WhatsApp';
                Image = SendTo;
                ToolTip = 'Abre los mensajes de WhatsApp vinculados a la incidencia seleccionada.';
                trigger OnAction()
                var
                    Procesos_GTask: Codeunit Procesos_GTask;
                begin
                    Procesos_GTask.AbrirListaMensajesWhatsAppIncidencia(Rec);
                end;
            }


        }

        area(Promoted)
        {

            actionref(EditarRef; Editar) { }

            actionref(MensajesWhatsAppListaPromoted; MensajesWhatsAppLista) { }
        }
    }

    var
        NombreUsuario: Text;
        NombreUsuarioAsignado: Text;
        UrlPrimeraImagen: Text;



    trigger OnAfterGetRecord()
    var
        UsuarioGtask: Record UsuariosGtask;
    begin
        NombreUsuario := '';
        If not IsNullGuid(Rec.Usuario) then begin
            UsuarioGtask.SetRange("Id Usuario", Rec.Usuario);
            If UsuarioGtask.FindFirst() then begin
                NombreUsuario := UsuarioGtask.Nombre + ' ' + UsuarioGtask.Apellido;
            end;
        end;
        NombreUsuarioAsignado := '';
        If not IsNullGuid(Rec."Usuario Asignado") then begin
            UsuarioGtask.SetRange("Id Usuario", Rec."Usuario Asignado");
            If UsuarioGtask.FindFirst() then begin
                NombreUsuarioAsignado := UsuarioGtask.Nombre + ' ' + UsuarioGtask.Apellido;
            end;
        end;
        UrlPrimeraImagen := GetUrlPrimeraImagen();
    end;

    local procedure GetUrlPrimeraImagen(): Text
    var
        ImagenesOrdenFijacion: Record "Imagenes Orden fijación";
    begin
        if Rec."Nº Orden" = 0 then
            exit('');

        ImagenesOrdenFijacion.SetRange("Nº Orden", Rec."Nº Orden");
        ImagenesOrdenFijacion.SetRange("Es Incidencia", true);
        ImagenesOrdenFijacion.SetFilter(Url, '<>%1', '');
        ImagenesOrdenFijacion.SetCurrentKey("Nº Orden", "Nº Imagen");
        if ImagenesOrdenFijacion.FindFirst() then
            exit(ImagenesOrdenFijacion.Url)
        else
            exit('');
    end;
}
