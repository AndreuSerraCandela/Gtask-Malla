page 50112 "Incidencias Taller"
{
    PageType = Card;
    SourceTable = "Incidencias";
    ApplicationArea = All;
    UsageCategory = Documents;
    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Descripción"; Rec."Descripción") { ApplicationArea = All; }
                field(Recurso; Rec.Recurso) { ApplicationArea = All; }
                field("Tipo Incidencia"; Rec."Tipo Incidencia") { ApplicationArea = All; }
                field("Fecha"; Rec."Fecha") { ApplicationArea = All; }
                field("Estado"; Rec."Estado") { ApplicationArea = All; }
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
            actionref(AsignarImagenaLineas; "Asignar Imagen a la Incidencia")

            {

            }
            actionref(DesasignarImagenaLineas; "Desasignar Imagen de la Incidencia")
            {

            }
            actionref(CerrarIncidencia; "Cerrar Incidencia") { }
        }
    }
    trigger OnOpenPage()
    begin
        CurrPage.ImagenesNoAsociadas.Page.MarcaIncidencia();

    end;

}