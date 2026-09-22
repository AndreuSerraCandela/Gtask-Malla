/// <summary>
/// OData FichaParada — paradas Opis para Mantenimiento / GMalla.
/// Publicar en el servicio OData (p. ej. powerbi) como entidad FichaParada.
/// </summary>
page 50091 FichaParada
{
    ApplicationArea = All;
    Caption = 'FichaParada';
    DelayedInsert = true;
    PageType = List;
    SourceTable = Emplazamientos;
    SourceTableView = where("Tipo Emplazamiento" = const(Opis));
    ODataKeyFields = "Tipo Emplazamiento", "Nº Emplazamiento";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Tipo Emplazamiento"; Rec."Tipo Emplazamiento")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Nº Emplazamiento"; Rec."Nº Emplazamiento")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                }
                field(Concesión; Rec.Concesión)
                {
                    ApplicationArea = All;
                }
                field("Tipo Parada"; Rec."Tipo Parada")
                {
                    ApplicationArea = All;
                }
                field("Observaciones"; Rec."Observaciones")
                {
                    ApplicationArea = All;
                }
                field("Ubicación"; Rec."Ubicación")
                {
                    ApplicationArea = All;
                }
                field("Zona Limpieza"; Rec."Zona Limpieza")
                {
                    ApplicationArea = All;
                }
                field("Descripción Zona"; Rec.DescripcionZona())
                {
                    ApplicationArea = All;
                    Caption = 'Descripción Zona';
                    Editable = false;
                }
                field("Zona Crítica"; Rec."Zona Crítica")
                {
                    ApplicationArea = All;
                }
                field("Tipo Banco"; Rec."Tipo Banco")
                {
                    ApplicationArea = All;
                }
                field(Matricula; Rec.Contratado)
                {
                    ApplicationArea = All;
                    Caption = 'Matricula';
                }
                field("Semoan"; Rec."Semoan")
                {
                    ApplicationArea = All;
                }
                field("Estado Parada"; Rec."Estado Parada")
                {
                    ApplicationArea = All;
                }
                field("Fecha instalación"; Rec."Fecha instalación")
                {
                    ApplicationArea = All;
                }
                field("Bajo Mantenimiento"; Rec."Bajo Mantenimiento")
                {
                    ApplicationArea = All;
                }
                field("Fecha Próximo Mantenimiento"; Rec."Fecha Próximo Mantenimiento")
                {
                    ApplicationArea = All;
                }
                field("Periodicidad Mantenimiento"; Rec."Periodicidad Mantenimiento")
                {
                    ApplicationArea = All;
                }
                field("Periodicidad Mant. Invierno"; Rec."Periodicidad Mant. Invierno")
                {
                    ApplicationArea = All;
                }
                field("Último Mantenimiento"; Rec."Último Mantenimiento")
                {
                    ApplicationArea = All;
                }
                field("Zona Mantenimiento"; Rec."Zona Mantenimiento")
                {
                    ApplicationArea = All;
                }
                field(PuntoX; Rec.PuntoX)
                {
                    ApplicationArea = All;
                }
                field(PuntoY; Rec.PuntoY)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
