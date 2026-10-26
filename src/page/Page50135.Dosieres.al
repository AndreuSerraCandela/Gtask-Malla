page 50135 "Dosier Malla"
{
    PageType = Card;
    SourceTable = Incidencias;
    Caption = 'Dosier';
    ApplicationArea = All;
    UsageCategory = Documents;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                }
                field("Tipo Elemento"; Rec."Tipo Elemento")
                {
                    ApplicationArea = All;
                }
                field(Recurso; Rec.Recurso)
                {
                    ApplicationArea = All;
                    Caption = 'Recurso / emplazamiento';
                }
                field("Tipo Incidencia"; Rec."Tipo Incidencia")
                {
                    ApplicationArea = All;
                }
                field("Tipo Intervención"; Rec."Tipo Intervención")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Estado; Rec.Estado)
                {
                    ApplicationArea = All;
                }
                field("Fecha Hora"; Rec.FechaHora)
                {
                    ApplicationArea = All;
                }
                field(Id_Gtask; Rec.Id_Gtask)
                {
                    ApplicationArea = All;
                    Caption = 'Id incidencia GTask';
                    Editable = false;
                }
                field("Parte Trabajo"; Rec."Parte Trabajo")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(Notas)
            {
                field(DescripcionAmpliada; DescripcionAmpliada)
                {
                    ApplicationArea = All;
                    Caption = 'Descripción ampliada';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;

                    trigger OnValidate()
                    begin
                        Rec.SetWorkDescription(DescripcionAmpliada);
                    end;
                }
            }
            part(Imagenes; "Imagenes Orden fijacion")
            {
                ApplicationArea = All;
                Caption = 'Fotos y dibujos';
                SubPageLink = "Nº Orden" = field("Nº Orden"), "Es Incidencia" = const(true);
                SubPageView = where("Es Incidencia" = const(true), "Nº Orden" = filter(<> 0));
            }
        }
        area(FactBoxes)
        {
            part(VisorImagen; "Ocr Viewer Part")
            {
                ApplicationArea = All;
                Provider = Imagenes;
                SubPageLink = "Nº Orden" = field("Nº Orden"), "Nº Imagen" = field("Nº Imagen");
            }
            part(Documentos; "Doc. Attachment List FactBox")
            {
                ApplicationArea = All;
                Caption = 'Audio y documentos';
                SubPageLink = "Table ID" = const(Database::Incidencias), "No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CrearOrdenTrabajo)
            {
                ApplicationArea = All;
                Caption = 'Crear parte / orden';
                Image = NewDocument;

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.CrearOrdenTrabajoIncidencia(Rec);
                    CurrPage.Update(false);
                    Page.Run(Page::"Ordenes Trabajo", Rec);
                end;
            }
            action(AbrirOrdenes)
            {
                ApplicationArea = All;
                Caption = 'Abrir en Ordenes';
                Image = LinkWeb;
                Enabled = Rec."Parte Trabajo" <> '';

                trigger OnAction()
                begin
                    Rec.TestField("Parte Trabajo");
                    Hyperlink('https://ordenes.malla.es/OT-' + Rec."Parte Trabajo");
                end;
            }
        }
        area(Promoted)
        {
            actionref(CrearOrdenTrabajoPromoted; CrearOrdenTrabajo) { }
            actionref(AbrirOrdenesPromoted; AbrirOrdenes) { }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Tipo Intervención" := Rec."Tipo Intervención"::Dosier;
        Rec."SubTipo Incidencia" := Rec."SubTipo Incidencia"::Otras;
    end;

    trigger OnAfterGetRecord()
    begin
        DescripcionAmpliada := Rec.GetWorkDescription();
    end;

    var
        DescripcionAmpliada: Text;
}

page 50136 "Lista Dosieres"
{
    PageType = List;
    SourceTable = Incidencias;
    SourceTableView = where("Tipo Intervención" = const(Dosier));
    CardPageId = "Dosier Malla";
    Caption = 'Dosieres';
    ApplicationArea = All;
    UsageCategory = Documents;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Dosieres)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                }
                field(Recurso; Rec.Recurso)
                {
                    ApplicationArea = All;
                    Caption = 'Recurso / emplazamiento';
                }
                field("Tipo Elemento"; Rec."Tipo Elemento")
                {
                    ApplicationArea = All;
                }
                field(Estado; Rec.Estado)
                {
                    ApplicationArea = All;
                }
                field("Fecha Hora"; Rec.FechaHora)
                {
                    ApplicationArea = All;
                }
                field(UsuarioGtask; Rec.ID_UsuarioGtask(Rec.Usuario))
                {
                    ApplicationArea = All;
                    Caption = 'Usuario GTask';
                }
                field(Id_Gtask; Rec.Id_Gtask)
                {
                    ApplicationArea = All;
                    Caption = 'Id GTask';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AbrirDosier)
            {
                ApplicationArea = All;
                Caption = 'Abrir dosier';
                Image = Open;

                trigger OnAction()
                begin
                    Page.Run(Page::"Dosier Malla", Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(AbrirDosierPromoted; AbrirDosier) { }
        }
    }
}
