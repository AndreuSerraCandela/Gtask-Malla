pageextension 92157 "UserTaskList" extends "User Task List"
{
    layout
    {
        addafter("Title")
        {
            field(Description; Rec.GetDescription())
            {
                ApplicationArea = All;
                StyleExpr = EstadoStyle;
            }
        }

        modify("Assigned To User Name")
        {
            Visible = false;
        }
        addbefore("created by User Name")
        {
            field(Responsable; Rec."Assigned To User Name")
            {
                Caption = 'Responsable';
                ApplicationArea = Basic, Suite;
                StyleExpr = EstadoStyle;
                DrillDown = false;
                ToolTip = 'Responsable de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.SetRange("Id Usuario", Rec."Assigned To");
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Validate("Assigned To", User."Id Usuario");
                        CurrPage.Update(true);
                    end;
                end;

            }
            field(Supervisor; Rec."Supervisor User Name")
            {
                Caption = 'Supervisor';
                ApplicationArea = Basic, Suite;
                StyleExpr = EstadoStyle;
                DrillDown = false;
                ToolTip = 'Especifique el supervisor de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.SetRange("Id Usuario", Rec.Supervisor);
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;
                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Supervisor := User."Id Usuario";
                        CurrPage.Update(true);
                    end;
                end;

            }
            field(Departamento; Rec.Departamento)
            {
                ApplicationArea = All;
                StyleExpr = EstadoStyle;
            }
            field(Servicio; Rec.Servicio)
            {
                ApplicationArea = All;
                StyleExpr = EstadoStyle;
            }
        }
        modify("User Task Group Assigned To")
        {
            Caption = 'Categoría';
            StyleExpr = EstadoStyle;
        }
        addafter("User Task Group Assigned To")
        {
            field(Job; Rec."Job No.")
            {
                Caption = 'Nº Proyecto';
                ApplicationArea = All;
                StyleExpr = EstadoStyle;
            }
            field(Estado; Rec.Estado)
            {
                Caption = 'Estado';
                ApplicationArea = All;
                StyleExpr = EstadoStyle;
            }
        }

    }
    actions
    {
        addafter("Delete User Tasks")
        {
            action("Tareas Supervisadas")
            {
                ApplicationArea = All;
                Caption = 'Tareas Supervisadas';
                Image = ServiceTasks;
                trigger OnAction()
                var
                begin
                    rec.SetRange("Assigned To");
                    Rec.SetRange("Supervisor", UserSecurityId());
                end;
            }
            action("Tareas Asignadas")
            {
                ApplicationArea = All;
                Caption = 'Tareas Asignadas';
                Image = Task;
                trigger OnAction()
                var
                begin
                    rec.SetRange(Supervisor);
                    rec.SetRange("Assigned To", UserSecurityId());
                end;
            }
            action("Tareas creadas")
            {
                ApplicationArea = All;
                Caption = 'Tareas creadas';
                Image = TaskPage;
                trigger OnAction()
                var
                begin
                    Rec.SetRange("Assigned To");
                    Rec.SetRange(Supervisor);
                    rec.SetRange("created by", UserSecurityId());
                end;
            }
            action("Actualizar Proyectos")
            {
                ApplicationArea = All;
                Caption = 'Actualizar Proyectos';
                Image = RefreshVoucher;
                trigger OnAction()
                var
                    OrdenFijacion: Record "Cab Orden fijación";
                    DocAttach: Record "Document Attachment";
                    DocAttachNew: Record "Document Attachment";
                    Task: Record "User Task";
                    a: Integer;
                begin
                    DocAttach.SetRange("Table ID", Database::"User Task");
                    If DocAttach.FindSet() then
                        repeat
                            Task.SetRange("No.", DocAttach."No.");
                            If Task.FindFirst() then begin
                                If OrdenFijacion.Get(Task.OrdenFijacion) then begin
                                    DocAttachNew.SetRange("Table ID", Database::Job);
                                    DocAttachNew.SetRange(Id, DocAttach.Id);
                                    If Not DocAttachNew.FindFirst() then begin
                                        DocAttachnew := DocAttach;
                                        DocAttachNew."Table ID" := Database::Job;
                                        DocAttachNew."No." := OrdenFijacion."Nº Proyecto";
                                        repeat
                                            DocAttachNew."Line No." := a;
                                            a += 1;
                                        until DocAttachNew.Insert();
                                        a := 0;
                                    end;
                                end;
                            end;

                        until DocAttach.Next() = 0;
                end;
            }
            // action("Actualizar Documentos Adjuntos")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Actualizar Documentos Adjuntos';
            //     Image = RefreshVoucher;
            //     trigger OnAction()
            //     var
            //         UserTask: Record "User Task";
            //         DocumentAttachment: Record "Document Attachment";
            //         DocumentAttachment2: Record "Document Attachment";
            //     begin
            //         CurrPage.SetSelectionFilter(UserTask);

            //         if UserTask.FindSet() then
            //             repeat
            //                 DocumentAttachment.SetRange("Table ID", Database::"User Task");
            //                 DocumentAttachment.SetRange("No.", UserTask."No.");
            //                 if DocumentAttachment.FindSet() then
            //                     repeat
            //                         DocumentAttachment2.SetRange("Table ID", Database::"User Task");
            //                         DocumentAttachment2.SetRange("No.", UserTask."No.");
            //                         DocumentAttachment2.SetRange("File Name", DocumentAttachment."File Name");
            //                         DocumentAttachment2.SetFilter("URL", '<>%1', DocumentAttachment.Url);
            //                         if DocumentAttachment2.FindFirst() then begin
            //                             DocumentAttachment2.Delete(true);
            //                         end;
            //                     until DocumentAttachment.Next() = 0;
            //             until UserTask.Next() = 0;
            //     end;
            // }
        }
        addbefore("User Task Groups_Promoted")
        {
            actionref("Tareas_Supervisadas_ref"; "Tareas Supervisadas") { }
            actionref("Tareas_Asignadas_ref"; "Tareas Asignadas") { }
            actionref("Tareas_Creadas_ref"; "Tareas creadas") { }
        }
    }
    trigger OnOpenPage()
    begin
        // Rec.SetRange("Assigned To", UserSecurityId());
    end;

    var
        EstadoStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Estado of
            Rec.Estado::Pendiente:
                EstadoStyle := 'Attention';
            Rec.Estado::"En Proceso":
                EstadoStyle := 'StrongAccent';
            Rec.Estado::Finalizado:
                EstadoStyle := 'Favorable';
            Rec.Estado::Cancelado:
                EstadoStyle := 'Unfavorable';
        end;
    end;

}
