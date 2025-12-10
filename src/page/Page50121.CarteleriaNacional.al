page 50121 "Cartelería Nacional"
{
    PageType = ListPart;
    SourceTable = "Time Sheet Line";
    Caption = 'Lineas Cartelería Nacional';
    Editable = true;


    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de la hoja de tiempo.';
                }
                field("Fecha Inicio"; Rec."Fecha Orden")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de inicio.';
                }
                field("Contrato"; Rec."Nº Contrato")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si está contrado.';
                }
                field("Campaña"; Rec.Descripcion)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la campaña.';
                }
                field("Soportes"; Rec."Soportes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica los soportes.';
                }
                field("Formato"; Rec."Formato")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el formato.';
                }
                field("Recibido"; Rec."Recibido")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si está recibido.';
                }


            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Enviar Líneas No Enviadas")
            {
                ApplicationArea = All;
                Caption = 'Enviar Líneas No Enviadas';
                Image = SendMail;
                ToolTip = 'Envía por correo las líneas no enviadas con un archivo Excel.';

                trigger OnAction()
                var
                    TimeSheetLine: Record "Time Sheet Line";
                    LineCount: Integer;
                    FileName: Text;
                begin
                    // Filtrar líneas no enviadas
                    TimeSheetLine.SetRange("Time Sheet No.", Rec."Time Sheet No.");
                    TimeSheetLine.SetRange(Enviada, false);
                    LineCount := TimeSheetLine.Count();

                    if LineCount > 0 then begin
                        FileName := GenerarExcelLineasNoEnviadas(TimeSheetLine);
                        CrearTareaLineasNoEnviadas(TimeSheetLine, LineCount, FileName);
                        Message('Se han enviado %1 líneas no enviadas. Se ha creado una tarea y enviado el correo.', LineCount);
                    end else
                        Message('No se encontraron líneas no enviadas para enviar.');

                    // Marcar líneas como enviadas
                    if TimeSheetLine.FindSet() then
                        repeat
                            TimeSheetLine.Enviada := true;
                            TimeSheetLine.Modify();
                        until TimeSheetLine.Next() = 0;
                end;
            }
        }
    }

    local procedure CrearTareaLineasNoEnviadas(TimeSheetLine: Record "Time Sheet Line"; LineCount: Integer; FileName: Text)
    var
        Gtask: Codeunit GTask;
        RecRef: RecordRef;
    begin
        if LineCount > 0 then begin
            RecRef.GetTable(TimeSheetLine);
            Gtask.CrearTarea(RecRef,
                'Líneas No Enviadas ' + Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>'),
                'TALLER', 'COMPRAS',
                'Seguimiento Líneas No Enviadas',
                'RECEPCIONES', true, FileName, '.xlsx');
        end;
    end;

    local procedure GenerarExcelLineasNoEnviadas(var TimeSheetLine: Record "Time Sheet Line"): Text
    var
        ExcelBuffer: Record "Excel Buffer";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
        Base64Content: Text;
        RowNo: Integer;
        Base64: Codeunit "Base64 Convert";
    begin
        FileName := 'Lineas_No_Enviadas_' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>') + '.xlsx';

        // Limpiar ExcelBuffer
        ExcelBuffer.DeleteAll();

        // Crear encabezados
        RowNo := 1;
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Hoja', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Nº Línea', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Tipo', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Job No.', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Descripción', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Job Line No.', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Tipo Elemento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('No. Elemento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Descripción Elemento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Unidad', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Nº Contrato', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Fecha Orden', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Finalizada', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Comprobada', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Enviada', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);

        if TimeSheetLine.FindSet() then begin
            repeat
                RowNo += 1;
                ExcelBuffer.NewRow();
                ExcelBuffer.AddColumn(TimeSheetLine."Time Sheet No.", false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine."Line No."), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine.Type), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(TimeSheetLine."Job No.", false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(TimeSheetLine.Description, false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine."Job Line No."), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine.Tipo), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(TimeSheetLine.No, false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(TimeSheetLine.Descripcion, false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(TimeSheetLine.Unidad, false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(TimeSheetLine."Nº Contrato", false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine."Fecha Orden"), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine.Finalizada), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine.Comprobada), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(TimeSheetLine.Enviada), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
            until TimeSheetLine.Next() = 0;
        end;

        // Crear archivo Excel
        ExcelBuffer.CreateNewBook('Lineas_No_Enviadas');
        ExcelBuffer.WriteSheet('Lineas_No_Enviadas', CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.SetFriendlyFilename(FileName);
        TempBlob.CreateOutStream(OutStream);
        ExcelBuffer.SaveToStream(OutStream, true);
        TempBlob.CreateInStream(InStream);
        Base64Content := Base64.ToBase64(InStream);

        exit(Base64Content);
    end;
}
