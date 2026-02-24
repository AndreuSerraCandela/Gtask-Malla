pageextension 92173 ZonasLimpiezaExt extends "Zonas Limpieza"
{
    layout
    {
        addlast(General)
        {
            field("Equipo Responsable"; Rec."Responsable")
            {
                ApplicationArea = All;
            }
            field("Supervisor"; Rec."Supervisor")
            {
                ApplicationArea = All;
            }
            field("Departamento"; Rec."Departamento")
            {
                ApplicationArea = All;
            }
            field("Servicio"; Rec."Servicio")
            {
                ApplicationArea = All;
            }
            field("Categoria"; Rec."Categoria")
            {
                ApplicationArea = All;
            }
            field("Correos Copia"; Rec."Correos Copia")
            {
                ApplicationArea = All;
            }
            field("Tipo Tarea"; Rec."Tipo Tarea")
            {
                ApplicationArea = All;
            }
        }
        modify("Periodicidad Invierno")
        {
            Visible = false;
        }


        modify("Periodicidad")
        {
            Visible = false;
        }

    }
    actions
    {
        addfirst(Navigation)
        {
            action(AbrirFicha)
            {
                ApplicationArea = All;
                Caption = 'Abrir ficha';
                Image = DocumentEdit;
                ToolTip = 'Abre la ficha de la zona de limpieza para editar datos y frecuencia.';

                trigger OnAction()
                var
                    ZonasLimpieza: Record "Zonas Limpieza";
                begin
                    ZonasLimpieza := Rec;
                    if ZonasLimpieza.Find() then
                        Page.Run(Page::"Ficha Zonas Limpieza", ZonasLimpieza);
                end;
            }
        }
        addlast(Processing)
        {
            action(ImportarParadasZona)
            {
                ApplicationArea = All;
                Caption = 'Importar paradas zona';
                Image = Import;
                ToolTip = 'Importa un archivo Excel con números de emplazamiento en la columna A y asigna la zona de limpieza actual a cada uno.';

                trigger OnAction()
                begin
                    ImportarParadasZonaDesdeExcel(Rec);
                end;
            }
        }
    }

    local procedure ImportarParadasZonaDesdeExcel(var ZonaLimpiezaActual: Record "Zonas Limpieza")
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ExcelBuffer: Record "Excel Buffer" temporary;
        Emplazamientos: Record Emplazamientos;
        FileInStream: InStream;
        SheetName: Text[250];
        NumEmplazamiento: Code[20];
        Actualizados: Integer;
        NoEncontrados: Integer;
        FiltroExcel: Text;
    begin


        FiltroExcel := FileMgt.GetToFilterText('', 'xlsx');
        if FileMgt.BLOBImportWithFilter(TempBlob, 'Importar paradas zona', '', FiltroExcel, 'xlsx') = '' then
            exit;

        TempBlob.CreateInStream(FileInStream);
        SheetName := ExcelBuffer.SelectSheetsNameStream(FileInStream);
        if SheetName = '' then
            Error('No se pudo leer el archivo Excel.');

        TempBlob.CreateInStream(FileInStream);
        if ExcelBuffer.OpenBookStream(FileInStream, SheetName) <> '' then
            Error('Error al abrir la hoja Excel.');

        ExcelBuffer.ReadSheet();
        ExcelBuffer.SetRange("Column No.", 1); // Columna A = nº emplazamiento

        if ExcelBuffer.FindSet() then
            repeat
                NumEmplazamiento := CopyStr(DelChr(ExcelBuffer."Cell Value as Text", '<>'), 1, MaxStrLen(NumEmplazamiento));
                if NumEmplazamiento <> '' then begin
                    if Emplazamientos.Get(Emplazamientos."Tipo Emplazamiento"::Opis, NumEmplazamiento) then begin
                        Emplazamientos.Validate("Zona Limpieza", ZonaLimpiezaActual.Id);
                        Emplazamientos.Modify(true);
                        Actualizados += 1;
                    end else
                        NoEncontrados += 1;
                end;
            until ExcelBuffer.Next() = 0;

        Message('Importación finalizada.\Emplazamientos actualizados: %1\Emplazamientos no encontrados: %2', Actualizados, NoEncontrados);
    end;
}
