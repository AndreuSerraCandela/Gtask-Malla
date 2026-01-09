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
                field(Revisión; Cab.Revisión)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica si es revisión';
                    StyleExpr = RowStyle;
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
                        //DocumentAttachment.SetRange("No.", Rec."Nº Proyecto");
                        DocumentAttachment.SetRange("Line No.", Rec."Nº Reserva");
                        DocumentAttachment.SetRange("ID_Doc", Rec."Nº Orden");
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
                    Gtask: Codeunit GTask;
                begin

                    CurrPage.SetSelectionFilter(OrdenFijacion);
                    if OrdenFijacion.FindSet() then begin
                        repeat
                            UserTask.SetRange(OrdenFijacion, OrdenFijacion."Nº Orden");
                            UserTask.SetRange(Reserva, OrdenFijacion."Nº Reserva");
                            if UserTask.FindSet() then begin
                                Gtask.UpdateTasksProoriry(UserTask);
                                DocumentAttachment.SetRange("Table ID", Database::"User Task");
                                DocumentAttachment.SetRange("No.", UserTask."No.");
                                DocumentAttachment.SetFilter("File Name", '%1', '*.jpg');
                                if DocumentAttachment.FindSet() then
                                    repeat
                                        DocumentAttachment3.SetRange("Table ID", Database::"Orden fijación");
                                        DocumentAttachment3.SetRange("ID_Doc", OrdenFijacion."Nº Orden");
                                        DocumentAttachment3.SetRange("Line No.", OrdenFijacion."Nº Reserva");
                                        DocumentAttachment3.SetRange("File Name", DocumentAttachment."File Name");
                                        if not DocumentAttachment3.FindSet() then begin
                                            DocumentAttachment2 := DocumentAttachment;
                                            //repeat
                                            //DocumentAttachment2."Line No." := a;
                                            DocumentAttachment2."Table ID" := Database::"Orden fijación";
                                            DocumentAttachment2."No." := OrdenFijacion."Nº Proyecto";
                                            DocumentAttachment2."Line No." := OrdenFijacion."Nº Reserva";
                                            DocumentAttachment2."ID_Doc" := OrdenFijacion."Nº Orden";
                                            DocumentAttachment2."Document Flow Service" := true;
                                            a += 1;
                                            If DocumentAttachment2.Insert() Then Gtask.AdImagenValla(DocumentAttachment2, '');
                                        end;
                                        DocumentAttachment3.SetRange("Table ID", Database::Job);
                                        DocumentAttachment3.SetRange("No.", OrdenFijacion."Nº Proyecto");
                                        DocumentAttachment3.SetRange("Line No.");
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
                    end else begin
                        DocumentAttachment.SetRange("Table ID", Database::"Orden fijación");
                        DocumentAttachment.Reset;
                        DocumentAttachment.SetRange("Line No.", OrdenFijacion."Nº Reserva");
                        DocumentAttachment.SetRange(ID_Doc, OrdenFijacion."Nº Orden");
                        DocumentAttachment.SetFilter("File Name", '%1', '*.jpg');

                        if DocumentAttachment.FindSet() then
                            Repeat
                                a += 1;
                                DocumentAttachment3.Reset;
                                DocumentAttachment3.SetRange("Table ID", Database::"User Task");
                                DocumentAttachment3.SetRange("No.", Format(UserTask.Id));
                                DocumentAttachment3.SetRange("File Name", DocumentAttachment."File Name");
                                if not DocumentAttachment3.FindSet() then begin
                                    DocumentAttachment2 := DocumentAttachment;
                                    //repeat
                                    //DocumentAttachment2."Line No." := a;

                                    DocumentAttachment2 := DocumentAttachment;
                                    repeat
                                        DocumentAttachment2."Line No." := a;
                                        DocumentAttachment2."Table ID" := Database::"User Task";
                                        DocumentAttachment2."No." := Format(UserTask."No.");
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
                end;
            }
            action(FinalizaTareas)
            {
                ApplicationArea = All;
                Caption = 'Finalizar Tareas';
                Image = ClosePeriod;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Cerrar las tareas desde Gtask';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    UserTask: Record "User Task";
                    OrdenFijacion: Record "Orden fijación";
                    Cerrar: Boolean;
                    TodasCerradas: Boolean;
                begin
                    CurrPage.SetSelectionFilter(OrdenFijacion);
                    if OrdenFijacion.FindSet() then
                        repeat
                            TodasCerradas := true;
                            UserTask.SetRange(Reserva, OrdenFijacion."Nº Reserva");
                            if UserTask.FindSet() then begin
                                Cerrar := true;
                                If UserTask.OrdenRetirada then begin
                                    If Confirm('La orden %1 tiene una retirada asociada para la reserva %2. ¿Desea cerrar la tarea?', true, OrdenFijacion."Nº Orden", OrdenFijacion."Nº Reserva") then
                                        Cerrar := true;
                                end;
                                if not Cerrar then TodasCerradas := false;
                                if (UserTask.Id_Tarea <> '') and (Cerrar) then
                                    If UserTask.Estado <> UserTask.Estado::Finalizado Then
                                        Gtask.CloseTarea(UserTask.Id);

                            end else begin
                                UserTask.SetRange(OrdenFijacion, OrdenFijacion."Nº Orden");
                                UserTask.SetRange(Reserva);
                                if UserTask.FindFirst() then
                                    repeat
                                        Cerrar := true;
                                        If UserTask.OrdenRetirada then begin
                                            If Confirm('La orden %1 tiene una retirada asociada para la reserva %2. ¿Desea cerrar la tarea?', true, OrdenFijacion."Nº Orden", OrdenFijacion."Nº Reserva") then
                                                Cerrar := true;
                                        end;
                                        if not Cerrar then TodasCerradas := false;
                                        If (UserTask.Id_Tarea <> '') and (Cerrar) then
                                            If UserTask.Estado <> UserTask.Estado::Finalizado Then
                                                Gtask.CloseTarea(UserTask.Id);
                                    until UserTask.Next() = 0;
                            end;
                            if TodasCerradas then begin
                                OrdenFijacion."Estado Medios" := OrdenFijacion."Estado Medios"::Finalizado;
                                If OrdenFijacion.Retirada then OrdenFijacion."Estado Medios" := OrdenFijacion."Estado Medios"::Retirada;

                                OrdenFijacion.Modify();
                            end;
                        until OrdenFijacion.Next() = 0;
                    //OrdenFijacion.ModifyAll("Cerrada Medios", true);
                    CurrPage.Update(false);
                    Message('Tareas actualizadas correctamente');
                end;
            }
            action(FinalizaTareasRetirada)
            {
                ApplicationArea = All;
                Caption = 'Finalizar Tareas Retirada';
                Image = ClosePeriod;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Cerrar las tareas de retirada desde Gtask';

                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    UserTask: Record "User Task";
                    OrdenFijacion: Record "Orden fijación";
                    Cerrar: Boolean;
                    TodasCerradas: Boolean;
                begin
                    CurrPage.SetSelectionFilter(OrdenFijacion);
                    if OrdenFijacion.FindSet() then
                        repeat
                            TodasCerradas := true;
                            UserTask.SetRange(Reserva, OrdenFijacion."Nº Reserva");
                            UserTask.SetRange(OrdenRetirada, true);
                            if UserTask.FindSet() then begin
                                if (UserTask.Id_Tarea <> '') then
                                    If UserTask.Estado <> UserTask.Estado::Finalizado Then
                                        Gtask.CloseTarea(UserTask.Id);

                            end;

                            OrdenFijacion."Estado Medios" := OrdenFijacion."Estado Medios"::Finalizado;
                            OrdenFijacion.Modify();
                        until OrdenFijacion.Next() = 0;
                    //OrdenFijacion.ModifyAll("Cerrada Medios", true);
                    CurrPage.Update(false);
                    Message('Tareas actualizadas correctamente');
                end;
            }
            // action("Recuperar Estado Medios")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Recuperar Estado Medios';
            //     Image = ClosePeriod;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     Visible = false;
            //     ToolTip = 'No Usar, solo para recuperar el estado de las ordenes de fijación';

            //     trigger OnAction()
            //     var
            //         Gtask: Codeunit Gtask;
            //         UserTask: Record "User Task";
            //         OrdenFijacion: Record "Orden fijación";
            //         Cerrar: Boolean;
            //         TodasCerradas: Boolean;
            //     begin
            //         CurrPage.SetSelectionFilter(OrdenFijacion);
            //         if OrdenFijacion.FindSet() then
            //             Repeat

            //                 If OrdenFijacion."Cerrada Medios" then begin

            //                     OrdenFijacion."Estado Medios" := OrdenFijacion."Estado Medios"::Finalizado;
            //                     if OrdenFijacion.Retirada then
            //                         OrdenFijacion."Estado Medios" := OrdenFijacion."Estado Medios"::Retirada;
            //                     if OrdenFijacion.Retirar then
            //                         OrdenFijacion."Estado Medios" := OrdenFijacion."Estado Medios"::Retirada;
            //                     OrdenFijacion.Modify();
            //                 end;
            //             until OrdenFijacion.Next() = 0;
            //         //OrdenFijacion.ModifyAll("Cerrada Medios", true);
            //         CurrPage.Update(false);
            //         Message('Tareas actualizadas correctamente');
            //     end;
            // }
            action("Actualizar Vallas")
            {
                ApplicationArea = All;
                Caption = 'Actualizar Vallas';
                Image = RefreshLines;
                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    a: Integer;
                    Gtask: Codeunit GTask;

                begin
                    DocumentAttachment.SetRange("Table ID", Database::"Orden fijación");
                    repeat
                        Gtask.AdImagenValla(DocumentAttachment, '');
                    until DocumentAttachment.Next() = 0;

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
        if Not Cab.Get(Rec."Nº Orden") then Cab.Init();

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
        Rec.Setrange(TieneTask, true);
        Rec.SetFILTER("Estado Medios", '%1|%2', Rec."Estado Medios"::" ", Rec."Estado Medios"::Retirada);
    end;

    var
        Cab: Record "Cab Orden fijación";




}