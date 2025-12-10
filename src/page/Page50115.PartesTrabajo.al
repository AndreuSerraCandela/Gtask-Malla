page 50115 "Partes de Trabajo"
{
    PageType = Card;
    SourceTable = "Time Sheet Header";
    Caption = 'Orden de Trabajo';
    SourceTableView = where(Tipo = const(Trabajo));
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de la hoja de tiempo.';
                }
                // field("Resource No."; Rec."Resource No.")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Especifica el número del recurso.';
                // }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de inicio del período de la hoja de tiempo.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de finalización del período de la hoja de tiempo.';
                }
                // field(Cliente; Rec.Cliente)
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Especifica el cliente.';
                // }
                // field("Nombre Cliente"; Rec."Nombre Cliente")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Especifica el nombre del cliente.';
                // }
                field(Proyecto; Rec.Proyecto)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el proyecto.';
                }
                // field("Fecha Inicio"; Rec."Fecha Inicio")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Especifica la fecha de inicio del proyecto.';
                // }
            }
            part(Lines; "Líneas Parte de Trabajo")
            {
                ApplicationArea = All;
                SubPageLink = "Time Sheet No." = field("No.");
            }
        }
        area(factboxes)
        {
            part(Documentos; "Doc. Attachment List FactBox")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Table ID" = const(Database::"Time Sheet Line"), "No." = field("Job No.");
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
                ToolTip = 'Añade un nuevo proyecto a las líneas de la hoja de tiempo.';

                trigger OnAction()
                var
                    Job: Record Job;
                    TimeSheetLine: Record "Time Sheet Line";
                    JobPlan: Record "Job Planning Line";
                    LineNo: Integer;
                begin
                    //if Rec.Proyecto = '' then
                    //  Error('Debe especificar un proyecto en la cabecera antes de añadir líneas.');
                    If Page.RunModal(0, Job) <> Action::LookupOK then
                        Error('Proyecto %1 no encontrado');

                    // Obtener el siguiente número de línea
                    TimeSheetLine.SetRange("Time Sheet No.", Rec."No.");
                    if TimeSheetLine.FindLast() then
                        LineNo := TimeSheetLine."Line No." + 10000
                    else
                        LineNo := 10000;

                    // Crear nueva línea con información del proyecto
                    TimeSheetLine.Init();
                    TimeSheetLine."Time Sheet No." := Rec."No.";
                    TimeSheetLine."Line No." := LineNo;
                    TimeSheetLine.Type := TimeSheetLine.Type::Job;
                    TimeSheetLine."Job No." := Job."No.";
                    TimeSheetLine.Description := Job.Description;
                    TimeSheetLine."Job Line No." := -1;
                    TimeSheetLine.Insert;
                    Rec.Proyecto := Job."No.";
                    JobPlan.SetRange("Job No.", Job."No.");
                    JobPlan.SetRange(Type, JobPlan.Type::Resource);
                    JobPlan.FindFirst();
                    Rec.Description := Job.Description;
                    Rec."Resource No." := JobPlan."No.";
                    Rec.Modify();

                    Message('Proyecto %1 añadido correctamente a las líneas.', Job."No.");
                end;
            }
            action("Ver Líneas")
            {
                ApplicationArea = All;
                Caption = 'Ver Líneas';
                Image = List;
                ToolTip = 'Abre las líneas de la hoja de tiempo.';
                RunObject = Page "Time Sheet Lines";
                RunPageLink = "Time Sheet No." = field("No.");
            }
            action("Crear Tarea Taller")
            {
                ApplicationArea = All;
                Caption = 'Crear Tarea Taller';
                Image = SendToMultiple;
                ToolTip = 'Crea una tarea para el taller';

                trigger OnAction()
                var
                    TimeSheetLine: Record "Time Sheet Line";
                    LineCount: Integer;
                    Control: Codeunit "Controlprocesos";
                    Gtask: Codeunit GTask;
                    FileName: Text;
                begin
                    If not Control.CompruebaPermisos(UserSecurityId(), 'ENVIARALTALLER', CompanyName) then
                        exit;

                    TimeSheetLine.SetRange("Time Sheet No.", Rec."No.");
                    TimeSheetLine.SetRange(Finalizada, false);
                    TimeSheetLine.SetRange(Enviada, false);
                    LineCount := TimeSheetLine.Count();
                    If TimeSheetLine.FindSet() then
                        CrearTareaTaller(TimeSheetLine, LineCount, FileName, false);
                    TimeSheetLine.ModifyAll(Enviada, true);

                end;
            }
        }
        area(Promoted)
        {

            actionref(AñadirProyectoAction; "Añadir Proyecto")
            {
            }
            actionref(VerLíneasAction; "Ver Líneas")
            {
            }
            actionref(CrearTareaTallerAction; "Crear Tarea Taller")
            {
            }
        }
    }
    local procedure CrearTareaTaller(PurchaseLine: Record "Time Sheet Line"; LineCount: Integer; FileName: Text; EnvioLineas: Boolean)
    var
        Gtask: Codeunit GTask;
        RecRef: RecordRef;


    begin
        // Contar líneas enviadas al taller


        RecRef.GetTable(PurchaseLine);
        Gtask.CrearTarea(RecRef,
            'Orden de trabajo ' + Format(Today(), 0, '<Day,2>/<Month,2>/<Year4>'),
            'TALLER', 'COMPRAS',
            'Tareas Talles',
            'PRODUCCION', false, '', '');

    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Self: Record "Time Sheet Header";
    begin
        Rec.Tipo := Rec.Tipo::Trabajo;


        If Rec."No." = '' Then begin
            Self.SetFilter("No.", '%1', 'PT' + Format(Date2DMY(WorkDate(), 3)) + '*');

            If Self.FindLast() then
                Rec."No." := IncStr(Self."No.")
            Else
                Rec."No." := 'PT' + Format(Date2DMY(WorkDate(), 3)) + '-00001';
            Rec."Fecha Inicio" := WorkDate();
            Rec."Fecha Fin" := WorkDate();
        end;

    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.Tipo := Rec.Tipo::Trabajo;
    end;

    trigger OnInit()
    begin
        Rec.Tipo := Rec.Tipo::Trabajo;
    end;
}
