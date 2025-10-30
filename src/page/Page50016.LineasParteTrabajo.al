page 50116 "Líneas Parte de Trabajo"
{
    PageType = ListPart;
    SourceTable = "Time Sheet Line";
    Caption = 'Líneas Parte de Trabajo';
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de línea.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el tipo de línea.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número del trabajo.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción de la línea.';
                    StyleExpr = Negrita;
                }
                field("Fecha Orden"; Rec."Fecha Orden")
                {
                    Caption = 'Fecha Orden';
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de aprobación de la línea.';
                    Visible = false;
                }
                field("Job Line No."; Rec."Job Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de línea del trabajo.';
                    Visible = false;
                }
                field(Tipo; Rec.Tipo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el tipo de elemento.';
                }
                field(No; Rec.No)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número del elemento.';
                }

                field(Unidad; Rec.Unidad)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la unidad.';
                }
                field(Fibalizada; Rec.Finalizada)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si la línea está finalizada.';

                }
                field(Comprobada; Rec.Comprobada)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si la línea está comprobada.';
                }
                field(Enviada; Rec.Enviada)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si la línea está enviada.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Añadir Proyecto")
            {
                ApplicationArea = All;
                Caption = 'Añadir Proyecto';
                Image = Add;
                ToolTip = 'Añade un nuevo proyecto a las líneas.';
                Promoted = true;

                trigger OnAction()
                var
                    TimeSheetHeader: Record "Time Sheet Header";
                    Job: Record Job;
                    JobPlan: Record "Job Planning Line";
                    TimeSheetLine: Record "Time Sheet Line";
                    LineNo: Integer;
                begin
                    if not TimeSheetHeader.Get(Rec."Time Sheet No.") then
                        Error('Hoja de tiempo %1 no encontrada', Rec."Time Sheet No.");

                    if TimeSheetHeader.Proyecto = '' then
                        Error('Debe especificar un proyecto en la cabecera antes de añadir líneas.');

                    if not Job.Get(TimeSheetHeader.Proyecto) then
                        Error('Proyecto %1 no encontrado', TimeSheetHeader.Proyecto);
                    JobPlan.SetRange("Job No.", Job."No.");
                    If Page.RunModal(0, JobPlan) <> Action::LookupOK then
                        Error('No se encontró línea de trabajo para el proyecto %1', Job."No.");

                    // Obtener el siguiente número de línea
                    TimeSheetLine.SetRange("Time Sheet No.", Rec."Time Sheet No.");
                    if TimeSheetLine.FindLast() then
                        LineNo := TimeSheetLine."Line No." + 10000
                    else
                        LineNo := 10000;

                    // Crear nueva línea con información del proyecto
                    TimeSheetLine.Init();
                    TimeSheetLine."Time Sheet No." := Rec."Time Sheet No.";
                    TimeSheetLine."Line No." := LineNo;
                    TimeSheetLine.Type := TimeSheetLine.Type::Job;
                    TimeSheetLine."Job No." := Job."No.";
                    TimeSheetLine.Description := JobPlan.Description;
                    TimeSheetHeader.Get(Rec."Time Sheet No.");
                    TimeSheetHeader."Resource No." := JobPlan."No.";
                    TimeSheetHeader.Modify();
                    TimeSheetLine."Job Line No." := 0;
                    TimeSheetLine.Insert();

                    Message('Proyecto %1 añadido correctamente a las líneas.', Job."No.");
                    TimeSheetLine.SetRange("Job No.", Job."No.");
                    TimeSheetLine.SetRange("Job Line No.", -1);
                    TimeSheetLine.ModifyAll(Finalizada, false);
                end;
            }
            action(Marcarcomocomprobadas)
            {
                ApplicationArea = All;
                Caption = 'Marcar como comprobadas';
                Image = Check;
                ToolTip = 'Marca las líneas seleccionadas como comprobadas.';
                Promoted = true;

                trigger OnAction()
                var
                    TimeSheetLine: Record "Time Sheet Line";
                begin
                    CurrPage.SetSelectionFilter(TimeSheetLine);
                    TimeSheetLine.ModifyAll(Comprobada, true);
                end;
            }
            action("Ver Adjuntos")
            {
                ApplicationArea = All;
                Caption = 'Ver Adjuntos';
                Image = Attach;
                ToolTip = 'Muestra los adjuntos relacionados con esta línea.';
                RunObject = Page "Document Attachment Details";
                RunPageLink = "Table ID" = const(Database::"Time Sheet Line"),
                              "No." = field("Time Sheet No."),
                              "Line No." = field("Line No.");
                Promoted = true;
            }
            action("Enviar Líneas No Finalizadas")
            {
                ApplicationArea = All;
                Caption = 'Enviar Líneas No Finalizadas';
                Image = SendMail;
                ToolTip = 'Envía por correo las líneas no finalizadas con un archivo Excel.';
                Promoted = true;

                trigger OnAction()
                var
                    TimeSheetLine: Record "Time Sheet Line";
                    LineCount: Integer;
                    FileName: Text;
                begin
                    // Filtrar líneas no finalizadas
                    TimeSheetLine.SetRange("Time Sheet No.", Rec."Time Sheet No.");
                    TimeSheetLine.SetRange(Finalizada, false);
                    TimeSheetLine.SetRange(Enviada, false);
                    LineCount := TimeSheetLine.Count();

                    if LineCount > 0 then begin
                        FileName := GenerarExcelLineasNoFinalizadas(TimeSheetLine);
                        CrearTareaLineasNoFinalizadas(TimeSheetLine, LineCount, FileName);
                        Message('Se han enviado %1 líneas no finalizadas. Se ha creado una tarea y enviado el correo.', LineCount);
                    end else
                        Message('No se encontraron líneas no finalizadas para enviar.');
                    If TimeSheetLine.FindSet() then
                        repeat
                            If TimeSheetLine."Job Line No." <> -1 then begin
                                TimeSheetLine.Enviada := true;
                                TimeSheetLine.Modify();
                            end;

                        until TimeSheetLine.Next() = 0;
                end;
            }
        }
    }

    var
        Negrita: Text;

    trigger OnAfterGetRecord()
    begin
        // Determinar si la descripción debe estar en negrita
        if Rec."Job Line No." <> 0 then
            Negrita := 'Strong'
        else
            Negrita := 'Standard';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        if TimeSheetHeader.Get(Rec."Time Sheet No.") then begin
            Rec."Job No." := TimeSheetHeader.Proyecto;
            Rec.Type := Rec.Type::Job;
        end;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
        JobPlan: Record "Job Planning Line";
    begin
        if TimeSheetHeader.Get(Rec."Time Sheet No.") then begin
            If TimeSheetHeader."Resource No." = '' then begin
                JobPlan.SetRange("Job No.", Rec."Job No.");
                JobPlan.SetRange(Type, JobPlan.Type::Resource);
                If JobPlan.FindFirst() then
                    TimeSheetHeader."Resource No." := JobPlan."No.";
                TimeSheetHeader.Modify();
            end;

        end;
        exit(true);
    end;

    local procedure CrearTareaLineasNoFinalizadas(TimeSheetLine: Record "Time Sheet Line"; LineCount: Integer; FileName: Text)
    var
        Gtask: Codeunit GTask;
        RecRef: RecordRef;
    begin
        if LineCount > 0 then begin
            RecRef.GetTable(TimeSheetLine);
            Gtask.CrearTarea(RecRef,
                'Líneas No Finalizadas ' + Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>'),
                'TALLER', 'COMPRAS',
                'Partes de Trabajo',
                'TRABAJO', true, FileName, '.xlsx');

        end;
    end;

    local procedure GenerarExcelLineasNoFinalizadas(var TimeSheetLine: Record "Time Sheet Line"): Text
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
        FileName := 'Lineas_No_Finalizadas_' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>') + '.xlsx';

        // Limpiar ExcelBuffer
        ExcelBuffer.DeleteAll();

        // Crear encabezados
        RowNo := 1;
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Hoja de Tiempo', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Nº Línea', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Tipo', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Job No.', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Descripción', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Job Line No.', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Tipo Elemento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('No. Elemento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Descripción Elemento', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Unidad', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Finalizada', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Comprobada', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Enviada', false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);

        if TimeSheetLine.FindSet() then begin
            repeat
                RowNo += 1;
                ExcelBuffer.NewRow();
                If TimeSheetLine."Job Line No." = -1 then begin
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
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Finalizada), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Comprobada), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Enviada), false, '', true, false, true, '', ExcelBuffer."Cell Type"::Text);
                end else begin
                    // sin negrita
                    ExcelBuffer.AddColumn(TimeSheetLine."Time Sheet No.", false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine."Line No."), false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Type), false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(TimeSheetLine."Job No.", false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(TimeSheetLine.Description, false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine."Job Line No."), false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Tipo), false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(TimeSheetLine.No, false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(TimeSheetLine.Descripcion, false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(TimeSheetLine.Unidad, false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Finalizada), false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Comprobada), false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);
                    ExcelBuffer.AddColumn(Format(TimeSheetLine.Enviada), false, '', false, false, true, '', ExcelBuffer."Cell Type"::Text);

                end;
            until TimeSheetLine.Next() = 0;
        end;

        // Crear archivo Excel
        ExcelBuffer.CreateNewBook('Lineas_No_Finalizadas');
        ExcelBuffer.WriteSheet('Lineas_No_Finalizadas', CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.SetFriendlyFilename(FileName);
        TempBlob.CreateOutStream(OutStream);
        ExcelBuffer.SaveToStream(OutStream, true);
        TempBlob.CreateInStream(InStream);
        Base64Content := Base64.ToBase64(InStream);

        exit(Base64Content);
    end;
}