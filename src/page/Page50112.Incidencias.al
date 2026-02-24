page 50112 "Incidencias Taller"
{
    PageType = Card;
    SourceTable = "Incidencias";
    //ApplicationArea = All;
    //UsageCategory = Documents;
    layout
    {
        area(content)
        {
            group(DescripciónAmpliada)
            {
                ShowCaption = false;

                field("Descripción Ampliada"; Description)
                {
                    MultiLine = true;
                    Caption = 'Descripción Ampliada';

                    ExtendedDatatype = RichContent;
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec.SetWorkDescription(description);
                    end;
                }
            }
            group(General)
            {

                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec."Descripción")
                {
                    ApplicationArea = All;
                    Caption = 'Descripción';
                    ToolTip = 'Descripción de la incidencia';
                    Editable = false;
                }

                field("Recurso/Parada"; Rec.Recurso) { ApplicationArea = All; }
                field("Tipo Incidencia"; Rec."Tipo Incidencia") { ApplicationArea = All; }
                field("Fecha Hora"; Rec."FechaHora") { ApplicationArea = All; }
                field("Estado"; Rec."Estado") { ApplicationArea = All; }
                //comunicado por EMT
                field("Comunicado por EMT"; Rec."Comunicado por EMT") { ApplicationArea = All; }
                //fecha de actuacion
                field("Fecha Actuacion"; Rec."Fecha Actuacion") { ApplicationArea = All; }
                //frecuencia
                field("Frecuencia"; Rec."Frecuencia") { ApplicationArea = All; }
                //es peticion
                field("Es Peticion"; Rec."Es Peticion") { ApplicationArea = All; }
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
                            NombreUsuario := Usuario.Nombre;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        Usuario: Record UsuariosGtask;
                    begin
                        Usuario.SetRange(Nombre, NombreUsuario);
                        If Usuario.FindFirst() then begin
                            Rec.Usuario := Usuario."Id Usuario";
                            Rec.Modify();
                        end;
                    end;
                }

            }
            part(ImagenesAsociadas; "Imagenes Orden fijacion")
            {
                Caption = 'Imagenes Asociadas';
                ApplicationArea = All;
                SubPageLink = "Nº Orden" = field("Nº Orden");
                SubPageView = where("Es Incidencia" = const(true), "Nº Orden" = filter(<> 0));
                Visible = true;
            }
            part(ImagenesNoAsociadas; "Imagenes Orden fijacion")
            {
                Caption = 'Imagenes No Asociadas';
                ApplicationArea = All;
                SubPageLink = "Nº Orden" = const(0);
                SubPageView = where("Es Incidencia" = const(true));
                Visible = true;
            }
        }
        area(factboxes)
        {
            part("Asociadas"; "Ocr Viewer Part")
            {
                ApplicationArea = All;
                Provider = ImagenesAsociadas;
                SubPageLink = "Nº Orden" = field("Nº Orden"), "Nº Imagen" = field("Nº Imagen");

            }
            part("No Asociadas"; "Ocr Viewer Part")
            {
                ApplicationArea = All;
                Provider = ImagenesNoAsociadas;
                SubPageLink = "Nº Orden" = field("Nº Orden"), "Nº Imagen" = field("Nº Imagen");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Restaurar Incidencia")
            {
                ApplicationArea = All;
                Caption = 'Restaurar Incidencia';
                Image = Restore;
                trigger OnAction()
                var
                    rDet: Record "Incidencias";
                    OrdenFijacion: Record "Cab Orden fijación";
                begin
                    //Crea Orden fijación si no existe
                    If not OrdenFijacion.Get(Rec."Nº Orden") then begin
                        OrdenFijacion.Init();
                        OrdenFijacion."Nº Orden" := Rec."Nº Orden";
                        OrdenFijacion.Insert();
                    end;
                end;
            }
            action("Asignar Imagen a la Incidencia")
            {
                ApplicationArea = All;
                Caption = 'Asignar Imagen a la Incidencia';
                Image = Picture;
                trigger OnAction()
                var
                    rImagenesOrdenFijacion: Record "Imagenes Orden fijación";
                    rImagenesOrdenFijaciontemp: Record "Imagenes Orden fijación" temporary;
                    rDet: Record "Incidencias";

                begin
                    rDet.Get(Rec."No.");
                    CurrPage.ImagenesNoAsociadas.Page.SetSelectionFilter(rImagenesOrdenFijacion);
                    if rImagenesOrdenFijacion.FindSet() then
                        repeat
                            rImagenesOrdenFijaciontemp := rImagenesOrdenFijacion;
                            rImagenesOrdenFijaciontemp.Insert();
                            rImagenesOrdenFijacion.Delete();
                        until rImagenesOrdenFijacion.Next() = 0;
                    if rImagenesOrdenFijaciontemp.FindSet() then
                        repeat
                            rImagenesOrdenFijacion := rImagenesOrdenFijaciontemp;
                            rDet.TestField("Nº Orden");
                            rImagenesOrdenFijacion."Nº Orden" := rDet."Nº Orden";
                            rImagenesOrdenFijacion.Insert();
                        until rImagenesOrdenFijaciontemp.Next() = 0;
                end;

            }
            action("Desasignar Imagen de la Incidencia")
            {
                ApplicationArea = All;
                Caption = 'Desasignar Imagen de la Incidencia';
                Image = Delete;
                trigger OnAction()
                var
                    rImagenesOrdenFijacion: Record "Imagenes Orden fijación";
                    rDet: Record "Incidencias";

                begin
                    rDet.Get(Rec."No.");
                    CurrPage.ImagenesAsociadas.Page.GetRecord(rImagenesOrdenFijacion);
                    rImagenesOrdenFijacion.ModifyAll("Nº Orden", 0);
                end;

            }
            action("Crear Incidencia")
            {
                ApplicationArea = All;
                Caption = 'Crear Incidencia Gtask';
                Image = Create;
                trigger OnAction()
                var
                    rDet: Record "Incidencias";
                    Gtask: Codeunit "Gtask";
                begin
                    rDet.Get(Rec."No.");
                    Gtask.CreateIncidencia(rDet);
                end;

            }
            action("Procesar Imagen con LM Studio")
            {
                ApplicationArea = All;
                Caption = 'Procesar Imagen con LM Studio';
                Image = Picture;
                ToolTip = 'Analiza la imagen seleccionada con LM Studio para extraer número de parada y descripción de la incidencia';

                trigger OnAction()
                var
                    rImagenesOrdenFijacion: Record "Imagenes Orden fijación";
                    Gtask: Codeunit GTask;
                    Procesos_GTask: Codeunit Procesos_GTask;
                    ImageBase64: Text;
                    ResponseJson: Text;
                    JsonResponse: JsonObject;
                    JsonCampo: JsonToken;
                    StopNumber: Text;
                    Description: Text;
                    Resource: Record Resource;
                    ParaDasBus: Record "Emplazamientos";
                    ResourceCode: Code[20];
                    Success: Boolean;
                    ErrorMessage: Text;
                    Control: Codeunit "Controlprocesos";
                    Stop: Boolean;
                begin
                    // Intentar obtener la imagen de las asociadas primero
                    Clear(rImagenesOrdenFijacion);
                    CurrPage.ImagenesAsociadas.Page.GetRecord(rImagenesOrdenFijacion);
                    if rImagenesOrdenFijacion."Nº Imagen" = 0 then begin
                        // Si no hay en asociadas, intentar en no asociadas
                        Clear(rImagenesOrdenFijacion);
                        CurrPage.ImagenesNoAsociadas.Page.GetRecord(rImagenesOrdenFijacion);
                        if rImagenesOrdenFijacion."Nº Imagen" = 0 then begin
                            Message('Por favor, seleccione una imagen para procesar.');
                            exit;
                        end;
                    end;

                    // Verificar que la imagen tiene URL
                    if rImagenesOrdenFijacion.Url = '' then begin
                        Message('La imagen seleccionada no tiene URL.');
                        exit;
                    end;

                    // Convertir la imagen a base64
#If CLEAN27
                    ImageBase64 := Control.ToBase64StringOcr(rImagenesOrdenFijacion.Url);
#else
                    ImageBase64 := rImagenesOrdenFijacion.ToBase64StringOcr(rImagenesOrdenFijacion.Url);
#endif

                    if ImageBase64 = '' then begin
                        Message('No se pudo convertir la imagen a base64.');
                        exit;
                    end;

                    // Llamar a la función de LM Studio
                    ResponseJson := Procesos_GTask.ProcessImageWithLMStudio(ImageBase64);

                    // Procesar la respuesta
                    Clear(JsonResponse);
                    if not JsonResponse.ReadFrom(ResponseJson) then begin
                        Message('Error al procesar la respuesta de LM Studio.');
                        exit;
                    end;

                    // Verificar si fue exitoso
                    if JsonResponse.Get('success', JsonCampo) then
                        Success := JsonCampo.AsValue().AsBoolean()
                    else
                        Success := false;

                    if not Success then begin
                        if JsonResponse.Get('error', JsonCampo) then
                            ErrorMessage := JsonCampo.AsValue().AsText()
                        else
                            ErrorMessage := 'Error desconocido al procesar la imagen.';
                        Message('Error: %1', ErrorMessage);
                        exit;
                    end;

                    // Extraer número de parada
                    if JsonResponse.Get('stop_number', JsonCampo) then begin
                        StopNumber := JsonCampo.AsValue().AsText();
                        if (StopNumber <> '') and (StopNumber <> 'null') then begin
                            // Buscar el recurso por el número de parada
                            // El formato puede ser P123 o PARADA_P123
                            ResourceCode := StopNumber;
                            if CopyStr(ResourceCode, 1, 7) = 'PARADA_' then begin
                                ResourceCode := CopyStr(ResourceCode, 8);
                                Stop := True;
                            end;
                            if CopyStr(ResourceCode, 1, 1) = 'P' then begin
                                ResourceCode := CopyStr(ResourceCode, 2);
                                Stop := True;
                            end;


                            // Buscar el recurso
                            If Stop then begin
                                If ParaDasBus.Get(ParaDasBus."Tipo Emplazamiento"::Opis, ResourceCode) then begin
                                    Rec.Recurso := ParaDasBus."Nº Emplazamiento";
                                    Rec."Tipo Elemento" := Rec."Tipo Elemento"::Parada;
                                    Rec.Modify();
                                end else begin
                                    Message('Número de parada encontrado: %1, pero no se encontró la parada correspondiente.', StopNumber);
                                end;
                            end else begin
                                if Resource.Get(ResourceCode) then begin
                                    Rec.Recurso := ResourceCode;
                                    Rec."Tipo Elemento" := Rec."Tipo Elemento"::Recurso;
                                    Rec.Modify();
                                end else begin
                                    // Intentar buscar como parada
                                    If ParaDasBus.Get(ParaDasBus."Tipo Emplazamiento"::Opis, ResourceCode) then begin
                                        Rec.Recurso := ParaDasBus."Nº Emplazamiento";
                                        Rec."Tipo Elemento" := Rec."Tipo Elemento"::Parada;
                                        Rec.Modify();
                                    end else begin
                                        Message('Número de parada, ni como recurso ni como parada encontrado: %1,', StopNumber);
                                    end;
                                end;
                            end;
                        end;
                    end;

                    // Extraer descripción
                    if JsonResponse.Get('description', JsonCampo) then begin
                        Description := JsonCampo.AsValue().AsText();
                        if (Description <> '') and (Description <> 'null') and (Description <> 'Sin incidencia visible') then begin
                            if StrLen(Description) > MaxStrLen(Rec."Descripción") then
                                Description := CopyStr(Description, 1, MaxStrLen(Rec."Descripción"));
                            Rec."Descripción" := Description;
                            Rec.Modify();
                        end;
                    end;

                    Message('Imagen procesada correctamente.\Número de parada: %1\Descripción: %2', StopNumber, Description);
                end;
            }


        }

        area(Promoted)
        {
            actionref(AsignarImagenaLineas; "Asignar Imagen a la Incidencia")

            {

            }
            actionref(DesasignarImagenaLineas; "Desasignar Imagen de la Incidencia")
            {

            }
            actionref(CrearIncidencia; "Crear Incidencia") { }
        }
    }
    trigger OnOpenPage()
    begin
        CurrPage.ImagenesNoAsociadas.Page.MarcaIncidencia();

    end;

    trigger OnAfterGetRecord()
    var
        Usuario: Record UsuariosGtask;
    begin
        Description := Rec.GetWorkDescription();
        If not IsNullGuid(Rec.Usuario) then begin
            Usuario.SetRange("Id Usuario", Rec.Usuario);
            If Usuario.FindFirst() then begin
                NombreUsuario := Usuario.Nombre;
            end;
        end;

    end;

    var
        Description: Text;
        NombreUsuario: Text;

}
page 50117 "Lista Incidencias Taller"
{
    PageType = List;
    SourceTable = "Incidencias";
    CardPageId = "Incidencias Taller";
    ApplicationArea = All;
    UsageCategory = Documents;
    layout
    {
        area(content)
        {
            repeater(Detalle)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Descripción"; Rec."Descripción") { ApplicationArea = All; }
                field(Recurso; Rec.Recurso) { ApplicationArea = All; }
                field("Tipo Incidencia"; Rec."Tipo Incidencia") { ApplicationArea = All; }
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
                            NombreUsuario := Usuario.Nombre;
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
                            NombreUsuario := Usuario.Nombre;
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


            }

        }

    }
    actions
    {
        area(Processing)
        {
            action("Cerrar Incidencia")
            {
                ApplicationArea = All;
                Caption = 'Cerrar Incidencia Gtask';
                Image = Close;
                trigger OnAction()
                var
                    rDet: Record "Incidencias";
                    Gtask: Codeunit "Gtask";
                begin
                    rDet.Get(Rec."No.");
                    Gtask.CreateIncidencia(rDet);
                end;

            }


        }

        area(Promoted)
        {



            actionref(CerrarIncidencia; "Cerrar Incidencia") { }
        }
    }
    var
        NombreUsuario: Text;
        UrlPrimeraImagen: Text;



    trigger OnAfterGetRecord()
    var
        UsuarioGtask: Record UsuariosGtask;
    begin
        If not IsNullGuid(Rec.Usuario) then begin
            UsuarioGtask.SetRange("Id Usuario", Rec.Usuario);
            If UsuarioGtask.FindFirst() then begin
                NombreUsuario := UsuarioGtask.Nombre;
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