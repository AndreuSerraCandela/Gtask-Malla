page 50101 "Ordenes Fijación QR"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Orden fijación";
    Caption = 'Estado de las Ordenes de Fijación';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Nº Orden"; Rec."Nº Orden")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de orden de fijación';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        OrdenFijacion: Record "Cab Orden fijación";
                    begin
                        OrdenFijacion.SetRange("Nº Orden", Rec."Nº Orden");
                        Page.Run(Page::"Lista ordenes fijación", OrdenFijacion);
                    end;
                }
                field("Nº Reserva"; Rec."Nº Reserva")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de reserva';
                    StyleExpr = RowStyle;

                }

                field("Nº Proyecto"; Rec."Nº Proyecto")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de proyecto';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        Proyecto: Record Job;
                    begin
                        Proyecto.SetRange("No.", Rec."Nº Proyecto");
                        Page.Run(Page::"Job List", Proyecto);
                    end;
                }
                field(Campaña; Rec.DescripcionCampaña())
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la campaña';
                    StyleExpr = RowStyle;
                }

                field("Nº Recurso"; Rec."Nº Recurso")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de recurso';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        Recurso: Record Resource;
                    begin
                        Recurso.SetRange("No.", Rec."Nº Recurso");
                        Page.Run(Page::"Resource List", Recurso);
                    end;
                }
                field(Descripcion; Rec.DescripcionRecurso())
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción del recurso';
                    StyleExpr = RowStyle;
                }
                field("Tipo Recurso"; Rec."Tipo Recurso")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el tipo de recurso';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        TipoRecurso: Record "Tipo Recurso";
                    begin
                        TipoRecurso.SetRange(Tipo, Rec."Tipo Recurso");
                        Page.Run(Page::"Tabla Tipo Recurso", TipoRecurso);
                    end;
                }
                field("Equipo"; Rec.Nombre())
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el equipo';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        UserGtask: Record UsuariosGtask;
                    begin
                        UserGtask.SetRange("Id Usuario", Rec."Equipo");
                        Page.Run(Page::UsuariosGtask, UserGtask);
                    end;

                }
                field(TieneTask; Rec.TieneTask)
                {
                    Caption = 'Tiene Tarea';
                    ApplicationArea = All;
                    ToolTip = 'Indica si la orden tiene una tarea asociada';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        UserTask: Record "User Task";
                    begin
                        UserTask.SetRange(OrdenFijacion, Rec."Nº Orden");
                        UserTask.SetRange(Reserva, Rec."Nº Reserva");
                        Page.Run(Page::"User Task List", UserTask);
                    end;
                }
                field("Fecha fijación"; Rec."Fecha fijación")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de fijación';
                    StyleExpr = RowStyle;
                }
                field("Fecha Inicio Reserva"; Rec."Fecha Inicio Reserva")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de reserva';
                    StyleExpr = RowStyle;
                }
                field("Fecha Fin Reserva"; Rec."Fecha Fin Reserva")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha de reserva';
                    StyleExpr = RowStyle;
                }
                field(EstadoTarea; Rec.EstadoTarea)
                {
                    Caption = 'Estado Tarea';
                    ApplicationArea = All;
                    ToolTip = 'Muestra el estado de la tarea asociada';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        UserTask: Record "User Task";
                    begin
                        UserTask.SetRange(OrdenFijacion, Rec."Nº Orden");
                        Page.Run(Page::"User Task List", UserTask);
                    end;
                }
                field(TieneFotos; Rec.TieneFotos)
                {
                    Caption = 'Tiene Fotos';
                    ApplicationArea = All;
                    ToolTip = 'Indica si la orden tiene fotos adjuntas';
                    StyleExpr = RowStyle;
                    trigger OnDrillDown()
                    var
                        DocumentAttachment: Record "Document Attachment";
                        UserTask: Record "User Task";
                    begin
                        DocumentAttachment.SetRange("Table ID", Database::"Orden fijación");
                        DocumentAttachment.SetRange("No.", Rec."Nº Proyecto");
                        DocumentAttachment.SetRange("Line No.", Rec."Nº Reserva");
                        DocumentAttachment.SetFilter("File Name", '%1', '*.jpg');
                        Page.Run(Page::"Document Attachment Details", DocumentAttachment);
                    end;

                }
                field(TieneQR; Rec.TieneQR)
                {
                    Visible = false;
                    Caption = 'Tiene QR';
                    ApplicationArea = All;
                    ToolTip = 'Indica si la orden tiene QR';
                    StyleExpr = RowStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActualizarTareas)
            {
                ApplicationArea = All;
                Caption = 'Actualizar Tareas';
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Actualiza las tareas desde Gtask';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    UserTask: Record "User Task";
                    OrdenFijacion: Record "Orden fijación";

                begin
                    CurrPage.SetSelectionFilter(OrdenFijacion);
                    if OrdenFijacion.FindSet() then
                        repeat
                            UserTask.SetRange(Reserva, OrdenFijacion."Nº Reserva");
                            if UserTask.FindSet() then begin
                                if UserTask.Id_Tarea <> '' then
                                    Gtask.GetTarea(UserTask.Id_Tarea);
                            end else begin
                                UserTask.SetRange(OrdenFijacion, OrdenFijacion."Nº Orden");
                                UserTask.SetRange(Reserva);
                                if UserTask.FindFirst() then
                                    repeat
                                        Gtask.GetTarea(UserTask.Id_Tarea);
                                    until UserTask.Next() = 0;
                            end;
                        until OrdenFijacion.Next() = 0;

                    CurrPage.Update(false);
                    Message('Tareas actualizadas correctamente');
                end;
            }
            action(ActualizarFotos)
            {
                ApplicationArea = All;
                Caption = 'Actualizar Fotos';
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    a: Integer;
                    DocumentAttachment2: Record "Document Attachment";
                    DocumentAttachment3: Record "Document Attachment";
                    UserTask: Record "User Task";
                    OrdenFijacion: Record "Orden fijación";

                begin
                    CurrPage.SetSelectionFilter(OrdenFijacion);
                    if OrdenFijacion.FindSet() then
                        repeat
                            UserTask.SetRange(OrdenFijacion, OrdenFijacion."Nº Orden");
                            UserTask.SetRange(Reserva, OrdenFijacion."Nº Reserva");
                            if UserTask.FindSet() then begin
                                DocumentAttachment.SetRange("Table ID", Database::"User Task");
                                DocumentAttachment.SetRange("No.", UserTask."No.");
                                DocumentAttachment.SetFilter("File Name", '%1', '*.jpg');
                                if DocumentAttachment.FindSet() then
                                    repeat
                                        DocumentAttachment3.SetRange("Table ID", Database::"Orden fijación");
                                        DocumentAttachment3.SetRange("No.", OrdenFijacion."Nº Proyecto");
                                        DocumentAttachment3.SetRange("Line No.", OrdenFijacion."Nº Reserva");
                                        DocumentAttachment3.SetRange("File Name", DocumentAttachment."File Name");
                                        if not DocumentAttachment3.FindSet() then begin
                                            DocumentAttachment2 := DocumentAttachment;
                                            repeat
                                                DocumentAttachment2."Line No." := a;
                                                DocumentAttachment2."Table ID" := Database::"Orden fijación";
                                                DocumentAttachment2."No." := OrdenFijacion."Nº Proyecto";
                                                DocumentAttachment2."Line No." := OrdenFijacion."Nº Reserva";
                                                DocumentAttachment2."Document Flow Service" := true;
                                                a += 1;
                                            until DocumentAttachment2.Insert();
                                        end;
                                        DocumentAttachment3.SetRange("Table ID", Database::Job);
                                        DocumentAttachment3.SetRange("No.", OrdenFijacion."Nº Proyecto");
                                        DocumentAttachment3.SetRange("File Name", DocumentAttachment."File Name");
                                        if not DocumentAttachment3.FindSet() then begin
                                            DocumentAttachment2 := DocumentAttachment;
                                            repeat
                                                DocumentAttachment2."Line No." := a;
                                                DocumentAttachment2."Table ID" := Database::Job;
                                                DocumentAttachment2."No." := OrdenFijacion."Nº Proyecto";
                                                DocumentAttachment2."Document Flow Service" := true;
                                                a += 1;
                                            until DocumentAttachment2.Insert();

                                        end;
                                    until DocumentAttachment.Next() = 0;
                            end;
                        until OrdenFijacion.Next() = 0;
                end;
            }
        }
    }

    var
        RowStyle: Text;

    trigger OnAfterGetRecord()
    begin
        Clear(RowStyle);
        Rec.calcfields(EstadoTarea, TieneTask, TieneFotos, TieneQR, Equipo);
        // Primero comprobamos si no tiene tarea (prioridad 1: rojo)
        if not Rec.TieneTask then begin
            RowStyle := 'Unfavorable';
            exit;
        end;

        // Si tiene fotos (prioridad 2: azul)
        if Rec.TieneFotos then
            RowStyle := 'StrongAccent'
        else begin
            // Si tiene tarea pero no fotos, color según estado (prioridad 3)
            case Rec.EstadoTarea of
                Rec.EstadoTarea::Pendiente:
                    begin
                        RowStyle := 'Ambiguous';
                    end;
                Rec.EstadoTarea::"En Proceso":
                    begin
                        RowStyle := 'StandardAccent';
                    end;
                Rec.EstadoTarea::Finalizado:
                    begin
                        RowStyle := 'Favorable';
                    end;
                Rec.EstadoTarea::Cancelado:
                    begin
                        RowStyle := 'Unfavorable';
                    end;
            end;
        end;


    end;

    trigger OnOpenPage()
    begin
        // Filtrar solo órdenes que tienen QR
        Rec.SetRange(TieneQR, true);
        Rec.SetRange(TieneFotos, false);
    end;




}