page 50122 "Cartelería Nacional Card"
{
    PageType = Card;
    SourceTable = "Time Sheet Header";
    Caption = 'Cartelería Nacional';
    Editable = true;
    SourceTableView = where(Tipo = const(Nacional));


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
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de inicio.';
                }

            }
            group(ProyectoInfo)
            {
                Caption = 'Proyecto';
                field(Proyecto; Rec.Proyecto)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el proyecto.';
                }
            }
            part(Lines; "Cartelería Nacional")
            {
                ApplicationArea = All;
                SubPageLink = "Time Sheet No." = field("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Insertar Línea de Proyecto")
            {
                ApplicationArea = All;
                Caption = 'Insertar Línea de Proyecto';
                Image = Add;
                ToolTip = 'Inserta una nueva línea basada en un proyecto.';

                trigger OnAction()
                var
                    Job: Record Job;
                    JobPlanningLine: Record "Job Planning Line";
                    TimeSheetLine: Record "Time Sheet Line";
                    LineNo: Integer;
                    SalesHeader: Record "Sales Header";
                begin
                    JobPlanningLine.SetRange("Job No.", Rec.Proyecto);
                    JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
                    if Page.RunModal(0, JobPlanningLine) = Action::LookupOK then begin
                        // Actualizar la cabecera con información del proyecto
                        // Crear línea en Time Sheet Line
                        TimeSheetLine.SetRange("Time Sheet No.", Rec."No.");
                        if TimeSheetLine.FindLast() then
                            LineNo := TimeSheetLine."Line No." + 10000
                        else
                            LineNo := 10000;

                        TimeSheetLine.Init();
                        TimeSheetLine."Time Sheet No." := Rec."No.";
                        TimeSheetLine."Line No." := LineNo;
                        SalesHeader.SetRange("Nº Proyecto", JobPlanningLine."Job No.");
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        if SalesHeader.FindFirst() then
                            TimeSheetLine."Nº Contrato" := SalesHeader."No."
                        Else
                            TimeSheetLine."Nº Contrato" := Job."No.";
                        TimeSheetLine.Descripcion := JobPlanningLine.Description;
                        TimeSheetLine."Fecha Orden" := JobPlanningLine."Planning Date";
                        TimeSheetLine.Type := TimeSheetLine.Type::Resource;
                        TimeSheetLine."Job No." := Job."No.";
                        TimeSheetLine."Job Line No." := JobPlanningLine."Line No.";
                        TimeSheetLine.Insert();

                        Message('Línea de proyecto %1 insertada correctamente.', Job."No.");
                    end else
                        Error('No se encontró línea de trabajo para el proyecto %1', Job."No.");
                end;

            }
        }
        area(Promoted)
        {
            actionref(InsertarLíneaDeProyectoAction; "Insertar Línea de Proyecto")
            {
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Self: Record "Time Sheet Header";
    begin
        Rec.Tipo := Rec.Tipo::Nacional;


        If Rec."No." = '' Then begin
            Self.SetFilter("No.", '%1', 'CN' + Format(Date2DMY(WorkDate(), 3)) + '*');

            If Self.FindLast() then
                Rec."No." := IncStr(Self."No.")
            Else
                Rec."No." := 'CN' + Format(Date2DMY(WorkDate(), 3)) + '-00001';
            Rec."Fecha Inicio" := WorkDate();
            Rec."Fecha Fin" := WorkDate();
        end;

    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.Tipo := Rec.Tipo::Nacional;
    end;


}
page 50123 "Partes de Trabajo y cartelería"
{
    PageType = List;
    SourceTable = "Time Sheet Header";
    Caption = 'Ordenes de Trabajo y Cartelería Nacional';
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTableView = where(Tipo = Filter(Nacional | Trabajo));
    InsertAllowed = false;
    Editable = false;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action("Ver")
            {
                ApplicationArea = All;
                Caption = 'Ver';
                Image = List;
                ToolTip = 'Abre detalle';
                trigger OnAction()
                begin
                    case Rec.Tipo of
                        Rec.Tipo::Nacional:
                            Page.Run(Page::"Cartelería Nacional Card", Rec);
                        Rec.Tipo::Trabajo:
                            Page.Run(Page::"Partes de Trabajo", Rec);
                    end;

                end;
            }
            action("Nueva Cartelería Nacional")
            {
                ApplicationArea = All;
                Caption = 'Nueva Cartelería Nacional';
                Image = New;
                ToolTip = 'Crea una nueva cartelería nacional.';
                trigger OnAction()
                var
                    Self: Record "Time Sheet Header";
                begin
                    Rec.Init();
                    Self.SetFilter("No.", '%1', 'CN' + Format(Date2DMY(WorkDate(), 3)) + '*');
                    If Self.FindLast() then
                        Rec."No." := IncStr(Self."No.")
                    Else
                        Rec."No." := 'CN' + Format(Date2DMY(WorkDate(), 3)) + '-00001';
                    Rec."Fecha Inicio" := WorkDate();
                    Rec."Fecha Fin" := WorkDate();
                    Rec.Tipo := Rec.Tipo::Nacional;
                    Rec.Insert();
                    Commit();
                    Page.RunModal(Page::"Cartelería Nacional Card", Rec);
                end;
            }
            action("Nueva Parte de Trabajo")
            {
                ApplicationArea = All;
                Caption = 'Nueva Parte de Trabajo';
                Image = New;
                ToolTip = 'Crea una nueva parte de trabajo.';
                trigger OnAction()
                var
                    Self: Record "Time Sheet Header";
                begin
                    Rec.Init();
                    Rec.Tipo := Rec.Tipo::Trabajo;
                    Self.SetFilter("No.", '%1', 'PT' + Format(Date2DMY(WorkDate(), 3)) + '*');
                    If Self.FindLast() then
                        Rec."No." := IncStr(Self."No.")
                    Else
                        Rec."No." := 'PT' + Format(Date2DMY(WorkDate(), 3)) + '-00001';
                    Rec."Fecha Inicio" := WorkDate();
                    Rec."Fecha Fin" := WorkDate();
                    Rec.Insert();
                    Commit();
                    Page.RunModal(Page::"Partes de Trabajo", Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(NuevaCarteleríaNacionalAction; "Nueva Cartelería Nacional")
            {
            }
            actionref(NuevaParteTrabajoAction; "Nueva Parte de Trabajo")
            {
            }
            actionref(VerAction; Ver)
            {
            }
        }
    }
}
