page 50081 "Lista Actuaciones TIP"
{
    Caption = 'Lista de Actuaciones TIP';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = Incidencias;
    SourceTableView = where("Tipo Elemento" = const(Parada),
                            "SubTipo Incidencia" = const(Tip),
                            "Tipo Incidencia" = const("Incidencias EMT"),
                            "Es Peticion" = const(false));
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(FechaActuacion; FechaActuacionTxt)
                {
                    Caption = 'Fecha';
                    ToolTip = 'Fecha y hora de la actuación.';
                    Editable = false;
                }
                field(Parada; ParadaTxt)
                {
                    Caption = 'Parada';
                    ToolTip = 'Código y descripción del TIP / parada.';
                    Editable = false;
                }
                field(Descripcion; DescripcionTxt)
                {
                    Caption = 'Descripción';
                    ToolTip = 'Descripción de la actuación.';
                    Editable = false;
                }
                field(UsuarioGtask; UsuarioGtaskTxt)
                {
                    Caption = 'Usuario (gTASK)';
                    ToolTip = 'Identificador gTASK y nombre del usuario.';
                    Editable = false;
                }
            }
        }
    }
    //Crear nueva actuación
    actions
    {
        area(Processing)
        {
            action(CrearActuacion)
            {
                ApplicationArea = All;
                Caption = 'Crear nueva actuación';
                Image = Create;
                ToolTip = 'Crea una actuación TIP para la parada actual.';
                trigger OnAction()
                var
                    NuevaActuacion: Record Incidencias;
                    ParadaNo: Code[20];
                begin
                    ParadaNo := ObtenerParadaActual();
                    if ParadaNo = '' then
                        Error('No se ha indicado la parada.');

                    NuevaActuacion.Init();
                    NuevaActuacion."Tipo Elemento" := NuevaActuacion."Tipo Elemento"::Parada;
                    NuevaActuacion.Recurso := ParadaNo;
                    NuevaActuacion."Tipo Incidencia" := NuevaActuacion."Tipo Incidencia"::"Incidencias EMT";
                    NuevaActuacion."SubTipo Incidencia" := NuevaActuacion."SubTipo Incidencia"::Tip;
                    NuevaActuacion."Es Peticion" := false;
                    NuevaActuacion."Comunicado por EMT" := false;
                    NuevaActuacion.Estado := NuevaActuacion.Estado::Abierta;
                    NuevaActuacion.Fecha := Today;
                    NuevaActuacion.FechaHora := CurrentDateTime;
                    NuevaActuacion."Fecha Actuacion" := CurrentDateTime;
                    NuevaActuacion.Insert(true);
                    Commit();
                    Page.RunModal(Page::"Incidencias Taller", NuevaActuacion);
                    CurrPage.Update(false);
                end;
            }
            //Editar actuación
            action(EditarActuacion)
            {
                ApplicationArea = All;
                Caption = 'Editar actuación';
                Image = Edit;
                trigger OnAction()
                begin
                    Page.RunModal(Page::"Incidencias Taller", Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FechaActuacionTxt := FormatoFechaActuacion();
        ParadaTxt := CopyStr(Rec.Recurso + ' · ' + Rec.NombreElemento(), 1, MaxStrLen(ParadaTxt));
        DescripcionTxt := CopyStr(DescripcionIncidencia(), 1, MaxStrLen(DescripcionTxt));
        UsuarioGtaskTxt := CopyStr(TextoUsuarioGtask(), 1, MaxStrLen(UsuarioGtaskTxt));
    end;

    var
        FechaActuacionTxt: Text[40];
        ParadaTxt: Text[120];
        DescripcionTxt: Text[250];
        UsuarioGtaskTxt: Text[200];

    local procedure FormatoFechaActuacion(): Text[40]
    var
        Dt: DateTime;
    begin
        if Rec."Fecha Actuacion" <> 0DT then
            Dt := Rec."Fecha Actuacion"
        else
            if Rec.FechaHora <> 0DT then
                Dt := Rec.FechaHora
            else
                exit(Format(Rec.Fecha));

        exit(Format(Dt));
    end;

    local procedure DescripcionIncidencia(): Text
    var
        Detalle: Text;
    begin
        if Rec.Descripción <> '' then
            exit(Rec.Descripción);
        Detalle := Rec.GetWorkDescription();
        exit(CopyStr(Detalle, 1, 250));
    end;

    local procedure TextoUsuarioGtask(): Text
    var
        IdGt: Text;
        Nom: Text;
    begin
        IdGt := Rec.ID_UsuarioGtask(Rec.Usuario);
        Nom := Rec.NombreUsuario(Rec.Usuario);
        if (IdGt <> '') and (Nom <> '') then
            exit(StrSubstNo('%1 — %2', IdGt, Nom));
        if Nom <> '' then
            exit(Nom);
        exit(IdGt);
    end;

    local procedure ObtenerParadaActual(): Code[20]
    var
        ParadaNo: Code[20];
        ParadaFiltro: Text;
    begin
        ParadaNo := Rec.GetRangeMin(Recurso);
        if ParadaNo <> '' then
            exit(ParadaNo);

        ParadaFiltro := Rec.GetFilter(Recurso);
        if ParadaFiltro = '' then
            exit(Rec.Recurso);

        ParadaFiltro := DelChr(ParadaFiltro, '=', '''');
        exit(CopyStr(ParadaFiltro, 1, MaxStrLen(ParadaNo)));
    end;
}
